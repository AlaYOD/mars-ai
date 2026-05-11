import 'package:flutter_litert_lm/flutter_litert_lm.dart';
import '../../core/services/inference_service.dart';
import 'agent_config.dart';

class AgentEngine {
  final InferenceService _inference;

  // Max characters of history text passed to the model per turn.
  // Gemma 4 has ~8192 token context. 12000 chars ≈ 3000 tokens — safe budget
  // that leaves room for the system prompt and the new response.
  static const int _maxHistoryChars = 12000;

  final Map<AgentType, LiteLmConversation> _conversations = {};

  // Full unbounded history kept in Dart for the UI — never trimmed.
  final Map<AgentType, List<ChatMessage>> _histories = {
    for (final type in AgentType.values) type: [],
  };

  AgentEngine(this._inference);

  List<ChatMessage> historyFor(AgentType type) =>
      List.unmodifiable(_histories[type]!);

  // Returns the most recent messages whose total text fits within the budget.
  // Always keeps pairs (user + assistant) so the model never sees an orphan turn.
  List<ChatMessage> _slidingWindow(List<ChatMessage> history) {
    int chars = 0;
    int start = history.length;

    for (int i = history.length - 1; i >= 0; i--) {
      chars += history[i].text.length;
      if (chars > _maxHistoryChars) break;
      start = i;
    }

    // Ensure we start on a user message so turns stay paired.
    while (start < history.length && !history[start].isUser) {
      start++;
    }

    return start < history.length ? history.sublist(start) : [];
  }

  Stream<String> send(AgentType type, String userMessage, String systemPrompt) async* {
    // Dispose previous — LiteLmConversation cannot be reused after completion.
    await _conversations[type]?.dispose();
    _conversations.remove(type);

    _histories[type]!.add(ChatMessage(text: userMessage, isUser: true));

    // Pass only the sliding window of history — unlimited turns, safe memory.
    final windowHistory = _slidingWindow(
      _histories[type]!.sublist(0, _histories[type]!.length - 1),
    );

    _conversations[type] = await _inference.createConversation(
      systemPrompt: systemPrompt,
      history: windowHistory,
    );

    final conversation = _conversations[type]!;
    final buffer = StringBuffer();

    yield* _inference
        .streamResponse(conversation, userMessage)
        .map((token) {
      buffer.write(token);
      return token;
    });

    _histories[type]!.add(ChatMessage(text: buffer.toString(), isUser: false));
  }

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
