import 'package:flutter/material.dart';
import '../../../../core/utils/number_formatter.dart';

class InvoiceStatsWidget extends StatelessWidget {
  final int totalCount;
  final int paidCount;
  final int pendingCount;
  final double totalAmount;

  const InvoiceStatsWidget({
    super.key,
    required this.totalCount,
    required this.paidCount,
    required this.pendingCount,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        childAspectRatio: 3,
        children: [
          _buildStatCard(
            context,
            'الاجمالي',
            totalCount.toString(),
            Icons.description,
            const Color(0xFF1D4ED8),
            const Color(0xFFEFF6FF),
          ),
          _buildStatCard(
            context,
            'المدفوع',
            paidCount.toString(),
            Icons.check_circle,
            const Color(0xFF1D4ED8),
            const Color(0xFFEFF6FF),
          ),
          _buildStatCard(
            context,
            'المعلق',
            pendingCount.toString(),
            Icons.access_time_filled,
            const Color(0xFF1D4ED8),
            const Color(0xFFF0F9FF),
          ),
          _buildStatCard(
            context,
            'الاجمالي المبلغ',
            '${totalAmount.toStringAsFixed(2)} ${NumberFormatter.getCurrencySymbol()}',
            Icons.account_balance_wallet,
            const Color(0xFF1D4ED8),
            const Color(0xFFEFF6FF),
            isAmount: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color backgroundColor, {
    bool isAmount = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.bold,
                    fontSize: isAmount ? 18 : 24,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
