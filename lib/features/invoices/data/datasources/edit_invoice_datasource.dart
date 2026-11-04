import 'dart:async';
import 'package:erad/features/invoices/data/models/sales_invoice.dart';
import 'package:erad/features/invoices/data/models/purchase_invoice.dart';
import 'package:erad/features/invoices/data/models/invoice_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class EditInvoiceDataSource {
  Future<SalesInvoice> getSalesInvoiceForEdit(String id);
  Future<PurchaseInvoice> getPurchaseInvoiceForEdit(String id);
  Future<SalesInvoice> updateSalesInvoice(
    SalesInvoice invoice,
    List<InvoiceItem> newItems,
  );
  Future<PurchaseInvoice> updatePurchaseInvoice(
    PurchaseInvoice invoice,
    List<InvoiceItem> newItems,
  );
  Future<void> updateCustomerBalance(String customerId, double amount);
  Future<void> updateSupplierBalance(String supplierId, double amount);
}

class EditInvoiceDataSourceImpl implements EditInvoiceDataSource {
  final SupabaseClient _supabaseClient;

  EditInvoiceDataSourceImpl(this._supabaseClient);

  @override
  Future<SalesInvoice> getSalesInvoiceForEdit(String id) async {
    try {
      final response = await _supabaseClient
          .from('sales_invoices')
          .select('*, customers(id, name), sales_invoice_items(*)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        throw Exception('Invoice not found');
      }

      final invoiceJson = Map<String, dynamic>.from(response);

      if (response['customers'] != null) {
        invoiceJson['customer_id'] = response['customers']['id'];
        invoiceJson['customer_name'] = response['customers']['name'];
      }

      if (response['sales_invoice_items'] != null) {
        invoiceJson['items'] = response['sales_invoice_items'];
      }

      invoiceJson.remove('customers');
      invoiceJson.remove('sales_invoice_items');

      return SalesInvoice.fromJson(invoiceJson);
    } catch (e) {
      throw Exception('Failed to load sales invoice for edit: $e');
    }
  }

  @override
  Future<PurchaseInvoice> getPurchaseInvoiceForEdit(String id) async {
    try {
      final response = await _supabaseClient
          .from('purchase_invoices')
          .select('*, suppliers(id, name), purchase_invoice_items(*)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        throw Exception('Invoice not found');
      }

      final invoiceJson = Map<String, dynamic>.from(response);

      if (response['suppliers'] != null) {
        invoiceJson['supplier_id'] = response['suppliers']['id'];
        invoiceJson['supplier_name'] = response['suppliers']['name'];
      }

      if (response['purchase_invoice_items'] != null) {
        invoiceJson['items'] = response['purchase_invoice_items'];
      }

      invoiceJson.remove('suppliers');
      invoiceJson.remove('purchase_invoice_items');

      return PurchaseInvoice.fromJson(invoiceJson);
    } catch (e) {
      throw Exception('Failed to load purchase invoice for edit: $e');
    }
  }

  @override
  Future<SalesInvoice> updateSalesInvoice(
    SalesInvoice invoice,
    List<InvoiceItem> newItems,
  ) async {
    try {
      final oldInvoice = await getSalesInvoiceForEdit(invoice.id);
      final oldItems = _salesItemRows(invoice.id, oldInvoice.items);

      final invoiceData = invoice.toJson();
      invoiceData.remove('created_at');
      invoiceData.remove('customer_name');
      invoiceData.remove('items');

      await _supabaseClient
          .from('sales_invoices')
          .update(invoiceData)
          .eq('id', invoice.id);

      await _supabaseClient
          .from('sales_invoice_items')
          .delete()
          .eq('invoice_id', invoice.id);

      try {
        final itemsData = _salesItemRows(invoice.id, newItems);
        if (itemsData.isNotEmpty) {
          await _supabaseClient.from('sales_invoice_items').insert(itemsData);
        }
      } catch (e) {
        // Keep the invoice consistent if the item list could not be written.
        await _restoreSalesInvoice(invoice.id, oldInvoice, oldItems);
        rethrow;
      }

      // Stock şimdilik donduruldu
      // if (oldStatus != newStatus) {
      //   await _stockService.handleStatusChange(
      //     newStatus: newStatus,
      //     oldStatus: oldStatus,
      //     items: newItems,
      //     isPurchase: false,
      //     invoiceId: invoice.id,
      //   );
      // }

      final updatedInvoice = await getSalesInvoiceForEdit(invoice.id);
      return updatedInvoice;
    } catch (e) {
      throw Exception('Failed to update sales invoice: $e');
    }
  }

  @override
  Future<PurchaseInvoice> updatePurchaseInvoice(
    PurchaseInvoice invoice,
    List<InvoiceItem> newItems,
  ) async {
    try {
      final oldInvoice = await getPurchaseInvoiceForEdit(invoice.id);
      final oldItems = _purchaseItemRows(invoice.id, oldInvoice.items);

      final invoiceData = invoice.toJson();
      invoiceData.remove('id');
      invoiceData.remove('created_at');
      invoiceData.remove('supplier_name');
      invoiceData.remove('items');

      await _supabaseClient
          .from('purchase_invoices')
          .update(invoiceData)
          .eq('id', invoice.id);

      await _supabaseClient
          .from('purchase_invoice_items')
          .delete()
          .eq('invoice_id', invoice.id);

      try {
        final itemsData = _purchaseItemRows(invoice.id, newItems);
        if (itemsData.isNotEmpty) {
          await _supabaseClient
              .from('purchase_invoice_items')
              .insert(itemsData);
        }
      } catch (e) {
        await _restorePurchaseInvoice(invoice.id, oldInvoice, oldItems);
        rethrow;
      }

      // Stock şimdilik donduruldu
      // if (oldStatus != newStatus) {
      //   await _stockService.handleStatusChange(
      //     newStatus: newStatus,
      //     oldStatus: oldStatus,
      //     items: newItems,
      //     isPurchase: true,
      //     invoiceId: invoice.id,
      //   );
      // }

      final updatedInvoice = await getPurchaseInvoiceForEdit(invoice.id);
      return updatedInvoice;
    } catch (e) {
      throw Exception('Failed to update purchase invoice: $e');
    }
  }

  List<Map<String, dynamic>> _salesItemRows(
    String invoiceId,
    List<InvoiceItem> items,
  ) {
    return items
        .map(
          (item) => {
            'invoice_id': invoiceId,
            'product_id': item.productId,
            'product_name': item.productName ?? '',
            'quantity': item.quantity ?? 0,
            'unit_price': item.unitPrice?.toDouble() ?? 0.0,
            'purchase_price': item.purchasePrice?.toDouble() ?? 0.0,
            'discount_amount': item.discountAmount?.toDouble() ?? 0.0,
            'total_price': item.totalPrice?.toDouble() ?? 0.0,
            'measurement': item.measurement ?? '',
            'unit': item.unit ?? '',
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> _purchaseItemRows(
    String invoiceId,
    List<InvoiceItem> items,
  ) {
    return items
        .map(
          (item) => {
            'invoice_id': invoiceId,
            'product_id': item.productId,
            'product_name': item.productName ?? '',
            'quantity': item.quantity ?? 0,
            'unit_price': item.unitPrice?.toDouble() ?? 0.0,
            'purchase_price': item.purchasePrice?.toDouble() ?? 0.0,
            'total_price': item.totalPrice?.toDouble() ?? 0.0,
            'measurement': item.measurement ?? '',
            'unit': item.unit ?? '',
          },
        )
        .toList();
  }

  Future<void> _restoreSalesInvoice(
    String invoiceId,
    SalesInvoice oldInvoice,
    List<Map<String, dynamic>> oldItems,
  ) async {
    try {
      final header = oldInvoice.toJson()
        ..remove('created_at')
        ..remove('customer_name')
        ..remove('items');
      await _supabaseClient
          .from('sales_invoices')
          .update(header)
          .eq('id', invoiceId);
    } catch (_) {}
    if (oldItems.isEmpty) return;
    try {
      await _supabaseClient.from('sales_invoice_items').insert(oldItems);
    } catch (_) {}
  }

  Future<void> _restorePurchaseInvoice(
    String invoiceId,
    PurchaseInvoice oldInvoice,
    List<Map<String, dynamic>> oldItems,
  ) async {
    try {
      final header = oldInvoice.toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('supplier_name')
        ..remove('items');
      await _supabaseClient
          .from('purchase_invoices')
          .update(header)
          .eq('id', invoiceId);
    } catch (_) {}
    if (oldItems.isEmpty) return;
    try {
      await _supabaseClient.from('purchase_invoice_items').insert(oldItems);
    } catch (_) {}
  }

  @override
  Future<void> updateCustomerBalance(String customerId, double amount) async {
    try {
      await _supabaseClient.rpc(
        'update_customer_balance',
        params: {'p_customer_id': customerId, 'p_amount': amount},
      );
    } catch (e) {
      throw Exception('Failed to update customer balance: $e');
    }
  }

  @override
  Future<void> updateSupplierBalance(String supplierId, double amount) async {
    try {
      await _supabaseClient.rpc(
        'update_supplier_balance',
        params: {'p_supplier_id': supplierId, 'p_amount': amount},
      );
    } catch (e) {
      throw Exception('Failed to update supplier balance: $e');
    }
  }
}
