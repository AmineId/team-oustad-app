import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configuration Firebase multi-environnement
/// Lit la variable ENVIRONMENT depuis --dart-define pour sélectionner la bonne config
/// 
/// Environnements supportés:
/// - dev: Développement local (pprod config)
/// - pprod: Pré-production
/// - prod: Production
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Lire l'environnement depuis --dart-define
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
    
    if (kIsWeb) {
      return _getWebOptions(environment);
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _getAndroidOptions(environment);
      case TargetPlatform.iOS:
        return _getIosOptions(environment);
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Configuration Android selon l'environnement
  static FirebaseOptions _getAndroidOptions(String environment) {
    switch (environment) {
      case 'prod':
        return _androidProd;
      case 'pprod':
      case 'dev':
      default:
        return _androidPprod;
    }
  }

  // Configuration iOS selon l'environnement
  static FirebaseOptions _getIosOptions(String environment) {
    switch (environment) {
      case 'prod':
        return _iosProd;
      case 'pprod':
      case 'dev':
      default:
        return _iosPprod;
    }
  }

  // Configuration Web selon l'environnement
  static FirebaseOptions _getWebOptions(String environment) {
    switch (environment) {
      case 'prod':
        return _webProd;
      case 'pprod':
      case 'dev':
      default:
        return _webPprod;
    }
  }

  // === PRE-PRODUCTION CONFIGS ===
  
  static const FirebaseOptions _webPprod = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions _androidPprod = FirebaseOptions(
    apiKey: 'AIzaSyAjjOJpnbk8Zw_8VwBNyJ3SyYcdwdTvlq5qiNLju7FTnk',
    appId: '1:1056504785579:android:9ccdd64c4d390ac7ebe5ee',
    messagingSenderId: '1056504785579',
    projectId: 'team-fitness-app-29fa1',
    storageBucket: 'team-fitness-app-29fa1.firebasestorage.app',
  );

  static const FirebaseOptions _iosPprod = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.teamfitness.app',
  );

  // === PRODUCTION CONFIGS ===
  
  static const FirebaseOptions _webProd = FirebaseOptions(
    apiKey: 'YOUR_WEB_PROD_API_KEY',
    appId: 'YOUR_WEB_PROD_APP_ID',
    messagingSenderId: 'YOUR_PROD_SENDER_ID',
    projectId: 'YOUR_PROD_PROJECT_ID',
    authDomain: 'YOUR_PROD_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROD_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions _androidProd = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_PROD_API_KEY',
    appId: 'YOUR_ANDROID_PROD_APP_ID',
    messagingSenderId: 'YOUR_PROD_SENDER_ID',
    projectId: 'YOUR_PROD_PROJECT_ID',
    storageBucket: 'YOUR_PROD_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions _iosProd = FirebaseOptions(
    apiKey: 'YOUR_IOS_PROD_API_KEY',
    appId: 'YOUR_IOS_PROD_APP_ID',
    messagingSenderId: 'YOUR_PROD_SENDER_ID',
    projectId: 'YOUR_PROD_PROJECT_ID',
    storageBucket: 'YOUR_PROD_PROJECT_ID.appspot.com',
    iosBundleId: 'com.teamfitness.app.prod',
  );
}



