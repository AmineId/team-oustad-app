import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/common/common_screens.dart';
import 'screens/admin/admin_screens.dart';
import 'screens/kiosk/kiosk_screens.dart';
import 'core/services/services.dart';
import 'core/utils/app_navigator.dart';
import 'core/theme/theme.dart';
import 'core/l10n/app_localizations.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Captures d'écran bloquées uniquement sur les écrans sensibles
  // (voir SecureScreen / ScreenSecurityService)
  
  // Initialize Firebase
  try {
    // Afficher l'environnement détecté
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
    // ignore: avoid_print
    debugPrint('🌍 Environment detected: $environment');

    // Sur iOS, vérifier que le bundle ID du plist Firebase correspond à l'app
    // (peut différer après re-signature xtool avec un Apple ID gratuit)
    bool canInitFirebase = true;
    if (!kIsWeb && Platform.isIOS) {
      try {
        const securityChannel = MethodChannel('team.oustad.security');
        canInitFirebase = await securityChannel.invokeMethod<bool>('checkFirebasePlistBundle') ?? false;
        if (!canInitFirebase) {
          debugPrint('⚠️ Firebase: bundle ID mismatch (xtool signing), skipping init');
        }
      } catch (_) {
        canInitFirebase = false;
      }
    }

    if (canInitFirebase) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // ignore: avoid_print
      debugPrint('✅ Firebase initialized for $environment environment');

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  } catch (e) {
    // ignore: avoid_print
    debugPrint('⚠️ Firebase initialization failed: $e');
    // Continue without Firebase if configuration is missing
  }
  
  // Initialize API and error reporter early so we can catch global errors
  ApiService.fromEnv();
  final reporter = ErrorReporter(supportEmail: const String.fromEnvironment('SUPPORT_EMAIL', defaultValue: 'support@example.com'));
  
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
    // `silent` is how Flutter marks errors that were already handled
    // elsewhere (e.g. Image.network's errorBuilder already shows a
    // fallback for a decode failure) — reporting those too just pops an
    // unwanted crash-report email for something the UI already recovered
    // from. Still forward to the default handler either way.
    if (!details.silent) {
      reporter.report(Exception(details.exception), details.stack, context: details.context?.toDescription());
    }
    FlutterError.presentError(details);
  };

  // Uncaught Dart errors
  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.report(Exception(error.toString()), stack);
    return true; // handled
  };

  runApp(MyApp(localeService: localeService));
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
  }

  @override
  void dispose() {
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('MyApp: build called');
    return ListenableBuilder(
      listenable: Listenable.merge([_themeProvider, widget.localeService]),
      builder: (context, child) {
        debugPrint('MyApp: ListenableBuilder rebuild. Locale: ${widget.localeService.currentLocale}');
        return ThemeProviderScope(
          themeProvider: _themeProvider,
          child: LocaleServiceScope(
            localeService: widget.localeService,
            child: MaterialApp(
              navigatorKey: appNavigatorKey,
              title: 'Team Oustad',
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
              // Deux builds web distincts (WEB_TARGET) partagent ce même code :
              // kiosk.team-oustad.com (borne d'accueil, check-in) et
              // team-oustad.com (page vitrine publique des salles). Hors web,
              // c'est toujours le flow normal (splash/login).
              home: !kIsWeb
                  ? const SplashScreen()
                  : (const String.fromEnvironment('WEB_TARGET', defaultValue: 'kiosk') == 'showcase'
                      ? const GymShowcaseListScreen()
                      : const CheckinTerminalScreen()),
              routes: {
                '/admin/members': (context) => const AdminMembersScreen(),
                '/admin/plannings': (context) => const AdminPlanningsScreen(),
              },
            ),
          ),
        );
      },
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
    return true;
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
    return true;
  }
}




