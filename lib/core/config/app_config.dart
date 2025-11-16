/// Application configuration for different environments
class AppConfig {
  /// Environment name (dev, pprod, prod)
  final String environment;
  
  /// API base URL
  final String apiBaseUrl;
  
  /// Support email
  final String supportEmail;
  
  /// Whether this is a production environment
  bool get isProduction => environment == 'prod';
  
  /// Whether this is a pre-production environment
  bool get isPreProduction => environment == 'pprod';
  
  /// Whether this is a development environment
  bool get isDevelopment => environment == 'dev';

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.supportEmail,
  });

  /// Development environment (localhost)
  static const dev = AppConfig(
    environment: 'dev',
    apiBaseUrl: 'http://localhost:3000',
    supportEmail: 'support@example.com',
  );

  /// Pre-production environment
  static const pprod = AppConfig(
    environment: 'pprod',
    apiBaseUrl: 'https://api-pprod.team-oustad.com',
    supportEmail: 'support@team-oustad.com',
  );

  /// Production environment
  static const prod = AppConfig(
    environment: 'prod',
    apiBaseUrl: 'https://api.team-oustad.com',
    supportEmail: 'support@team-oustad.com',
  );

  /// Get configuration based on environment variable
  /// Reads from --dart-define=ENVIRONMENT=pprod|prod|dev
  /// Defaults to dev environment
  factory AppConfig.fromEnvironment() {
    const envName = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
    
    switch (envName) {
      case 'pprod':
        return AppConfig.pprod;
      case 'prod':
        return AppConfig.prod;
      case 'dev':
      default:
        return AppConfig.dev;
    }
  }

  @override
  String toString() => 'AppConfig(environment: $environment, apiBaseUrl: $apiBaseUrl)';
}
