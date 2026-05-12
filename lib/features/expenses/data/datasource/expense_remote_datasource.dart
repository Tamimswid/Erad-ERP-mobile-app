import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/user_service.dart';

abstract class ExpenseRemoteDataSource {
  // جلب جميع فئات المصروفات
  Future<List<ExpenseCategory>> getExpenseCategories();
  // إنشاء فئة مصروفات جديدة
  Future<ExpenseCategory> createExpenseCategory(ExpenseCategory category);
  // تحديث فئة المصروفات
  Future<ExpenseCategory> updateExpenseCategory(ExpenseCategory category);
  // حذف فئة المصروفات
  Future<void> deleteExpenseCategory(String id);
  // مراقبة فئات المصروفات بشكل فوري
  Stream<List<ExpenseCategory>> watchExpenseCategories();
  
  // جلب المصروفات مع إمكانية التصفية
  Future<List<Expense>> getExpenses({DateTime? startDate, DateTime? endDate, String? categoryId});
  // جلب مصروف بالمعرف
  Future<Expense> getExpense(String id);
  // إنشاء مصروف جديد
  Future<Expense> createExpense(Expense expense);
  // تحديث المصروف
  Future<Expense> updateExpense(Expense expense);
  // حذف المصروف
  Future<void> deleteExpense(String id);
  // مراقبة المصروفات بشكل فوري
  Stream<List<Expense>> watchExpenses();
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final SupabaseClient client;

  ExpenseRemoteDataSourceImpl(this.client);

  @override
  Future<List<ExpenseCategory>> getExpenseCategories() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      // جلب فئات المصروفات النشطة
      final response = await client
          .from('expense_categories')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('name');

      return response.map((category) => ExpenseCategory.fromMap(category)).toList();
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<ExpenseCategory> createExpenseCategory(ExpenseCategory category) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      // إضافة معرف المستخدم إلى الفئة
      final categoryWithUserId = category.copyWith(userId: userId);
      final response = await client
          .from('expense_categories')
          .insert(categoryWithUserId.toMap())
          .select()
          .single();

      return ExpenseCategory.fromMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<ExpenseCategory> updateExpenseCategory(ExpenseCategory category) async {
    try {
      final response = await client
          .from('expense_categories')
          .update(category.toMap())
          .eq('id', category.id)
          .select()
          .single();

      return ExpenseCategory.fromMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<void> deleteExpenseCategory(String id) async {
    try {
      await client.from('expense_categories').delete().eq('id', id);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Stream<List<ExpenseCategory>> watchExpenseCategories() async* {
    final userId = await UserService.getUserId();
    if (userId == null) {
      throw Exception('User not logged in');
    }

    // مراقبة فئات المصروفات بشكل فوري
    yield* client
        .from('expense_categories')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('name')
        .asStream()
        .map((response) => response.map((item) => ExpenseCategory.fromMap(item)).toList());
  }

  @override
  Future<List<Expense>> getExpenses({DateTime? startDate, DateTime? endDate, String? categoryId}) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      // جلب المصروفات مع فئاتها
      final response = await client
          .from('expenses')
          .select('*, expense_categories(name)')
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .order('expense_date', ascending: false);

      return response.map((expense) => Expense.fromMap(expense)).toList();
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<Expense> getExpense(String id) async {
    try {
      final response = await client
          .from('expenses')
          .select('*, expense_categories(name)')
          .eq('id', id)
          .single();

      return Expense.fromMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<Expense> createExpense(Expense expense) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      // إضافة معرف المستخدم إلى المصروف
      final expenseWithUserId = expense.copyWith(userId: userId);
      final response = await client
          .from('expenses')
          .insert(expenseWithUserId.toMap())
          .select('*, expense_categories(name)')
          .single();

      return Expense.fromMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<Expense> updateExpense(Expense expense) async {
    try {
      final response = await client
          .from('expenses')
          .update(expense.toMap())
          .eq('id', expense.id)
          .select('*, expense_categories(name)')
          .single();

      return Expense.fromMap(response);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      await client.from('expenses').delete().eq('id', id);
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Stream<List<Expense>> watchExpenses() async* {
    final userId = await UserService.getUserId();
    if (userId == null) {
      throw Exception('User not logged in');
    }

    // مراقبة المصروفات بشكل فوري
    yield* client
        .from('expenses')
        .select('*, expense_categories(name)')
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('expense_date', ascending: false)
        .asStream()
        .map((response) => response.map((item) => Expense.fromMap(item)).toList());
  }
}
