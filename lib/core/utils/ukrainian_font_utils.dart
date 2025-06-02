import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Utility class for handling Ukrainian font rendering across the entire app
class UkrainianFontUtils {
  /// Checks if text contains Ukrainian characters that need special font handling
  static bool hasUkrainianCharacters(String text) {
    return text.contains('і') || 
           text.contains('ї') || 
           text.contains('Ї') || 
           text.contains('І') ||
           text.contains('українська') || 
           text.contains('Українська') ||
           text.contains('відповідей') ||
           text.contains('налаштування') ||
           text.contains('Налаштування') ||
           text.contains('повідомлення') ||
           text.contains('Повідомлення') ||
           // Add more common Ukrainian words that contain these characters
           text.contains('Виберіть') ||
           text.contains('виберіть') ||
           text.contains('бажану') ||
           text.contains('мову') ||
           text.contains('додатку') ||
           text.contains('підтримку') ||
           text.contains('налаштувати') ||
           text.contains('сповіщення') ||
           text.contains('історію') ||
           text.contains('розмови') ||
           text.contains('двійники') ||
           text.contains('персонажі');
  }

  /// Gets Lato text style with Ukrainian character support
  static TextStyle latoWithUkrainianSupport({
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
      return TextStyle(
        fontFamily: 'system',
        fontFamilyFallback: const ['Roboto', 'Noto Sans', 'Arial', 'sans-serif'],
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        shadows: shadows,
        height: height,
        decoration: decoration,
      );
    } else {
      return GoogleFonts.lato(
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
      return TextStyle(
        fontFamily: 'system',
        fontFamilyFallback: const ['Roboto', 'Noto Sans', 'Arial', 'serif'],
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
} 