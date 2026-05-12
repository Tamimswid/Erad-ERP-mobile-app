import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../models/supplier.dart';
import '../datasource/supplier_remote_datasource.dart';

class SupplierRepository {
  final SupplierRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  SupplierRepository(this.remoteDataSource, this.networkInfo);

  Future<Either<Failure, List<SupplierModel>>> getSuppliers() async {
    if (await networkInfo.isConnected) {
      try {
        final suppliers = await remoteDataSource.getSuppliers();
        return Right(suppliers);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  // Stream للموردين في الوقت الفعلي
  Stream<Either<Failure, List<SupplierModel>>> watchSuppliers() {
    return remoteDataSource.watchSuppliers().map(
          (suppliers) => Right<Failure, List<SupplierModel>>(suppliers),
        ).handleError(
          (error) => Left<Failure, List<SupplierModel>>(exceptionToFailure(error)),
        );
  }

  Future<Either<Failure, SupplierModel>> getSupplier(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final supplier = await remoteDataSource.getSupplier(id);
        return Right(supplier);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, SupplierModel>> createSupplier(SupplierModel supplier) async {
    if (await networkInfo.isConnected) {
      try {
        final createdSupplier = await remoteDataSource.createSupplier(supplier);
        return Right(createdSupplier);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, SupplierModel>> updateSupplier(SupplierModel supplier) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedSupplier = await remoteDataSource.updateSupplier(supplier);
        return Right(updatedSupplier);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, void>> deleteSupplier(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteSupplier(id);
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

  Future<Either<Failure, List<SupplierModel>>> searchSuppliers(String query) async {
    if (await networkInfo.isConnected) {
      try {
        final suppliers = await remoteDataSource.searchSuppliers(query);
        return Right(suppliers);
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
