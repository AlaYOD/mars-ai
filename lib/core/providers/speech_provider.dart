import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import '../services/vosk_model_service.dart';

// ── Public types ──────────────────────────────────────────────────────────────

enum SpeechStatus {
  idle,
  loadingModel, // Vosk model is being downloaded / extracted
  listening,
  notAvailable, // Microphone permission denied or fatal error
}

class SpeechState {
  final SpeechStatus status;
  final String partialText;
  final double modelLoadProgress; // 0.0–1.0 while loading
  final String? errorMessage;

  const SpeechState({
    this.status = SpeechStatus.idle,
    this.partialText = '',
    this.modelLoadProgress = 0.0,
    this.errorMessage,
  });

  SpeechState copyWith({
    SpeechStatus? status,
    String? partialText,
    double? modelLoadProgress,
    String? errorMessage,
  }) {
    return SpeechState(
      status: status ?? this.status,
      partialText: partialText ?? this.partialText,
      modelLoadProgress: modelLoadProgress ?? this.modelLoadProgress,
      errorMessage: errorMessage,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SpeechNotifier extends StateNotifier<SpeechState> {
  SpeechNotifier() : super(const SpeechState());

  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();

  /// Active speech service (microphone → Vosk recognizer pipeline).
  SpeechService? _speechService;

  /// Currently loaded language code — avoids reloading the same model twice.
  String? _loadedLang;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Start listening with the Vosk model for [langCode].
  ///
  /// Downloads and loads the model on first use (shows progress in [state]).
  /// [onResult] fires with the final recognised text when the user pauses.
  Future<void> startListening({
    required String langCode,
    required void Function(String finalText) onResult,
  }) async {
    if (state.status == SpeechStatus.listening) return;

    // ── 1. Microphone permission ──────────────────────────────────────────────
    final permStatus = await Permission.microphone.request();
    if (!permStatus.isGranted) {
      state = state.copyWith(
        status: SpeechStatus.notAvailable,
        errorMessage: 'Microphone permission denied.',
      );
      return;
    }

    // ── 2. Load Vosk model (first use or language change) ────────────────────
    if (_loadedLang != langCode || _speechService == null) {
      state = state.copyWith(
        status: SpeechStatus.loadingModel,
        modelLoadProgress: 0.0,
      );

      try {
        final modelPath = await VoskModelService.instance.ensureModel(
          langCode,
          onProgress: (p) {
            if (mounted) {
              state = state.copyWith(modelLoadProgress: p);
            }
          },
        );

        // Dispose previous service before creating a new one.
        await _disposeService();

        final model = await _vosk.createModel(modelPath);
        final recognizer = await _vosk.createRecognizer(
          model: model,
          sampleRate: 16000,
        );
        _speechService = await _vosk.initSpeechService(recognizer);
        _loadedLang = langCode;
      } catch (e) {
        state = state.copyWith(
          status: SpeechStatus.notAvailable,
          errorMessage: 'Failed to load speech model: $e',
        );
        return;
      }
    }

    // ── 3. Wire up result listeners and start ─────────────────────────────────
    state = state.copyWith(
      status: SpeechStatus.listening,
      partialText: '',
      modelLoadProgress: 1.0,
      errorMessage: null,
    );

    // Partial results → live transcript shown in the text field.
    _speechService!.onPartial().listen((partialJson) {
      if (!mounted) return;
      final partial = _extractText(partialJson, key: 'partial');
      if (partial.isNotEmpty) {
        state = state.copyWith(partialText: partial);
      }
    });

    // Final results → fired after a speech pause.
    _speechService!.onResult().listen((resultJson) {
      if (!mounted) return;
      final text = _extractText(resultJson, key: 'text');
      if (text.isNotEmpty) {
        state = const SpeechState(status: SpeechStatus.idle);
        onResult(text);
      }
    });

    await _speechService!.start();
  }

  /// Stop listening and return to idle.
  Future<void> stopListening() async {
    if (_speechService != null) {
      await _speechService!.stop();
    }
    state = const SpeechState(status: SpeechStatus.idle);
  }

  @override
  void dispose() {
    _disposeService();
    super.dispose();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _disposeService() async {
    if (_speechService != null) {
      await _speechService!.stop();
      _speechService = null;
    }
  }

  /// Vosk returns JSON strings like {"partial":"hello"} or {"text":"hello world"}.
  /// This helper safely extracts the value for [key].
  String _extractText(String json, {required String key}) {
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return (map[key] as String? ?? '').trim();
    } catch (_) {
      return '';
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final speechProvider =
    StateNotifierProvider<SpeechNotifier, SpeechState>((ref) {
  return SpeechNotifier();
});
