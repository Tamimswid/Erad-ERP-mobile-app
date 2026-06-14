import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/core/network/network_info.dart';
import 'package:erad/core/services/user_service.dart';
import 'package:erad/features/customer_debts/data/datasource/customer_debt_remote_datasource.dart';
import 'package:erad/features/customer_debts/data/datasource/customer_debt_local_datasource.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_model.dart';
import 'package:erad/features/customer_debts/data/repositories/customer_debt_repository.dart';

// تنفيذ مستودع ديون العملاء - يتحقق من الاتصال ويعالج الأخطاء
class CustomerDebtRepositoryImpl implements CustomerDebtRepository {
  final CustomerDebtRemoteDataSource remoteDataSource;
  final CustomerDebtLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CustomerDebtRepositoryImpl(this.remoteDataSource, this.localDataSource, this.networkInfo);

  @override
  Future<Either<Failure, List<CustomerDebtModel>>> getCustomerDebts() async {
    if (await networkInfo.isConnected) {
      try {
        final debts = await remoteDataSource.getCustomerDebts();
        final userId = await UserService.getUserId();
        if (userId != null) {
          await localDataSource.cacheCustomerDebts(userId, debts);
        }
        return Right(debts);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      try {
        final userId = await UserService.getUserId();
        if (userId == null) return Left(CacheFailure.notFound());
        final cached = await localDataSource.getCachedCustomerDebts(userId);
        if (cached.isNotEmpty) return Right(cached);
        return Left(NetworkFailure.noConnection());
      } catch (_) {
        return Left(NetworkFailure.noConnection());
      }
    }
  }

  @override
  Future<Either<Failure, List<CustomerDebtModel>>> searchCustomerDebts(String query) async {
    if (await networkInfo.isConnected) {
      try {
        final debts = await remoteDataSource.searchCustomerDebts(query);
        final userId = await UserService.getUserId();
        if (userId != null) {
          await localDataSource.cacheCustomerDebts(userId, debts);
        }
        return Right(debts);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      try {
        final userId = await UserService.getUserId();
        if (userId == null) return Left(CacheFailure.notFound());
        final cached = await localDataSource.getCachedCustomerDebts(userId);
        final q = query.toLowerCase();
        final filtered = cached.where((d) =>
          d.name.toLowerCase().contains(q) ||
          (d.phone != null && d.phone!.contains(query)),
        ).toList();
        if (filtered.isNotEmpty) return Right(filtered);
        return Left(NetworkFailure.noConnection());
      } catch (_) {
        return Left(NetworkFailure.noConnection());
      }
    }
  }

  // إضافة دفعة جديدة مع التحقق من الاتصال
  @override
  Future<Either<Failure, void>> addPayment(String customerId, double amount, String? note, String paymentDate) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.addPayment(customerId, amount, note, paymentDate);
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

  @override
  Future<Either<Failure, CustomerDebtModel>> getCustomerDebt(String customerId) async {
    if (await networkInfo.isConnected) {
      try {
        final debt = await remoteDataSource.getCustomerDebt(customerId);
        return Right(debt);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      try {
        final userId = await UserService.getUserId();
        if (userId == null) return Left(CacheFailure.notFound());
        final cached = await localDataSource.getCachedCustomerDebts(userId);
        final match = cached.where((d) => d.id == customerId).toList();
        if (match.isNotEmpty) return Right(match.first);
        return Left(NetworkFailure.noConnection());
      } catch (_) {
        return Left(NetworkFailure.noConnection());
      }
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getCustomerInvoices(String customerId) async {
    if (await networkInfo.isConnected) {
      try {
        final invoices = await remoteDataSource.getCustomerInvoices(customerId);
        final userId = await UserService.getUserId();
        if (userId != null) {
          await localDataSource.cacheCustomerInvoices(userId, customerId, invoices);
        }
        return Right(invoices);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      try {
        final userId = await UserService.getUserId();
        if (userId == null) return Left(CacheFailure.notFound());
        final cached = await localDataSource.getCachedCustomerInvoices(userId, customerId);
        if (cached.isNotEmpty) return Right(cached);
        return Left(NetworkFailure.noConnection());
      } catch (_) {
        return Left(NetworkFailure.noConnection());
      }
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getCustomerPayments(String customerId) async {
    if (await networkInfo.isConnected) {
      try {
        final payments = await remoteDataSource.getCustomerPayments(customerId);
        final userId = await UserService.getUserId();
        if (userId != null) {
          await localDataSource.cacheCustomerPayments(userId, customerId, payments);
        }
        return Right(payments);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      try {
        final userId = await UserService.getUserId();
        if (userId == null) return Left(CacheFailure.notFound());
        final cached = await localDataSource.getCachedCustomerPayments(userId, customerId);
        if (cached.isNotEmpty) return Right(cached);
        return Left(NetworkFailure.noConnection());
      } catch (_) {
        return Left(NetworkFailure.noConnection());
      }
    }
  }

  // حذف دفعة مع التحقق من الاتصال
  @override
  Future<Either<Failure, void>> deletePayment(String paymentId, String customerId, double amount) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deletePayment(paymentId, customerId, amount);
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

  // دStream لمتابعة تغييرات رصيد العملاء
  @override
  Stream<Either<Failure, List<CustomerDebtModel>>> watchCustomerDebts() {
    return remoteDataSource.watchCustomerDebts().map(
      (debts) => Right<Failure, List<CustomerDebtModel>>(debts),
    ).handleError(
      (error) => Left<Failure, List<CustomerDebtModel>>(ServerFailure(error.toString())),
    );
  }
}
