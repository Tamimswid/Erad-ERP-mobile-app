import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_formatter.dart';

class ExpenseSummaryCardsWidget extends StatelessWidget {
  final double totalAmount;
  final int totalCount;
  final double averageAmount;

  const ExpenseSummaryCardsWidget({
    super.key,
    required this.totalAmount,
    required this.totalCount,
    required this.averageAmount,
  });

@override
  Widget build(BuildContext context) {
    final currencySymbol = NumberFormatter.getCurrencySymbol();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          spacing: 5,
          children: [
            Expanded(
              child: _buildCard(
                title: 'إجمالي',
                value: '${NumberFormatter.format(totalAmount)} $currencySymbol ',
                valueColor: AppColors.primary,
              ),
            ),
            // Expanded(
            //   child: _buildCard(
            //     title: 'عدد',
            //     value: totalCount.toString(),
            //     valueColor: AppColors.text,
            //   ),
            // ),
            Expanded(
              child: _buildCard(
                title: 'المتوسط',
                value: '${NumberFormatter.format(averageAmount)} $currencySymbol',
                valueColor: AppColors.text,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
