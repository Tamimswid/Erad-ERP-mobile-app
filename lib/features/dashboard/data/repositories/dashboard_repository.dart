import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/user_service.dart';
import '../models/dashboard_financials.dart';
import '../models/dashboard_product_stock.dart';
import '../datasource/dashboard_remote_datasource.dart';
import '../datasource/dashboard_local_datasource.dart';

class DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final DashboardLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  DashboardRepository(this.remoteDataSource, this.localDataSource, this.networkInfo);

  Future<Either<Failure, DashboardFinancialsModel>> getFinancials() async {
    if (await networkInfo.isConnected) {
      try {
        final financials = await remoteDataSource.getFinancials();
        final userId = await UserService.getUserId();
        if (userId != null) {
          await localDataSource.cacheFinancials(userId, financials);
        }
        return Right(financials);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      try {
        final userId = await UserService.getUserId();
        if (userId == null) return Left(ServerFailure('User not found'));
        final cached = await localDataSource.getCachedFinancials(userId);
        if (cached != null) return Right(cached);
        return Left(NetworkFailure.noConnection());
      } catch (_) {
        return Left(NetworkFailure.noConnection());
      }
    }
  }

  Future<Either<Failure, List<DashboardProductStockModel>>> getProductStock() async {
    if (await networkInfo.isConnected) {
      try {
        final stock = await remoteDataSource.getProductStock();
        final userId = await UserService.getUserId();
        if (userId != null) {
          await localDataSource.cacheProductStock(userId, stock);
        }
        return Right(stock);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      try {
        final userId = await UserService.getUserId();
        if (userId == null) return Left(ServerFailure('User not found'));
        final cached = await localDataSource.getCachedProductStock(userId);
        if (cached.isNotEmpty) return Right(cached);
        return Left(NetworkFailure.noConnection());
      } catch (_) {
        return Left(NetworkFailure.noConnection());
      }
    }
  }
}
