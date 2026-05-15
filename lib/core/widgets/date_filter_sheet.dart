import 'package:flutter/material.dart';
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.divider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'تصفية البيانات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'اختر السنة أو نطاق تاريخ مخصص',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'السنة',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
                              child: GestureDetector(
                                onTap: () {
                                  onYearSelected(year);
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.divider,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      year,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
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
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.divider)),
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
                          Expanded(child: Divider(color: AppColors.divider)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'نطاق تاريخ مخصص',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
                          child: TextButton.icon(
                            onPressed: () {
                              onClearFilter();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('إلغاء التصفية'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: date != null ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              date != null
                  ? '${date!.day}/${date!.month}/${date!.year}'
                  : label,
              style: TextStyle(
                fontSize: 13,
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
