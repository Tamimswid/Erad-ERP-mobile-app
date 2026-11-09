import 'dart:developer';
import 'package:erad/core/services/user_service.dart';
import 'package:erad/core/utils/paged_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:erad/core/errors/failures.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_model.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_totals_model.dart';

class CustomerDebtRemoteDataSource {
  final SupabaseClient supabaseClient;

  CustomerDebtRemoteDataSource(this.supabaseClient);

  Future<PagedResult<CustomerDebtModel>> getCustomerDebtsPage({
    required int offset,
    int limit = 10,
    String? search,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      var query = supabaseClient
          .from('view_customer_debt_details')
          .select('*')
          .eq('user_id', userId);

      final term = search?.trim() ?? '';
      if (term.isNotEmpty) {
        query = query.ilike('customer_name', '%$term%');
      }

      final response = await query
          .order('customer_name', ascending: true)
          .order('customer_id', ascending: true)
          .range(offset, offset + limit);

      final rows = (response as List)
          .map(
            (json) =>
                CustomerDebtModel.fromViewMap(json as Map<String, dynamic>),
          )
          .toList();

      final hasMore = rows.length > limit;
      return PagedResult(
        items: hasMore ? rows.sublist(0, limit) : rows,
        hasMore: hasMore,
      );
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  Future<int> getCustomerDebtCount({String? search}) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      var query = supabaseClient
          .from('view_customer_debt_details')
          .select('customer_id')
          .eq('user_id', userId);

      final term = search?.trim() ?? '';
      if (term.isNotEmpty) {
        query = query.ilike('customer_name', '%$term%');
      }

      final response = await query.limit(1).count(CountOption.exact);
      return response.count;
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  Future<CustomerDebtTotalsModel> getCustomerDebtTotals() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      final response = await supabaseClient
          .from('view_dashboard_customer_debts')
          .select('*')
          .eq('user_id', userId)
          .single();

      return CustomerDebtTotalsModel.fromMap(response);
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  Future<void> addPayment(
    String customerId,
    double amount,
    String? note,
    String paymentDate,
  ) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      await supabaseClient.from('payments').insert({
        'user_id': userId,
        'customer_id': customerId,
        'payment_type': 'customer',
        'amount': amount,
        'payment_date': paymentDate,
        'notes': note,
      });

      log('Payment: Recorded payment of $amount for customer $customerId');
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  Future<CustomerDebtModel> getCustomerDebt(String customerId) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      final response = await supabaseClient
          .from('view_customer_debt_details')
          .select('*')
          .eq('user_id', userId)
          .eq('customer_id', customerId)
          .single();

      return CustomerDebtModel.fromViewMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerInvoices(
    String customerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      var query = supabaseClient
          .from('sales_invoices')
          .select('*')
          .eq('user_id', userId)
          .eq('customer_id', customerId);
      if (startDate != null) {
        query = query.gte('invoice_date', _startOfDay(startDate));
      }
      if (endDate != null) {
        query = query.lte('invoice_date', _endOfDay(endDate));
      }

      final response = await query.order('invoice_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  Future<PagedResult<Map<String, dynamic>>> getCustomerInvoicesPage(
    String customerId, {
    required int offset,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      var query = supabaseClient
          .from('sales_invoices')
          .select('*')
          .eq('user_id', userId)
          .eq('customer_id', customerId)
          .eq('payment_status', 'debt');
      if (startDate != null) {
        query = query.gte('invoice_date', _startOfDay(startDate));
      }
      if (endDate != null) {
        query = query.lte('invoice_date', _endOfDay(endDate));
      }

      final response = await query
          .order('invoice_date', ascending: false)
          .order('id', ascending: true)
          .range(offset, offset + limit);

      final rows = List<Map<String, dynamic>>.from(response);
      final hasMore = rows.length > limit;
      return PagedResult(
        items: hasMore ? rows.sublist(0, limit) : rows,
        hasMore: hasMore,
      );
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  Future<PagedResult<Map<String, dynamic>>> getCustomerPaymentsPage(
    String customerId, {
    required int offset,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      var query = supabaseClient
          .from('payments')
          .select('*')
          .eq('user_id', userId)
          .eq('customer_id', customerId);
      if (startDate != null) {
        query = query.gte('payment_date', _startOfDay(startDate));
      }
      if (endDate != null) {
        query = query.lte('payment_date', _endOfDay(endDate));
      }

      final response = await query
          .order('payment_date', ascending: false)
          .order('id', ascending: true)
          .range(offset, offset + limit);

      final rows = List<Map<String, dynamic>>.from(response);
      final hasMore = rows.length > limit;
      return PagedResult(
        items: hasMore ? rows.sublist(0, limit) : rows,
        hasMore: hasMore,
      );
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  Future<double> getCustomerInvoiceTotal(String customerId) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      final response = await supabaseClient
          .from('sales_invoices')
          .select('total_amount')
          .eq('user_id', userId)
          .eq('customer_id', customerId)
          .eq('payment_status', 'debt');

      return response.fold<double>(
        0,
        (sum, row) => sum + ((row['total_amount'] ?? 0) as num).toDouble(),
      );
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  Future<double> getCustomerPaymentTotal(String customerId) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      final response = await supabaseClient
          .from('payments')
          .select('amount')
          .eq('user_id', userId)
          .eq('customer_id', customerId);

      return response.fold<double>(
        0,
        (sum, row) => sum + ((row['amount'] ?? 0) as num).toDouble(),
      );
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerPayments(
    String customerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      var query = supabaseClient
          .from('payments')
          .select('*')
          .eq('user_id', userId)
          .eq('customer_id', customerId);
      if (startDate != null) {
        query = query.gte('payment_date', _startOfDay(startDate));
      }
      if (endDate != null) {
        query = query.lte('payment_date', _endOfDay(endDate));
      }

      final response = await query.order('payment_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  Future<void> deletePayment(
    String paymentId,
    String customerId,
    double amount,
  ) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      await supabaseClient
          .from('payments')
          .delete()
          .eq('id', paymentId)
          .eq('user_id', userId);

      await supabaseClient.rpc(
        'update_customer_balance',
        params: {'p_customer_id': customerId, 'p_amount': amount},
      );
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  String _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day).toIso8601String();
  }

  String _endOfDay(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
      999,
    ).toIso8601String();
  }
}
