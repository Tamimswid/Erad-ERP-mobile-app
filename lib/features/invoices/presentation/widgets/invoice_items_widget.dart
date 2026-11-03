import 'package:flutter/material.dart';
import 'package:erad/core/constants/app_constants.dart';

class InvoiceItemsWidget extends StatelessWidget {
  final List items;
  final double? invoiceDiscountAmount;

  const InvoiceItemsWidget({super.key, required this.items, this.invoiceDiscountAmount});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('لا توجد صنفات في هذه الفاتورة'),
      );
    }

    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('الصنف', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('السعر', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('الخصم', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        // Table rows
        ...items.map((item) => _buildItemRow(item)).toList(),
      ],
    );
  }

  double _getDiscountAmount(dynamic item) {
    // Check if the item has discountAmount property (SalesInvoiceItem)
    if (item.runtimeType.toString().contains('SalesInvoiceItem')) {
      return item.discountAmount ?? 0.0;
    }
    // For PurchaseInvoiceItem, distribute invoice-level discount
    if (invoiceDiscountAmount != null && items.isNotEmpty) {
      return invoiceDiscountAmount! / items.length;
    }
    return 0.0;
  }

  Widget _buildItemRow(dynamic item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? 'صنف غير محدد',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (item.productCode != null)
                  Text(
                    'SKU: ${item.productCode}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(flex: 1, child: Text('${item.quantity ?? 0}')),
          Expanded(flex: 1, child: Text('${(item.unitPrice ?? 0.0).toStringAsFixed(2)}')),
          Expanded(
            flex: 1,
            child: Text(
              '${_getDiscountAmount(item).toStringAsFixed(2)}',
              style: TextStyle(color: AppColors.error),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${(item.totalPrice ?? 0.0).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
