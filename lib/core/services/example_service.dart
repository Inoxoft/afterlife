import 'base_service.dart';
import 'preferences_service.dart';

/// Example service demonstrating the new BaseService pattern
/// This shows how new services should be implemented
class ExampleService extends BaseService {
  static ExampleService? _instance;
  static bool _isInitialized = false;

  ExampleService._();

  static ExampleService get instance => _instance ??= ExampleService._();

  @override
  String get serviceName => 'ExampleService';

  @override
  bool get isInitialized => _isInitialized;

  @override
  List<Future<void> Function()> get dependencies => [
    () => PreferencesService.initialize(),
  ];

  @override
  Future<ServiceInitializationResult> doInitialize() async {
    try {
      // Perform service-specific initialization here
      // This is where you'd load settings, initialize connections, etc.
      
      // Example: Load some configuration
      final prefs = await PreferencesService.getPrefs();
      final someConfig = prefs.getString('example_config') ?? 'default';
      
      // Mark as initialized
      _isInitialized = true;
      
      // Return success (optionally with warnings)
      return ServiceInitializationResult.success(
        warnings: someConfig == 'default' ? ['Using default configuration'] : [],
      );
    } catch (e) {
      return ServiceInitializationResult.failure(
        'Failed to initialize example service',
        e,
      );
    }
  }

  /// Example service method
  String getExampleData() {
    if (!isInitialized) {
      throw StateError('ExampleService must be initialized before use');
    }
    return 'Example data';
  }

  /// Reset for testing
  static void reset() {
    _instance = null;
    _isInitialized = false;
  }
}