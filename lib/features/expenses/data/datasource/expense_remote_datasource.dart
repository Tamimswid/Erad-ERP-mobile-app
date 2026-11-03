import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/expense_summary.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/paged_result.dart';

abstract class ExpenseRemoteDataSource {
  // جلب جميع فئات المصروفات
  Future<List<ExpenseCategory>> getExpenseCategories();
  // إنشاء فئة مصروفات جديدة
  Future<ExpenseCategory> createExpenseCategory(ExpenseCategory category);
  // تحديث فئة المصروفات
  Future<ExpenseCategory> updateExpenseCategory(ExpenseCategory category);
  // حذف فئة المصروفات
  Future<void> deleteExpenseCategory(String id);

  // جلب صفحة من المصروفات مع إمكانية التصفية
  Future<PagedResult<Expense>> getExpensesPage({
    required int offset,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  });
  // ملخص المصروفات (إجمالي، عدد، متوسط، بيانات شهرية)
  Future<ExpenseSummary> getExpenseSummary({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  });
  // جلب مصروف بالمعرف
  Future<Expense> getExpense(String id);
  // إنشاء مصروف جديد
  Future<Expense> createExpense(Expense expense);
  // تحديث المصروف
  Future<Expense> updateExpense(Expense expense);
  // حذف المصروف
  Future<void> deleteExpense(String id);
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
  Future<PagedResult<Expense>> getExpensesPage({
    required int offset,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      var query = client
          .from('expenses')
          .select('*, expense_categories(name)')
          .eq('user_id', userId)
          .isFilter('deleted_at', null);

      if (startDate != null) {
        query = query.gte('expense_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('expense_date', endDate.toIso8601String());
      }
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      final response = await query
          .order('expense_date', ascending: false)
          .order('id', ascending: true)
          .range(offset, offset + limit);

      final expenses =
          response.map((expense) => Expense.fromMap(expense)).toList();
      final hasMore = expenses.length > limit;
      return PagedResult(
        items: hasMore ? expenses.sublist(0, limit) : expenses,
        hasMore: hasMore,
      );
    } catch (e) {
      throw exceptionToFailure(e);
    }
  }

  @override
  Future<ExpenseSummary> getExpenseSummary({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not logged in');
      }

      var query = client
          .from('expenses')
          .select('amount, expense_date')
          .eq('user_id', userId)
          .isFilter('deleted_at', null);

      if (startDate != null) {
        query = query.gte('expense_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('expense_date', endDate.toIso8601String());
      }
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      final response = await query;

      var totalAmount = 0.0;
      var totalCount = 0;
      final monthlyData = <String, double>{};

      for (final row in response) {
        final amount = (row['amount'] ?? 0).toDouble();
        final date = DateTime.parse(row['expense_date']);
        totalAmount += amount;
        totalCount++;
        final key =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyData[key] = (monthlyData[key] ?? 0) + amount;
      }

      return ExpenseSummary(
        totalAmount: totalAmount,
        totalCount: totalCount,
        averageAmount: totalCount > 0 ? totalAmount / totalCount : 0,
        monthlyData: monthlyData,
      );
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
}
