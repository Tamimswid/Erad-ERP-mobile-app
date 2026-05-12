part of 'expense_cubit.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {}

class ExpenseLoading extends ExpenseState {}

class ExpenseCategoriesLoaded extends ExpenseState {
  final List<ExpenseCategory> categories;

  const ExpenseCategoriesLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class ExpensesLoaded extends ExpenseState {
  final List<Expense> expenses;
  final List<ExpenseCategory> categories;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedCategoryId;
  final double totalAmount;
  final int totalCount;
  final double averageAmount;
  final Map<String, double> monthlyData;

  const ExpensesLoaded({
    required this.expenses,
    required this.categories,
    this.startDate,
    this.endDate,
    this.selectedCategoryId,
    this.totalAmount = 0,
    this.totalCount = 0,
    this.averageAmount = 0,
    this.monthlyData = const {},
  });

  @override
  List<Object?> get props => [
        expenses,
        categories,
        startDate,
        endDate,
        selectedCategoryId,
        totalAmount,
        totalCount,
        averageAmount,
        monthlyData,
      ];

  ExpensesLoaded copyWith({
    List<Expense>? expenses,
    List<ExpenseCategory>? categories,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedCategoryId,
    double? totalAmount,
    int? totalCount,
    double? averageAmount,
    Map<String, double>? monthlyData,
  }) {
    return ExpensesLoaded(
      expenses: expenses ?? this.expenses,
      categories: categories ?? this.categories,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      totalAmount: totalAmount ?? this.totalAmount,
      totalCount: totalCount ?? this.totalCount,
      averageAmount: averageAmount ?? this.averageAmount,
      monthlyData: monthlyData ?? this.monthlyData,
    );
  }
}

class ExpenseSuccess extends ExpenseState {
  final String message;

  const ExpenseSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ExpenseError extends ExpenseState {
  final String message;

  const ExpenseError(this.message);

  @override
  List<Object?> get props => [message];
}
