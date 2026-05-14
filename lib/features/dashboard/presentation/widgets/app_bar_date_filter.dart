import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/constants/app_constants.dart';
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

    showModalBottomSheet(
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

                      // Year section
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
                        children: cubit.getAvailableYears().map((year) {
                          final isSelected = state.selectedYear == year;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: year != cubit.getAvailableYears().last ? 8 : 0,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  cubit.setYear(year);
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
                      const Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.divider)),
                          Padding(
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

                      // Custom date range
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
                              date: state.customDateRange?.start,
                              onTap: () => _pickDateRange(context, cubit, state),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DateField(
                              label: 'إلى',
                              date: state.customDateRange?.end,
                              onTap: () => _pickDateRange(context, cubit, state),
                            ),
                          ),
                        ],
                      ),
                      if (state.isCustomDateRange) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              cubit.clearCustomDateRange();
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
              Iconsax.calendar_1,
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
