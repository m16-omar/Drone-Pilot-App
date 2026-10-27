import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Central theme definitions for Drone Control Pilot (Light & Dark modes).
abstract final class AppTheme {
  /// Dark Theme (Aeronautical Cockpit Mode)
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.jetBlack,
      cardColor: AppColors.cockpitSlate,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.avionicsBlue,
        brightness: Brightness.dark,
        surface: AppColors.cockpitSlate,
        onSurface: Colors.white,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cockpitSlate,
        elevation: 2,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cockpitSlate,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: const Color(0x2A94A3B8),
    );
  }

  /// Light Theme (Bright Day / Airfield Mode)
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Slate 100
      cardColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.avionicsBlue,
        brightness: Brightness.light,
        surface: Colors.white,
        onSurface: const Color(0xFF0F172A),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: const Color(0xFFE2E8F0),
    );
  }
}

/// Handy extension on [BuildContext] to access theme-adaptive tokens.
extension AppThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get cardBg => isDark ? AppColors.cockpitSlate : Colors.white;

  Color get cardBorder =>
      isDark ? const Color(0x2A94A3B8) : const Color(0x1F0F172A);

  Color get textPrimary => isDark ? Colors.white : const Color(0xFF0F172A);

  Color get textMuted => isDark ? AppColors.textMuted : const Color(0xFF64748B);
}
