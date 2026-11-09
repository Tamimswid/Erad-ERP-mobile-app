import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/core/network/network_info.dart';
import 'package:erad/features/comparison_points/data/datasource/comparison_point_remote_datasource.dart';
import 'package:erad/features/comparison_points/data/models/comparison_point_model.dart';
import 'package:erad/features/comparison_points/data/repositories/comparison_point_repository.dart';

class ComparisonPointRepositoryImpl implements ComparisonPointRepository {
  final ComparisonPointRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ComparisonPointRepositoryImpl(this.remoteDataSource, this.networkInfo);

  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure.noConnection());
    }
    try {
      return Right(await action());
    } catch (e) {
      return Left(exceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<ComparisonPointModel>>> getPoints({
    required ComparisonPartyType partyType,
    required String partyId,
  }) => _run(
    () => remoteDataSource.getPoints(partyType: partyType, partyId: partyId),
  );

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPointInvoices(
    String pointId,
  ) => _run(() => remoteDataSource.getPointInvoices(pointId));

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPointPayments(
    String pointId,
  ) => _run(() => remoteDataSource.getPointPayments(pointId));

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getUnassignedInvoices({
    required ComparisonPartyType partyType,
    required String partyId,
  }) => _run(
    () => remoteDataSource.getUnassignedInvoices(
      partyType: partyType,
      partyId: partyId,
    ),
  );

  @override
  Future<Either<Failure, void>> ensureStartPoint({
    required ComparisonPartyType partyType,
    required String partyId,
  }) => _run(() async {
    await remoteDataSource.ensureStartPoint(
      partyType: partyType,
      partyId: partyId,
    );
  });

  @override
  Future<Either<Failure, String>> createPoint({
    required ComparisonPartyType partyType,
    required String partyId,
    required String anchorInvoiceId,
    String? label,
    String? notes,
  }) => _run(
    () => remoteDataSource.createPoint(
      partyType: partyType,
      partyId: partyId,
      anchorInvoiceId: anchorInvoiceId,
      label: label,
      notes: notes,
    ),
  );
}
