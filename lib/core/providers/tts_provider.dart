import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsNotifier extends StateNotifier<String?> {
  final FlutterTts _tts = FlutterTts();

  // speakingMessageId holds the id of the message currently being spoken
  TtsNotifier() : super(null) {
    _tts.setCompletionHandler(() => state = null);
    _tts.setCancelHandler(() => state = null);
    _tts.setErrorHandler((msg) => state = null);
  }

  Future<void> speak({
    required String messageId,
    required String text,
    required String languageCode,
  }) async {
    // Tap again on same message → stop
    if (state == messageId) {
      await _tts.stop();
      state = null;
      return;
    }

    await _tts.stop();

    // Map app locale code to BCP-47 TTS language tag
    const map = {
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
    final lang = map[languageCode] ?? 'en-US';

    await _tts.setLanguage(lang);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);

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
