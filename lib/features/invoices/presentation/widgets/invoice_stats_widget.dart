import 'package:erad/core/constants/app_constants.dart';
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
    return Row(
      children: [
        // _buildStatCard(
        //   context,
        //   'الاجمالي',
        //   totalCount.toString(),
        //   Icons.description,
        //   const Color(0xFF1D4ED8),
        //   const Color(0xFFEFF6FF),
        // ),
        _buildStatCard(
          context,
          'الاجمالي المبلغ',
          '$totalAmount',
          NumberFormatter.getCurrencySymbol(),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String currencySymbol,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
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
                      color: AppColors.surface,
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    currencySymbol,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w200,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
