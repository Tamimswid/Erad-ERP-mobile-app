import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

import '../../../../core/constants/app_constants.dart';

/// زر فتح ورقة فلترة الفواتير مع شارة بعدد المجموعات النشطة.
class InvoiceFilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const InvoiceFilterButton({
    super.key,
    required this.activeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = activeCount > 0;

    return Semantics(
      button: true,
      label: isActive
          ? 'فلترة الفواتير، $activeCount فلاتر نشطة'
          : 'فلترة الفواتير',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Icon(
                  sc.LucideIcons.slidersHorizontal,
                  size: 20,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              if (isActive)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$activeCount',
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1,
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
