import 'package:equatable/equatable.dart';
import 'package:erad/features/voice_invoice/data/models/voice_invoice_draft.dart';

enum VoiceInvoiceStatus { idle, listening, analyzing, ready, error }

class VoiceInvoiceState extends Equatable {
  const VoiceInvoiceState._(
    this.status,
    this.transcript, {
    this.draft,
    this.message,
  });

  const VoiceInvoiceState.idle() : this._(VoiceInvoiceStatus.idle, '');

  const VoiceInvoiceState.listening(String transcript)
    : this._(VoiceInvoiceStatus.listening, transcript);

  const VoiceInvoiceState.analyzing(String transcript)
    : this._(VoiceInvoiceStatus.analyzing, transcript);

  const VoiceInvoiceState.ready(String transcript, VoiceInvoiceDraft draft)
    : this._(VoiceInvoiceStatus.ready, transcript, draft: draft);

  const VoiceInvoiceState.failure(String transcript, String message)
    : this._(VoiceInvoiceStatus.error, transcript, message: message);

  final VoiceInvoiceStatus status;
  final String transcript;
  final VoiceInvoiceDraft? draft;
  final String? message;

  bool get isListening => status == VoiceInvoiceStatus.listening;
  bool get isAnalyzing => status == VoiceInvoiceStatus.analyzing;
  bool get hasTranscript => transcript.trim().isNotEmpty;

  @override
  List<Object?> get props => [status, transcript, draft, message];
}
