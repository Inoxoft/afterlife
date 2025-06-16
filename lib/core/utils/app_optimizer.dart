import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'image_optimizer.dart';

/// A comprehensive app optimization utility that combines all optimizations
class AppOptimizer {
  /// Initialize all app optimizations
  static Future<void> initializeApp() async {
    // Ensure Flutter is initialized first
    WidgetsFlutterBinding.ensureInitialized();

    // Set preferred device orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Preload important app images
    await ImageOptimizer.preloadAppImages();

    // Configure system chrome for optimal performance on mobile
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
      ),
    );

    // Set memory cache size
    imageCache.maximumSize = 80;
    imageCache.maximumSizeBytes = 40 * 1024 * 1024; // 40 MB
  }

  /// Optimize a widget for better performance
  static Widget optimizeWidget(Widget widget) {
    return RepaintBoundary(child: widget);
  }

  /// Optimize image loading
  static Widget optimizeImage(Widget imageWidget) {
    return RepaintBoundary(child: imageWidget);
  }

  /// Clear unused caches to free up memory
  static void clearUnusedCaches() {
    imageCache.clear();
    imageCache.clearLiveImages();
    PaintingBinding.instance.imageCache.clear();
  }

  /// Resize image for memory efficiency
  static ImageProvider optimizedAssetImage(String assetPath, {int? width}) {
    if (width != null) {
      return ResizeImage.resizeIfNeeded(width, null, AssetImage(assetPath));
    }
    return AssetImage(assetPath);
  }

  /// Optimize network image loading
  static ImageProvider optimizedNetworkImage(String url, {int? width}) {
    if (width != null) {
      return ResizeImage.resizeIfNeeded(width, null, NetworkImage(url));
    }
    return NetworkImage(url);
  }
}
