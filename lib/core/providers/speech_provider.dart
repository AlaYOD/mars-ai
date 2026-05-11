import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum SpeechStatus { idle, listening, notAvailable }

class SpeechState {
  final SpeechStatus status;
  final String partialText;

  const SpeechState({
    this.status = SpeechStatus.idle,
    this.partialText = '',
  });

  SpeechState copyWith({SpeechStatus? status, String? partialText}) {
    return SpeechState(
      status: status ?? this.status,
      partialText: partialText ?? this.partialText,
    );
  }
}

class SpeechNotifier extends StateNotifier<SpeechState> {
  final SpeechToText _stt = SpeechToText();
  bool _initialized = false;

  SpeechNotifier() : super(const SpeechState());

  Future<bool> _init() async {
    if (_initialized) return true;
    _initialized = await _stt.initialize(onError: (_) => _onError());
    if (!_initialized) state = state.copyWith(status: SpeechStatus.notAvailable);
    return _initialized;
  }

  void _onError() {
    state = const SpeechState(status: SpeechStatus.idle, partialText: '');
  }

  // Start listening. localeId examples: 'en_US', 'ar_SA', 'fr_FR'
  Future<void> startListening({
    required String localeId,
    required void Function(String finalText) onResult,
  }) async {
    final ready = await _init();
    if (!ready) return;

    state = state.copyWith(status: SpeechStatus.listening, partialText: '');

    await _stt.listen(
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(partialResults: true),
      onResult: (result) {
        if (result.finalResult) {
          state = const SpeechState(status: SpeechStatus.idle, partialText: '');
          final text = result.recognizedWords.trim();
          if (text.isNotEmpty) onResult(text);
        } else {
          state = state.copyWith(partialText: result.recognizedWords);
        }
      },
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
    state = const SpeechState(status: SpeechStatus.idle, partialText: '');
  }

  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }
}

final speechProvider = StateNotifierProvider<SpeechNotifier, SpeechState>((ref) {
  return SpeechNotifier();
});
