import 'package:flutter/foundation.dart';
import '../utils/app_logger.dart';

/// Base provider class with standardized error state management
abstract class BaseProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _lastError;
  bool _isDisposed = false;

  /// Current loading state
  bool get isLoading => _isLoading;

  /// Last error message
  String? get lastError => _lastError;

  /// Whether there's currently an error
  bool get hasError => _lastError != null;

  /// Whether provider is in a good state (not loading, no errors)
  bool get isReady => !_isLoading && !hasError;

  /// Set loading state
  @protected
  void setLoading(bool loading) {
    if (_isDisposed) return;

    _isLoading = loading;
    if (loading) {
      _lastError = null; // Clear errors when starting new operation
    }
    notifyListeners();
  }

  /// Set error state with optional logging
  @protected
  void setError(String message, {Object? error, String? tag}) {
    if (_isDisposed) return;

    _lastError = message;
    _isLoading = false;

    // Log the error with context
    AppLogger.error(message, tag: tag ?? runtimeType.toString(), error: error);

    notifyListeners();
  }

  /// Clear current error state
  @protected
  void clearError() {
    if (_isDisposed) return;

    _lastError = null;
    notifyListeners();
  }

  /// Execute an async operation with proper state management
  @protected
  Future<T?> executeWithState<T>({
    required Future<T> Function() operation,
    required String operationName,
    String? tag,
    bool clearErrorFirst = true,
  }) async {
    print('🔧 [BaseProvider] executeWithState called for: $operationName');
    print('🔧 [BaseProvider] - Provider type: ${runtimeType.toString()}');
    print('🔧 [BaseProvider] - Disposed: $_isDisposed');
    print('🔧 [BaseProvider] - Current loading: $_isLoading');
    print('🔧 [BaseProvider] - Current error: $_lastError');
    
    if (_isDisposed) {
      print('❌ [BaseProvider] Operation cancelled - provider disposed');
      return null;
    }

    try {
      print('🔧 [BaseProvider] Starting operation...');
      if (clearErrorFirst) clearError();
      setLoading(true);
      print('🔧 [BaseProvider] State set to loading');

      print('🔧 [BaseProvider] Executing operation function...');
      final result = await operation();
      print('✅ [BaseProvider] Operation function completed successfully');
      print('🔧 [BaseProvider] Result type: ${result.runtimeType}');
      print('🔧 [BaseProvider] Result: $result');

      // Only update state if not disposed
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
        print('🔧 [BaseProvider] State updated - loading: false');
      }

      AppLogger.debug(
        '$operationName completed successfully',
        tag: tag ?? runtimeType.toString(),
      );
      print('✅ [BaseProvider] executeWithState completed successfully');
      return result;
    } catch (e, stackTrace) {
      print('❌ [BaseProvider] Error in executeWithState: $e');
      print('❌ [BaseProvider] Stack trace: $stackTrace');
      if (!_isDisposed) {
        setError('$operationName failed: ${e.toString()}', error: e, tag: tag);
        print('❌ [BaseProvider] Error state set');
      }
      print('❌ [BaseProvider] Returning null due to error');
      return null;
    }
  }

  /// Execute an async operation with custom error message
  @protected
  Future<T?> executeWithCustomError<T>({
    required Future<T> Function() operation,
    required String operationName,
    required String errorMessage,
    String? tag,
    bool clearErrorFirst = true,
  }) async {
    if (_isDisposed) return null;

    try {
      if (clearErrorFirst) clearError();
      setLoading(true);

      final result = await operation();

      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }

      AppLogger.debug(
        '$operationName completed successfully',
        tag: tag ?? runtimeType.toString(),
      );
      return result;
    } catch (e) {
      if (!_isDisposed) {
        setError(errorMessage, error: e, tag: tag);
      }
      return null;
    }
  }

  /// Log user actions for analytics/debugging
  @protected
  void logUserAction(String action, {Map<String, dynamic>? context}) {
    AppLogger.userAction(
      '${runtimeType.toString()}: $action',
      context: context,
    );
  }

  /// Log provider state changes
  @protected
  void logStateChange(String change, {Map<String, dynamic>? context}) {
    AppLogger.debug(
      'State change: $change',
      tag: runtimeType.toString(),
      context: context,
    );
  }

  /// Track performance of operations
  @protected
  Future<T?> trackPerformance<T>({
    required Future<T> Function() operation,
    required String operationName,
    String? tag,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      stopwatch.stop();

      AppLogger.performance(
        operationName,
        stopwatch.elapsed,
        context: {'provider': runtimeType.toString()},
      );

      return result;
    } catch (e) {
      stopwatch.stop();
      AppLogger.performance(
        '$operationName (failed)',
        stopwatch.elapsed,
        context: {'provider': runtimeType.toString(), 'error': true},
      );
      rethrow;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    AppLogger.debug('Provider disposed', tag: runtimeType.toString());
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
