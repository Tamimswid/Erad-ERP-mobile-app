class VoiceInvoiceConfig {
  const VoiceInvoiceConfig({
    this.localeId = 'ar_SA',
    this.listenFor = const Duration(seconds: 90),
    this.pauseFor = const Duration(seconds: 4),
    this.requestTimeout = const Duration(seconds: 45),
    this.maxTranscriptLength = 2000,
  });

  final String localeId;
  final Duration listenFor;
  final Duration pauseFor;
  final Duration requestTimeout;
  final int maxTranscriptLength;
}
