import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/features/invoices/data/models/sales_invoice.dart';
import 'package:erad/features/invoices/data/models/purchase_invoice.dart';
import 'package:erad/features/invoices/data/models/invoice_item.dart';
import '../datasources/edit_invoice_datasource.dart';

abstract class EditInvoiceRepository {
  Future<Either<Failure, SalesInvoice>> getSalesInvoiceForEdit(String id);
  Future<Either<Failure, PurchaseInvoice>> getPurchaseInvoiceForEdit(String id);
  Future<Either<Failure, SalesInvoice>> updateSalesInvoice(
    SalesInvoice invoice,
    List<InvoiceItem> newItems,
  );
  Future<Either<Failure, PurchaseInvoice>> updatePurchaseInvoice(
    PurchaseInvoice invoice,
    List<InvoiceItem> newItems,
  );
  Future<Either<Failure, void>> updateCustomerBalance(
    String customerId,
    double amount,
  );
  Future<Either<Failure, void>> updateSupplierBalance(
    String supplierId,
    double amount,
  );
}

class EditInvoiceRepositoryImpl implements EditInvoiceRepository {
  final EditInvoiceDataSource dataSource;

  EditInvoiceRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, SalesInvoice>> getSalesInvoiceForEdit(
    String id,
  ) async {
    try {
      final invoice = await dataSource.getSalesInvoiceForEdit(id);
      return Right(invoice);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseInvoice>> getPurchaseInvoiceForEdit(
    String id,
  ) async {
    try {
      final invoice = await dataSource.getPurchaseInvoiceForEdit(id);
      return Right(invoice);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SalesInvoice>> updateSalesInvoice(
    SalesInvoice invoice,
    List<InvoiceItem> newItems,
  ) async {
    try {
      final updatedInvoice = await dataSource.updateSalesInvoice(
        invoice,
        newItems,
      );
      return Right(updatedInvoice);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseInvoice>> updatePurchaseInvoice(
    PurchaseInvoice invoice,
    List<InvoiceItem> newItems,
  ) async {
    try {
      final updatedInvoice = await dataSource.updatePurchaseInvoice(
        invoice,
        newItems,
      );
      return Right(updatedInvoice);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomerBalance(
    String customerId,
    double amount,
  ) async {
    try {
      await dataSource.updateCustomerBalance(customerId, amount);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateSupplierBalance(
    String supplierId,
    double amount,
  ) async {
    try {
      await dataSource.updateSupplierBalance(supplierId, amount);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
