import '../utils/app_logger.dart';

/// Result of service initialization
class ServiceInitializationResult {
  final bool success;
  final String? errorMessage;
  final Object? error;
  final List<String> warnings;

  const ServiceInitializationResult({
    required this.success,
    this.errorMessage,
    this.error,
    this.warnings = const [],
  });

  factory ServiceInitializationResult.success({List<String> warnings = const []}) {
    return ServiceInitializationResult(
      success: true,
      warnings: warnings,
    );
  }

  factory ServiceInitializationResult.failure(
    String errorMessage, [
    Object? error,
    List<String> warnings = const [],
  ]) {
    return ServiceInitializationResult(
      success: false,
      errorMessage: errorMessage,
      error: error,
      warnings: warnings,
    );
  }
}

/// Abstract base class for all services with standardized initialization
abstract class BaseService {
  /// Service name for logging purposes
  String get serviceName;

  /// Whether the service has been initialized
  bool get isInitialized;

  /// Initialize the service
  /// This is the method that subclasses should override
  Future<ServiceInitializationResult> doInitialize();

  /// Optional dependencies that must be initialized before this service
  List<Future<void> Function()> get dependencies => [];

  /// Standardized initialization wrapper
  /// This method handles the common patterns and should not be overridden
  Future<void> initialize() async {
    if (isInitialized) return;

    try {
      // Initialize dependencies first
      for (final dependency in dependencies) {
        await dependency();
      }

      // Perform the actual initialization
      final result = await doInitialize();

      if (result.success) {
        AppLogger.serviceInitialized(serviceName);
        
        // Log any warnings
        for (final warning in result.warnings) {
          AppLogger.warning(warning, tag: serviceName);
        }
      } else {
        AppLogger.serviceError(
          serviceName,
          result.errorMessage ?? 'initialization failed',
          result.error,
        );
      }
    } catch (e) {
      AppLogger.serviceError(serviceName, 'initialization failed', e);
    }
  }
}

/// Mixin for services that need singleton pattern
mixin SingletonService {
  static bool _isInitialized = false;
  
  bool get isInitialized => _isInitialized;
  
  void markInitialized() {
    _isInitialized = true;
  }
  
  void resetInitialization() {
    _isInitialized = false;
  }
}

/// Utility class for managing service initialization
class ServiceManager {
  static final Map<String, BaseService> _services = {};
  static final List<String> _initializationOrder = [];

  /// Register a service
  static void register(BaseService service) {
    _services[service.serviceName] = service;
  }

  /// Initialize all registered services in dependency order
  static Future<Map<String, ServiceInitializationResult>> initializeAll() async {
    final results = <String, ServiceInitializationResult>{};
    
    for (final service in _services.values) {
      try {
        await service.initialize();
        results[service.serviceName] = ServiceInitializationResult.success();
        _initializationOrder.add(service.serviceName);
      } catch (e) {
        results[service.serviceName] = ServiceInitializationResult.failure(
          'Service initialization failed',
          e,
        );
      }
    }
    
    return results;
  }

  /// Get initialization order
  static List<String> get initializationOrder => List.unmodifiable(_initializationOrder);

  /// Check if all services are initialized
  static bool get allServicesInitialized {
    return _services.values.every((service) => service.isInitialized);
  }

  /// Get service status summary
  static Map<String, bool> getServiceStatus() {
    return Map.fromEntries(
      _services.entries.map((entry) => MapEntry(entry.key, entry.value.isInitialized)),
    );
  }

  /// Reset all services (for testing)
  static void resetAll() {
    _services.clear();
    _initializationOrder.clear();
  }
}

/// Static service initialization helper for backward compatibility
class StaticServiceInitializer {
  /// Standardized static service initialization
  static Future<void> initializeService({
    required String serviceName,
    required bool Function() isInitialized,
    required void Function() markInitialized,
    required Future<void> Function() initializeLogic,
    List<Future<void> Function()> dependencies = const [],
    bool allowReinitialization = false,
  }) async {
    if (isInitialized() && !allowReinitialization) return;

    try {
      // Initialize dependencies first
      for (final dependency in dependencies) {
        await dependency();
      }

      // Perform the actual initialization
      await initializeLogic();
      
      markInitialized();
      AppLogger.serviceInitialized(serviceName);
    } catch (e) {
      AppLogger.serviceError(serviceName, 'initialization failed', e);
      markInitialized(); // Prevent retry loops
      rethrow;
    }
  }
}