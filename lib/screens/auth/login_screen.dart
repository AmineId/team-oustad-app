import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';
import '../../widgets/common/common_widgets.dart';
import '../admin/admin_home_screen.dart';
import '../member/member_home_screen.dart';
import '../member/onboarding_screen.dart';
import 'forgot_password_screen.dart';
import 'setup_password_screen.dart';
import '../../core/services/api_service.dart';
import '../../core/services/fcm_service.dart';

class LoginScreen extends StatefulWidget {
  final bool? initialDbHealthy;
  
  const LoginScreen({super.key, this.initialDbHealthy});

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
    
    // Tenter l'authentification biométrique automatiquement si disponible et DB OK
    if (_canCheckBiometrics && _dbHealthy) {
      // Petit délai pour laisser l'UI se charger
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _attemptBiometricLogin();
      }
    }
  }

  Future<void> _checkBiometricAvailability() async {
    _canCheckBiometrics = await _authService.canCheckBiometrics();
    if (mounted) setState(() {});
  }

  Future<void> _attemptBiometricLogin() async {
    // Ne rien faire si déjà en cours d'authentification
    if (_isAuthenticating) return;
    
    // Vérifier qu'il y a des credentials sauvegardés
    final hasCredentials = await _authService.hasStoredCredentials();
    if (!hasCredentials) return;
    
    setState(() => _isAuthenticating = true);
    
    final result = await _authService.authenticateWithBiometricsAndCheckOnboarding();
    
    if (!mounted) return;
    
    setState(() => _isAuthenticating = false);
    
    if (result['status'] == AuthStatus.success) {
      final needsOnboarding = result['needsOnboarding'] as bool? ?? false;
      final userType = result['userType'] as String? ?? '';
      
      debugPrint('🔍 [Biometric] needsOnboarding=$needsOnboarding, userType=$userType');
      
      if (needsOnboarding && userType.toLowerCase() == 'member') {
        debugPrint('🎯 [Biometric] Onboarding nécessaire - redirection vers onboarding');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      } else {
        debugPrint('✅ [Biometric] Redirection vers home');
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
    setState(() => _isAuthenticating = true);
    
    final result = await _authService.authenticateWithBiometricsAndCheckOnboarding();
    
    if (!mounted) return;
    
    setState(() => _isAuthenticating = false);
    
    if (result['status'] == AuthStatus.success) {
      final needsOnboarding = result['needsOnboarding'] as bool? ?? false;
      final userType = result['userType'] as String? ?? '';
      
      debugPrint('🔍 [Biometric] Button - needsOnboarding=$needsOnboarding, userType=$userType');
      
      if (needsOnboarding && userType.toLowerCase() == 'member') {
        debugPrint('🎯 [Biometric] Button - Onboarding nécessaire - redirection vers onboarding');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary), fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).cardTheme.color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.error, width: 1),
          ),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 200,
            left: 20,
            right: 20,
          ),
        ),
      );
    }
  }

  Future<void> _submitPassword() async {
    // Clean input by removing null bytes and control characters
    final email = _emailController.text.trim().replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F]'), '');
    final password = _passwordController.text.replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F]'), '');

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Veuillez saisir votre email/téléphone et mot de passe',
                  style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary), fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).cardTheme.color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.error, width: 1),
          ),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 200,
            left: 20,
            right: 20,
          ),
        ),
      );
      return;
    }

    setState(() => _isAuthenticating = true);

    try {
      final loginResult = await _apiService.login(email, password);
      
      debugPrint('🔍 Login - loginResult reçu: $loginResult');
      
      if (!mounted) return;

      if (loginResult != null) {
        debugPrint('🔍 Login - loginResult est non-null, extraction des données...');
        
        final token = loginResult['token'] as String;
        final userType = loginResult['userType'] as String;
        final userId = loginResult['userId'] as String;
        final needsOnboarding = loginResult['onboarding'] as bool? ?? true;
        
        debugPrint('🔍 Login - onboarding value from server: ${loginResult['onboarding']}');
        debugPrint('🔍 Login - needsOnboarding: $needsOnboarding, userType: $userType');
        
        await _authService.saveToken(token);
        await _authService.saveUserType(userType);
        await _authService.saveCredentials(email, password);
        
        // Fetch and cache user profile data
        await _authService.fetchAndCacheUserProfile(token);
        
        // Small delay to ensure token is properly saved and validated
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Send FCM token to server for push notifications (after JWT is saved and validated)
        try {
          debugPrint('🔍 Tentative de récupération du token FCM...');
          final fcmToken = await FCMService().getToken();
          debugPrint('🔍 Token FCM récupéré: $fcmToken');
          
          if (fcmToken != null && fcmToken.isNotEmpty) {
            debugPrint('📤 Envoi du token FCM au serveur (userId: $userId)...');
            debugPrint('🔑 JWT utilisé: ${token.substring(0, 20)}...');
            final result = await _apiService.updateUserFCMToken(int.parse(userId), fcmToken, token);
            debugPrint('✅ Réponse serveur pour FCM token: $result');
          } else {
            debugPrint('⚠️ Token FCM null ou vide, non envoyé au serveur');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ Erreur lors de l\'envoi du token FCM: $e');
          debugPrint('Stack trace: $stackTrace');
          // Don't block login if FCM token sending fails
        }
        
        // Check if onboarding is needed for members who haven't completed it
        debugPrint('🔍 Checking onboarding: needsOnboarding=$needsOnboarding, userType=$userType');
        debugPrint('🔍 Condition check: needsOnboarding=$needsOnboarding, isMember=${userType.toLowerCase() == 'member'}');
        
        if (needsOnboarding && userType.toLowerCase() == 'member') {
          debugPrint('🎯 Onboarding nécessaire - redirection vers onboarding');
          if (!context.mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        } else {
          debugPrint('✅ Redirection vers home (onboarding déjà fait)');
          _goToHome();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Builder(
                    builder: (context) => Text(
                      'Identifiants incorrects',
                      style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary), fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).cardTheme.color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.error, width: 1),
            ),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 200,
              left: 20,
              right: 20,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur: $e',
                    style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).cardTheme.color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.error, width: 1),
            ),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 200,
              left: 20,
              right: 20,
            ),
          ),
        );
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

  Future<void> _goToHome() async {
    // Determine which home screen to show based on user type
    final userType = await _authService.getUserType();
    
    if (!mounted) return;
    
    Widget homeScreen;
    if (userType == 'admin' || userType == 'owner') {
      homeScreen = const AdminHomeScreen();
    } else {
      homeScreen = const MemberHomeScreen();
    }
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => homeScreen),
    );
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [Theme.of(context).scaffoldBackgroundColor, Theme.of(context).cardTheme.color!]
              : [Theme.of(context).scaffoldBackgroundColor, Theme.of(context).cardTheme.color!],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              final isTablet = constraints.maxWidth > 600 && constraints.maxWidth <= 900;
              final isWatch = constraints.maxWidth < 300;
              
              if (_isCheckingHealth) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) => Text(
                          'Vérification de la connexion...',
                          style: TextStyle(color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary), fontSize: 16),
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
                              const Text(
                                'Team Fitness',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Builder(
                                builder: (context) => Text(
                                  'Gestion de votre salle de sport',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
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
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: _dbHealthy 
                                ? _buildOnlineContent(context, isDesktop: true)
                                : _buildOfflineContent(context, isDesktop: true),
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
    );
  }

  Widget _buildOfflineContent(BuildContext context, {bool isDesktop = false}) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: isDesktop 
            ? const BoxConstraints(minHeight: 400)
            : BoxConstraints(minHeight: MediaQuery.of(context).size.height - 48),
        child: IntrinsicHeight(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning,
                color: AppColors.warning,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Mode hors ligne',
                style: TextStyle(
                  color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Connexion à la base de données impossible.\nL\'app fonctionne en mode limité.',
                style: TextStyle(
                  color: Colors.orange.shade400,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 8),
              Text(
                'Vous pouvez toujours vous connecter en mode hors ligne si vous avez déjà un compte.',
                style: TextStyle(
                  color: Colors.orange.shade400,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
            : BoxConstraints(minHeight: MediaQuery.of(context).size.height - 48),
        child: IntrinsicHeight(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isDesktop) ...[
                Image.asset(
                  'assets/images/logo.png',
                  width: 240,
                  height: 240,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),
              ],
              Text(
                isDesktop ? 'Connexion' : 'Bienvenue\nConnectez-vous',
                textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                style: isDesktop ? AppTextStyles.h2 : AppTextStyles.h3,
              ),
              const SizedBox(height: 32),
              if (_canCheckBiometrics) ...[
                ModernButton(
                  text: 'Se connecter avec la biométrie',
                  icon: Icons.fingerprint,
                  onPressed: _isAuthenticating ? null : _onBiometricPressed,
                  isLoading: _isAuthenticating,
                  fullWidth: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'ou utilisez votre mot de passe', 
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
              ModernTextField(
                controller: _emailController,
                label: 'Email ou Numéro de téléphone',
                prefixIcon: Icons.person,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              ModernTextField(
                controller: _passwordController,
                label: 'Mot de passe',
                prefixIcon: Icons.lock,
                obscureText: _obscurePassword,
                suffixIcon: _obscurePassword ? Icons.visibility : Icons.visibility_off,
                onSuffixIconPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                onChanged: (_) {},
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _forgotPassword, child: const Text('Mot de passe oublié ?')),
              ),
              const SizedBox(height: 24),
              ModernButton(
                text: 'Se connecter',
                onPressed: _submitPassword,
                isLoading: _isAuthenticating,
                fullWidth: true,
              ),
              const SizedBox(height: 16),
              ModernButton(
                text: 'Première connexion',
                icon: Icons.person_add,
                variant: ModernButtonVariant.secondary,
                onPressed: _isAuthenticating ? null : () {
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
                        color: (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
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







