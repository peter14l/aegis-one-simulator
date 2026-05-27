import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(
    0xFF09090B,
  ); // Slate/Zinc Black (Vercel)
  static const Color surface = Color(0xFF18181B); // Slate/Zinc Dark
  static const Color primary = Color(
    0xFF3B82F6,
  ); // Sapphire Blue (Tailwind Blue)
  static const Color secondary = Color(0xFF6366F1); // Royal Indigo
  static const Color accent = Color(0xFF8B5CF6); // Enterprise Violet
  static const Color textPrimary = Color(0xFFF4F4F5); // Crisp Zinc Off-White
  static const Color textSecondary = Color(
    0xFF8E8E9F,
  ); // Elegant Muted Slate Grey
  static const Color danger = Color(0xFFEF4444); // Coral Red
  static const Color success = Color(0xFF10B981); // Emerald Green

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
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -1.0,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.015),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: primary),
      dividerColor: textSecondary.withValues(alpha: 0.08),
    );
  }
}
