import 'dart:async';
import 'dart:developer';

import 'package:erad/core/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:erad/core/errors/failures.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_model.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_totals_model.dart';

class SupplierDebtRemoteDataSource {
  final SupabaseClient supabaseClient;

  SupplierDebtRemoteDataSource(this.supabaseClient);

  Future<List<SupplierDebtModel>> getSupplierDebts() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      final response = await supabaseClient
          .from('view_supplier_debt_details')
          .select('*')
          .eq('user_id', userId);

      return (response as List)
          .map((json) =>
              SupplierDebtModel.fromViewMap(json as Map<String, dynamic>))
          .toList();
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

  Future<List<SupplierDebtModel>> searchSupplierDebts(String query) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      final response = await supabaseClient
          .from('view_supplier_debt_details')
          .select('*')
          .eq('user_id', userId)
          .ilike('supplier_name', '%$query%');

      return (response as List)
          .map((json) =>
              SupplierDebtModel.fromViewMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
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
    String supplierId,
  ) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      final response = await supabaseClient
          .from('purchase_invoices')
          .select('*')
          .eq('user_id', userId)
          .eq('supplier_id', supplierId)
          .order('invoice_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  Future<List<Map<String, dynamic>>> getSupplierPayments(
    String supplierId,
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
          .eq('supplier_id', supplierId)
          .order('payment_date', ascending: false);

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

      await supabaseClient.rpc('update_supplier_balance', params: {
        'p_supplier_id': supplierId,
        'p_amount': amount,
      });
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  Stream<List<SupplierDebtModel>> watchSupplierDebts() {
    final controller = StreamController<List<SupplierDebtModel>>();
    List<StreamSubscription> subscriptions = [];

    _fetchAndEmitSupplierDebts(controller);

    final userId = UserService.getUserId();

    userId.then((uid) {
      if (uid == null) return;

      final invoiceStream = supabaseClient
          .from('purchase_invoices')
          .stream(primaryKey: ['id'])
          .eq('user_id', uid);

      final paymentStream = supabaseClient
          .from('payments')
          .stream(primaryKey: ['id'])
          .eq('user_id', uid);

      subscriptions.add(
          invoiceStream.listen((_) => _fetchAndEmitSupplierDebts(controller)));
      subscriptions.add(
          paymentStream.listen((_) => _fetchAndEmitSupplierDebts(controller)));
    });

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
      controller.close();
    };

    return controller.stream;
  }

  Future<void> _fetchAndEmitSupplierDebts(
    StreamController<List<SupplierDebtModel>> controller,
  ) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) return;

      final response = await supabaseClient
          .from('view_supplier_debt_details')
          .select('*')
          .eq('user_id', userId);

      final debts = (response as List)
          .map((json) =>
              SupplierDebtModel.fromViewMap(json as Map<String, dynamic>))
          .toList();

      if (!controller.isClosed) {
        controller.add(debts);
      }
    } catch (e) {
      log('Error in _fetchAndEmitSupplierDebts: $e');
    }
  }
}
