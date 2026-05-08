import 'package:flutter_litert_lm/flutter_litert_lm.dart';
import '../../core/services/inference_service.dart';
import 'agent_config.dart';

/// Owns one LiteLmConversation per agent type.
/// When the user switches agents, the previous conversation is untouched —
/// its full history stays in memory so returning to it feels seamless.
class AgentEngine {
  final InferenceService _inference;

  // One conversation slot per agent. Null until the agent is first opened.
  final Map<AgentType, LiteLmConversation> _conversations = {};

  // One message history per agent, kept in Dart for the UI to read.
  final Map<AgentType, List<ChatMessage>> _histories = {
    for (final type in AgentType.values) type: [],
  };

  AgentEngine(this._inference);

  List<ChatMessage> historyFor(AgentType type) =>
      List.unmodifiable(_histories[type]!);

  /// Opens (or re-uses) the conversation for the given agent.
  /// First call creates a new LiteLmConversation with the agent's system prompt.
  Future<void> ensureConversationReady(AgentType type) async {
    if (_conversations.containsKey(type)) return;

    final config = kAgents[type]!;
    _conversations[type] = await _inference.createConversation(
      systemPrompt: config.systemPrompt,
    );
  }

  /// Sends a user message to the specified agent and streams back the response.
  /// Appends both turns to the Dart-side history as the stream completes.
  Stream<String> send(AgentType type, String userMessage) async* {
    await ensureConversationReady(type);

    _histories[type]!.add(ChatMessage(text: userMessage, isUser: true));

    final conversation = _conversations[type]!;
    final buffer = StringBuffer();

    yield* _inference
        .streamResponse(conversation, userMessage)
        .map((token) {
      buffer.write(token);
      return token;
    });

    // Append the completed AI response to history once streaming finishes.
    _histories[type]!.add(ChatMessage(text: buffer.toString(), isUser: false));
  }

  /// Clears the conversation for one agent — user can "reset" a single agent
  /// without affecting the other three.
  Future<void> resetAgent(AgentType type) async {
    await _conversations[type]?.dispose();
    _conversations.remove(type);
    _histories[type] = [];
  }

  Future<void> dispose() async {
    for (final conv in _conversations.values) {
      await conv.dispose();
    }
    _conversations.clear();
  }
}
