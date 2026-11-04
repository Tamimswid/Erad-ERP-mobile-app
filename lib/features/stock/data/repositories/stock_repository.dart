import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/paged_result.dart';
import '../datasources/stock_remote_datasource.dart';
import '../models/stock_category.dart';
import '../models/stock_review_item.dart';

class StockRepository {
  StockRepository(this._remoteDataSource, this._networkInfo);

  final StockRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  Future<Either<Failure, PagedResult<StockReviewItem>>> getStockPage({
    required int offset,
    int limit = 10,
    String? search,
    String? categoryId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Left(NetworkFailure.noConnection());
    }
    try {
      final page = await _remoteDataSource.getStockPage(
        offset: offset,
        limit: limit,
        search: search,
        categoryId: categoryId,
      );
      return Right(page);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(exceptionToFailure(e));
    }
  }

  Future<Either<Failure, List<StockCategory>>> getCategories() async {
    if (!await _networkInfo.isConnected) {
      return Left(NetworkFailure.noConnection());
    }
    try {
      final categories = await _remoteDataSource.getCategories();
      return Right(categories);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(exceptionToFailure(e));
    }
  }
}
