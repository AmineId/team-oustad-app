import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/ota_update_service.dart';
import '../../core/theme/theme.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final AuthService _authService = AuthService(ApiService.fromEnv());
  final ApiService _apiService = ApiService.fromEnv();
  final OTAUpdateService _otaService = OTAUpdateService();
  bool _canCheckBiometrics = false;
  bool _notificationsEnabled = true;
  bool _workoutNotificationsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final canCheck = await _authService.canCheckBiometrics();
      final prefs = await SharedPreferences.getInstance();
      final notifEnabled = prefs.getBool('notifications_enabled') ?? true;
      
      // Charger les préférences de notification depuis le profil utilisateur
      final profileData = await _authService.getCachedUserProfile();
      bool workoutNotifEnabled = true;
      
      if (profileData != null) {
        // Charger depuis le membre si disponible
        final memberData = profileData['member'] as Map<String, dynamic>?;
        if (memberData != null && memberData['workoutNotificationsEnabled'] != null) {
          workoutNotifEnabled = memberData['workoutNotificationsEnabled'] as bool;
        }
      }
      
      if (mounted) {
        setState(() {
          _canCheckBiometrics = canCheck;
          _notificationsEnabled = notifEnabled;
          _workoutNotificationsEnabled = workoutNotifEnabled;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
      // Si on désactive les notifications, désactiver aussi les notifications de planning
      if (!value) {
        _workoutNotificationsEnabled = false;
      }
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);
      
      // Mettre à jour le profil utilisateur
      final profileData = await _authService.getCachedUserProfile();
      if (profileData != null) {
        final userId = profileData['id'] as int;
        final token = await _authService.loadToken();
        
        if (token != null) {
          // Mettre à jour notificationEnabled sur l'utilisateur
          await _apiService.updateUserProfile(
            userId,
            {'notificationEnabled': value},
            token,
          );
          
          // Si on désactive les notifications, mettre aussi workoutNotificationsEnabled à false
          if (!value) {
            await _apiService.updateMemberProfile(
              userId,
              {'workoutNotificationsEnabled': false},
              token,
            );
          }
          
          // Rafraîchir le cache du profil
          await _authService.refreshUserProfile();
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  value ? Icons.notifications_active : Icons.notifications_off,
                  color: value ? AppColors.success : Colors.white70,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value 
                        ? 'Notifications activées'
                        : 'Notifications désactivées',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: value ? AppColors.darkCard : AppColors.darkCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: value ? AppColors.success : Colors.white38,
                width: 1,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _notificationsEnabled = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur lors de la sauvegarde',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.darkCard,
          ),
        );
      }
    }
  }

  Future<void> _toggleWorkoutNotifications(bool value) async {
    setState(() => _workoutNotificationsEnabled = value);
    
    try {
      // Mettre à jour le profil membre
      final profileData = await _authService.getCachedUserProfile();
      if (profileData != null) {
        final userId = profileData['id'] as int;
        final token = await _authService.loadToken();
        
        if (token != null) {
          // Mettre à jour workoutNotificationsEnabled sur le membre
          await _apiService.updateMemberProfile(
            userId,
            {'workoutNotificationsEnabled': value},
            token,
          );
          
          // Rafraîchir le cache du profil
          await _authService.refreshUserProfile();
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  value ? Icons.calendar_today : Icons.event_busy,
                  color: value ? AppColors.success : Colors.white70,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value 
                        ? 'Notifications de planning activées'
                        : 'Notifications de planning désactivées',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: value ? AppColors.darkCard : AppColors.darkCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: value ? AppColors.success : Colors.white38,
                width: 1,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _workoutNotificationsEnabled = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur lors de la sauvegarde',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.darkCard,
          ),
        );
      }
    }
  }

  Future<void> _checkForUpdates() async {
    // Afficher un dialog de chargement
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.info),
      ),
    );

    try {
      final updateInfo = await _otaService.checkForUpdate();
      
      if (!mounted) return;
      Navigator.pop(context); // Fermer le dialog de chargement

      if (updateInfo == null) {
        // Aucune mise à jour disponible
        _showUpdateDialog(
          title: 'Application à jour',
          message: 'Vous utilisez la dernière version de l\'application.',
          icon: Icons.check_circle_outline,
          iconColor: AppColors.success,
        );
      } else {
        // Mise à jour disponible
        _showUpdateAvailableDialog(updateInfo);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      _showUpdateDialog(
        title: 'Erreur',
        message: 'Impossible de vérifier les mises à jour. Vérifiez votre connexion.',
        icon: Icons.error_outline,
        iconColor: AppColors.error,
      );
    }
  }

  void _showUpdateDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('OK', style: TextStyle(color: AppColors.info, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateAvailableDialog(UpdateInfo updateInfo) async {
    final packageInfo = await PackageInfo.fromPlatform();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCard,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Mise à jour disponible',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${packageInfo.version} → ${updateInfo.latestVersion}',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (updateInfo.forceUpdate)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cette mise à jour est obligatoire',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            const Text(
              'Nouveautés :',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              updateInfo.changelog,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          if (!updateInfo.forceUpdate)
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Plus tard', style: TextStyle(color: Colors.white60, fontSize: 16)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(context);
              _startUpdateDownload(updateInfo);
            },
            child: const Text('Mettre à jour', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _startUpdateDownload(UpdateInfo updateInfo) {
    // Afficher un dialog de téléchargement avec progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.darkCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.download, color: AppColors.info, size: 28),
                SizedBox(width: 12),
                Text('Téléchargement', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: _otaService.downloadProgress,
                  backgroundColor: Colors.white24,
                  color: AppColors.info,
                ),
                const SizedBox(height: 16),
                Text(
                  '${(_otaService.downloadProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Démarrer le téléchargement
    _otaService.downloadAndInstallUpdate(
      updateInfo,
      onProgress: (progress) {
        // Mettre à jour l'UI avec le progrès (simplification ici)
        if (mounted) setState(() {});
      },
    ).then((success) {
      if (!mounted) return;
      Navigator.pop(context);
      
      if (success) {
        _showUpdateDialog(
          title: 'Téléchargement terminé',
          message: 'La mise à jour a été téléchargée. L\'application va redémarrer.',
          icon: Icons.check_circle_outline,
          iconColor: AppColors.success,
        );
      } else {
        _showUpdateDialog(
          title: 'Échec',
          message: 'Le téléchargement de la mise à jour a échoué.',
          icon: Icons.error_outline,
          iconColor: AppColors.error,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.darkBackground, AppColors.darkSurface]
                : [AppColors.lightBackground, AppColors.lightSurface],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 600;
              
              return Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyLarge!.color),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Paramètres',
                          style: AppTextStyles.h2.copyWith(
                            color: theme.textTheme.bodyLarge!.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isDesktop ? 600 : double.infinity,
                        ),
                        child: _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // En-tête Section Sécurité
                                    Text(
                                      'SÉCURITÉ',
                                      style: AppTextStyles.caption.copyWith(
                                        color: theme.textTheme.bodyMedium!.color,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Info sur la biométrie automatique
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.fingerprint,
                                            color: theme.colorScheme.primary,
                                            size: 32,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Authentification biométrique',
                                                  style: AppTextStyles.body1.copyWith(
                                                    color: theme.textTheme.bodyLarge!.color,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  _canCheckBiometrics
                                                      ? 'La biométrie est automatiquement activée sur votre appareil. Vous serez invité à vous authentifier avec votre empreinte digitale ou Face ID lors de la connexion.'
                                                      : 'La biométrie n\'est pas disponible sur cet appareil.',
                                                  style: AppTextStyles.body2.copyWith(
                                                    color: theme.textTheme.bodyMedium!.color,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    
                                    const SizedBox(height: 16),
                                    
                                    // Changer mot de passe
                                    Card(
                                      color: theme.cardTheme.color,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Fonctionnalité à venir'),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.lock_outline,
                                                  color: theme.colorScheme.primary,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  'Modifier le mot de passe',
                                                  style: AppTextStyles.body1.copyWith(
                                                    color: theme.textTheme.bodyLarge!.color,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                color: theme.textTheme.bodyMedium!.color,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 32),
                                    
                                    // En-tête Section Notifications
                                    Text(
                                      'NOTIFICATIONS',
                                      style: AppTextStyles.caption.copyWith(
                                        color: theme.textTheme.bodyMedium!.color,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Section Notifications
                                    Card(
                                      color: theme.cardTheme.color,
                                      child: Column(
                                        children: [
                                          // Toggle principal des notifications
                                          Padding(
                                            padding: const EdgeInsets.all(20.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.success.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Icon(
                                                    Icons.notifications_active,
                                                    color: AppColors.success,
                                                    size: 28,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text(
                                                        'Notifications',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _notificationsEnabled
                                                            ? 'Recevoir les notifications push'
                                                            : 'Les notifications sont désactivées',
                                                        style: TextStyle(
                                                          color: Colors.white.withValues(alpha: 0.6),
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Switch(
                                                  value: _notificationsEnabled,
                                                  onChanged: _toggleNotifications,
                                                  activeTrackColor: AppColors.success,
                                                  inactiveThumbColor: Colors.white60,
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Divider
                                          if (_notificationsEnabled)
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                              child: Divider(
                                                color: Colors.white.withValues(alpha: 0.1),
                                                height: 1,
                                              ),
                                            ),
                                          // Option notifications de planning (sub-option)
                                          if (_notificationsEnabled)
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                                              child: Row(
                                                children: [
                                                  const SizedBox(width: 56), // Alignement avec le texte au-dessus
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text(
                                                          'Notifier mon planning',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 15,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          'Recevoir des rappels pour vos séances d\'entraînement',
                                                          style: TextStyle(
                                                            color: Colors.white.withValues(alpha: 0.5),
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Switch(
                                                    value: _workoutNotificationsEnabled,
                                                    onChanged: _notificationsEnabled ? _toggleWorkoutNotifications : null,
                                                    activeTrackColor: AppColors.success,
                                                    inactiveThumbColor: Colors.white60,
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 32),
                                    
                                    // En-tête Section Mises à jour
                                    Text(
                                      'APPLICATION',
                                      style: AppTextStyles.caption.copyWith(
                                        color: theme.textTheme.bodyMedium!.color,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Section Mises à jour
                                    Card(
                                      color: theme.cardTheme.color,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: _checkForUpdates,
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: AppColors.info.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.system_update,
                                                  color: AppColors.info,
                                                  size: 28,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              const Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Vérifier les mises à jour',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      'Maintenir l\'application à jour',
                                                      style: TextStyle(
                                                        color: Colors.white60,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.arrow_forward_ios,
                                                color: Colors.white60,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
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

