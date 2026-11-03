import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';
import '../bloc/dashboard_cubit.dart';

class DateFilterSection extends StatelessWidget {
  const DateFilterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is! DashboardLoaded) {
          return const SizedBox.shrink();
        }

        return sc.Card(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Year Selection
              _buildYearDropdown(context, state),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'أو',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Custom Date Range
              _buildDateRangePicker(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYearDropdown(BuildContext context, DashboardLoaded state) {
    final cubit = context.read<DashboardCubit>();
    final availableYears = cubit.getAvailableYears();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختيار السنة',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: state.selectedYear,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              icon: const Icon(sc.LucideIcons.chevronDown),
              items: availableYears.map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(
                    year,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  cubit.setYear(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangePicker(BuildContext context, DashboardLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نطاق التاريخ المخصص',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateInput(
                context: context,
                label: 'من',
                date: state.customDateRange?.start,
                onTap: () => _showDateRangePicker(context, state),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDateInput(
                context: context,
                label: 'إلى',
                date: state.customDateRange?.end,
                onTap: () => _showDateRangePicker(context, state),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateInput({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              sc.LucideIcons.calendar,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? '${date.day}/${date.month}/${date.year}'
                    : 'mm/dd/yyyy',
                style: TextStyle(
                  fontSize: 14,
                  color: date != null ? AppColors.text : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context, DashboardLoaded state) async {
    final initialDateRange = state.customDateRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      context.read<DashboardCubit>().setCustomDateRange(picked);
    }
  }
}
