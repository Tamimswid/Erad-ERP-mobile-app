import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';

enum PeriodMode { year, custom }

class ExpenseFiltersWidget extends StatelessWidget {
  final PeriodMode periodMode;
  final ValueChanged<PeriodMode> onPeriodModeChanged;
  final String? selectedYear;
  final ValueChanged<String?> onYearChanged;
  final DateTimeRange? customDateRange;
  final VoidCallback onDateRangeTap;
  final List<String> availableYears;

  const ExpenseFiltersWidget({
    super.key,
    required this.periodMode,
    required this.onPeriodModeChanged,
    this.selectedYear,
    required this.onYearChanged,
    this.customDateRange,
    required this.onDateRangeTap,
    required this.availableYears,
  });

  @override
  Widget build(BuildContext context) {
    return sc.Card(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 14,
        runSpacing: 14,
        children: [
          _buildPeriodToggle(),
          if (periodMode == PeriodMode.year)
            _buildYearDropdown()
          else
            _buildDateRangeDisplay(),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الفترة',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleButton(
                label: 'سنة',
                isActive: periodMode == PeriodMode.year,
                onTap: () => onPeriodModeChanged(PeriodMode.year),
              ),
              _buildToggleButton(
                label: 'مخصص',
                isActive: periodMode == PeriodMode.custom,
                onTap: () => onPeriodModeChanged(PeriodMode.custom),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isActive ? AppColors.onPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildYearDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'السنة',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              padding: EdgeInsets.zero,
              value: selectedYear ?? availableYears.firstOrNull,
              items: availableYears.map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(
                    year,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: onYearChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نطاق التاريخ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        // CustomDateRangePicker.buildDateRangeDisplay(
        //   dateRange: customDateRange,
        //   onTap: onDateRangeTap,
        //   placeholder: 'اختر نطاق التاريخ',
        // ),
      ],
    );
  }
}
