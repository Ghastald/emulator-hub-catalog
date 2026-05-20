// lib/shared/theme/app_theme.dart

import 'package:flutter/material.dart';

abstract class AppColors {
  static const green   = Color(0xFF3DCA8F);   // beacon green — primary accent
  static const offWhite = Color(0xFFD8D6CF);  // text / surfaces on dark
  static const black   = Color(0xFF0A0A0A);   // background
  static const amber   = Color(0xFFEF9F27);   // secondary accent / warnings
  static const surface = Color(0xFF141414);
  static const card    = Color(0xFF1C1C1C);
  static const border  = Color(0xFF2A2A2A);
  static const muted   = Color(0xFF6B6B6B);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.black,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.green,
      secondary: AppColors.amber,
      surface: AppColors.surface,
      onPrimary: AppColors.black,
      onSecondary: AppColors.black,
      onSurface: AppColors.offWhite,
    ),
    cardTheme: CardTheme(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.black,
      foregroundColor: AppColors.offWhite,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.border,
      labelStyle: const TextStyle(color: AppColors.offWhite, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: BorderSide.none,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.offWhite,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(color: AppColors.offWhite, fontWeight: FontWeight.w600),
      titleLarge:    TextStyle(color: AppColors.offWhite, fontWeight: FontWeight.w500),
      titleMedium:   TextStyle(color: AppColors.offWhite),
      bodyMedium:    TextStyle(color: AppColors.offWhite, fontSize: 14),
      bodySmall:     TextStyle(color: AppColors.muted, fontSize: 12),
    ),
  );
}
