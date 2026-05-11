import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'agent_config.dart';
import 'agent_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/speech_provider.dart';
import '../../core/services/inference_service.dart';

class AgentChatScreen extends ConsumerStatefulWidget {
  final AgentType type;
  const AgentChatScreen({super.key, required this.type});

  @override
  ConsumerState<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends ConsumerState<AgentChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  AgentConfig get _config => kAgents[widget.type]!;

  // Maps app locale code to a BCP-47 locale ID accepted by the device STT engine.
  // Falls back to 'en_US' so recognition never breaks.
  String get _sttLocaleId {
    final code = ref.read(localeProvider).languageCode;
    const map = {
      'en': 'en_US',
      'ar': 'ar_SA',
      'fr': 'fr_FR',
      'es': 'es_ES',
      'de': 'de_DE',
      'zh': 'zh_CN',
      'ja': 'ja_JP',
      'ko': 'ko_KR',
      'hi': 'hi_IN',
      'pt': 'pt_BR',
      'ru': 'ru_RU',
      'tr': 'tr_TR',
      'it': 'it_IT',
      'nl': 'nl_NL',
    };
    return map[code] ?? '${code}_${code.toUpperCase()}';
  }

  void _toggleSpeech() {
    final speech = ref.read(speechProvider);
    if (speech.status == SpeechStatus.listening) {
      ref.read(speechProvider.notifier).stopListening();
    } else {
      ref.read(speechProvider.notifier).startListening(
        localeId: _sttLocaleId,
        onResult: (text) {
          _inputController.text = text;
          _inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: text.length),
          );
        },
      );
    }
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    ref.read(chatProvider(widget.type).notifier).sendMessage(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _confirmReset() {
    final l10n = ref.read(localizationProvider);
    final agentName = l10n.translate('agent_${widget.type.name}_name');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(l10n.translate('chat_reset_title'), style: const TextStyle(color: Colors.white)),
        content: Text(
          '${l10n.translate('chat_reset_confirm')} ($agentName)',
          style: const TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('chat_cancel'), style: const TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(chatProvider(widget.type).notifier).reset();
            },
            child: Text(l10n.translate('chat_reset'), style: TextStyle(color: _config.color)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.type));
    final l10n = ref.watch(localizationProvider);

    // Scroll down whenever messages or streaming token changes.
    ref.listen(chatProvider(widget.type), (prev, next) => _scrollToBottom());

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: _buildAppBar(chatState, l10n),
      body: Directionality(
        textDirection: l10n.textDirection,
        child: Column(
          children: [
            Expanded(child: _buildMessageList(chatState)),
            if (chatState.status == ChatStatus.error)
              _ErrorBanner(message: chatState.errorMessage ?? 'Something went wrong.'),
            _buildInputBar(chatState, l10n),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(AgentChatState chatState, AppLocalizations l10n) {
    final agentName = l10n.translate('agent_${widget.type.name}_name');

    return AppBar(
      backgroundColor: const Color(0xFF0D0D0D),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _config.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_config.icon, color: _config.color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                agentName,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                chatState.status == ChatStatus.generating 
                    ? l10n.translate('chat_thinking') 
                    : l10n.translate('chat_online'),
                style: TextStyle(
                  color: chatState.status == ChatStatus.generating
                      ? _config.color
                      : Colors.greenAccent,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.white.withValues(alpha: 0.5), size: 20),
          tooltip: l10n.translate('chat_reset_title'),
          onPressed: _confirmReset,
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
      ),
    );
  }

  Widget _buildMessageList(AgentChatState chatState) {
    final messages = chatState.messages;
    final isStreaming = chatState.status == ChatStatus.generating;
    final streamingText = chatState.streamingToken;

    // Total items: past messages + streaming bubble if active
    final itemCount = messages.length + (isStreaming ? 1 : 0);

    if (itemCount == 0) {
      return _EmptyState(config: _config);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Last item is the live streaming bubble
        if (isStreaming && index == messages.length) {
          return _StreamingBubble(
            text: streamingText,
            config: _config,
          );
        }
        final msg = messages[index];
        return _MessageBubble(message: msg, config: _config);
      },
    );
  }

  Widget _buildInputBar(AgentChatState chatState, AppLocalizations l10n) {
    final isGenerating = chatState.status == ChatStatus.generating;
    final agentName = l10n.translate('agent_${widget.type.name}_name');
    final speechState = ref.watch(speechProvider);
    final isListening = speechState.status == SpeechStatus.listening;
    final sttUnavailable = speechState.status == SpeechStatus.notAvailable;

    // While listening, show the partial transcript live in the text field
    if (isListening && speechState.partialText.isNotEmpty) {
      _inputController.value = TextEditingValue(
        text: speechState.partialText,
        selection: TextSelection.fromPosition(
          TextPosition(offset: speechState.partialText.length),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isListening)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MicPulse(color: _config.color),
                    const SizedBox(width: 8),
                    Text(
                      l10n.translate('chat_listening'),
                      style: TextStyle(color: _config.color, fontSize: 12),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!sttUnavailable)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 0),
                    child: _MicButton(
                      isListening: isListening,
                      isGenerating: isGenerating,
                      color: _config.color,
                      onTap: isGenerating ? null : _toggleSpeech,
                    ),
                  ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isListening
                            ? _config.color.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: TextField(
                      controller: _inputController,
                      enabled: !isGenerating && !isListening,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: isGenerating
                            ? l10n.translate('chat_thinking')
                            : isListening
                                ? l10n.translate('chat_listening')
                                : '${l10n.translate('chat_type_msg')} ($agentName)',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 15),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SendButton(
                  isGenerating: isGenerating,
                  color: _config.color,
                  controller: _inputController,
                  onSend: _sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Individual message bubble ─────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final AgentConfig config;

  const _MessageBubble({required this.message, required this.config});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? config.color.withValues(alpha: 0.18)
              : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser
                ? config.color.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.45),
        ),
      ),
    );
  }
}

// ── Streaming bubble — shows tokens arriving in real time ────────────────────

class _StreamingBubble extends StatefulWidget {
  final String text;
  final AgentConfig config;

  const _StreamingBubble({required this.text, required this.config});

  @override
  State<_StreamingBubble> createState() => _StreamingBubbleState();
}

class _StreamingBubbleState extends State<_StreamingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4, right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: widget.text.isEmpty
            ? _TypingDots(color: widget.config.color)
            : AnimatedBuilder(
                animation: _cursorController,
                builder: (context, _) {
                  return Text(
                    widget.text + (_cursorController.value > 0.5 ? '▌' : ''),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15, height: 1.45),
                  );
                },
              ),
      ),
    );
  }
}

// Three animated dots shown before the first token arrives
class _TypingDots extends StatefulWidget {
  final Color color;
  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (ctx, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value - i * 0.2).clamp(0.0, 1.0);
            final opacity = (phase < 0.5 ? phase * 2 : (1.0 - phase) * 2).clamp(0.3, 1.0);
            return Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Send button — switches between send icon and loading indicator ────────────

class _SendButton extends StatelessWidget {
  final bool isGenerating;
  final Color color;
  final TextEditingController controller;
  final VoidCallback onSend;

  const _SendButton({
    required this.isGenerating,
    required this.color,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    if (isGenerating) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      );
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (ctx, value, child) {
        final hasText = value.text.trim().isNotEmpty;
        return GestureDetector(
          onTap: hasText ? onSend : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasText ? color : Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_upward_rounded,
              color: hasText ? Colors.white : Colors.white38,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}

// ── Empty state shown before any messages ────────────────────────────────────

class _EmptyState extends ConsumerWidget {
  final AgentConfig config;
  const _EmptyState({required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final agentName = l10n.translate('agent_${config.type.name}_name');
    final agentSub = l10n.translate('agent_${config.type.name}_sub');

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(config.icon, color: config.color, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            agentName,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            agentSub,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: config.color.withValues(alpha: 0.2)),
            ),
            child: Text(
              l10n.translate('chat_empty_prompt'),
              style: TextStyle(color: config.color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error banner shown above input bar ───────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.red.shade900.withValues(alpha: 0.6),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white70, fontSize: 13),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Microphone button ─────────────────────────────────────────────────────────

class _MicButton extends StatelessWidget {
  final bool isListening;
  final bool isGenerating;
  final Color color;
  final VoidCallback? onTap;

  const _MicButton({
    required this.isListening,
    required this.isGenerating,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isListening
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
          shape: BoxShape.circle,
          border: Border.all(
            color: isListening ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Icon(
          isListening ? Icons.mic : Icons.mic_none_rounded,
          color: isListening ? color : Colors.white54,
          size: 20,
        ),
      ),
    );
  }
}

// ── Pulsing dot shown while mic is active ─────────────────────────────────────

class _MicPulse extends StatefulWidget {
  final Color color;
  const _MicPulse({required this.color});

  @override
  State<_MicPulse> createState() => _MicPulseState();
}

class _MicPulseState extends State<_MicPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
