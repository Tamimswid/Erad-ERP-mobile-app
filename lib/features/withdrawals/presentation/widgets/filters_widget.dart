import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';

enum PeriodMode { year, custom }

class FiltersWidget extends StatelessWidget {
  final PeriodMode periodMode;
  final ValueChanged<PeriodMode> onPeriodModeChanged;
  final String? selectedYear;
  final ValueChanged<String?> onYearChanged;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final ValueChanged<DateTime?> onDateFromChanged;
  final ValueChanged<DateTime?> onDateToChanged;
  final List<String> availableYears;

  const FiltersWidget({
    super.key,
    required this.periodMode,
    required this.onPeriodModeChanged,
    this.selectedYear,
    required this.onYearChanged,
    this.dateFrom,
    this.dateTo,
    required this.onDateFromChanged,
    required this.onDateToChanged,
    required this.availableYears,
  });

  @override
  Widget build(BuildContext context) {
    return sc.Card(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: 14,
        runSpacing: 14,
        children: [
          _buildPeriodToggle(),
          if (periodMode == PeriodMode.year)
            _buildYearDropdown()
          else
            _buildDateRange(context),
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
          ),
        ),
        const SizedBox(height: 4),
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
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            
            child: DropdownButton<String>(
              padding: EdgeInsets.all(0),
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

  Widget _buildDateRange(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نطاق التاريخ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildDatePicker(
              context: context,
              value: dateFrom,
              hint: 'البداية',
              onChanged: onDateFromChanged,
            ),
            const SizedBox(width: 8),
            _buildDatePicker(
              context: context,
              value: dateTo,
              hint: 'النهاية',
              onChanged: onDateToChanged,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required BuildContext context,
    DateTime? value,
    required String hint,
    required ValueChanged<DateTime?> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value != null
                    ? '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}'
                    : hint,
                style: TextStyle(
                  fontSize: 14,
                  color: value != null ? AppColors.text : AppColors.textSecondary,
                ),
              ),
            ),
            const Icon(
              sc.LucideIcons.calendar,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
