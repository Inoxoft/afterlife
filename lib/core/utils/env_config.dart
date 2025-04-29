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

  // Keys for SharedPreferences
  static const String _openRouterApiKeyPref = 'user_openrouter_api_key';

  /// Initialize environment configuration
  static Future<void> initialize() async {
    // Clear existing variables to ensure we get fresh data
    _envVars.clear();
    _isInitialized = false;

    try {
      print('Initializing environment configuration...');

      // First try to get API key from SharedPreferences (user setting)
      final prefs = await SharedPreferences.getInstance();
      final userApiKey = prefs.getString(_openRouterApiKeyPref);

      if (userApiKey != null && userApiKey.isNotEmpty) {
        _envVars['OPENROUTER_API_KEY'] = userApiKey;
        print('Using API key from user preferences');
      } else {
        // Otherwise try to load from .env file or assets
        await _loadFromDotEnv();
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
    }

    // If dotenv loaded successfully, copy values to our map
    if (dotenvLoaded) {
      dotenv.env.forEach((key, value) {
        _envVars[key] = value;
      });
      print('Copied ${dotenv.env.length} variables from dotenv');
    }

    // If we don't have any env vars yet, try manual file loading
    if (_envVars.isEmpty) {
      await _loadEnvManually();
    }
  }

  /// Get an environment variable value
  static String? get(String key) {
    if (!_isInitialized) {
      print('Warning: EnvConfig not initialized before access');
    }
    return _envVars[key];
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

      // Empty string means remove it
      if (apiKey.isEmpty) {
        await prefs.remove(_openRouterApiKeyPref);
        print('Removed user API key from preferences');
      } else {
        await prefs.setString(_openRouterApiKeyPref, apiKey);
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
      _parseEnvString(envString);
      print('Loaded .env from assets');
      return;
    } catch (e) {
      print('Could not load .env from assets: $e');
    }

    // Try to load from app documents directory
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/.env');

      if (file.existsSync()) {
        final envString = await file.readAsString();
        print('Read .env file content: ${envString.length} characters');
        _parseEnvString(envString);
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
  static void _parseEnvString(String envString) {
    final envLines = envString.split('\n');
    print('Parsing ${envLines.length} lines from env file');

    for (final line in envLines) {
      // Skip comments and empty lines
      if (line.trim().startsWith('#') || line.trim().isEmpty) continue;

      // Parse key=value format
      final parts = line.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join('=').trim();
        _envVars[key] = value;
        print('Parsed variable: $key (${value.length} characters)');
      }
    }
  }

  /// Log loaded environment variables (with obfuscation for sensitive data)
  static void _logLoadedVars() {
    print('=== Environment Variables ===');
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
    print('============================');
  }

  /// Force a fresh reload of environment variables, bypassing all caches
  static Future<void> forceReload() async {
    print('Forcing complete reload of environment configuration...');

    // Clear our internal cache
    _envVars.clear();
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
}
