import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/user_utils.dart';
import '../../widgets/common/common_widgets.dart';
import '../admin/admin_home_screen.dart';
import '../coach/coach_home_screen.dart';
import '../member/member_home_screen.dart';
import '../member/onboarding_screen.dart';
import 'forgot_password_screen.dart';
import 'setup_password_screen.dart';
import '../../core/services/api_service.dart';
import '../../core/services/fcm_service.dart';

class LoginScreen extends StatefulWidget {
  final bool? initialDbHealthy;
  final bool fromLogout;

  const LoginScreen({
    super.key,
    this.initialDbHealthy,
    this.fromLogout = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  late final AuthService _authService;
  late final ApiService _apiService;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isAuthenticating = false;
  bool _isCheckingHealth = false;
  bool _dbHealthy = false;
  bool _canCheckBiometrics = false;
  bool _hasBiometricConsent = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dbHealthy = widget.initialDbHealthy ?? false;
    _apiService = ApiService.fromEnv();
    _authService = AuthService(_apiService);
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkBiometricAvailability();

    // Vérifier la connexion DB seulement si elle n'a pas été vérifiée depuis le splash screen
    if (!_dbHealthy) {
      await _performHealthCheck();
    }

    // Tenter l'authentification biométrique automatiquement SEULEMENT si l'utilisateur a donné son consentement
    // et que ce n'est pas une déconnexion volontaire
    if (_canCheckBiometrics &&
        _dbHealthy &&
        _hasBiometricConsent &&
        !widget.fromLogout) {
      // Petit délai pour laisser l'UI se charger
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _attemptBiometricLogin();
      }
    }
  }

  Future<void> _checkBiometricAvailability() async {
    _canCheckBiometrics = await _authService.canCheckBiometrics();
    if (_canCheckBiometrics) {
      _hasBiometricConsent = await _authService.hasBiometricConsent();
    }
    if (mounted) setState(() {});
  }

  Future<void> _attemptBiometricLogin() async {
    // Ne rien faire si déjà en cours d'authentification
    if (_isAuthenticating) return;

    // Vérifier qu'il y a des credentials sauvegardés
    final hasCredentials = await _authService.hasStoredCredentials();
    if (!hasCredentials) return;

    setState(() => _isAuthenticating = true);

    final result = await _authService
        .authenticateWithBiometricsAndCheckOnboarding();

    if (!mounted) return;

    setState(() => _isAuthenticating = false);

    if (result['status'] == AuthStatus.success) {
      final needsOnboarding = result['needsOnboarding'] as bool? ?? false;
      final userType = result['userType'] as String? ?? '';

      debugPrint(
        '🔍 [Biometric Auto] needsOnboarding=$needsOnboarding, userType=$userType',
      );

      if (needsOnboarding && userType.toLowerCase() == 'member') {
        debugPrint(
          '🎯 [Biometric Auto] Onboarding nécessaire - redirection vers onboarding',
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      } else {
        debugPrint('✅ [Biometric Auto] Redirection vers home');
        _goToHome();
      }
    }
    // Si échec, ne pas afficher d'erreur, laisser l'utilisateur se connecter manuellement
  }

  Future<void> _performHealthCheck() async {
    if (_isCheckingHealth) return;
    setState(() => _isCheckingHealth = true);
    try {
      final ok = await _apiService.healthCheck();
      if (mounted) {
        setState(() {
          _dbHealthy = ok;
          _isCheckingHealth = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dbHealthy = false;
          _isCheckingHealth = false;
        });
      }
    }
  }

  Future<void> _onBiometricPressed() async {
    final hasConsent = await _authService.hasBiometricConsent();
    if (!hasConsent) {
      if (mounted) {
        AppSnackBar.info(
          context,
          'Connectez-vous d\'abord avec votre mot de passe pour activer la biométrie',
        );
      }
      return;
    }

    setState(() => _isAuthenticating = true);

    final result = await _authService
        .authenticateWithBiometricsAndCheckOnboarding();

    if (!mounted) return;

    setState(() => _isAuthenticating = false);

    if (result['status'] == AuthStatus.success) {
      final needsOnboarding = result['needsOnboarding'] as bool? ?? false;
      final userType = result['userType'] as String? ?? '';

      debugPrint(
        '🔍 [Biometric] Button - needsOnboarding=$needsOnboarding, userType=$userType',
      );

      if (needsOnboarding && userType.toLowerCase() == 'member') {
        debugPrint(
          '🎯 [Biometric] Button - Onboarding nécessaire - redirection vers onboarding',
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      } else {
        debugPrint('✅ [Biometric] Button - Redirection vers home');
        _goToHome();
      }
    } else {
      final status = result['status'] as AuthStatus;
      String message = 'Authentification biométrique échouée';
      switch (status) {
        case AuthStatus.noSavedCredentials:
          message = 'Aucun identifiant sauvegardé';
          break;
        case AuthStatus.serverUnavailable:
          message = 'Serveur indisponible';
          break;
        case AuthStatus.serverAuthFailed:
          message = 'Authentification serveur échouée';
          break;
        case AuthStatus.biometricFailed:
          message = 'Authentification biométrique échouée';
          break;
        case AuthStatus.error:
          message = 'Une erreur est survenue';
          break;
        default:
          break;
      }
      AppSnackBar.error(context, message);
    }
  }

  Future<void> _showOfflineQrCodeDialog() async {
    // Load cached QR code and profile
    final qrCodeBytes = await _authService.getQrCodeCache();
    final profileData = await _authService.getCachedUserProfile();

    if (!mounted) return;

    // Check if member has completed onboarding
    bool needsOnboarding = false;
    if (profileData != null) {
      final memberData = profileData['member'] as Map<String, dynamic>?;
      needsOnboarding =
          memberData?['onboarding'] as bool? ??
          profileData['onboarding'] as bool? ??
          true;
    }

    // If member needs onboarding, show message instead of QR code
    if (needsOnboarding) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_off_outlined,
                    size: 48,
                    color: context.palette.warning,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Inscription incomplète',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                Text(
                  'Votre inscription n\'est pas encore finalisée.',
                  style: TextStyle(
                    fontSize: 16,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Info message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: context.palette.info, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Veuillez vous connecter en ligne ultérieurement pour finaliser votre inscription et accéder à votre QR code.',
                          style: TextStyle(color: context.palette.info, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.palette.primaryFill,
                      foregroundColor:
                          (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Compris',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    if (qrCodeBytes == null) {
      AppSnackBar.warning(
        context,
        'Aucun QR code en cache. Connectez-vous en ligne pour le télécharger.',
      );
      return;
    }

    // Show QR code dialog
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with offline indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.palette.info, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off, color: context.palette.info, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Mode Hors Ligne',
                      style: TextStyle(
                        color: context.palette.info,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Votre QR Code',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
                ),
              ),
              const SizedBox(height: 20),

              // QR Code
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.memory(
                  Uint8List.fromList(qrCodeBytes),
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),

              // User info
              if (profileData != null) ...[
                Text(
                  getUserFullName(profileData),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (profileData['displayId'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      profileData['displayId'],
                      style: TextStyle(
                        color: context.palette.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              // Info message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: context.palette.info, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Présentez ce code au staff pour accéder à la salle',
                        style: TextStyle(color: context.palette.info, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.primaryFill,
                    foregroundColor:
                        (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _authenticateWithBiometrics({bool offlineMode = false}) async {
    final hasConsent = await _authService.hasBiometricConsent();
    if (!hasConsent) {
      if (mounted) {
        AppSnackBar.info(
          context,
          'Connectez-vous d\'abord avec votre mot de passe pour activer la biométrie',
        );
      }
      return;
    }

    setState(() => _isAuthenticating = true);

    // In offline mode, try to authenticate using cached data only
    if (offlineMode) {
      final result = await _authService.authenticateWithBiometricsOffline();

      if (!mounted) return;

      setState(() => _isAuthenticating = false);

      if (result['status'] == AuthStatus.success) {
        debugPrint('✅ [Biometric Offline] Success - Showing QR code');
        // Instead of going to home, show QR code dialog
        await _showOfflineQrCodeDialog();
      } else {
        final status = result['status'] as AuthStatus;
        String message = 'Authentification échouée';
        switch (status) {
          case AuthStatus.noSavedCredentials:
            message =
                'Aucune donnée en cache. Connectez-vous en ligne d\'abord.';
            break;
          case AuthStatus.biometricFailed:
            message = 'Authentification biométrique échouée';
            break;
          case AuthStatus.error:
            message = 'Une erreur est survenue';
            break;
          default:
            message = 'Impossible de se connecter en mode hors ligne';
            break;
        }
        AppSnackBar.error(context, message);
      }
      return;
    }

    // Online mode: regular authentication
    final result = await _authService
        .authenticateWithBiometricsAndCheckOnboarding();

    if (!mounted) return;

    setState(() => _isAuthenticating = false);

    if (result['status'] == AuthStatus.success) {
      final needsOnboarding = result['needsOnboarding'] as bool? ?? false;
      final userType = result['userType'] as String? ?? '';

      debugPrint(
        '🔍 [Biometric] Button - needsOnboarding=$needsOnboarding, userType=$userType',
      );

      if (needsOnboarding && userType.toLowerCase() == 'member') {
        debugPrint(
          '🎯 [Biometric] Button - Onboarding nécessaire - redirection vers onboarding',
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      } else {
        debugPrint('✅ [Biometric] Button - Redirection vers home');
        _goToHome();
      }
    } else {
      final status = result['status'] as AuthStatus;
      String message = 'Authentification biométrique échouée';
      switch (status) {
        case AuthStatus.noSavedCredentials:
          message = 'Aucun identifiant sauvegardé';
          break;
        case AuthStatus.serverUnavailable:
          message = 'Serveur indisponible';
          break;
        case AuthStatus.serverAuthFailed:
          message = 'Authentification serveur échouée';
          break;
        case AuthStatus.biometricFailed:
          message = 'Authentification biométrique échouée';
          break;
        case AuthStatus.error:
          message = 'Une erreur est survenue';
          break;
        default:
          break;
      }
      AppSnackBar.error(context, message);
    }
  }

  Future<void> _submitPassword() async {
    // Clean input by removing null bytes and control characters
    final email = _emailController.text.trim().replaceAll(
      RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F]'),
      '',
    );
    final password = _passwordController.text.replaceAll(
      RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F]'),
      '',
    );

    if (email.isEmpty || password.isEmpty) {
      AppSnackBar.error(
        context,
        AppLocalizations.of(context).fillEmailPassword,
      );
      return;
    }

    setState(() => _isAuthenticating = true);

    try {
      final loginResult = await _apiService.login(email, password);

      if (!mounted) return;

      if (loginResult != null) {
        debugPrint(
          '🔍 Login - loginResult est non-null, extraction des données...',
        );

        final token = loginResult['token'] as String;
        final userType = loginResult['userType'] as String;
        final userId = loginResult['userId'] as String;
        final needsOnboarding = loginResult['onboarding'] as bool? ?? true;

        debugPrint(
          '🔍 Login - onboarding value from server: ${loginResult['onboarding']}',
        );
        debugPrint(
          '🔍 Login - needsOnboarding: $needsOnboarding, userType: $userType',
        );

        await _authService.saveToken(token);
        await _authService.saveUserType(userType);
        await _authService.saveCredentials(email, password);

        // Fetch and cache user profile data
        await _authService.fetchAndCacheUserProfile(token);

        // Download and cache QR code for offline access (only for members)
        if (userType.toLowerCase() == 'member' && !needsOnboarding) {
          try {
            debugPrint('📥 Téléchargement du QR code pour le cache offline...');
            final qrCodeBytes = await _apiService.getUserQrCode(
              int.parse(userId),
              token,
            );
            if (qrCodeBytes != null) {
              await _authService.saveQrCodeCache(qrCodeBytes);
              debugPrint('✅ QR code mis en cache avec succès');
            } else {
              debugPrint('⚠️ Impossible de télécharger le QR code');
            }
          } catch (e) {
            debugPrint('❌ Erreur lors du téléchargement du QR code: $e');
            // Don't block login if QR code download fails
          }
        }

        // Small delay to ensure token is properly saved and validated
        await Future.delayed(const Duration(milliseconds: 100));

        // Send FCM token to server for push notifications (after JWT is saved and validated)
        try {
          debugPrint('🔍 Tentative de récupération du token FCM...');
          final fcmToken = await FCMService().getToken();
          debugPrint('🔍 Token FCM récupéré: $fcmToken');

          if (fcmToken != null && fcmToken.isNotEmpty) {
            debugPrint('📤 Envoi du token FCM au serveur (userId: $userId)...');
            final result = await _apiService.updateUserFCMToken(
              int.parse(userId),
              fcmToken,
              token,
            );
            debugPrint('✅ Réponse serveur pour FCM token: $result');
          } else {
            debugPrint('⚠️ Token FCM null ou vide, non envoyé au serveur');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ Erreur lors de l\'envoi du token FCM: $e');
          debugPrint('Stack trace: $stackTrace');
          // Don't block login if FCM token sending fails
        }

        // Demander le consentement biométrique si disponible et pas encore donné
        if (_canCheckBiometrics && !await _authService.hasBiometricConsent()) {
          await _showBiometricConsentDialog();
          final consentGiven = await _authService.hasBiometricConsent();
          // Envoyer le consentement biométrique en base de données
          try {
            await _apiService.updateUserProfile(int.parse(userId), {
              'biometricConsent': consentGiven,
            }, token);
          } catch (_) {}
          // Si consentement accordé, déclencher Face ID immédiatement pour confirmer
          if (mounted && consentGiven) {
            await _authService.promptBiometric(
              localizedReason:
                  'Confirmez votre identité pour activer la connexion biométrique',
            );
          }
        }
        // Le mot de passe n'est gardé que pour la reconnexion biométrique.
        if (!await _authService.isBiometricEnabled()) {
          await _authService.clearCredentials();
        }

        // Check if onboarding is needed for members who haven't completed it
        debugPrint(
          '🔍 Checking onboarding: needsOnboarding=$needsOnboarding, userType=$userType',
        );
        debugPrint(
          '🔍 Condition check: needsOnboarding=$needsOnboarding, isMember=${userType.toLowerCase() == 'member'}',
        );

        if (needsOnboarding && userType.toLowerCase() == 'member') {
          debugPrint('🎯 Onboarding nécessaire - redirection vers onboarding');
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        } else {
          debugPrint('✅ Redirection vers home (onboarding déjà fait)');
          _goToHome();
        }
      } else {
        AppSnackBar.error(
          context,
          AppLocalizations.of(context).invalidCredentials,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  void _forgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  Future<void> _showBiometricConsentDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fingerprint,
                  color: context.palette.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Authentification biométrique',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Voulez-vous activer l\'authentification biométrique (empreinte digitale ou reconnaissance faciale) pour vous connecter plus rapidement la prochaine fois ?',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _authService.setBiometricConsent(false);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(
                'Non merci',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _authService.setBiometricConsent(true);
                if (context.mounted) Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.palette.primaryFill,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Activer', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _goToHome() async {
    // Determine which home screen to show based on user type
    final userType = await _authService.getUserType();

    if (!mounted) return;

    Widget homeScreen;
    if (userType == 'manager' || userType == 'owner') {
      homeScreen = const AdminHomeScreen();
    } else if (userType == 'coach') {
      homeScreen = const CoachHomeScreen();
    } else {
      homeScreen = const MemberHomeScreen();
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => homeScreen));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ne plus vérifier la connexion à chaque reprise de l'app
    // La vérification est faite uniquement au lancement
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  isDark
                      ? Theme.of(context).cardTheme.color!
                      : AppColors.lightBackground.withValues(alpha: 0.6),
                ],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 900;
                  final isTablet =
                      constraints.maxWidth > 600 && constraints.maxWidth <= 900;
                  final isWatch = constraints.maxWidth < 300;

                  if (_isCheckingHealth) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: context.palette.primary,
                          ),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (context) => Text(
                              AppLocalizations.of(context).checkingConnection,
                              style: TextStyle(
                                color:
                                    (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (isDesktop) {
                    // Desktop layout: split screen
                    return Row(
                      children: [
                        // Left side - Branding
                        Expanded(
                          flex: 5,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.cardTheme.color ?? Colors.black,
                                  theme.scaffoldBackgroundColor,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/logo.png',
                                    width: 300,
                                    height: 300,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 24),
                                  Builder(
                                    builder: (context) => Text(
                                      AppLocalizations.of(
                                        context,
                                      ).gymManagement,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color:
                                            (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Right side - Login form
                        Expanded(
                          flex: 4,
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(48.0),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 400,
                                ),
                                child: _dbHealthy
                                    ? _buildOnlineContent(
                                        context,
                                        isDesktop: true,
                                      )
                                    : _buildOfflineContent(
                                        context,
                                        isDesktop: true,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Tablet or mobile layout
                  Widget content = Padding(
                    padding: EdgeInsets.all(isWatch ? 12.0 : 24.0),
                    child: _dbHealthy
                        ? _buildOnlineContent(context)
                        : _buildOfflineContent(context),
                  );

                  if (isTablet) {
                    content = Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: content,
                      ),
                    );
                  }

                  return content;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineContent(BuildContext context, {bool isDesktop = false}) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: isDesktop
            ? const BoxConstraints(minHeight: 400)
            : BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 48,
              ),
        child: IntrinsicHeight(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.wifi_off, color: context.palette.warning, size: 64),
                const SizedBox(height: 24),
                Text(
                  'Mode Hors Ligne',
                  style: TextStyle(
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Pas de connexion Internet détectée',
                  style: TextStyle(color: Colors.orange.shade400, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Biometric login button if available
                if (_canCheckBiometrics) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          size: 48,
                          color: context.palette.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Affichez votre QR code',
                          style: TextStyle(
                            color:
                                (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Authentifiez-vous pour afficher votre QR code en mode hors ligne',
                          style: TextStyle(
                            color:
                                (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isAuthenticating
                              ? null
                              : () => _authenticateWithBiometrics(
                                  offlineMode: true,
                                ),
                          icon: _isAuthenticating
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.fingerprint, size: 24),
                          label: Text(
                            _isAuthenticating
                                ? 'Authentification...'
                                : 'Afficher mon QR code',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.palette.primaryFill,
                            foregroundColor:
                                (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Info message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade400,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'En mode hors ligne, vous pouvez uniquement afficher votre QR code si vous l\'avez déjà téléchargé.',
                          style: TextStyle(
                            color: Colors.orange.shade400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Retry connection button
                OutlinedButton.icon(
                  onPressed: _performHealthCheck,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer la connexion'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.palette.primary,
                    side: BorderSide(color: context.palette.primary, width: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineContent(BuildContext context, {bool isDesktop = false}) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: isDesktop
            ? const BoxConstraints(minHeight: 400)
            : BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 48,
              ),
        child: IntrinsicHeight(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isDesktop) ...[
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TEAM',
                          style: AppTextStyles.h1.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          'OUSTAD',
                          style: AppTextStyles.h1.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
              Text(
                isDesktop
                    ? AppLocalizations.of(context).login
                    : AppLocalizations.of(context).welcomeLogin,
                textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                style: isDesktop ? AppTextStyles.h2 : AppTextStyles.h3,
              ),
              const SizedBox(height: 32),
              if (_canCheckBiometrics) ...[
                ModernButton(
                  text: AppLocalizations.of(context).signInBiometric,
                  icon: Icons.fingerprint,
                  onPressed: _isAuthenticating ? null : _onBiometricPressed,
                  isLoading: _isAuthenticating,
                  fullWidth: true,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).orUsePassword,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
              ModernTextField(
                controller: _emailController,
                label: AppLocalizations.of(context).emailOrPhone,
                prefixIcon: Icons.person,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              ModernTextField(
                controller: _passwordController,
                label: AppLocalizations.of(context).password,
                prefixIcon: Icons.lock,
                obscureText: _obscurePassword,
                suffixIcon: _obscurePassword
                    ? Icons.visibility
                    : Icons.visibility_off,
                onSuffixIconPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                onChanged: (_) {},
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: Text(AppLocalizations.of(context).forgotPassword),
                ),
              ),
              const SizedBox(height: 24),
              ModernButton(
                text: AppLocalizations.of(context).signIn,
                onPressed: _submitPassword,
                isLoading: _isAuthenticating,
                fullWidth: true,
              ),
              const SizedBox(height: 16),
              ModernButton(
                text: AppLocalizations.of(context).firstLogin,
                icon: Icons.person_add,
                variant: ModernButtonVariant.secondary,
                onPressed: _isAuthenticating
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SetupPasswordScreen(),
                          ),
                        );
                      },
                fullWidth: true,
              ),
              const SizedBox(height: 24),

              // Version info
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final version = snapshot.data!.version;
                    final build = snapshot.data!.buildNumber;
                    return Text(
                      'Version $version (Build $build)',
                      style: TextStyle(
                        fontSize: 12,
                        color: (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                      ),
                      textAlign: TextAlign.center,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
