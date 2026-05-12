import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/core/network/network_info.dart';
import 'package:erad/features/customer_debts/data/datasource/customer_debt_remote_datasource.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_model.dart';
import 'package:erad/features/customer_debts/data/repositories/customer_debt_repository.dart';

// تنفيذ مستودع ديون العملاء - يتحقق من الاتصال ويعالج الأخطاء
class CustomerDebtRepositoryImpl implements CustomerDebtRepository {
  final CustomerDebtRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CustomerDebtRepositoryImpl(this.remoteDataSource, this.networkInfo);

  // جلب جميع ديون العملاء مع التحقق من الاتصال
  @override
  Future<Either<Failure, List<CustomerDebtModel>>> getCustomerDebts() async {
    if (await networkInfo.isConnected) {
      try {
        final debts = await remoteDataSource.getCustomerDebts();
        return Right(debts);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  // البحث عن ديون العملاء مع التحقق من الاتصال
  @override
  Future<Either<Failure, List<CustomerDebtModel>>> searchCustomerDebts(String query) async {
    if (await networkInfo.isConnected) {
      try {
        final debts = await remoteDataSource.searchCustomerDebts(query);
        return Right(debts);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
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

  // جلب ديون عميل محدد مع التحقق من الاتصال
  @override
  Future<Either<Failure, CustomerDebtModel>> getCustomerDebt(String customerId) async {
    if (await networkInfo.isConnected) {
      try {
        final debt = await remoteDataSource.getCustomerDebt(customerId);
        return Right(debt);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  // جلب فواتير العميل مع التحقق من الاتصال
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getCustomerInvoices(String customerId) async {
    if (await networkInfo.isConnected) {
      try {
        final invoices = await remoteDataSource.getCustomerInvoices(customerId);
        return Right(invoices);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  // جلب دفعات العميل مع التحقق من الاتصال
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getCustomerPayments(String customerId) async {
    if (await networkInfo.isConnected) {
      try {
        final payments = await remoteDataSource.getCustomerPayments(customerId);
        return Right(payments);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
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
