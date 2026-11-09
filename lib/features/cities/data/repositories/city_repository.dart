import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../datasource/city_remote_datasource.dart';
import '../models/city.dart';

class CityRepository {
  final CityRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CityRepository(this.remoteDataSource, this.networkInfo);

  Future<Either<Failure, List<CityModel>>> getCities() async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure.noConnection());
    }

    try {
      final cities = await remoteDataSource.getCities();
      return Right(cities);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(exceptionToFailure(e));
    }
  }
}
