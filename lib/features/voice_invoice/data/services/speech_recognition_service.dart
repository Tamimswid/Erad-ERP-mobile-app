import 'dart:developer';

import 'package:erad/features/voice_invoice/voice_invoice_config.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechRecognitionService {
  final VoiceInvoiceConfig config;
  final SpeechToText _speech;

  bool _initialized = false;
  bool _active = false;
  bool _doneNotified = false;
  void Function(String message)? _onError;
  void Function()? _onDone;

  SpeechRecognitionService({
    this.config = const VoiceInvoiceConfig(),
    SpeechToText? speech,
  }) : _speech = speech ?? SpeechToText();

  bool get isListening => _speech.isListening;

  Future<void> start({
    required void Function(String text, bool isFinal) onTranscript,
    required void Function(String message) onError,
    required void Function() onDone,
  }) async {
    _active = false;
    if (_speech.isListening) {
      _doneNotified = true;
      await _speech.cancel();
    }

    _onError = onError;
    _onDone = onDone;
    _doneNotified = false;

    if (!await _ensureInitialized()) {
      _onError?.call('تعذر تشغيل التعرف على الصوت على هذا الجهاز');
      return;
    }

    try {
      await _speech.listen(
        onResult: (result) {
          if (!_active) return;
          var text = result.recognizedWords.trim();
          if (text.length > config.maxTranscriptLength) {
            text = text.substring(0, config.maxTranscriptLength);
          }
          onTranscript(text, result.finalResult);
          if (result.finalResult) _notifyDone();
        },
        listenOptions: SpeechListenOptions(
          localeId: config.localeId,
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          listenFor: config.listenFor,
          pauseFor: config.pauseFor,
        ),
      );
      _active = true;
    } catch (e) {
      log('speech listen failed: $e');
      _onError?.call('تعذر بدء التسجيل، حاول مرة أخرى');
    }
  }

  Future<void> stop() async {
    if (!_speech.isListening) return;
    await _speech.stop();
  }

  Future<void> cancel() async {
    _active = false;
    _doneNotified = true;
    if (_speech.isListening) await _speech.cancel();
  }

  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;

    try {
      _initialized = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
        finalTimeout: const Duration(seconds: 2),
      );
    } catch (e) {
      log('speech initialize failed: $e');
      _initialized = false;
    }
    return _initialized;
  }

  void _handleError(SpeechRecognitionError error) {
    if (!_active || !error.permanent) return;
    _onError?.call(_messageFor(error.errorMsg));
  }

  void _handleStatus(String status) {
    if (!_active) return;
    if (status == 'done' || status == 'notListening') _notifyDone();
  }

  void _notifyDone() {
    if (!_active || _doneNotified) return;
    _doneNotified = true;
    _onDone?.call();
  }

  String _messageFor(String error) {
    if (error.contains('permission')) {
      return 'تم رفض إذن الميكروفون، فعّله من إعدادات الجهاز';
    }
    if (error.contains('no_match')) {
      return 'لم يتم التعرف على الكلام، حاول مرة أخرى';
    }
    if (error.contains('speech_timeout')) {
      return 'انتهت مهلة الاستماع، حاول مرة أخرى';
    }
    if (error.contains('network')) {
      return 'تحقق من اتصال الإنترنت ثم حاول مرة أخرى';
    }
    if (error.contains('busy')) {
      return 'خدمة التعرف على الصوت مشغولة، حاول بعد قليل';
    }
    return 'تعذر التعرف على الصوت، حاول مرة أخرى';
  }
}
