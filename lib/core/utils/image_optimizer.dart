import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A utility class for efficient image loading and caching
class ImageOptimizer {
  // Static cache to prevent reloading the same assets
  static final Map<String, ui.Image> _imageCache = {};
  static final Map<String, bool> _preloadedAssets = {};

  /// Preload important app images for faster initial rendering
  static Future<void> preloadAppImages() async {
    // List all critical images to preload
    final imagesToPreload = [
      'assets/images/einstein.png',
      'assets/images/monroe.png',
      'assets/images/turing.png',
      'assets/images/reagan.png',
    ];

    // Load all images in parallel using our optimized loading method
    await Future.wait(
      imagesToPreload.map((path) async {
        if (!_preloadedAssets.containsKey(path)) {
          await loadOptimizedImage(path);
          _preloadedAssets[path] = true;
        }
      }),
    );
  }

  /// Get a cached asset image
  static ImageProvider getOptimizedAssetImage(String assetPath) {
    return AssetImage(assetPath);
  }

  /// Decode an image with specific size constraints for memory efficiency
  static Future<ui.Image> loadOptimizedImage(
    String assetPath, {
    int? targetWidth,
    int? targetHeight,
  }) async {
    // Check if image is already cached
    if (_imageCache.containsKey(assetPath)) {
      return _imageCache[assetPath]!;
    }

    // Load asset as bytes
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();

    // Decode the image
    final ui.Codec codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );

    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;

    // Cache the image
    _imageCache[assetPath] = image;

    return image;
  }

  /// Preload an asset image using the standard Flutter mechanism when context is available
  static Future<void> preloadImageWithContext(
    BuildContext context,
    String assetPath,
  ) async {
    await precacheImage(AssetImage(assetPath), context);
  }

  /// Clear the image cache to free memory
  static void clearCache() {
    _imageCache.forEach((_, image) => image.dispose());
    _imageCache.clear();
    _preloadedAssets.clear();
  }
}
