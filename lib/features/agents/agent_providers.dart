import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/inference_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/services/inference_service.dart';
import 'agent_config.dart';
import 'agent_engine.dart';

// Singleton AgentEngine — created once, lives as long as the app.
final agentEngineProvider = Provider<AgentEngine>((ref) {
  final inference = ref.read(inferenceServiceProvider);
  final engine = AgentEngine(inference);
  ref.onDispose(engine.dispose);
  return engine;
});

// --- Per-agent chat state ---

enum ChatStatus { idle, generating, error }

class AgentChatState {
  final List<ChatMessage> messages;
  final ChatStatus status;
  final String? errorMessage;
  // The partial token string being streamed right now (empty when idle).
  final String streamingToken;

  const AgentChatState({
    this.messages = const [],
    this.status = ChatStatus.idle,
    this.errorMessage,
    this.streamingToken = '',
  });

  AgentChatState copyWith({
    List<ChatMessage>? messages,
    ChatStatus? status,
    String? errorMessage,
    String? streamingToken,
  }) {
    return AgentChatState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      errorMessage: errorMessage,
      streamingToken: streamingToken ?? this.streamingToken,
    );
  }
}

// One notifier per AgentType — Riverpod .family ensures they are fully isolated.
// chatProvider(AgentType.psychology) and chatProvider(AgentType.social) are
// completely separate state machines. Switching agents never merges their data.
class AgentChatNotifier extends FamilyNotifier<AgentChatState, AgentType> {
  @override
  AgentChatState build(AgentType arg) => const AgentChatState();

  Future<void> sendMessage(String text) async {
    if (state.status == ChatStatus.generating) return;
    if (text.trim().isEmpty) return;

    final engine = ref.read(agentEngineProvider);
    final l10n = ref.read(localizationProvider);
    final systemPrompt = l10n.translate('agent_${arg.name}_prompt');

    state = state.copyWith(
      status: ChatStatus.generating,
      streamingToken: '',
      errorMessage: null,
    );

    final buffer = StringBuffer();

    try {
      await for (final token in engine.send(arg, text, systemPrompt)) {
        buffer.write(token);
        state = state.copyWith(streamingToken: buffer.toString());
      }

      // Streaming finished — move the completed response into the message list.
      state = AgentChatState(
        messages: engine.historyFor(arg).toList(),
        status: ChatStatus.idle,
        streamingToken: '',
      );
    } catch (e) {
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: e.toString(),
        streamingToken: '',
      );
    }
  }

  Future<void> reset() async {
    final engine = ref.read(agentEngineProvider);
    await engine.resetAgent(arg);
    state = const AgentChatState();
  }
}

final chatProvider =
    NotifierProviderFamily<AgentChatNotifier, AgentChatState, AgentType>(
  AgentChatNotifier.new,
);
