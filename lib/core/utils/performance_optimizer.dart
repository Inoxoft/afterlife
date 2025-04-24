import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A utility class to optimize app performance on mobile devices
class PerformanceOptimizer {
  /// Initialize performance optimizations for the app
  static Future<void> initialize() async {
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Set preferred device orientations for better performance
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set system UI overlay style for performance
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    // Set image cache size
    PaintingBinding.instance.imageCache.maximumSize =
        100; // Reduced from default
    PaintingBinding.instance.imageCache.maximumSizeBytes =
        50 * 1024 * 1024; // 50 MB

    // Additional optimizations for release mode
    if (!kDebugMode) {
      // Add release-only optimizations here
    }
  }

  /// Create a memory-efficient image provider
  static ImageProvider optimizedNetworkImage(String url) {
    return NetworkImage(
      url,
      // Add specific caching or resizing parameters if needed
    );
  }

  /// Optimize a widget tree for rendering performance
  static Widget optimizedWidget(Widget child) {
    return RepaintBoundary(child: child);
  }
}
