import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/expense.dart';
import '../../data/models/expense_category.dart';
import '../../data/repositories/expense_repository.dart';

part 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  static const int pageSize = 10;

  final ExpenseRepository _expenseRepository;

  final List<Expense> _expenses = [];
  List<ExpenseCategory> _categories = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategoryId;

  int _offset = 0;
  int _requestId = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  double _totalAmount = 0;
  int _totalCount = 0;
  double _averageAmount = 0;
  Map<String, double> _monthlyData = const {};

  ExpenseCubit({required ExpenseRepository expenseRepository})
      : _expenseRepository = expenseRepository,
        super(ExpenseInitial());

  // Getters for filter states
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get selectedCategoryId => _selectedCategoryId;
  List<ExpenseCategory> get categories => _categories;
  List<Expense> get expenses => List<Expense>.unmodifiable(_expenses);

  Future<void> loadInitial({DateTime? startDate, DateTime? endDate}) async {
    _startDate = startDate;
    _endDate = endDate;
    await _reload(showLoading: true, includeCategories: true);
  }

  Future<void> loadMore() async {
    if (isClosed || !_hasMore || _isLoadingMore) return;

    final requestId = _requestId;
    _isLoadingMore = true;
    _emitLoaded();

    final result = await _expenseRepository.getExpensesPage(
      offset: _offset,
      limit: pageSize,
      startDate: _startDate,
      endDate: _endDate,
      categoryId: _selectedCategoryId,
    );
    if (isClosed || requestId != _requestId) return;

    _isLoadingMore = false;
    result.fold(
      (_) {
        _hasMore = false;
        _emitLoaded();
      },
      (page) {
        _expenses.addAll(page.items);
        _offset += page.items.length;
        _hasMore = page.hasMore;
        _emitLoaded();
      },
    );
  }

  Future<void> _reload({
    bool showLoading = false,
    bool includeCategories = false,
  }) async {
    final requestId = ++_requestId;
    _offset = 0;
    _hasMore = true;
    _isLoadingMore = false;

    if (showLoading && !isClosed) emit(ExpenseLoading());

    final pageFuture = _expenseRepository.getExpensesPage(
      offset: 0,
      limit: pageSize,
      startDate: _startDate,
      endDate: _endDate,
      categoryId: _selectedCategoryId,
    );
    final summaryFuture = _expenseRepository.getExpenseSummary(
      startDate: _startDate,
      endDate: _endDate,
      categoryId: _selectedCategoryId,
    );
    final categoriesFuture = includeCategories
        ? _expenseRepository.getExpenseCategories()
        : null;

    final pageResult = await pageFuture;
    final summaryResult = await summaryFuture;
    final categoriesResult =
        categoriesFuture == null ? null : await categoriesFuture;

    if (isClosed || requestId != _requestId) return;

    pageResult.fold(
      (failure) => emit(ExpenseError(failure.message)),
      (page) {
        _expenses
          ..clear()
          ..addAll(page.items);
        _offset = page.items.length;
        _hasMore = page.hasMore;

        summaryResult.fold(
          (_) {
            _totalAmount = 0;
            _totalCount = 0;
            _averageAmount = 0;
            _monthlyData = const {};
          },
          (summary) {
            _totalAmount = summary.totalAmount;
            _totalCount = summary.totalCount;
            _averageAmount = summary.averageAmount;
            _monthlyData = summary.monthlyData;
          },
        );

        if (categoriesResult != null) {
          categoriesResult.fold((_) {}, (categories) {
            _categories = categories;
          });
        }

        _emitLoaded();
      },
    );
  }

  void _emitLoaded() {
    if (isClosed) return;
    emit(ExpensesLoaded(
      expenses: List<Expense>.unmodifiable(_expenses),
      categories: _categories,
      startDate: _startDate,
      endDate: _endDate,
      selectedCategoryId: _selectedCategoryId,
      totalAmount: _totalAmount,
      totalCount: _totalCount,
      averageAmount: _averageAmount,
      monthlyData: _monthlyData,
      hasMore: _hasMore,
      isLoadingMore: _isLoadingMore,
    ));
  }

  // Expense Categories
  Future<void> _reloadCategories() async {
    final result = await _expenseRepository.getExpenseCategories();
    if (isClosed) return;
    result.fold((_) {}, (categories) {
      _categories = categories;
      _emitLoaded();
    });
  }

  Future<void> createExpenseCategory(ExpenseCategory category) async {
    final result = await _expenseRepository.createExpenseCategory(category);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ExpenseError('فشل إضافة الفئة: ${failure.message}')),
      (_) {
        if (isClosed) return;
        emit(ExpenseSuccess('تم إضافة فئة المصروفات بنجاح'));
        _reloadCategories();
      },
    );
  }

  Future<void> updateExpenseCategory(ExpenseCategory category) async {
    final result = await _expenseRepository.updateExpenseCategory(category);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ExpenseError(failure.message)),
      (_) {
        if (isClosed) return;
        emit(ExpenseSuccess('تم تحديث فئة المصروفات بنجاح'));
        _reloadCategories();
      },
    );
  }

  Future<void> deleteExpenseCategory(String id) async {
    final result = await _expenseRepository.deleteExpenseCategory(id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ExpenseError(failure.message)),
      (_) {
        if (isClosed) return;
        emit(ExpenseSuccess('تم حذف فئة المصروفات بنجاح'));
        _reloadCategories();
      },
    );
  }

  // Filter methods
  Future<void> setCategoryFilter(String? categoryId) async {
    _selectedCategoryId = categoryId;
    await _reload();
  }

  Future<void> filterByDateRange(DateTime? start, DateTime? end) async {
    _startDate = start;
    _endDate = end;
    await _reload();
  }

  Future<void> clearFilters() async {
    _startDate = null;
    _endDate = null;
    _selectedCategoryId = null;
    await _reload();
  }

  // CRUD operations
  Future<void> createExpense(Expense expense) async {
    emit(ExpenseLoading());
    final result = await _expenseRepository.createExpense(expense);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ExpenseError(failure.message)),
      (_) {
        if (isClosed) return;
        emit(ExpenseSuccess('تم إضافة المصروف بنجاح'));
        _reload();
      },
    );
  }

  Future<void> updateExpense(Expense expense) async {
    final result = await _expenseRepository.updateExpense(expense);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ExpenseError(failure.message)),
      (_) {
        if (isClosed) return;
        emit(ExpenseSuccess('تم تحديث المصروف بنجاح'));
        _reload();
      },
    );
  }

  Future<void> deleteExpense(String id) async {
    final result = await _expenseRepository.deleteExpense(id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ExpenseError(failure.message)),
      (_) {
        if (isClosed) return;
        emit(ExpenseSuccess('تم حذف المصروف بنجاح'));
        _reload();
      },
    );
  }

  void clearError() {
    if (isClosed) return;
    emit(ExpenseInitial());
  }
}
