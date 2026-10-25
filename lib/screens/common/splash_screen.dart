import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../admin/admin_home_screen.dart';
import '../member/member_home_screen.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/app_version_service.dart';
import '../../core/utils/app_navigator.dart';
import '../../widgets/common/update_available_dialog.dart';
import '../../core/theme/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final ApiService _apiService;
  bool _dbHealthy = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService.fromEnv();
    _performHealthCheck();
  }

  Future<void> _performHealthCheck() async {
    try {
      _dbHealthy = await _apiService.healthCheck();
    } catch (e) {
      _dbHealthy = false;
    }

    // Vérifier si c'est le premier démarrage et proposer les notifications
    await _checkFirstLaunchAndRequestNotifications();

    // Vérifier en arrière-plan si une nouvelle version est disponible
    _checkForUpdates();

    // After health check, if we have a stored JWT validate it and
    // navigate directly to Home when valid. Otherwise go to Login.
    if (!mounted) return;
    try {
      final auth = AuthService(_apiService);
      await auth.clearStaleTokenOnFreshInstall();
      final token = await auth.loadToken();
      if (token != null) {
        final valid = _apiService.verifyToken(token);
        if (valid) {
          if (!mounted) return;

          // Determine which home screen based on user type
          final userType = await auth.getUserType();
          Widget homeScreen;
          if (userType == 'admin' || userType == 'owner') {
            homeScreen = const AdminHomeScreen();
          } else {
            homeScreen = const MemberHomeScreen();
          }

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => homeScreen),
            );
          }
          return;
        }
      }
    } catch (_) {
      // ignore and fall back to login screen
    }

    // Naviguer vers l'écran de connexion après le health check
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginScreen(initialDbHealthy: _dbHealthy),
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    try {
      final updateInfo = await AppVersionService().checkForUpdate();
      if (updateInfo == null) return;

      // Laisser l'utilisateur arriver sur l'écran suivant : le splash est
      // remplacé entre-temps, d'où le navigator racine.
      await Future.delayed(const Duration(seconds: 2));
      final navContext = appNavigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        showUpdateAvailableDialog(navContext, updateInfo);
      }
    } catch (e) {
      // Ignorer les erreurs silencieusement pour ne pas perturber l'expérience utilisateur
      debugPrint('Erreur lors de la vérification de version: $e');
    }
  }

  Future<void> _checkFirstLaunchAndRequestNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('first_launch') ?? true;

      if (isFirstLaunch) {
        // Marquer que ce n'est plus le premier lancement
        await prefs.setBool('first_launch', false);

        // Demander directement la permission système Android
        // (Android affichera sa propre popup système)
        if (mounted) {
          final granted = await NotificationService().requestPermissions();

          // Mettre à jour le profil utilisateur selon la réponse
          if (granted) {
            await prefs.setBool('notifications_enabled', true);

            // Mettre à jour le serveur si l'utilisateur est connecté
            try {
              final authService = AuthService(ApiService.fromEnv());
              final profileData = await authService.getCachedUserProfile();
              if (profileData != null) {
                final userId = profileData['id'] as int;
                final token = await authService.loadToken();

                if (token != null) {
                  await ApiService.fromEnv().updateUserProfile(userId, {
                    'notificationEnabled': true,
                  }, token);
                  await authService.refreshUserProfile();
                }
              }
            } catch (e) {
              debugPrint('Erreur lors de la mise à jour du profil: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification du premier lancement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).cardTheme.color!,
            ],
          ),
        ),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWatch = constraints.maxWidth < 300;
              final isDesktop = constraints.maxWidth > 600;

              final logoSize = isWatch ? 100.0 : (isDesktop ? 400.0 : 300.0);
              final fontSize = isWatch ? 11.0 : (isDesktop ? 20.0 : 16.0);
              final spacing = isWatch ? 16.0 : 32.0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: spacing),
                  Text(
                    'Votre partenaire fitness',
                    style: TextStyle(
                      fontSize: fontSize,
                      color: (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                    ),
                  ),
                  SizedBox(height: spacing + 16),
                  // Indicateur de chargement avec texte
                  Column(
                    children: [
                      CircularProgressIndicator(
                        color: context.palette.primary,
                        strokeWidth: isWatch ? 2.0 : 4.0,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Vérification de la connexion...',
                        style: TextStyle(
                          fontSize: isWatch ? 10 : 14,
                          color:
                              (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
