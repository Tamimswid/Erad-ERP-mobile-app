import 'dart:developer';

import 'package:erad/core/services/user_service.dart';
import 'package:erad/core/utils/paged_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:erad/core/errors/failures.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_model.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_totals_model.dart';

class SupplierDebtRemoteDataSource {
  final SupabaseClient supabaseClient;

  SupplierDebtRemoteDataSource(this.supabaseClient);

  Future<PagedResult<SupplierDebtModel>> getSupplierDebtsPage({
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
          .from('view_supplier_debt_details')
          .select('*')
          .eq('user_id', userId);

      final term = search?.trim() ?? '';
      if (term.isNotEmpty) {
        query = query.ilike('supplier_name', '%$term%');
      }

      final response = await query
          .order('supplier_name', ascending: true)
          .order('supplier_id', ascending: true)
          .range(offset, offset + limit);

      final rows = (response as List)
          .map(
            (json) =>
                SupplierDebtModel.fromViewMap(json as Map<String, dynamic>),
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

  Future<int> getSupplierDebtCount({String? search}) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      var query = supabaseClient
          .from('view_supplier_debt_details')
          .select('supplier_id')
          .eq('user_id', userId);

      final term = search?.trim() ?? '';
      if (term.isNotEmpty) {
        query = query.ilike('supplier_name', '%$term%');
      }

      final response = await query.limit(1).count(CountOption.exact);
      return response.count;
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  Future<SupplierDebtTotalsModel> getSupplierDebtTotals() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      final response = await supabaseClient
          .from('view_dashboard_supplier_debts')
          .select('*')
          .eq('user_id', userId)
          .single();

      return SupplierDebtTotalsModel.fromMap(response);
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  Future<void> addPayment(
    String supplierId,
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
        'supplier_id': supplierId,
        'payment_type': 'supplier',
        'amount': amount,
        'payment_date': paymentDate,
        'notes': note,
      });

      log('Payment: Recorded payment of $amount for supplier $supplierId');
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  Future<SupplierDebtModel> getSupplierDebt(String supplierId) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      final response = await supabaseClient
          .from('view_supplier_debt_details')
          .select('*')
          .eq('user_id', userId)
          .eq('supplier_id', supplierId)
          .single();

      return SupplierDebtModel.fromViewMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  Future<List<Map<String, dynamic>>> getSupplierInvoices(
    String supplierId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      var query = supabaseClient
          .from('purchase_invoices')
          .select('*')
          .eq('user_id', userId)
          .eq('supplier_id', supplierId);
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

  Future<PagedResult<Map<String, dynamic>>> getSupplierInvoicesPage(
    String supplierId, {
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
          .from('purchase_invoices')
          .select('*')
          .eq('user_id', userId)
          .eq('supplier_id', supplierId)
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

  Future<PagedResult<Map<String, dynamic>>> getSupplierPaymentsPage(
    String supplierId, {
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
          .eq('supplier_id', supplierId);
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

  Future<double> getSupplierInvoiceTotal(String supplierId) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      final response = await supabaseClient
          .from('purchase_invoices')
          .select('total_amount')
          .eq('user_id', userId)
          .eq('supplier_id', supplierId)
          .eq('payment_status', 'debt');

      return response.fold<double>(
        0,
        (sum, row) => sum + ((row['total_amount'] ?? 0) as num).toDouble(),
      );
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  Future<double> getSupplierPaymentTotal(String supplierId) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      final response = await supabaseClient
          .from('payments')
          .select('amount')
          .eq('user_id', userId)
          .eq('supplier_id', supplierId);

      return response.fold<double>(
        0,
        (sum, row) => sum + ((row['amount'] ?? 0) as num).toDouble(),
      );
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  Future<List<Map<String, dynamic>>> getSupplierPayments(
    String supplierId, {
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
          .eq('supplier_id', supplierId);
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
    String supplierId,
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
        'update_supplier_balance',
        params: {'p_supplier_id': supplierId, 'p_amount': amount},
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
