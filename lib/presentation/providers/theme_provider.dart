import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeOption {
  system,
  light,
  dark;

  String get displayName {
    switch (this) {
      case ThemeModeOption.system:
        return 'System';
      case ThemeModeOption.light:
        return 'Light';
      case ThemeModeOption.dark:
        return 'Dark';
    }
  }
}

class ThemeNotifier extends StateNotifier<ThemeModeOption> {
  static const String _themeKey = 'theme_mode';

  ThemeNotifier() : super(ThemeModeOption.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_themeKey);
      if (themeString != null) {
        state = ThemeModeOption.values.firstWhere(
          (e) => e.name == themeString,
          orElse: () => ThemeModeOption.system,
        );
      }
    } catch (e) {
      // Fallback to system theme on error
      state = ThemeModeOption.system;
    }
  }

  Future<void> setTheme(ThemeModeOption theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme.name);
      state = theme;
    } catch (e) {
      // If save fails, still update state (in-memory only)
      state = theme;
    }
  }

  ThemeMode get themeMode {
    switch (state) {
      case ThemeModeOption.system:
        return ThemeMode.system;
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeModeOption>((ref) {
  return ThemeNotifier();
});

