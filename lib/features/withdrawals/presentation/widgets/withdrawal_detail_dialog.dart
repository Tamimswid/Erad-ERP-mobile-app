import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../data/models/withdrawal.dart';
import '../../data/models/partner.dart';

class WithdrawalDetailDialog extends StatelessWidget {
  final Withdrawal withdrawal;
  final Partner? partner;

  const WithdrawalDetailDialog({
    super.key,
    required this.withdrawal,
    this.partner,
  });

  static void show(BuildContext context, Withdrawal withdrawal, Partner? partner) {
    showDialog(
      context: context,
      builder: (context) => WithdrawalDetailDialog(
        withdrawal: withdrawal,
        partner: partner,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final currencySymbol = NumberFormatter.getCurrencySymbol();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'تفاصيل السحب',
                  style: TextStyle(
                    fontSize: AppFonts.fontSizeXLarge,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Amount
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Column(
                children: [
                  const Text(
                    'المبلغ',
                    style: TextStyle(
                      fontSize: AppFonts.fontSizeSmall,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$currencySymbol ${NumberFormatter.format(withdrawal.amount)}',
                    style: const TextStyle(
                      fontSize: AppFonts.fontSizeXXLarge,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Partner
            _buildInfoRow(
              icon: Icons.person,
              label: 'الشريك',
              value: partner?.name ?? '-',
            ),
            const SizedBox(height: 12),

            // Date
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'التاريخ',
              value: dateFormat.format(withdrawal.withdrawalDate),
            ),
            const SizedBox(height: 12),

            // Description
            _buildInfoRow(
              icon: Icons.description,
              label: 'الوصف',
              value: withdrawal.description?.isNotEmpty == true 
                  ? withdrawal.description! 
                  : '-',
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'إغلاق',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: AppFonts.fontSizeSmall,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: AppFonts.fontSizeMedium,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}