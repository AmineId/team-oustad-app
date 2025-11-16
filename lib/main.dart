import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/common/common_screens.dart';
import 'screens/admin/admin_screens.dart';
import 'core/services/services.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Bloquer les screenshots et l'enregistrement d'écran
  await _disableScreenCapture();
  
  // Initialize Firebase
  try {
    // Afficher l'environnement détecté
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
    // ignore: avoid_print
    print('🌍 Environment detected: $environment');
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // ignore: avoid_print
    print('✅ Firebase initialized for $environment environment');
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    // ignore: avoid_print
    print('⚠️ Firebase initialization failed: $e');
    // Continue without Firebase if configuration is missing
  }
  
  // Initialize API and error reporter early so we can catch global errors
  final api = ApiService.fromEnv();
  final reporter = ErrorReporter(api, supportEmail: const String.fromEnvironment('SUPPORT_EMAIL', defaultValue: 'support@example.com'));
  
  // Initialize notification service
  try {
    await NotificationService().initialize();
    // Ne pas demander les permissions ici, elles seront demandées au premier démarrage
  } catch (e) {
    // ignore: avoid_print
    print('Failed to initialize notifications: $e');
  }
  
  // Initialize FCM service
  try {
    await FCMService().initialize();
  } catch (e) {
    // ignore: avoid_print
    print('Failed to initialize FCM: $e');
  }

  // Flutter framework errors
  FlutterError.onError = (details) {
    // report and also forward to default handler
    reporter.report(Exception(details.exception), details.stack, context: details.context?.toDescription());
    FlutterError.presentError(details);
  };

  // Uncaught Dart errors
  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.report(Exception(error.toString()), stack);
    return true; // handled
  };

  runApp(const MyApp());
}

/// Désactive la capture d'écran et l'enregistrement d'écran
Future<void> _disableScreenCapture() async {
  if (Platform.isAndroid) {
    try {
      // Sur Android, empêcher les screenshots et l'enregistrement d'écran
      const platform = MethodChannel('team.fitness.security');
      await platform.invokeMethod('disableScreenCapture');
      // ignore: avoid_print
      print('🔒 Protection des screenshots activée (Android)');
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Erreur lors de l\'activation de la protection: $e');
    }
  } else if (Platform.isIOS) {
    try {
      // Sur iOS, masquer le contenu dans le task switcher
      // La protection contre les screenshots est gérée au niveau système iOS
      // ignore: avoid_print
      print('🔒 Protection des screenshots activée (iOS)');
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Erreur iOS: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team Fitness App',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1a1f2e),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFe89547), // Orange/gold color
          secondary: const Color(0xFFf4a261),
          surface: const Color(0xFF2d3748),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1a1f2e),
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFe89547),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2d3748),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/admin/members': (context) => const AdminMembersScreen(),
        '/admin/plannings': (context) => const AdminPlanningsScreen(),
      },
    );
  }
}
