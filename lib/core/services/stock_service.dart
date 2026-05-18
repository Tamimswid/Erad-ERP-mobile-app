import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:erad/core/services/user_service.dart';
import 'package:erad/features/invoices/data/models/invoice_status.dart';
import 'package:erad/features/invoices/data/models/invoice_item.dart';
import 'package:erad/features/stock/data/models/stock_movement.dart';

class StockService {
  final SupabaseClient _client;

  StockService(this._client);

  Future<String?> _getInvoiceStatus(String invoiceId, bool isPurchase) async {
    try {
      final table = isPurchase ? 'purchase_invoices' : 'sales_invoices';
      final result = await _client
          .from(table)
          .select('status')
          .eq('id', invoiceId)
          .maybeSingle();
      return result?['status'] as String?;
    } catch (e) {
      log('StockService: Error getting invoice status - $e');
      return null;
    }
  }

  Future<bool> _isInvoiceValidForStock(String invoiceId, bool isPurchase) async {
    final status = await _getInvoiceStatus(invoiceId, isPurchase);
    if (status == null) return false;
    
    final invoiceStatus = InvoiceStatus.values.firstWhere(
      (e) => e.name == status.toLowerCase(),
      orElse: () => InvoiceStatus.pending,
    );
    
    return invoiceStatus != InvoiceStatus.cancelled;
  }

  Future<void> _recordMovement({
    required String productId,
    required int quantityChange,
    required int previousStock,
    required int newStock,
    required StockMovementType type,
    String? referenceId,
    String? referenceType,
    double? unitPrice,
    String? notes,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        log('StockService: userId is null, skipping movement');
        return;
      }

      final movementData = {
        'user_id': userId,
        'product_id': productId,
        'movement_type': type.name,
        'reference_id': referenceId,
        'reference_type': referenceType,
        'quantity_change': quantityChange,
        'previous_stock': previousStock,
        'new_stock': newStock,
        'unit_price': unitPrice,
        'notes': notes,
      };

      log('StockService: Recording movement - $movementData');
      await _client.from('stock_movements').insert(movementData);
      log('StockService: Movement recorded successfully');
    } catch (e, stackTrace) {
      log('StockService: Error recording movement - $e');
      log('StockService: Stack trace - $stackTrace');
    }
  }

  Future<void> _updateProductStock(String productId, int newStock) async {
    await _client
        .from('products')
        .update({'current_stock': newStock})
        .eq('id', productId);
  }

  Future<int> _getProductCurrentStock(String productId) async {
    final result = await _client
        .from('products')
        .select('current_stock')
        .eq('id', productId)
        .single();
    return result['current_stock'] as int? ?? 0;
  }

  Future<void> applyInvoiceStock({
    required List<InvoiceItem> items,
    required bool isPurchase,
    required String invoiceId,
    double? invoiceCreatedAt,
  }) async {
    log('StockService.applyInvoiceStock called - isPurchase: $isPurchase, invoiceId: $invoiceId, items: ${items.length}');
    
    if (items.isEmpty) {
      log('StockService.applyInvoiceStock: No items to process');
      return;
    }
    
    try {
      for (final item in items) {
        if (item.productId == null) {
          log('StockService: Skipping item with null productId');
          continue;
        }

        log('StockService: Processing item - productId: ${item.productId}, quantity: ${item.quantity}');

        final previousStock = await _getProductCurrentStock(item.productId!);
        final quantityChange = isPurchase ? item.quantity : -item.quantity;
        final newStock = previousStock + quantityChange;

        log('StockService: Updating product ${item.productId} stock from $previousStock to $newStock (change: $quantityChange)');

        await _updateProductStock(item.productId!, newStock);

        await _recordMovement(
          productId: item.productId!,
          quantityChange: quantityChange,
          previousStock: previousStock,
          newStock: newStock,
          type: isPurchase ? StockMovementType.purchase : StockMovementType.sale,
          referenceId: invoiceId,
          referenceType: isPurchase ? 'purchase_invoice' : 'sales_invoice',
          unitPrice: item.unitPrice,
        );
      }
      
      log('StockService.applyInvoiceStock completed successfully');
    } catch (e, stackTrace) {
      log('StockService.applyInvoiceStock error: $e');
      log('Stack trace: $stackTrace');
    }
  }

  Future<void> reverseInvoiceStock({
    required List<InvoiceItem> items,
    required bool isPurchase,
    required String invoiceId,
  }) async {
    for (final item in items) {
      if (item.productId == null) continue;

      final previousStock = await _getProductCurrentStock(item.productId!);
      final quantityChange = isPurchase ? -item.quantity : item.quantity;
      final newStock = previousStock + quantityChange;

      await _updateProductStock(item.productId!, newStock);

      await _recordMovement(
        productId: item.productId!,
        quantityChange: quantityChange,
        previousStock: previousStock,
        newStock: newStock,
        type: isPurchase ? StockMovementType.returnPurchase : StockMovementType.returnSale,
        referenceId: invoiceId,
        referenceType: isPurchase ? 'purchase_invoice' : 'sales_invoice',
        notes: 'تم التراجع عن الفاتورة',
      );
    }
  }

  Future<void> handleStatusChange({
    required InvoiceStatus newStatus,
    required InvoiceStatus? oldStatus,
    required List<InvoiceItem> items,
    required bool isPurchase,
    required String invoiceId,
  }) async {
    log('StockService.handleStatusChange - oldStatus: $oldStatus, newStatus: $newStatus');
    
    final shouldApply = newStatus == InvoiceStatus.completed;
    final shouldReverse = (oldStatus == InvoiceStatus.completed) &&
        (newStatus == InvoiceStatus.cancelled);

    log('StockService: shouldApply: $shouldApply, shouldReverse: $shouldReverse');

    if (shouldApply && !_wasAlreadyCompleted(oldStatus)) {
      log('StockService: Applying stock for completed invoice');
      await applyInvoiceStock(
        items: items,
        isPurchase: isPurchase,
        invoiceId: invoiceId,
      );
    } else if (shouldReverse) {
      log('StockService: Reversing stock for cancelled invoice');
      await reverseInvoiceStock(
        items: items,
        isPurchase: isPurchase,
        invoiceId: invoiceId,
      );
    }
  }

  bool _wasAlreadyCompleted(InvoiceStatus? oldStatus) {
    return oldStatus == InvoiceStatus.completed;
  }

  Future<int> getCalculatedStockForProduct(String productId) async {
    try {
      final movementsResult = await _client
          .from('stock_movements')
          .select('new_stock, reference_id, reference_type')
          .eq('product_id', productId)
          .order('created_at', ascending: true);

      if (movementsResult.isEmpty) {
        final productResult = await _client
            .from('products')
            .select('current_stock')
            .eq('id', productId)
            .maybeSingle();
        return productResult?['current_stock'] as int? ?? 0;
      }

      int calculatedStock = 0;
      
      for (final movement in movementsResult) {
        final referenceId = movement['reference_id'] as String?;
        final referenceType = movement['reference_type'] as String?;
        
        if (referenceId != null && referenceType != null) {
          final isPurchase = referenceType == 'purchase_invoice';
          final isValid = await _isInvoiceValidForStock(referenceId, isPurchase);
          
          if (!isValid) {
            log('StockService: Skipping cancelled invoice movement for product $productId');
            continue;
          }
        }
        
        calculatedStock = movement['new_stock'] as int? ?? calculatedStock;
      }

      return calculatedStock;
    } catch (e) {
      log('StockService.getCalculatedStockForProduct error: $e');
      return 0;
    }
  }

  Future<Map<String, int>> getAllCalculatedStock() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        log('StockService: userId is null');
        return {};
      }

      final products = await _client
          .from('products')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true);

      log('StockService.getAllCalculatedStock: Found ${products.length} products');

      final Map<String, int> stockMap = {};

      for (final product in products) {
        final productId = product['id'] as String;
        try {
          final calculatedStock = await getCalculatedStockForProduct(productId);
          stockMap[productId] = calculatedStock;
        } catch (e) {
          log('StockService: Error calculating stock for $productId: $e');
        }
      }

      log('StockService.getAllCalculatedStock: Returning ${stockMap.length} products with calculated stock');
      return stockMap;
    } catch (e) {
      log('StockService.getAllCalculatedStock error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getStockDiscrepancyReport() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) return {'products': [], 'totalDiscrepancies': 0};

      final products = await _client
          .from('products')
          .select('id, name, current_stock')
          .eq('user_id', userId)
          .eq('is_active', true);

      final List<Map<String, dynamic>> discrepancies = [];

      for (final product in products) {
        final productId = product['id'] as String;
        final storedStock = product['current_stock'] as int? ?? 0;
        final calculatedStock = await getCalculatedStockForProduct(productId);

        if (storedStock != calculatedStock) {
          discrepancies.add({
            'productId': productId,
            'productName': product['name'],
            'storedStock': storedStock,
            'calculatedStock': calculatedStock,
            'difference': calculatedStock - storedStock,
          });
        }
      }

      return {
        'products': discrepancies,
        'totalDiscrepancies': discrepancies.length,
      };
    } catch (e) {
      log('StockService.getStockDiscrepancyReport error: $e');
      return {'products': [], 'totalDiscrepancies': 0};
    }
  }
}