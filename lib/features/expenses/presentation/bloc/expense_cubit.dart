import 'dart:async';
import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/expense.dart';
import '../../data/models/expense_category.dart';
import '../../data/repositories/expense_repository.dart';

part 'expense_state.dart';

class ExpenseCubit extends Cubit<ExpenseState> {
  final ExpenseRepository _expenseRepository;

  // Stream subscriptions for real-time updates
  StreamSubscription<Either<Failure, List<ExpenseCategory>>>? _categoriesSubscription;
  StreamSubscription<Either<Failure, List<Expense>>>? _expensesSubscription;

  // Filter states
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategoryId;
  List<ExpenseCategory> _categories = [];
  List<Expense> _expenses = [];

  ExpenseCubit({required ExpenseRepository expenseRepository})
      : _expenseRepository = expenseRepository,
        super(ExpenseInitial()) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!isClosed) {
        _startRealtimeListeners();
      }
    });
  }

  // Real-time listeners
  void _startRealtimeListeners() {
    emit(ExpenseLoading());
    // Listen to categories stream
    _categoriesSubscription = _expenseRepository.watchExpenseCategories().listen(
      (result) {
        result.fold(
          (failure) => emit(ExpenseError(failure.message)),
          (categories) {
            _categories = categories;
            _emitExpensesLoaded();
          },
        );
      },
    );

    // Listen to expenses stream
    _expensesSubscription = _expenseRepository.watchExpenses().listen(
      (result) {
        result.fold(
          (failure) => emit(ExpenseError(failure.message)),
          (expenses) {
            _expenses = expenses;
            _emitExpensesLoaded();
          },
        );
      },
    );
  }

  void _emitExpensesLoaded() {
    final filteredExpenses = _getFilteredExpenses();
    final totalAmount = filteredExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final totalCount = filteredExpenses.length;
    final averageAmount = totalCount > 0 ? (totalAmount / totalCount).toDouble() : 0.0;
    final monthlyData = _calculateMonthlyData(filteredExpenses);

    emit(ExpensesLoaded(
      expenses: filteredExpenses,
      categories: _categories,
      startDate: _startDate,
      endDate: _endDate,
      selectedCategoryId: _selectedCategoryId,
      totalAmount: totalAmount,
      totalCount: totalCount,
      averageAmount: averageAmount,
      monthlyData: monthlyData,
    ));
  }

  Map<String, double> _calculateMonthlyData(List<Expense> expenses) {
    final Map<String, double> monthlyMap = {};

    for (final expense in expenses) {
      final key = '${expense.expenseDate.year}-${expense.expenseDate.month.toString().padLeft(2, '0')}';
      monthlyMap[key] = (monthlyMap[key] ?? 0) + expense.amount;
    }

    return monthlyMap;
  }

  List<Expense> _getFilteredExpenses() {
    final filtered = _expenses.where((expense) {
      // Date filter
      if (_startDate != null && _endDate != null) {
        final expenseDate = expense.expenseDate;
        if (expenseDate.isBefore(_startDate!) || expenseDate.isAfter(_endDate!)) {
          return false;
        }
      }
      // Category filter
      if (_selectedCategoryId != null) {
        return expense.categoryId == _selectedCategoryId;
      }
      return true;
    }).toList();
    
    // Sort by date descending (newest first)
    filtered.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return filtered;
  }

  @override
  Future<void> close() {
    _categoriesSubscription?.cancel();
    _expensesSubscription?.cancel();
    return super.close();
  }

  // Getters for filter states
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get selectedCategoryId => _selectedCategoryId;
  List<ExpenseCategory> get categories => _categories;
  List<Expense> get expenses => _expenses;

  // Expense Categories - Optimistic UI pattern
  Future<void> createExpenseCategory(ExpenseCategory category) async {
    // 1. Generate temporary ID for optimistic update
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';

    // 2. Add to local list immediately (optimistic)
    final optimisticCategory = category.copyWith(id: tempId);
    _categories = [..._categories, optimisticCategory];
    _emitExpensesLoaded();

    // 3. Send to Supabase
    final result = await _expenseRepository.createExpenseCategory(category);

    result.fold(
      (failure) {
        // 4. Rollback: Remove from local list on error
        _categories = _categories.where((c) => c.id != tempId).toList();
        _emitExpensesLoaded();
        emit(ExpenseError('فشل إضافة الفئة: ${failure.message}'));
      },
      (createdCategory) {
        // 5. Success: Real-time stream will replace temp with actual data
        emit(ExpenseSuccess('تم إضافة فئة المصروفات بنجاح'));
        // Stream will automatically update the list with real ID
      },
    );
  }

  Future<void> updateExpenseCategory(ExpenseCategory category) async {
    final result = await _expenseRepository.updateExpenseCategory(category);
    result.fold(
      (failure) => emit(ExpenseError(failure.message)),
      (updatedCategory) {
        emit(ExpenseSuccess('تم تحديث فئة المصروفات بنجاح'));
        // Stream will automatically update the list
      },
    );
  }

  Future<void> deleteExpenseCategory(String id) async {
    final result = await _expenseRepository.deleteExpenseCategory(id);
    result.fold(
      (failure) => emit(ExpenseError(failure.message)),
      (_) {
        emit(ExpenseSuccess('تم حذف فئة المصروفات بنجاح'));
        // Stream will automatically update the list
      },
    );
  }

  // Filter methods - Just re-emit with filtered data
  void setCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    _emitExpensesLoaded();
  }

  void filterByDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _emitExpensesLoaded();
  }

  void clearFilters() {
    _startDate = null;
    _endDate = null;
    _selectedCategoryId = null;
    _emitExpensesLoaded();
  }

  // CRUD operations - Stream will handle automatic updates
  Future<void> createExpense(Expense expense) async {
    emit(ExpenseLoading());
    final result = await _expenseRepository.createExpense(expense);
    result.fold(
      (failure) => emit(ExpenseError(failure.message)),
      (createdExpense) {
        emit(ExpenseSuccess('تم إضافة المصروف بنجاح'));
        // Reload data to show updated list
        _emitExpensesLoaded();
      },
    );
  }

  Future<void> updateExpense(Expense expense) async {
    final result = await _expenseRepository.updateExpense(expense);
    result.fold(
      (failure) => emit(ExpenseError(failure.message)),
      (updatedExpense) {
        emit(ExpenseSuccess('تم تحديث المصروف بنجاح'));
        _emitExpensesLoaded();
      },
    );
  }

  Future<void> deleteExpense(String id) async {
    final result = await _expenseRepository.deleteExpense(id);
    result.fold(
      (failure) => emit(ExpenseError(failure.message)),
      (_) {
        emit(ExpenseSuccess('تم حذف المصروف بنجاح'));
        _emitExpensesLoaded();
      },
    );
  }

  void clearError() {
    emit(ExpenseInitial());
  }
}
