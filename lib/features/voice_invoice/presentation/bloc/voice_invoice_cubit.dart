import 'package:erad/features/voice_invoice/data/repositories/voice_invoice_repository.dart';
import 'package:erad/features/voice_invoice/data/services/speech_recognition_service.dart';
import 'package:erad/features/voice_invoice/presentation/bloc/voice_invoice_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VoiceInvoiceCubit extends Cubit<VoiceInvoiceState> {
  final VoiceInvoiceRepository _repository;
  final SpeechRecognitionService _speech;

  String? _typeHint;
  bool _analyzing = false;

  VoiceInvoiceCubit({
    required VoiceInvoiceRepository repository,
    required SpeechRecognitionService speech,
  }) : _repository = repository,
       _speech = speech,
       super(const VoiceInvoiceState.idle());

  Future<void> startListening({String? typeHint}) async {
    if (_analyzing) return;
    _typeHint = typeHint;
    emit(const VoiceInvoiceState.listening(''));

    await _speech.start(
      onTranscript: _handleTranscript,
      onError: _handleSpeechError,
      onDone: _handleSpeechDone,
    );
  }

  Future<void> stopListening() async {
    if (!state.isListening) return;
    await _speech.stop();
  }

  Future<void> analyze() async {
    if (_analyzing || isClosed) return;

    final transcript = state.transcript.trim();
    if (transcript.isEmpty) {
      emit(
        const VoiceInvoiceState.failure(
          '',
          'لم يتم التعرف على أي نص، حاول مرة أخرى',
        ),
      );
      return;
    }

    _analyzing = true;
    emit(VoiceInvoiceState.analyzing(transcript));
    await _speech.cancel();

    final result = await _repository.buildDraft(
      transcript: transcript,
      typeHint: _typeHint,
    );
    _analyzing = false;
    if (isClosed) return;

    result.fold(
      (failure) => emit(VoiceInvoiceState.failure(transcript, failure.message)),
      (draft) => emit(VoiceInvoiceState.ready(transcript, draft)),
    );
  }

  Future<void> retry() async {
    if (state.hasTranscript) {
      await analyze();
    } else {
      await startListening(typeHint: _typeHint);
    }
  }

  Future<void> reset() async {
    _analyzing = false;
    await _speech.cancel();
    if (!isClosed) emit(const VoiceInvoiceState.idle());
  }

  void _handleTranscript(String text, bool isFinal) {
    if (isClosed || !state.isListening) return;
    emit(VoiceInvoiceState.listening(text));
  }

  void _handleSpeechDone() {
    if (isClosed || !state.isListening) return;
    if (state.hasTranscript) {
      analyze();
    } else {
      emit(
        const VoiceInvoiceState.failure(
          '',
          'لم يتم التعرف على أي نص، حاول مرة أخرى',
        ),
      );
    }
  }

  void _handleSpeechError(String message) {
    if (isClosed) return;
    if (state.isListening || state.isAnalyzing) {
      emit(VoiceInvoiceState.failure(state.transcript, message));
    }
  }

  @override
  Future<void> close() async {
    await _speech.cancel();
    return super.close();
  }
}
