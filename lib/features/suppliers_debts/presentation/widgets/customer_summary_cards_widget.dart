import 'package:flutter/material.dart';
import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/number_formatter.dart';

class CustomerSummaryCardsWidget extends StatelessWidget {
  final double totalInvoices;
  final double totalPaid;
  final double remainingDebt;

  const CustomerSummaryCardsWidget({
    super.key,
    required this.totalInvoices,
    required this.totalPaid,
    required this.remainingDebt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildCard('إجمالي', totalInvoices, AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _buildCard('المدفوع', totalPaid, AppColors.success)),
        const SizedBox(width: 12),
        Expanded(child: _buildCard('المتبقي', remainingDebt, AppColors.warning)),
      ],
    );
  }

  Widget _buildCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppFonts.fontSizeSmall,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${NumberFormatter.format(amount)} ${NumberFormatter.getCurrencySymbol()}',
            style: TextStyle(
              fontSize: AppFonts.fontSizeLarge,
              fontWeight: AppFonts.fontWeightBold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}