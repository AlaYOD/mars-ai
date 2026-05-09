import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontSizeOption { small, medium, large, extraLarge }
enum ThemeColorOption { purple, teal, blue, green }
enum BrightnessOption { dark, amoled, light }

class AccessibilityState {
  final FontSizeOption fontSize;
  final ThemeColorOption themeColor;
  final BrightnessOption brightness;

  const AccessibilityState({
    this.fontSize = FontSizeOption.medium,
    this.themeColor = ThemeColorOption.purple,
    this.brightness = BrightnessOption.dark,
  });

  double get fontMultiplier {
    switch (fontSize) {
      case FontSizeOption.small:
        return 0.85;
      case FontSizeOption.medium:
        return 1.0;
      case FontSizeOption.large:
        return 1.25;
      case FontSizeOption.extraLarge:
        return 1.45;
    }
  }

  Color get primaryColor {
    switch (themeColor) {
      case ThemeColorOption.purple:
        return Colors.deepPurpleAccent;
      case ThemeColorOption.teal:
        return Colors.tealAccent;
      case ThemeColorOption.blue:
        return Colors.blueAccent;
      case ThemeColorOption.green:
        return Colors.greenAccent;
    }
  }

  ThemeData getThemeData() {
    Color bg;
    Color cardBg;
    Brightness br;
    switch (brightness) {
      case BrightnessOption.dark:
        bg = const Color(0xFF0D0D0D);
        cardBg = const Color(0xFF1E1E1E);
        br = Brightness.dark;
        break;
      case BrightnessOption.amoled:
        bg = Colors.black;
        cardBg = const Color(0xFF0F0F0F);
        br = Brightness.dark;
        break;
      case BrightnessOption.light:
        bg = const Color(0xFFF5F5F7);
        cardBg = Colors.white;
        br = Brightness.light;
        break;
    }

    final prim = primaryColor;
    final isLgt = br == Brightness.light;

    return ThemeData(
      brightness: br,
      scaffoldBackgroundColor: bg,
      primaryColor: prim,
      colorScheme: ColorScheme.fromSeed(
        seedColor: prim,
        brightness: br,
        primary: prim,
        surface: cardBg,
      ),
      useMaterial3: true,
      dividerTheme: DividerThemeData(
        color: isLgt ? Colors.black12 : Colors.white.withValues(alpha: 0.08),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isLgt ? Colors.black87 : Colors.white),
        titleTextStyle: TextStyle(
          color: isLgt ? Colors.black87 : Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme().apply(
        fontSizeFactor: fontMultiplier,
        bodyColor: isLgt ? Colors.black87 : Colors.white,
        displayColor: isLgt ? Colors.black87 : Colors.white,
      ),
    );
  }

  AccessibilityState copyWith({
    FontSizeOption? fontSize,
    ThemeColorOption? themeColor,
    BrightnessOption? brightness,
  }) {
    return AccessibilityState(
      fontSize: fontSize ?? this.fontSize,
      themeColor: themeColor ?? this.themeColor,
      brightness: brightness ?? this.brightness,
    );
  }
}

final accessibilityProvider =
    StateNotifierProvider<AccessibilityNotifier, AccessibilityState>((ref) {
  return AccessibilityNotifier();
});

class AccessibilityNotifier extends StateNotifier<AccessibilityState> {
  AccessibilityNotifier() : super(const AccessibilityState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final fIndex = prefs.getInt('acc_font_size') ?? FontSizeOption.medium.index;
    final cIndex = prefs.getInt('acc_color_theme') ?? ThemeColorOption.purple.index;
    final bIndex = prefs.getInt('acc_brightness') ?? BrightnessOption.dark.index;

    state = AccessibilityState(
      fontSize: FontSizeOption.values[fIndex],
      themeColor: ThemeColorOption.values[cIndex],
      brightness: BrightnessOption.values[bIndex],
    );
  }

  Future<void> setFontSize(FontSizeOption size) async {
    state = state.copyWith(fontSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('acc_font_size', size.index);
  }

  Future<void> setThemeColor(ThemeColorOption color) async {
    state = state.copyWith(themeColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('acc_color_theme', color.index);
  }

  Future<void> setBrightness(BrightnessOption brightness) async {
    state = state.copyWith(brightness: brightness);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('acc_brightness', brightness.index);
  }
}
