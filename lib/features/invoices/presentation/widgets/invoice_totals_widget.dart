import 'package:flutter/material.dart';
import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/widgets/common_widgets.dart';
import 'package:erad/core/utils/number_formatter.dart';

class InvoiceTotalsWidget extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double total;

  const InvoiceTotalsWidget({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _buildTotalRow(
            icon: Icons.receipt_long,
            label: 'المجموع الفرعي',
            value: subtotal,
            color: AppColors.textSecondary,
          ),
          
          const SizedBox(height: 6),
          
          _buildTotalRow(
            icon: Icons.percent,
            label: 'الخصم',
            value: discount,
            color: AppColors.error,
            isDiscount: true,
          ),
          
          const SizedBox(height: 8),
          
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.3),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          _buildTotalRow(
            icon: Icons.calculate,
            label: 'المجموع الإجمالي',
            value: total,
            color: AppColors.primary,
            isLarge: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow({
    required IconData icon,
    required String label,
    required double value,
    required Color color,
    bool isDiscount = false,
    bool isLarge = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isLarge ? AppFonts.fontSizeMedium : AppFonts.fontSizeMedium,
                fontWeight: isLarge ? AppFonts.fontWeightBold : AppFonts.fontWeightRegular,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          '${isDiscount ? '-' : ''}${NumberFormatter.getCurrencySymbol()} ${NumberFormatter.format(value)}',
          style: TextStyle(
            fontSize: isLarge ? AppFonts.fontSizeXLarge : AppFonts.fontSizeMedium,
            fontWeight: isLarge ? AppFonts.fontWeightBold : AppFonts.fontWeightSemiBold,
            color: color,
          ),
        ),
      ],
    );
  }
}
