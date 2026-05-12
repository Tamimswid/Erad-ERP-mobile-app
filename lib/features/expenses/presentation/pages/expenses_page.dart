import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/services_locator.dart' as sl;
import '../../../../core/utils/custom_date_range_picker.dart';
import '../bloc/expense_cubit.dart';
import '../widgets/expense_categories_dialog.dart';
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
  late ExpenseCubit _expenseCubit;
  PeriodMode _periodMode = PeriodMode.year;
  String? _selectedYear;
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    _expenseCubit = sl.sl<ExpenseCubit>();
    _selectedYear = DateTime.now().year.toString();
    // Apply initial year filter after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final year = int.tryParse(_selectedYear!) ?? DateTime.now().year;
      _expenseCubit.filterByDateRange(
        DateTime(year, 1, 1),
        DateTime(year, 12, 31),
      );
    });
  }

  List<String> get _availableYears {
    final currentYear = DateTime.now().year;
    return [
      currentYear.toString(),
      (currentYear - 1).toString(),
      (currentYear - 2).toString(),
    ];
  }

  void _showCustomDateRangePicker() {
    CustomDateRangePicker.showDateRangePicker(
      context: context,
      initialDateRange: _customDateRange,
      onDateRangeChanged: (dateRange) {
        setState(() {
          _customDateRange = dateRange;
        });
        // Apply date filter to cubit
        _expenseCubit.filterByDateRange(dateRange.start, dateRange.end);
      },
    );
  }

  int _getSelectedYear() {
    return int.tryParse(_selectedYear ?? DateTime.now().year.toString()) ?? DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _expenseCubit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocConsumer<ExpenseCubit, ExpenseState>(
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
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state is ExpensesLoaded) ...[
                    // Filters
                    _buildFilters(context, state),
                    const SizedBox(height: 16),
                    // Summary Cards
                    ExpenseSummaryCardsWidget(
                      totalAmount: state.totalAmount,
                      totalCount: state.totalCount,
                      averageAmount: state.averageAmount,
                    ),
                    const SizedBox(height: 16),
                    // Monthly Chart - Show full year with Arabic month names
                    ExpenseMonthlyChartWidget(
                      expenses: state.expenses,
                      year: _getSelectedYear(),
                    ),
                    const SizedBox(height: 16),
                    // Category Chips
                    _buildCategoryChips(context, state),
                    const SizedBox(height: 16),
                    // Expenses Table
                    ExpenseTableWidget(
                      expenses: state.expenses,
                      categories: state.categories,
                      onDelete: (expense) => _expenseCubit.deleteExpense(expense.id),
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
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddExpenseDialog(context),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, ExpensesLoaded state) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ExpenseFiltersWidget(
              periodMode: _periodMode,
              onPeriodModeChanged: (mode) {
                setState(() {
                  _periodMode = mode;
                });
                if (mode == PeriodMode.year) {
                  // Clear custom date range and apply year filter
                  _customDateRange = null;
                  final year = int.tryParse(_selectedYear ?? DateTime.now().year.toString()) ?? DateTime.now().year;
                  _expenseCubit.filterByDateRange(
                    DateTime(year, 1, 1),
                    DateTime(year, 12, 31),
                  );
                } else {
                  // Switch to custom mode - clear filters until user selects range
                  _expenseCubit.clearFilters();
                }
              },
              selectedYear: _selectedYear,
              onYearChanged: (year) {
                setState(() {
                  _selectedYear = year;
                });
                if (_periodMode == PeriodMode.year && year != null) {
                  final yearInt = int.tryParse(year) ?? DateTime.now().year;
                  _expenseCubit.filterByDateRange(
                    DateTime(yearInt, 1, 1),
                    DateTime(yearInt, 12, 31),
                  );
                }
              },
              customDateRange: _customDateRange,
              onDateRangeTap: _showCustomDateRangePicker,
              availableYears: _availableYears,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 180,
            child: _buildCategoriesButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'الفئات',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          ElevatedButton.icon(
            onPressed: () => _showCategoriesDialog(context),
            icon: const Icon(Icons.category_outlined, size: 16),
            label: const Text('إدارة الفئات', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
    );
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
          // All expenses chip
          _buildChip(
            label: 'الكل',
            isSelected: selectedCategory == null,
            onTap: () => cubit.setCategoryFilter(null),
          ),
          const SizedBox(width: 8),
          // Category chips
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

  void _showAddExpenseDialog(BuildContext context) {
    final cubit = context.read<ExpenseCubit>();
    final categories = cubit.categories;

    showDialog(
      context: context,
      builder: (dialogContext) => ExpenseFormDialog(
        categories: categories,
        onSubmit: (expense) {
          cubit.createExpense(expense);
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

  void _showCategoriesDialog(BuildContext context) {
    final cubit = context.read<ExpenseCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => ExpenseCategoriesDialog(
        categories: cubit.categories,
        onAddCategory: (category) {
          cubit.createExpenseCategory(category);
        },
        onUpdateCategory: (category) {
          cubit.updateExpenseCategory(category);
        },
        onDeleteCategory: (id) {
          cubit.deleteExpenseCategory(id);
        },
      ),
    );
  }
}
