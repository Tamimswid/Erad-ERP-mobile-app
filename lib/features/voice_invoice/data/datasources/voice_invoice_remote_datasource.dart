import 'dart:developer';

import 'package:erad/core/errors/failures.dart';
import 'package:erad/features/voice_invoice/data/models/voice_invoice_draft.dart';
import 'package:erad/features/voice_invoice/voice_invoice_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VoiceInvoiceRemoteDataSource {
  static const _functionName = 'voice-invoice';

  final SupabaseClient supabaseClient;
  final VoiceInvoiceConfig config;

  const VoiceInvoiceRemoteDataSource(
    this.supabaseClient, {
    this.config = const VoiceInvoiceConfig(),
  });

  Future<VoiceInvoiceDraft> buildDraft({
    required String transcript,
    String? typeHint,
  }) async {
    try {
      final response = await supabaseClient.functions
          .invoke(
            _functionName,
            body: {
              'transcript': transcript,
              if (typeHint != null && typeHint.isNotEmpty)
                'type_hint': typeHint,
            },
          )
          .timeout(config.requestTimeout);

      final data = response.data;
      if (data is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }

      return VoiceInvoiceDraft.fromJson(Map<String, dynamic>.from(data));
    } on FunctionException catch (e) {
      log('voice-invoice failed: ${e.status} ${e.details}');
      throw _mapFunctionException(e);
    } on Failure {
      rethrow;
    } catch (e) {
      log('voice-invoice error: $e');
      throw exceptionToFailure(e);
    }
  }

  Failure _mapFunctionException(FunctionException exception) {
    final message = _messageFrom(exception.details);

    if (exception.status == 401 || exception.status == 403) {
      return AuthFailure(message ?? 'انتهت الجلسة', code: 'UNAUTHORIZED');
    }
    if (exception.status == 400 || exception.status == 413) {
      return ValidationFailure(
        message ?? 'تعذر التعرف على النص، حاول مرة أخرى',
        code: 'INVALID_TRANSCRIPT',
      );
    }
    return ServerFailure(
      message ?? 'تعذر تحليل الفاتورة الصوتية',
      code: 'VOICE_INVOICE_ERROR',
    );
  }

  String? _messageFrom(dynamic details) {
    if (details is Map) {
      final error = details['error'];
      if (error is String && error.trim().isNotEmpty) return error.trim();
    }
    if (details is String && details.trim().isNotEmpty) {
      return details.trim();
    }
    return null;
  }
}
