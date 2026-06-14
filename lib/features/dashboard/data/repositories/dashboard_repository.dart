import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../models/dashboard_financials.dart';
import '../models/dashboard_product_stock.dart';
import '../datasource/dashboard_remote_datasource.dart';

class DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  DashboardRepository(this.remoteDataSource, this.networkInfo);

  Future<Either<Failure, DashboardFinancialsModel>> getFinancials() async {
    if (await networkInfo.isConnected) {
      try {
        final financials = await remoteDataSource.getFinancials();
        return Right(financials);
      } on Failure catch (failure) {
        return Left(failure);
      } catch (e) {
        return Left(exceptionToFailure(e));
      }
    } else {
      return Left(NetworkFailure.noConnection());
    }
  }

  Future<Either<Failure, List<DashboardProductStockModel>>> getProductStock() async {
    if (await networkInfo.isConnected) {
      try {
        final stock = await remoteDataSource.getProductStock();
        return Right(stock);
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
