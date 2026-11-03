import 'dart:async';

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/paged_result.dart';
import '../models/sales_invoice.dart';
import '../models/purchase_invoice.dart';
import '../datasources/invoice_local_datasource.dart';
import '../datasources/invoice_remote_datasource.dart';

abstract class InvoiceRepository {
  // جلب جميع فواتير البيع
  Future<Either<Failure, List<SalesInvoice>>> getSalesInvoices();
  // جلب جميع فواتير الشراء
  Future<Either<Failure, List<PurchaseInvoice>>> getPurchaseInvoices();
  // جلب صفحة من فواتير البيع
  Future<Either<Failure, PagedResult<SalesInvoice>>> getSalesInvoicesPage({
    required int offset,
    int limit = 10,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
  });
  // جلب صفحة من فواتير الشراء
  Future<Either<Failure, PagedResult<PurchaseInvoice>>> getPurchaseInvoicesPage({
    required int offset,
    int limit = 10,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
  });
  // دStream لفواتير البيع في الوقت الفعلي
  Stream<Either<Failure, List<SalesInvoice>>> watchSalesInvoices();
  // دStream لفواتير الشراء في الوقت الفعلي
  Stream<Either<Failure, List<PurchaseInvoice>>> watchPurchaseInvoices();
  // جلب فاتورة بيع بالمعرف
  Future<Either<Failure, SalesInvoice>> getSalesInvoiceById(String id);
  // جلب فاتورة شراء بالمعرف
  Future<Either<Failure, PurchaseInvoice>> getPurchaseInvoiceById(String id);
  // إنشاء فاتورة بيع جديدة
  Future<Either<Failure, SalesInvoice>> createSalesInvoice(SalesInvoice invoice);
  // إنشاء فاتورة شراء جديدة
  Future<Either<Failure, PurchaseInvoice>> createPurchaseInvoice(PurchaseInvoice invoice);
  // تحديث فاتورة بيع
  Future<Either<Failure, SalesInvoice>> updateSalesInvoice(SalesInvoice invoice);
  // تحديث فاتورة شراء
  Future<Either<Failure, PurchaseInvoice>> updatePurchaseInvoice(PurchaseInvoice invoice);
  // حذف فاتورة بيع
  Future<Either<Failure, void>> deleteSalesInvoice(String id);
  // حذف فاتورة شراء
  Future<Either<Failure, void>> deletePurchaseInvoice(String id);
  // إنهاء فاتورة بيع
  Future<Either<Failure, void>> finalizeSalesInvoice(String id);
  // إنهاء فاتورة شراء
  Future<Either<Failure, void>> finalizePurchaseInvoice(String id);
  // تحديث رصيد العميل
  Future<Either<Failure, void>> updateCustomerBalance(String customerId, double amount);
}

// تنفيذ مستودع الفواتير - يغلف datasource ويعالج الأخطاء
class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDataSource remoteDataSource;
  final InvoiceLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  InvoiceRepositoryImpl(this.remoteDataSource, this.localDataSource, this.networkInfo);

  @override
  Future<Either<Failure, List<SalesInvoice>>> getSalesInvoices() async {
    if (await networkInfo.isConnected) {
      try {
        final invoices = await remoteDataSource.getSalesInvoices();
        final userId = await UserService.getUserId();
        if (userId != null) {
          await localDataSource.cacheSalesInvoices(userId, invoices);
        }
        return Right(invoices);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      try {
        final userId = await UserService.getUserId();
        if (userId == null) return Left(ServerFailure('User not found'));
        final cached = await localDataSource.getCachedSalesInvoices(userId);
        if (cached.isNotEmpty) return Right(cached);
        return Left(NetworkFailure.noConnection());
      } catch (_) {
        return Left(NetworkFailure.noConnection());
      }
    }
  }

  @override
  Future<Either<Failure, List<PurchaseInvoice>>> getPurchaseInvoices() async {
    if (await networkInfo.isConnected) {
      try {
        final invoices = await remoteDataSource.getPurchaseInvoices();
        final userId = await UserService.getUserId();
        if (userId != null) {
          await localDataSource.cachePurchaseInvoices(userId, invoices);
        }
        return Right(invoices);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      try {
        final userId = await UserService.getUserId();
        if (userId == null) return Left(ServerFailure('User not found'));
        final cached = await localDataSource.getCachedPurchaseInvoices(userId);
        if (cached.isNotEmpty) return Right(cached);
        return Left(NetworkFailure.noConnection());
      } catch (_) {
        return Left(NetworkFailure.noConnection());
      }
    }
  }

  @override
  Future<Either<Failure, PagedResult<SalesInvoice>>> getSalesInvoicesPage({
    required int offset,
    int limit = 10,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getSalesInvoicesPage(
          offset: offset,
          limit: limit,
          status: status,
          dateFrom: dateFrom,
          dateTo: dateTo,
          search: search,
        );
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }

    try {
      final userId = await UserService.getUserId();
      if (userId == null) return Left(ServerFailure('User not found'));
      final cached = await localDataSource.getCachedSalesInvoices(userId);
      final filtered = cached
          .where((invoice) {
            if (status != null &&
                status != 'all' &&
                invoice.paymentStatus.name != status) {
              return false;
            }
            if (dateFrom != null && invoice.invoiceDate.isBefore(dateFrom)) {
              return false;
            }
            if (dateTo != null && invoice.invoiceDate.isAfter(dateTo)) {
              return false;
            }
            if (search != null && search.trim().isNotEmpty) {
              final term = search.toLowerCase();
              final number = invoice.invoiceNumber.toLowerCase();
              final party = invoice.customerName?.toLowerCase() ?? '';
              if (!number.contains(term) && !party.contains(term)) return false;
            }
            return true;
          })
          .toList()
        ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
      final page = _slice(filtered, offset, limit);
      return Right(page);
    } catch (_) {
      return Left(NetworkFailure.noConnection());
    }
  }

  @override
  Future<Either<Failure, PagedResult<PurchaseInvoice>>> getPurchaseInvoicesPage({
    required int offset,
    int limit = 10,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPurchaseInvoicesPage(
          offset: offset,
          limit: limit,
          status: status,
          dateFrom: dateFrom,
          dateTo: dateTo,
          search: search,
        );
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    }

    try {
      final userId = await UserService.getUserId();
      if (userId == null) return Left(ServerFailure('User not found'));
      final cached = await localDataSource.getCachedPurchaseInvoices(userId);
      final filtered = cached
          .where((invoice) {
            if (status != null &&
                status != 'all' &&
                invoice.paymentStatus.name != status) {
              return false;
            }
            if (dateFrom != null && invoice.invoiceDate.isBefore(dateFrom)) {
              return false;
            }
            if (dateTo != null && invoice.invoiceDate.isAfter(dateTo)) {
              return false;
            }
            if (search != null && search.trim().isNotEmpty) {
              final term = search.toLowerCase();
              final number = invoice.invoiceNumber.toLowerCase();
              final party = invoice.supplierName?.toLowerCase() ?? '';
              if (!number.contains(term) && !party.contains(term)) return false;
            }
            return true;
          })
          .toList()
        ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
      final page = _slice(filtered, offset, limit);
      return Right(page);
    } catch (_) {
      return Left(NetworkFailure.noConnection());
    }
  }

  PagedResult<T> _slice<T>(List<T> items, int offset, int limit) {
    final start = offset.clamp(0, items.length);
    final end = (start + limit).clamp(0, items.length);
    return PagedResult(
      items: items.sublist(start, end),
      hasMore: end < items.length,
    );
  }

  @override
  Future<Either<Failure, SalesInvoice>> getSalesInvoiceById(String id) async {
    try {
      final invoice = await remoteDataSource.getSalesInvoiceById(id);
      return Right(invoice);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseInvoice>> getPurchaseInvoiceById(String id) async {
    try {
      final invoice = await remoteDataSource.getPurchaseInvoiceById(id);
      return Right(invoice);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SalesInvoice>> createSalesInvoice(SalesInvoice invoice) async {
    try {
      final createdInvoice = await remoteDataSource.createSalesInvoice(invoice);
      return Right(createdInvoice);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseInvoice>> createPurchaseInvoice(PurchaseInvoice invoice) async {
    try {
      final createdInvoice = await remoteDataSource.createPurchaseInvoice(invoice);
      return Right(createdInvoice);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SalesInvoice>> updateSalesInvoice(SalesInvoice invoice) async {
    try {
      final updatedInvoice = await remoteDataSource.updateSalesInvoice(invoice);
      return Right(updatedInvoice);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseInvoice>> updatePurchaseInvoice(PurchaseInvoice invoice) async {
    try {
      final updatedInvoice = await remoteDataSource.updatePurchaseInvoice(invoice);
      return Right(updatedInvoice);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSalesInvoice(String id) async {
    try {
      await remoteDataSource.deleteSalesInvoice(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePurchaseInvoice(String id) async {
    try {
      await remoteDataSource.deletePurchaseInvoice(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> finalizeSalesInvoice(String id) async {
    try {
      await remoteDataSource.finalizeSalesInvoice(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> finalizePurchaseInvoice(String id) async {
    try {
      await remoteDataSource.finalizePurchaseInvoice(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomerBalance(String customerId, double amount) async {
    try {
      await remoteDataSource.updateCustomerBalance(customerId, amount);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<SalesInvoice>>> watchSalesInvoices() {
    return remoteDataSource.watchSalesInvoices().map(
      (invoices) => Right<Failure, List<SalesInvoice>>(invoices),
    ).handleError(
      (error) => Left<Failure, List<SalesInvoice>>(ServerFailure(error.toString())),
    );
  }

  @override
  Stream<Either<Failure, List<PurchaseInvoice>>> watchPurchaseInvoices() {
    return remoteDataSource.watchPurchaseInvoices().map(
      (invoices) => Right<Failure, List<PurchaseInvoice>>(invoices),
    ).handleError(
      (error) => Left<Failure, List<PurchaseInvoice>>(ServerFailure(error.toString())),
    );
  }
}
