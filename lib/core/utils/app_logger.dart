import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error, critical }

class AppLogger {
  static const String _prefix = 'Afterlife';
  static bool _isEnabled = kDebugMode;
  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.error;

  // Configure logging behavior
  static void configure({bool? enabled, LogLevel? minLevel}) {
    if (enabled != null) _isEnabled = enabled;
    if (minLevel != null) _minLevel = minLevel;
  }

  // Main logging methods
  static void debug(
    String message, {
    String? tag,
    Object? error,
    Map<String, dynamic>? context,
  }) {
    _log(LogLevel.debug, message, tag: tag, error: error, context: context);
  }

  static void info(
    String message, {
    String? tag,
    Object? error,
    Map<String, dynamic>? context,
  }) {
    _log(LogLevel.info, message, tag: tag, error: error, context: context);
  }

  static void warning(
    String message, {
    String? tag,
    Object? error,
    Map<String, dynamic>? context,
  }) {
    _log(LogLevel.warning, message, tag: tag, error: error, context: context);
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    Map<String, dynamic>? context,
  }) {
    _log(LogLevel.error, message, tag: tag, error: error, context: context);
  }

  static void critical(
    String message, {
    String? tag,
    Object? error,
    Map<String, dynamic>? context,
  }) {
    _log(LogLevel.critical, message, tag: tag, error: error, context: context);
  }

  // Service-specific logging helpers
  static void service(
    String serviceName,
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
  }) {
    _log(level, message, tag: serviceName, error: error);
  }

  static void serviceInitialized(
    String serviceName, {
    Map<String, dynamic>? context,
  }) {
    info(
      '$serviceName initialized successfully',
      tag: serviceName,
      context: context,
    );
  }

  static void serviceError(
    String serviceName,
    String message,
    Object? errorObj,
  ) {
    error('$serviceName error: $message', tag: serviceName, error: errorObj);
  }

  // API and network logging
  static void apiRequest(String endpoint, {Map<String, dynamic>? context}) {
    debug('API Request: $endpoint', tag: 'API', context: context);
  }

  static void apiResponse(
    String endpoint,
    int statusCode, {
    Map<String, dynamic>? context,
  }) {
    final level = statusCode >= 400 ? LogLevel.warning : LogLevel.debug;
    _log(
      level,
      'API Response: $endpoint (${statusCode})',
      tag: 'API',
      context: context,
    );
  }

  static void apiError(
    String endpoint,
    Object apiError, {
    Map<String, dynamic>? context,
  }) {
    error(
      'API Error: $endpoint',
      tag: 'API',
      error: apiError,
      context: context,
    );
  }

  // User action logging
  static void userAction(String action, {Map<String, dynamic>? context}) {
    info('User: $action', tag: 'User', context: context);
  }

  // Performance logging
  static void performance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? context,
  }) {
    info(
      'Performance: $operation took ${duration.inMilliseconds}ms',
      tag: 'Perf',
      context: context,
    );
  }

  // Internal logging implementation
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    Map<String, dynamic>? context,
  }) {
    if (!_isEnabled || level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String().substring(
      11,
      23,
    ); // HH:mm:ss.SSS
    final levelStr = _getLevelString(level);
    final tagStr = tag != null ? '[$tag] ' : '';
    final contextStr = context != null ? ' | ${_formatContext(context)}' : '';

    final logMessage =
        '$_prefix $timestamp $levelStr $tagStr$message$contextStr';

    // Use appropriate output method based on level
    switch (level) {
      case LogLevel.debug:
      case LogLevel.info:
        debugPrint(logMessage);
        break;
      case LogLevel.warning:
      case LogLevel.error:
      case LogLevel.critical:
        debugPrint(logMessage);
        if (error != null) {
          debugPrint('  └─ Error: $error');
        }
        break;
    }
  }

  static String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '[🔍]';
      case LogLevel.info:
        return '[ℹ️ ]';
      case LogLevel.warning:
        return '[⚠️ ]';
      case LogLevel.error:
        return '[❌]';
      case LogLevel.critical:
        return '[🔥]';
    }
  }

  static String _formatContext(Map<String, dynamic> context) {
    final items = context.entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}=${e.value}')
        .take(3) // Limit to prevent log spam
        .join(', ');
    return items.isNotEmpty ? '{$items}' : '';
  }

  // Production-safe methods that never log sensitive data
  static void secureInfo(String message, {String? tag}) {
    if (kDebugMode) {
      info(message, tag: tag);
    }
  }

  static void secureError(String message, {String? tag, Object? errorObj}) {
    // Always log errors, but sanitize in production
    final sanitizedMessage = kDebugMode ? message : _sanitizeMessage(message);
    final sanitizedError = kDebugMode ? errorObj : null;
    error(sanitizedMessage, tag: tag, error: sanitizedError);
  }

  static String _sanitizeMessage(String message) {
    // Remove potentially sensitive information in production
    return message
        .replaceAll(RegExp(r'sk-[A-Za-z0-9_-]+'), 'sk-***') // API keys
        .replaceAll(RegExp(r'\b\d{4}\b'), '****') // Potential PINs
        .replaceAll(RegExp(r'Bearer\s+\S+'), 'Bearer ***'); // Bearer tokens
  }

  // Development helpers
  static void debugObject(String name, Object obj, {String? tag}) {
    if (kDebugMode) {
      debug('$name: ${obj.toString()}', tag: tag);
    }
  }

  static void trace(String message, {String? tag}) {
    if (kDebugMode) {
      debug('TRACE: $message', tag: tag);
    }
  }
}
