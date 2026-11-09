import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/core/utils/paged_result.dart';
import 'package:erad/features/invoices/data/models/purchase_invoice.dart';
import 'package:erad/features/invoices/data/models/sales_invoice.dart';
import '../datasources/report_remote_datasource.dart';

abstract class ReportRepository {
  Future<Either<Failure, List<SalesInvoice>>> getSalesInvoicesByCustomer(
    String customerId, {
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, List<PurchaseInvoice>>> getPurchaseInvoicesBySupplier(
    String supplierId, {
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, PagedResult<SalesInvoice>>> getSalesInvoicesPage({
    required String customerId,
    required int offset,
    int limit = 10,
    String? year,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, PagedResult<PurchaseInvoice>>>
  getPurchaseInvoicesPage({
    required String supplierId,
    required int offset,
    int limit = 10,
    String? year,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<Either<Failure, List<String>>> getSalesInvoiceYears(String customerId);
  Future<Either<Failure, List<String>>> getPurchaseInvoiceYears(
    String supplierId,
  );
}

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _remoteDataSource;

  ReportRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<SalesInvoice>>> getSalesInvoicesByCustomer(
    String customerId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final invoices = await _remoteDataSource.getSalesInvoicesByCustomer(
        customerId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(invoices);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseInvoice>>> getPurchaseInvoicesBySupplier(
    String supplierId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final invoices = await _remoteDataSource.getPurchaseInvoicesBySupplier(
        supplierId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(invoices);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PagedResult<SalesInvoice>>> getSalesInvoicesPage({
    required String customerId,
    required int offset,
    int limit = 10,
    String? year,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final page = await _remoteDataSource.getSalesInvoicesPage(
        customerId: customerId,
        offset: offset,
        limit: limit,
        year: year,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(page);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PagedResult<PurchaseInvoice>>>
  getPurchaseInvoicesPage({
    required String supplierId,
    required int offset,
    int limit = 10,
    String? year,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final page = await _remoteDataSource.getPurchaseInvoicesPage(
        supplierId: supplierId,
        offset: offset,
        limit: limit,
        year: year,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(page);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getSalesInvoiceYears(
    String customerId,
  ) async {
    try {
      final years = await _remoteDataSource.getSalesInvoiceYears(customerId);
      return Right(years);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getPurchaseInvoiceYears(
    String supplierId,
  ) async {
    try {
      final years = await _remoteDataSource.getPurchaseInvoiceYears(supplierId);
      return Right(years);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
