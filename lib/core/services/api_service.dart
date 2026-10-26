import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Simple API client for the Team Oustad Express+Prisma backend.
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

  // Singleton instance
  static ApiService? _instance;
  static bool _initialized = false;

  ApiService(this.baseUri);

  /// Returns the singleton instance of ApiService.
  /// Creates it once on first call, then reuses the same instance.
  factory ApiService.fromEnv() {
    if (_instance != null) {
      return _instance!;
    }

    String apiUrl;

    // Priority 1: Check for custom API_BASE_URL (optional override)
    const customUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

    if (customUrl.isNotEmpty) {
      apiUrl = customUrl;
      if (!_initialized) {
        // ignore: avoid_print
        debugPrint('🌐 ApiService: Using custom API_BASE_URL → $apiUrl');
      }
    } else {
      // Priority 2: Use ENVIRONMENT variable with AppConfig
      final config = AppConfig.fromEnvironment();
      apiUrl = config.apiBaseUrl;
      if (!_initialized) {
        // ignore: avoid_print
        debugPrint(
          '🌐 ApiService: Using ${config.environment} environment → $apiUrl',
        );
      }
    }

    _instance = ApiService(Uri.parse(apiUrl));
    _initialized = true;
    return _instance!;
  }

  /// Reset the singleton (useful for testing or environment changes)
  static void reset() {
    _instance = null;
    _initialized = false;
  }

  /// Health check - returns true when backend is reachable and returns 200.
  Future<bool> healthCheck({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/health');
    try {
      // Helpful debug log while developing
      // ignore: avoid_print
      debugPrint(
        'ApiService.healthCheck -> $uri (timeout: ${timeout.inSeconds}s)',
      );
      final resp = await http.get(uri);
      return resp.statusCode == 200;
    } catch (exception) {
      // ignore: avoid_print
      debugPrint('Health check failed: $exception');
      return false;
    }
  }

  /// Clean string by removing null bytes and other invalid characters
  String _cleanString(String input) {
    // Remove null bytes and other control characters except newlines/tabs
    return input
        .replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F]'), '')
        .trim();
  }

  /// Attempt login against the API. Returns a map with token and user info on success,
  /// or null on failure. The backend returns JSON like:
  /// {"token":"...", "user": {"id":"...", "email":"...", "fullName":"...", "gymId":"...", "type":"admin|member|owner"}}
  /// Supports login with email OR phoneNumber
  ///
  /// [kiosk] ouvre une session borne (`client: "kiosk"`), distincte de celle
  /// de l'app : elle ne déconnecte pas le téléphone. Un rôle non autorisé au
  /// kiosk (coach, member) renvoie `{'error': 'kiosk_forbidden_role'}`.
  Future<Map<String, dynamic>?> login(
    String emailOrPhone,
    String password, {
    bool kiosk = false,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/auth/login');
    try {
      // Clean input to remove null bytes and invalid characters
      final cleanEmailOrPhone = _cleanString(emailOrPhone);
      final cleanPassword = _cleanString(password);

      // Determine if input is email or phone number
      final isEmail = cleanEmailOrPhone.contains('@');
      final requestBody = isEmail
          ? {'email': cleanEmailOrPhone, 'password': cleanPassword}
          : {'phoneNumber': cleanEmailOrPhone, 'password': cleanPassword};
      if (kiosk) requestBody['client'] = 'kiosk';

      // ignore: avoid_print
      debugPrint(
        'ApiService.login -> $uri with ${isEmail ? "email" : "phoneNumber"}: $cleanEmailOrPhone',
      );

      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(timeout);

      // ignore: avoid_print
      debugPrint('ApiService.login response status: ${resp.statusCode}');

      if (resp.statusCode == 403) {
        try {
          final body = jsonDecode(resp.body);
          if (body is Map && body['error'] == 'kiosk_forbidden_role') {
            return {'error': 'kiosk_forbidden_role'};
          }
        } catch (_) {}
        return null;
      }

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
              debugPrint(
                'ApiService.login extracted type from user object: $userType',
              );
            } else if (user['role'] != null) {
              userType = user['role'] as String;
              // ignore: avoid_print
              debugPrint(
                'ApiService.login extracted role from user object: $userType',
              );
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
                  final payloadString = utf8.decode(
                    base64Url.decode(normalized),
                  );
                  final payloadMap =
                      jsonDecode(payloadString) as Map<String, dynamic>;

                  if (payloadMap['type'] != null) {
                    userType = payloadMap['type'] as String;
                    // ignore: avoid_print
                    debugPrint(
                      'ApiService.login extracted type from JWT: $userType',
                    );
                  }
                }
              } catch (jwtError) {
                // ignore: avoid_print
                debugPrint('ApiService.login JWT decode error: $jwtError');
              }
            }

            // ignore: avoid_print
            debugPrint('ApiService.login final userType: $userType');

            // Extract onboarding status from member object or body root
            // true = needs onboarding, false = onboarding completed
            // Check multiple locations: body.onboarding, user.member.onboarding, user.onboarding
            bool onboarding = true; // Default: needs onboarding
            if (body['onboarding'] != null) {
              onboarding = body['onboarding'] as bool;
              debugPrint(
                'ApiService.login onboarding from body root: $onboarding',
              );
            } else if (user['member'] != null &&
                user['member']['onboarding'] != null) {
              onboarding = user['member']['onboarding'] as bool;
              debugPrint(
                'ApiService.login onboarding from user.member: $onboarding',
              );
            } else if (user['onboarding'] != null) {
              onboarding = user['onboarding'] as bool;
              debugPrint('ApiService.login onboarding from user: $onboarding');
            } else {
              // Default to true if not provided (needs onboarding for new members)
              debugPrint(
                'ApiService.login onboarding not found, defaulting to: true (needs onboarding)',
              );
            }

            // Construire fullName depuis firstName/lastName ou utiliser fullName si présent
            final String fullName;
            if (user['fullName'] != null) {
              fullName = user['fullName'].toString();
            } else {
              final firstName = user['firstName']?.toString() ?? '';
              final lastName = user['lastName']?.toString() ?? '';
              fullName = '$firstName $lastName'.trim();
            }

            return {
              'token': body['token'] as String,
              'userType': userType,
              'userId': user['id'].toString(),
              'email': user['email'] as String,
              'fullName': fullName,
              'gymId': user['gymId']?.toString(),
              'onboarding': onboarding,
            };
          }
        } catch (e) {
          // ignore: avoid_print
          debugPrint('ApiService.login parse error: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      debugPrint('ApiService.login exception: $e');
      return null;
    }
  }

  /// Verify a JWT locally by decoding and checking expiration.
  /// Returns true when token is valid and not expired.
  /// Lit un claim texte du payload JWT (sans vérifier la signature : la
  /// valeur sert à l'affichage, le serveur reste seul juge des droits).
  static String? decodeJwtClaim(String token, String claim) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final value = (jsonDecode(payload) as Map<String, dynamic>)[claim];
      return value is String ? value : null;
    } catch (_) {
      return null;
    }
  }

  bool verifyToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(payloadString) as Map<String, dynamic>;

      // Check expiration
      final exp = payloadMap['exp'] as int?;
      if (exp == null) return false;

      final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isBefore(expDate);
    } catch (_) {
      return false;
    }
  }

  /// Request a password reset code for the given email.
  /// Returns true if the request was successful (note: backend doesn't reveal if email exists).
  Future<bool> forgotPassword(
    String email, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/auth/forgot-password');
    try {
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
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
            body: jsonEncode({
              'email': email,
              'token': token,
              'newPassword': newPassword,
            }),
          )
          .timeout(timeout);

      if (resp.statusCode == 200) {
        return {'success': true};
      } else {
        // Try to parse error message from body
        try {
          final body = jsonDecode(resp.body);
          final errorMsg =
              body['error'] ?? 'Erreur lors de la réinitialisation';
          return {'success': false, 'error': errorMsg};
        } catch (_) {
          return {
            'success': false,
            'error': 'Erreur lors de la réinitialisation',
          };
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

  /// Check if a phone number exists and has a password configured
  /// POST /auth/check-phone
  Future<Map<String, dynamic>> checkPhone(
    String phoneNumber, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/auth/check-phone');
    try {
      debugPrint(
        'ApiService.checkPhone -> $uri with phoneNumber: $phoneNumber',
      );

      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phoneNumber': phoneNumber}),
          )
          .timeout(timeout);

      debugPrint('ApiService.checkPhone response status: ${resp.statusCode}');
      debugPrint('ApiService.checkPhone response body: ${resp.body}');

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        // exists: true, hasPassword: true/false, user data
        return {
          'success': true,
          'exists': body['exists'] ?? false,
          'hasPassword': body['hasPassword'] ?? false,
          'user': body['user'],
        };
      } else if (resp.statusCode == 409) {
        // Phone exists with password
        final body = jsonDecode(resp.body);
        return {
          'success': true,
          'exists': true,
          'hasPassword': true,
          'message': body['message'],
        };
      } else if (resp.statusCode == 404) {
        // Phone not found
        return {'success': true, 'exists': false, 'hasPassword': false};
      } else {
        final body = jsonDecode(resp.body);
        return {
          'success': false,
          'error': body['error'] ?? 'Erreur de vérification',
        };
      }
    } catch (e) {
      debugPrint('ApiService.checkPhone exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Setup initial password for a new account
  /// POST /auth/setup-password
  /// Supports both email and phoneNumber
  Future<Map<String, dynamic>> setupPassword(
    String emailOrPhone,
    String token,
    String password, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/auth/setup-password');
    try {
      // Determine if input is email or phone number
      final isEmail = emailOrPhone.contains('@');
      final requestBody = isEmail
          ? {'email': emailOrPhone, 'token': token, 'password': password}
          : {'phoneNumber': emailOrPhone, 'token': token, 'password': password};

      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
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
      } else if (resp.statusCode == 400 ||
          resp.statusCode == 403 ||
          resp.statusCode == 404) {
        // Détail du refus (QR invalide, sans abonnement, autre salle,
        // membre inconnu)
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

  /// Check-in via QR code scan.
  /// Returns check-in result with member info and updated quota.
  /// Expected backend endpoint: POST /check-in/scan
  Future<Map<String, dynamic>?> checkInScan({
    required String qrCode,
    required int gymId,
    required String token,
    String? notes,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/check-in/scan');
    try {
      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'qrCode': qrCode,
              'gymId': gymId,
              'notes': ?notes,
            }),
          )
          .timeout(timeout);

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      } else if (resp.statusCode == 400 || resp.statusCode == 403) {
        // Return error details
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error in checkInScan: $e');
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
    String firstName,
    String lastName,
    String address,
    int gymId,
    String token, {
    String? password,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/users/create-admin');
    try {
      final body = {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'address': address,
        'role': 'admin',
        'gymId': gymId,
        'password': ?password,
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
    String firstName,
    String lastName,
    int gymId,
    String token, {
    String? password,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/users/create-owner');
    try {
      final body = {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'gymId': gymId,
        'password': ?password,
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
      debugPrint('ApiService.getUserProfile -> $uri');

      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);

      // ignore: avoid_print
      debugPrint(
        'ApiService.getUserProfile response status: ${resp.statusCode}',
      );
      // ignore: avoid_print
      debugPrint('ApiService.getUserProfile response body: ${resp.body}');

      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          // ignore: avoid_print
          debugPrint('ApiService.getUserProfile parsed body: $body');
          return body as Map<String, dynamic>;
        } catch (e) {
          // ignore: avoid_print
          debugPrint('ApiService.getUserProfile parse error: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      debugPrint('ApiService.getUserProfile exception: $e');
      return null;
    }
  }

  // ==================== MEMBERS MANAGEMENT ====================

  /// Update member profile (birthDate, phone, profession, fitnessLevel, profileImage).
  Future<Map<String, dynamic>?> updateMemberProfile(
    int memberId,
    Map<String, dynamic> profileData,
    String token, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = baseUri.resolve('/members/$memberId/profile');
    try {
      // ignore: avoid_print
      debugPrint('ApiService.updateMemberProfile -> $uri');
      // ignore: avoid_print
      debugPrint('ApiService.updateMemberProfile data: $profileData');

      final resp = await http
          .put(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(profileData),
          )
          .timeout(timeout);

      // ignore: avoid_print
      debugPrint(
        'ApiService.updateMemberProfile response status: ${resp.statusCode}',
      );
      // ignore: avoid_print
      debugPrint('ApiService.updateMemberProfile response body: ${resp.body}');

      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (e) {
          // ignore: avoid_print
          debugPrint('ApiService.updateMemberProfile parse error: $e');
          return null;
        }
      }
      return {'error': 'Status code: ${resp.statusCode}'};
    } catch (e) {
      // ignore: avoid_print
      debugPrint('ApiService.updateMemberProfile exception: $e');
      return {'error': e.toString()};
    }
  }

  /// Create member measurement (weight, waist, height).
  Future<Map<String, dynamic>?> createMemberMeasurement(
    int memberId,
    Map<String, dynamic> measurementData,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/members/$memberId/measurements');
    try {
      // ignore: avoid_print
      debugPrint('ApiService.createMemberMeasurement -> $uri');
      // ignore: avoid_print
      debugPrint('ApiService.createMemberMeasurement data: $measurementData');

      final resp = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(measurementData),
          )
          .timeout(timeout);

      // ignore: avoid_print
      debugPrint(
        'ApiService.createMemberMeasurement response status: ${resp.statusCode}',
      );

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (e) {
          // ignore: avoid_print
          debugPrint('ApiService.createMemberMeasurement parse error: $e');
          return null;
        }
      }
      return {'error': 'Status code: ${resp.statusCode}'};
    } catch (e) {
      // ignore: avoid_print
      debugPrint('ApiService.createMemberMeasurement exception: $e');
      return {'error': e.toString()};
    }
  }

  /// Get member goals.
  Future<List<dynamic>> getMemberGoals(
    int memberId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/members/$memberId/goals');
    try {
      // ignore: avoid_print
      debugPrint('ApiService.getMemberGoals -> $uri');

      final resp = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(timeout);

      // ignore: avoid_print
      debugPrint(
        'ApiService.getMemberGoals response status: ${resp.statusCode}',
      );

      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          if (body is Map && body['goals'] is List) {
            return body['goals'] as List<dynamic>;
          }
          return [];
        } catch (e) {
          // ignore: avoid_print
          debugPrint('ApiService.getMemberGoals parse error: $e');
          return [];
        }
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      debugPrint('ApiService.getMemberGoals exception: $e');
      return [];
    }
  }

  /// Create member goal (title, description, startWeight, startWaist).
  Future<Map<String, dynamic>?> createMemberGoal(
    int memberId,
    Map<String, dynamic> goalData,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/members/$memberId/goals');
    try {
      // ignore: avoid_print
      debugPrint('ApiService.createMemberGoal -> $uri');
      // ignore: avoid_print
      debugPrint('ApiService.createMemberGoal data: $goalData');

      final resp = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(goalData),
          )
          .timeout(timeout);

      // ignore: avoid_print
      debugPrint(
        'ApiService.createMemberGoal response status: ${resp.statusCode}',
      );

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (e) {
          // ignore: avoid_print
          debugPrint('ApiService.createMemberGoal parse error: $e');
          return null;
        }
      }
      return {'error': 'Status code: ${resp.statusCode}'};
    } catch (e) {
      // ignore: avoid_print
      debugPrint('ApiService.createMemberGoal exception: $e');
      return {'error': e.toString()};
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
    String? description,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/gyms');
    try {
      final body = {
        'name': name,
        'address': address,
        'phone': ?phone,
        'description': ?description,
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
    String? description,
    bool? isPublished,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/gyms/$gymId');
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (address != null) body['address'] = address;
      if (phone != null) body['phone'] = phone;
      if (description != null) body['description'] = description;
      if (isPublished != null) body['isPublished'] = isPublished;

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
      debugPrint('ApiService.getMemberPlannings -> $uri');
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
      debugPrint('Error getting member plannings: $e');
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
      debugPrint('ApiService.getNextPlanningDay -> $uri');
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
      debugPrint('Error getting next planning day: $e');
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
      debugPrint('ApiService.updateUserProfile -> $uri');
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
          debugPrint('Error parsing update response: $e');
          return null;
        }
      } else {
        // ignore: avoid_print
        debugPrint(
          'Failed to update profile: ${resp.statusCode} - ${resp.body}',
        );
        throw Exception('Failed to update profile: ${resp.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error updating user profile: $e');
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
      debugPrint('ApiService.uploadProfileImage -> $uri');
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
          debugPrint('Error parsing upload image response: $e');
          return null;
        }
      } else {
        // ignore: avoid_print
        debugPrint(
          'Failed to upload profile image: ${resp.statusCode} - ${resp.body}',
        );
        throw Exception('Failed to upload profile image: ${resp.statusCode}');
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error uploading profile image: $e');
      rethrow;
    }
  }

  // ==================== FCM TOKENS ====================

  /// Update user FCM token for push notifications
  /// PUT /users/fcm-token
  /// L'utilisateur est identifié par le token JWT
  Future<Map<String, dynamic>?> updateUserFCMToken(
    int? userId, // Gardé pour compatibilité mais non utilisé dans l'URL
    String fcmToken,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/users/fcm-token');

    try {
      // ignore: avoid_print
      debugPrint('ApiService.updateUserFCMToken -> $uri');

      final resp = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'id': ?userId, 'fcmToken': fcmToken}),
          )
          .timeout(timeout);

      // ignore: avoid_print
      debugPrint('updateUserFCMToken status: ${resp.statusCode}');

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
      debugPrint('❌ Error updating FCM token: $e');
      return null;
    }
  }

  /// Remove user FCM token (logout from notifications)
  /// DELETE /users/fcm-token
  Future<bool> removeUserFCMToken(
    String token, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final uri = baseUri.resolve('/users/fcm-token');
    try {
      final resp = await http
          .delete(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      return resp.statusCode == 200;
    } catch (_) {
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
      debugPrint('ApiService.requestExerciseHelp -> $uri');
      // ignore: avoid_print
      debugPrint('  Exercise: $exerciseName');

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
      debugPrint('requestExerciseHelp status: ${resp.statusCode}');

      return resp.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error requesting exercise help: $e');
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
      debugPrint('ApiService.respondToHelpRequest -> $uri');
      // ignore: avoid_print
      debugPrint('  Member: $memberId, Response: $response');

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
      debugPrint('respondToHelpRequest status: ${resp.statusCode}');

      return resp.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error responding to help request: $e');
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
      debugPrint('ApiService.getUsers -> $uri');
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);

      debugPrint('ApiService.getUsers status: ${resp.statusCode}');

      // Parse and display body without heavy qrCode data
      try {
        final body = jsonDecode(resp.body);
        if (body is List) {
          debugPrint('ApiService.getUsers body: ${body.length} users');
          for (var i = 0; i < body.length && i < 5; i++) {
            final user = body[i] as Map<String, dynamic>;
            final userCopy = Map<String, dynamic>.from(user);
            if (userCopy.containsKey('qrCode')) {
              userCopy['qrCode'] =
                  '(${userCopy['qrCode'].toString().length} bytes)';
            }
            debugPrint('  User $i: $userCopy');
          }
        } else {
          debugPrint('ApiService.getUsers body: $body');
        }
      } catch (e) {
        debugPrint(
          'ApiService.getUsers body (raw): ${resp.body.substring(0, resp.body.length > 500 ? 500 : resp.body.length)}...',
        );
      }

      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          // Support both formats: {users: [...]} or [...]
          if (body is List) {
            return body;
          } else if (body is Map && body['users'] is List) {
            return body['users'] as List<dynamic>;
          }
          return null;
        } catch (e) {
          debugPrint('ApiService.getUsers parse error: $e');
          return null;
        }
      }
      debugPrint('ApiService.getUsers failed with status: ${resp.statusCode}');
      return null;
    } catch (e) {
      debugPrint('ApiService.getUsers exception: $e');
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
      debugPrint('ApiService.getUserById -> $uri');
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);

      // ignore: avoid_print
      debugPrint('getUserById status: ${resp.statusCode}');
      // ignore: avoid_print
      debugPrint('getUserById body: ${resp.body}');

      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          // According to swagger, the response is the user object directly
          return body as Map<String, dynamic>;
        } catch (e) {
          // ignore: avoid_print
          debugPrint('Error parsing user response: $e');
          return null;
        }
      } else {
        // ignore: avoid_print
        debugPrint(
          'getUserById failed with status ${resp.statusCode}: ${resp.body}',
        );
        return null;
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('getUserById exception: $e');
      return null;
    }
  }

  /// Create a new member (Admin/Owner)
  /// POST /users
  Future<Map<String, dynamic>?> createMember(
    String email,
    String firstName,
    String lastName,
    int gymId,
    String token, {
    String? password,
    String? phone,
    bool shouldSendSetupEmail = false,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/users');
    try {
      final body = {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': 'member',
        'gymId': gymId,
        'sendSetupEmail': shouldSendSetupEmail,
        'password': ?password,
        'phoneNumber': ?phone,
      };

      // ignore: avoid_print
      debugPrint('ApiService.createMember -> $uri');
      // ignore: avoid_print
      debugPrint('  Body: $body');

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
      debugPrint('createMember status: ${resp.statusCode}');
      // ignore: avoid_print
      debugPrint('createMember response: ${resp.body}');

      if (resp.statusCode == 201) {
        try {
          final responseBody = jsonDecode(resp.body);
          return responseBody['user'] as Map<String, dynamic>?;
        } catch (e) {
          // ignore: avoid_print
          debugPrint('Error parsing response: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error creating member: $e');
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
  Future<List<dynamic>?> getSubscriptionTypes({
    bool includeInactive = false,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    var path = '/subscription-types';
    if (includeInactive) {
      path += '?includeInactive=true';
    }
    final uri = baseUri.resolve(path);

    try {
      // ignore: avoid_print
      debugPrint('🔍 Fetching subscription types from: $uri');

      final resp = await http.get(uri).timeout(timeout);

      // ignore: avoid_print
      debugPrint('📥 Response status: ${resp.statusCode}');
      // ignore: avoid_print
      debugPrint('📥 Response body type: ${resp.body.runtimeType}');

      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);

          // ignore: avoid_print
          debugPrint('🔍 Decoded body type: ${body.runtimeType}');
          // ignore: avoid_print
          debugPrint(
            '🔍 Body keys: ${body is Map ? body.keys.toList() : "not a map"}',
          );

          // Check if the body is a Map with 'subscriptionTypes' key
          if (body is Map && body.containsKey('subscriptionTypes')) {
            final types = body['subscriptionTypes'] as List<dynamic>;
            // ignore: avoid_print
            debugPrint('✅ Found ${types.length} subscription types');
            return types;
          } else if (body is List) {
            // API might return array directly
            // ignore: avoid_print
            debugPrint(
              '✅ Got direct array with ${body.length} subscription types',
            );
            return body;
          } else {
            // ignore: avoid_print
            debugPrint('❌ Unexpected response structure: $body');
            return null;
          }
        } catch (e) {
          // ignore: avoid_print
          debugPrint('❌ Error parsing response: $e');
          return null;
        }
      } else {
        // ignore: avoid_print
        debugPrint('❌ Non-200 status code: ${resp.statusCode}');
        return null;
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('❌ Exception fetching subscription types: $e');
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
    final uri = baseUri.resolve(
      '/subscription-types/$subscriptionTypeId/subscriptions',
    );
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
        'description': ?description,
        'features': ?features,
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
      debugPrint('ApiService.createSubscription -> $uri');
      // ignore: avoid_print
      debugPrint('Body: $body');

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
      debugPrint('createSubscription status: ${resp.statusCode}');
      // ignore: avoid_print
      debugPrint('createSubscription body: ${resp.body}');

      if (resp.statusCode == 201) {
        try {
          final responseBody = jsonDecode(resp.body);
          return responseBody as Map<String, dynamic>;
        } catch (e) {
          // ignore: avoid_print
          debugPrint('Error parsing subscription response: $e');
          return null;
        }
      } else {
        // ignore: avoid_print
        debugPrint(
          'createSubscription failed with status ${resp.statusCode}: ${resp.body}',
        );
        return null;
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('createSubscription exception: $e');
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
    final uri = baseUri.resolve(
      '/subscriptions/payments/$paymentId/acknowledge',
    );
    try {
      final body = {
        'paymentMethod': paymentMethod,
        'transactionId': ?transactionId,
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
        'transactionId': ?transactionId,
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

  // ==================== BANNERS ====================

  /// Get all banners with optional filters
  /// GET /banners
  Future<List<dynamic>?> getBanners({
    String? token,
    String? type,
    int? gymId,
    bool activeOnly = true,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final queryParams = <String, String>{};
    // Toujours envoyer activeOnly pour être explicite avec le backend
    queryParams['activeOnly'] = activeOnly.toString();
    if (type != null) queryParams['type'] = type;
    if (gymId != null) queryParams['gymId'] = gymId.toString();

    final uri = baseUri
        .resolve('/banners')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    try {
      debugPrint('ApiService.getBanners -> $uri');

      final headers = <String, String>{};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final resp = await http
          .get(uri, headers: headers.isNotEmpty ? headers : null)
          .timeout(timeout);

      debugPrint('ApiService.getBanners response: ${resp.statusCode}');
      debugPrint('ApiService.getBanners body: ${resp.body}');

      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          // Le serveur renvoie un tableau brut, le swagger annonce
          // { banners: [...] } : on accepte les deux.
          final banners = body is List
              ? body
              : (body as Map<String, dynamic>)['banners'] as List<dynamic>;
          debugPrint('ApiService.getBanners found ${banners.length} banners');
          return banners;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting banners: $e');
      return null;
    }
  }

  /// Get a single banner by ID
  /// GET /banners/{id}
  Future<Map<String, dynamic>?> getBanner(
    int bannerId, {
    String? token,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/banners/$bannerId');
    try {
      final headers = <String, String>{};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final resp = await http
          .get(uri, headers: headers.isNotEmpty ? headers : null)
          .timeout(timeout);
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting banner $bannerId: $e');
      return null;
    }
  }

  /// Create a new banner
  /// POST /banners
  Future<Map<String, dynamic>?> createBanner(
    String token,
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = baseUri.resolve('/banners');
    try {
      debugPrint('ApiService.createBanner -> $uri');
      final resp = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(data),
          )
          .timeout(timeout);

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to create banner: ${resp.statusCode}');
    } catch (e) {
      debugPrint('Error creating banner: $e');
      rethrow;
    }
  }

  /// Update a banner
  /// PUT /banners/{id}
  Future<Map<String, dynamic>?> updateBanner(
    String token,
    int bannerId,
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = baseUri.resolve('/banners/$bannerId');
    try {
      debugPrint('ApiService.updateBanner -> $uri');
      final resp = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(data),
          )
          .timeout(timeout);

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to update banner: ${resp.statusCode}');
    } catch (e) {
      debugPrint('Error updating banner $bannerId: $e');
      rethrow;
    }
  }

  /// Delete a banner
  /// DELETE /banners/{id}
  Future<void> deleteBanner(
    String token,
    int bannerId, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/banners/$bannerId');
    try {
      final resp = await http
          .delete(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      if (resp.statusCode != 200) {
        throw Exception('Failed to delete banner: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting banner $bannerId: $e');
      rethrow;
    }
  }

  /// Track banner view
  /// POST /banners/{id}/track/view
  Future<bool> trackBannerView(
    int bannerId, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/banners/$bannerId/track/view');
    try {
      final resp = await http.post(uri).timeout(timeout);
      return resp.statusCode == 200;
    } catch (e) {
      debugPrint('Error tracking banner view: $e');
      return false;
    }
  }

  /// Track banner click
  /// POST /banners/{id}/track/click
  Future<bool> trackBannerClick(
    int bannerId, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/banners/$bannerId/track/click');
    try {
      final resp = await http.post(uri).timeout(timeout);
      return resp.statusCode == 200;
    } catch (e) {
      debugPrint('Error tracking banner click: $e');
      return false;
    }
  }

  /// Get banner statistics
  /// GET /banners/{id}/stats
  Future<Map<String, dynamic>?> getBannerStats(
    int bannerId, {
    String? token,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/banners/$bannerId/stats');
    try {
      final headers = <String, String>{};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final resp = await http
          .get(uri, headers: headers.isNotEmpty ? headers : null)
          .timeout(timeout);
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting banner stats: $e');
      return null;
    }
  }

  // ============================================
  // STORE PRODUCTS ENDPOINTS
  // ============================================

  /// Get all store products
  /// GET /store/products
  Future<List<dynamic>?> getStoreProducts({
    String? token,
    int? gymId,
    String? category,
    bool? available,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final queryParams = <String, String>{};
    if (gymId != null) queryParams['gymId'] = gymId.toString();
    if (category != null) queryParams['category'] = category;
    if (available != null) queryParams['available'] = available.toString();

    final uri = baseUri
        .resolve('/store/products')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    try {
      debugPrint('ApiService.getStoreProducts -> $uri');

      final headers = <String, String>{};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final resp = await http
          .get(uri, headers: headers.isNotEmpty ? headers : null)
          .timeout(timeout);

      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          final products = body['products'] as List<dynamic>;

          // Log pour debug des images
          if (products.isNotEmpty) {
            debugPrint('📦 Store products count: ${products.length}');
            final firstProduct = products.first as Map<String, dynamic>;
            debugPrint('📦 First product keys: ${firstProduct.keys.toList()}');
            debugPrint(
              '📦 Has imagesBase64: ${firstProduct.containsKey('imagesBase64')}',
            );
            debugPrint('📦 Has images: ${firstProduct.containsKey('images')}');
            debugPrint(
              '📦 Has imageUrl: ${firstProduct.containsKey('imageUrl')}',
            );
            if (firstProduct.containsKey('imagesBase64')) {
              debugPrint(
                '📦 imagesBase64 type: ${firstProduct['imagesBase64'].runtimeType}',
              );
              if (firstProduct['imagesBase64'] is List) {
                debugPrint(
                  '📦 imagesBase64 length: ${(firstProduct['imagesBase64'] as List).length}',
                );
              }
            }
          }

          return products;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting store products: $e');
      return null;
    }
  }

  /// Get a single store product by ID
  /// GET /store/products/{id}
  Future<Map<String, dynamic>?> getStoreProduct(
    String displayId, {
    String? token,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/store/products/$displayId');
    try {
      final headers = <String, String>{};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final resp = await http
          .get(uri, headers: headers.isNotEmpty ? headers : null)
          .timeout(timeout);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        return body['product'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting store product $displayId: $e');
      return null;
    }
  }

  /// Create a new store product with multiple images upload
  /// POST /store/products (multipart/form-data)
  Future<Map<String, dynamic>?> createStoreProduct(
    String token, {
    required String name,
    String? description,
    required double price,
    required int stock,
    String? category,
    int? gymId,
    List<Uint8List>? imagesBytes,
    List<String>? imageNames,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final uri = baseUri.resolve('/store/products');
    try {
      debugPrint('ApiService.createStoreProduct -> $uri');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['name'] = name;
      if (description != null) request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['stock'] = stock.toString();
      if (category != null) request.fields['category'] = category;
      if (gymId != null) request.fields['gymId'] = gymId.toString();

      // Add multiple images if provided (max 5)
      if (imagesBytes != null && imagesBytes.isNotEmpty) {
        for (int i = 0; i < imagesBytes.length && i < 5; i++) {
          final imageName = (imageNames != null && i < imageNames.length)
              ? imageNames[i]
              : 'product_image_$i.jpg';
          request.files.add(
            http.MultipartFile.fromBytes(
              'images', // Field name for multiple images
              imagesBytes[i],
              filename: imageName,
            ),
          );
        }
      }

      final streamedResponse = await request.send().timeout(timeout);
      final resp = await http.Response.fromStream(streamedResponse);

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        return body['product'] as Map<String, dynamic>;
      }
      throw Exception(
        'Failed to create product: ${resp.statusCode} - ${resp.body}',
      );
    } catch (e) {
      debugPrint('Error creating store product: $e');
      rethrow;
    }
  }

  /// Update a store product with multiple images
  /// PUT /store/products/{id} (multipart/form-data)
  Future<Map<String, dynamic>?> updateStoreProduct(
    String token,
    String displayId, {
    String? name,
    String? description,
    double? price,
    int? stock,
    String? category,
    bool? isActive,
    List<Uint8List>? imagesBytes,
    List<String>? imageNames,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final uri = baseUri.resolve('/store/products/$displayId');
    try {
      debugPrint('ApiService.updateStoreProduct -> $uri');

      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields only if provided
      if (name != null) request.fields['name'] = name;
      if (description != null) request.fields['description'] = description;
      if (price != null) request.fields['price'] = price.toString();
      if (stock != null) request.fields['stock'] = stock.toString();
      if (category != null) request.fields['category'] = category;
      if (isActive != null) request.fields['isActive'] = isActive.toString();

      // Add multiple images if provided (max 5)
      if (imagesBytes != null && imagesBytes.isNotEmpty) {
        for (int i = 0; i < imagesBytes.length && i < 5; i++) {
          final imageName = (imageNames != null && i < imageNames.length)
              ? imageNames[i]
              : 'product_image_$i.jpg';
          request.files.add(
            http.MultipartFile.fromBytes(
              'images', // Field name for multiple images
              imagesBytes[i],
              filename: imageName,
            ),
          );
        }
      }

      final streamedResponse = await request.send().timeout(timeout);
      final resp = await http.Response.fromStream(streamedResponse);

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        return body['product'] as Map<String, dynamic>;
      }
      throw Exception(
        'Failed to update product: ${resp.statusCode} - ${resp.body}',
      );
    } catch (e) {
      debugPrint('Error updating store product $displayId: $e');
      rethrow;
    }
  }

  /// Delete a store product
  /// DELETE /store/products/{id}
  Future<void> deleteStoreProduct(
    String token,
    String displayId, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/store/products/$displayId');
    try {
      final resp = await http
          .delete(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      if (resp.statusCode != 200) {
        final body = jsonDecode(resp.body);
        throw Exception(
          body['message'] ?? 'Failed to delete product: ${resp.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error deleting store product $displayId: $e');
      rethrow;
    }
  }

  // ============================================================================
  // NEW API ENDPOINTS - January 2, 2026
  // ============================================================================

  /// Get today's check-in count for a gym.
  /// GET /check-in/gym/{gymId}/today
  Future<int?> getTodayCheckIns(
    int gymId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/check-in/gym/$gymId/today');
    try {
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        return body['count'] as int?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Checkout from gym (record exit time).
  /// POST /check-in/{id}/checkout
  Future<Map<String, dynamic>?> checkoutMember(
    int checkInId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/check-in/$checkInId/checkout');
    try {
      debugPrint('ApiService.checkoutMember -> $uri');

      final resp = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(timeout);

      debugPrint(
        'ApiService.checkoutMember response status: ${resp.statusCode}',
      );

      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (e) {
          debugPrint('ApiService.checkoutMember parse error: $e');
          return null;
        }
      } else if (resp.statusCode == 400 || resp.statusCode == 404) {
        // Return error details for "Already checked out" or "Check-in not found"
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (_) {
          return {'error': 'Status code: ${resp.statusCode}'};
        }
      }
      return {'error': 'Status code: ${resp.statusCode}'};
    } catch (e) {
      debugPrint('ApiService.checkoutMember exception: $e');
      return {'error': e.toString()};
    }
  }

  /// Update member onboarding status.
  /// PUT /members/{id}/onboarding
  Future<Map<String, dynamic>?> updateOnboardingStatus(
    int memberId,
    bool onboarding,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/members/$memberId/onboarding');
    try {
      debugPrint(
        'ApiService.updateOnboardingStatus -> $uri (onboarding: $onboarding)',
      );

      final resp = await http
          .put(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'onboarding': onboarding}),
          )
          .timeout(timeout);

      debugPrint(
        'ApiService.updateOnboardingStatus response status: ${resp.statusCode}',
      );

      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (e) {
          debugPrint('ApiService.updateOnboardingStatus parse error: $e');
          return null;
        }
      } else if (resp.statusCode == 400 || resp.statusCode == 403) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (_) {
          return {'error': 'Status code: ${resp.statusCode}'};
        }
      }
      return {'error': 'Status code: ${resp.statusCode}'};
    } catch (e) {
      debugPrint('ApiService.updateOnboardingStatus exception: $e');
      return {'error': e.toString()};
    }
  }

  /// Upload profile picture for a member.
  /// PUT /members/{id}/profile-picture
  /// imageData can be a full data URI (with data:image/...;base64, prefix) or just raw base64 string
  Future<Map<String, dynamic>?> uploadProfilePicture(
    int memberId,
    String imageData,
    String token, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = baseUri.resolve('/members/$memberId/profile-picture');
    try {
      debugPrint('ApiService.uploadProfilePicture -> $uri');

      final resp = await http
          .put(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'imageData': imageData}),
          )
          .timeout(timeout);

      debugPrint(
        'ApiService.uploadProfilePicture response status: ${resp.statusCode}',
      );

      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (e) {
          debugPrint('ApiService.uploadProfilePicture parse error: $e');
          return null;
        }
      } else if (resp.statusCode == 400 || resp.statusCode == 403) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (_) {
          return {'error': 'Status code: ${resp.statusCode}'};
        }
      }
      return {'error': 'Status code: ${resp.statusCode}'};
    } catch (e) {
      debugPrint('ApiService.uploadProfilePicture exception: $e');
      return {'error': e.toString()};
    }
  }

  /// Get profile picture for a member.
  /// GET /members/{id}/profile-picture
  /// Returns base64-encoded image data
  Future<Map<String, dynamic>?> getProfilePicture(
    int memberId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/members/$memberId/profile-picture');
    try {
      debugPrint('ApiService.getProfilePicture -> $uri');

      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);

      debugPrint(
        'ApiService.getProfilePicture response status: ${resp.statusCode}',
      );

      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (e) {
          debugPrint('ApiService.getProfilePicture parse error: $e');
          return null;
        }
      } else if (resp.statusCode == 403 || resp.statusCode == 404) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (_) {
          return {'error': 'Status code: ${resp.statusCode}'};
        }
      }
      return {'error': 'Status code: ${resp.statusCode}'};
    } catch (e) {
      debugPrint('ApiService.getProfilePicture exception: $e');
      return {'error': e.toString()};
    }
  }

  /// Delete profile picture for a member.
  /// DELETE /members/{id}/profile-picture
  Future<Map<String, dynamic>?> deleteProfilePicture(
    int memberId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/members/$memberId/profile-picture');
    try {
      debugPrint('ApiService.deleteProfilePicture -> $uri');

      final resp = await http
          .delete(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);

      debugPrint(
        'ApiService.deleteProfilePicture response status: ${resp.statusCode}',
      );

      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (e) {
          debugPrint('ApiService.deleteProfilePicture parse error: $e');
          return null;
        }
      } else if (resp.statusCode == 403) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (_) {
          return {'error': 'Status code: ${resp.statusCode}'};
        }
      }
      return {'error': 'Status code: ${resp.statusCode}'};
    } catch (e) {
      debugPrint('ApiService.deleteProfilePicture exception: $e');
      return {'error': e.toString()};
    }
  }

  // ==================== GYMS — IMAGE ====================

  /// Upload or update gym image (base64).
  /// PUT /gyms/{id}/image
  Future<bool> uploadGymImage(
    int gymId,
    String imageData,
    String token, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final uri = baseUri.resolve('/gyms/$gymId/image');
    try {
      debugPrint('ApiService.uploadGymImage -> $uri');
      final resp = await http
          .put(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'imageData': imageData}),
          )
          .timeout(timeout);
      debugPrint('uploadGymImage status: ${resp.statusCode}');
      return resp.statusCode == 200;
    } catch (e) {
      debugPrint('Error uploading gym image: $e');
      return false;
    }
  }

  // ==================== GYMS — PHOTO GALLERY (page vitrine) ====================

  /// List photo metadata for a gym (id, position, isCover).
  /// Expected backend endpoint: GET /gyms/{id}/photos
  Future<List<dynamic>?> getGymPhotos(
    int gymId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/gyms/$gymId/photos');
    try {
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body['photos'] as List<dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns the authenticated URL serving a given photo's binary data.
  /// Expected backend endpoint: GET /gyms/{id}/photos/{photoId}/image
  Uri gymPhotoImageUri(int gymId, int photoId) {
    return baseUri.resolve('/gyms/$gymId/photos/$photoId/image');
  }

  /// Add a photo to a gym's gallery (base64).
  /// Expected backend endpoint: POST /gyms/{id}/photos
  Future<Map<String, dynamic>?> addGymPhoto(
    int gymId,
    String imageData,
    String token, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final uri = baseUri.resolve('/gyms/$gymId/photos');
    try {
      final resp = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'imageData': imageData}),
          )
          .timeout(timeout);
      if (resp.statusCode == 201) {
        try {
          final body = jsonDecode(resp.body);
          return body['photo'] as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error adding gym photo: $e');
      return null;
    }
  }

  /// Delete a photo from a gym's gallery.
  /// Expected backend endpoint: DELETE /gyms/{id}/photos/{photoId}
  Future<bool> deleteGymPhoto(
    int gymId,
    int photoId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/gyms/$gymId/photos/$photoId');
    try {
      final resp = await http
          .delete(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Reorder a gym's gallery photos.
  /// Expected backend endpoint: PUT /gyms/{id}/photos/reorder
  Future<bool> reorderGymPhotos(
    int gymId,
    List<int> orderedPhotoIds,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/gyms/$gymId/photos/reorder');
    try {
      final resp = await http
          .put(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'order': orderedPhotoIds}),
          )
          .timeout(timeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Set a photo as the gym's cover photo.
  /// Expected backend endpoint: PUT /gyms/{id}/photos/{photoId}/cover
  Future<bool> setGymPhotoCover(
    int gymId,
    int photoId,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/gyms/$gymId/photos/$photoId/cover');
    try {
      final resp = await http
          .put(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ==================== GYMS — PAGE VITRINE PUBLIQUE (sans auth) ====================

  /// List published gyms for the public showcase site.
  /// Expected backend endpoint: GET /public/gyms
  Future<List<dynamic>?> getPublicGyms({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/public/gyms');
    try {
      final resp = await http.get(uri).timeout(timeout);
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

  /// Get full public details (photos, team, opening hours) for a published gym.
  /// Expected backend endpoint: GET /public/gyms/{slugOrId}
  Future<Map<String, dynamic>?> getPublicGym(
    String slugOrId, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/public/gyms/$slugOrId');
    try {
      final resp = await http.get(uri).timeout(timeout);
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

  // ==================== SHOWCASE CMS ====================

  /// Contenu éditable de la page d'accueil vitrine (public, sans auth).
  /// Expected backend endpoint: GET /public/showcase/home
  /// Retourne `{}` si rien n'est encore enregistré (→ contenu par défaut),
  /// null en cas d'erreur réseau.
  Future<Map<String, dynamic>?> getPublicShowcaseHome({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/public/showcase/home');
    try {
      final resp = await http.get(uri).timeout(timeout);
      if (resp.statusCode == 200) {
        return (jsonDecode(resp.body) as Map<String, dynamic>?) ?? {};
      }
      if (resp.statusCode == 404) return {};
      return null;
    } catch (_) {
      return null;
    }
  }

  /// GET /showcase/home (owner) ou GET /gyms/{gymId}/showcase (owner, admin
  /// de la salle) — page CMS `{ hero?, sections: [...] }`.
  /// Retourne `{}` si rien n'est encore enregistré, null en cas d'erreur.
  Future<Map<String, dynamic>?> getShowcasePage(
    String token, {
    int? gymId,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve(
      gymId == null ? '/showcase/home' : '/gyms/$gymId/showcase',
    );
    try {
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      if (resp.statusCode == 200) {
        return (jsonDecode(resp.body) as Map<String, dynamic>?) ?? {};
      }
      if (resp.statusCode == 404) return {};
      return null;
    } catch (_) {
      return null;
    }
  }

  /// PUT /showcase/home ou PUT /gyms/{gymId}/showcase — remplace la page
  /// entière (liste ordonnée des sections).
  Future<bool> updateShowcasePage(
    String token,
    Map<String, dynamic> page, {
    int? gymId,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = baseUri.resolve(
      gymId == null ? '/showcase/home' : '/gyms/$gymId/showcase',
    );
    try {
      final resp = await http
          .put(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(page),
          )
          .timeout(timeout);
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // ==================== REQUÊTE JSON GÉNÉRIQUE ====================

  /// Requête JSON authentifiée pour les services de domaine (coachs,
  /// programmes, séances, incidents) : renvoie le code HTTP et le corps
  /// décodé (null si vide ou illisible). `status == 0` = erreur réseau.
  Future<({int status, dynamic body})> sendJson(
    String method,
    String path,
    String token, {
    Object? body,
    Map<String, String>? query,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    var uri = baseUri.resolve(path);
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final headers = {
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };
    final encoded = body == null ? null : jsonEncode(body);
    try {
      final resp = await switch (method) {
        'GET' => http.get(uri, headers: headers),
        'POST' => http.post(uri, headers: headers, body: encoded),
        'PUT' => http.put(uri, headers: headers, body: encoded),
        'PATCH' => http.patch(uri, headers: headers, body: encoded),
        'DELETE' => http.delete(uri, headers: headers, body: encoded),
        _ => throw ArgumentError.value(method, 'method'),
      }.timeout(timeout);
      dynamic decoded;
      if (resp.body.isNotEmpty) {
        try {
          decoded = jsonDecode(resp.body);
        } catch (_) {}
      }
      return (status: resp.statusCode, body: decoded);
    } catch (e) {
      debugPrint('ApiService.sendJson $method $path error: $e');
      return (status: 0, body: null);
    }
  }

  /// Contenu binaire authentifié (photos d'incident…), null si absent.
  Future<Uint8List?> getBytes(
    String path,
    String token, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final resp = await http
          .get(
            baseUri.resolve(path),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(timeout);
      return resp.statusCode == 200 ? resp.bodyBytes : null;
    } catch (_) {
      return null;
    }
  }

  /// Extrait une liste d'une réponse : tableau brut ou `{key: [...]}`.
  static List<Map<String, dynamic>> listFrom(dynamic body, String key) {
    final raw = body is List ? body : (body is Map ? body[key] : null);
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  // ==================== SUBSCRIPTIONS — RENEW ====================

  /// Renew a subscription (creates new subscription of same type from today).
  /// POST /subscriptions/{id}/renew
  Future<Map<String, dynamic>?> renewSubscription(
    int subscriptionId,
    String token, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = baseUri.resolve('/subscriptions/$subscriptionId/renew');
    try {
      debugPrint('ApiService.renewSubscription -> $uri');
      final resp = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(timeout);
      debugPrint('renewSubscription status: ${resp.statusCode}');
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        try {
          return jsonDecode(resp.body) as Map<String, dynamic>;
        } catch (_) {
          return {};
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error renewing subscription: $e');
      return null;
    }
  }

  // ==================== WHATSAPP ====================

  /// Get WhatsApp connection status.
  /// GET /whatsapp/status
  Future<Map<String, dynamic>?> getWhatsAppStatus(
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/whatsapp/status');
    try {
      debugPrint('ApiService.getWhatsAppStatus -> $uri');
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      debugPrint('getWhatsAppStatus status: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        try {
          return jsonDecode(resp.body) as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting WhatsApp status: $e');
      return null;
    }
  }

  /// Get WhatsApp QR code (data URL). Returns null if already connected or QR not ready.
  /// GET /whatsapp/qr
  Future<Map<String, dynamic>?> getWhatsAppQr(
    String token, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = baseUri.resolve('/whatsapp/qr');
    try {
      debugPrint('ApiService.getWhatsAppQr -> $uri');
      final resp = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      debugPrint('getWhatsAppQr status: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        try {
          return jsonDecode(resp.body) as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return {'statusCode': resp.statusCode};
    } catch (e) {
      debugPrint('Error getting WhatsApp QR: $e');
      return null;
    }
  }

  /// Disconnect WhatsApp session.
  /// DELETE /whatsapp/session
  Future<bool> disconnectWhatsApp(
    String token, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = baseUri.resolve('/whatsapp/session');
    try {
      debugPrint('ApiService.disconnectWhatsApp -> $uri');
      final resp = await http
          .delete(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(timeout);
      debugPrint('disconnectWhatsApp status: ${resp.statusCode}');
      return resp.statusCode == 200;
    } catch (e) {
      debugPrint('Error disconnecting WhatsApp: $e');
      return false;
    }
  }

  /// Request a WhatsApp pairing code (alternative to QR scan).
  /// POST /whatsapp/pairing-code
  Future<Map<String, dynamic>?> requestWhatsAppPairingCode(
    String phoneNumber,
    String token, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = baseUri.resolve('/whatsapp/pairing-code');
    try {
      debugPrint('ApiService.requestWhatsAppPairingCode -> $uri');
      final resp = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'phoneNumber': phoneNumber}),
          )
          .timeout(timeout);
      debugPrint('requestWhatsAppPairingCode status: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        try {
          return jsonDecode(resp.body) as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return {'statusCode': resp.statusCode};
    } catch (e) {
      debugPrint('Error requesting WhatsApp pairing code: $e');
      return null;
    }
  }

  /// Set the WhatsApp display name (pushName). `null` or empty resets it to
  /// the account name. Returns `{displayName, applied}` — `applied` is false
  /// when WhatsApp is disconnected (applied on next connection).
  /// PUT /whatsapp/display-name
  Future<Map<String, dynamic>?> setWhatsAppDisplayName(
    String? displayName,
    String token, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final uri = baseUri.resolve('/whatsapp/display-name');
    try {
      debugPrint('ApiService.setWhatsAppDisplayName -> $uri');
      final resp = await http
          .put(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'displayName': displayName}),
          )
          .timeout(timeout);
      debugPrint('setWhatsAppDisplayName status: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        try {
          return jsonDecode(resp.body) as Map<String, dynamic>;
        } catch (_) {
          return {'displayName': displayName, 'applied': true};
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error setting WhatsApp display name: $e');
      return null;
    }
  }

  /// Set the WhatsApp profile picture. [imageBase64] is raw base64 (no
  /// `data:` prefix). Returns the HTTP status code (200 on success, 400 when
  /// WhatsApp is not connected), or null on network error.
  /// PUT /whatsapp/profile-picture
  Future<int?> setWhatsAppProfilePicture(
    String imageBase64,
    String mimeType,
    String token, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final uri = baseUri.resolve('/whatsapp/profile-picture');
    try {
      debugPrint('ApiService.setWhatsAppProfilePicture -> $uri');
      final resp = await http
          .put(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'image': imageBase64, 'mimeType': mimeType}),
          )
          .timeout(timeout);
      debugPrint('setWhatsAppProfilePicture status: ${resp.statusCode}');
      return resp.statusCode;
    } catch (e) {
      debugPrint('Error setting WhatsApp profile picture: $e');
      return null;
    }
  }

  // ==================== ANDROID CONFIG ====================

  /// Get Android app configuration (API URL, min version, features).
  /// GET /android/config
  Future<Map<String, dynamic>?> getAndroidConfig({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/android/config');
    try {
      debugPrint('ApiService.getAndroidConfig -> $uri');
      final resp = await http.get(uri).timeout(timeout);
      debugPrint('getAndroidConfig status: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        try {
          return jsonDecode(resp.body) as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting Android config: $e');
      return null;
    }
  }

  // ==================== MEMBERS — PREFERRED TRAINING DAYS ====================

  /// Update preferred training days for a member.
  /// PUT /members/{id}/preferred-training-days
  /// days can be numbers (0-6) or day names (sunday, monday, etc.)
  /// Alternative field name 'preferredTrainingDays' is also accepted
  Future<Map<String, dynamic>?> updatePreferredTrainingDays(
    int memberId,
    List<dynamic> days,
    String token, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = baseUri.resolve('/members/$memberId/preferred-training-days');
    try {
      debugPrint(
        'ApiService.updatePreferredTrainingDays -> $uri (days: $days)',
      );

      final resp = await http
          .put(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'days': days}),
          )
          .timeout(timeout);

      debugPrint(
        'ApiService.updatePreferredTrainingDays response status: ${resp.statusCode}',
      );

      if (resp.statusCode == 200) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (e) {
          debugPrint('ApiService.updatePreferredTrainingDays parse error: $e');
          return null;
        }
      } else if (resp.statusCode == 400 || resp.statusCode == 403) {
        try {
          final body = jsonDecode(resp.body);
          return body as Map<String, dynamic>;
        } catch (_) {
          return {'error': 'Status code: ${resp.statusCode}'};
        }
      }
      return {'error': 'Status code: ${resp.statusCode}'};
    } catch (e) {
      debugPrint('ApiService.updatePreferredTrainingDays exception: $e');
      return {'error': e.toString()};
    }
  }
}
