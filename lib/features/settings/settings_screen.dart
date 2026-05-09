import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/accessibility_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        final activeLocale = ref.watch(localeProvider);
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'App Language / لغة التطبيق / Langue de l\'app', 
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English', style: TextStyle(color: Colors.white)),
                trailing: activeLocale.languageCode == 'en' ? const Icon(Icons.check, color: Colors.deepPurpleAccent) : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale('en');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('العربية', style: TextStyle(color: Colors.white)),
                trailing: activeLocale.languageCode == 'ar' ? const Icon(Icons.check, color: Colors.deepPurpleAccent) : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale('ar');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Français', style: TextStyle(color: Colors.white)),
                trailing: activeLocale.languageCode == 'fr' ? const Icon(Icons.check, color: Colors.deepPurpleAccent) : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale('fr');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final activeLocale = ref.watch(localeProvider);
    final accState = ref.watch(accessibilityProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('settings_title')),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: l10n.textDirection,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileSection(context, ref, l10n),
            const SizedBox(height: 20),
            _buildAccessibilitySection(context, ref, l10n),
            const SizedBox(height: 20),
            _buildActionItem(
              context,
              icon: Icons.language,
              title: l10n.translate('settings_app_lang'),
              subtitle: activeLocale.languageCode == 'ar' 
                  ? 'العربية' 
                  : activeLocale.languageCode == 'fr' 
                      ? 'Français' 
                      : 'English',
              color: Colors.blueAccent,
              onTap: () => _showLanguageDialog(context, ref),
            ),
            const SizedBox(height: 12),
            _buildActionItem(
              context,
              icon: Icons.history_toggle_off,
              title: l10n.translate('settings_clear_history'),
              subtitle: l10n.translate('settings_clear_history_sub'),
              color: Colors.redAccent,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.translate('settings_history_cleared'))),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionItem(
              context,
              icon: Icons.system_update_alt,
              title: l10n.translate('settings_check_updates'),
              subtitle: l10n.translate('settings_check_updates_sub'),
              color: accState.primaryColor,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.translate('settings_updates_latest'))),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildActionItem(
              context,
              icon: Icons.logout,
              title: l10n.translate('settings_reset_profile'),
              subtitle: l10n.translate('settings_reset_profile_sub'),
              color: Colors.orangeAccent,
              onTap: () {
                ref.read(profileNotifierProvider.notifier).clearProfile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final profileState = ref.watch(profileNotifierProvider);
    final theme = Theme.of(context);
    final isLgt = theme.brightness == Brightness.light;
    final accState = ref.watch(accessibilityProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLgt ? Colors.black.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLgt ? Colors.black12 : Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: isLgt ? Colors.black54 : Colors.white70),
              const SizedBox(width: 12),
              Text(
                l10n.translate('settings_your_profile'), 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Navigate to edit profile
                },
                child: Text(l10n.translate('settings_edit'), style: TextStyle(color: accState.primaryColor)),
              ),
            ],
          ),
          const Divider(height: 24),
          profileState.when(
            data: (profile) {
              if (profile == null) {
                return Text(l10n.translate('settings_no_profile'), style: const TextStyle(color: Colors.white54));
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileRow(context, l10n.translate('setup_native_country'), profile.nativeCountry),
                  _buildProfileRow(context, l10n.translate('setup_host_country'), profile.hostCountry),
                  _buildProfileRow(context, l10n.translate('setup_native_lang'), profile.language),
                  _buildProfileRow(context, l10n.translate('setup_status'), profile.status),
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

  Widget _buildProfileRow(BuildContext context, String label, String value) {
    final isLgt = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isLgt ? Colors.black54 : Colors.white54, fontSize: 14)),
          Text(value, style: TextStyle(color: isLgt ? Colors.black87 : Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAccessibilitySection(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final accState = ref.watch(accessibilityProvider);
    final isLgt = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLgt ? Colors.black.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLgt ? Colors.black12 : Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.accessibility_new, color: accState.primaryColor),
              const SizedBox(width: 12),
              Text(
                l10n.translate('settings_accessibility'), 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.translate('settings_accessibility_sub'),
            style: TextStyle(color: isLgt ? Colors.black45 : Colors.white54, fontSize: 13),
          ),
          const Divider(height: 24),

          // 1. Font Sizing Row
          Text(
            l10n.translate('settings_font_size'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: FontSizeOption.values.map((opt) {
                final isSelected = accState.fontSize == opt;
                String labelKey;
                switch (opt) {
                  case FontSizeOption.small: labelKey = 'font_small'; break;
                  case FontSizeOption.medium: labelKey = 'font_medium'; break;
                  case FontSizeOption.large: labelKey = 'font_large'; break;
                  case FontSizeOption.extraLarge: labelKey = 'font_xlarge'; break;
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(l10n.translate(labelKey)),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(accessibilityProvider.notifier).setFontSize(opt);
                    },
                    selectedColor: accState.primaryColor.withValues(alpha: 0.25),
                    checkmarkColor: accState.primaryColor,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Color Scheme Row
          Text(
            l10n.translate('settings_color_theme'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ThemeColorOption.values.map((opt) {
              final isSelected = accState.themeColor == opt;
              Color optColor;
              String labelKey;
              switch (opt) {
                case ThemeColorOption.purple:
                  optColor = Colors.deepPurpleAccent;
                  labelKey = 'theme_purple';
                  break;
                case ThemeColorOption.teal:
                  optColor = Colors.tealAccent;
                  labelKey = 'theme_teal';
                  break;
                case ThemeColorOption.blue:
                  optColor = Colors.blueAccent;
                  labelKey = 'theme_blue';
                  break;
                case ThemeColorOption.green:
                  optColor = Colors.greenAccent;
                  labelKey = 'theme_green';
                  break;
              }
              return GestureDetector(
                onTap: () {
                  ref.read(accessibilityProvider.notifier).setThemeColor(opt);
                },
                child: Tooltip(
                  message: l10n.translate(labelKey),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: optColor.withValues(alpha: isSelected ? 1.0 : 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? (isLgt ? Colors.black : Colors.white) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.black, size: 20)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 3. Brightness Row
          Text(
            l10n.translate('settings_brightness'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: BrightnessOption.values.map((opt) {
                final isSelected = accState.brightness == opt;
                String labelKey;
                switch (opt) {
                  case BrightnessOption.dark: labelKey = 'bright_dark'; break;
                  case BrightnessOption.amoled: labelKey = 'bright_amoled'; break;
                  case BrightnessOption.light: labelKey = 'bright_light'; break;
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(l10n.translate(labelKey)),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(accessibilityProvider.notifier).setBrightness(opt);
                    },
                    selectedColor: accState.primaryColor.withValues(alpha: 0.25),
                    checkmarkColor: accState.primaryColor,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isLgt = Theme.of(context).brightness == Brightness.light;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLgt ? Colors.black.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isLgt ? Colors.black12 : Colors.white12),
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
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: isLgt ? Colors.black45 : Colors.white54, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
