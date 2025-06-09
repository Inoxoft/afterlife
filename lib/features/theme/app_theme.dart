import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

/// AppTheme defines the visual styling for the entire Afterlife application.
/// This includes colors, text styles, decorations, and other visual elements.
class AppTheme {
  // Primary colors
  static Color primaryColor = const Color(0xFF00E5FF);
  static Color secondaryColor = const Color(0xFFAE00FF);
  static Color accentColor = const Color(0xFFFFD500);

  // Neutral colors
  static Color darkColor = const Color(0xFF121212);
  static Color darkAccentColor = const Color(0xFF1E1E1E);
  static Color lightColor = const Color(0xFFFFFFFF);
  static Color greyColor = const Color(0xFF9E9E9E);

  // Jar-specific colors
  static Color jarGlassColorDark = const Color(0xFF0C4754);
  static Color jarRimColor = const Color(0xFF236D82);
  static MaterialColor neutralColor = MaterialColor(0xFF9E9E9E, <int, Color>{
    50: const Color(0xFFFAFAFA),
    100: const Color(0xFFF5F5F5),
    200: const Color(0xFFEEEEEE),
    300: const Color(0xFFE0E0E0),
    400: const Color(0xFFBDBDBD),
    500: const Color(0xFF9E9E9E),
    600: const Color(0xFF757575),
    700: const Color(0xFF616161),
    800: const Color(0xFF424242),
    900: const Color(0xFF212121),
  });

  // Semantic colors
  static Color successColor = const Color(0xFF4CAF50);
  static Color errorColor = const Color(0xFFF44336);
  static Color warningColor = const Color(0xFFFFEB3B);
  static Color infoColor = const Color(0xFF2196F3);

  // Gradients - Enhanced for better visibility
  static LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryColor.withValues(alpha: 0.6)],
  );

  static LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryColor, primaryColor],
  );

  static LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkColor, darkAccentColor],
  );

  // Additional gradients
  static LinearGradient jarGlassGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [jarGlassColorDark.withValues(alpha: 0.6), jarGlassColorDark],
  );

  static LinearGradient neonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, secondaryColor],
  );

  // Text styles
  static TextStyle get headingStyle => GoogleFonts.spaceMono(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: lightColor,
    letterSpacing: 0.5,
  );

  static TextStyle get subheadingStyle => GoogleFonts.spaceMono(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: lightColor,
    letterSpacing: 0.3,
  );

  static TextStyle get bodyStyle => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: lightColor,
    letterSpacing: 0.2,
  );

  static TextStyle get captionStyle => GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: greyColor,
    letterSpacing: 0.1,
  );

  static TextStyle get buttonStyle => GoogleFonts.roboto(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: darkColor,
    letterSpacing: 0.3,
  );

  // Decorations
  static BoxDecoration cardDecoration = BoxDecoration(
    color: darkAccentColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1),
    boxShadow: [
      BoxShadow(
        color: darkColor.withValues(alpha: 0.5),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration buttonDecoration = BoxDecoration(
    color: primaryColor,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.3),
        blurRadius: 8,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration inputDecoration = BoxDecoration(
    color: darkAccentColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: greyColor.withValues(alpha: 0.3), width: 1),
  );

  // Theme data
  static ThemeData themeData = ThemeData(
    scaffoldBackgroundColor: darkColor,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: darkColor,
      error: errorColor,
    ),
    textTheme: TextTheme(
      displayLarge: headingStyle,
      displayMedium: subheadingStyle,
      bodyLarge: bodyStyle,
      bodyMedium: captionStyle,
      labelLarge: buttonStyle,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: lightColor),
      titleTextStyle: headingStyle,
    ),
    iconTheme: IconThemeData(color: lightColor, size: 24),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: darkColor,
        textStyle: buttonStyle,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkAccentColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: greyColor.withValues(alpha: 0.3), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: greyColor.withValues(alpha: 0.3), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: primaryColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: errorColor.withValues(alpha: 0.6), width: 1),
      ),
      labelStyle: captionStyle,
      hintStyle: captionStyle.copyWith(color: greyColor.withValues(alpha: 0.5)),
    ),
  );
}
