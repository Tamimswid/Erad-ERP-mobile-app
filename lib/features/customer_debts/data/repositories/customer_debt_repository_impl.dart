import 'dart:async';
import 'dart:developer' as dev;

import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/core/network/network_info.dart';
import 'package:erad/core/services/user_service.dart';
import 'package:erad/features/customer_debts/data/datasource/customer_debt_remote_datasource.dart';
import 'package:erad/features/customer_debts/data/datasource/customer_debt_local_datasource.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_model.dart';
import 'package:erad/features/customer_debts/data/models/customer_debt_totals_model.dart';
import 'package:erad/features/customer_debts/data/repositories/customer_debt_repository.dart';

// تنفيذ مستودع ديون العملاء - يتحقق من الاتصال ويعالج الأخطاء
class CustomerDebtRepositoryImpl implements CustomerDebtRepository {
  final CustomerDebtRemoteDataSource remoteDataSource;
  final CustomerDebtLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  StreamSubscription<bool>? _connectionSubscription;

  CustomerDebtRepositoryImpl(this.remoteDataSource, this.localDataSource, this.networkInfo) {
    _connectionSubscription = networkInfo.connectionStream.listen((isConnected) {
      dev.log('CustomerDebtRepo: connection changed -> $isConnected');
      if (isConnected) {
        dev.log('CustomerDebtRepo: Connection restored, syncing pending payments...');
        syncPendingPayments();
      }
    });
  }

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
        if (userId == null) {
          dev.log('getCustomerDebts offline: userId null');
          return Left(CacheFailure.notFound());
        }
        final cached = await localDataSource.getCachedCustomerDebts(userId);
        dev.log('getCustomerDebts offline: found ${cached.length} cached debts');
        if (cached.isNotEmpty) return Right(cached);
        dev.log('getCustomerDebts offline: cache empty');
        return Left(NetworkFailure.noConnection());
      } catch (e) {
        dev.log('getCustomerDebts offline error: $e');
        return Left(NetworkFailure.noConnection());
      }
    }
  }

  @override
  Future<Either<Failure, CustomerDebtTotalsModel>> getCustomerDebtTotals() async {
    if (await networkInfo.isConnected) {
      try {
        final totals = await remoteDataSource.getCustomerDebtTotals();
        return Right(totals);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
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

  @override
  Future<Either<Failure, void>> addPayment(String customerId, double amount, String? note, String paymentDate) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.addPayment(customerId, amount, note, paymentDate);
        await syncPendingPayments();
        return const Right(null);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        dev.log('addPayment remote error: $e');
        return Left(exceptionToFailure(e));
      }
    } else {
      try {
        final userId = await UserService.getUserId();
        if (userId == null) {
          dev.log('addPayment offline: userId null');
          return Left(CacheFailure.notFound());
        }
        dev.log('addPayment offline: queuing for userId=$userId customerId=$customerId amount=$amount');
        await localDataSource.queuePayment({
          'id': 'pending_${DateTime.now().millisecondsSinceEpoch}',
          'user_id': userId,
          'customer_id': customerId,
          'amount': amount,
          'notes': note,
          'payment_date': paymentDate,
          'created_at': DateTime.now().toIso8601String(),
        });
        await localDataSource.updateDebtAfterPayment(userId, customerId, amount);
        await localDataSource.addPaymentToLocalCache(userId, customerId, {
          'id': 'pending_${DateTime.now().millisecondsSinceEpoch}',
          'user_id': userId,
          'customer_id': customerId,
          'amount': amount,
          'notes': note,
          'payment_date': paymentDate,
          'payment_method': 'نقداً',
          'payment_type': 'customer',
          'created_at': DateTime.now().toIso8601String(),
        });
        dev.log('addPayment offline: queued and caches updated');
        return const Right(null);
      } catch (e) {
        dev.log('addPayment offline error: $e');
        return Left(CacheFailure.writeError());
      }
    }
  }

  Future<void> syncPendingPayments() async {
    dev.log('syncPendingPayments: starting...');
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        dev.log('syncPendingPayments: userId null');
        return;
      }
      final pending = await localDataSource.getPendingPayments(userId);
      dev.log('syncPendingPayments: found ${pending.length} pending payments');
      for (final payment in pending) {
        try {
          dev.log('syncPendingPayments: sending payment ${payment['id']} for customer ${payment['customer_id']} amount ${payment['amount']}');
          await remoteDataSource.addPayment(
            payment['customer_id'] as String,
            (payment['amount'] as num).toDouble(),
            payment['notes'] as String?,
            payment['payment_date'] as String,
          );
          await localDataSource.deletePendingPayment(payment['id'] as String);
          dev.log('syncPendingPayments: payment ${payment['id']} synced and deleted');
        } catch (e) {
          dev.log('syncPendingPayments: failed for ${payment['id']}: $e');
          break;
        }
      }
      dev.log('syncPendingPayments: done');
    } catch (e) {
      dev.log('syncPendingPayments: error $e');
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
        return const Right([]);
      } catch (_) {
        return const Right([]);
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
        return const Right([]);
      } catch (_) {
        return const Right([]);
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

  @override
  Stream<Either<Failure, List<CustomerDebtModel>>> watchCustomerDebts() {
    return remoteDataSource.watchCustomerDebts().map(
      (debts) => Right<Failure, List<CustomerDebtModel>>(debts),
    ).handleError(
      (_) => null,
    );
  }
}
