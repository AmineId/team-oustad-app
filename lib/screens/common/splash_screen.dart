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
      final token = await auth.loadToken();
      if (token != null) {
        final valid = await _apiService.verifyToken(token);
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
        
        // Afficher le dialog de demande de notifications
        if (mounted) {
          await _showNotificationPermissionDialog();
        }
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Erreur lors de la vérification du premier lancement: $e');
    }
  }

  Future<void> _showNotificationPermissionDialog() async {
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
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: AppColors.success,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Builder(
                  builder: (context) => Text(
                    'Notifications',
                    style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary), fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          content: Builder(
            builder: (context) => Text(
              'Souhaitez-vous recevoir des notifications pour rester informé des nouveautés, rappels d\'entraînement et messages importants ?',
              style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary), fontSize: 15),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Builder(
                builder: (context) => Text(
                  'Plus tard',
                  style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Theme.of(context).brightness == Brightness.dark ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : AppColors.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Activer',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                // Demander les permissions
                await NotificationService().requestPermissions();
                
                // Activer les notifications par défaut
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('notifications_enabled', true);
              },
            ),
          ],
        );
      },
    );
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
                      color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
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
                          color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
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
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final otaService = OTAUpdateService();
      final success = await otaService.downloadAndInstallUpdate(
        widget.updateInfo,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );

      if (!mounted) return;

      if (success) {
        // L'installateur Android s'est ouvert automatiquement
        Navigator.pop(context);
      } else {
        setState(() {
          _isDownloading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors du téléchargement'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
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
                style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary), fontSize: 18, fontWeight: FontWeight.bold),
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
                border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Builder(
                      builder: (context) => Text(
                        'Cette mise à jour est obligatoire',
                        style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            'Version: ${widget.updateInfo.currentVersion} → ${widget.updateInfo.latestVersion}',
            style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary), fontSize: 14),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) => Text(
              'Nouveautés :',
              style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary), fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.updateInfo.changelog,
            style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary), fontSize: 14),
          ),
          if (_isDownloading) ...[
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.info),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              'Téléchargement en cours... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        if (!_isDownloading && !widget.updateInfo.forceUpdate)
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Builder(
              builder: (context) => Text('Plus tard', style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary), fontSize: 16)),
            ),
          ),
        if (!_isDownloading)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Theme.of(context).brightness == Brightness.dark ? (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary) : AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _startDownload,
            child: const Text('Mettre à jour', style: TextStyle(fontSize: 16)),
          ),
      ],
    );
  }
}





