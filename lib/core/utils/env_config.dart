import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A utility class for managing environment configuration
class EnvConfig {
  static bool _isInitialized = false;
  static final Map<String, String> _envVars = {};
  static final Map<String, String> _defaultEnvVars = {}; // Store default keys separately

  // Keys for SharedPreferences
  static const String _openRouterApiKeyPref = 'user_openrouter_api_key';

  /// Initialize environment configuration
  static Future<void> initialize() async {
    // Clear existing variables to ensure we get fresh data
    _envVars.clear();
    _defaultEnvVars.clear(); // Clear default vars too
    _isInitialized = false;

    try {

      // First try to get API key from SharedPreferences (user setting)
      final prefs = await SharedPreferences.getInstance();
      final userApiKey = prefs.getString(_openRouterApiKeyPref);

      // Always load from .env file for default values
      await _loadFromDotEnv();

      // If user has set a key, it takes precedence
      if (userApiKey != null && userApiKey.isNotEmpty) {
        _envVars['OPENROUTER_API_KEY'] = userApiKey;
        _cachedUserApiKey = userApiKey;
      }

      _isInitialized = true;
      _logLoadedVars();
    } catch (e) {
      _isInitialized = true; // Mark as initialized to prevent repeated attempts
    }
  }

  // Load from .env file using dotenv
  static Future<void> _loadFromDotEnv() async {
    // Try to load using dotenv first
    bool dotenvLoaded = false;
    try {
      // Force reload by setting filename explicitly
      await dotenv.load(fileName: '.env');
      dotenvLoaded = true;
    } catch (e) {
      // Create a default empty .env file if it doesn't exist
      try {
        final file = File('.env');
        if (!await file.exists()) {
          await file.writeAsString('''
# Afterlife API Configuration
# Replace with your actual API key from https://openrouter.ai
# OPENROUTER_API_KEY=your_api_key_here
''');
          
          // Try to load the newly created file
          await dotenv.load(fileName: '.env');
          dotenvLoaded = true;
        }
      } catch (err) {
      }
    }

    // If dotenv loaded successfully, copy values to our default map
    if (dotenvLoaded) {
      dotenv.env.forEach((key, value) {
        _defaultEnvVars[key] = value;
      });
    }

    // If we don't have any env vars yet, try manual file loading
    if (_defaultEnvVars.isEmpty) {
      await _loadEnvManually();
    }
  }

  /// Get an environment variable value
  static String? get(String key) {
    if (!_isInitialized) {
    }

    // Special case for API key - always check SharedPreferences first
    if (key == 'OPENROUTER_API_KEY') {
      try {
        // This is synchronous but we're in a sync method, so we use a different approach
        final cachedUserKey = _getCachedUserApiKey();
        if (cachedUserKey != null) {
          return cachedUserKey;
        }
      } catch (e) {
      }
    }

    // First check user vars, then fall back to default vars
    return _envVars[key] ?? _defaultEnvVars[key];
  }

  /// Get only the default environment variable (not user-overridden)
  static String? getDefaultValue(String key) {
    if (!_isInitialized) {
    }
    return _defaultEnvVars[key];
  }

  /// Check if a key exists and has a non-empty value
  static bool hasValue(String key) {
    final value = get(key);
    return value != null && value.isNotEmpty;
  }

  /// Cache for the user API key to avoid sync/async issues
  static String? _cachedUserApiKey;

  // Get cached user API key (sync version)
  static String? _getCachedUserApiKey() {
    return _cachedUserApiKey;
  }

  /// Set an API key that overrides the one in the .env file
  static Future<bool> setUserApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Empty string means remove it
      if (apiKey.isEmpty) {
        await prefs.remove(_openRouterApiKeyPref);
        _cachedUserApiKey = null;
      } else {
        await prefs.setString(_openRouterApiKeyPref, apiKey);
        _cachedUserApiKey = apiKey;
      }

      // Update our in-memory map
      if (apiKey.isEmpty) {
        _envVars.remove('OPENROUTER_API_KEY');
      } else {
        _envVars['OPENROUTER_API_KEY'] = apiKey;
      }

      return true;
    } catch (e) {
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

  /// Create a .env file with sample values if it doesn't exist
  static Future<void> createSampleEnvFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/.env');

      if (!file.existsSync()) {
        await file.writeAsString('''
# Afterlife API Configuration
# Replace with your actual API key from https://openrouter.ai
OPENROUTER_API_KEY=your_api_key_here
''');
      }
    } catch (e) {
    }
  }

  /// Load environment variables manually from assets or file system
  static Future<void> _loadEnvManually() async {

    // Try to load from assets bundle
    try {
      final envString = await rootBundle.loadString('.env');
      _parseEnvString(envString, isDefault: true);
      return;
    } catch (e) {
      
      // Create a default .env in assets directory if possible
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final assetDir = Directory('${appDir.path}/assets');
        if (!await assetDir.exists()) {
          await assetDir.create(recursive: true);
        }
        
        final envFile = File('${assetDir.path}/.env');
        if (!await envFile.exists()) {
          await envFile.writeAsString('''
# Afterlife API Configuration
# Replace with your actual API key from https://openrouter.ai
# OPENROUTER_API_KEY=your_api_key_here
''');
        }
      } catch (err) {
      }
    }

    // Try to load from app documents directory
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/.env');

      if (file.existsSync()) {
        final envString = await file.readAsString();
        _parseEnvString(envString, isDefault: true);
        return;
      }
    } catch (e) {
    }

    await createSampleEnvFile();
  }

  /// Parse environment variables from a string
  static void _parseEnvString(String envString, {bool isDefault = false}) {
    final envLines = envString.split('\n');
    
    final targetMap = isDefault ? _defaultEnvVars : _envVars;

    for (final line in envLines) {
      // Skip comments and empty lines
      if (line.trim().startsWith('#') || line.trim().isEmpty) continue;

      // Parse key=value format
      final parts = line.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join('=').trim();
        targetMap[key] = value;
      }
    }
  }

  /// Log loaded environment variables (with obfuscation for sensitive data)
  static void _logLoadedVars() {
    _envVars.forEach((key, value) {
      if (key.toLowerCase().contains('key') ||
          key.toLowerCase().contains('secret') ||
          key.toLowerCase().contains('password')) {
        // Mask sensitive values
        final masked =
            value.length > 8
                ? '${value.substring(0, 4)}...${value.substring(value.length - 4)}'
                : '****';
      } else {
        if (kDebugMode) {
        }
      }
    });
    
    _defaultEnvVars.forEach((key, value) {
      if (key.toLowerCase().contains('key') ||
          key.toLowerCase().contains('secret') ||
          key.toLowerCase().contains('password')) {
        // Mask sensitive values
        final masked =
            value.length > 8
                ? '${value.substring(0, 4)}...${value.substring(value.length - 4)}'
                : '****';
      } else {
        if (kDebugMode) {
        }
      }
    });
  }

  /// Force a fresh reload of environment variables, bypassing all caches
  static Future<void> forceReload() async {

    // Clear our internal cache
    _envVars.clear();
    _defaultEnvVars.clear();
    _isInitialized = false;

    // Clear dotenv cache if possible
    try {
      dotenv.env.clear();
    } catch (e) {
    }

    // Reload completely
    await initialize();

  }

  /// Dump diagnostic information about the API key source
  static Future<void> dumpApiKeyInfo() async {
    final currentKey = get('OPENROUTER_API_KEY');
    final defaultKey = getDefaultValue('OPENROUTER_API_KEY');
    final hasUserKey = await hasUserApiKey();

    if (kDebugMode) {
      print(
        'Current Key from get(): ${currentKey != null ? (currentKey.isEmpty ? "EMPTY" : "${currentKey.substring(0, min(4, currentKey.length))}...") : "NULL"}',
      );
      print(
        'Default Key from .env: ${defaultKey != null ? (defaultKey.isEmpty ? "EMPTY" : "${defaultKey.substring(0, min(4, defaultKey.length))}...") : "NULL"}',
      );
      print(
        'Cached User Key: ${_cachedUserApiKey != null ? ((_cachedUserApiKey!.isEmpty) ? "EMPTY" : "${_cachedUserApiKey!.substring(0, min(4, _cachedUserApiKey!.length))}...") : "NULL"}',
      );
      print(
        'In-Memory User Key: ${_envVars['OPENROUTER_API_KEY'] != null ? (_envVars['OPENROUTER_API_KEY']!.isEmpty ? "EMPTY" : "${_envVars['OPENROUTER_API_KEY']!.substring(0, min(4, _envVars['OPENROUTER_API_KEY']!.length))}...") : "NULL"}',
      );
    }
  }

  static int min(int a, int b) => a < b ? a : b;
}
