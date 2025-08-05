import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';
import 'base_service.dart';

/// Singleton service for SharedPreferences management
/// Eliminates repeated getInstance() calls and provides a centralized preference management system
class PreferencesService {
  static PreferencesService? _instance;
  static SharedPreferences? _prefsCache;
  static bool _isInitialized = false;

  /// Private constructor for singleton pattern
  PreferencesService._();

  /// Get the singleton instance
  static PreferencesService get instance => _instance ??= PreferencesService._();

  /// Initialize the service - should be called once at app startup
  static Future<void> initialize() async {
    await StaticServiceInitializer.initializeService(
      serviceName: 'PreferencesService',
      isInitialized: () => _isInitialized,
      markInitialized: () => _isInitialized = true,
      initializeLogic: () async {
        _prefsCache = await SharedPreferences.getInstance();
      },
    );
  }

  /// Get SharedPreferences instance (cached)
  /// This is the main method that replaces all SharedPreferences.getInstance() calls
  static Future<SharedPreferences> getPrefs() async {
    if (_prefsCache != null) {
      return _prefsCache!;
    }

    // If not initialized yet, initialize now
    if (!_isInitialized) {
      await initialize();
    }

    // If still null after initialization, create a new instance
    if (_prefsCache == null) {
      AppLogger.warning('Creating new SharedPreferences instance after failed initialization');
      _prefsCache = await SharedPreferences.getInstance();
    }

    return _prefsCache!;
  }

  /// Synchronous access to cached preferences (only use if you're sure it's initialized)
  static SharedPreferences? get prefsSync => _prefsCache;

  /// Check if service is initialized and ready to use
  static bool get isReady => _isInitialized && _prefsCache != null;

  // ============================================================================
  // CONVENIENCE METHODS - Common preference operations
  // ============================================================================

  /// Get a string value
  static Future<String?> getString(String key) async {
    final prefs = await getPrefs();
    return prefs.getString(key);
  }

  /// Set a string value
  static Future<bool> setString(String key, String value) async {
    try {
      final prefs = await getPrefs();
      final result = await prefs.setString(key, value);
      AppLogger.debug('Set preference: $key = $value', tag: 'PreferencesService');
      return result;
    } catch (e) {
      AppLogger.error('Failed to set string preference: $key', error: e, tag: 'PreferencesService');
      return false;
    }
  }

  /// Get a boolean value
  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await getPrefs();
    return prefs.getBool(key) ?? defaultValue;
  }

  /// Set a boolean value
  static Future<bool> setBool(String key, bool value) async {
    try {
      final prefs = await getPrefs();
      final result = await prefs.setBool(key, value);
      AppLogger.debug('Set preference: $key = $value', tag: 'PreferencesService');
      return result;
    } catch (e) {
      AppLogger.error('Failed to set bool preference: $key', error: e, tag: 'PreferencesService');
      return false;
    }
  }

  /// Get an integer value
  static Future<int> getInt(String key, {int defaultValue = 0}) async {
    final prefs = await getPrefs();
    return prefs.getInt(key) ?? defaultValue;
  }

  /// Set an integer value
  static Future<bool> setInt(String key, int value) async {
    try {
      final prefs = await getPrefs();
      final result = await prefs.setInt(key, value);
      AppLogger.debug('Set preference: $key = $value', tag: 'PreferencesService');
      return result;
    } catch (e) {
      AppLogger.error('Failed to set int preference: $key', error: e, tag: 'PreferencesService');
      return false;
    }
  }

  /// Get a double value
  static Future<double> getDouble(String key, {double defaultValue = 0.0}) async {
    final prefs = await getPrefs();
    return prefs.getDouble(key) ?? defaultValue;
  }

  /// Set a double value
  static Future<bool> setDouble(String key, double value) async {
    try {
      final prefs = await getPrefs();
      final result = await prefs.setDouble(key, value);
      AppLogger.debug('Set preference: $key = $value', tag: 'PreferencesService');
      return result;
    } catch (e) {
      AppLogger.error('Failed to set double preference: $key', error: e, tag: 'PreferencesService');
      return false;
    }
  }

  /// Get a string list value
  static Future<List<String>?> getStringList(String key) async {
    final prefs = await getPrefs();
    return prefs.getStringList(key);
  }

  /// Set a string list value
  static Future<bool> setStringList(String key, List<String> value) async {
    try {
      final prefs = await getPrefs();
      final result = await prefs.setStringList(key, value);
      AppLogger.debug('Set preference: $key = ${value.length} items', tag: 'PreferencesService');
      return result;
    } catch (e) {
      AppLogger.error('Failed to set string list preference: $key', error: e, tag: 'PreferencesService');
      return false;
    }
  }

  /// Remove a preference key
  static Future<bool> remove(String key) async {
    try {
      final prefs = await getPrefs();
      final result = await prefs.remove(key);
      AppLogger.debug('Removed preference: $key', tag: 'PreferencesService');
      return result;
    } catch (e) {
      AppLogger.error('Failed to remove preference: $key', error: e, tag: 'PreferencesService');
      return false;
    }
  }

  /// Clear all preferences
  static Future<bool> clear() async {
    try {
      final prefs = await getPrefs();
      final result = await prefs.clear();
      AppLogger.warning('Cleared all preferences', tag: 'PreferencesService');
      return result;
    } catch (e) {
      AppLogger.error('Failed to clear preferences', error: e, tag: 'PreferencesService');
      return false;
    }
  }

  /// Check if a key exists
  static Future<bool> containsKey(String key) async {
    final prefs = await getPrefs();
    return prefs.containsKey(key);
  }

  /// Get all keys
  static Future<Set<String>> getAllKeys() async {
    final prefs = await getPrefs();
    return prefs.getKeys();
  }

  /// Reload preferences from storage
  static Future<void> reload() async {
    try {
      final prefs = await getPrefs();
      await prefs.reload();
      AppLogger.debug('Reloaded preferences from storage', tag: 'PreferencesService');
    } catch (e) {
      AppLogger.error('Failed to reload preferences', error: e, tag: 'PreferencesService');
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get preference with type safety and default value
  static Future<T> getPreference<T>(String key, T defaultValue) async {
    final prefs = await getPrefs();
    
    if (T == String) {
      return (prefs.getString(key) ?? defaultValue) as T;
    } else if (T == bool) {
      return (prefs.getBool(key) ?? defaultValue) as T;
    } else if (T == int) {
      return (prefs.getInt(key) ?? defaultValue) as T;
    } else if (T == double) {
      return (prefs.getDouble(key) ?? defaultValue) as T;
    } else {
      AppLogger.warning('Unsupported preference type: $T', tag: 'PreferencesService');
      return defaultValue;
    }
  }

  /// Set preference with type safety
  static Future<bool> setPreference<T>(String key, T value) async {
    try {
      final prefs = await getPrefs();
      
      if (T == String) {
        return await prefs.setString(key, value as String);
      } else if (T == bool) {
        return await prefs.setBool(key, value as bool);
      } else if (T == int) {
        return await prefs.setInt(key, value as int);
      } else if (T == double) {
        return await prefs.setDouble(key, value as double);
      } else {
        AppLogger.warning('Unsupported preference type: $T', tag: 'PreferencesService');
        return false;
      }
    } catch (e) {
      AppLogger.error('Failed to set preference: $key', error: e, tag: 'PreferencesService');
      return false;
    }
  }

  /// Debug method to log all preferences (use with caution)
  static Future<void> debugLogAllPreferences() async {
    if (!kDebugMode) return;
    
    try {
      final prefs = await getPrefs();
      final keys = prefs.getKeys();
      
      AppLogger.debug('=== All Preferences ===', tag: 'PreferencesService');
      for (final key in keys) {
        final value = prefs.get(key);
        // Don't log sensitive data like API keys
        if (key.toLowerCase().contains('key') || key.toLowerCase().contains('token')) {
          AppLogger.debug('$key: [REDACTED]', tag: 'PreferencesService');
        } else {
          AppLogger.debug('$key: $value', tag: 'PreferencesService');
        }
      }
      AppLogger.debug('========================', tag: 'PreferencesService');
    } catch (e) {
      AppLogger.error('Failed to debug log preferences', error: e, tag: 'PreferencesService');
    }
  }

  /// Reset the service (for testing purposes)
  static void reset() {
    _instance = null;
    _prefsCache = null;
    _isInitialized = false;
  }
} 