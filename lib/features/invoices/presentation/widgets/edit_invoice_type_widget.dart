import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';
import '../bloc/edit_invoice_cubit.dart';

class EditInvoiceTypeWidget extends StatelessWidget {
  final bool isSales;

  const EditInvoiceTypeWidget({super.key, required this.isSales});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: sc.Card(
        padding: const EdgeInsets.all(AppConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(sc.LucideIcons.receiptText, 'معلومات الفاتورة'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isSales 
                    ? AppColors.primary.withValues(alpha: 0.1) 
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(
                  color: isSales ? AppColors.primary : AppColors.warning,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSales ? sc.LucideIcons.trendingUp : sc.LucideIcons.trendingDown,
                    color: isSales ? AppColors.primary : AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isSales ? 'فاتورة مبيعات' : 'فاتورة مشتريات',
                    style: TextStyle(
                      fontWeight: AppFonts.fontWeightSemiBold,
                      color: isSales ? AppColors.primary : AppColors.warning,
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

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.text),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: AppFonts.fontSizeMedium,
            fontWeight: AppFonts.fontWeightSemiBold,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}