import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/core/network/network_info.dart';
import 'package:erad/core/utils/paged_result.dart';
import 'package:erad/features/suppliers_debts/data/datasource/supplier_debt_remote_datasource.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_model.dart';
import 'package:erad/features/suppliers_debts/data/models/supplier_debt_totals_model.dart';
import 'package:erad/features/suppliers_debts/data/repositories/supplier_debt_repository.dart';

class SupplierDebtRepositoryImpl implements SupplierDebtRepository {
  final SupplierDebtRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  SupplierDebtRepositoryImpl(this.remoteDataSource, this.networkInfo);

  @override
  Future<Either<Failure, PagedResult<SupplierDebtModel>>> getSupplierDebtsPage({
    required int offset,
    int limit = 10,
    String? search,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final page = await remoteDataSource.getSupplierDebtsPage(
          offset: offset,
          limit: limit,
          search: search,
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

  @override
  Future<Either<Failure, int>> getSupplierDebtCount({String? search}) async {
    if (await networkInfo.isConnected) {
      try {
        final count = await remoteDataSource.getSupplierDebtCount(
          search: search,
        );
        return Right(count);
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
  Future<Either<Failure, SupplierDebtTotalsModel>>
  getSupplierDebtTotals() async {
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
  Future<Either<Failure, void>> addPayment(
    String supplierId,
    double amount,
    String? note,
    String paymentDate,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.addPayment(
          supplierId,
          amount,
          note,
          paymentDate,
        );
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
  Future<Either<Failure, SupplierDebtModel>> getSupplierDebt(
    String supplierId,
  ) async {
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
  Future<Either<Failure, List<Map<String, dynamic>>>> getSupplierInvoices(
    String supplierId,
  ) async {
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
  Future<Either<Failure, List<Map<String, dynamic>>>> getSupplierPayments(
    String supplierId,
  ) async {
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
  Future<Either<Failure, PagedResult<Map<String, dynamic>>>>
  getSupplierInvoicesPage(
    String supplierId, {
    required int offset,
    int limit = 10,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final page = await remoteDataSource.getSupplierInvoicesPage(
          supplierId,
          offset: offset,
          limit: limit,
        );
        return Right(page);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    }
    return Left(NetworkFailure.noConnection());
  }

  @override
  Future<Either<Failure, PagedResult<Map<String, dynamic>>>>
  getSupplierPaymentsPage(
    String supplierId, {
    required int offset,
    int limit = 10,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final page = await remoteDataSource.getSupplierPaymentsPage(
          supplierId,
          offset: offset,
          limit: limit,
        );
        return Right(page);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    }
    return Left(NetworkFailure.noConnection());
  }

  @override
  Future<Either<Failure, double>> getSupplierInvoiceTotal(
    String supplierId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final total = await remoteDataSource.getSupplierInvoiceTotal(
          supplierId,
        );
        return Right(total);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    }
    return Left(NetworkFailure.noConnection());
  }

  @override
  Future<Either<Failure, double>> getSupplierPaymentTotal(
    String supplierId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final total = await remoteDataSource.getSupplierPaymentTotal(
          supplierId,
        );
        return Right(total);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    }
    return Left(NetworkFailure.noConnection());
  }

  @override
  Future<Either<Failure, void>> deletePayment(
    String paymentId,
    String supplierId,
    double amount,
  ) async {
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
}
