import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'agent_config.dart';

class AgentChatScreen extends ConsumerStatefulWidget {
  final AgentType type;
  const AgentChatScreen({super.key, required this.type});

  @override
  ConsumerState<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends ConsumerState<AgentChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = []; // Mock messages

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add({'sender': 'user', 'text': text});
      });
      _textController.clear();
      // Mock response
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _messages.add({'sender': 'ai', 'text': 'This is a simulated response from the ${kAgents[widget.type]?.name} agent.'});
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = kAgents[widget.type]!;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: config.color.withValues(alpha: 0.1),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: config.color.withValues(alpha: 0.2),
              child: Icon(config.icon, color: config.color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(config.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
                Text('Online', style: TextStyle(color: config.color, fontSize: 12)),
              ],
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? config.color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
                      ),
                      border: Border.all(
                        color: isUser ? config.color.withValues(alpha: 0.5) : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      msg['text']!,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildInputArea(config),
        ],
      ),
    );
  }

  Widget _buildInputArea(AgentConfig config) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white54),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _textController,
              builder: (context, value, child) {
                if (value.text.trim().isNotEmpty) {
                  return CircleAvatar(
                    backgroundColor: config.color,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  );
                }
                return CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  child: IconButton(
                    icon: const Icon(Icons.mic, color: Colors.white, size: 20),
                    onPressed: () {
                      // Voice record
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
