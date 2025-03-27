// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color deepIndigo = Color(0xFF2D3047);
  static const Color softLavender = Color(0xFF8D9DB6);
  static const Color etherealCyan = Color(0xFF4ECDC4);
  static const Color backgroundStart = Color(0xFF121212);
  static const Color backgroundEnd = Color(0xFF1E1E24);
  
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: backgroundStart,
      primaryColor: etherealCyan,
      colorScheme: const ColorScheme.dark(
        primary: etherealCyan,
        secondary: softLavender,
        background: backgroundStart,
        surface: deepIndigo,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: GoogleFonts.spaceGrotesk(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.5,
            color: Colors.white,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: etherealCyan,
          foregroundColor: Colors.black87,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
          elevation: 4,
        ),
      ),
    );
  }
}
