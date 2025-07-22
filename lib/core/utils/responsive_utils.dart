import 'package:flutter/material.dart';

/// Utility class for responsive design and adaptive layouts
class ResponsiveUtils {
  // Breakpoints for different screen sizes
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Get the device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else if (width < desktopBreakpoint) {
      return DeviceType.desktop;
    } else {
      return DeviceType.tv;
    }
  }

  /// Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get grid cross axis count based on device type and orientation
  static int getGridCrossAxisCount(BuildContext context) {
    final deviceType = getDeviceType(context);
    final isLandscapeMode = isLandscape(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return isLandscapeMode ? 3 : 2;
      case DeviceType.tablet:
        return isLandscapeMode ? 3 : 2;
      case DeviceType.desktop:
        return isLandscapeMode ? 6 : 4;
      case DeviceType.tv:
        return isLandscapeMode ? 8 : 6;
    }
  }

  /// Get appropriate padding based on device type
  static EdgeInsets getScreenPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.symmetric(horizontal: 16);
      case DeviceType.tablet:
        return const EdgeInsets.symmetric(horizontal: 32);
      case DeviceType.desktop:
        return const EdgeInsets.symmetric(horizontal: 64);
      case DeviceType.tv:
        return const EdgeInsets.symmetric(horizontal: 120);
    }
  }

  /// Get chat message max width percentage based on device type
  static double getChatMessageMaxWidthFactor(BuildContext context) {
    final deviceType = getDeviceType(context);
    final isLandscapeMode = isLandscape(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return isLandscapeMode ? 0.6 : 0.75;
      case DeviceType.tablet:
        return isLandscapeMode ? 0.5 : 0.65;
      case DeviceType.desktop:
        return 0.45;
      case DeviceType.tv:
        return 0.35;
    }
  }

  /// Get appropriate font size scaling based on device type
  static double getFontSizeScale(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.tablet:
        return 1.1;
      case DeviceType.desktop:
        return 1.2;
      case DeviceType.tv:
        return 1.4;
    }
  }

  /// Get grid child aspect ratio based on device type
  static double getGridChildAspectRatio(BuildContext context) {
    final deviceType = getDeviceType(context);
    final isLandscapeMode = isLandscape(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return isLandscapeMode ? 0.8 : 0.7;
      case DeviceType.tablet:
        return isLandscapeMode ? 0.9 : 0.75;
      case DeviceType.desktop:
        return 0.7;
      case DeviceType.tv:
        return 0.65;
    }
  }

  /// Get spacing between grid items
  static double getGridSpacing(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 16;
      case DeviceType.tablet:
        return 20;
      case DeviceType.desktop:
        return 24;
      case DeviceType.tv:
        return 32;
    }
  }

  /// Get chat input area padding
  static EdgeInsets getChatInputPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(16);
      case DeviceType.tablet:
        return const EdgeInsets.all(20);
      case DeviceType.desktop:
        return const EdgeInsets.all(24);
      case DeviceType.tv:
        return const EdgeInsets.all(32);
    }
  }

  /// Get chat list padding
  static EdgeInsets getChatListPadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return const EdgeInsets.all(16);
      case DeviceType.tablet:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
      case DeviceType.desktop:
        return const EdgeInsets.symmetric(horizontal: 64, vertical: 20);
      case DeviceType.tv:
        return const EdgeInsets.symmetric(horizontal: 120, vertical: 24);
    }
  }

  /// Check if we should use wide layout (side-by-side layout for larger screens)
  static bool shouldUseWideLayout(BuildContext context) {
    final deviceType = getDeviceType(context);
    final isLandscapeMode = isLandscape(context);
    
    return (deviceType == DeviceType.desktop || deviceType == DeviceType.tv) ||
           (deviceType == DeviceType.tablet && isLandscapeMode);
  }

  /// Get app bar height based on device type
  static double getAppBarHeight(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return kToolbarHeight;
      case DeviceType.tablet:
        return kToolbarHeight + 8;
      case DeviceType.desktop:
        return kToolbarHeight + 16;
      case DeviceType.tv:
        return kToolbarHeight + 24;
    }
  }
}

enum DeviceType {
  mobile,
  tablet,
  desktop,
  tv,
} 