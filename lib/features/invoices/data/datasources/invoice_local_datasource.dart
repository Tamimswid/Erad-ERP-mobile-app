import 'package:erad/core/database/app_database.dart';
import '../models/sales_invoice.dart';
import '../models/purchase_invoice.dart';

abstract class InvoiceLocalDataSource {
  Future<void> cacheSalesInvoices(String userId, List<SalesInvoice> invoices);
  Future<void> cachePurchaseInvoices(String userId, List<PurchaseInvoice> invoices);
  Future<List<SalesInvoice>> getCachedSalesInvoices(String userId);
  Future<List<PurchaseInvoice>> getCachedPurchaseInvoices(String userId);
  Future<void> clearCache(String userId);
}

class InvoiceLocalDataSourceImpl implements InvoiceLocalDataSource {
  final AppDatabase _db;

  InvoiceLocalDataSourceImpl(this._db);

  @override
  Future<void> cacheSalesInvoices(String userId, List<SalesInvoice> invoices) async {
    await _db.clearTable('sales_invoices_cache', userId);
    await _db.upsertJsonList(
      'sales_invoices_cache',
      userId,
      invoices.map((inv) => inv.toJson()).toList(),
      (map) => map['id'] as String,
    );
  }

  @override
  Future<void> cachePurchaseInvoices(String userId, List<PurchaseInvoice> invoices) async {
    await _db.clearTable('purchase_invoices_cache', userId);
    await _db.upsertJsonList(
      'purchase_invoices_cache',
      userId,
      invoices.map((inv) => inv.toJson()).toList(),
      (map) => map['id'] as String,
    );
  }

  @override
  Future<List<SalesInvoice>> getCachedSalesInvoices(String userId) async {
    final items = await _db.getAllJson('sales_invoices_cache', userId);
    return items.map((json) => SalesInvoice.fromJson(json)).toList();
  }

  @override
  Future<List<PurchaseInvoice>> getCachedPurchaseInvoices(String userId) async {
    final items = await _db.getAllJson('purchase_invoices_cache', userId);
    return items.map((json) => PurchaseInvoice.fromJson(json)).toList();
  }

  @override
  Future<void> clearCache(String userId) async {
    await _db.clearTable('sales_invoices_cache', userId);
    await _db.clearTable('purchase_invoices_cache', userId);
  }
}
