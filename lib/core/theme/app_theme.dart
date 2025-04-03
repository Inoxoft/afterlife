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
  static const Color accentPurple = Color(0xFF9D8DF1);
  static const Color subtleGrey = Color(0xFF2A2A2A);

  // Gradients
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundStart, backgroundEnd],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [etherealCyan, accentPurple],
  );

  // BoxDecorations
  static BoxDecoration get glowDecoration => BoxDecoration(
    boxShadow: [
      BoxShadow(
        color: etherealCyan.withOpacity(0.2),
        blurRadius: 15,
        spreadRadius: 1,
      ),
    ],
  );

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: subtleGrey.withOpacity(0.3),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white10),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Main theme
  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: backgroundStart,
    primaryColor: etherealCyan,
    colorScheme: const ColorScheme.dark(
      primary: etherealCyan,
      secondary: softLavender,
      tertiary: accentPurple,
      surface: deepIndigo,
      background: backgroundStart,
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(
      ThemeData.dark().textTheme.copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          letterSpacing: 2.5,
          color: Colors.white,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w300,
          letterSpacing: 1.5,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: Colors.white60),
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
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25.0),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.black26,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 14.0,
      ),
      hintStyle: TextStyle(color: Colors.white60),
    ),
  );

  // ColorScheme for the app
  static final ColorScheme colorScheme = ColorScheme.dark(
    primary: etherealCyan,
    secondary: accentPurple,
    background: backgroundStart,
    surface: deepIndigo,
    error: Colors.red.shade300,
    onPrimary: Colors.black,
    onSecondary: Colors.white,
    onBackground: Colors.white,
    onSurface: Colors.white,
    onError: Colors.white,
    brightness: Brightness.dark,
  );
}
