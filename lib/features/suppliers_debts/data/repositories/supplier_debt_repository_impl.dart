import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/core/network/network_info.dart';
import 'package:erad/features/suppliers_debts/data/datasource/supplier_debt_remote_datasource.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_model.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_totals_model.dart';
import 'package:erad/features/suppliers_debts/data/repositories/supplier_debt_repository.dart';

class SupplierDebtRepositoryImpl implements SupplierDebtRepository {
  final SupplierDebtRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  SupplierDebtRepositoryImpl(this.remoteDataSource, this.networkInfo);

  @override
  Future<Either<Failure, List<SupplierDebtModel>>> getSupplierDebts() async {
    if (await networkInfo.isConnected) {
      try {
        final debts = await remoteDataSource.getSupplierDebts();
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

  @override
  Future<Either<Failure, SupplierDebtTotalsModel>> getSupplierDebtTotals() async {
    if (await networkInfo.isConnected) {
      try {
        final totals = await remoteDataSource.getSupplierDebtTotals();
        return Right(totals);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  @override
  Future<Either<Failure, List<SupplierDebtModel>>> searchSupplierDebts(String query) async {
    if (await networkInfo.isConnected) {
      try {
        final debts = await remoteDataSource.searchSupplierDebts(query);
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

  @override
  Future<Either<Failure, void>> addPayment(String supplierId, double amount, String? note, String paymentDate) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.addPayment(supplierId, amount, note, paymentDate);
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
  Future<Either<Failure, SupplierDebtModel>> getSupplierDebt(String supplierId) async {
    if (await networkInfo.isConnected) {
      try {
        final debt = await remoteDataSource.getSupplierDebt(supplierId);
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

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getSupplierInvoices(String supplierId) async {
    if (await networkInfo.isConnected) {
      try {
        final invoices = await remoteDataSource.getSupplierInvoices(supplierId);
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

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getSupplierPayments(String supplierId) async {
    if (await networkInfo.isConnected) {
      try {
        final payments = await remoteDataSource.getSupplierPayments(supplierId);
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

  @override
  Future<Either<Failure, void>> deletePayment(String paymentId, String supplierId, double amount) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deletePayment(paymentId, supplierId, amount);
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
  Stream<Either<Failure, List<SupplierDebtModel>>> watchSupplierDebts() {
    return remoteDataSource.watchSupplierDebts().map(
      (debts) => Right<Failure, List<SupplierDebtModel>>(debts),
    ).handleError(
      (error) => Left<Failure, List<SupplierDebtModel>>(ServerFailure(error.toString())),
    );
  }
}