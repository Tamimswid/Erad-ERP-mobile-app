import 'package:erad/core/utils/app_utils.dart';
import 'package:erad/features/invoices/data/models/invoice_item.dart';
import 'package:erad/features/invoices/data/models/invoice_status.dart';
import 'package:erad/features/invoices/data/models/payment_status.dart';
import 'package:flutter/material.dart';
import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/widgets/common_widgets.dart';
import 'package:erad/core/utils/number_formatter.dart';

class InvoiceInfoCardWidget extends StatelessWidget {
  final String invoiceDate;
  final String customerName;
  final List<InvoiceItem> products;

  const InvoiceInfoCardWidget({
    super.key,
    required this.invoiceDate,
    required this.customerName,
    required this.products,
  });


  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(8),
      child: _buildProductsSection(),
    );
  }





  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'المنتجات',
              style: TextStyle(
                fontSize: AppFonts.fontSizeMedium,
                fontWeight: AppFonts.fontWeightRegular,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '${products.length}',
                style: TextStyle(
                  fontSize: AppFonts.fontSizeSmall,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Table Header
        Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              // border: Border(
              //   bottom: BorderSide(color: AppColors.primary, width: 2),
              // ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'اسم المنتج',
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeSmall,
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'الكمية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeSmall,
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'السعر',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeSmall,
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'الإجمالي',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeSmall,
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
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
            children: products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return _buildProductRow(product, index);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProductRow(InvoiceItem product, int index) {
    final name = product.nameWithMeasurementUnit;
    final quantity = product.quantity;
    final unitPrice = product.unitPrice;
    final total = product.totalPrice;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            style: index == products.length - 1
                ? BorderStyle.none
                : BorderStyle.solid,
            width: 0.5,
          ),
        ),
        color: index % 2 == 0 ? Colors.transparent : AppColors.background,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: TextStyle(
                fontSize: AppFonts.fontSizeSmall,
                fontWeight: AppFonts.fontWeightMedium,
                color: AppColors.text,
              ),
            ),
          ),

          Expanded(
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppFonts.fontSizeSmall,
                fontWeight: AppFonts.fontWeightMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${AppUtils.formatNumber(unitPrice)} ${NumberFormatter.getCurrencySymbol()}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: AppFonts.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${AppUtils.formatNumber(total)} ${NumberFormatter.getCurrencySymbol()} ',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: AppFonts.fontSizeSmall,
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
