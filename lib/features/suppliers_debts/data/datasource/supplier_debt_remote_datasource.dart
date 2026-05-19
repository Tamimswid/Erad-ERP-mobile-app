import 'dart:async';
import 'dart:developer';

import 'package:erad/core/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:erad/core/errors/failures.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_model.dart';

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
          .from('purchase_invoices')
          .select('''
            id,
            invoice_number,
            supplier_id,
            invoice_date,
            due_date,
            total_amount,
            payment_status,
            status,
            suppliers!inner(
              name,
              phone
            )
          ''')
          .eq('user_id', userId)
          .eq('status', 'completed')
          .order('invoice_date', ascending: false);

      final paymentsResponse = await supabaseClient
          .from('payments')
          .select('supplier_id, amount')
          .eq('user_id', userId);

      final supplierPayments = <String, double>{};
      for (var json in paymentsResponse as List) {
        final payment = json as Map<String, dynamic>;
        final supplierId = payment['supplier_id'] as String?;
        if (supplierId != null) {
          final amount = (payment['amount'] ?? 0.0).toDouble();
          supplierPayments[supplierId] = (supplierPayments[supplierId] ?? 0.0) + amount;
        }
      }

      final supplierDebts = <String, SupplierDebtModel>{};

      for (var json in response as List) {
        final invoiceData = json as Map<String, dynamic>;
        final supplierId = invoiceData['supplier_id'] as String?;
        if (supplierId == null) continue;

        final totalAmount = (invoiceData['total_amount'] ?? 0.0).toDouble();
        final paidAmount = supplierPayments[supplierId] ?? 0.0;
        final supplierData = invoiceData['suppliers'] as Map<String, dynamic>?;

        if (supplierDebts.containsKey(supplierId)) {
          final existing = supplierDebts[supplierId]!;
          supplierDebts[supplierId] = SupplierDebtModel(
            id: supplierId,
            name: existing.name,
            phone: existing.phone,
            totalInvoices: existing.totalInvoices + totalAmount,
            totalPaid: paidAmount,
            totalInvoicesCount: existing.totalInvoicesCount + 1,
            pendingInvoicesCount: existing.pendingInvoicesCount + 1,
            overdueInvoicesCount: existing.overdueInvoicesCount,
            latestDueDate: _getLatestDate(existing.latestDueDate, invoiceData['due_date']),
          );
        } else {
          supplierDebts[supplierId] = SupplierDebtModel(
            id: supplierId,
            name: supplierData?['name'] ?? 'غير محدد',
            phone: supplierData?['phone'],
            totalInvoices: totalAmount,
            totalPaid: paidAmount,
            totalInvoicesCount: 1,
            pendingInvoicesCount: 1,
            overdueInvoicesCount: 0,
            latestDueDate: invoiceData['due_date'],
          );
        }
      }

      return supplierDebts.values.toList();
    } catch (e) {
      log(e.toString());
      throw exceptionToFailure(e);
    }
  }

  String? _getLatestDate(String? current, String? newDate) {
    if (current == null) return newDate;
    if (newDate == null) return current;
    return DateTime.parse(newDate).isAfter(DateTime.parse(current)) ? newDate : current;
  }

  Future<List<SupplierDebtModel>> searchSupplierDebts(String query) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw const AuthFailure('User not authenticated');
      }

      final response = await supabaseClient
          .from('purchase_invoices')
          .select('''
            id,
            invoice_number,
            supplier_id,
            invoice_date,
            due_date,
            total_amount,
            payment_status,
            status,
            suppliers!inner(
              name,
              phone
            )
          ''')
          .eq('user_id', userId)
          .or('suppliers.name.ilike.%$query%,invoice_number.ilike.%$query%')
          .order('invoice_date', ascending: false);

      final Set<String> supplierIds = {};
      for (var json in response as List) {
        supplierIds.add((json as Map<String, dynamic>)['supplier_id'] as String);
      }

      final supplierPayments = <String, double>{};
      if (supplierIds.isNotEmpty) {
        final paymentsResponse = await supabaseClient
            .from('payments')
            .select('supplier_id, amount')
            .eq('user_id', userId)
            .eq('payment_type', 'supplier')
            .inFilter('supplier_id', supplierIds.toList());

        for (var json in paymentsResponse as List) {
          final payment = json as Map<String, dynamic>;
          final supplierId = payment['supplier_id'] as String?;
          if (supplierId != null) {
            final amount = (payment['amount'] ?? 0.0).toDouble();
            supplierPayments[supplierId] = (supplierPayments[supplierId] ?? 0.0) + amount;
          }
        }
      }

      final supplierDebts = <String, SupplierDebtModel>{};

      for (var json in response as List) {
        final invoiceData = json as Map<String, dynamic>;
        final supplierId = invoiceData['supplier_id'] as String?;
        if (supplierId == null) continue;

        final totalAmount = (invoiceData['total_amount'] ?? 0.0).toDouble();
        final paidAmount = supplierPayments[supplierId] ?? 0.0;
        final supplierData = invoiceData['suppliers'] as Map<String, dynamic>?;

        if (supplierDebts.containsKey(supplierId)) {
          final existing = supplierDebts[supplierId]!;
          supplierDebts[supplierId] = SupplierDebtModel(
            id: supplierId,
            name: existing.name,
            phone: existing.phone,
            totalInvoices: existing.totalInvoices + totalAmount,
            totalPaid: paidAmount,
            totalInvoicesCount: existing.totalInvoicesCount + 1,
            pendingInvoicesCount: existing.pendingInvoicesCount + 1,
            overdueInvoicesCount: existing.overdueInvoicesCount,
            latestDueDate: _getLatestDate(existing.latestDueDate, invoiceData['due_date']),
          );
        } else {
          supplierDebts[supplierId] = SupplierDebtModel(
            id: supplierId,
            name: supplierData?['name'] ?? 'غير محدد',
            phone: supplierData?['phone'],
            totalInvoices: totalAmount,
            totalPaid: paidAmount,
            totalInvoicesCount: 1,
            pendingInvoicesCount: 1,
            overdueInvoicesCount: 0,
            latestDueDate: invoiceData['due_date'],
          );
        }
      }

      return supplierDebts.values.toList();
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  Future<void> addPayment(String supplierId, double amount, String? note, String paymentDate) async {
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
          .from('purchase_invoices')
          .select('''
            id,
            invoice_number,
            supplier_id,
            invoice_date,
            due_date,
            total_amount,
            payment_status,
            status,
            suppliers!inner(
              name,
              phone
            )
          ''')
          .eq('user_id', userId)
          .eq('supplier_id', supplierId)
          .order('invoice_date', ascending: false);

      final paymentsResponse = await supabaseClient
          .from('payments')
          .select('amount')
          .eq('user_id', userId)
          .eq('supplier_id', supplierId);

      double totalPaidAmount = 0.0;
      for (var json in paymentsResponse as List) {
        totalPaidAmount += (json['amount'] ?? 0.0).toDouble();
      }

      final supplierDebts = <String, SupplierDebtModel>{};

      for (var json in response as List) {
        final invoiceData = json as Map<String, dynamic>;
        final currentSupplierId = invoiceData['supplier_id'] as String;
        final totalAmount = (invoiceData['total_amount'] ?? 0.0).toDouble();
        final supplierData = invoiceData['suppliers'] as Map<String, dynamic>?;

        if (supplierDebts.containsKey(currentSupplierId)) {
          final existing = supplierDebts[currentSupplierId]!;
          supplierDebts[currentSupplierId] = SupplierDebtModel(
            id: currentSupplierId,
            name: existing.name,
            phone: existing.phone,
            totalInvoices: existing.totalInvoices + totalAmount,
            totalPaid: totalPaidAmount,
            totalInvoicesCount: existing.totalInvoicesCount + 1,
            pendingInvoicesCount: existing.pendingInvoicesCount + 1,
            overdueInvoicesCount: existing.overdueInvoicesCount,
            latestDueDate: _getLatestDate(existing.latestDueDate, invoiceData['due_date']),
          );
        } else {
          supplierDebts[currentSupplierId] = SupplierDebtModel(
            id: currentSupplierId,
            name: supplierData?['name'] ?? 'غير محدد',
            phone: supplierData?['phone'],
            totalInvoices: totalAmount,
            totalPaid: totalPaidAmount,
            totalInvoicesCount: 1,
            pendingInvoicesCount: 1,
            overdueInvoicesCount: 0,
            latestDueDate: invoiceData['due_date'],
          );
        }
      }

      return supplierDebts.values.first;
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  Future<List<Map<String, dynamic>>> getSupplierInvoices(String supplierId) async {
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

  Future<List<Map<String, dynamic>>> getSupplierPayments(String supplierId) async {
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

  Future<void> deletePayment(String paymentId, String supplierId, double amount) async {
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

  Stream<List<SupplierDebtModel>> watchSupplierDebts() async* {
    final userId = await UserService.getUserId();
    if (userId == null) throw Exception('User not logged in');

    log('SupplierDebtDataSource: Starting watchSupplierDebts stream...');

    await for (final data in supabaseClient
        .from('purchase_invoices')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('invoice_date', ascending: false)) {

      log('SupplierDebtDataSource: Received ${data.length} invoices from stream');

      final supplierPayments = <String, double>{};
      try {
        final paymentsResponse = await supabaseClient
            .from('payments')
            .select('supplier_id, amount')
            .eq('user_id', userId);

        for (var json in paymentsResponse as List) {
          final payment = json as Map<String, dynamic>;
          final supplierId = payment['supplier_id'] as String?;
          if (supplierId != null) {
            final amount = (payment['amount'] ?? 0.0).toDouble();
            supplierPayments[supplierId] = (supplierPayments[supplierId] ?? 0.0) + amount;
          }
        }
      } catch (e) {
        log('Error fetching payments in stream: $e');
      }

      final supplierDebts = <String, SupplierDebtModel>{};

      for (var json in data) {
        final supplierId = json['supplier_id'] as String?;
        if (supplierId == null) continue;

        final totalAmount = (json['total_amount'] ?? 0.0).toDouble();
        final paidAmount = supplierPayments[supplierId] ?? 0.0;

        if (supplierDebts.containsKey(supplierId)) {
          final existing = supplierDebts[supplierId]!;
          supplierDebts[supplierId] = SupplierDebtModel(
            id: supplierId,
            name: existing.name,
            phone: existing.phone,
            totalInvoices: existing.totalInvoices + totalAmount,
            totalPaid: paidAmount,
            totalInvoicesCount: existing.totalInvoicesCount + 1,
            pendingInvoicesCount: existing.pendingInvoicesCount + 1,
            overdueInvoicesCount: existing.overdueInvoicesCount,
            latestDueDate: _getLatestDate(existing.latestDueDate, json['due_date']),
          );
        } else {
          supplierDebts[supplierId] = SupplierDebtModel(
            id: supplierId,
            name: 'مورد #$supplierId',
            phone: null,
            totalInvoices: totalAmount,
            totalPaid: paidAmount,
            totalInvoicesCount: 1,
            pendingInvoicesCount: 1,
            overdueInvoicesCount: 0,
            latestDueDate: json['due_date'],
          );
        }
      }

      log('SupplierDebtDataSource: Filtered ${supplierDebts.length} suppliers with debt');
      yield supplierDebts.values.toList();
    }
  }
}