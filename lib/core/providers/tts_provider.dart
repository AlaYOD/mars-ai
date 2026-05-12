import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Manages text-to-speech playback using [FlutterTts].
///
/// [FlutterTts] delegates to the device's on-board TTS engine
/// (Android: Google TTS / Samsung TTS; iOS: AVSpeechSynthesizer).
/// Both engines operate fully offline once their language voices are installed.
///
/// State holds the ID of the message currently being spoken, or null if idle.
class TtsNotifier extends StateNotifier<String?> {
  final FlutterTts _tts = FlutterTts();

  TtsNotifier() : super(null) {
    _configure();
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> _configure() async {
    // Ensure TTS uses offline engine on Android where possible.
    await _tts.setSharedInstance(true);

    // Callbacks
    _tts.setCompletionHandler(() {
      if (mounted) state = null;
    });
    _tts.setCancelHandler(() {
      if (mounted) state = null;
    });
    _tts.setErrorHandler((_) {
      if (mounted) state = null;
    });
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Speak [text] using the voice for [languageCode].
  ///
  /// Tapping the same message a second time stops playback (toggle).
  Future<void> speak({
    required String messageId,
    required String text,
    required String languageCode,
  }) async {
    // Toggle: tap again → stop.
    if (state == messageId) {
      await _tts.stop();
      state = null;
      return;
    }

    await _tts.stop();

    // BCP-47 locale tags accepted by FlutterTts.
    const langMap = {
      'en': 'en-US',
      'ar': 'ar-SA',
      'fr': 'fr-FR',
      'es': 'es-ES',
      'de': 'de-DE',
      'zh': 'zh-CN',
      'ja': 'ja-JP',
      'ko': 'ko-KR',
      'hi': 'hi-IN',
      'pt': 'pt-BR',
      'ru': 'ru-RU',
      'tr': 'tr-TR',
      'it': 'it-IT',
      'nl': 'nl-NL',
    };
    final lang = langMap[languageCode] ?? 'en-US';

    await _tts.setLanguage(lang);
    await _tts.setSpeechRate(0.5);  // comfortable listening pace
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    state = messageId;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    state = null;
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}

final ttsProvider = StateNotifierProvider<TtsNotifier, String?>((ref) {
  return TtsNotifier();
});
