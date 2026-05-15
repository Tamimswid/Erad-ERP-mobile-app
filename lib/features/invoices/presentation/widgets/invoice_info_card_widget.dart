import 'package:erad/core/utils/app_utils.dart';
import 'package:erad/features/invoices/data/models/invoice_item.dart';
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildProductsSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeLarge,
                    fontWeight: AppFonts.fontWeightSemiBold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  invoiceDate,
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${products.length} منتج',
              style: TextStyle(
                fontSize: AppFonts.fontSizeSmall,
                fontWeight: AppFonts.fontWeightMedium,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
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
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Products List
        Column(
          children: products.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            return _buildProductRow(product, index);
          }).toList(),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: index < products.length - 1
            ? const Border(
                bottom: BorderSide(color: AppColors.divider, width: 1),
              )
            : null,
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
