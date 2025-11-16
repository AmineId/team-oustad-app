import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Simple API client for the Team Fitness Express+Prisma backend.
///
/// The base URL is determined by:
/// 1. API_BASE_URL variable - for custom URLs (optional override)
/// 2. ENVIRONMENT variable (pprod, prod, dev) - uses AppConfig
///
/// Environments:
/// - dev: http://localhost:3000 (or http://10.0.2.2:3000 for Android)
/// - pprod: https://api-pprod.team-oustad.com (pre-production/beta)
/// - prod: https://api.team-oustad.com (production)
///
/// Note: Builds should always define ENVIRONMENT variable via --dart-define.
class ApiService {
  final Uri baseUri;

  ApiService(this.baseUri);

  factory ApiService.fromEnv() {
    String apiUrl;
    
    // Priority 1: Check for custom API_BASE_URL (optional override)
    const customUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    
    if (customUrl.isNotEmpty) {
      apiUrl = customUrl;
      // ignore: avoid_print
      print('🌐 ApiService: Using custom API_BASE_URL → $apiUrl');
    } else {
      // Priority 2: Use ENVIRONMENT variable with AppConfig
      final config = AppConfig.fromEnvironment();
      apiUrl = config.apiBaseUrl;
      // ignore: avoid_print
      print('🌐 ApiService: Using ${config.environment} environment → $apiUrl');
    }

    return ApiService(Uri.parse(apiUrl));
  }

  /// Health check - returns true when backend is reachable and returns 200.
  Future<bool> healthCheck({Duration timeout = const Duration(seconds: 8)}) async {
    final uri = baseUri.resolve('/health');
    try {
      // Helpful debug log while developing
      // ignore: avoid_print
      print('ApiService.healthCheck -> $uri (timeout: ${timeout.inSeconds}s)');
      final resp = await http.get(uri);
      return resp.statusCode == 200;
    } catch (exception) {
      // ignore: avoid_print
      print('Health check failed: $exception');
      return false;
    }
  }

  /// Clean string by removing null bytes and other invalid characters
  String _cleanString(String input) {
    // Remove null bytes and other control characters except newlines/tabs
    return input.replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F]'), '').trim();
  }

  /// Attempt login against the API. Returns a map with token and user info on success,
  /// or null on failure. The backend returns JSON like:
  /// {"token":"...", "user": {"id":"...", "email":"...", "fullName":"...", "gymId":"...", "type":"admin|member|owner"}}
  Future<Map<String, dynamic>?> login(String email, String password, {Duration timeout = const Duration(seconds: 8)}) async {
    final uri = baseUri.resolve('/auth/login');
    try {
      // Clean input to remove null bytes and invalid characters
      final cleanEmail = _cleanString(email);
      final cleanPassword = _cleanString(password);
      
      // ignore: avoid_print
      print('ApiService.login -> $uri with email: $cleanEmail');
      
      final resp = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': cleanEmail, 'password': cleanPassword})).timeout(timeout);
      
      // ignore: avoid_print
      print('ApiService.login response status: ${resp.statusCode}');
      // ignore: avoid_print
      print('ApiService.login response body: ${resp.body}');
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          if (body is Map && body['token'] is String && body['user'] is Map) {
            final user = body['user'] as Map<String, dynamic>;
            
            // Extraire le type depuis l'objet user (priorité) ou depuis le JWT (fallback)
            String userType = 'member'; // Par défaut
            
            // Priorité 1: user.type directement dans la réponse
            if (user['type'] != null) {
              userType = user['type'] as String;
              // ignore: avoid_print
              print('ApiService.login extracted type from user object: $userType');
            } else if (user['role'] != null) {
              userType = user['role'] as String;
              // ignore: avoid_print
              print('ApiService.login extracted role from user object: $userType');
            } else {
              // Priorité 2: Fallback vers JWT decode
              try {
                final token = body['token'] as String;
                // Décoder le JWT (partie payload)
                final parts = token.split('.');
                if (parts.length == 3) {
                  final payload = parts[1];
                  // Ajouter le padding nécessaire pour base64
                  final normalized = base64Url.normalize(payload);
                  final payloadString = utf8.decode(base64Url.decode(normalized));
                  final payloadMap = jsonDecode(payloadString) as Map<String, dynamic>;
                  
                  if (payloadMap['type'] != null) {
                    userType = payloadMap['type'] as String;
                    // ignore: avoid_print
                    print('ApiService.login extracted type from JWT: $userType');
                  }
                }
              } catch (jwtError) {
                // ignore: avoid_print
                print('ApiService.login JWT decode error: $jwtError');
              }
            }
            
            // ignore: avoid_print
            print('ApiService.login final userType: $userType');
            
            return {
              'token': body['token'] as String,
              'userType': userType,
              'userId': user['id'].toString(),
              'email': user['email'] as String,
              'fullName': user['fullName'] as String,
              'gymId': user['gymId']?.toString(),
            };
          }
        } catch (e) {
          // ignore: avoid_print
          print('ApiService.login parse error: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('ApiService.login exception: $e');
      return null;
    }
  }

  /// Verify a JWT by calling the backend. Returns true when token is valid.
  Future<bool> verifyToken(String token, {Duration timeout = const Duration(seconds: 8)}) async {
    final uri = baseUri.resolve('/auth/verify');
    try {
      final resp = await http.get(uri, headers: {'Authorization': 'Bearer $token'}).timeout(timeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Report an exception to the backend for operator review. The backend
  /// can forward this to an email or store it.
  Future<bool> reportError(String message, String? stack, {Map<String, dynamic>? extra}) async {
    final uri = baseUri.resolve('/errors');
    try {
      final body = {
        'message': message,
        'stack': stack,
        'extra': extra ?? {},
      };
      final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(const Duration(seconds: 8));
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e) {
      // ignore network/reporting errors here
      return false;
    }
  }

  /// Request a password reset code for the given email.
  /// Returns true if the request was successful (note: backend doesn't reveal if email exists).
  Future<bool> forgotPassword(String email, {Duration timeout = const Duration(seconds: 8)}) async {
    final uri = baseUri.resolve('/auth/forgot-password');
    try {
      final resp = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email}))
          .timeout(timeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Reset password using the token (6-digit code) received via email.
  /// Returns a map with 'success' (bool) and optional 'error' message.
  Future<Map<String, dynamic>> resetPassword(
    String email,
    String token,
    String newPassword, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/auth/reset-password');
    try {
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'token': token, 'newPassword': newPassword}),
          )
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        return {'success': true};
      } else {
        // Try to parse error message from body
        try {
          final body = jsonDecode(resp.body);
          final errorMsg = body['error'] ?? 'Erreur lors de la réinitialisation';
          return {'success': false, 'error': errorMsg};
        } catch (_) {
          return {'success': false, 'error': 'Erreur lors de la réinitialisation'};
        }
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: ${e.toString()}'};
    }
  }

  /// Send account setup email with password creation token (Admin/Owner)
  /// POST /auth/send-setup-email
  Future<bool> sendSetupEmail(
    String email,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/auth/send-setup-email');
    try {
      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'email': email}),
          )
          .timeout(timeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Setup initial password for a new account
  /// POST /auth/setup-password
  Future<Map<String, dynamic>> setupPassword(
    String email,
    String token,
    String password, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/auth/setup-password');
    try {
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'token': token, 'password': password}),
          )
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        return {'success': true};
      } else {
        try {
          final body = jsonDecode(resp.body);
          final errorMsg = body['error'] ?? 'Erreur lors de la configuration';
          return {'success': false, 'error': errorMsg};
        } catch (_) {
          return {'success': false, 'error': 'Erreur lors de la configuration'};
        }
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: ${e.toString()}'};
    }
  }

  /// Scan a QR code and validate gym access.
  /// Returns validation result with access status.
  /// Expected backend endpoint: POST /auth/scan-qr
  Future<Map<String, dynamic>?> scanQrCode(
    String qrData,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/auth/scan-qr');
    try {
      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'qrData': qrData}),
          )
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      } else if (resp.statusCode == 400) {
        // Return error details for invalid QR or access denied
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get QR code image for a user.
  /// Returns PNG image data as bytes.
  /// Expected backend endpoint: GET /users/{id}/qr
  Future<List<int>?> getUserQrCode(
    int userId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/users/$userId/qr');
    try {
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        return resp.bodyBytes;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Create a new admin user (Owner only).
  /// POST /users/create-admin
  /// If no password is provided, a setup email will be sent automatically
  Future<Map<String, dynamic>?> createAdmin(
    String email,
    String fullName,
    int gymId,
    String token, {
    String? password,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/users/create-admin');
    try {
      final body = {
        'email': email,
        'fullName': fullName,
        'gymId': gymId,
        if (password != null) 'password': password,
      };

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
      
      if (resp.statusCode == 201) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Create a new owner user (Owner only).
  /// POST /users/create-owner
  /// If no password is provided, a setup email will be sent automatically
  Future<Map<String, dynamic>?> createOwner(
    String email,
    String fullName,
    int gymId,
    String token, {
    String? password,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/users/create-owner');
    try {
      final body = {
        'email': email,
        'fullName': fullName,
        'gymId': gymId,
        if (password != null) 'password': password,
      };

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
      
      if (resp.statusCode == 201) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get all gyms with user counts (Owner only).
  /// Expected backend endpoint: GET /users/gyms/all
  Future<List<dynamic>?> getAllGyms(
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/users/gyms/all');
    try {
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body['gyms'] as List<dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get global statistics (Owner only).
  /// Expected backend endpoint: GET /users/stats
  Future<Map<String, dynamic>?> getGlobalStats(
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/users/stats');
    try {
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body['stats'] as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get current user profile (member or admin).
  /// Expected backend endpoint: GET /auth/me
  /// Returns user profile data with subscription info for members.
  Future<Map<String, dynamic>?> getUserProfile(
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/auth/me');
    try {
      // ignore: avoid_print
      print('ApiService.getUserProfile -> $uri');
      
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      // ignore: avoid_print
      print('ApiService.getUserProfile response status: ${resp.statusCode}');
      // ignore: avoid_print
      print('ApiService.getUserProfile response body: ${resp.body}');
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          // ignore: avoid_print
          print('ApiService.getUserProfile parsed body: $body');
          return body as Map<String, dynamic>;
        } catch (e) {
          // ignore: avoid_print
          print('ApiService.getUserProfile parse error: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('ApiService.getUserProfile exception: $e');
      return null;
    }
  }

  // ==================== GYMS MANAGEMENT ====================

  /// Create a new gym (Owner only).
  /// Expected backend endpoint: POST /gyms
  Future<Map<String, dynamic>?> createGym(
    String name,
    String address,
    String token, {
    String? phone,
    double? latitude,
    double? longitude,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/gyms');
    try {
      final body = {
        'name': name,
        'address': address,
        if (phone != null) 'phone': phone,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
      
      if (resp.statusCode == 201) {
        try {
          final responseBody = jsonDecode(resp.body);
          return responseBody as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get list of gyms filtered by permissions.
  /// Expected backend endpoint: GET /gyms
  Future<List<dynamic>?> getGyms(
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/gyms');
    try {
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body['gyms'] as List<dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get gym details by ID.
  /// Expected backend endpoint: GET /gyms/{id}
  Future<Map<String, dynamic>?> getGymById(
    int gymId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/gyms/$gymId');
    try {
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body['gym'] as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Update gym information.
  /// Expected backend endpoint: PUT /gyms/{id}
  Future<Map<String, dynamic>?> updateGym(
    int gymId,
    String token, {
    String? name,
    String? address,
    String? phone,
    double? latitude,
    double? longitude,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/gyms/$gymId');
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (address != null) body['address'] = address;
      if (phone != null) body['phone'] = phone;
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;

      final resp = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final responseBody = jsonDecode(resp.body);
          return responseBody as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Delete a gym (Owner only).
  /// Expected backend endpoint: DELETE /gyms/{id}
  Future<bool> deleteGym(
    int gymId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/gyms/$gymId');
    try {
      final resp = await http
          .delete(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ==================== OPENING HOURS ====================

  /// Set opening hours for a gym.
  /// Expected backend endpoint: POST /gyms/{id}/opening-hours
  Future<Map<String, dynamic>?> setOpeningHours(
    int gymId,
    List<Map<String, dynamic>> openingHours,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/gyms/$gymId/opening-hours');
    try {
      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(openingHours),
          )
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get opening hours for a gym.
  /// Expected backend endpoint: GET /gyms/{id}/opening-hours
  Future<List<dynamic>?> getOpeningHours(
    int gymId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/gyms/$gymId/opening-hours');
    try {
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body['openingHours'] as List<dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get all plannings for a specific member
  /// GET /plannings/member/{memberId}
  Future<Map<String, dynamic>> getMemberPlannings(
    int memberId,
    String token, {
    String? status,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    var path = '/plannings/member/$memberId';
    if (status != null) {
      path += '?status=$status';
    }
    final uri = baseUri.resolve(path);
    
    try {
      // ignore: avoid_print
      print('ApiService.getMemberPlannings -> $uri');
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load plannings: ${resp.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getting member plannings: $e');
      rethrow;
    }
  }

  /// Get next planning day for a member
  /// GET /plannings/next-day/{memberId}
  Future<Map<String, dynamic>?> getNextPlanningDay(
    int memberId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/plannings/next-day/$memberId');
    
    try {
      // ignore: avoid_print
      print('ApiService.getNextPlanningDay -> $uri');
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } else if (resp.statusCode == 204) {
        // No content - no planning for today/next days
        return null;
      } else {
        throw Exception('Failed to load next planning day: ${resp.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getting next planning day: $e');
      return null;
    }
  }

  /// Update user profile information
  /// PUT /users/{userId}
  Future<Map<String, dynamic>?> updateUserProfile(
    int userId,
    Map<String, dynamic> updateData,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/users/$userId');
    
    try {
      // ignore: avoid_print
      print('ApiService.updateUserProfile -> $uri');
      final resp = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(updateData),
          )
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (e) {
          // ignore: avoid_print
          print('Error parsing update response: $e');
          return null;
        }
      } else {
        // ignore: avoid_print
        print('Failed to update profile: ${resp.statusCode} - ${resp.body}');
        throw Exception('Failed to update profile: ${resp.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Upload profile image for user
  /// PUT /users/{userId}/profile-image
  Future<Map<String, dynamic>?> uploadProfileImage(
    int userId,
    String imageDataBase64,
    String token, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = baseUri.resolve('/users/$userId/profile-image');
    
    try {
      // ignore: avoid_print
      print('ApiService.uploadProfileImage -> $uri');
      final resp = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'imageData': imageDataBase64}),
          )
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (e) {
          // ignore: avoid_print
          print('Error parsing upload image response: $e');
          return null;
        }
      } else {
        // ignore: avoid_print
        print('Failed to upload profile image: ${resp.statusCode} - ${resp.body}');
        throw Exception('Failed to upload profile image: ${resp.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error uploading profile image: $e');
      rethrow;
    }
  }

  // ==================== FCM TOKENS ====================

  /// Update user FCM token for push notifications
  /// PUT /users/fcm-token
  /// L'utilisateur est identifié par le token JWT
  Future<Map<String, dynamic>?> updateUserFCMToken(
    int userId, // Gardé pour compatibilité mais non utilisé dans l'URL
    String fcmToken,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/users/fcm-token');
    
    try {
      // ignore: avoid_print
      print('ApiService.updateUserFCMToken -> $uri');
      // ignore: avoid_print
      print('  FCM Token: $fcmToken');
      // ignore: avoid_print
      print('  JWT: Bearer ${token.substring(0, 30)}...');
      
      // Décoder le JWT pour voir ce qu'il contient
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final payloadString = utf8.decode(base64Url.decode(normalized));
          // ignore: avoid_print
          print('  JWT Payload: $payloadString');
        }
      } catch (e) {
        // ignore: avoid_print
        print('  Erreur décodage JWT: $e');
      }
      
      final resp = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'fcmToken': fcmToken}),
          )
          .timeout(timeout);
      
      // ignore: avoid_print
      print('updateUserFCMToken status: ${resp.statusCode}');
      // ignore: avoid_print
      print('updateUserFCMToken response: ${resp.body}');
      
      if (resp.statusCode == 200) {
        try {
          return jsonDecode(resp.body) as Map<String, dynamic>;
        } catch (_) {
          return {'success': true};
        }
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error updating FCM token: $e');
      return null;
    }
  }

  /// Send push notification to specific user
  /// POST /notifications/send
  Future<bool> sendPushNotification(
    int userId,
    String title,
    String body,
    String token, {
    Map<String, dynamic>? data,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/notifications/send');
    
    try {
      final requestBody = {
        'userId': userId,
        'title': title,
        'body': body,
        if (data != null) 'data': data,
      };

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);
      
      return resp.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('Error sending push notification: $e');
      return false;
    }
  }

  /// Send push notification to multiple users
  /// POST /notifications/send-bulk
  Future<bool> sendBulkPushNotification(
    List<int> userIds,
    String title,
    String body,
    String token, {
    Map<String, dynamic>? data,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/notifications/send-bulk');
    
    try {
      final requestBody = {
        'userIds': userIds,
        'title': title,
        'body': body,
        if (data != null) 'data': data,
      };

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);
      
      return resp.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('Error sending bulk push notifications: $e');
      return false;
    }
  }

  /// Send push notification to all users in a gym
  /// POST /notifications/send-to-gym
  Future<bool> sendGymPushNotification(
    int gymId,
    String title,
    String body,
    String token, {
    Map<String, dynamic>? data,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/notifications/send-to-gym');
    
    try {
      final requestBody = {
        'gymId': gymId,
        'title': title,
        'body': body,
        if (data != null) 'data': data,
      };

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);
      
      return resp.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('Error sending gym push notification: $e');
      return false;
    }
  }

  /// Request help from gym admins for an exercise
  /// POST /plannings/request-help
  /// Notifies all admins of the member's gym about the help request
  Future<bool> requestExerciseHelp(
    String exerciseName,
    String token, {
    String? notes,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/plannings/request-help');
    
    try {
      final requestBody = {
        'exerciseName': exerciseName,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      // ignore: avoid_print
      print('ApiService.requestExerciseHelp -> $uri');
      // ignore: avoid_print
      print('  Exercise: $exerciseName');

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);
      
      // ignore: avoid_print
      print('requestExerciseHelp status: ${resp.statusCode}');
      
      return resp.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('Error requesting exercise help: $e');
      return false;
    }
  }

  /// Respond to a help request (Admin/Owner)
  /// POST /plannings/respond-help
  /// Notifies the member about the admin/owner response
  Future<bool> respondToHelpRequest(
    int memberId,
    String exerciseName,
    String response,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/plannings/respond-help');
    
    try {
      final requestBody = {
        'memberId': memberId,
        'exerciseName': exerciseName,
        'response': response, // 'coming' or 'busy'
      };

      // ignore: avoid_print
      print('ApiService.respondToHelpRequest -> $uri');
      // ignore: avoid_print
      print('  Member: $memberId, Response: $response');

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);
      
      // ignore: avoid_print
      print('respondToHelpRequest status: ${resp.statusCode}');
      
      return resp.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('Error responding to help request: $e');
      return false;
    }
  }

  // ==================== USERS MANAGEMENT ====================

  /// Get all users (Admin/Owner)
  /// GET /users
  Future<List<dynamic>?> getUsers(
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/users');
    try {
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body['users'] as List<dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get user by ID
  /// GET /users/{id}
  /// According to swagger, returns user object directly (not wrapped in "user" property)
  Future<Map<String, dynamic>?> getUserById(
    int userId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/users/$userId');
    try {
      // ignore: avoid_print
      print('ApiService.getUserById -> $uri');
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      // ignore: avoid_print
      print('getUserById status: ${resp.statusCode}');
      // ignore: avoid_print
      print('getUserById body: ${resp.body}');
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          // According to swagger, the response is the user object directly
          return body as Map<String, dynamic>;
        } catch (e) {
          // ignore: avoid_print
          print('Error parsing user response: $e');
          return null;
        }
      } else {
        // ignore: avoid_print
        print('getUserById failed with status ${resp.statusCode}: ${resp.body}');
        return null;
      }
    } catch (e) {
      // ignore: avoid_print
      print('getUserById exception: $e');
      return null;
    }
  }

  /// Create a new member (Admin/Owner)
  /// POST /users
  Future<Map<String, dynamic>?> createMember(
    String email,
    String fullName,
    int gymId,
    String token, {
    String? password,
    String? phone,
    bool sendSetupEmail = true,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/users');
    try {
      final body = {
        'email': email,
        'fullName': fullName,
        'gymId': gymId,
        'role': 'member',
        if (password != null) 'password': password,
        if (phone != null) 'phone': phone,
        'sendSetupEmail': sendSetupEmail,
      };

      // ignore: avoid_print
      print('ApiService.createMember -> $uri');
      // ignore: avoid_print
      print('  Body: $body');

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
      
      // ignore: avoid_print
      print('createMember status: ${resp.statusCode}');
      // ignore: avoid_print
      print('createMember response: ${resp.body}');
      
      if (resp.statusCode == 201) {
        try {
          final responseBody = jsonDecode(resp.body);
          return responseBody as Map<String, dynamic>;
        } catch (e) {
          // ignore: avoid_print
          print('Error parsing response: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error creating member: $e');
      return null;
    }
  }

  /// Delete a user (Admin/Owner)
  /// DELETE /users/{id}
  Future<bool> deleteUser(
    int userId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/users/$userId');
    try {
      final resp = await http
          .delete(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Get all members of a specific gym (Admin/Owner)
  /// GET /users/gym/{gymId}/members
  /// Returns members with subscription status and recent payments
  Future<List<dynamic>?> getGymMembers(
    int gymId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/users/gym/$gymId/members');
    try {
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body['members'] as List<dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ==================== SUBSCRIPTIONS MANAGEMENT ====================

  /// Get subscription types
  /// GET /subscription-types
  Future<List<dynamic>?> getSubscriptionTypes(
    {bool includeInactive = false,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    var path = '/subscription-types';
    if (includeInactive) {
      path += '?includeInactive=true';
    }
    final uri = baseUri.resolve(path);
    
    try {
      // ignore: avoid_print
      print('🔍 Fetching subscription types from: $uri');
      
      final resp = await http.get(uri).timeout(timeout);
      
      // ignore: avoid_print
      print('📥 Response status: ${resp.statusCode}');
      // ignore: avoid_print
      print('📥 Response body type: ${resp.body.runtimeType}');
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          
          // ignore: avoid_print
          print('🔍 Decoded body type: ${body.runtimeType}');
          // ignore: avoid_print
          print('🔍 Body keys: ${body is Map ? body.keys.toList() : "not a map"}');
          
          // Check if the body is a Map with 'subscriptionTypes' key
          if (body is Map && body.containsKey('subscriptionTypes')) {
            final types = body['subscriptionTypes'] as List<dynamic>;
            // ignore: avoid_print
            print('✅ Found ${types.length} subscription types');
            return types;
          } else if (body is List) {
            // API might return array directly
            // ignore: avoid_print
            print('✅ Got direct array with ${body.length} subscription types');
            return body;
          } else {
            // ignore: avoid_print
            print('❌ Unexpected response structure: $body');
            return null;
          }
        } catch (e) {
          // ignore: avoid_print
          print('❌ Error parsing response: $e');
          return null;
        }
      } else {
        // ignore: avoid_print
        print('❌ Non-200 status code: ${resp.statusCode}');
        return null;
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Exception fetching subscription types: $e');
      return null;
    }
  }

  /// Get subscription type details by ID
  /// GET /subscription-types/{id}
  Future<Map<String, dynamic>?> getSubscriptionTypeById(
    int subscriptionTypeId, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/subscription-types/$subscriptionTypeId');
    try {
      final resp = await http.get(uri).timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get subscriptions by type (Admin/Owner)
  /// GET /subscription-types/{id}/subscriptions
  Future<List<dynamic>?> getSubscriptionsByType(
    int subscriptionTypeId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/subscription-types/$subscriptionTypeId/subscriptions');
    try {
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body['subscriptions'] as List<dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Create a subscription type (Owner only)
  /// POST /subscription-types
  Future<Map<String, dynamic>?> createSubscriptionType(
    String name,
    double monthlyPrice,
    String token, {
    String? description,
    List<String>? features,
    bool isActive = true,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/subscription-types');
    try {
      final body = {
        'name': name,
        'monthlyPrice': monthlyPrice,
        'isActive': isActive,
        if (description != null) 'description': description,
        if (features != null) 'features': features,
      };

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
      
      if (resp.statusCode == 201) {
        try {
          final responseBody = jsonDecode(resp.body);
          return responseBody as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Update subscription type (Owner only)
  /// PUT /subscription-types/{id}
  Future<Map<String, dynamic>?> updateSubscriptionType(
    int subscriptionTypeId,
    String token, {
    String? name,
    String? description,
    double? monthlyPrice,
    List<String>? features,
    bool? isActive,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/subscription-types/$subscriptionTypeId');
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (monthlyPrice != null) body['monthlyPrice'] = monthlyPrice;
      if (features != null) body['features'] = features;
      if (isActive != null) body['isActive'] = isActive;

      final resp = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final responseBody = jsonDecode(resp.body);
          return responseBody as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Deactivate subscription type (Owner only)
  /// DELETE /subscription-types/{id}
  Future<bool> deleteSubscriptionType(
    int subscriptionTypeId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/subscription-types/$subscriptionTypeId');
    try {
      final resp = await http
          .delete(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Get subscriptions for a member
  /// GET /subscriptions/member/{memberId}
  Future<List<dynamic>?> getMemberSubscriptions(
    int memberId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/subscriptions/member/$memberId');
    try {
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body['subscriptions'] as List<dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get subscription details by ID
  /// GET /subscriptions/{id}
  Future<Map<String, dynamic>?> getSubscriptionById(
    int subscriptionId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/subscriptions/$subscriptionId');
    try {
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Create a new subscription
  /// POST /subscriptions
  /// Creates an annual subscription with 12 monthly payments automatically
  /// The API accepts only memberId and subscriptionTypeId
  Future<Map<String, dynamic>?> createSubscription(
    int memberId,
    int subscriptionTypeId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/subscriptions');
    try {
      // According to API spec, only send memberId and subscriptionTypeId
      final body = {
        'memberId': memberId,
        'subscriptionTypeId': subscriptionTypeId,
      };

      // ignore: avoid_print
      print('ApiService.createSubscription -> $uri');
      // ignore: avoid_print
      print('Body: $body');

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
      
      // ignore: avoid_print
      print('createSubscription status: ${resp.statusCode}');
      // ignore: avoid_print
      print('createSubscription body: ${resp.body}');
      
      if (resp.statusCode == 201) {
        try {
          final responseBody = jsonDecode(resp.body);
          return responseBody as Map<String, dynamic>;
        } catch (e) {
          // ignore: avoid_print
          print('Error parsing subscription response: $e');
          return null;
        }
      } else {
        // ignore: avoid_print
        print('createSubscription failed with status ${resp.statusCode}: ${resp.body}');
        return null;
      }
    } catch (e) {
      // ignore: avoid_print
      print('createSubscription exception: $e');
      return null;
    }
  }

  /// Acknowledge payment and activate subscription
  /// POST /subscriptions/payments/{paymentId}/acknowledge
  /// Marks payment as completed and automatically activates subscription if pending
  Future<Map<String, dynamic>?> acknowledgePayment(
    int paymentId,
    String paymentMethod,
    String token, {
    String? transactionId,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/subscriptions/payments/$paymentId/acknowledge');
    try {
      final body = {
        'paymentMethod': paymentMethod,
        if (transactionId != null) 'transactionId': transactionId,
      };

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final responseBody = jsonDecode(resp.body);
          return responseBody as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Mark payment as completed (simple version)
  /// POST /subscriptions/payments/{paymentId}/complete
  /// Only updates payment status without subscription logic
  /// For subscription payments, prefer using acknowledgePayment instead
  Future<Map<String, dynamic>?> completePayment(
    int paymentId,
    String paymentMethod,
    String token, {
    String? transactionId,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/subscriptions/payments/$paymentId/complete');
    try {
      final body = {
        'paymentMethod': paymentMethod,
        if (transactionId != null) 'transactionId': transactionId,
      };

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final responseBody = jsonDecode(resp.body);
          return responseBody as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get upcoming payments (Admin/Owner)
  /// GET /subscriptions/payments/upcoming
  /// Returns payments due in the next 7 days
  Future<List<dynamic>?> getUpcomingPayments(
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/subscriptions/payments/upcoming');
    try {
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body['payments'] as List<dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ==================== PLANNINGS MANAGEMENT ====================

  /// Get all exercises
  /// GET /plannings/exercises
  Future<List<dynamic>?> getExercises(
    String token, {
    String? category,
    String? difficulty,
    String? muscleGroup,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    var path = '/plannings/exercises';
    final queryParams = <String>[];
    if (category != null) queryParams.add('category=$category');
    if (difficulty != null) queryParams.add('difficulty=$difficulty');
    if (muscleGroup != null) queryParams.add('muscleGroup=$muscleGroup');
    
    if (queryParams.isNotEmpty) {
      path += '?${queryParams.join('&')}';
    }
    
    final uri = baseUri.resolve(path);
    try {
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body['exercises'] as List<dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get all plannings
  /// GET /plannings
  Future<List<dynamic>?> getPlannings(
    String token, {
    int? memberId,
    String? status,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    var path = '/plannings';
    final queryParams = <String>[];
    if (memberId != null) queryParams.add('memberId=$memberId');
    if (status != null) queryParams.add('status=$status');
    
    if (queryParams.isNotEmpty) {
      path += '?${queryParams.join('&')}';
    }
    
    final uri = baseUri.resolve(path);
    try {
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body['plannings'] as List<dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Create a new planning
  /// POST /plannings
  Future<Map<String, dynamic>?> createPlanning(
    int memberId,
    String title,
    String startDate,
    String endDate,
    String token, {
    String? description,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/plannings');
    try {
      final body = {
        'memberId': memberId,
        'title': title,
        'startDate': startDate,
        'endDate': endDate,
        if (description != null) 'description': description,
      };

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
      
      if (resp.statusCode == 201) {
        try {
          final responseBody = jsonDecode(resp.body);
          return responseBody as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Add exercise to planning day
  /// POST /plannings/{planningId}/days/{dayOfWeek}/exercises
  Future<Map<String, dynamic>?> addExerciseToPlanningDay(
    int planningId,
    int dayOfWeek,
    int exerciseId,
    String token, {
    int? sets,
    int? reps,
    int? duration,
    double? weight,
    int? restTime,
    String? notes,
    int? order,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/plannings/$planningId/days/$dayOfWeek/exercises');
    try {
      final body = {
        'exerciseId': exerciseId,
        if (sets != null) 'sets': sets,
        if (reps != null) 'reps': reps,
        if (duration != null) 'duration': duration,
        if (weight != null) 'weight': weight,
        if (restTime != null) 'restTime': restTime,
        if (notes != null) 'notes': notes,
        if (order != null) 'order': order,
      };

      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
      
      if (resp.statusCode == 201) {
        try {
          final responseBody = jsonDecode(resp.body);
          return responseBody as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Delete a planning
  /// DELETE /plannings/{id}
  Future<bool> deletePlanning(
    int planningId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/plannings/$planningId');
    try {
      // ignore: avoid_print
      print('ApiService.deletePlanning -> $uri');
      
      final resp = await http
          .delete(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      
      // ignore: avoid_print
      print('deletePlanning status: ${resp.statusCode}');
      
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting planning: $e');
      return false;
    }
  }
}
