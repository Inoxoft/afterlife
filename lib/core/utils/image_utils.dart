import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageUtils {
  static const int _maxImageSize = 512; // Maximum width/height in pixels
  static const int _maxFileSizeKB = 500; // Maximum file size in KB
  static const double _jpegQuality = 0.8; // JPEG compression quality

  /// Pick an image from gallery with size optimization
  static Future<String?> pickAndOptimizeImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: _maxImageSize.toDouble(),
        maxHeight: _maxImageSize.toDouble(),
        imageQuality: (_jpegQuality * 100).round(),
      );

      if (image == null) return null;

      // Get the app's documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String charactersImagesDir = path.join(appDocDir.path, 'character_images');
      
      // Create the directory if it doesn't exist
      final Directory dir = Directory(charactersImagesDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Generate a unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = path.extension(image.path).toLowerCase();
      final String filename = 'character_${timestamp}${extension.isEmpty ? '.jpg' : extension}';
      final String finalPath = path.join(charactersImagesDir, filename);

      // Read the image bytes
      final Uint8List imageBytes = await image.readAsBytes();

      // Further optimize if needed
      final Uint8List optimizedBytes = await _optimizeImageBytes(imageBytes);

      // Save the optimized image
      final File finalFile = File(finalPath);
      await finalFile.writeAsBytes(optimizedBytes);

      return finalPath;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Optimize image bytes for size and quality
  static Future<Uint8List> _optimizeImageBytes(Uint8List bytes) async {
    try {
      // Decode the image
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image image = frame.image;

      // Calculate new dimensions maintaining aspect ratio
      final int originalWidth = image.width;
      final int originalHeight = image.height;
      
      double scale = 1.0;
      if (originalWidth > _maxImageSize || originalHeight > _maxImageSize) {
        scale = _maxImageSize / (originalWidth > originalHeight ? originalWidth : originalHeight);
      }

      final int newWidth = (originalWidth * scale).round();
      final int newHeight = (originalHeight * scale).round();

      // Create a new image with the calculated dimensions
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      
      // Draw the image scaled
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, originalWidth.toDouble(), originalHeight.toDouble()),
        Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
        Paint(),
      );

      // Convert to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image resizedImage = await picture.toImage(newWidth, newHeight);

      // Convert to bytes
      final ByteData? byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      
      image.dispose();
      resizedImage.dispose();

      return byteData?.buffer.asUint8List() ?? bytes;
    } catch (e) {
      debugPrint('Error optimizing image: $e');
      return bytes;
    }
  }

  /// Delete a character image file
  static Future<bool> deleteCharacterImage(String imagePath) async {
    try {
      final File file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  /// Check if an image path is valid and exists
  static Future<bool> isValidImagePath(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return false;
    
    try {
      final File file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get file size in KB
  static Future<int> getImageFileSizeKB(String imagePath) async {
    try {
      final File file = File(imagePath);
      if (await file.exists()) {
        final int bytes = await file.length();
        return (bytes / 1024).round();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Create a circular avatar widget from image path
  static Widget buildCharacterAvatar({
    required String? imagePath,
    required double size,
    IconData? fallbackIcon,
    String? fallbackText,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Colors.grey.shade300,
      ),
      child: ClipOval(
        child: imagePath != null && imagePath.isNotEmpty
            ? Image.file(
                File(imagePath),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackAvatar(
                    size: size,
                    icon: fallbackIcon,
                    text: fallbackText,
                    foregroundColor: foregroundColor,
                  );
                },
              )
            : _buildFallbackAvatar(
                size: size,
                icon: fallbackIcon,
                text: fallbackText,
                foregroundColor: foregroundColor,
              ),
      ),
    );
  }

  /// Create a circular icon avatar widget that can use either icon image or fallback
  static Widget buildIconAvatar({
    required String? iconImagePath,
    required double size,
    IconData? fallbackIcon,
    String? fallbackText,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Colors.grey.shade300,
      ),
      child: ClipOval(
        child: iconImagePath != null && iconImagePath.isNotEmpty
            ? Image.file(
                File(iconImagePath),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackAvatar(
                    size: size,
                    icon: fallbackIcon,
                    text: fallbackText,
                    foregroundColor: foregroundColor,
                  );
                },
              )
            : _buildFallbackAvatar(
                size: size,
                icon: fallbackIcon,
                text: fallbackText,
                foregroundColor: foregroundColor,
              ),
      ),
    );
  }

  /// Pick and optimize an icon image (smaller size optimized for icons)
  static Future<String?> pickAndOptimizeIconImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 256.0, // Smaller size for icons
        maxHeight: 256.0,
        imageQuality: 90, // Higher quality for icons
      );

      if (image == null) return null;

      // Get the app's documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String iconImagesDir = path.join(appDocDir.path, 'character_icons');
      
      // Create the directory if it doesn't exist
      final Directory dir = Directory(iconImagesDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Generate a unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = path.extension(image.path).toLowerCase();
      final String filename = 'icon_${timestamp}${extension.isEmpty ? '.jpg' : extension}';
      final String finalPath = path.join(iconImagesDir, filename);

      // Read the image bytes
      final Uint8List imageBytes = await image.readAsBytes();

      // Further optimize for icon size
      final Uint8List optimizedBytes = await _optimizeIconImageBytes(imageBytes);

      // Save the optimized image
      final File finalFile = File(finalPath);
      await finalFile.writeAsBytes(optimizedBytes);

      return finalPath;
    } catch (e) {
      debugPrint('Error picking icon image: $e');
      return null;
    }
  }

  /// Optimize image bytes specifically for icon usage (smaller size)
  static Future<Uint8List> _optimizeIconImageBytes(Uint8List bytes) async {
    try {
      // Decode the image
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image image = frame.image;

      // Calculate new dimensions for icon (256x256 max)
      final int originalWidth = image.width;
      final int originalHeight = image.height;
      const int maxIconSize = 256;
      
      double scale = 1.0;
      if (originalWidth > maxIconSize || originalHeight > maxIconSize) {
        scale = maxIconSize / (originalWidth > originalHeight ? originalWidth : originalHeight);
      }

      final int newWidth = (originalWidth * scale).round();
      final int newHeight = (originalHeight * scale).round();

      // Create a new image with the calculated dimensions
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      
      // Draw the image scaled
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, originalWidth.toDouble(), originalHeight.toDouble()),
        Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
        Paint(),
      );

      // Convert to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image resizedImage = await picture.toImage(newWidth, newHeight);

      // Convert to bytes
      final ByteData? byteData = await resizedImage.toByteData(format: ui.ImageByteFormat.png);
      
      image.dispose();
      resizedImage.dispose();

      return byteData?.buffer.asUint8List() ?? bytes;
    } catch (e) {
      debugPrint('Error optimizing icon image: $e');
      return bytes;
    }
  }

  /// Delete a character icon image file
  static Future<bool> deleteCharacterIconImage(String iconImagePath) async {
    try {
      final File file = File(iconImagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting icon image: $e');
      return false;
    }
  }

  /// Build fallback avatar when no image is available
  static Widget _buildFallbackAvatar({
    required double size,
    IconData? icon,
    String? text,
    Color? foregroundColor,
  }) {
    return Container(
      width: size,
      height: size,
      child: Center(
        child: icon != null
            ? Icon(
                icon,
                size: size * 0.5,
                color: foregroundColor ?? Colors.grey.shade600,
              )
            : Text(
                text?.isNotEmpty == true ? text![0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: foregroundColor ?? Colors.grey.shade600,
                ),
              ),
      ),
    );
  }

  /// Clean up old unused character images
  static Future<void> cleanupUnusedImages(List<String> usedImagePaths) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String charactersImagesDir = path.join(appDocDir.path, 'character_images');
      final Directory dir = Directory(charactersImagesDir);
      
      if (!await dir.exists()) return;

      final List<FileSystemEntity> files = await dir.list().toList();
      
      for (final FileSystemEntity file in files) {
        if (file is File && !usedImagePaths.contains(file.path)) {
          try {
            await file.delete();
            debugPrint('Deleted unused image: ${file.path}');
          } catch (e) {
            debugPrint('Error deleting unused image ${file.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error during image cleanup: $e');
    }
  }
} 