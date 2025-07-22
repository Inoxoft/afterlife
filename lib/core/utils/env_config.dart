import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A utility class for managing environment configuration
class EnvConfig {
  static bool _isInitialized = false;

  // Keys for SharedPreferences
  static const String _openRouterApiKeyPref = 'user_openrouter_api_key';

  /// Cache for the user API key to avoid sync/async issues
  static String? _cachedUserApiKey;

  /// Initialize environment configuration
  static Future<void> initialize() async {
    _isInitialized = false;

    try {
      // Get API key from SharedPreferences (user setting)
      final prefs = await SharedPreferences.getInstance();
      _cachedUserApiKey = prefs.getString(_openRouterApiKeyPref);

      _isInitialized = true;
      if (kDebugMode) {
        print('EnvConfig initialized.');
        dumpApiKeyInfo();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing EnvConfig: $e');
      }
      _isInitialized = true; // Mark as initialized to prevent repeated attempts
    }
  }

  /// Get an environment variable value
  static String? get(String key) {
    if (!_isInitialized) {
      if (kDebugMode) {
        print('Warning: EnvConfig.get called before initialization.');
      }
    }

    if (key == 'OPENROUTER_API_KEY') {
      return _cachedUserApiKey;
    }

    // Return null for any other key as we are no longer using a .env file
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
      final prefs = await SharedPreferences.getInstance();

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
        print('Error saving API key: $e');
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
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString(_openRouterApiKeyPref);
      return key != null && key.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Force a reload of the configuration from SharedPreferences
  static Future<void> forceReload() async {
    if (kDebugMode) {
      print('Forcing EnvConfig reload...');
    }
    await initialize();
  }

  /// Dump diagnostic information about the API key source
  static Future<void> dumpApiKeyInfo() async {
    if (kDebugMode) {
      print('--- API Key Diagnostics ---');
      print(
        'Cached User Key: ${_cachedUserApiKey != null ? (_cachedUserApiKey!.isEmpty ? "EMPTY" : "${_cachedUserApiKey!.substring(0, min(4, _cachedUserApiKey!.length))}...") : "NULL"}',
      );
      final hasKey = await hasUserApiKey();
      print('Has user API key in SharedPreferences: $hasKey');
      print('--------------------------');
    }
  }

  static int min(int a, int b) => a < b ? a : b;
}
