import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/features/comparison_points/data/models/comparison_point_model.dart';

abstract class ComparisonPointRepository {
  Future<Either<Failure, List<ComparisonPointModel>>> getPoints({
    required ComparisonPartyType partyType,
    required String partyId,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getPointInvoices(
    String pointId,
  );

  Future<Either<Failure, List<Map<String, dynamic>>>> getPointPayments(
    String pointId,
  );

  Future<Either<Failure, List<Map<String, dynamic>>>> getUnassignedInvoices({
    required ComparisonPartyType partyType,
    required String partyId,
  });

  Future<Either<Failure, void>> ensureStartPoint({
    required ComparisonPartyType partyType,
    required String partyId,
  });

  Future<Either<Failure, String>> createPoint({
    required ComparisonPartyType partyType,
    required String partyId,
    required String anchorInvoiceId,
    String? label,
    String? notes,
  });
}
