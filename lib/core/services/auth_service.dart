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
      return await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
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
          IOSAuthMessages(
            cancelButton: 'Annuler',
          ),
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
      if (!errorString.contains('UserCancel') && !errorString.contains('AuthenticationCanceled')) {
        // ignore: avoid_print
        debugPrint('❌ Erreur biométrie: $e');
      }
      
      return false;
    }
  }

  /// Full biometric flow: prompt user, load saved credentials and try login via API.
  Future<AuthStatus> authenticateWithBiometrics() async {
    final ok = await promptBiometric(localizedReason: 'Please authenticate to access the app');
    if (!ok) return AuthStatus.biometricFailed;

    // Prefer using a stored JWT token when available.
    final token = await loadToken();
    if (token != null) {
      try {
        final valid = await _apiService.verifyToken(token);
        if (valid) return AuthStatus.success;
        // token invalid -> fallthrough to credential-based flow
      } catch (e, st) {
        try {
          await _apiService.reportError('Token verify failed during biometric auth: $e', st.toString());
        } catch (_) {}
        // fallback
      }
    }

    final creds = await loadCredentials();
    if (creds == null) return AuthStatus.noSavedCredentials;

    // Check backend health
    try {
      final healthy = await _apiService.healthCheck();
      if (!healthy) return AuthStatus.serverUnavailable;
    } catch (e, st) {
      // report to backend for developer review
      try {
        await _apiService.reportError('Health check failed during biometric auth: $e', st.toString());
      } catch (_) {}
      return AuthStatus.serverUnavailable;
    }

    // Try login using saved credentials
    try {
      final loginResult = await _apiService.login(creds['email']!, creds['password']!);
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
          debugPrint('🔍 [Biometric] Tentative de récupération du token FCM...');
          final fcmToken = await FCMService().getToken();
          debugPrint('🔍 [Biometric] Token FCM récupéré: $fcmToken');
          
          if (fcmToken != null && fcmToken.isNotEmpty) {
            debugPrint('📤 [Biometric] Envoi du token FCM au serveur (userId: $userId)...');
            debugPrint('🔑 [Biometric] JWT utilisé: ${token.substring(0, 20)}...');
            final result = await _apiService.updateUserFCMToken(int.parse(userId), fcmToken, token);
            debugPrint('✅ [Biometric] Réponse serveur pour FCM token: $result');
          } else {
            debugPrint('⚠️ [Biometric] Token FCM null ou vide, non envoyé au serveur');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ [Biometric] Erreur lors de l\'envoi du token FCM: $e');
          debugPrint('Stack trace: $stackTrace');
          // Don't block login if FCM token sending fails
        }
        
        return AuthStatus.success;
      }
      return AuthStatus.serverAuthFailed;
    } catch (e, st) {
      try {
        await _apiService.reportError('Login failed during biometric auth: $e', st.toString());
      } catch (_) {}
      return AuthStatus.error;
    }
  }

  /// Full biometric flow with onboarding check
  Future<Map<String, dynamic>> authenticateWithBiometricsAndCheckOnboarding() async {
    final ok = await promptBiometric(localizedReason: 'Please authenticate to access the app');
    if (!ok) {
      return {'status': AuthStatus.biometricFailed};
    }

    // Prefer using a stored JWT token when available.
    final token = await loadToken();
    if (token != null) {
      try {
        final valid = await _apiService.verifyToken(token);
        if (valid) {
          // Token valid, but we need to check onboarding status from server
          debugPrint('🔍 [Biometric] Token valid, fetching profile for onboarding check...');
          
          // Get user type from storage
          final userType = await getUserType();
          
          // Fetch fresh profile to get REAL onboarding status from server
          final profileData = await _apiService.getUserProfile(token);
          
          if (profileData != null) {
            // Check onboarding in member object first, then at root level
            final memberData = profileData['member'] as Map<String, dynamic>?;
            final needsOnboarding = memberData?['onboarding'] as bool? ?? 
                                    profileData['onboarding'] as bool? ?? 
                                    true; // Default to true if not found
            
            debugPrint('🔍 [Biometric] Profile fetched - onboarding=$needsOnboarding, userType=$userType');
            debugPrint('🔍 [Biometric] Member data: $memberData');
            
            return {
              'status': AuthStatus.success,
              'needsOnboarding': needsOnboarding,
              'userType': userType ?? 'member',
            };
          } else {
            debugPrint('⚠️ [Biometric] Profile fetch returned null, defaulting to needs onboarding');
            return {
              'status': AuthStatus.success,
              'needsOnboarding': true,
              'userType': userType ?? 'member',
            };
          }
        }
        // token invalid -> fallthrough to credential-based flow
      } catch (e, st) {
        debugPrint('❌ [Biometric] Error during token validation: $e');
        try {
          await _apiService.reportError('Token verify failed during biometric auth: $e', st.toString());
        } catch (_) {}
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
    } catch (e, st) {
      try {
        await _apiService.reportError('Health check failed during biometric auth: $e', st.toString());
      } catch (_) {}
      return {'status': AuthStatus.serverUnavailable};
    }

    // Try login using saved credentials
    try {
      final loginResult = await _apiService.login(creds['email']!, creds['password']!);
      if (loginResult != null) {
        final token = loginResult['token'] as String;
        final userType = loginResult['userType'] as String;
        final userId = loginResult['userId'] as String;
        final needsOnboarding = loginResult['onboarding'] as bool? ?? true;
        
        debugPrint('🔍 [Biometric] Login successful - onboarding=$needsOnboarding, userType=$userType');
        
        // persist token and user type for future biometric logins
        await saveToken(token);
        await saveUserType(userType);
        
        // Small delay to ensure token is properly saved and validated
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Send FCM token to server for push notifications (after JWT is saved and validated)
        try {
          debugPrint('🔍 [Biometric] Tentative de récupération du token FCM...');
          final fcmToken = await FCMService().getToken();
          debugPrint('🔍 [Biometric] Token FCM récupéré: $fcmToken');
          
          if (fcmToken != null && fcmToken.isNotEmpty) {
            debugPrint('📤 [Biometric] Envoi du token FCM au serveur (userId: $userId)...');
            debugPrint('🔑 [Biometric] JWT utilisé: ${token.substring(0, 20)}...');
            final result = await _apiService.updateUserFCMToken(int.parse(userId), fcmToken, token);
            debugPrint('✅ [Biometric] Réponse serveur pour FCM token: $result');
          } else {
            debugPrint('⚠️ [Biometric] Token FCM null ou vide, non envoyé au serveur');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ [Biometric] Erreur lors de l\'envoi du token FCM: $e');
          debugPrint('Stack trace: $stackTrace');
          // Don't block login if FCM token sending fails
        }
        
        return {
          'status': AuthStatus.success,
          'needsOnboarding': needsOnboarding,
          'userType': userType,
        };
      }
      return {'status': AuthStatus.serverAuthFailed};
    } catch (e, st) {
      try {
        await _apiService.reportError('Login failed during biometric auth: $e', st.toString());
      } catch (_) {}
      return {'status': AuthStatus.error};
    }
  }

  /// Clear all stored credentials and tokens (for logout)
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
  }

  /// Fetch user profile from API and cache it locally
  Future<bool> fetchAndCacheUserProfile(String token) async {
    try {
      final profileData = await _apiService.getUserProfile(token);
      if (profileData != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile_cache', jsonEncode(profileData));
        await prefs.setInt('user_profile_cache_time', DateTime.now().millisecondsSinceEpoch);
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
        await prefs.setInt('user_profile_cache_time', DateTime.now().millisecondsSinceEpoch);
        return profileData;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}




