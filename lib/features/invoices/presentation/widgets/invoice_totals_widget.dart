import 'package:erad/core/utils/app_utils.dart';
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
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildTotalRow(
            label: 'المجموع الفرعي',
            value: subtotal,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          _buildTotalRow(
            label: 'الخصم',
            value: discount,
            color: AppColors.error,
            isDiscount: true,
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          _buildTotalRow(
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
                fontSize: isLarge
                    ? AppFonts.fontSizeMedium
                    : AppFonts.fontSizeMedium,
                fontWeight: isLarge
                    ? AppFonts.fontWeightBold
                    : AppFonts.fontWeightRegular,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          '${isDiscount ? '-' : ''}${AppUtils.formatNumber(value)} ${NumberFormatter.getCurrencySymbol()}',
          style: TextStyle(
            fontSize: isLarge
                ? AppFonts.fontSizeXLarge
                : AppFonts.fontSizeMedium,
            fontWeight: isLarge
                ? AppFonts.fontWeightBold
                : AppFonts.fontWeightSemiBold,
            color: color,
          ),
        ),
      ],
    );
  }
}
