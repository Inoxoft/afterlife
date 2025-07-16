import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  static const String _languageKey = 'user_language';
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  String get currentLanguageCode => _currentLocale.languageCode;

  String get currentLanguageName {
    switch (_currentLocale.languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      case 'it':
        return 'Italian';
      case 'ja':
        return 'Japanese';
      case 'ko':
        return 'Korean';
      case 'uk':
        return 'Ukrainian';
      case 'ru':
        return 'Russian';
      default:
        return 'English';
    }
  }

  Future<void> initializeLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_languageKey);
      if (savedLanguageCode != null) {
        _currentLocale = Locale(savedLanguageCode);
        notifyListeners();
      }
    } catch (e) {
    }
  }

  Future<void> setLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Ensure proper UTF-8 encoding for Cyrillic languages (Ukrainian and Russian)
      if (languageCode == 'uk' || languageCode == 'ru') {
        // Use explicit UTF-8 encoding for Cyrillic languages
        final encodedCode = utf8.encode(languageCode);
        final decodedCode = utf8.decode(encodedCode);
        await prefs.setString(_languageKey, decodedCode);
      } else {
        await prefs.setString(_languageKey, languageCode);
      }
      
      _currentLocale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
    }
  }

  static List<Locale> get supportedLocales => const [
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('uk'),
    Locale('ru'),
  ];

  static List<String> get supportedLanguageCodes => 
    supportedLocales.map((locale) => locale.languageCode).toList();
} 