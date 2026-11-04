import 'package:equatable/equatable.dart';
import 'package:erad/core/notifications/data_change_notifier.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/expense.dart';
import '../../data/models/expense_category.dart';
import '../../data/repositories/expense_repository.dart';

part 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  static const int pageSize = 10;

  final ExpenseRepository _expenseRepository;
  final DataChangeNotifier _dataChanges;
  int _dataChangeVersion = 0;

  final List<Expense> _expenses = [];
  List<ExpenseCategory> _categories = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategoryId;

  int _offset = 0;
  int _requestId = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _hasLoaded = false;

  double _totalAmount = 0;
  int _totalCount = 0;
  double _averageAmount = 0;
  Map<String, double> _monthlyData = const {};

  ExpenseCubit({
    required ExpenseRepository expenseRepository,
    required DataChangeNotifier dataChanges,
  }) : _expenseRepository = expenseRepository,
       _dataChanges = dataChanges,
       super(ExpenseInitial()) {
    _dataChangeVersion = _dataChanges.versionOf(DataDomain.expenses);
    _dataChanges.addListener(_handleDataChange);
  }

  Future<void> refresh() => _reload(showLoading: false);

  void _handleDataChange() {
    if (isClosed) return;
    final version = _dataChanges.versionOf(DataDomain.expenses);
    if (version == _dataChangeVersion) return;
    _dataChangeVersion = version;
    refresh();
  }

  @override
  Future<void> close() {
    _dataChanges.removeListener(_handleDataChange);
    return super.close();
  }

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
    final hadLoaded = _hasLoaded;
    final previousOffset = _offset;
    final previousHasMore = _hasMore;
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
    final categoriesResult = categoriesFuture == null
        ? null
        : await categoriesFuture;

    if (isClosed || requestId != _requestId) return;

    pageResult.fold(
      (failure) {
        _offset = previousOffset;
        _hasMore = previousHasMore;
        emit(ExpenseError(failure.message));
        if (hadLoaded) _emitLoaded();
      },
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

        _hasLoaded = true;
        _emitLoaded();
      },
    );
  }

  void _emitLoaded() {
    if (isClosed) return;
    emit(
      ExpensesLoaded(
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
      ),
    );
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
    result.fold((failure) => emit(ExpenseError(failure.message)), (_) {
      if (isClosed) return;
      emit(ExpenseSuccess('تم تحديث فئة المصروفات بنجاح'));
      _reloadCategories();
    });
  }

  Future<void> deleteExpenseCategory(String id) async {
    final result = await _expenseRepository.deleteExpenseCategory(id);
    if (isClosed) return;
    result.fold((failure) => emit(ExpenseError(failure.message)), (_) {
      if (isClosed) return;
      emit(ExpenseSuccess('تم حذف فئة المصروفات بنجاح'));
      _reloadCategories();
    });
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
    if (isClosed) return;
    final snapshot = _snapshot();
    final optimistic = _withOptimisticId(expense);
    if (_matchesFilters(optimistic)) {
      _expenses.insert(0, optimistic);
      _applyTotalsDelta(optimistic.amount, 1);
      _emitLoaded();
    }

    final result = await _expenseRepository.createExpense(expense);
    if (isClosed) return;
    result.fold(
      (failure) {
        _restore(snapshot);
        emit(ExpenseError(failure.message));
        _emitLoaded();
      },
      (_) {
        emit(ExpenseSuccess('تم إضافة المصروف بنجاح'));
        if (_hasLoaded) _emitLoaded();
        _dataChanges.notifyChanged(DataDomain.expenses);
      },
    );
  }

  Future<void> updateExpense(Expense expense) async {
    if (isClosed) return;
    final snapshot = _snapshot();
    final index = _expenses.indexWhere((item) => item.id == expense.id);
    if (index != -1) {
      final previous = _expenses[index];
      final wasVisible = _matchesFilters(previous);
      final isVisible = _matchesFilters(expense);
      if (isVisible) {
        _expenses[index] = expense;
      } else {
        _expenses.removeAt(index);
      }
      if (wasVisible) _applyTotalsDelta(-previous.amount, -1);
      if (isVisible) _applyTotalsDelta(expense.amount, 1);
      _emitLoaded();
    }

    final result = await _expenseRepository.updateExpense(expense);
    if (isClosed) return;
    result.fold(
      (failure) {
        _restore(snapshot);
        emit(ExpenseError(failure.message));
        _emitLoaded();
      },
      (_) {
        emit(ExpenseSuccess('تم تحديث المصروف بنجاح'));
        if (_hasLoaded) _emitLoaded();
        _dataChanges.notifyChanged(DataDomain.expenses);
      },
    );
  }

  Future<void> deleteExpense(String id) async {
    if (isClosed) return;
    final snapshot = _snapshot();
    final index = _expenses.indexWhere((item) => item.id == id);
    if (index != -1) {
      final removed = _expenses.removeAt(index);
      _applyTotalsDelta(-removed.amount, -1);
      if (_offset > 0) _offset--;
      _emitLoaded();
    }

    final result = await _expenseRepository.deleteExpense(id);
    if (isClosed) return;
    result.fold(
      (failure) {
        _restore(snapshot);
        emit(ExpenseError(failure.message));
        _emitLoaded();
      },
      (_) {
        emit(ExpenseSuccess('تم حذف المصروف بنجاح'));
        if (_hasLoaded) _emitLoaded();
        _dataChanges.notifyChanged(DataDomain.expenses);
      },
    );
  }

  ({
    List<Expense> expenses,
    double totalAmount,
    int totalCount,
    double averageAmount,
    Map<String, double> monthlyData,
    int offset,
    bool hasMore,
  })
  _snapshot() => (
    expenses: List<Expense>.from(_expenses),
    totalAmount: _totalAmount,
    totalCount: _totalCount,
    averageAmount: _averageAmount,
    monthlyData: _monthlyData,
    offset: _offset,
    hasMore: _hasMore,
  );

  void _restore(
    ({
      List<Expense> expenses,
      double totalAmount,
      int totalCount,
      double averageAmount,
      Map<String, double> monthlyData,
      int offset,
      bool hasMore,
    })
    snapshot,
  ) {
    _expenses
      ..clear()
      ..addAll(snapshot.expenses);
    _totalAmount = snapshot.totalAmount;
    _totalCount = snapshot.totalCount;
    _averageAmount = snapshot.averageAmount;
    _monthlyData = snapshot.monthlyData;
    _offset = snapshot.offset;
    _hasMore = snapshot.hasMore;
  }

  Expense _withOptimisticId(Expense expense) {
    if (expense.id.isNotEmpty) return expense;
    return expense.copyWith(
      id: 'optimistic_${DateTime.now().microsecondsSinceEpoch}',
    );
  }

  bool _matchesFilters(Expense expense) {
    final date = DateTime(
      expense.expenseDate.year,
      expense.expenseDate.month,
      expense.expenseDate.day,
    );
    if (_startDate != null) {
      final start = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
      );
      if (date.isBefore(start)) return false;
    }
    if (_endDate != null) {
      final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
      if (date.isAfter(end)) return false;
    }
    if (_selectedCategoryId != null &&
        expense.categoryId != _selectedCategoryId) {
      return false;
    }
    return true;
  }

  void _applyTotalsDelta(double amountDelta, int countDelta) {
    _totalAmount += amountDelta;
    if (_totalAmount < 0) _totalAmount = 0;
    _totalCount += countDelta;
    if (_totalCount < 0) _totalCount = 0;
    _averageAmount = _totalCount == 0 ? 0 : _totalAmount / _totalCount;
  }

  void clearError() {
    if (isClosed) return;
    emit(ExpenseInitial());
  }
}
