import 'package:erad/core/database/app_database.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_model.dart';

abstract class CustomerDebtLocalDataSource {
  Future<void> cacheCustomerDebts(String userId, List<CustomerDebtModel> debts);
  Future<List<CustomerDebtModel>> getCachedCustomerDebts(String userId);
  Future<void> cacheCustomerInvoices(String userId, String customerId, List<Map<String, dynamic>> invoices);
  Future<List<Map<String, dynamic>>> getCachedCustomerInvoices(String userId, String customerId);
  Future<void> cacheCustomerPayments(String userId, String customerId, List<Map<String, dynamic>> payments);
  Future<List<Map<String, dynamic>>> getCachedCustomerPayments(String userId, String customerId);
  Future<void> queuePayment(Map<String, dynamic> payment);
  Future<List<Map<String, dynamic>>> getPendingPayments(String userId);
  Future<void> deletePendingPayment(String id);
  Future<void> updateDebtAfterPayment(String userId, String customerId, double amount);
  Future<void> addPaymentToLocalCache(String userId, String customerId, Map<String, dynamic> payment);
  Future<void> clearCache(String userId);
}

class CustomerDebtLocalDataSourceImpl implements CustomerDebtLocalDataSource {
  final AppDatabase _db;

  CustomerDebtLocalDataSourceImpl(this._db);

  @override
  Future<void> cacheCustomerDebts(String userId, List<CustomerDebtModel> debts) async {
    await _db.clearTable('customer_debts_cache', userId);
    await _db.upsertJsonList(
      'customer_debts_cache',
      userId,
      debts.map((d) => d.toMap()).toList(),
      (map) => map['id'] as String,
    );
  }

  @override
  Future<List<CustomerDebtModel>> getCachedCustomerDebts(String userId) async {
    final items = await _db.getAllJson('customer_debts_cache', userId);
    return items.map((json) => CustomerDebtModel.fromMap(json)).toList();
  }

  @override
  Future<void> cacheCustomerInvoices(
    String userId,
    String customerId,
    List<Map<String, dynamic>> invoices,
  ) async {
    await _db.upsertCustomerData('customer_invoices_cache', customerId, userId, invoices);
  }

  @override
  Future<List<Map<String, dynamic>>> getCachedCustomerInvoices(
    String userId,
    String customerId,
  ) async {
    return await _db.getCustomerData('customer_invoices_cache', customerId, userId);
  }

  @override
  Future<void> cacheCustomerPayments(
    String userId,
    String customerId,
    List<Map<String, dynamic>> payments,
  ) async {
    await _db.upsertCustomerData('customer_payments_cache', customerId, userId, payments);
  }

  @override
  Future<List<Map<String, dynamic>>> getCachedCustomerPayments(
    String userId,
    String customerId,
  ) async {
    return await _db.getCustomerData('customer_payments_cache', customerId, userId);
  }

  @override
  Future<void> queuePayment(Map<String, dynamic> payment) async {
    await _db.insertPendingPayment(payment);
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingPayments(String userId) async {
    return await _db.getPendingPayments(userId);
  }

  @override
  Future<void> deletePendingPayment(String id) async {
    await _db.deletePendingPayment(id);
  }

  @override
  Future<void> updateDebtAfterPayment(String userId, String customerId, double amount) async {
    final debts = await getCachedCustomerDebts(userId);
    final index = debts.indexWhere((d) => d.id == customerId);
    if (index == -1) return;
    final updated = debts[index].copyWith(
      totalPaid: debts[index].totalPaid + amount,
    );
    debts[index] = updated;
    await cacheCustomerDebts(userId, debts);
  }

  @override
  Future<void> addPaymentToLocalCache(String userId, String customerId, Map<String, dynamic> payment) async {
    final payments = await getCachedCustomerPayments(userId, customerId);
    payments.add(payment);
    await cacheCustomerPayments(userId, customerId, payments);
  }

  @override
  Future<void> clearCache(String userId) async {
    await _db.clearTable('customer_debts_cache', userId);
  }
}
