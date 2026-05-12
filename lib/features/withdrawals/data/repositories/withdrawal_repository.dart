import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../models/withdrawal.dart';
import '../models/partner.dart';
import '../datasource/withdrawal_remote_datasource.dart';

class WithdrawalRepository {
  final WithdrawalRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  WithdrawalRepository(this.remoteDataSource, this.networkInfo);

  Future<Either<Failure, List<Withdrawal>>> getWithdrawals({DateTime? startDate, DateTime? endDate, String? partnerId}) async {
    if (await networkInfo.isConnected) {
      try {
        final withdrawals = await remoteDataSource.getWithdrawals(startDate: startDate, endDate: endDate, partnerId: partnerId);
        return Right(withdrawals);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, Withdrawal>> getWithdrawal(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final withdrawal = await remoteDataSource.getWithdrawal(id);
        return Right(withdrawal);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, Withdrawal>> createWithdrawal(Withdrawal withdrawal) async {
    if (await networkInfo.isConnected) {
      try {
        final createdWithdrawal = await remoteDataSource.createWithdrawal(withdrawal);
        return Right(createdWithdrawal);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, Withdrawal>> updateWithdrawal(Withdrawal withdrawal) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedWithdrawal = await remoteDataSource.updateWithdrawal(withdrawal);
        return Right(updatedWithdrawal);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, void>> deleteWithdrawal(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteWithdrawal(id);
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

  Future<Either<Failure, List<Partner>>> getPartners() async {
    if (await networkInfo.isConnected) {
      try {
        final partners = await remoteDataSource.getPartners();
        return Right(partners);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, Partner>> createPartner(Partner partner) async {
    if (await networkInfo.isConnected) {
      try {
        final createdPartner = await remoteDataSource.createPartner(partner);
        return Right(createdPartner);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, void>> deletePartner(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deletePartner(id);
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

  Stream<Either<Failure, List<Withdrawal>>> watchWithdrawals({String? partnerId}) {
    try {
      return remoteDataSource.watchWithdrawals(partnerId: partnerId)
          .map((data) => Right<Failure, List<Withdrawal>>(data));
    } catch (e) {
      return Stream.value(Left(exceptionToFailure(e)));
    }
  }

  Stream<Either<Failure, List<Partner>>> watchPartners() {
    try {
      return remoteDataSource.watchPartners()
          .map((data) => Right<Failure, List<Partner>>(data));
    } catch (e) {
      return Stream.value(Left(exceptionToFailure(e)));
    }
  }
}
