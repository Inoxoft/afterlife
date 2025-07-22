import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// A utility class for handling Ukrainian and Russian Cyrillic character rendering issues
class UkrainianFontUtils {
  // A set of Ukrainian and Russian Cyrillic characters for quick look-up
  static const String ukrainianCharacters =
      'АаБбВвГгҐґДдЕеЄєЖжЗзИиІіЇїЙйКкЛлМмНнОоПпРрСсТтУуФфХхЦцЧчШшЩщьЮюЯя';
  
  // Russian specific characters (some overlap with Ukrainian)
  static const String russianCharacters =
      'АаБбВвГгДдЕеЁёЖжЗзИиЙйКкЛлМмНнОоПпРрСсТтУуФфХхЦцЧчШшЩщЪъЫыЬьЭэЮюЯя';
  
  // Combined Cyrillic character set
  static const String cyrillicCharacters =
      'АаБбВвГгҐґДдЕеЁёЄєЖжЗзИиІіЇїЙйКкЛлМмНнОоПпРрСсТтУуФфХхЦцЧчШшЩщЪъЫыЬьЭэЮюЯя';

  /// Checks if a string contains any Ukrainian characters
  static bool hasUkrainianCharacters(String text) {
    for (int i = 0; i < text.length; i++) {
      if (ukrainianCharacters.contains(text[i])) {
        return true;
      }
    }
    return false;
  }

  /// Checks if a string contains any Russian characters
  static bool hasRussianCharacters(String text) {
    for (int i = 0; i < text.length; i++) {
      if (russianCharacters.contains(text[i])) {
        return true;
      }
    }
    return false;
  }

  /// Checks if a string contains any Cyrillic characters (Ukrainian or Russian)
  static bool hasCyrillicCharacters(String text) {
    for (int i = 0; i < text.length; i++) {
      if (cyrillicCharacters.contains(text[i])) {
        return true;
      }
    }
    return false;
  }

  /// Selects the appropriate font family based on character set
  static String _getFontFamilyForText(String text, String preferredFamily) {
    if (hasCyrillicCharacters(text)) {
      // Use mobile-specific fonts with better Cyrillic support
      if (kIsWeb) {
        return 'system-ui';
      }
      
      if (Platform.isAndroid) {
        return 'Noto Sans';  // Android's Noto fonts have excellent Cyrillic support
      } else if (Platform.isIOS) {
        return '.SF UI Text';  // iOS system font with good Unicode support
      }
      
      return 'system-ui';
    }
    return preferredFamily;
  }

  /// Debug function to check if text is being detected as Cyrillic
  static void debugCyrillicDetection(String text) {
    if (kDebugMode) {
      final isCyrillic = hasCyrillicCharacters(text);
      final isUkrainian = hasUkrainianCharacters(text);
      final isRussian = hasRussianCharacters(text);
      print(
        'Text: "$text" - Cyrillic: $isCyrillic, Ukrainian: $isUkrainian, Russian: $isRussian',
      );
    }
  }

  /// Legacy debug function for backwards compatibility
  static void debugUkrainianDetection(String text) {
    debugCyrillicDetection(text);
  }

  /// Returns a Lato TextStyle with Cyrillic font support if needed
  static TextStyle latoWithUkrainianSupport({
    required String text,
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    double? letterSpacing,
    List<Shadow>? shadows,
    double? height,
  }) {
    final fontFamily = _getFontFamilyForText(text, 'Lato');
    final fontFallbacks = hasCyrillicCharacters(text) ? getMobileFontFallbacks() : null;
    
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallbacks,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      decoration: decoration,
      letterSpacing: letterSpacing,
      shadows: shadows,
      height: height,
    ).merge(textStyle);
  }

  /// Returns a Cinzel TextStyle with Cyrillic font support if needed
  static TextStyle cinzelWithUkrainianSupport({
    required String text,
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    double? letterSpacing,
    List<Shadow>? shadows,
    double? height,
  }) {
    final fontFamily = _getFontFamilyForText(text, 'Cinzel');
    final fontFallbacks = hasCyrillicCharacters(text) ? getMobileSerifFontFallbacks() : null;
    
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallbacks,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      decoration: decoration,
      letterSpacing: letterSpacing,
      shadows: shadows,
      height: height,
    ).merge(textStyle);
  }

  /// A utility for getting a text style with proper Cyrillic font support
  static TextStyle getTextStyleWithUkrainianSupport({
    required String text,
    required TextStyle originalStyle,
    String defaultFontFamily = 'Lato',
  }) {
    final fontFamily = _getFontFamilyForText(
      text,
      originalStyle.fontFamily ?? defaultFontFamily,
    );
    return originalStyle.copyWith(fontFamily: fontFamily);
  }

  /// Get the best font family for Cyrillic text on mobile
  static String getMobileFontFamily() {
    if (kIsWeb) {
      return 'system-ui';
    }
    
    if (Platform.isAndroid) {
      return 'Noto Sans';  // Android's Noto fonts have excellent Cyrillic support
    } else if (Platform.isIOS) {
      return '.SF UI Text';  // iOS system font with good Unicode support
    }
    
    return 'system-ui';
  }

  static List<String> getMobileFontFallbacks() {
    if (kIsWeb) {
      return ['system-ui', 'Roboto', 'Helvetica Neue', 'Arial', 'sans-serif'];
    }
    
    if (Platform.isAndroid) {
      return [
        'Noto Sans',
        'Noto Sans UI', 
        'Roboto',
        'Droid Sans',
        'Arial Unicode MS',
        'system-ui',
        'sans-serif'
      ];
    } else if (Platform.isIOS) {
      return [
        '.SF UI Text',
        '.SF Pro Text',
        'SF Pro Display',
        'Helvetica Neue',
        'Arial Unicode MS',
        'system-ui',
        'sans-serif'
      ];
    }
    
    return ['system-ui', 'sans-serif'];
  }

  static List<String> getMobileSerifFontFallbacks() {
    if (kIsWeb) {
      return ['system-ui', 'Georgia', 'Times New Roman', 'serif'];
    }
    
    if (Platform.isAndroid) {
      return [
        'Noto Serif',
        'Noto Sans',  // Fallback to sans if serif not available
        'Droid Serif',
        'Times New Roman',
        'Georgia',
        'system-ui',
        'serif'
      ];
    } else if (Platform.isIOS) {
      return [
        '.SF UI Text',
        'New York',  // iOS serif font
        'Georgia',
        'Times New Roman',
        'system-ui',
        'serif'
      ];
    }
    
    return ['system-ui', 'serif'];
  }

  /// Creates a TextStyle with automatic Cyrillic font detection and fallback
  /// This method can be used globally throughout the app
  static TextStyle createGlobalTextStyle({
    String? text,
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextDecoration? decoration,
    double? letterSpacing,
    List<Shadow>? shadows,
    double? height,
    bool isSerif = false,
  }) {
    // Determine if we need Cyrillic font support
    final needsCyrillicSupport = text != null && hasCyrillicCharacters(text);
    
    List<String>? fallbacks;
    String? finalFontFamily = fontFamily;
    
    if (needsCyrillicSupport) {
      // Use system fonts that support Cyrillic
      finalFontFamily = getMobileFontFamily();
      fallbacks = isSerif ? getMobileSerifFontFallbacks() : getMobileFontFallbacks();
    } else {
      // For non-Cyrillic text, still provide fallbacks for safety
      fallbacks = isSerif ? getMobileSerifFontFallbacks() : getMobileFontFallbacks();
    }
    
    return TextStyle(
      fontFamily: finalFontFamily,
      fontFamilyFallback: fallbacks,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      decoration: decoration,
      letterSpacing: letterSpacing,
      shadows: shadows,
      height: height,
    );
  }

  /// Enhances an existing TextStyle with Cyrillic font support
  static TextStyle enhanceTextStyleForUkrainian(TextStyle original, {String? text}) {
    if (text != null && hasCyrillicCharacters(text)) {
      final fontFallbacks = getMobileFontFallbacks();
      return original.copyWith(
        fontFamily: getMobileFontFamily(),
        fontFamilyFallback: fontFallbacks,
      );
    }
    
    // Even for non-Cyrillic text, add fallbacks for better rendering
    final fontFallbacks = getMobileFontFallbacks();
    return original.copyWith(
      fontFamilyFallback: original.fontFamilyFallback ?? fontFallbacks,
    );
  }
} 