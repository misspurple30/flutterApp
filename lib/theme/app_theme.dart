import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF7C4DFF);
  static const primaryDark = Color(0xFF5E35B1);
  static const accent = Color(0xFFB388FF);

  static const lightBg = Color(0xFFF7F5FB);
  static const lightSurface = Colors.white;
  static const lightBubbleOther = Color(0xFFEDE7F6);

  static const darkBg = Color(0xFF121016);
  static const darkSurface = Color(0xFF1E1A24);
  static const darkBubbleOther = Color(0xFF2A2432);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: _inputTheme(isDark: false),
      elevatedButtonTheme: _buttonTheme(),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.lightSurface,
        margin: EdgeInsets.zero,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: _inputTheme(isDark: true),
      elevatedButtonTheme: _buttonTheme(),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        margin: EdgeInsets.zero,
      ),
    );
  }

  static InputDecorationTheme _inputTheme({required bool isDark}) {
    final borderColor =
        isDark ? Colors.white.withOpacity(.15) : Colors.black.withOpacity(.1);
    return InputDecorationTheme(
      filled: true,
      fillColor:
          isDark ? AppColors.darkSurface : AppColors.lightSurface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  static ElevatedButtonThemeData _buttonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }
}
