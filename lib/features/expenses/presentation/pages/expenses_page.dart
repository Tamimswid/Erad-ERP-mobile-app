import 'package:erad/features/expenses/data/models/expense.dart';
import 'package:erad/features/expenses/data/models/expense_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/services_locator.dart' as sl;
import '../../../../core/widgets/app_pagination_list.dart';
import '../../../../core/widgets/date_filter_sheet.dart';
import '../bloc/expense_cubit.dart';
import '../widgets/expense_categories_dialog.dart';
import '../widgets/expense_filters_widget.dart';
import '../widgets/expense_form_dialog.dart';
import '../widgets/expense_monthly_chart_widget.dart';
import '../widgets/expense_summary_cards_widget.dart';
import '../widgets/expense_table_widget.dart';

class ExpensesPage extends StatefulWidget {
  final bool isLocal;
  final bool autoOpenAdd;

  const ExpensesPage({
    super.key,
    this.isLocal = false,
    this.autoOpenAdd = false,
  });

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
        isLocal: widget.isLocal,
        autoOpenAdd: widget.autoOpenAdd,
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
  final bool isLocal;
  final bool autoOpenAdd;
  final PeriodMode periodMode;
  final String? selectedYear;
  final DateTimeRange? customDateRange;
  final ValueChanged<PeriodMode> onPeriodModeChanged;
  final ValueChanged<String?> onYearChanged;
  final ValueChanged<DateTimeRange?> onCustomDateRangeChanged;
  final VoidCallback onClearCustomDateRange;
  final List<String> availableYears;

  const _ExpensesPageBody({
    required this.isLocal,
    required this.autoOpenAdd,
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
  bool _autoAddHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final year =
          int.tryParse(widget.selectedYear ?? DateTime.now().year.toString()) ??
          DateTime.now().year;
      context.read<ExpenseCubit>().loadInitial(
        startDate: DateTime(year, 1, 1),
        endDate: DateTime(year, 12, 31),
      );
    });
  }

  void _maybeAutoOpenAdd(BuildContext context, ExpensesLoaded state) {
    if (!widget.autoOpenAdd || _autoAddHandled || state.categories.isEmpty) {
      return;
    }
    _autoAddHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showAddExpenseDialog(
        context: context,
        onTap: (expense) {
          context.read<ExpenseCubit>().createExpense(expense);
          Navigator.pop(context);
        },
        categories: state.categories,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المصروفات'),
        actions: [
          if (!widget.isLocal)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Builder(
                builder: (context) {
                  final cubit = context.read<ExpenseCubit>();
                  final categories = cubit.categories;
                  return IconButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (dialogContext) => ExpenseCategoriesDialog(
                        categories: categories,
                        onAddCategory: (category) {
                          context.read<ExpenseCubit>().createExpenseCategory(
                            category,
                          );
                        },
                        onUpdateCategory: (category) {
                          context.read<ExpenseCubit>().updateExpenseCategory(
                            category,
                          );
                        },
                        onDeleteCategory: (id) {
                          context.read<ExpenseCubit>().deleteExpenseCategory(
                            id,
                          );
                        },
                      ),
                    ),
                    icon: const Icon(sc.LucideIcons.folderOpen, size: 22),
                    tooltip: 'إدارة التصنيفات',
                  );
                },
              ),
            ),
          const SizedBox(width: 8),
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
                context.read<ExpenseCubit>().filterByDateRange(
                  range.start,
                  range.end,
                );
              },
              onClearFilter: () {
                widget.onClearCustomDateRange();
                widget.onPeriodModeChanged(PeriodMode.year);
                final year =
                    int.tryParse(
                      widget.selectedYear ?? DateTime.now().year.toString(),
                    ) ??
                    DateTime.now().year;
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
            if (state is ExpensesLoaded) {
              _maybeAutoOpenAdd(context, state);
            }
            if (state is ExpenseSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
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
            if (state is ExpenseError) {
              final cubit = context.read<ExpenseCubit>();
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      sc.LucideIcons.circleAlert,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: TextStyle(color: AppColors.text),
                    ),
                    const SizedBox(height: 16),
                    sc.Button(
                      alignment: Alignment.center,
                      style: sc.ButtonStyle.primary(),
                      onPressed: () => cubit.filterByDateRange(
                        cubit.startDate,
                        cubit.endDate,
                      ),
                      child: const Text('أعد المحاولة'),
                    ),
                  ],
                ),
              );
            }
            if (state is! ExpensesLoaded) {
              return const SizedBox.shrink();
            }

            final cubit = context.read<ExpenseCubit>();
            final categoryById = {
              for (final category in state.categories) category.id: category,
            };

            return RefreshIndicator(
              onRefresh: () =>
                  cubit.filterByDateRange(cubit.startDate, cubit.endDate),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExpenseSummaryCardsWidget(
                            totalAmount: state.totalAmount,
                            totalCount: state.totalCount,
                            averageAmount: state.averageAmount,
                          ),
                          const SizedBox(height: 12),
                          ExpenseMonthlyChartWidget(
                            monthlyData: state.monthlyData,
                            year: _getSelectedYear(),
                          ),
                          const SizedBox(height: 12),
                          _buildCategoryChips(context, state),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  if (state.expenses.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _buildEmptyState(),
                      ),
                    )
                  else
                    AppPaginationSliverList(
                      itemCount: state.expenses.length,
                      hasMore: state.hasMore,
                      isLoadingMore: state.isLoadingMore,
                      onLoadMore: cubit.loadMore,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                      separator: const SizedBox(height: 10),
                      bottomSpace: 100,
                      itemBuilder: (context, index) {
                        final expense = state.expenses[index];
                        return ExpenseTableCard(
                          expense: expense,
                          category: categoryById[expense.categoryId],
                          onDelete: (expense) =>
                              cubit.deleteExpense(expense.id),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: widget.isLocal
          ? null
          : Builder(
              builder: (context) {
                final categories = context.watch<ExpenseCubit>().categories;
                return FloatingActionButton.extended(
                  label: const Text('إضافة مصروف'),
                  onPressed: () => _showAddExpenseDialog(
                    context: context,
                    onTap: (expense) {
                      context.read<ExpenseCubit>().createExpense(expense);
                      Navigator.pop(context);
                    },
                    categories: categories,
                  ),
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
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.onPrimary : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return sc.Card(
      padding: const EdgeInsets.all(32),
      child: const Column(
        children: [
          Icon(
            sc.LucideIcons.receiptText,
            size: 40,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'لم يتم العثور على بيانات',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
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
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(sc.LucideIcons.calendar, size: 16, color: AppColors.text),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
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
    final initial =
        customDateRange ??
        DateTimeRange(
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
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.text,
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
