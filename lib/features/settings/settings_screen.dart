import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/profile_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileSection(context, ref),
          const SizedBox(height: 32),
          _buildActionItem(
            icon: Icons.history_toggle_off,
            title: 'Clear Chat History',
            subtitle: 'Delete all conversations from this device',
            color: Colors.redAccent,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat history cleared.')),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildActionItem(
            icon: Icons.system_update_alt,
            title: 'Check for Model Updates',
            subtitle: 'Download the latest version of Mars AI',
            color: Colors.deepPurpleAccent,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('You are on the latest model version.')),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildActionItem(
            icon: Icons.logout,
            title: 'Reset App Profile',
            subtitle: 'Clear setup data to start over',
            color: Colors.orangeAccent,
            onTap: () {
              ref.read(profileNotifierProvider.notifier).clearProfile();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileNotifierProvider);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.white70),
              const SizedBox(width: 12),
              const Text('Your Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Navigate to edit profile or show modal
                },
                child: const Text('Edit'),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          profileState.when(
            data: (profile) {
              if (profile == null) return const Text('No profile data', style: TextStyle(color: Colors.white54));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileRow('Native Country', profile.nativeCountry),
                  _buildProfileRow('Host Country', profile.hostCountry),
                  _buildProfileRow('Language', profile.language),
                  _buildProfileRow('Status', profile.status),
                ],
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
