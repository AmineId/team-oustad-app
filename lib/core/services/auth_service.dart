import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'fcm_service.dart';

/// Outcome of a biometric authentication attempt that includes an API login step.
enum AuthStatus {
  success,
  noSavedCredentials,
  serverUnavailable,
  serverAuthFailed,
  biometricFailed,
  error,
}

class AuthService {
  final ApiService _apiService;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthService(this._apiService);

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
  }

  /// Check if user has given consent for biometric authentication
  Future<bool> hasBiometricConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_consent') ?? false;
  }

  /// Set user consent for biometric authentication
  Future<void> setBiometricConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_consent', consent);
    // If consent is given, enable biometric
    if (consent) {
      await setBiometricEnabled(true);
    } else {
      await setBiometricEnabled(false);
    }
  }

  Future<void> saveCredentials(String email, String password) async {
    try {
      await _secureStorage.write(key: 'auth_email', value: email);
      await _secureStorage.write(key: 'auth_password', value: password);
    } catch (_) {
      // ignore storage errors
    }
  }

  Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: 'auth_token', value: token);
    } catch (_) {}
  }

  Future<String?> loadToken() async {
    try {
      return await _secureStorage.read(key: 'auth_token');
    } catch (_) {
      return null;
    }
  }

  /// Save user type (admin or member) in SharedPreferences
  Future<void> saveUserType(String userType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_type', userType);
    } catch (_) {}
  }

  /// Load user type from SharedPreferences
  Future<String?> getUserType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_type');
    } catch (_) {
      return null;
    }
  }

  /// Check if current user is an admin (NOT owner)
  Future<bool> isAdmin() async {
    final userType = await getUserType();
    return userType == 'admin';
  }

  /// Check if current user is an owner (super admin)
  Future<bool> isOwner() async {
    final userType = await getUserType();
    return userType == 'owner';
  }

  /// Check if current user is an admin OR owner (has admin access)
  Future<bool> hasAdminAccess() async {
    final userType = await getUserType();
    return userType == 'admin' || userType == 'owner';
  }

  Future<bool> hasStoredCredentials() async {
    try {
      final email = await _secureStorage.read(key: 'auth_email');
      final pwd = await _secureStorage.read(key: 'auth_password');
      return email != null && pwd != null;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, String>?> loadCredentials() async {
    try {
      final email = await _secureStorage.read(key: 'auth_email');
      final pwd = await _secureStorage.read(key: 'auth_password');
      if (email == null || pwd == null) return null;
      return {'email': email, 'password': pwd};
    } catch (_) {
      return null;
    }
  }

  /// Prompt only the biometric UI and return whether the user authenticated.
  Future<bool> promptBiometric({required String localizedReason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Authentification biométrique',
            cancelButton: 'Annuler',
          ),
          IOSAuthMessages(cancelButton: 'Annuler'),
        ],
      );
    } catch (e) {
      // Handle all biometric errors
      final errorString = e.toString();

      // Check if it's a known non-error case
      if (errorString.contains('noCredentialsSet') ||
          errorString.contains('NotEnrolled') ||
          errorString.contains('NotAvailable') ||
          errorString.contains('PasscodeNotSet')) {
        // User hasn't set up biometrics - this is normal, not an error
        // ignore: avoid_print
        debugPrint('ℹ️ Biométrie non configurée sur cet appareil');
        return false;
      }

      // Only print as error if it's an actual error (not user cancellation)
      if (!errorString.contains('UserCancel') &&
          !errorString.contains('AuthenticationCanceled')) {
        // ignore: avoid_print
        debugPrint('❌ Erreur biométrie: $e');
      }

      return false;
    }
  }

  /// Full biometric flow: prompt user, load saved credentials and try login via API.
  Future<AuthStatus> authenticateWithBiometrics() async {
    // Vérifier le consentement avant d'utiliser la biométrie
    final hasConsent = await hasBiometricConsent();
    if (!hasConsent) return AuthStatus.biometricFailed;

    final ok = await promptBiometric(
      localizedReason: 'Please authenticate to access the app',
    );
    if (!ok) return AuthStatus.biometricFailed;

    // Prefer using a stored JWT token when available.
    final token = await loadToken();
    if (token != null) {
      try {
        final valid = _apiService.verifyToken(token);
        if (valid) return AuthStatus.success;
        // token invalid -> fallthrough to credential-based flow
      } catch (e) {
        debugPrint('❌ [Biometric] Token verify error: $e');
        // fallback
      }
    }

    final creds = await loadCredentials();
    if (creds == null) return AuthStatus.noSavedCredentials;

    // Check backend health
    try {
      final healthy = await _apiService.healthCheck();
      if (!healthy) return AuthStatus.serverUnavailable;
    } catch (e) {
      debugPrint('❌ [Biometric] Health check error: $e');
      return AuthStatus.serverUnavailable;
    }

    // Try login using saved credentials
    try {
      final loginResult = await _apiService.login(
        creds['email']!,
        creds['password']!,
      );
      if (loginResult != null) {
        final token = loginResult['token'] as String;
        final userType = loginResult['userType'] as String;
        final userId = loginResult['userId'] as String;

        // persist token and user type for future biometric logins
        await saveToken(token);
        await saveUserType(userType);

        // Small delay to ensure token is properly saved and validated
        await Future.delayed(const Duration(milliseconds: 100));

        // Send FCM token to server for push notifications (after JWT is saved and validated)
        try {
          debugPrint(
            '🔍 [Biometric] Tentative de récupération du token FCM...',
          );
          final fcmToken = await FCMService().getToken();
          debugPrint('🔍 [Biometric] Token FCM récupéré: $fcmToken');

          if (fcmToken != null && fcmToken.isNotEmpty) {
            debugPrint(
              '📤 [Biometric] Envoi du token FCM au serveur (userId: $userId)...',
            );
            debugPrint(
              '🔑 [Biometric] JWT utilisé: ${token.substring(0, 20)}...',
            );
            final result = await _apiService.updateUserFCMToken(
              int.parse(userId),
              fcmToken,
              token,
            );
            debugPrint('✅ [Biometric] Réponse serveur pour FCM token: $result');
          } else {
            debugPrint(
              '⚠️ [Biometric] Token FCM null ou vide, non envoyé au serveur',
            );
          }
        } catch (e, stackTrace) {
          debugPrint('❌ [Biometric] Erreur lors de l\'envoi du token FCM: $e');
          debugPrint('Stack trace: $stackTrace');
          // Don't block login if FCM token sending fails
        }

        return AuthStatus.success;
      }
      return AuthStatus.serverAuthFailed;
    } catch (e) {
      debugPrint('❌ [Biometric] Login error: $e');
      return AuthStatus.error;
    }
  }

  /// Full biometric flow with onboarding check
  Future<Map<String, dynamic>>
  authenticateWithBiometricsAndCheckOnboarding() async {
    // Vérifier le consentement avant d'utiliser la biométrie
    final hasConsent = await hasBiometricConsent();
    if (!hasConsent) {
      return {'status': AuthStatus.biometricFailed};
    }

    final ok = await promptBiometric(
      localizedReason: 'Please authenticate to access the app',
    );
    if (!ok) {
      return {'status': AuthStatus.biometricFailed};
    }

    // Prefer using a stored JWT token when available.
    final token = await loadToken();
    if (token != null) {
      try {
        final valid = _apiService.verifyToken(token);
        if (valid) {
          // Token valid, fetch and cache profile
          debugPrint(
            '🔍 [Biometric] Token valid, fetching and caching profile...',
          );

          // Get user type from storage
          final userType = await getUserType();

          // Fetch and cache profile data (single API call)
          final success = await fetchAndCacheUserProfile(token);

          if (success) {
            // Get cached profile to check onboarding
            final profileData = await getCachedUserProfile();

            if (profileData != null) {
              // Check onboarding in member object first, then at root level
              final memberData = profileData['member'] as Map<String, dynamic>?;
              final needsOnboarding =
                  memberData?['onboarding'] as bool? ??
                  profileData['onboarding'] as bool? ??
                  true; // Default to true if not found

              debugPrint(
                '🔍 [Biometric] Profile fetched and cached - onboarding=$needsOnboarding, userType=$userType',
              );

              return {
                'status': AuthStatus.success,
                'needsOnboarding': needsOnboarding,
                'userType': userType ?? 'member',
              };
            }
          }

          debugPrint(
            '⚠️ [Biometric] Profile fetch failed, defaulting to needs onboarding',
          );
          return {
            'status': AuthStatus.success,
            'needsOnboarding': true,
            'userType': userType ?? 'member',
          };
        }
        // token invalid -> fallthrough to credential-based flow
      } catch (e) {
        debugPrint('❌ [Biometric] Error during token validation: $e');
        // fallback
      }
    }

    final creds = await loadCredentials();
    if (creds == null) {
      return {'status': AuthStatus.noSavedCredentials};
    }

    // Check backend health
    try {
      final healthy = await _apiService.healthCheck();
      if (!healthy) {
        return {'status': AuthStatus.serverUnavailable};
      }
    } catch (e) {
      debugPrint('❌ [Biometric] Health check error: $e');
      return {'status': AuthStatus.serverUnavailable};
    }

    // Try login using saved credentials
    try {
      final loginResult = await _apiService.login(
        creds['email']!,
        creds['password']!,
      );
      if (loginResult != null) {
        final token = loginResult['token'] as String;
        final userType = loginResult['userType'] as String;
        final userId = loginResult['userId'] as String;
        final needsOnboarding = loginResult['onboarding'] as bool? ?? true;

        debugPrint(
          '🔍 [Biometric] Login successful - onboarding=$needsOnboarding, userType=$userType',
        );

        // persist token and user type for future biometric logins
        await saveToken(token);
        await saveUserType(userType);

        // Fetch and cache user profile data
        await fetchAndCacheUserProfile(token);

        // Small delay to ensure token is properly saved and validated
        await Future.delayed(const Duration(milliseconds: 100));

        // Send FCM token to server for push notifications (after JWT is saved and validated)
        try {
          debugPrint(
            '🔍 [Biometric] Tentative de récupération du token FCM...',
          );
          final fcmToken = await FCMService().getToken();
          debugPrint('🔍 [Biometric] Token FCM récupéré: $fcmToken');

          if (fcmToken != null && fcmToken.isNotEmpty) {
            debugPrint(
              '📤 [Biometric] Envoi du token FCM au serveur (userId: $userId)...',
            );
            debugPrint(
              '🔑 [Biometric] JWT utilisé: ${token.substring(0, 20)}...',
            );
            final result = await _apiService.updateUserFCMToken(
              int.parse(userId),
              fcmToken,
              token,
            );
            debugPrint('✅ [Biometric] Réponse serveur pour FCM token: $result');
          } else {
            debugPrint(
              '⚠️ [Biometric] Token FCM null ou vide, non envoyé au serveur',
            );
          }
        } catch (e, stackTrace) {
          debugPrint('❌ [Biometric] Erreur lors de l\'envoi du token FCM: $e');
          debugPrint('Stack trace: $stackTrace');
          // Don't block login if FCM token sending fails
        }

        // Download and cache QR code for offline access (only for members who completed onboarding)
        if (userType.toLowerCase() == 'member' && !needsOnboarding) {
          try {
            debugPrint(
              '📥 [Biometric] Téléchargement du QR code pour le cache offline...',
            );
            final qrCodeBytes = await _apiService.getUserQrCode(
              int.parse(userId),
              token,
            );
            if (qrCodeBytes != null) {
              await saveQrCodeCache(qrCodeBytes);
              debugPrint('✅ [Biometric] QR code mis en cache avec succès');
            }
          } catch (e) {
            debugPrint(
              '❌ [Biometric] Erreur lors du téléchargement du QR code: $e',
            );
            // Don't block login if QR code download fails
          }
        }

        return {
          'status': AuthStatus.success,
          'needsOnboarding': needsOnboarding,
          'userType': userType,
        };
      }
      return {'status': AuthStatus.serverAuthFailed};
    } catch (e) {
      debugPrint('❌ [Biometric] Login error: $e');
      return {'status': AuthStatus.error};
    }
  }

  /// Authenticate with biometrics in offline mode (use cached data only)
  Future<Map<String, dynamic>> authenticateWithBiometricsOffline() async {
    // Vérifier le consentement avant d'utiliser la biométrie
    final hasConsent = await hasBiometricConsent();
    if (!hasConsent) {
      return {'status': AuthStatus.biometricFailed};
    }

    // Prompt for biometric authentication
    final ok = await promptBiometric(
      localizedReason:
          'Authentifiez-vous pour accéder à vos données hors ligne',
    );
    if (!ok) {
      return {'status': AuthStatus.biometricFailed};
    }

    debugPrint('🔍 [Biometric Offline] Checking for cached credentials...');

    // Check if we have cached credentials
    final creds = await loadCredentials();
    if (creds == null) {
      debugPrint('❌ [Biometric Offline] No cached credentials found');
      return {'status': AuthStatus.noSavedCredentials};
    }

    // Check if we have a cached profile
    final profileData = await getCachedUserProfile();
    if (profileData == null) {
      debugPrint('❌ [Biometric Offline] No cached profile found');
      return {'status': AuthStatus.noSavedCredentials};
    }

    // Get user type from storage
    final userType = await getUserType();
    if (userType == null) {
      debugPrint('❌ [Biometric Offline] No user type found');
      return {'status': AuthStatus.noSavedCredentials};
    }

    debugPrint(
      '✅ [Biometric Offline] Authentication successful - userType=$userType',
    );

    return {
      'status': AuthStatus.success,
      'userType': userType,
      'needsOnboarding': false, // Assume onboarding done if cached
    };
  }

  /// On Android, flutter_secure_storage survives uninstall but SharedPreferences
  /// does not. Detect a fresh install by checking a sentinel in SharedPreferences;
  /// if absent, wipe the stale token so the user lands on the login screen.
  Future<void> clearStaleTokenOnFreshInstall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final installed = prefs.getBool('_app_installed') ?? false;
      if (!installed) {
        await _secureStorage.delete(key: 'auth_token');
        await prefs.setBool('_app_installed', true);
      }
    } catch (_) {}
  }

  /// Clear all stored credentials and tokens (for logout)
  Future<void> clearAll() async {
    try {
      // Only delete the session token — keep credentials so biometric re-login works after logout.
      await _secureStorage.delete(key: 'auth_token');
      final prefs = await SharedPreferences.getInstance();
      // Preserve biometric consent across logout — it's a device-level preference
      final biometricConsent = prefs.getBool('biometric_consent');
      final biometricEnabled = prefs.getBool('biometric_enabled');
      await prefs.clear();
      if (biometricConsent != null) await prefs.setBool('biometric_consent', biometricConsent);
      if (biometricEnabled != null) await prefs.setBool('biometric_enabled', biometricEnabled);
      // Clear QR code cache on logout
      await clearQrCodeCache();
    } catch (_) {}
  }

  /// Clear only profile cache (keep credentials for biometric)
  Future<void> clearProfileCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile_cache');
      await prefs.remove('user_profile_cache_time');
    } catch (_) {}
  }

  /// Save QR code to cache
  Future<void> saveQrCodeCache(List<int> qrCodeBytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Convert bytes to base64 string for storage
      final base64Qr = base64Encode(qrCodeBytes);
      await prefs.setString('qr_code_cache', base64Qr);
      await prefs.setInt(
        'qr_code_cache_time',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  /// Get cached QR code
  Future<List<int>?> getQrCodeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final base64Qr = prefs.getString('qr_code_cache');
      if (base64Qr != null) {
        // Convert base64 string back to bytes
        return base64Decode(base64Qr);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Clear QR code cache
  Future<void> clearQrCodeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('qr_code_cache');
      await prefs.remove('qr_code_cache_time');
    } catch (_) {}
  }

  /// Fetch user profile from API and cache it locally
  Future<bool> fetchAndCacheUserProfile(String token) async {
    try {
      final profileData = await _apiService.getUserProfile(token);
      if (profileData != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile_cache', jsonEncode(profileData));
        await prefs.setInt(
          'user_profile_cache_time',
          DateTime.now().millisecondsSinceEpoch,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Get cached user profile data
  Future<Map<String, dynamic>?> getCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('user_profile_cache');
      if (data != null) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Check if cached profile is stale (older than 1 hour)
  Future<bool> isProfileCacheStale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTime = prefs.getInt('user_profile_cache_time');
      if (cacheTime == null) return true;

      final now = DateTime.now().millisecondsSinceEpoch;
      final oneHour = 60 * 60 * 1000; // 1 hour in milliseconds
      return (now - cacheTime) > oneHour;
    } catch (_) {
      return true;
    }
  }

  /// Refresh user profile (fetch from API and update cache)
  Future<Map<String, dynamic>?> refreshUserProfile() async {
    try {
      final token = await loadToken();
      if (token == null) return null;

      final profileData = await _apiService.getUserProfile(token);
      if (profileData != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile_cache', jsonEncode(profileData));
        await prefs.setInt(
          'user_profile_cache_time',
          DateTime.now().millisecondsSinceEpoch,
        );
        return profileData;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
