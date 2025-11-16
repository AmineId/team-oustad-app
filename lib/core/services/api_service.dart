import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Service for making API calls to the backend
class ApiService {
  late final String _baseUrl;
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client() {
    _baseUrl = _getBaseUrl();
    print('ApiService initialized with base URL: $_baseUrl');
  }

  /// Determine the base URL based on environment configuration
  /// Priority:
  /// 1. API_BASE_URL environment variable (if set)
  /// 2. ENVIRONMENT variable mapped to AppConfig
  String _getBaseUrl() {
    // Priority 1: Check for explicit API_BASE_URL
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (apiBaseUrl.isNotEmpty) {
      return apiBaseUrl;
    }

    // Priority 2: Use ENVIRONMENT to determine config
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
    final config = AppConfig.fromEnvironment(environment);
    return config.apiBaseUrl;
  }

  /// Get request with error handling
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      print('GET request to: $url');
      
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout - please check your network connection');
        },
      );

      return _handleResponse(response);
    } catch (e) {
      print('API GET error: $e');
      rethrow;
    }
  }

  /// Post request with error handling
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      print('POST request to: $url');
      
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout - please check your network connection');
        },
      );

      return _handleResponse(response);
    } catch (e) {
      print('API POST error: $e');
      rethrow;
    }
  }

  /// Handle HTTP response and convert to Map
  Map<String, dynamic> _handleResponse(http.Response response) {
    print('Response status: ${response.statusCode}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'API error: ${response.statusCode} - ${response.reasonPhrase}',
      );
    }
  }

  /// Test connection to the API
  Future<bool> testConnection() async {
    try {
      print('Testing connection to: $_baseUrl');
      final url = Uri.parse('$_baseUrl/health');
      
      final response = await _client.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  /// Get the current base URL being used
  String get baseUrl => _baseUrl;

  /// Dispose of resources
  void dispose() {
    _client.close();
  }
}
