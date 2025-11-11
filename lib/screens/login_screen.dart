import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_home_screen.dart';
import 'member_home_screen.dart';
import 'forgot_password_screen.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';

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
  bool _biometricEnabled = false;
  bool _canCheckBiometrics = false;

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
    if (!_dbHealthy) {
      await _performHealthCheck();
    }
  }

  Future<void> _checkBiometricAvailability() async {
    _canCheckBiometrics = await _authService.canCheckBiometrics();
    _biometricEnabled = await _authService.isBiometricEnabled();
    if (mounted) setState(() {});
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
    
    final status = await _authService.authenticateWithBiometrics();
    
    if (!mounted) return;
    
    setState(() => _isAuthenticating = false);
    
    if (status == AuthStatus.success) {
      _goToHome();
    } else {
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
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
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
          content: const Text(
            'Veuillez remplir tous les champs',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
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
      
      if (!mounted) return;

      if (loginResult != null) {
        final token = loginResult['token'] as String;
        final userType = loginResult['userType'] as String;
        final userId = loginResult['userId'] as String;
        
        await _authService.saveToken(token);
        await _authService.saveUserType(userType);
        await _authService.saveCredentials(email, password);
        
        // Fetch and cache user profile data
        await _authService.fetchAndCacheUserProfile(token);
        
        // Small delay to ensure token is properly saved and validated
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Send FCM token to server for push notifications (after JWT is saved and validated)
        try {
          // ignore: avoid_print
          print('🔍 Tentative de récupération du token FCM...');
          final fcmToken = await FCMService().getToken();
          // ignore: avoid_print
          print('🔍 Token FCM récupéré: $fcmToken');
          
          if (fcmToken != null && fcmToken.isNotEmpty) {
            // ignore: avoid_print
            print('📤 Envoi du token FCM au serveur (userId: $userId)...');
            // ignore: avoid_print
            print('🔑 JWT utilisé: ${token.substring(0, 20)}...');
            final result = await _apiService.updateUserFCMToken(int.parse(userId), fcmToken, token);
            // ignore: avoid_print
            print('✅ Réponse serveur pour FCM token: $result');
          } else {
            // ignore: avoid_print
            print('⚠️ Token FCM null ou vide, non envoyé au serveur');
          }
        } catch (e, stackTrace) {
          // ignore: avoid_print
          print('❌ Erreur lors de l\'envoi du token FCM: $e');
          // ignore: avoid_print
          print('Stack trace: $stackTrace');
          // Don't block login if FCM token sending fails
        }
        
        if (_canCheckBiometrics && !_biometricEnabled) {
          await _askEnableBiometric();
        } else {
          _goToHome();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Email ou mot de passe incorrect',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
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
            content: Text(
              'Erreur: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
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

  Future<void> _askEnableBiometric() async {
    final choice = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Activer l\'authentification biométrique ?'),
        content: const Text(
          'Voulez-vous activer l\'authentification biométrique pour des connexions plus rapides ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (choice == true) {
      setState(() => _isAuthenticating = true);

      final enrolled = await _authService.promptBiometric(
          localizedReason: 'Authentifiez-vous pour activer la biométrie');

      if (!mounted) return;

      setState(() => _isAuthenticating = false);

      if (enrolled) {
        await _authService.setBiometricEnabled(true);

        // Clean input by removing null bytes and control characters
        final email = _emailController.text.trim().replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F]'), '');
        final pwd = _passwordController.text.replaceAll(RegExp(r'[\x00-\x08\x0B-\x0C\x0E-\x1F]'), '');
        if (email.isNotEmpty && pwd.isNotEmpty) {
          await _authService.saveCredentials(email, pwd);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Biométrie activée',
                textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height - 200,
                left: 20,
                right: 20,
              ),
            ),
          );
        }
      } else {
        await _authService.setBiometricEnabled(false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Activation biométrique échouée',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
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

      _goToHome();
    } else {
      await _authService.setBiometricEnabled(false);
      _goToHome();
    }
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
    if (state == AppLifecycleState.resumed) {
      _performHealthCheck();
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
            colors: [const Color(0xFF1a1f2e), const Color(0xFF2d3748)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _isCheckingHealth
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFe89547)),
                        SizedBox(height: 16),
                        Text(
                          'Vérification de la connexion à la base de données...',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : (_dbHealthy ? _buildOnlineContent(context) : _buildOfflineContent(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineContent(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 48),
        child: IntrinsicHeight(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning,
                color: Colors.orange,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Mode hors ligne',
                style: TextStyle(
                  color: Colors.white,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      setState(() => _isCheckingHealth = true);
                      try {
                        final ok = await _apiService.healthCheck();
                        _dbHealthy = ok;
                      } catch (e) {
                        _dbHealthy = false;
                      }
                      if (mounted) setState(() => _isCheckingHealth = false);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineContent(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 48),
        child: IntrinsicHeight(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 240,
                height: 240,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              const Text(
                'Bienvenue\nConnectez-vous',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 32),
              if (_biometricEnabled && _canCheckBiometrics) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.fingerprint, size: 28),
                  label: const Text(
                    'Se connecter avec la biométrie',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  onPressed: _isAuthenticating ? null : _onBiometricPressed,
                ),
                const SizedBox(height: 16),
                const Text('ou utilisez votre mot de passe', style: TextStyle(color: Colors.white60)),
                const SizedBox(height: 16),
              ] else if (!_biometricEnabled && _canCheckBiometrics) ...[
                const Text(
                  'Se connecter avec votre mot de passe.\nVous pourrez activer la biométrie après.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const Text('Biométrie non disponible sur cet appareil', style: TextStyle(color: Colors.white60)),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email, color: Color(0xFFe89547)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: Icon(Icons.lock, color: Color(0xFFe89547)),
                ),
                onSubmitted: (_) => _submitPassword(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _forgotPassword, child: const Text('Mot de passe oublié ?')),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isAuthenticating ? null : _submitPassword,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                  child: _isAuthenticating
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Se connecter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
