import 'dart:async';
import 'dart:developer';
import 'package:erad/core/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:erad/core/errors/failures.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_model.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_totals_model.dart';

class CustomerDebtRemoteDataSource {
  final SupabaseClient supabaseClient;

  CustomerDebtRemoteDataSource(this.supabaseClient);

  Future<List<CustomerDebtModel>> getCustomerDebts() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }
      final response = await supabaseClient
          .from('view_customer_debt_details')
          .select('*')
          .eq('user_id', userId);
      return (response as List)
          .map(
            (json) =>
                CustomerDebtModel.fromViewMap(json as Map<String, dynamic>),
          )
          .toList();
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

  Future<List<CustomerDebtModel>> searchCustomerDebts(String query) async {
    try {
      final response = await supabaseClient
          .from('view_customer_debt_details')
          .select('*')
          .ilike('customer_name', '%$query%');

      return (response as List)
          .map(
            (json) =>
                CustomerDebtModel.fromViewMap(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
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
    String customerId,
  ) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      final response = await supabaseClient
          .from('sales_invoices')
          .select('*')
          .eq('user_id', userId)
          .eq('customer_id', customerId)
          .order('invoice_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  Future<List<Map<String, dynamic>>> getCustomerPayments(
    String customerId,
  ) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      final response = await supabaseClient
          .from('payments')
          .select('*')
          .eq('user_id', userId)
          .eq('customer_id', customerId)
          .order('payment_date', ascending: false);

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

  Stream<List<CustomerDebtModel>> watchCustomerDebts() {
    final controller = StreamController<List<CustomerDebtModel>>();
    List<StreamSubscription> subscriptions = [];

    _fetchAndEmitDebts(controller);

    final userId = UserService.getUserId();

    userId.then((uid) {
      if (uid == null) return;

      final invoiceStream = supabaseClient
          .from('sales_invoices')
          .stream(primaryKey: ['id'])
          .eq('user_id', uid);

      final paymentStream = supabaseClient
          .from('payments')
          .stream(primaryKey: ['id'])
          .eq('user_id', uid);

      subscriptions.add(
        invoiceStream.listen((_) => _fetchAndEmitDebts(controller)),
      );
      subscriptions.add(
        paymentStream.listen((_) => _fetchAndEmitDebts(controller)),
      );
    });

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
      controller.close();
    };

    return controller.stream;
  }

  Future<void> _fetchAndEmitDebts(
    StreamController<List<CustomerDebtModel>> controller,
  ) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) return;

      final response = await supabaseClient
          .from('view_customer_debt_details')
          .select('*')
          .eq('user_id', userId);

      final debts = (response as List)
          .map(
            (json) =>
                CustomerDebtModel.fromViewMap(json as Map<String, dynamic>),
          )
          .toList();

      if (!controller.isClosed) {
        controller.add(debts);
      }
    } catch (e) {
      log('Error in _fetchAndEmitDebts: $e');
    }
  }
}
