// import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/preferences_service.dart';
import '../services/base_service.dart';
import 'app_logger.dart';

/// A utility class for managing environment configuration
class EnvConfig {
  static bool _isInitialized = false;

  // Keys for SharedPreferences
  static const String _openRouterApiKeyPref = 'user_openrouter_api_key';

  /// Cache for the user API key to avoid sync/async issues
  static String? _cachedUserApiKey;
  static String? _cachedHuggingFaceToken;

  /// Initialize environment configuration
  static Future<void> initialize() async {
    await StaticServiceInitializer.initializeService(
      serviceName: 'EnvConfig',
      isInitialized: () => _isInitialized,
      markInitialized: () => _isInitialized = true,
      dependencies: [
        () => PreferencesService.initialize(),
      ],
      initializeLogic: () async {
        // Load .env file (if present)
        try {
          await dotenv.load(fileName: '.env', isOptional: true);
        } catch (e) {
          if (kDebugMode) {
            AppLogger.warning('Failed to load .env file (optional): $e', tag: 'EnvConfig');
          }
        }

        // Get API key from SharedPreferences (user setting)
        final prefs = await PreferencesService.getPrefs();
        _cachedUserApiKey = prefs.getString(_openRouterApiKeyPref);

        // Read HF token from .env
        _cachedHuggingFaceToken = dotenv.maybeGet('HUGGINGFACE_TOKEN');

        if (kDebugMode) {
          dumpApiKeyInfo();
        }
      },
    );
  }

  /// Get an environment variable value
  static String? get(String key) {
    if (!_isInitialized) {
      if (kDebugMode) {
        AppLogger.warning('EnvConfig.get called before initialization', tag: 'EnvConfig');
      }
    }

    if (key == 'OPENROUTER_API_KEY') {
      return _cachedUserApiKey;
    }
    if (key == 'HUGGINGFACE_TOKEN') {
      return _cachedHuggingFaceToken;
    }

    // Return null for any other key if not found
    return null;
  }

  /// Check if a key exists and has a non-empty value
  static bool hasValue(String key) {
    final value = get(key);
    return value != null && value.isNotEmpty;
  }

  /// Set an API key that overrides the one in the .env file
  static Future<bool> setUserApiKey(String apiKey) async {
    try {
      final prefs = await PreferencesService.getPrefs();

      if (apiKey.isEmpty) {
        await prefs.remove(_openRouterApiKeyPref);
        _cachedUserApiKey = null;
      } else {
        await prefs.setString(_openRouterApiKeyPref, apiKey);
        _cachedUserApiKey = apiKey;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('Error saving API key', tag: 'EnvConfig', error: e);
      }
      return false;
    }
  }

  /// Remove the user-specified API key
  static Future<bool> removeUserApiKey() async {
    return await setUserApiKey('');
  }

  /// Check if the user has set a custom API key
  static Future<bool> hasUserApiKey() async {
    try {
      final prefs = await PreferencesService.getPrefs();
      final key = prefs.getString(_openRouterApiKeyPref);
      return key != null && key.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Force a reload of the configuration from SharedPreferences
  static Future<void> forceReload() async {
    if (kDebugMode) {
      AppLogger.debug('Forcing EnvConfig reload', tag: 'EnvConfig');
    }
    await initialize();
  }

  /// Dump diagnostic information about the API key source
  static Future<void> dumpApiKeyInfo() async {
    if (kDebugMode) {
      AppLogger.debug('--- API Key Diagnostics ---', tag: 'EnvConfig');
      final keyDisplay = _cachedUserApiKey != null 
          ? (_cachedUserApiKey!.isEmpty ? "EMPTY" : "${_cachedUserApiKey!.substring(0, 4)}...")
          : "NULL";
      AppLogger.debug('Cached User Key: $keyDisplay', tag: 'EnvConfig');
      final hfDisplay = _cachedHuggingFaceToken != null 
          ? (_cachedHuggingFaceToken!.isEmpty ? "EMPTY" : "${_cachedHuggingFaceToken!.substring(0, 4)}...")
          : "NULL";
      AppLogger.debug('HF Token from .env: $hfDisplay', tag: 'EnvConfig');
      final hasKey = await hasUserApiKey();
      AppLogger.debug('Has user API key in SharedPreferences: $hasKey', tag: 'EnvConfig');
      AppLogger.debug('--------------------------', tag: 'EnvConfig');
    }
  }

  static int min(int a, int b) => a < b ? a : b;
}
