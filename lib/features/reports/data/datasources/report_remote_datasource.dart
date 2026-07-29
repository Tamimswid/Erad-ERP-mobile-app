import 'dart:async';
import 'dart:developer';

import 'package:erad/core/services/user_service.dart';
import 'package:erad/features/invoices/data/models/purchase_invoice.dart';
import 'package:erad/features/invoices/data/models/sales_invoice.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ReportRemoteDataSource {
  Future<List<SalesInvoice>> getSalesInvoicesByCustomer(String customerId);
  Future<List<PurchaseInvoice>> getPurchaseInvoicesBySupplier(String supplierId);
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final SupabaseClient _supabaseClient;

  ReportRemoteDataSourceImpl(this._supabaseClient);

  @override
  Future<List<SalesInvoice>> getSalesInvoicesByCustomer(String customerId) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await _supabaseClient
          .from('sales_invoices')
          .select('*, customers!inner(name), sales_invoice_items(*)')
          .eq('user_id', userId)
          .eq('customer_id', customerId)
          .isFilter('deleted_at', null)
          .order('invoice_date', ascending: false);

      return response.map((json) => _mapJsonToSalesInvoice(json)).toList();
    } catch (e) {
      log('ReportRemoteDataSource: Failed to load customer invoices - $e');
      throw Exception('Failed to load customer invoices: $e');
    }
  }

  @override
  Future<List<PurchaseInvoice>> getPurchaseInvoicesBySupplier(String supplierId) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await _supabaseClient
          .from('purchase_invoices')
          .select('*, suppliers!inner(name), purchase_invoice_items(*)')
          .eq('user_id', userId)
          .eq('supplier_id', supplierId)
          .isFilter('deleted_at', null)
          .order('invoice_date', ascending: false);

      return response.map((json) => _mapJsonToPurchaseInvoice(json)).toList();
    } catch (e) {
      log('ReportRemoteDataSource: Failed to load supplier invoices - $e');
      throw Exception('Failed to load supplier invoices: $e');
    }
  }

  SalesInvoice _mapJsonToSalesInvoice(Map<String, dynamic> json) {
    final customerData = json['customers'] as Map<String, dynamic>?;
    final customerName = customerData?['name'] as String?;

    final itemsData = json['sales_invoice_items'] as List<dynamic>? ?? [];
    final items = itemsData.map((itemJson) {
      final item = Map<String, dynamic>.from(itemJson);
      item['product_name'] = item['product_name'] ?? '';
      return item;
    }).toList();

    final mapped = Map<String, dynamic>.from(json);
    mapped['customer_name'] = customerName;
    mapped['items'] = items;
    mapped.remove('customers');
    mapped.remove('sales_invoice_items');
    return SalesInvoice.fromJson(mapped);
  }

  PurchaseInvoice _mapJsonToPurchaseInvoice(Map<String, dynamic> json) {
    final supplierData = json['suppliers'] as Map<String, dynamic>?;
    final supplierName = supplierData?['name'] as String?;

    final itemsData = json['purchase_invoice_items'] as List<dynamic>? ?? [];
    final items = itemsData.map((itemJson) {
      final item = Map<String, dynamic>.from(itemJson);
      item['product_name'] = item['product_name'] ?? '';
      return item;
    }).toList();

    final mapped = Map<String, dynamic>.from(json);
    mapped['supplier_name'] = supplierName;
    mapped['items'] = items;
    mapped.remove('suppliers');
    mapped.remove('purchase_invoice_items');
    return PurchaseInvoice.fromJson(mapped);
  }
}
