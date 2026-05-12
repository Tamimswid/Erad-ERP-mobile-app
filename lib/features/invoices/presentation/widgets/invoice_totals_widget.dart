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
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.background,
                    AppColors.surface,
                  ],
                ),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildTotalRow(
                    icon: Icons.receipt_long,
                    label: 'المجموع الفرعي',
                    value: subtotal,
                    color: AppColors.textSecondary,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildTotalRow(
                    icon: Icons.percent,
                    label: 'Ýndirim',
                    value: discount,
                    color: AppColors.error,
                    isDiscount: true,
                  ),
                  
                  const SizedBox(height: 16),
                  
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
                  
                  const SizedBox(height: 16),
                  
                  _buildTotalRow(
                    icon: Icons.calculate,
                    label: 'المجموع الإجمالي',
                    value: total,
                    color: AppColors.primary,
                    isLarge: true,
                  ),
                ],
              ),
            ),
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
            Icon(
              icon,
              size: isLarge ? 20 : 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: isLarge ? AppFonts.fontSizeLarge : AppFonts.fontSizeMedium,
                fontWeight: isLarge ? AppFonts.fontWeightBold : AppFonts.fontWeightRegular,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          '${isDiscount ? '-' : ''}${NumberFormatter.getCurrencySymbol()} ${NumberFormatter.format(value)}',
          style: TextStyle(
            fontSize: isLarge ? AppFonts.fontSizeXXXLarge : AppFonts.fontSizeMedium,
            fontWeight: isLarge ? AppFonts.fontWeightBold : AppFonts.fontWeightSemiBold,
            color: color,
          ),
        ),
      ],
    );
  }
}
