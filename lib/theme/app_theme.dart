import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.deepTeal,
          primary: AppColors.deepTeal,
          secondary: AppColors.limeAccent,
          surface: AppColors.surface,
          error: AppColors.danger,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.dmSansTextTheme().copyWith(
          headlineLarge: GoogleFonts.manrope(fontSize: 29, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -1),
          headlineMedium: GoogleFonts.manrope(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.7),
          titleMedium: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
          bodyMedium: GoogleFonts.dmSans(fontSize: 12, color: AppColors.ink),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
          border: _fieldBorder,
          enabledBorder: _fieldBorder,
          focusedBorder: _fieldBorder.copyWith(
            borderSide: const BorderSide(color: AppColors.deepTeal, width: 1.5),
          ),
        ),
      );

  static final _fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.fieldBorder),
  );
}
