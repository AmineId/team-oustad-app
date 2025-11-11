import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configuration Firebase par défaut pour votre projet
/// 
/// IMPORTANT: Vous devez remplacer ces valeurs par celles de votre projet Firebase
/// 
/// Pour obtenir ces valeurs:
/// 1. Allez sur https://console.firebase.google.com
/// 2. Sélectionnez votre projet ou créez-en un nouveau
/// 3. Allez dans les paramètres du projet (icône engrenage)
/// 4. Faites défiler jusqu'à "Vos applications"
/// 5. Cliquez sur "Ajouter une application" et choisissez la plateforme
/// 6. Suivez les instructions pour obtenir les clés
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAjjOJpnbk8Zw_8VwBNyJ3SyYcdwdTvlq5qiNLju7FTnk',
    appId: '1:1056504785579:android:9ccdd64c4d390ac7ebe5ee',
    messagingSenderId: '1056504785579',
    projectId: 'team-fitness-app-29fa1',
    storageBucket: 'team-fitness-app-29fa1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.teamfitness.app',
  );
}
