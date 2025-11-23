# Configuration Firebase pour Push Notifications

## Étapes de configuration

### 1. Créer un projet Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com)
2. Cliquez sur "Ajouter un projet"
3. Nommez votre projet (ex: "team-fitness")
4. Suivez les étapes de création

### 2. Ajouter une application Android

1. Dans votre projet Firebase, cliquez sur l'icône Android
2. Entrez le nom du package: `com.teamfitness.app` (ou celui dans `android/app/build.gradle`)
3. Téléchargez le fichier `google-services.json`
4. Placez-le dans `android/app/`

### 3. Ajouter une application iOS (optionnel)

1. Cliquez sur l'icône iOS
2. Entrez le Bundle ID: `com.teamfitness.app`
3. Téléchargez `GoogleService-Info.plist`
4. Ajoutez-le à votre projet iOS dans Xcode

### 4. Configurer Cloud Messaging

1. Dans Firebase Console, allez dans **Build** > **Cloud Messaging**
2. Notez votre **Server Key** (pour le serveur backend)

### 5. Mettre à jour firebase_options.dart

Après avoir ajouté vos applications, Firebase vous donne les clés de configuration.

**Option automatique (recommandée):**

```bash
# Installer FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurer Firebase automatiquement
flutterfire configure
```

Cela va générer automatiquement le fichier `firebase_options.dart` avec les bonnes valeurs.

**Option manuelle:**

Éditez `lib/firebase_options.dart` et remplacez les valeurs:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaXXXXXXXXXXXXXXXXXXXXXXXX', // Depuis Firebase Console
  appId: '1:123456789:android:abcdef', // Depuis google-services.json
  messagingSenderId: '123456789',      // Depuis google-services.json
  projectId: 'team-fitness-xxxxx',     // Votre project ID
  storageBucket: 'team-fitness-xxxxx.appspot.com',
);
```

### 6. Configuration Android supplémentaire

Éditez `android/app/build.gradle`:

```gradle
dependencies {
    // ... autres dépendances
    
    // Firebase
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

En bas du fichier, ajoutez:

```gradle
apply plugin: 'com.google.gms.google-services'
```

Éditez `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        // ... autres dépendances
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### 7. Configuration serveur (Backend)

#### Obtenir la clé de service

1. Dans Firebase Console > **Paramètres du projet** (icône engrenage)
2. Allez dans l'onglet **Comptes de service**
3. Cliquez sur **Générer une nouvelle clé privée**
4. Sauvegardez le fichier JSON téléchargé dans votre serveur (ex: `config/serviceAccountKey.json`)
5. **Ne commitez JAMAIS ce fichier dans Git!**

#### Installer Firebase Admin SDK

```bash
npm install firebase-admin
```

#### Initialiser dans votre serveur

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./config/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
```

### 8. Tester la configuration

#### Dans l'app mobile:

```dart
// Après le login
final fcmToken = FCMService().token;
print('Token FCM: $fcmToken');

// Envoyer le token au serveur
await ApiService.fromEnv().updateUserFCMToken(
  userId,
  fcmToken!,
  authToken,
);
```

#### Depuis Firebase Console:

1. Allez dans **Build** > **Cloud Messaging**
2. Cliquez sur **Send test message**
3. Collez le token FCM de votre appareil
4. Envoyez un message de test

#### Depuis le serveur:

```javascript
const { messaging } = require('firebase-admin');

await messaging().send({
  notification: {
    title: 'Test',
    body: 'Message de test',
  },
  token: 'TOKEN_FCM_DE_LAPPAREIL',
});
```

### 9. Vérification

✅ **Android:**
- `google-services.json` dans `android/app/`
- Dependencies Firebase dans `build.gradle`
- L'app démarre sans erreur Firebase

✅ **iOS:**
- `GoogleService-Info.plist` ajouté dans Xcode
- Capabilities > Push Notifications activé

✅ **Backend:**
- `serviceAccountKey.json` configuré
- Firebase Admin initialisé
- Endpoint `/notifications/send` fonctionne

## Dépannage

### Erreur: "Default FirebaseApp is not initialized"

Vérifiez que:
1. `firebase_options.dart` existe et a les bonnes valeurs
2. `Firebase.initializeApp()` est appelé dans `main.dart`
3. `google-services.json` est présent (Android)

### Les notifications n'arrivent pas

1. Vérifiez le token FCM dans les logs
2. Testez avec Firebase Console > Send test message
3. Vérifiez les permissions de notification sur l'appareil
4. Vérifiez que le token est bien envoyé au serveur

### Erreur serveur: "403 Forbidden"

Vérifiez que:
1. Le fichier `serviceAccountKey.json` est correct
2. Firebase Admin SDK est bien initialisé
3. L'API Cloud Messaging est activée dans Firebase Console

## Ressources

- [Documentation Firebase](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
