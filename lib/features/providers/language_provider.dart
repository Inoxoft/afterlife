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
      case 'ja':
        return 'Japanese';
      case 'ko':
        return 'Korean';
      case 'zh':
        return 'Chinese';
      case 'pt':
        return 'Portuguese';
      case 'ru':
        return 'Russian';
      case 'ar':
        return 'Arabic';
      case 'hi':
        return 'Hindi';
      case 'it':
        return 'Italian';
      case 'uk':
        return 'Ukrainian';
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
      print('Error loading saved language: $e');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      _currentLocale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      print('Error saving language: $e');
    }
  }

  static List<Locale> get supportedLocales => const [
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('de'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale('pt'),
    Locale('ru'),
    Locale('ar'),
    Locale('hi'),
    Locale('it'),
    Locale('uk'),
  ];

  static List<String> get supportedLanguageCodes => 
    supportedLocales.map((locale) => locale.languageCode).toList();
} 