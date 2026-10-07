import 'package:flutter/material.dart';

abstract final class StudentColors {
  static const background = Color(0xFFEAF4FF);
  static const backgroundDark = Color(0xFF0F172A);
  static const ink = Color(0xFF101318);
  static const inkDark = Color(0xFFF8FAFC);
  static const mutedInk = Color(0xFF777B84);
  static const mutedInkDark = Color(0xFF94A3B8);
  static const primary = Color(0xFF4B96F3);
  static const softBlue = Color(0xFFEAF4FF);
  static const softBlueDark = Color(0xFF1E293B);
  static const cardBlue = Color(0xFFBFE0FC);
  static const cardPurple = Color(0xFFE4C7FF);
}

abstract final class StudentTheme {
  static ThemeData lightTheme() {
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
        fontFamily: 'Poppins',
        bodyColor: StudentColors.ink,
        displayColor: StudentColors.ink,
      ),
    );
  }
}
