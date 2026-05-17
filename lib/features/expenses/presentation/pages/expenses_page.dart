import 'package:erad/features/expenses/data/models/expense.dart';
import 'package:erad/features/expenses/data/models/expense_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/services_locator.dart' as sl;
import '../../../../core/widgets/date_filter_sheet.dart';
import '../bloc/expense_cubit.dart';
import '../widgets/expense_filters_widget.dart';
import '../widgets/expense_form_dialog.dart';
import '../widgets/expense_monthly_chart_widget.dart';
import '../widgets/expense_summary_cards_widget.dart';
import '../widgets/expense_table_widget.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  PeriodMode _periodMode = PeriodMode.year;
  String? _selectedYear = DateTime.now().year.toString();
  DateTimeRange? _customDateRange;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl.sl<ExpenseCubit>(),
      child: _ExpensesPageBody(
        periodMode: _periodMode,
        selectedYear: _selectedYear,
        customDateRange: _customDateRange,
        onPeriodModeChanged: (mode) => setState(() => _periodMode = mode),
        onYearChanged: (year) => setState(() => _selectedYear = year),
        onCustomDateRangeChanged: (range) =>
            setState(() => _customDateRange = range),
        onClearCustomDateRange: () => setState(() => _customDateRange = null),
        availableYears: [
          DateTime.now().year.toString(),
          (DateTime.now().year - 1).toString(),
          (DateTime.now().year - 2).toString(),
        ],
      ),
    );
  }
}

class _ExpensesPageBody extends StatefulWidget {
  final PeriodMode periodMode;
  final String? selectedYear;
  final DateTimeRange? customDateRange;
  final ValueChanged<PeriodMode> onPeriodModeChanged;
  final ValueChanged<String?> onYearChanged;
  final ValueChanged<DateTimeRange?> onCustomDateRangeChanged;
  final VoidCallback onClearCustomDateRange;
  final List<String> availableYears;

  const _ExpensesPageBody({
    required this.periodMode,
    required this.selectedYear,
    required this.customDateRange,
    required this.onPeriodModeChanged,
    required this.onYearChanged,
    required this.onCustomDateRangeChanged,
    required this.onClearCustomDateRange,
    required this.availableYears,
  });

  @override
  State<_ExpensesPageBody> createState() => _ExpensesPageBodyState();
}

class _ExpensesPageBodyState extends State<_ExpensesPageBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final year =
          int.tryParse(widget.selectedYear ?? DateTime.now().year.toString()) ??
          DateTime.now().year;
      context.read<ExpenseCubit>().filterByDateRange(
        DateTime(year, 1, 1),
        DateTime(year, 12, 31),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المصروفات'),
        backgroundColor: AppColors.background,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _ExpensesDateFilter(
            selectedYear: widget.selectedYear,
            customDateRange: widget.customDateRange,
            onYearSelected: (year) {
              widget.onYearChanged(year);
              final yearInt = int.tryParse(year) ?? DateTime.now().year;
              context.read<ExpenseCubit>().filterByDateRange(
                DateTime(yearInt, 1, 1),
                DateTime(yearInt, 12, 31),
              );
            },
            onDateRangeSelected: (range) {
              widget.onCustomDateRangeChanged(range);
              context.read<ExpenseCubit>().filterByDateRange(range.start, range.end);
            },
            onClearFilter: () {
              widget.onClearCustomDateRange();
              widget.onPeriodModeChanged(PeriodMode.year);
              final year = int.tryParse(widget.selectedYear ?? DateTime.now().year.toString()) ?? DateTime.now().year;
              context.read<ExpenseCubit>().filterByDateRange(
                DateTime(year, 1, 1),
                DateTime(year, 12, 31),
              );
            },
          ),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<ExpenseCubit, ExpenseState>(
          listener: (context, state) {
            if (state is ExpenseSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else if (state is ExpenseError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ExpenseInitial || state is ExpenseLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state is ExpensesLoaded) ...[

                    ExpenseSummaryCardsWidget(
                      totalAmount: state.totalAmount,
                      totalCount: state.totalCount,
                      averageAmount: state.averageAmount,
                    ),
                    const SizedBox(height: 12),
                    ExpenseMonthlyChartWidget(
                      expenses: state.expenses,
                      year: _getSelectedYear(),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryChips(context, state),
                    const SizedBox(height: 12),
                    ExpenseTableWidget(
                      expenses: state.expenses,
                      categories: state.categories,
                      onDelete: (expense) => context
                          .read<ExpenseCubit>()
                          .deleteExpense(expense.id),
                      onTap: (expense) {},
                    ),
                  ] else if (state is ExpenseLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final categories = context.watch<ExpenseCubit>().categories;
          return FloatingActionButton.extended(
            label: Text('مصروف',style: TextStyle(color: AppColors.surface),)  ,
            onPressed: () => _showAddExpenseDialog(
              context: context,
              onTap: (expense) {
                context.read<ExpenseCubit>().createExpense(expense);
              },
              categories: categories,
            ),
            backgroundColor: AppColors.primary,
          
          );
        },
      ),
    );
  }

  int _getSelectedYear() {
    return int.tryParse(
          widget.selectedYear ?? DateTime.now().year.toString(),
        ) ??
        DateTime.now().year;
  }

  Widget _buildCategoryChips(BuildContext context, ExpensesLoaded state) {
    final cubit = context.read<ExpenseCubit>();
    final categories = cubit.categories;
    final selectedCategory = cubit.selectedCategoryId;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip(
            label: 'الكل',
            isSelected: selectedCategory == null,
            onTap: () => cubit.setCategoryFilter(null),
          ),
          const SizedBox(width: 8),
          ...categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                label: category.name,
                isSelected: selectedCategory == category.id,
                onTap: () => cubit.setCategoryFilter(category.id),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddExpenseDialog({
    required BuildContext context,
    required Function(Expense expense) onTap,
    required List<ExpenseCategory> categories,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => ExpenseFormDialog(
        categories: categories,
        onSubmit: (expense) => onTap(expense),
      ),
    );
  }

}

class _ExpensesDateFilter extends StatelessWidget {
  final String? selectedYear;
  final DateTimeRange? customDateRange;
  final ValueChanged<String> onYearSelected;
  final ValueChanged<DateTimeRange> onDateRangeSelected;
  final VoidCallback onClearFilter;

  const _ExpensesDateFilter({
    required this.selectedYear,
    required this.customDateRange,
    required this.onYearSelected,
    required this.onDateRangeSelected,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final label = customDateRange != null
        ? '${customDateRange!.start.day}/${customDateRange!.start.month} - ${customDateRange!.end.day}/${customDateRange!.end.month}'
        : (selectedYear ?? DateTime.now().year.toString());

    return GestureDetector(
      onTap: () => _showSheet(context),
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
              Icons.calendar_today,
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
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    final now = DateTime.now();
    final availableYears = [
      now.year.toString(),
      (now.year - 1).toString(),
      (now.year - 2).toString(),
    ];

    DateFilterSheet.show(
      context: context,
      selectedYear: selectedYear,
      availableYears: availableYears,
      customDateRange: customDateRange,
      isCustomDateRange: customDateRange != null,
      onYearSelected: onYearSelected,
      onDateRangeSelected: onDateRangeSelected,
      onClearFilter: onClearFilter,
      onDateRangePickerTap: () => _pickDateRange(context),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final initial = customDateRange ?? DateTimeRange(
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
      onDateRangeSelected(picked);
      Navigator.pop(context);
    }
  }
}
