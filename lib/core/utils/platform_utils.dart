import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Enum to represent different device types
enum DeviceType {
  mobile,
  desktop,
  watch,
  web,
}

/// Utility class for platform and device detection
class PlatformUtils {
  /// Check if running on mobile (iOS or Android)
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Check if running on desktop (Windows, macOS, or Linux)
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Check if running on a watch (WearOS or watchOS)
  static bool isWatch(BuildContext context) {
    // Watches typically have smaller screens (< 300 logical pixels)
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 300 || size.height < 300;
    return isMobile && isSmallScreen;
  }

  /// Get the current device type based on platform and screen size
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (isWeb) {
      // For web, determine based on screen size
      if (width < 300) {
        return DeviceType.watch;
      } else if (width < 600) {
        return DeviceType.mobile;
      } else {
        return DeviceType.desktop;
      }
    } else if (isWatch(context)) {
      return DeviceType.watch;
    } else if (isDesktop) {
      // Desktop platform - force desktop layout regardless of window size
      // This ensures desktop app always shows desktop UI
      // ignore: avoid_print
      debugPrint('🖥️ Desktop detected - width: ${width}px');
      return DeviceType.desktop;
    } else {
      return DeviceType.mobile;
    }
  }

  /// Check if the screen is considered large (desktop or tablet)
  static bool isLargeScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600;
  }

  /// Check if the screen is considered extra large (desktop)
  static bool isExtraLargeScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 1200;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.watch:
        return const EdgeInsets.all(8.0);
      case DeviceType.mobile:
        return const EdgeInsets.all(16.0);
      case DeviceType.desktop:
      case DeviceType.web:
        return const EdgeInsets.all(24.0);
    }
  }

  /// Get responsive font size multiplier
  static double getFontSizeMultiplier(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.watch:
        return 0.85;
      case DeviceType.mobile:
        return 1.0;
      case DeviceType.desktop:
      case DeviceType.web:
        return 1.1;
    }
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.watch:
        return 20.0;
      case DeviceType.mobile:
        return 24.0;
      case DeviceType.desktop:
      case DeviceType.web:
        return 28.0;
    }
  }
}




