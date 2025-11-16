import 'dart:async';

/// Configuration for connecting to a PostgreSQL database.
///
/// For security, DO NOT hardcode secrets in source. Prefer passing values via
/// --dart-define at build/run time and reading them with String.fromEnvironment.
class DatabaseConfig {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final bool useSSL;

  const DatabaseConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    this.useSSL = false,
  });

  /// Reads settings from --dart-define values.
  /// Example run args:
  ///   --dart-define=DB_HOST=your-host --dart-define=DB_USER=... etc
  factory DatabaseConfig.fromEnv() {
    String read(String key, [String def = '']) => String.fromEnvironment(key, defaultValue: def);
    int readInt(String key, [int def = 5432]) {
      final s = String.fromEnvironment(key, defaultValue: '');
      return int.tryParse(s) ?? def;
    }

    // Common keys: DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, DB_SSL
    final host = read('DB_HOST', 'localhost');
    final port = readInt('DB_PORT', 5432);
    final db = read('DB_NAME', 'fitness');
    final user = read('DB_USER', 'admin');
    final pass = read('DB_PASSWORD', 'admin');
    final useSSL = read('DB_SSL', 'false').toLowerCase() == 'true';

    return DatabaseConfig(
      host: host,
      port: port,
      database: db,
      username: user,
      password: pass,
      useSSL: useSSL,
    );
  }
}

/// A minimal interface for DB operations your app needs.
abstract class DbService {
  Future<void> connect();
  Future<void> close();

  /// Demo method: verify a username/password (for POC only).
  /// In production, do auth on a server, never directly against the DB.
  Future<bool> verifyUserPassword(String username, String password);
}
