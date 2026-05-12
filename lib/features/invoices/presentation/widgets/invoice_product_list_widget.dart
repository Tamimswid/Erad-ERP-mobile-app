import 'package:erad/features/invoices/data/models/invoice_item.dart';
import 'package:flutter/material.dart';
import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/app_utils.dart';
import 'package:erad/core/utils/number_formatter.dart';

class InvoiceProductListWidget extends StatelessWidget {
  final List<InvoiceItem> items;

  const InvoiceProductListWidget({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.inventory_2, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              'Products',
              style: TextStyle(
                fontSize: AppFonts.fontSizeMedium,
                fontWeight: AppFonts.fontWeightSemiBold,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${items.length}',
                style: TextStyle(
                  fontSize: AppFonts.fontSizeSmall,
                  fontWeight: AppFonts.fontWeightSemiBold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Table Header
        Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Product Name',
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeMedium,
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Quantity',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeMedium,
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Unit Price',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeMedium,
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Total',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeMedium,
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Products List
        Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: Border(
              left: BorderSide(color: AppColors.border, width: 0.5),
              right: BorderSide(color: AppColors.border, width: 0.5),
              bottom: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildProductRow(item, index);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProductRow(InvoiceItem item, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            style: index == items.length - 1
                ? BorderStyle.none
                : BorderStyle.solid,
            width: 0.5,
          ),
        ),
        color: index % 2 == 0 ? Colors.transparent : AppColors.background,
      ),
      child: Row(
        children: [
          // Product Name
          Expanded(
            flex: 2,
            child: Text(
              '(${item.unit}) ${item.productName}',
              style: TextStyle(
                fontSize: AppFonts.fontSizeMedium,
                fontWeight: AppFonts.fontWeightMedium,
                color: AppColors.text,
              ),
            ),
          ),

          // Quantity
          Expanded(
            child: Text(
              item.quantity.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFonts.fontSizeMedium,
                fontWeight: AppFonts.fontWeightMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Unit Price
          Expanded(
            child: Text(
              '${AppUtils.formatNumber(item.unitPrice)} ${NumberFormatter.getCurrencySymbol()}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: AppFonts.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Total
          Expanded(
            child: Text(
              '${AppUtils.formatNumber(item.totalPrice)} ${NumberFormatter.getCurrencySymbol()} ',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: AppFonts.fontSizeMedium,
                fontWeight: AppFonts.fontWeightBold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
