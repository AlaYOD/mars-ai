import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/locale_provider.dart';
import 'home_screen.dart';
import '../team/team_screen.dart';
import '../settings/settings_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TeamScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Directionality(
        textDirection: l10n.textDirection,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)),
          ),
          child: BottomNavigationBar(
            backgroundColor: const Color(0xFF0D0D0D),
            selectedItemColor: Colors.deepPurpleAccent,
            unselectedItemColor: Colors.white54,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.dashboard_outlined),
                activeIcon: const Icon(Icons.dashboard),
                label: l10n.translate('nav_home'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.people_outline),
                activeIcon: const Icon(Icons.people),
                label: l10n.translate('nav_team'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings_outlined),
                activeIcon: const Icon(Icons.settings),
                label: l10n.translate('nav_settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
