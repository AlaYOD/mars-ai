import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/locale_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nativeCountryCtrl = TextEditingController();
  final _hostCountryCtrl = TextEditingController();
  String? _selectedLanguage;
  String _status = 'Immigrant'; // Default

  static const List<String> _countries = [
    'Afghanistan', 'Algeria', 'Argentina', 'Australia', 'Austria', 'Bangladesh', 'Belgium', 'Brazil',
    'Canada', 'China', 'Colombia', 'Egypt', 'France', 'Germany', 'India', 'Indonesia',
    'Iraq', 'Italy', 'Japan', 'Jordan', 'Lebanon', 'Morocco', 'Netherlands', 'Pakistan',
    'Saudi Arabia', 'South Africa', 'Spain', 'Sudan', 'Sweden', 'Switzerland', 'Syria',
    'Tunisia', 'Turkey', 'United Arab Emirates', 'United Kingdom', 'United States', 'Yemen'
  ];

  static const List<String> _languages = [
    'Arabic (العربية)', 'Bengali', 'Chinese', 'English', 'French (Français)',
    'German (Deutsch)', 'Hindi', 'Indonesian', 'Italian (Italiano)', 'Japanese',
    'Korean', 'Persian (Farsi)', 'Portuguese', 'Russian', 'Spanish (Español)',
    'Turkish (Türkçe)', 'Urdu'
  ];

  @override
  void dispose() {
    _nativeCountryCtrl.dispose();
    _hostCountryCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(profileNotifierProvider.notifier).saveProfile(
        nativeCountry: _nativeCountryCtrl.text.trim(),
        hostCountry: _hostCountryCtrl.text.trim(),
        language: _selectedLanguage ?? '',
        status: _status,
      );
    }
  }

  void _showSelector({
    required String title,
    required List<String> items,
    required TextEditingController controller,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isLgt = Theme.of(context).brightness == Brightness.light;
            final bg = isLgt ? const Color(0xFFF5F5F7) : const Color(0xFF141414);
            final textCol = isLgt ? Colors.black87 : Colors.white;

            final filtered = items
                .where((item) => item.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(color: textCol, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: isLgt ? Colors.black54 : Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    style: TextStyle(color: textCol),
                    decoration: InputDecoration(
                      hintText: 'Search / بحث / Rechercher...',
                      hintStyle: TextStyle(color: isLgt ? Colors.black38 : Colors.white30),
                      prefixIcon: Icon(Icons.search, color: isLgt ? Colors.black45 : Colors.white54),
                      filled: true,
                      fillColor: isLgt ? Colors.black.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isSelected = item.toLowerCase() == controller.text.toLowerCase();
                        return ListTile(
                          title: Text(item, style: TextStyle(color: textCol, fontSize: 15)),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: Colors.deepPurpleAccent)
                              : null,
                          onTap: () {
                            setState(() {
                              controller.text = item;
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);
    final activeLocale = ref.watch(localeProvider);
    final isLgt = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('setup_title')),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: l10n.textDirection,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isLgt ? Colors.black.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isLgt ? Colors.black12 : Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: activeLocale.languageCode,
                        dropdownColor: isLgt ? Colors.white : const Color(0xFF1A1A1A),
                        isExpanded: true,
                        style: TextStyle(color: isLgt ? Colors.black87 : Colors.white, fontSize: 16),
                        icon: Icon(Icons.translate, color: isLgt ? Colors.black54 : Colors.white70),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English (App Language)')),
                          DropdownMenuItem(value: 'ar', child: Text('العربية (لغة التطبيق)')),
                          DropdownMenuItem(value: 'fr', child: Text('Français (Langue de l\'app)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(localeProvider.notifier).setLocale(val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    l10n.translate('setup_subtitle'),
                    style: TextStyle(color: isLgt ? Colors.black54 : Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  _buildSelectorField(
                    controller: _nativeCountryCtrl,
                    label: l10n.translate('setup_native_country'),
                    icon: Icons.public,
                    validatorMessage: l10n.translate('setup_err_enter'),
                    onTap: () => _showSelector(
                      title: l10n.translate('setup_native_country'),
                      items: _countries,
                      controller: _nativeCountryCtrl,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSelectorField(
                    controller: _hostCountryCtrl,
                    label: l10n.translate('setup_host_country'),
                    icon: Icons.location_on,
                    validatorMessage: l10n.translate('setup_err_enter'),
                    onTap: () => _showSelector(
                      title: l10n.translate('setup_host_country'),
                      items: _countries,
                      controller: _hostCountryCtrl,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: InputDecoration(
                      labelText: l10n.translate('setup_native_lang'),
                      labelStyle: TextStyle(color: isLgt ? Colors.black45 : Colors.white.withValues(alpha: 0.5)),
                      prefixIcon: Icon(Icons.language, color: isLgt ? Colors.black45 : Colors.white.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: isLgt ? Colors.black.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isLgt ? Colors.black12 : Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.deepPurpleAccent),
                      ),
                    ),
                    dropdownColor: isLgt ? Colors.white : const Color(0xFF1A1A1A),
                    style: TextStyle(color: isLgt ? Colors.black87 : Colors.white, fontSize: 16),
                    icon: Icon(Icons.arrow_drop_down, color: isLgt ? Colors.black54 : Colors.white70),
                    items: _languages.map((lang) {
                      return DropdownMenuItem<String>(
                        value: lang,
                        child: Text(lang),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedLanguage = val;
                      });
                    },
                    validator: (val) => val == null || val.isEmpty ? '${l10n.translate('setup_err_enter')} ${l10n.translate('setup_native_lang')}' : null,
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    l10n.translate('setup_status'),
                    style: TextStyle(color: isLgt ? Colors.black54 : Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isLgt ? Colors.black.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isLgt ? Colors.black12 : Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _status,
                        dropdownColor: isLgt ? Colors.white : const Color(0xFF1A1A1A),
                        isExpanded: true,
                        style: TextStyle(color: isLgt ? Colors.black87 : Colors.white, fontSize: 16),
                        items: [
                          DropdownMenuItem(value: 'Immigrant', child: Text(l10n.translate('setup_status_immigrant'))),
                          DropdownMenuItem(value: 'Student', child: Text(l10n.translate('setup_status_student'))),
                          DropdownMenuItem(value: 'Expat', child: Text(l10n.translate('setup_status_expat'))),
                          DropdownMenuItem(value: 'Other', child: Text(l10n.translate('setup_status_other'))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _status = val);
                          }
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.translate('setup_continue'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String validatorMessage,
    required VoidCallback onTap,
  }) {
    final isLgt = Theme.of(context).brightness == Brightness.light;
    final textCol = isLgt ? Colors.black87 : Colors.white;

    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: TextStyle(color: textCol),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isLgt ? Colors.black45 : Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: isLgt ? Colors.black45 : Colors.white.withValues(alpha: 0.5)),
        suffixIcon: Icon(Icons.arrow_drop_down, color: isLgt ? Colors.black54 : Colors.white70),
        filled: true,
        fillColor: isLgt ? Colors.black.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isLgt ? Colors.black12 : Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurpleAccent),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$validatorMessage $label';
        }
        return null;
      },
    );
  }
}
