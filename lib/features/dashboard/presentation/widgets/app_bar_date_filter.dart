import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/date_filter_sheet.dart';
import '../bloc/dashboard_cubit.dart';

class AppBarDateFilter extends StatelessWidget {
  const AppBarDateFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is! DashboardLoaded) {
          return const SizedBox.shrink();
        }

        final label = state.isCustomDateRange && state.customDateRange != null
            ? '${state.customDateRange!.start.day}/${state.customDateRange!.start.month} - ${state.customDateRange!.end.day}/${state.customDateRange!.end.month}'
            : state.selectedYear;

        return GestureDetector(
          onTap: () => _showFilterSheet(context, state),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.calendar,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Iconsax.arrow_down_1,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context, DashboardLoaded state) {
    final cubit = context.read<DashboardCubit>();

    DateFilterSheet.show(
      context: context,
      selectedYear: state.selectedYear,
      availableYears: cubit.getAvailableYears(),
      customDateRange: state.customDateRange,
      isCustomDateRange: state.isCustomDateRange,
      onYearSelected: (year) {
        cubit.setYear(year);
      },
      onDateRangeSelected: (range) {
        cubit.setCustomDateRange(range);
      },
      onClearFilter: () {
        cubit.clearCustomDateRange();
      },
      onDateRangePickerTap: () => _pickDateRange(context, cubit, state),
    );
  }

  Future<void> _pickDateRange(
    BuildContext context,
    DashboardCubit cubit,
    DashboardLoaded state,
  ) async {
    final initial = state.customDateRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      cubit.setCustomDateRange(picked);
      Navigator.pop(context);
    }
  }
}
