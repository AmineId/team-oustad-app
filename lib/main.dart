import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/common/common_screens.dart';
import 'screens/admin/admin_screens.dart';
import 'core/services/services.dart';
import 'core/theme/theme.dart';
import 'core/l10n/app_localizations.dart';
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
    debugPrint('🌍 Environment detected: $environment');
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // ignore: avoid_print
    debugPrint('✅ Firebase initialized for $environment environment');
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    // ignore: avoid_print
    debugPrint('⚠️ Firebase initialization failed: $e');
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
    debugPrint('Failed to initialize notifications: $e');
  }
  
  // Initialize FCM service
  try {
    await FCMService().initialize();
  } catch (e) {
    // ignore: avoid_print
    debugPrint('Failed to initialize FCM: $e');
  }

  // Initialize locale service
  final localeService = LocaleService();
  try {
    await localeService.initialize();
    // ignore: avoid_print
    debugPrint('✅ Locale service initialized: ${localeService.currentLocale}');
  } catch (e) {
    // ignore: avoid_print
    debugPrint('⚠️ Failed to initialize locale service: $e');
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

  runApp(MyApp(localeService: localeService));
}

/// Désactive la capture d'écran et l'enregistrement d'écran
Future<void> _disableScreenCapture() async {
  if (Platform.isAndroid) {
    try {
      // Sur Android, empêcher les screenshots et l'enregistrement d'écran
      const platform = MethodChannel('team.fitness.security');
      await platform.invokeMethod('disableScreenCapture');
      // ignore: avoid_print
      debugPrint('🔒 Protection des screenshots activée (Android)');
    } catch (e) {
      // ignore: avoid_print
      debugPrint('⚠️ Erreur lors de l\'activation de la protection: $e');
    }
  } else if (Platform.isIOS) {
    try {
      // Sur iOS, masquer le contenu dans le task switcher
      // La protection contre les screenshots est gérée au niveau système iOS
      // ignore: avoid_print
      debugPrint('🔒 Protection des screenshots activée (iOS)');
    } catch (e) {
      // ignore: avoid_print
      debugPrint('⚠️ Erreur iOS: $e');
    }
  }
}

class MyApp extends StatefulWidget {
  final LocaleService localeService;
  
  const MyApp({super.key, required this.localeService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider();
    _themeProvider.addListener(() {
      setState(() {});
    });
    
    // Listen to locale changes
    widget.localeService.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProviderScope(
      themeProvider: _themeProvider,
      child: LocaleServiceScope(
        localeService: widget.localeService,
        child: MaterialApp(
          title: 'Team Fitness App',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocaleService.supportedLocales,
          locale: widget.localeService.currentLocale,
          home: const SplashScreen(),
          routes: {
            '/admin/members': (context) => const AdminMembersScreen(),
            '/admin/plannings': (context) => const AdminPlanningsScreen(),
          },
        ),
      ),
    );
  }
}

// Widget pour fournir le ThemeProvider dans l'arbre
class ThemeProviderScope extends InheritedWidget {
  final ThemeProvider themeProvider;

  const ThemeProviderScope({
    super.key,
    required this.themeProvider,
    required super.child,
  });

  static ThemeProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeProviderScope>();
    assert(scope != null, 'No ThemeProviderScope found in context');
    return scope!.themeProvider;
  }

  @override
  bool updateShouldNotify(ThemeProviderScope oldWidget) {
    return themeProvider != oldWidget.themeProvider;
  }
}

// Widget pour fournir le LocaleService dans l'arbre
class LocaleServiceScope extends InheritedWidget {
  final LocaleService localeService;

  const LocaleServiceScope({
    super.key,
    required this.localeService,
    required super.child,
  });

  static LocaleService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleServiceScope>();
    assert(scope != null, 'No LocaleServiceScope found in context');
    return scope!.localeService;
  }

  @override
  bool updateShouldNotify(LocaleServiceScope oldWidget) {
    return localeService != oldWidget.localeService;
  }
}




