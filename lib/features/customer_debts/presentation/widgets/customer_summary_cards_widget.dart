import 'package:erad/core/constants/app_constants.dart';
import 'package:erad/core/utils/app_utils.dart';
import 'package:erad/core/utils/number_formatter.dart';
import 'package:flutter/material.dart';

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
    final currencySymbol = NumberFormatter.getCurrencySymbol();
    
    return Column(
      children: [
        // Top row - Total Invoices and Paid
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'إجمالي',
                '${AppUtils.formatNumber(totalInvoices)} $currencySymbol',        
                Icons.receipt_long_outlined,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'المدفوع',
                '${AppUtils.formatNumber(totalPaid)} $currencySymbol',
                Icons.payment_outlined,
                AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bottom row - Remaining debt
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: remainingDebt > 0 
                ? AppColors.error.withValues(alpha: 0.1) 
                : AppColors.success.withValues(alpha: 0.1),
            border: Border.all(
              color: remainingDebt > 0 
                  ? AppColors.error.withValues(alpha: 0.3) 
                  : AppColors.success.withValues(alpha: 0.3)
            ),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المتبقي',
                style: TextStyle(
                  fontSize: AppFonts.fontSizeMedium,
                  fontWeight: AppFonts.fontWeightSemiBold,
                  color: AppColors.text,
                ),
              ),
              Text(
                '${AppUtils.formatNumber(remainingDebt)} $currencySymbol',
                style: TextStyle(
                  fontSize: AppFonts.fontSizeXLarge,
                  fontWeight: AppFonts.fontWeightBold,
                  color: remainingDebt > 0 ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppFonts.fontSizeSmall,
                  fontWeight: AppFonts.fontWeightMedium,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
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
