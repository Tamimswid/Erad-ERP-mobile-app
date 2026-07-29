import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/features/invoices/data/models/purchase_invoice.dart';
import 'package:erad/features/invoices/data/models/sales_invoice.dart';
import '../datasources/report_remote_datasource.dart';

abstract class ReportRepository {
  Future<Either<Failure, List<SalesInvoice>>> getSalesInvoicesByCustomer(String customerId);
  Future<Either<Failure, List<PurchaseInvoice>>> getPurchaseInvoicesBySupplier(String supplierId);
}

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _remoteDataSource;

  ReportRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<SalesInvoice>>> getSalesInvoicesByCustomer(String customerId) async {
    try {
      final invoices = await _remoteDataSource.getSalesInvoicesByCustomer(customerId);
      return Right(invoices);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseInvoice>>> getPurchaseInvoicesBySupplier(String supplierId) async {
    try {
      final invoices = await _remoteDataSource.getPurchaseInvoicesBySupplier(supplierId);
      return Right(invoices);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
