import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/features/app_status/data/datasource/app_status_remote_datasource.dart';

class AppStatusRepository {
  final AppStatusRemoteDataSource remoteDataSource;

  AppStatusRepository({required this.remoteDataSource});

  Future<Either<Failure, bool>> checkAppStatus() async {
    try {
      final isActive = await remoteDataSource.checkAppStatus();
      return Right(isActive);
    } catch (e) {
      return Left(ServerFailure.internalServerError());
    }
  }
}
