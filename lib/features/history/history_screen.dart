import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/locale_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.translate('history_title'), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: l10n.textDirection,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle(l10n.translate('history_bookmarks')),
            _buildListItem(
              Icons.bookmark,
              l10n.translate('history_mock_bookmark_1'),
              l10n.translate('history_mock_bookmark_1_sub'),
              Colors.blue,
            ),
            _buildListItem(
              Icons.bookmark,
              l10n.translate('history_mock_bookmark_2'),
              l10n.translate('history_mock_bookmark_2_sub'),
              Colors.green,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(l10n.translate('history_conversations')),
            _buildListItem(
              Icons.chat_bubble_outline,
              l10n.translate('history_mock_chat_1'),
              l10n.translate('history_mock_chat_1_sub'),
              Colors.orange,
            ),
            _buildListItem(
              Icons.chat_bubble_outline,
              l10n.translate('history_mock_chat_2'),
              l10n.translate('history_mock_chat_2_sub'),
              Colors.orange,
            ),
            _buildListItem(
              Icons.chat_bubble_outline,
              l10n.translate('history_mock_chat_3'),
              l10n.translate('history_mock_chat_3_sub'),
              Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildListItem(IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: () {},
      ),
    );
  }
}
