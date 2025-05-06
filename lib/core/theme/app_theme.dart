// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central theme configuration for the Afterlife application
class AppTheme {
  // Primary colors - Updated for mask aesthetics
  static const Color midnightPurple = Color(
    0xFF2C2344,
  ); // Deeper purple for dramatic effect
  static const Color deepNavy = Color(0xFF171B38); // Darker navy for background
  static const Color warmGold = Color(0xFFE6C988); // Keeping gold for accents
  static const Color silverMist = Color(
    0xFFE0E6ED,
  ); // Slightly brighter for better contrast
  static const Color dustyRose = Color(
    0xFFC9A9A6,
  ); // Keeping for Monroe's lipstick accent

  // Accent colors - Updated for mask aesthetics
  static const Color etherealGold = Color(0xFFDAAA40); // Richer gold
  static const Color celestialTeal = Color(
    0xFF498D96,
  ); // Slightly brighter teal
  static const Color softCopper = Color(
    0xFFCB8D73,
  ); // Keeping for skin tone accent
  static const Color gentlePurple = Color(
    0xFFA78FC5,
  ); // Slightly brighter purple

  // Legacy colors - keeping for backward compatibility and some UI elements
  static const Color cosmicBlack = Color(
    0xFF080815,
  ); // Slightly adjusted for mask theme
  static const Color deepSpaceNavy = Color(0xFF050530);
  static const Color etherealCyan = Color(0xFF00BFFF);
  static const Color cyberPurple = Color(0xFF8A2BE2);
  static const Color neonPink = Color(0xFFFF1493);
  static const Color cosmicBlue = Color(0xFF0B0B45);
  static const Color starlight = Color(0xFFE6E6FA);
  static const Color accentPurple = Color(0xFF9370DB);
  static const Color backgroundStart = Color(
    0xFF1C1A36,
  ); // Adjusted for mask theme
  static const Color backgroundEnd = Color(
    0xFF14141C,
  ); // Adjusted for mask theme
  static const Color deepIndigo = Color(0xFF1E1E52);

  // Background gradients - Updated for mask aesthetics
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundStart, backgroundEnd],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [celestialTeal, gentlePurple],
  );

  static const LinearGradient energyFieldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x26E6C988),
      Color(0x4DA78FC5),
    ], // Adjusted opacity and colors
    stops: [0.0, 1.0],
  );

  // Text styles - Updated for better contrast with new colors
  static TextStyle get titleStyle => GoogleFonts.cinzel(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    letterSpacing: 3.0,
    color: silverMist,
    shadows: [
      Shadow(
        color: warmGold.withOpacity(0.8),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static TextStyle get subtitleStyle => GoogleFonts.cinzel(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 3.0,
    color: silverMist,
    shadows: [
      Shadow(
        color: warmGold.withOpacity(0.6),
        blurRadius: 8,
        offset: const Offset(0, 1),
      ),
    ],
  );

  static TextStyle get bodyTextStyle => GoogleFonts.lato(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: silverMist,
    letterSpacing: 0.5,
  );

  static TextStyle get captionStyle => GoogleFonts.lato(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: silverMist.withOpacity(0.9),
    letterSpacing: 0.5,
  );

  static TextStyle get twinNameStyle => GoogleFonts.cinzel(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    color: silverMist,
  );

  static TextStyle get metadataStyle => GoogleFonts.lato(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: silverMist.withOpacity(0.8),
    letterSpacing: 0.3,
  );

  static TextStyle get labelStyle => GoogleFonts.lato(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: warmGold,
  );

  // Container decorations - Updated for mask aesthetics
  static BoxDecoration get containerDecoration => BoxDecoration(
    color: midnightPurple.withOpacity(0.7), // More opacity for dramatic effect
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: warmGold.withOpacity(0.4),
      width: 1,
    ), // Slightly more visible border
    boxShadow: [
      BoxShadow(
        color: cosmicBlack.withOpacity(0.5),
        blurRadius: 15,
        spreadRadius: 1,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static BoxDecoration get energyFieldDecoration => BoxDecoration(
    gradient: energyFieldGradient,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: warmGold.withOpacity(0.2),
        blurRadius: 15,
        spreadRadius: 0,
      ),
    ],
  );

  // Updated glow effect for masks
  static BoxDecoration get glowDecoration => BoxDecoration(
    boxShadow: [
      BoxShadow(
        color: warmGold.withOpacity(0.4), // Slightly stronger glow
        blurRadius: 20,
        spreadRadius: 0,
      ),
    ],
  );

  // Bottom navigation theme - Updated with new colors
  static BottomNavigationBarThemeData get bottomNavTheme =>
      BottomNavigationBarThemeData(
        backgroundColor: cosmicBlack.withOpacity(0.85), // Slightly more opaque
        selectedItemColor: warmGold,
        unselectedItemColor: silverMist.withOpacity(0.5),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      );

  // Divider styling
  static Divider get divider =>
      Divider(color: warmGold.withOpacity(0.3), thickness: 1, height: 1);
}
