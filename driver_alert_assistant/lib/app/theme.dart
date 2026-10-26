import 'package:flutter/material.dart';

import '../models/app_settings.dart';

/// Colours and sizes for the whole app.
///
/// Big text and big buttons so they are easy to read and press.
class AppTheme {
  AppTheme._();

  static const Color brand = Color(0xFF00796B);
  static const Color danger = Color(0xFFC62828);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeMode modeFor(ThemeChoice choice) {
    switch (choice) {
      case ThemeChoice.light:
        return ThemeMode.light;
      case ThemeChoice.dark:
        return ThemeMode.dark;
      case ThemeChoice.system:
        return ThemeMode.system;
    }
  }

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: brightness,
    );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    const bigButton = Size.fromHeight(56);
    const buttonText = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 18),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: bigButton,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: bigButton,
          textStyle: buttonText,
        ),
      ),
      cardTheme: const CardThemeData(margin: EdgeInsets.zero),
    );
  }
}
