import 'dart:io' show Platform;

/// Application configuration for different environments
class AppConfig {
  final String apiBaseUrl;
  final String environment;

  const AppConfig._({
    required this.apiBaseUrl,
    required this.environment,
  });

  /// Development environment configuration
  static AppConfig get dev {
    return AppConfig._(
      apiBaseUrl: _getPlatformDevUrl(),
      environment: 'dev',
    );
  }

  /// Pre-production environment configuration
  static const AppConfig pprod = AppConfig._(
    apiBaseUrl: 'https://api-pprod.team-oustad.com',
    environment: 'pprod',
  );

  /// Production environment configuration
  static const AppConfig prod = AppConfig._(
    apiBaseUrl: 'https://api.team-oustad.com',
    environment: 'prod',
  );

  /// Get platform-specific development URL
  /// Android emulator uses 10.0.2.2 to access host machine localhost
  /// All other platforms use localhost directly
  static String _getPlatformDevUrl() {
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000';
      }
    } catch (e) {
      // Platform check might fail on web, fallback to localhost
    }
    return 'http://localhost:3000';
  }

  /// Get configuration based on environment string
  static AppConfig fromEnvironment(String? env) {
    switch (env?.toLowerCase()) {
      case 'prod':
      case 'production':
        return AppConfig.prod;
      case 'pprod':
      case 'preproduction':
      case 'pre-production':
        return AppConfig.pprod;
      case 'dev':
      case 'development':
      default:
        return AppConfig.dev;
    }
  }
}
