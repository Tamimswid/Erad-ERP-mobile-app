import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';

class SummaryCardsWidget extends StatelessWidget {
  final double totalAmount;
  final int totalCount;
  final double averageAmount;
  final String currencySymbol;

  const SummaryCardsWidget({
    super.key,
    required this.totalAmount,
    required this.totalCount,
    required this.averageAmount,
    this.currencySymbol = '﷼',
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // final isSmall = constraints.maxWidth < 600;
        return GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 3,
          children: [
            _buildCard(
              title: 'المبلغ الإجمالي',
              value: _formatCurrency(totalAmount),
              valueColor: AppColors.primary,
            ),
            _buildCard(
              title: 'عدد السحوبات',
              value: totalCount.toString(),
              valueColor: AppColors.text,
            ),
            _buildCard(
              title: 'المتوسط',
              value: _formatCurrency(averageAmount),
              valueColor: AppColors.text,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'tr_TR');
    return '${formatter.format(amount)} $currencySymbol';
  }
}
