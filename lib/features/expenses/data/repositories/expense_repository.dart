import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/paged_result.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/expense_summary.dart';
import '../datasource/expense_remote_datasource.dart';

// مستودع المصروفات - يتحقق من الاتصال ويعالج الأخطاء
class ExpenseRepository {
  final ExpenseRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ExpenseRepository(this.remoteDataSource, this.networkInfo);

  // جلب فئات المصروفات مع التحقق من الاتصال
  Future<Either<Failure, List<ExpenseCategory>>> getExpenseCategories() async {
    if (await networkInfo.isConnected) {
      try {
        final categories = await remoteDataSource.getExpenseCategories();
        return Right(categories);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  // إنشاء فئة مصروفات مع التحقق من الاتصال
  Future<Either<Failure, ExpenseCategory>> createExpenseCategory(ExpenseCategory category) async {
    if (await networkInfo.isConnected) {
      try {
        final createdCategory = await remoteDataSource.createExpenseCategory(category);
        return Right(createdCategory);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  // تحديث فئة المصروفات مع التحقق من الاتصال
  Future<Either<Failure, ExpenseCategory>> updateExpenseCategory(ExpenseCategory category) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedCategory = await remoteDataSource.updateExpenseCategory(category);
        return Right(updatedCategory);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  // حذف فئة المصروفات مع التحقق من الاتصال
  Future<Either<Failure, void>> deleteExpenseCategory(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteExpenseCategory(id);
        return const Right(null);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  // جلب صفحة من المصروفات مع التحقق من الاتصال
  Future<Either<Failure, PagedResult<Expense>>> getExpensesPage({
    required int offset,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final page = await remoteDataSource.getExpensesPage(
          offset: offset,
          limit: limit,
          startDate: startDate,
          endDate: endDate,
          categoryId: categoryId,
        );
        return Right(page);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  // ملخص المصروفات مع التحقق من الاتصال
  Future<Either<Failure, ExpenseSummary>> getExpenseSummary({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final summary = await remoteDataSource.getExpenseSummary(
          startDate: startDate,
          endDate: endDate,
          categoryId: categoryId,
        );
        return Right(summary);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  // جلب مصروف بالمعرف مع التحقق من الاتصال
  Future<Either<Failure, Expense>> getExpense(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final expense = await remoteDataSource.getExpense(id);
        return Right(expense);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  // إنشاء مصروف مع التحقق من الاتصال
  Future<Either<Failure, Expense>> createExpense(Expense expense) async {
    if (await networkInfo.isConnected) {
      try {
        final createdExpense = await remoteDataSource.createExpense(expense);
        return Right(createdExpense);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  // تحديث المصروف مع التحقق من الاتصال
  Future<Either<Failure, Expense>> updateExpense(Expense expense) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedExpense = await remoteDataSource.updateExpense(expense);
        return Right(updatedExpense);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  // حذف المصروف مع التحقق من الاتصال
  Future<Either<Failure, void>> deleteExpense(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteExpense(id);
        return const Right(null);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

}
