import 'dart:async';
import 'package:flutter_litert_lm/flutter_litert_lm.dart';
import 'model_storage_service.dart';

enum InferenceStatus { unloaded, loading, ready, generating, error }

class ChatMessage {
  final String text;
  final bool isUser;

  const ChatMessage({required this.text, required this.isUser});

  LiteLmMessage toLiteLm() =>
      isUser ? LiteLmMessage.user(text) : LiteLmMessage.model(text);
}

class InferenceService {
  final ModelStorageService _storage;

  LiteLmEngine? _engine;
  InferenceStatus _status = InferenceStatus.unloaded;
  String? _lastError;

  InferenceService(this._storage);

  InferenceStatus get status => _status;
  String? get lastError => _lastError;
  bool get isReady => _status == InferenceStatus.ready;

  /// Loads the model file into the LiteRT-LM native engine.
  /// The engine memory-maps the file — it does NOT copy 2 GB into the Dart heap.
  Future<void> loadModel() async {
    if (_status == InferenceStatus.ready) return;

    _status = InferenceStatus.loading;
    _lastError = null;

    try {
      final modelPath = await _storage.modelFilePath;
      final cacheDir = await _storage.modelDirectory;

      _engine = await LiteLmEngine.create(
        LiteLmEngineConfig(
          modelPath: modelPath,
          // GPU on Android; CPU is the safe fallback on all devices.
          backend: LiteLmBackend.gpu,
          // Caches compiled model artifacts so subsequent loads are faster.
          cacheDir: cacheDir,
        ),
      );

      _status = InferenceStatus.ready;
    } catch (e) {
      // GPU may not be available on all devices — retry with CPU.
      try {
        final modelPath = await _storage.modelFilePath;
        _engine = await LiteLmEngine.create(
          LiteLmEngineConfig(modelPath: modelPath, backend: LiteLmBackend.cpu),
        );
        _status = InferenceStatus.ready;
      } catch (fallbackError) {
        _status = InferenceStatus.error;
        _lastError = fallbackError.toString();
        rethrow;
      }
    }
  }

  /// Creates a conversation with the given system prompt and history pre-loaded.
  /// Each agent gets its own conversation — no state shared between agents.
  Future<LiteLmConversation> createConversation({
    required String systemPrompt,
    List<ChatMessage> history = const [],
  }) async {
    if (_engine == null) throw StateError('Call loadModel() first.');

    return _engine!.createConversation(
      LiteLmConversationConfig(
        systemInstruction: systemPrompt,
        initialMessages: history.map((m) => m.toLiteLm()).toList(),
      ),
    );
  }

  /// Streams tokens from the model as they are generated.
  /// Returns partial text deltas — use these to build a real-time typing effect.
  Stream<String> streamResponse(
    LiteLmConversation conversation,
    String userMessage,
  ) {
    _status = InferenceStatus.generating;
    return conversation
        .sendMessageStream(userMessage)
        .map((msg) => msg.text)
        .handleError((e) {
      _status = InferenceStatus.ready;
      throw e;
    }).transform(_onDoneTransform(() => _status = InferenceStatus.ready));
  }

  Future<void> dispose() async {
    await _engine?.dispose();
    _engine = null;
    _status = InferenceStatus.unloaded;
  }
}

/// Stream transformer that runs a callback when the stream closes normally.
StreamTransformer<T, T> _onDoneTransform<T>(void Function() onDone) {
  return StreamTransformer.fromHandlers(
    handleData: (data, sink) => sink.add(data),
    handleError: (e, st, sink) => sink.addError(e, st),
    handleDone: (sink) {
      onDone();
      sink.close();
    },
  );
}
