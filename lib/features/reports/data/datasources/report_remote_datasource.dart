import 'dart:async';
import 'dart:developer';

import 'package:erad/core/services/user_service.dart';
import 'package:erad/core/utils/paged_result.dart';
import 'package:erad/features/invoices/data/models/purchase_invoice.dart';
import 'package:erad/features/invoices/data/models/sales_invoice.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ReportRemoteDataSource {
  Future<List<SalesInvoice>> getSalesInvoicesByCustomer(String customerId);
  Future<List<PurchaseInvoice>> getPurchaseInvoicesBySupplier(
    String supplierId,
  );
  Future<PagedResult<SalesInvoice>> getSalesInvoicesPage({
    required String customerId,
    required int offset,
    int limit = 10,
    String? year,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<PagedResult<PurchaseInvoice>> getPurchaseInvoicesPage({
    required String supplierId,
    required int offset,
    int limit = 10,
    String? year,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<String>> getSalesInvoiceYears(String customerId);
  Future<List<String>> getPurchaseInvoiceYears(String supplierId);
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final SupabaseClient _supabaseClient;

  ReportRemoteDataSourceImpl(this._supabaseClient);

  @override
  Future<List<SalesInvoice>> getSalesInvoicesByCustomer(
    String customerId,
  ) async {
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
  Future<List<PurchaseInvoice>> getPurchaseInvoicesBySupplier(
    String supplierId,
  ) async {
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

  @override
  Future<PagedResult<SalesInvoice>> getSalesInvoicesPage({
    required String customerId,
    required int offset,
    int limit = 10,
    String? year,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      var query = _supabaseClient
          .from('sales_invoices')
          .select('*, customers!inner(name), sales_invoice_items(*)')
          .eq('user_id', userId)
          .eq('customer_id', customerId)
          .isFilter('deleted_at', null);

      final range = _resolveDateRange(year, startDate, endDate);
      if (range != null) {
        query = query
            .gte('invoice_date', range.$1.toIso8601String())
            .lte('invoice_date', range.$2.toIso8601String());
      }

      final response = await query
          .order('invoice_date', ascending: false)
          .order('id', ascending: true)
          .range(offset, offset + limit);

      final invoices = response.map(_mapJsonToSalesInvoice).toList();
      final hasMore = invoices.length > limit;
      return PagedResult(
        items: hasMore ? invoices.sublist(0, limit) : invoices,
        hasMore: hasMore,
      );
    } catch (e) {
      log('ReportRemoteDataSource: Failed to load customer invoice page - $e');
      throw Exception('Failed to load customer invoices: $e');
    }
  }

  @override
  Future<PagedResult<PurchaseInvoice>> getPurchaseInvoicesPage({
    required String supplierId,
    required int offset,
    int limit = 10,
    String? year,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      var query = _supabaseClient
          .from('purchase_invoices')
          .select('*, suppliers!inner(name), purchase_invoice_items(*)')
          .eq('user_id', userId)
          .eq('supplier_id', supplierId)
          .isFilter('deleted_at', null);

      final range = _resolveDateRange(year, startDate, endDate);
      if (range != null) {
        query = query
            .gte('invoice_date', range.$1.toIso8601String())
            .lte('invoice_date', range.$2.toIso8601String());
      }

      final response = await query
          .order('invoice_date', ascending: false)
          .order('id', ascending: true)
          .range(offset, offset + limit);

      final invoices = response.map(_mapJsonToPurchaseInvoice).toList();
      final hasMore = invoices.length > limit;
      return PagedResult(
        items: hasMore ? invoices.sublist(0, limit) : invoices,
        hasMore: hasMore,
      );
    } catch (e) {
      log('ReportRemoteDataSource: Failed to load supplier invoice page - $e');
      throw Exception('Failed to load supplier invoices: $e');
    }
  }

  @override
  Future<List<String>> getSalesInvoiceYears(String customerId) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await _supabaseClient
          .from('sales_invoices')
          .select('invoice_date')
          .eq('user_id', userId)
          .eq('customer_id', customerId)
          .isFilter('deleted_at', null);

      return _extractYears(response);
    } catch (e) {
      log('ReportRemoteDataSource: Failed to load customer invoice years - $e');
      throw Exception('Failed to load customer invoice years: $e');
    }
  }

  @override
  Future<List<String>> getPurchaseInvoiceYears(String supplierId) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      final response = await _supabaseClient
          .from('purchase_invoices')
          .select('invoice_date')
          .eq('user_id', userId)
          .eq('supplier_id', supplierId)
          .isFilter('deleted_at', null);

      return _extractYears(response);
    } catch (e) {
      log('ReportRemoteDataSource: Failed to load supplier invoice years - $e');
      throw Exception('Failed to load supplier invoice years: $e');
    }
  }

  (DateTime, DateTime)? _resolveDateRange(
    String? year,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate != null && endDate != null) {
      return (
        DateTime(startDate.year, startDate.month, startDate.day),
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999),
      );
    }
    final parsedYear = int.tryParse(year ?? '');
    if (parsedYear != null) {
      return (
        DateTime(parsedYear, 1, 1),
        DateTime(parsedYear, 12, 31, 23, 59, 59, 999),
      );
    }
    return null;
  }

  List<String> _extractYears(List<Map<String, dynamic>> rows) {
    final years = <String>{};
    for (final row in rows) {
      final raw = row['invoice_date'];
      final date = raw is String ? DateTime.tryParse(raw) : null;
      if (date != null) years.add(date.year.toString());
    }
    final sorted = years.toList()..sort((a, b) => b.compareTo(a));
    return sorted.isEmpty ? [DateTime.now().year.toString()] : sorted;
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
