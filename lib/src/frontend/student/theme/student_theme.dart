import 'package:flutter/material.dart';

abstract final class StudentColors {
  static const background = Color(0xFFF9FBFF);
  static const ink = Color(0xFF101318);
  static const mutedInk = Color(0xFF777B84);
  static const primary = Color(0xFF4B96F3);
  static const softBlue = Color(0xFFEAF4FF);
  static const cardBlue = Color(0xFFBFE0FC);
  static const cardPurple = Color(0xFFE4C7FF);
}

abstract final class StudentTheme {
  static ThemeData theme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: StudentColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: StudentColors.primary,
        onPrimary: Colors.white,
        surface: StudentColors.background,
        onSurface: StudentColors.ink,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: StudentColors.ink,
        displayColor: StudentColors.ink,
        fontFamily: 'Arial',
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        indicatorColor: StudentColors.softBlue,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}