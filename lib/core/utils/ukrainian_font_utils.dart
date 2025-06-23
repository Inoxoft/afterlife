import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// A utility class for handling Ukrainian character rendering issues
class UkrainianFontUtils {
  // A set of Ukrainian characters for quick look-up
  static const String ukrainianCharacters =
      'АаБбВвГгҐґДдЕеЄєЖжЗзИиІіЇїЙйКкЛлМмНнОоПпРрСсТтУуФфХхЦцЧчШшЩщьЮюЯя';

  /// Checks if a string contains any Ukrainian characters
  static bool hasUkrainianCharacters(String text) {
    for (int i = 0; i < text.length; i++) {
      if (ukrainianCharacters.contains(text[i])) {
        return true;
      }
    }
    return false;
  }

  /// Selects the appropriate font family based on character set
  static String _getFontFamilyForText(String text, String preferredFamily) {
    return hasUkrainianCharacters(text) ? 'Roboto' : preferredFamily;
  }

  /// Debug function to check if text is being detected as Ukrainian
  static void debugUkrainianDetection(String text) {
    if (kDebugMode) {
      final isUkrainian = hasUkrainianCharacters(text);
      print(
        'Text: "$text" - Ukrainian detected: $isUkrainian',
      );
    }
  }

  /// Returns a Lato TextStyle with Ukrainian font support if needed
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
    return TextStyle(
      fontFamily: _getFontFamilyForText(text, 'Lato'),
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      decoration: decoration,
      letterSpacing: letterSpacing,
      shadows: shadows,
      height: height,
    ).merge(textStyle);
  }

  /// Returns a Cinzel TextStyle with Ukrainian font support if needed
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
    return TextStyle(
      fontFamily: _getFontFamilyForText(text, 'Cinzel'),
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      decoration: decoration,
      letterSpacing: letterSpacing,
      shadows: shadows,
      height: height,
    ).merge(textStyle);
  }

  /// A utility for getting a text style with proper Ukrainian font support
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

  /// Get the best font family for Ukrainian text on mobile
  static String _getMobileFontFamily() {
    if (kIsWeb) {
      return 'system-ui';
    }
    
    if (Platform.isAndroid) {
      return 'Noto Sans';  // Android's Noto fonts have excellent Ukrainian support
    } else if (Platform.isIOS) {
      return '.SF UI Text';  // iOS system font with good Unicode support
    }
    
    return 'system-ui';
  }

  static List<String> _getMobileFontFallbacks() {
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

  static List<String> _getMobileSerifFontFallbacks() {
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
} 