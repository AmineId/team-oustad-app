import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../admin/admin_home_screen.dart';
import '../member/member_home_screen.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/ota_update_service.dart';
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

    // Vérifier automatiquement les mises à jour OTA en arrière-plan
    _checkForOTAUpdates();

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

  Future<void> _checkForOTAUpdates() async {
    try {
      final otaService = OTAUpdateService();
      final updateInfo = await otaService.checkForUpdate();

      if (updateInfo != null && mounted) {
        // Attendre un peu pour laisser l'utilisateur arriver sur l'écran d'accueil
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          _showOTAUpdateDialog(updateInfo);
        }
      }
    } catch (e) {
      // Ignorer les erreurs silencieusement pour ne pas perturber l'expérience utilisateur
      // ignore: avoid_print
      debugPrint('Erreur lors de la vérification OTA: $e');
    }
  }

  void _showOTAUpdateDialog(dynamic updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) => _OTAUpdateDialog(updateInfo: updateInfo),
    );
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
                        color: AppColors.primary,
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

// Dialog widget pour afficher et gérer la mise à jour OTA
class _OTAUpdateDialog extends StatefulWidget {
  final dynamic updateInfo;

  const _OTAUpdateDialog({required this.updateInfo});

  @override
  State<_OTAUpdateDialog> createState() => _OTAUpdateDialogState();
}

class _OTAUpdateDialogState extends State<_OTAUpdateDialog> {
  Future<void> _openPlayStore() async {
    try {
      final otaService = OTAUpdateService();
      final success = await otaService.openPlayStoreForUpdate(
        widget.updateInfo,
      );

      if (!mounted) return;

      if (success) {
        // Le Play Store s'est ouvert
        Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'ouverture du Play Store'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.system_update,
              color: AppColors.info,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Builder(
              builder: (context) => Text(
                'Mise à jour disponible',
                style: TextStyle(
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.updateInfo.forceUpdate)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Builder(
                      builder: (context) => Text(
                        'Cette mise à jour est obligatoire',
                        style: TextStyle(
                          color:
                              (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            'Version: ${widget.updateInfo.currentVersion} → ${widget.updateInfo.latestVersion}',
            style: TextStyle(
              color: (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) => Text(
              'Nouveautés :',
              style: TextStyle(
                color: (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.updateInfo.changelog,
            style: TextStyle(
              color: (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary),
              fontSize: 14,
            ),
          ),
        ],
      ),
      actions: [
        if (!widget.updateInfo.forceUpdate)
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Builder(
              builder: (context) => Text(
                'Plus tard',
                style: TextStyle(
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.info,
            foregroundColor: Theme.of(context).brightness == Brightness.dark
                ? (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary)
                : AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _openPlayStore,
          child: const Text(
            'Ouvrir Play Store',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
