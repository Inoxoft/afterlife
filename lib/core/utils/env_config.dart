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
      print('Initializing environment configuration...');

      // First try to get API key from SharedPreferences (user setting)
      final prefs = await SharedPreferences.getInstance();
      final userApiKey = prefs.getString(_openRouterApiKeyPref);

      // Always load from .env file for default values
      await _loadFromDotEnv();

      // If user has set a key, it takes precedence
      if (userApiKey != null && userApiKey.isNotEmpty) {
        _envVars['OPENROUTER_API_KEY'] = userApiKey;
        _cachedUserApiKey = userApiKey;
        print('Using API key from user preferences - overriding default');
      }

      _isInitialized = true;
      _logLoadedVars();
    } catch (e) {
      print('Error initializing environment: $e');
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
      print('Dotenv loaded successfully');
    } catch (e) {
      print('Error loading .env using dotenv: $e');
      // Create a default empty .env file if it doesn't exist
      try {
        final file = File('.env');
        if (!await file.exists()) {
          await file.writeAsString('''
# Afterlife API Configuration
# Replace with your actual API key from https://openrouter.ai
# OPENROUTER_API_KEY=your_api_key_here
''');
          print('Created default empty .env file');
          
          // Try to load the newly created file
          await dotenv.load(fileName: '.env');
          dotenvLoaded = true;
          print('Loaded newly created .env file');
        }
      } catch (err) {
        print('Failed to create default .env file: $err');
      }
    }

    // If dotenv loaded successfully, copy values to our default map
    if (dotenvLoaded) {
      dotenv.env.forEach((key, value) {
        _defaultEnvVars[key] = value;
      });
      print('Copied ${dotenv.env.length} variables from dotenv to defaults');
    }

    // If we don't have any env vars yet, try manual file loading
    if (_defaultEnvVars.isEmpty) {
      await _loadEnvManually();
    }
  }

  /// Get an environment variable value
  static String? get(String key) {
    if (!_isInitialized) {
      print('Warning: EnvConfig not initialized before access');
    }

    // Special case for API key - always check SharedPreferences first
    if (key == 'OPENROUTER_API_KEY') {
      try {
        // This is synchronous but we're in a sync method, so we use a different approach
        final cachedUserKey = _getCachedUserApiKey();
        if (cachedUserKey != null) {
          print('Returning user-specified API key from memory cache');
          return cachedUserKey;
        }
      } catch (e) {
        print('Error checking for cached user API key: $e');
      }
    }

    // First check user vars, then fall back to default vars
    return _envVars[key] ?? _defaultEnvVars[key];
  }

  /// Get only the default environment variable (not user-overridden)
  static String? getDefaultValue(String key) {
    if (!_isInitialized) {
      print('Warning: EnvConfig not initialized before access');
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
        print('Removed user API key from preferences');
      } else {
        await prefs.setString(_openRouterApiKeyPref, apiKey);
        _cachedUserApiKey = apiKey;
        print('Saved user API key to preferences');
      }

      // Update our in-memory map
      if (apiKey.isEmpty) {
        _envVars.remove('OPENROUTER_API_KEY');
      } else {
        _envVars['OPENROUTER_API_KEY'] = apiKey;
      }

      return true;
    } catch (e) {
      print('Error saving user API key: $e');
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
      print('Error checking for user API key: $e');
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
        print('Created sample .env file at ${file.path}');
      }
    } catch (e) {
      print('Error creating sample .env file: $e');
    }
  }

  /// Load environment variables manually from assets or file system
  static Future<void> _loadEnvManually() async {
    print('Trying to load environment variables manually');

    // Try to load from assets bundle
    try {
      final envString = await rootBundle.loadString('.env');
      _parseEnvString(envString, isDefault: true);
      print('Loaded .env from assets');
      return;
    } catch (e) {
      print('Could not load .env from assets: $e');
      
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
          print('Created default .env in assets directory');
        }
      } catch (err) {
        print('Could not create default .env in assets: $err');
      }
    }

    // Try to load from app documents directory
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/.env');

      if (file.existsSync()) {
        final envString = await file.readAsString();
        print('Read .env file content: ${envString.length} characters');
        _parseEnvString(envString, isDefault: true);
        print('Loaded .env from ${file.path}');
        return;
      }
    } catch (e) {
      print('Could not load .env from file system: $e');
    }

    print('No .env file found. Creating sample file...');
    await createSampleEnvFile();
  }

  /// Parse environment variables from a string
  static void _parseEnvString(String envString, {bool isDefault = false}) {
    final envLines = envString.split('\n');
    print('Parsing ${envLines.length} lines from env file');
    
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
        print('Parsed variable: $key (${value.length} characters)');
      }
    }
  }

  /// Log loaded environment variables (with obfuscation for sensitive data)
  static void _logLoadedVars() {
    print('=== Environment Variables ===');
    print('== User Variables ==');
    _envVars.forEach((key, value) {
      if (key.toLowerCase().contains('key') ||
          key.toLowerCase().contains('secret') ||
          key.toLowerCase().contains('password')) {
        // Mask sensitive values
        final masked =
            value.length > 8
                ? '${value.substring(0, 4)}...${value.substring(value.length - 4)}'
                : '****';
        print('$key: $masked');
      } else {
        print('$key: $value');
      }
    });
    
    print('== Default Variables ==');
    _defaultEnvVars.forEach((key, value) {
      if (key.toLowerCase().contains('key') ||
          key.toLowerCase().contains('secret') ||
          key.toLowerCase().contains('password')) {
        // Mask sensitive values
        final masked =
            value.length > 8
                ? '${value.substring(0, 4)}...${value.substring(value.length - 4)}'
                : '****';
        print('$key: $masked');
      } else {
        print('$key: $value');
      }
    });
    print('============================');
  }

  /// Force a fresh reload of environment variables, bypassing all caches
  static Future<void> forceReload() async {
    print('Forcing complete reload of environment configuration...');

    // Clear our internal cache
    _envVars.clear();
    _defaultEnvVars.clear();
    _isInitialized = false;

    // Clear dotenv cache if possible
    try {
      dotenv.env.clear();
    } catch (e) {
      print('Could not clear dotenv cache: $e');
    }

    // Reload completely
    await initialize();

    print('Environment configuration reloaded forcibly');
  }

  /// Dump diagnostic information about the API key source
  static Future<void> dumpApiKeyInfo() async {
    final currentKey = get('OPENROUTER_API_KEY');
    final defaultKey = getDefaultValue('OPENROUTER_API_KEY');
    final hasUserKey = await hasUserApiKey();

    print('=========== API KEY SOURCE DIAGNOSTICS ===========');
    print('Has User API Key in Preferences: $hasUserKey');
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
    print('=== SERVICES WILL USE THIS KEY MOVING FORWARD ===');
    print('==================================================');
  }

  // Helper function to avoid importing dart:math
  static int min(int a, int b) => a < b ? a : b;
}
