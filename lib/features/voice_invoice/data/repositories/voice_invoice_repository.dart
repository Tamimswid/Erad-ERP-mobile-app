import 'package:dartz/dartz.dart';
import 'package:erad/core/errors/failures.dart';
import 'package:erad/core/network/network_info.dart';
import 'package:erad/features/voice_invoice/data/datasources/voice_invoice_remote_datasource.dart';
import 'package:erad/features/voice_invoice/data/models/voice_invoice_draft.dart';

class VoiceInvoiceRepository {
  final VoiceInvoiceRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const VoiceInvoiceRepository(this.remoteDataSource, this.networkInfo);

  Future<Either<Failure, VoiceInvoiceDraft>> buildDraft({
    required String transcript,
    String? typeHint,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure.noConnection());
    }

    try {
      final draft = await remoteDataSource.buildDraft(
        transcript: transcript,
        typeHint: typeHint,
      );
      return Right(draft);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(exceptionToFailure(e));
    }
  }
}
