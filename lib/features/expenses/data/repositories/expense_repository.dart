import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
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

  // مراقبة فئات المصروفات بشكل فوري
  Stream<Either<Failure, List<ExpenseCategory>>> watchExpenseCategories() {
    try {
      return remoteDataSource.watchExpenseCategories().map((data) => Right(data));
    } catch (e) {
      return Stream.value(Left(exceptionToFailure(e)));
    }
  }

  // جلب المصروفات مع التحقق من الاتصال
  Future<Either<Failure, List<Expense>>> getExpenses({DateTime? startDate, DateTime? endDate, String? categoryId}) async {
    if (await networkInfo.isConnected) {
      try {
        final expenses = await remoteDataSource.getExpenses(startDate: startDate, endDate: endDate, categoryId: categoryId);
        return Right(expenses);
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

  // مراقبة المصروفات بشكل فوري
  Stream<Either<Failure, List<Expense>>> watchExpenses() {
    try {
      return remoteDataSource.watchExpenses().map((data) => Right(data));
    } catch (e) {
      return Stream.value(Left(exceptionToFailure(e)));
    }
  }
}
