import 'package:erad/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class DebtTableHeaderWidget extends StatelessWidget {
  const DebtTableHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: Text(
              'الاسم',
              style: TextStyle(
                fontSize: AppFonts.fontSizeMedium,
                fontWeight: AppFonts.fontWeightSemiBold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Text(
              'إجمالي',
              style: TextStyle(
                fontSize: AppFonts.fontSizeMedium,
                fontWeight: AppFonts.fontWeightSemiBold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Text(
              'المدفوع',
              style: TextStyle(
                fontSize: AppFonts.fontSizeMedium,
                fontWeight: AppFonts.fontWeightSemiBold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Text(
              'المتبقي',
              style: TextStyle(
                fontSize: AppFonts.fontSizeMedium,
                fontWeight: AppFonts.fontWeightSemiBold,
                color: AppColors.textSecondary,
              ),
            ),
          ),

        ],
      ),
    );
  }
}
