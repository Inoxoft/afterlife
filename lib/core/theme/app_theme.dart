import 'package:flutter/material.dart';

/// Unified theme configuration for the Afterlife application
/// Consolidates both core and features theme classes into a single, comprehensive design system
class AppTheme {
  // ============================================================================
  // PRIMARY THEME COLORS - Main mask aesthetics theme
  // ============================================================================
  
  /// Primary colors - Updated for mask aesthetics
  static const Color midnightPurple = Color(0xFF2C2344); // Deeper purple for dramatic effect
  static const Color deepNavy = Color(0xFF171B38); // Darker navy for background
  static const Color warmGold = Color(0xFFE6C988); // Keeping gold for accents
  static const Color silverMist = Color(0xFFE0E6ED); // Slightly brighter for better contrast
  static const Color dustyRose = Color(0xFFC9A9A6); // Keeping for Monroe's lipstick accent

  /// Accent colors - Updated for mask aesthetics
  static const Color etherealGold = Color(0xFFDAAA40); // Richer gold
  static const Color celestialTeal = Color(0xFF498D96); // Slightly brighter teal
  static const Color softCopper = Color(0xFFCB8D73); // Keeping for skin tone accent
  static const Color gentlePurple = Color(0xFFA78FC5); // Slightly brighter purple

  /// Legacy colors - keeping for backward compatibility and some UI elements
  static const Color cosmicBlack = Color(0xFF080815); // Slightly adjusted for mask theme
  static const Color deepSpaceNavy = Color(0xFF050530);
  static const Color etherealCyan = Color(0xFF00E5FF);
  static const Color cyberPurple = Color(0xFF8A2BE2);
  static const Color neonPink = Color(0xFFFF1493);
  static const Color cosmicBlue = Color(0xFF0B0B45);
  static const Color starlight = Color(0xFFE6E6FA);
  static const Color accentPurple = Color(0xFF9370DB);
  static const Color backgroundStart = Color(0xFF1C1A36); // Adjusted for mask theme
  static const Color backgroundEnd = Color(0xFF14141C); // Adjusted for mask theme
  static const Color deepIndigo = Color(0xFF1E1E52);

  // ============================================================================
  // ALTERNATIVE THEME COLORS - From features theme (for compatibility)
  // ============================================================================
  
  /// Alternative primary colors (from features theme)
  static const Color primaryColor = Color(0xFF6200EE);
  static const Color secondaryColor = Color(0xFFAE00FF);
  static const Color accentColor = Color(0xFFFFD500);

  /// Neutral colors (from features theme)
  static const Color darkColor = Color(0xFF121212);
  static const Color darkAccentColor = Color(0xFF1E1E1E);
  static const Color lightColor = Color(0xFFFFFFFF);
  static const Color greyColor = Color(0xFF9E9E9E);

  /// Jar-specific colors (from features theme)
  static const Color jarGlassColorDark = Color(0xFF0C4754);
  static const Color jarRimColor = Color(0xFF236D82);
  
  /// Material color swatch (from features theme)
  static const MaterialColor neutralColor = MaterialColor(0xFF9E9E9E, <int, Color>{
    50: Color(0xFFFAFAFA),
    100: Color(0xFFF5F5F5),
    200: Color(0xFFEEEEEE),
    300: Color(0xFFE0E0E0),
    400: Color(0xFFBDBDBD),
    500: Color(0xFF9E9E9E),
    600: Color(0xFF757575),
    700: Color(0xFF616161),
    800: Color(0xFF424242),
    900: Color(0xFF212121),
  });

  /// Semantic colors (from features theme)
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFFEB3B);
  static const Color infoColor = Color(0xFF2196F3);

  // ============================================================================
  // GRADIENTS - Unified from both themes
  // ============================================================================
  
  /// Main background gradients - Primary mask aesthetics
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

  /// Alternative gradients (from features theme)
  static LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryColor.withValues(alpha: 0.6)],
  );

  static LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkColor, darkAccentColor],
  );

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

  // ============================================================================
  // TEXT STYLES - Unified from both themes
  // ============================================================================
  
  /// Base text style with Lato font (primary theme)
  static const TextStyle baseTextStyle = TextStyle(
    fontFamily: 'Lato',
    color: AppTheme.silverMist,
    height: 1.5,
  );

  /// Title style with Cinzel font - for main headings (primary theme)
  static TextStyle get titleStyle => const TextStyle(
    fontFamily: 'Cinzel',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppTheme.warmGold,
    letterSpacing: 2.0,
    shadows: [
      Shadow(blurRadius: 8.0, color: AppTheme.warmGold, offset: Offset(0, 0)),
    ],
  );

  /// Subtitle style - for secondary headings (primary theme)
  static TextStyle get subtitleStyle => const TextStyle(
    fontFamily: 'Cinzel',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppTheme.silverMist,
    letterSpacing: 1.5,
  );

  /// Body text style - for standard text (primary theme)
  static TextStyle get bodyTextStyle =>
      baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.normal);

  /// Caption style - for smaller text, metadata (primary theme)
  static TextStyle get captionStyle => baseTextStyle.copyWith(
    fontSize: 12,
    color: AppTheme.silverMist.withValues(alpha: 0.7),
  );

  /// Twin name style - for character names in cards (primary theme)
  static TextStyle get twinNameStyle => const TextStyle(
    fontFamily: 'Cinzel',
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppTheme.silverMist,
  );

  /// Metadata style - for timestamps, etc. (primary theme)
  static TextStyle get metadataStyle => baseTextStyle.copyWith(
    fontSize: 12,
    color: AppTheme.silverMist.withValues(alpha: 0.6),
  );

  /// Label style - for buttons, tabs, etc. (primary theme)
  static TextStyle get labelStyle => baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
  );

  // Alternative text styles (from features theme) - for backward compatibility
  static TextStyle get headingStyle => const TextStyle(
    fontFamily: 'SpaceMono',
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  static TextStyle get subheadingStyle => const TextStyle(
    fontFamily: 'SpaceMono',
    fontSize: 18.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.1,
  );

  static TextStyle get bodyStyle => const TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16.0,
    height: 1.5,
  );

  static TextStyle get buttonStyle => const TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.1,
  );

  // ============================================================================
  // DECORATIONS - Unified from both themes
  // ============================================================================
  
  /// Primary container decorations - mask aesthetics
  static BoxDecoration get containerDecoration => BoxDecoration(
    color: midnightPurple.withValues(alpha: 0.7), // More opacity for dramatic effect
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: warmGold.withValues(alpha: 0.4),
      width: 1,
    ), // Slightly more visible border
    boxShadow: [
      BoxShadow(
        color: cosmicBlack.withValues(alpha: 0.5),
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
        color: warmGold.withValues(alpha: 0.2),
        blurRadius: 15,
        spreadRadius: 0,
      ),
    ],
  );

  /// Updated glow effect for masks
  static BoxDecoration get glowDecoration => BoxDecoration(
    boxShadow: [
      BoxShadow(
        color: warmGold.withValues(alpha: 0.4), // Slightly stronger glow
        blurRadius: 20,
        spreadRadius: 0,
      ),
    ],
  );

  /// Alternative decorations (from features theme)
  static BoxDecoration get cardDecoration => BoxDecoration(
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

  static BoxDecoration get buttonDecoration => BoxDecoration(
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

  static BoxDecoration get inputDecoration => BoxDecoration(
    color: darkAccentColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: greyColor.withValues(alpha: 0.3), width: 1),
  );

  // ============================================================================
  // THEME DATA - Complete Flutter theme configuration
  // ============================================================================
  
  /// Complete theme data configuration
  static ThemeData get themeData => ThemeData(
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
      iconTheme: const IconThemeData(color: lightColor),
      titleTextStyle: headingStyle,
    ),
    iconTheme: const IconThemeData(color: lightColor, size: 24),
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

  // ============================================================================
  // ADDITIONAL THEME COMPONENTS
  // ============================================================================
  
  /// Bottom navigation theme - Updated with new colors
  static BottomNavigationBarThemeData get bottomNavTheme =>
      BottomNavigationBarThemeData(
        backgroundColor: cosmicBlack.withValues(alpha: 0.85), // Slightly more opaque
        selectedItemColor: warmGold,
        unselectedItemColor: silverMist.withValues(alpha: 0.5),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      );

  /// Divider styling
  static Divider get divider =>
      Divider(color: warmGold.withValues(alpha: 0.3), thickness: 1, height: 1);

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================
  
  /// Get appropriate text color based on background
  static Color getTextColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5 ? cosmicBlack : silverMist;
  }

  /// Get appropriate contrast color
  static Color getContrastColor(Color color) {
    return color.computeLuminance() > 0.5 ? cosmicBlack : lightColor;
  }

  /// Create a themed box shadow
  static List<BoxShadow> createShadow({
    Color? color,
    double blurRadius = 8.0,
    double spreadRadius = 0.0,
    Offset offset = const Offset(0, 4),
    double opacity = 0.3,
  }) {
    return [
      BoxShadow(
        color: (color ?? cosmicBlack).withValues(alpha: opacity),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: offset,
      ),
    ];
  }
}
