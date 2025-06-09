import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Utility class for handling Ukrainian font rendering across the entire app
class UkrainianFontUtils {
  /// Enhanced list of Ukrainian characters and common Ukrainian words
  static bool hasUkrainianCharacters(String text) {
    // Ukrainian-specific characters
    const ukrainianChars = [
      'а', 'б', 'в', 'г', 'ґ', 'д', 'е', 'є', 'ж', 'з', 'и', 'і', 'ї', 'й', 'к', 'л', 'м', 'н', 'о', 'п', 'р', 'с', 'т', 'у', 'ф', 'х', 'ц', 'ч', 'ш', 'щ', 'ь', 'ю', 'я',
      'А', 'Б', 'В', 'Г', 'Ґ', 'Д', 'Е', 'Є', 'Ж', 'З', 'И', 'І', 'Ї', 'Й', 'К', 'Л', 'М', 'Н', 'О', 'П', 'Р', 'С', 'Т', 'У', 'Ф', 'Х', 'Ц', 'Ч', 'Ш', 'Щ', 'Ь', 'Ю', 'Я'
    ];
    
    // Common Ukrainian words
    const ukrainianWords = [
      'дослідити', 'двійники', 'створити', 'налаштування',
      'Дослідити', 'Двійники', 'Створити', 'Налаштування',
      'мова', 'бажану', 'додатку', 'сповіщення', 'зберегти',
      'українська', 'ДОСЛІДИТИ', 'ДВІЙНИКІВ', 'ЦИФРОВИХ',
      'афтерлайф', 'безкоштовно', 'персонажа'
    ];
    
    // Check for Ukrainian characters
    for (String char in ukrainianChars) {
      if (text.contains(char)) return true;
    }
    
    // Check for Ukrainian words
    for (String word in ukrainianWords) {
      if (text.contains(word)) return true;
    }
    
    return false;
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

  /// Gets Lato text style with Ukrainian character support
  static TextStyle latoWithUkrainianSupport({
    required String text,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    List<Shadow>? shadows,
    TextDecoration? decoration,
    double? height,
  }) {
    if (hasUkrainianCharacters(text)) {
      return TextStyle(
        fontFamily: _getMobileFontFamily(),
        fontFamilyFallback: _getMobileFontFallbacks(),
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        shadows: shadows,
        decoration: decoration,
        height: height,
      );
    }
    
    return GoogleFonts.lato(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      shadows: shadows,
      decoration: decoration,
      height: height,
    );
  }

  /// Gets Cinzel text style with Ukrainian character support
  static TextStyle cinzelWithUkrainianSupport({
    required String text,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    List<Shadow>? shadows,
    double? height,
    TextDecoration? decoration,
  }) {
    if (hasUkrainianCharacters(text)) {
      // Always use system default font for Ukrainian text to ensure proper rendering
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        shadows: shadows,
        height: height,
        decoration: decoration,
      );
    } else {
      return GoogleFonts.cinzel(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        shadows: shadows,
        height: height,
        decoration: decoration,
      );
    }
  }

  /// Generic text style with Ukrainian support for any Google Font
  static TextStyle getTextStyleWithUkrainianSupport({
    required String text,
    required TextStyle Function() googleFontStyle,
    String? fallbackFontFamily,
    List<String>? customFallbacks,
  }) {
    if (hasUkrainianCharacters(text)) {
      final originalStyle = googleFontStyle();
      return TextStyle(
        fontFamily: fallbackFontFamily ?? 'system',
        fontFamilyFallback: customFallbacks ?? ['Roboto', 'Noto Sans', 'Arial', 'sans-serif'],
        fontSize: originalStyle.fontSize,
        fontWeight: originalStyle.fontWeight,
        color: originalStyle.color,
        letterSpacing: originalStyle.letterSpacing,
        shadows: originalStyle.shadows,
        height: originalStyle.height,
        decoration: originalStyle.decoration,
        decorationColor: originalStyle.decorationColor,
        decorationStyle: originalStyle.decorationStyle,
        decorationThickness: originalStyle.decorationThickness,
      );
    } else {
      return googleFontStyle();
    }
  }

  // Debug method to test Ukrainian character detection
  static void debugUkrainianDetection(String text) {
  }
} 