import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing app-wide theme mood (Dark / Light).
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Default to aeronautical dark mode
    return ThemeMode.dark;
  }

  /// Toggle between Dark and Light mood
  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  /// Explicitly set the theme mood
  void setTheme(ThemeMode mode) {
    state = mode;
  }
}
