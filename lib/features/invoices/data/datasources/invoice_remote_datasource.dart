import 'dart:async';
import 'dart:developer';

import 'package:erad/features/invoices/data/models/sales_invoice.dart';
import 'package:erad/features/invoices/data/models/purchase_invoice.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/paged_result.dart';

abstract class InvoiceRemoteDataSource {
  // جلب جميع فواتير البيع
  Future<List<SalesInvoice>> getSalesInvoices();
  // جلب جميع فواتير الشراء
  Future<List<PurchaseInvoice>> getPurchaseInvoices();
  // جلب صفحة من فواتير البيع
  Future<PagedResult<SalesInvoice>> getSalesInvoicesPage({
    required int offset,
    int limit = 10,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
  });
  // جلب صفحة من فواتير الشراء
  Future<PagedResult<PurchaseInvoice>> getPurchaseInvoicesPage({
    required int offset,
    int limit = 10,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
  });
  // جلب فاتورة بيع بالمعرف
  Future<SalesInvoice> getSalesInvoiceById(String id);
  // جلب فاتورة شراء بالمعرف
  Future<PurchaseInvoice> getPurchaseInvoiceById(String id);
  // إنشاء فاتورة بيع جديدة
  Future<SalesInvoice> createSalesInvoice(SalesInvoice invoice);
  // إنشاء فاتورة شراء جديدة
  Future<PurchaseInvoice> createPurchaseInvoice(PurchaseInvoice invoice);
  // تحديث فاتورة بيع
  Future<SalesInvoice> updateSalesInvoice(SalesInvoice invoice);
  // تحديث فاتورة شراء
  Future<PurchaseInvoice> updatePurchaseInvoice(PurchaseInvoice invoice);
  // حذف فاتورة بيع
  Future<void> deleteSalesInvoice(String id);
  // حذف فاتورة شراء
  Future<void> deletePurchaseInvoice(String id);
  // إنهاء فاتورة بيع
  Future<void> finalizeSalesInvoice(String id);
  // إنهاء فاتورة شراء
  Future<void> finalizePurchaseInvoice(String id);
  // تحديث رصيد العميل
  Future<void> updateCustomerBalance(String customerId, double amount);
}

class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  final SupabaseClient _supabaseClient;

  InvoiceRemoteDataSourceImpl(this._supabaseClient);

  @override
  Future<List<SalesInvoice>> getSalesInvoices() async {
    try {
      // التحقق من تسجيل دخول المستخدم
      final userId = await UserService.getUserId();
      if (userId == null) throw Exception('User not logged in');
      // جلب فواتير البيع مع بيانات العناصر
      final response = await _supabaseClient
          .from('sales_invoices')
          .select('*, customers!inner(name), sales_invoice_items(*)')
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .eq('customers.is_active', true)
          .order('created_at', ascending: false);

      return response.map((json) => _mapJsonToSalesInvoice(json)).toList();
    } catch (e) {
      throw Exception('Failed to load sales invoices: $e');
    }
  }

  @override
  Future<List<PurchaseInvoice>> getPurchaseInvoices() async {
    try {
      // التحقق من تسجيل دخول المستخدم
      final userId = await UserService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      log('DEBUG: Loading purchase invoices for user: $userId');

      // جلب فواتير الشراء مع بيانات العناصر
      final response = await _supabaseClient
          .from('purchase_invoices')
          .select('*, suppliers(name), purchase_invoice_items(*)')
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      log('DEBUG: Purchase invoices response count: ${response.length}');

      final invoices = response
          .map((json) => _mapJsonToPurchaseInvoice(json))
          .toList();
      log('DEBUG: Mapped purchase invoices count: ${invoices.length}');
      log(response.toString());
      return invoices;
    } catch (e) {
      log('ERROR: Failed to load purchase invoices: $e');
      throw Exception('Failed to load purchase invoices: $e');
    }
  }

  @override
  Future<PagedResult<SalesInvoice>> getSalesInvoicesPage({
    required int offset,
    int limit = 10,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      var query = _supabaseClient
          .from('sales_invoices')
          .select('*, customers!inner(name), sales_invoice_items(*)')
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .eq('customers.is_active', true);

      if (status != null && status != 'all') {
        query = query.eq('payment_status', status);
      }
      if (dateFrom != null) {
        query = query.gte('invoice_date', dateFrom.toIso8601String());
      }
      if (dateTo != null) {
        query = query.lte('invoice_date', dateTo.toIso8601String());
      }
      final term = search?.trim();
      if (term != null && term.isNotEmpty) {
        final safe = term.replaceAll(',', ' ');
        query = query.or(
          'invoice_number.ilike.%$safe%,customers.name.ilike.%$safe%',
        );
      }

      final response = await query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .range(offset, offset + limit);

      final rows = response.map(_mapJsonToSalesInvoice).toList();
      final hasMore = rows.length > limit;
      return PagedResult(
        items: hasMore ? rows.sublist(0, limit) : rows,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception('Failed to load sales invoices: $e');
    }
  }

  @override
  Future<PagedResult<PurchaseInvoice>> getPurchaseInvoicesPage({
    required int offset,
    int limit = 10,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) throw Exception('User not logged in');

      var query = _supabaseClient
          .from('purchase_invoices')
          .select('*, suppliers(name), purchase_invoice_items(*)')
          .eq('user_id', userId)
          .isFilter('deleted_at', null);

      if (status != null && status != 'all') {
        query = query.eq('payment_status', status);
      }
      if (dateFrom != null) {
        query = query.gte('invoice_date', dateFrom.toIso8601String());
      }
      if (dateTo != null) {
        query = query.lte('invoice_date', dateTo.toIso8601String());
      }
      final term = search?.trim();
      if (term != null && term.isNotEmpty) {
        final safe = term.replaceAll(',', ' ');
        query = query.or(
          'invoice_number.ilike.%$safe%,suppliers.name.ilike.%$safe%',
        );
      }

      final response = await query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .range(offset, offset + limit);

      final rows = response.map(_mapJsonToPurchaseInvoice).toList();
      final hasMore = rows.length > limit;
      return PagedResult(
        items: hasMore ? rows.sublist(0, limit) : rows,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception('Failed to load purchase invoices: $e');
    }
  }

  @override
  Future<SalesInvoice> getSalesInvoiceById(String id) async {
    try {
      final response = await _supabaseClient
          .from('sales_invoices')
          .select('*, customers(name), sales_invoice_items(*)')
          .eq('id', id)
          .single();

      return _mapJsonToSalesInvoice(response);
    } catch (e) {
      throw Exception('Failed to load sales invoice: $e');
    }
  }

  @override
  Future<PurchaseInvoice> getPurchaseInvoiceById(String id) async {
    try {
      final response = await _supabaseClient
          .from('purchase_invoices')
          .select('*, suppliers(name), purchase_invoice_items(*)')
          .eq('id', id)
          .single();

      return _mapJsonToPurchaseInvoice(response);
    } catch (e) {
      throw Exception('Failed to load purchase invoice: $e');
    }
  }

  @override
  Future<SalesInvoice> createSalesInvoice(SalesInvoice invoice) async {
    try {
      final invoiceData = invoice.toJson();

      invoiceData.remove('created_at');
      invoiceData.remove('updated_at');
      invoiceData.remove('customer_name');
      invoiceData.remove('items');

      final response = await _supabaseClient
          .from('sales_invoices')
          .insert(invoiceData)
          .select('*, customers(name)')
          .single();

      List<Map<String, dynamic>> itemsData = [];
      if (invoice.items.isNotEmpty) {
        itemsData = invoice.items
            .map(
              (item) => {
                'invoice_id': response['id'],
                'product_id': item.productId ?? 'null_data',
                'product_name': item.productName ?? 'null_data',
                'quantity': item.quantity ?? 0,
                'unit_price': item.unitPrice?.toDouble() ?? 0.0,
                'purchase_price': item.purchasePrice?.toDouble() ?? 0.0,
                'discount_amount': item.discountAmount?.toDouble() ?? 0.0,
                'total_price': item.totalPrice?.toDouble() ?? 0.0,
                'measurement': item.measurement ?? 'null_data',
                'unit': item.unit ?? 'null_data',
              },
            )
            .toList();

        await _supabaseClient.from('sales_invoice_items').insert(itemsData);
      }

      log('Stock şimdilik donduruldu - Invoice status = ${invoice.status}');

      final completeInvoice = Map<String, dynamic>.from(response);
      completeInvoice['items'] = itemsData;

      return _mapJsonToSalesInvoice(completeInvoice);
    } catch (e) {
      log(e.toString());
      throw Exception('Failed to create sales invoice: $e');
    }
  }

  @override
  Future<PurchaseInvoice> createPurchaseInvoice(PurchaseInvoice invoice) async {
    try {
      final invoiceData = invoice.toJson();
      invoiceData.remove('id');
      invoiceData.remove('created_at');
      invoiceData.remove('updated_at');
      invoiceData.remove('supplier_name');
      invoiceData.remove('items');

      final response = await _supabaseClient
          .from('purchase_invoices')
          .insert(invoiceData)
          .select('*, suppliers!inner(name)')
          .single();

      List<Map<String, dynamic>> itemsData = [];
      if (invoice.items.isNotEmpty) {
        itemsData = invoice.items
            .map(
              (item) => {
                'invoice_id': response['id'],
                'product_id': item.productId ?? 'null_data',
                'product_name': item.productName ?? 'null_data',
                'quantity': item.quantity ?? 0,
                'unit_price': item.unitPrice?.toDouble() ?? 0.0,
                'purchase_price': item.purchasePrice?.toDouble() ?? 0.0,
                'total_price': item.totalPrice?.toDouble() ?? 0.0,
                'measurement': item.measurement ?? 'null_data',
                'unit': item.unit ?? 'null_data',
              },
            )
            .toList();

        log(
          'Inserting ${itemsData.length} purchase invoice items for invoice ${response['id']}',
        );
        await _supabaseClient.from('purchase_invoice_items').insert(itemsData);
        log('Purchase invoice items inserted successfully');
      }

      log('Stock şimdilik donduruldu - Creating purchase invoice');

      final completeInvoice = Map<String, dynamic>.from(response);
      completeInvoice['items'] = itemsData;

      return _mapJsonToPurchaseInvoice(completeInvoice);
    } catch (e) {
      log('Failed to create purchase invoice: $e');
      throw Exception('Failed to create purchase invoice: $e');
    }
  }

  @override
  Future<SalesInvoice> updateSalesInvoice(SalesInvoice invoice) async {
    try {
      final oldInvoice = await getSalesInvoiceById(invoice.id);
      final oldStatus = oldInvoice.status;
      final newStatus = invoice.status;

      final invoiceData = invoice.toJson();
      invoiceData.remove('created_at');
      invoiceData.remove('customer_name');
      invoiceData.remove('items');

      final response = await _supabaseClient
          .from('sales_invoices')
          .update(invoiceData)
          .eq('id', invoice.id)
          .select('*, customers(name)')
          .single();

      // Stock şimdilik donduruldu
      // if (oldStatus != newStatus) {
      //   await _stockService.handleStatusChange(
      //     newStatus: newStatus,
      //     oldStatus: oldStatus,
      //     items: invoice.items,
      //     isPurchase: false,
      //     invoiceId: invoice.id,
      //   );
      // }

      return _mapJsonToSalesInvoice(response);
    } catch (e) {
      throw Exception('Failed to update sales invoice: $e');
    }
  }

  @override
  Future<PurchaseInvoice> updatePurchaseInvoice(PurchaseInvoice invoice) async {
    try {
      final oldInvoice = await getPurchaseInvoiceById(invoice.id);
      final oldStatus = oldInvoice.status;
      final newStatus = invoice.status;

      final invoiceData = invoice.toJson();
      invoiceData.remove('created_at');
      invoiceData.remove('supplier_name');
      invoiceData.remove('items');

      final response = await _supabaseClient
          .from('purchase_invoices')
          .update(invoiceData)
          .eq('id', invoice.id)
          .select('*, suppliers(name)')
          .single();

      // Stock şimdilik donduruldu
      // if (oldStatus != newStatus) {
      //   await _stockService.handleStatusChange(
      //     newStatus: newStatus,
      //     oldStatus: oldStatus,
      //     items: invoice.items,
      //     isPurchase: true,
      //     invoiceId: invoice.id,
      //   );
      // }

      return _mapJsonToPurchaseInvoice(response);
    } catch (e) {
      throw Exception('Failed to update purchase invoice: $e');
    }
  }

  @override
  Future<void> deleteSalesInvoice(String id) async {
    try {
      final oldInvoice = await getSalesInvoiceById(id);
      
      // Stock şimdilik donduruldu
      // if (oldInvoice.status == InvoiceStatus.completed) {
      //   await _stockService.reverseInvoiceStock(
      //     items: oldInvoice.items,
      //     isPurchase: false,
      //     invoiceId: id,
      //   );
      // }

      await _supabaseClient
          .from('sales_invoice_items')
          .delete()
          .eq('invoice_id', id);
      await _supabaseClient.from('sales_invoices').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete sales invoice: $e');
    }
  }

  @override
  Future<void> deletePurchaseInvoice(String id) async {
    try {
      final oldInvoice = await getPurchaseInvoiceById(id);
      
      // Stock şimdilik donduruldu
      // if (oldInvoice.status == InvoiceStatus.completed) {
      //   await _stockService.reverseInvoiceStock(
      //     items: oldInvoice.items,
      //     isPurchase: true,
      //     invoiceId: id,
      //   );
      // }

      await _supabaseClient
          .from('purchase_invoice_items')
          .delete()
          .eq('invoice_id', id);
      await _supabaseClient.from('purchase_invoices').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete purchase invoice: $e');
    }
  }

  @override
  Future<void> finalizeSalesInvoice(String id) async {
    try {
      // إنهاء فاتورة البيع - قاعدة البيانات ستتعامل مع الباقي تلقائياً
      await _supabaseClient
          .from('sales_invoices')
          .update({'is_finalized': true})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to finalize sales invoice: $e');
    }
  }

  @override
  Future<void> finalizePurchaseInvoice(String id) async {
    try {
      // إنهاء فاتورة الشراء - قاعدة البيانات ستتعامل مع الباقي تلقائياً
      await _supabaseClient
          .from('purchase_invoices')
          .update({'is_finalized': true})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to finalize purchase invoice: $e');
    }
  }

  @override
  Future<void> updateCustomerBalance(String customerId, double amount) async {
    try {
      // تحديث رصيد العميل باستخدام دالة قاعدة البيانات
      await _supabaseClient.rpc(
        'update_customer_balance',
        params: {'p_customer_id': customerId, 'p_amount': amount},
      );
    } catch (e) {
      throw Exception('Failed to update customer balance: $e');
    }
  }

  // تحويل JSON إلى كائن فاتورة بيع
  SalesInvoice _mapJsonToSalesInvoice(Map<String, dynamic> json) {
    final invoiceJson = Map<String, dynamic>.from(json);

    // استخراج اسم العميل
    if (json['customers'] != null) {
      invoiceJson['customer_name'] = json['customers']['name'];
    }

    // استخراج عناصر الفاتورة
    if (json['sales_invoice_items'] != null) {
      invoiceJson['items'] = json['sales_invoice_items'];
    }

    invoiceJson.remove('customers');
    invoiceJson.remove('sales_invoice_items');

    return SalesInvoice.fromJson(invoiceJson);
  }

  // تحويل JSON إلى كائن فاتورة شراء
  PurchaseInvoice _mapJsonToPurchaseInvoice(Map<String, dynamic> json) {
    final invoiceJson = Map<String, dynamic>.from(json);

    // استخراج اسم المورد
    if (json['suppliers'] != null) {
      invoiceJson['supplier_name'] = json['suppliers']['name'];
    }

    // استخراج عناصر الفاتورة
    if (json['purchase_invoice_items'] != null) {
      invoiceJson['items'] = json['purchase_invoice_items'];
    }

    invoiceJson.remove('suppliers');
    invoiceJson.remove('purchase_invoice_items');

    return PurchaseInvoice.fromJson(invoiceJson);
  }
}
