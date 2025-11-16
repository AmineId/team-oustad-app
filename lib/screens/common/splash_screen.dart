import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../admin/admin_home_screen.dart';
import '../member/member_home_screen.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';

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
      print('Erreur lors de la vérification du premier lancement: $e');
    }
  }

  Future<void> _showNotificationPermissionDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2d3748),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Color(0xFF4CAF50),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'Souhaitez-vous recevoir des notifications pour rester informé des nouveautés, rappels d\'entraînement et messages importants ?',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Plus tard',
                style: TextStyle(color: Colors.white60),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
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
              const Color(0xFF1a1f2e),
              const Color(0xFF2d3748),
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
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: spacing + 16),
                  // Indicateur de chargement avec texte
                  Column(
                    children: [
                      CircularProgressIndicator(
                        color: const Color(0xFFe89547),
                        strokeWidth: isWatch ? 2.0 : 4.0,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Vérification de la connexion...',
                        style: TextStyle(
                          fontSize: isWatch ? 10 : 14,
                          color: Colors.white70,
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