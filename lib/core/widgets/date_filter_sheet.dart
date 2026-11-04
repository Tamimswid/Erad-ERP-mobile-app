import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../constants/app_constants.dart';

class DateFilterSheet {
  static Future<void> show({
    required BuildContext context,
    required String? selectedYear,
    required List<String> availableYears,
    required DateTimeRange? customDateRange,
    required bool isCustomDateRange,
    required ValueChanged<String> onYearSelected,
    required ValueChanged<DateTimeRange> onDateRangeSelected,
    required VoidCallback onClearFilter,
    required VoidCallback onDateRangePickerTap,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusLg),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'تصفية البيانات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'اختر السنة أو نطاق تاريخ مخصص',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'السنة',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: availableYears.map((year) {
                            final isSelected = selectedYear == year;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: year != availableYears.last ? 8 : 0,
                                ),
                                child: sc.Clickable(
                                  onPressed: () {
                                    onYearSelected(year);
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.background,
                                      borderRadius: BorderRadius.circular(
                                        AppConstants.borderRadiusMd,
                                      ),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      year,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.onPrimary
                                            : AppColors.text,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: AppColors.divider),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'أو',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: AppColors.divider),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'نطاق تاريخ مخصص',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _DateField(
                                label: 'من',
                                date: customDateRange?.start,
                                onTap: onDateRangePickerTap,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _DateField(
                                label: 'إلى',
                                date: customDateRange?.end,
                                onTap: onDateRangePickerTap,
                              ),
                            ),
                          ],
                        ),
                        if (isCustomDateRange) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: sc.Button(
                              alignment: Alignment.center,
                              style: sc.ButtonStyle.ghost(),
                              onPressed: () {
                                onClearFilter();
                                Navigator.pop(context);
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    sc.LucideIcons.x,
                                    size: 16,
                                    color: AppColors.error,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'إلغاء التصفية',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return sc.Clickable(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              sc.LucideIcons.calendar,
              size: 16,
              color: date != null ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              date != null
                  ? '${date!.day}/${date!.month}/${date!.year}'
                  : label,
              style: TextStyle(
                fontSize: 14,
                color: date != null ? AppColors.text : AppColors.textSecondary,
                fontWeight: date != null ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
