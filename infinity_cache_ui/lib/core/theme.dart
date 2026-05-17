import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF0D0D12);
  static const Color surface = Color(0xFF161622);
  static const Color primary = Color(0xFF00FFCC); // Neon Cyan
  static const Color secondary = Color(0xFFFF0055); // Neon Pink
  static const Color accent = Color(0xFFB026FF); // Deep Neon Purple
  static const Color textPrimary = Color(0xFFE0E0E0);
  static const Color textSecondary = Color(0xFF8A8A9D);
  static const Color danger = Color(0xFFFF3333);
  static const Color success = Color(0xFF33FF77);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: danger,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.rajdhani(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 2.0,
        ),
        titleLarge: GoogleFonts.rajdhani(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.jetBrainsMono(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          color: primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 8,
        shadowColor: primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primary.withOpacity(0.2), width: 1),
        ),
      ),
      iconTheme: const IconThemeData(color: primary),
      dividerColor: textSecondary.withOpacity(0.2),
    );
  }
}
