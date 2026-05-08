import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('History & Bookmarks', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Bookmarks'),
          _buildListItem(Icons.bookmark, 'Job Interview Tips (Psychology)', 'Saved yesterday', Colors.blue),
          _buildListItem(Icons.bookmark, 'Grocery Shopping Phrases', 'Saved 3 days ago', Colors.green),
          const SizedBox(height: 24),
          _buildSectionTitle('Recent Conversations'),
          _buildListItem(Icons.chat_bubble_outline, 'Visa Application Help', 'Social Agent • Today', Colors.orange),
          _buildListItem(Icons.chat_bubble_outline, 'Local Cultural Etiquette', 'Social Agent • Yesterday', Colors.orange),
          _buildListItem(Icons.chat_bubble_outline, 'Healthcare System Info', 'Biological Agent • Last week', Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 8),
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
        trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3)),
        onTap: () {},
      ),
    );
  }
}
