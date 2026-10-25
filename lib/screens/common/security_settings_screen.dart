import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/app_version_service.dart';
import '../../core/theme/theme.dart';
import '../../widgets/common/language_switcher_button.dart';
import '../../widgets/common/update_available_dialog.dart';
import '../../main.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage>
    with WidgetsBindingObserver {
  final AuthService _authService = AuthService(ApiService.fromEnv());
  final ApiService _apiService = ApiService.fromEnv();
  final AppVersionService _versionService = AppVersionService();
  bool _canCheckBiometrics = false;
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;
  bool _workoutNotificationsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Recharger les paramètres quand l'app revient au premier plan
    if (state == AppLifecycleState.resumed) {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final canCheck = await _authService.canCheckBiometrics();
      final bioEnabled = await _authService.hasBiometricConsent();
      final prefs = await SharedPreferences.getInstance();
      final notifEnabled = prefs.getBool('notifications_enabled') ?? true;

      // Charger les préférences de notification depuis le profil utilisateur
      final profileData = await _authService.getCachedUserProfile();
      bool workoutNotifEnabled = true;

      if (profileData != null) {
        // Charger depuis le membre si disponible
        final memberData = profileData['member'] as Map<String, dynamic>?;
        if (memberData != null &&
            memberData['workoutNotificationsEnabled'] != null) {
          workoutNotifEnabled =
              memberData['workoutNotificationsEnabled'] as bool;
        }
      }

      if (mounted) {
        setState(() {
          _canCheckBiometrics = canCheck;
          _biometricEnabled = bioEnabled;
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
          await _apiService.updateUserProfile(userId, {
            'notificationEnabled': value,
          }, token);

          // Si on désactive les notifications, mettre aussi workoutNotificationsEnabled à false
          if (!value) {
            await _apiService.updateMemberProfile(userId, {
              'workoutNotificationsEnabled': false,
            }, token);
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
                  color: value
                      ? context.palette.success
                      : (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value
                        ? 'Notifications activées'
                        : 'Notifications désactivées',
                    style: TextStyle(
                      color: (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: value
                ? Theme.of(context).cardTheme.color
                : Theme.of(context).cardTheme.color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: value
                    ? context.palette.success
                    : (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary)
                          .withValues(alpha: 0.38),
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
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: context.palette.error, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur lors de la sauvegarde',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).cardTheme.color,
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
          await _apiService.updateMemberProfile(userId, {
            'workoutNotificationsEnabled': value,
          }, token);

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
                  color: value
                      ? context.palette.success
                      : (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value
                        ? 'Notifications de planning activées'
                        : 'Notifications de planning désactivées',
                    style: TextStyle(
                      color: (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: value
                ? Theme.of(context).cardTheme.color
                : Theme.of(context).cardTheme.color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: value
                    ? context.palette.success
                    : (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary)
                          .withValues(alpha: 0.38),
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
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: context.palette.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur lors de la sauvegarde',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).cardTheme.color,
          ),
        );
      }
    }
  }

  /// Vérifie le mot de passe : contre les identifiants stockés quand il y en
  /// a (biométrie active), sinon auprès du serveur. Dans ce dernier cas ils
  /// sont mémorisés, car c'est l'activation de la biométrie qui le demande.
  Future<bool> _verifyPassword(String password) async {
    final stored = await _authService.loadCredentials();
    if (stored != null) return stored['password'] == password;
    final profile = await _authService.getCachedUserProfile();
    final email = profile?['email'] as String?;
    final identifier = (email != null && email.isNotEmpty)
        ? email
        : profile?['phoneNumber'] as String?;
    if (identifier == null || identifier.isEmpty) return false;
    final result = await _apiService.login(identifier, password);
    if (result == null) return false;
    // Un login ouvre une nouvelle session et invalide la précédente
    // (session unique côté serveur) : garder le nouveau token.
    await _authService.saveToken(result['token'] as String);
    await _authService.saveCredentials(identifier, password);
    return true;
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Sans biométrie, le mot de passe n'est pas conservé : le redemander.
      if (!await _authService.hasStoredCredentials()) {
        if (!await _showPasswordConfirmationDialog(enabling: true)) return;
      }
      // Activation: demander la biométrie immédiatement
      final authenticated = await _authService.promptBiometric(
        localizedReason: 'Authentifiez-vous pour activer la biométrie',
      );

      if (authenticated) {
        await _authService.setBiometricConsent(true);
        setState(() => _biometricEnabled = true);
        // Envoyer le consentement en base de données
        try {
          final profileData = await _authService.getCachedUserProfile();
          final token = await _authService.loadToken();
          if (profileData != null && token != null) {
            await _apiService.updateUserProfile(profileData['id'] as int, {
              'biometricConsent': true,
            }, token);
          }
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: context.palette.success,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Authentification biométrique activée',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Theme.of(context).cardTheme.color,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.palette.success, width: 1),
              ),
            ),
          );
        }
      }
    } else {
      // Désactivation: demander le mot de passe
      final confirmed = await _showPasswordConfirmationDialog();
      if (confirmed) {
        await _authService.setBiometricConsent(false);
        setState(() => _biometricEnabled = false);
        // Envoyer la révocation du consentement en base de données
        try {
          final profileData = await _authService.getCachedUserProfile();
          final token = await _authService.loadToken();
          if (profileData != null && token != null) {
            await _apiService.updateUserProfile(profileData['id'] as int, {
              'biometricConsent': false,
            }, token);
          }
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: context.palette.info,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Authentification biométrique désactivée',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Theme.of(context).cardTheme.color,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.palette.info, width: 1),
              ),
            ),
          );
        }
      }
    }
  }

  Future<bool> _showPasswordConfirmationDialog({bool enabling = false}) async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      color: AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.security,
                      color: context.palette.warning,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Confirmation requise',
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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pour des raisons de sécurité, veuillez confirmer votre mot de passe pour ${enabling ? 'activer' : 'désactiver'} l\'authentification biométrique.',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    autofocus: true,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      labelStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      prefixIcon: Icon(
                        Icons.lock,
                        color: context.palette.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: context.palette.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardTheme.color,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: context.palette.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    passwordController.dispose();
                    Navigator.of(context).pop(false);
                  },
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final password = passwordController.text;
                    if (password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez entrer votre mot de passe'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    // Vérifier le mot de passe
                    if (await _verifyPassword(password)) {
                      passwordController.dispose();
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mot de passe incorrect'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.primaryFill,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Confirmer',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
    return result ?? false;
  }

  Future<void> _checkForUpdates() async {
    // Afficher un dialog de chargement
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: context.palette.info)),
    );

    try {
      final updateInfo = await _versionService.checkForUpdate();

      if (!mounted) return;
      Navigator.pop(context); // Fermer le dialog de chargement

      if (updateInfo == null) {
        // Aucune mise à jour disponible
        _showUpdateDialog(
          title: 'Application à jour',
          message: 'Vous utilisez la dernière version de l\'application.',
          icon: Icons.check_circle_outline,
          iconColor: context.palette.success,
        );
      } else {
        // Mise à jour disponible
        showUpdateAvailableDialog(context, updateInfo);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      _showUpdateDialog(
        title: 'Erreur',
        message:
            'Impossible de vérifier les mises à jour. Vérifiez votre connexion.',
        icon: Icons.error_outline,
        iconColor: context.palette.error,
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
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: (Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary),
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'OK',
              style: TextStyle(color: context.palette.info, fontSize: 16),
            ),
          ),
        ],
      ),
    );
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
                ? [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).cardTheme.color!,
                  ]
                : [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).cardTheme.color!,
                  ],
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
                          icon: Icon(
                            Icons.arrow_back,
                            color: theme.textTheme.bodyLarge!.color,
                          ),
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
                                        color:
                                            theme.textTheme.bodyMedium!.color,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Toggle biométrie
                                    Card(
                                      color: theme.cardTheme.color,
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.fingerprint,
                                                color:
                                                    theme.colorScheme.primary,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Authentification biométrique',
                                                    style: AppTextStyles.body1
                                                        .copyWith(
                                                          color: theme
                                                              .textTheme
                                                              .bodyLarge!
                                                              .color,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _canCheckBiometrics
                                                        ? (_biometricEnabled
                                                              ? 'Connexion rapide avec empreinte/Face ID'
                                                              : 'Connexion par mot de passe uniquement')
                                                        : 'Non disponible sur cet appareil',
                                                    style: AppTextStyles.body2
                                                        .copyWith(
                                                          color: theme
                                                              .textTheme
                                                              .bodyMedium!
                                                              .color,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Switch(
                                              value: _biometricEnabled,
                                              onChanged: _canCheckBiometrics
                                                  ? _toggleBiometric
                                                  : null,
                                              activeThumbColor:
                                                  theme.colorScheme.primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Changer mot de passe
                                    Card(
                                      color: theme.cardTheme.color,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Fonctionnalité à venir',
                                              ),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.lock_outline,
                                                  color:
                                                      theme.colorScheme.primary,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  'Modifier le mot de passe',
                                                  style: AppTextStyles.body1
                                                      .copyWith(
                                                        color: theme
                                                            .textTheme
                                                            .bodyLarge!
                                                            .color,
                                                      ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                color: theme
                                                    .textTheme
                                                    .bodyMedium!
                                                    .color,
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
                                        color:
                                            theme.textTheme.bodyMedium!.color,
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
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.success
                                                        .withValues(alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.notifications_active,
                                                    color: context.palette.success,
                                                    size: 28,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Notifications',
                                                        style: TextStyle(
                                                          color:
                                                              (Theme.of(
                                                                    context,
                                                                  ).brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? AppColors
                                                                    .darkTextPrimary
                                                              : AppColors
                                                                    .lightTextPrimary),
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _notificationsEnabled
                                                            ? 'Recevoir les notifications push'
                                                            : 'Les notifications sont désactivées',
                                                        style: TextStyle(
                                                          color:
                                                              (Theme.of(
                                                                    context,
                                                                  ).brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? AppColors
                                                                    .darkTextSecondary
                                                              : AppColors
                                                                    .lightTextSecondary),
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Switch(
                                                  value: _notificationsEnabled,
                                                  onChanged:
                                                      _toggleNotifications,
                                                  activeTrackColor:
                                                      context.palette.success,
                                                  inactiveThumbColor:
                                                      (Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? AppColors
                                                            .darkTextSecondary
                                                      : AppColors
                                                            .lightTextSecondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Divider
                                          if (_notificationsEnabled)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20.0,
                                                  ),
                                              child: Divider(
                                                color: Theme.of(
                                                  context,
                                                ).dividerColor,
                                                height: 1,
                                              ),
                                            ),
                                          // Option notifications de planning (sub-option)
                                          if (_notificationsEnabled)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    20,
                                                    16,
                                                    20,
                                                    20,
                                                  ),
                                              child: Row(
                                                children: [
                                                  const SizedBox(
                                                    width: 56,
                                                  ), // Alignement avec le texte au-dessus
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Notifier mon planning',
                                                          style: TextStyle(
                                                            color:
                                                                (Theme.of(
                                                                      context,
                                                                    ).brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? AppColors
                                                                      .darkTextPrimary
                                                                : AppColors
                                                                      .lightTextPrimary),
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          'Recevoir des rappels pour vos séances d\'entraînement',
                                                          style: TextStyle(
                                                            color:
                                                                (Theme.of(
                                                                      context,
                                                                    ).brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? AppColors
                                                                      .darkTextSecondary
                                                                : AppColors
                                                                      .lightTextSecondary),
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Switch(
                                                    value:
                                                        _workoutNotificationsEnabled,
                                                    onChanged:
                                                        _notificationsEnabled
                                                        ? _toggleWorkoutNotifications
                                                        : null,
                                                    activeTrackColor:
                                                        context.palette.success,
                                                    inactiveThumbColor:
                                                        (Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? AppColors
                                                              .darkTextSecondary
                                                        : AppColors
                                                              .lightTextSecondary),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 32),

                                    // En-tête Section Apparence
                                    Text(
                                      'APPARENCE',
                                      style: AppTextStyles.caption.copyWith(
                                        color:
                                            theme.textTheme.bodyMedium!.color,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Toggle thème clair/sombre
                                    Builder(
                                      builder: (context) {
                                        final themeProvider =
                                            ThemeProviderScope.of(context);
                                        return Card(
                                          color: theme.cardTheme.color,
                                          child: Padding(
                                            padding: const EdgeInsets.all(20.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: (isDark
                                                        ? context.palette.primary
                                                        : context.palette.info)
                                                        .withValues(alpha: 0.2),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: AnimatedSwitcher(
                                                    duration: const Duration(
                                                      milliseconds: 300,
                                                    ),
                                                    transitionBuilder:
                                                        (child, animation) {
                                                          return RotationTransition(
                                                            turns: animation,
                                                            child:
                                                                ScaleTransition(
                                                                  scale:
                                                                      animation,
                                                                  child: child,
                                                                ),
                                                          );
                                                        },
                                                    child: Icon(
                                                      isDark
                                                          ? Icons
                                                                .dark_mode_rounded
                                                          : Icons
                                                                .light_mode_rounded,
                                                      key: ValueKey(isDark),
                                                      color: isDark
                                                          ? context.palette.info
                                                          : context.palette.warning,
                                                      size: 28,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Thème',
                                                        style: TextStyle(
                                                          color: isDark
                                                              ? AppColors
                                                                    .darkTextPrimary
                                                              : AppColors
                                                                    .lightTextPrimary,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        isDark
                                                            ? 'Mode sombre activé'
                                                            : 'Mode clair activé',
                                                        style: TextStyle(
                                                          color: isDark
                                                              ? AppColors
                                                                    .darkTextSecondary
                                                              : AppColors
                                                                    .lightTextSecondary,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                // Toggle stylé avec icônes
                                                GestureDetector(
                                                  onTap: () {
                                                    themeProvider.toggleTheme();
                                                  },
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 300,
                                                    ),
                                                    width: 56,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      gradient: LinearGradient(
                                                        colors: isDark
                                                            ? [
                                                                AppColors
                                                                    .darkSurface,
                                                                AppColors
                                                                    .darkElevated,
                                                              ]
                                                            : [
                                                                AppColors
                                                                    .info
                                                                    .withValues(
                                                                      alpha:
                                                                          0.3,
                                                                    ),
                                                                AppColors
                                                                    .infoLight
                                                                    .withValues(
                                                                      alpha:
                                                                          0.3,
                                                                    ),
                                                              ],
                                                      ),
                                                      border: Border.all(
                                                        color: isDark
                                                            ? context.palette.warning
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  )
                                                            : context.palette.info
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  ),
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: AnimatedAlign(
                                                      duration: const Duration(
                                                        milliseconds: 300,
                                                      ),
                                                      curve: Curves.easeInOut,
                                                      alignment: isDark
                                                          ? Alignment.centerRight
                                                          : Alignment.centerLeft,
                                                      child: Container(
                                                        width: 24,
                                                        height: 24,
                                                        margin: const EdgeInsets.all(2),
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          gradient: LinearGradient(
                                                            begin: Alignment.topLeft,
                                                            end: Alignment.bottomRight,
                                                            colors: isDark
                                                                ? [
                                                                    context.palette.warning,
                                                                    AppColors.warningLight,
                                                                  ]
                                                                : [
                                                                    context.palette.info,
                                                                    AppColors.infoLight,
                                                                  ],
                                                          ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: (isDark
                                                                      ? context.palette.warning
                                                                      : context.palette.info)
                                                                  .withValues(alpha: 0.4),
                                                              blurRadius: 8,
                                                              spreadRadius: 1,
                                                            ),
                                                          ],
                                                        ),
                                                        child: Icon(
                                                          isDark
                                                              ? Icons.nightlight_round
                                                              : Icons.wb_sunny_rounded,
                                                          size: 14,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    const SizedBox(height: 32),

                                    // En-tête Section Mises à jour
                                    Text(
                                      'APPLICATION',
                                      style: AppTextStyles.caption.copyWith(
                                        color:
                                            theme.textTheme.bodyMedium!.color,
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
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.info
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.system_update,
                                                  color: context.palette.info,
                                                  size: 28,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Builder(
                                                      builder: (context) => Text(
                                                        'Vérifier les mises à jour',
                                                        style: TextStyle(
                                                          color:
                                                              (Theme.of(
                                                                    context,
                                                                  ).brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? AppColors
                                                                    .darkTextPrimary
                                                              : AppColors
                                                                    .lightTextPrimary),
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Builder(
                                                      builder: (context) => Text(
                                                        'Maintenir l\'application à jour',
                                                        style: TextStyle(
                                                          color:
                                                              (Theme.of(
                                                                    context,
                                                                  ).brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? AppColors
                                                                    .darkTextSecondary
                                                              : AppColors
                                                                    .lightTextSecondary),
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                color:
                                                    (Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? AppColors
                                                          .darkTextSecondary
                                                    : AppColors
                                                          .lightTextSecondary),
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 32),

                                    // En-tête Section Langue
                                    Text(
                                      'LANGUE',
                                      style: AppTextStyles.caption.copyWith(
                                        color:
                                            theme.textTheme.bodyMedium!.color,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Bouton changement de langue
                                    Builder(
                                      builder: (context) {
                                        final localeService =
                                            LocaleServiceScope.of(context);
                                        return Card(
                                          color: theme.cardTheme.color,
                                          child: Padding(
                                            padding: const EdgeInsets.all(20.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: theme
                                                        .colorScheme
                                                        .primary
                                                        .withValues(alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.language,
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                    size: 28,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Langue / Language',
                                                        style: TextStyle(
                                                          color:
                                                              (Theme.of(
                                                                    context,
                                                                  ).brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? AppColors
                                                                    .darkTextPrimary
                                                              : AppColors
                                                                    .lightTextPrimary),
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        localeService
                                                            .getLocaleName(
                                                              localeService
                                                                  .currentLocale,
                                                            ),
                                                        style: TextStyle(
                                                          color:
                                                              (Theme.of(
                                                                    context,
                                                                  ).brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? AppColors
                                                                    .darkTextSecondary
                                                              : AppColors
                                                                    .lightTextSecondary),
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                // Utiliser directement le LanguageSwitcherButton
                                                LanguageSwitcherButton(
                                                  localeService: localeService,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
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
