# 🚀 Quick Start - Configuration Firebase (15 minutes)

## ✅ État Actuel
- ✅ **App compilée et lancée avec succès!**
- ✅ Core library desugaring activé
- ✅ Toutes les dépendances installées
- ⚠️ **Firebase nécessite une configuration** (erreur visible dans les logs)

## 🔴 Erreur Actuelle
```
❌ Erreur initialisation FCM: Please set your Application ID. 
A valid Firebase App ID is required...
```

**Cause**: Les clés Firebase dans `lib/firebase_options.dart` sont des placeholders.

---

## 📋 Configuration Rapide (3 étapes)

### Étape 1: Créer le Projet Firebase (5 min)

1. **Aller sur**: https://console.firebase.google.com/
2. **Cliquer**: "Add project" / "Ajouter un projet"
3. **Nom**: `team-fitness-app` (ou votre choix)
4. **Google Analytics**: Activer (optionnel, recommandé)
5. **Créer le projet**: Cliquer sur "Create project"

### Étape 2: Configurer l'Application Android (5 min)

1. **Dans Firebase Console**, cliquer sur l'icône **Android** ⚙️
2. **Remplir les champs**:
   - **Android package name**: `team.fitness.team_fitness_app`
     *(Copier depuis `android/app/build.gradle.kts` - ligne `applicationId`)*
   - **App nickname**: `Team Fitness` (optionnel)
   - **Debug SHA-1**: Laisser vide pour l'instant (ou générer avec la commande ci-dessous)

3. **Télécharger `google-services.json`**:
   - Cliquer sur "Download google-services.json"
   - **Placer le fichier dans**: `android/app/google-services.json`
   
   ```
   team_fitness_app/
   └── android/
       └── app/
           ├── build.gradle.kts
           └── google-services.json  ⬅️ ICI
   ```

4. **Cliquer sur "Next"** puis "Continue to console"

### Étape 3: Récupérer les Clés Firebase (5 min)

1. **Firebase Console** → Icône ⚙️ (Settings) → **Project settings**

2. **Onglet "General"** → Descendre à "Your apps" → **Android app**

3. **Copier ces valeurs**:
   - 📝 **API Key** (Web API Key): `AIzaSy...`
   - 📝 **App ID**: `1:123456789:android:abc...`
   - 📝 **Messaging Sender ID** (Project number): `123456789`
   - 📝 **Project ID**: `team-fitness-app`

4. **Ouvrir**: `lib/firebase_options.dart`

5. **Remplacer les placeholders** avec vos vraies valeurs:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXX',              // ⬅️ Votre Web API Key
  appId: '1:123456789:android:abcdef123456',        // ⬅️ Votre App ID
  messagingSenderId: '123456789',                   // ⬅️ Votre Project Number
  projectId: 'team-fitness-app',                    // ⬅️ Votre Project ID
  storageBucket: 'team-fitness-app.firebasestorage.app',
);
```

### Étape 4: Activer Cloud Messaging (2 min)

1. **Firebase Console** → Menu gauche → **Build** → **Cloud Messaging**
2. Si un message "Enable" apparaît, cliquer dessus
3. **Cloud Messaging API** devrait être activé automatiquement

---

## ✅ Vérification

### Commande à Exécuter:
```bash
flutter run --dart-define=API_BASE_URL=https://england-dispatch-ministry-easy.trycloudflare.com -d R58M14MA7ZK
```

### Logs Attendus (Succès):
```
✅ Firebase initialized
✅ FCM permissions accordées
✅ FCM Token: fXXXXXXXXXXXXXXXXXXXXXX
✅ FCM token sent to server: fXXXXXXXXXXXXXXXXXXXXXX
```

### Si vous voyez encore l'erreur:
1. Vérifier que `google-services.json` est bien dans `android/app/`
2. Vérifier que les clés dans `firebase_options.dart` sont correctes (pas de placeholders)
3. Hot restart l'application (presser **R** dans le terminal Flutter)

---

## 🎯 Après Configuration

Une fois Firebase configuré, vous pourrez:
- ✅ Recevoir des notifications push depuis votre serveur
- ✅ Le token FCM sera automatiquement envoyé au backend à chaque connexion
- ✅ Tester les notifications avec `NotificationTestScreen`

---

## 📚 Guides Complets

Pour plus de détails:
- **FIREBASE_SETUP_GUIDE.md** - Guide complet Firebase (Android + iOS)
- **PUSH_NOTIFICATIONS_SETUP.md** - Guide complet notifications (client + serveur)
- **SERVER_PUSH_NOTIFICATIONS_GUIDE.md** - Implémentation backend

---

## 🔧 Commandes Utiles

### Obtenir le SHA-1 de débogage (optionnel):
```bash
cd android
./gradlew signingReport
```
Copier la clé SHA-1 de la variante `debug`.

### Hot Restart après modification:
Dans le terminal Flutter, presser **R** (majuscule)

### Nettoyer et reconstruire:
```bash
flutter clean
flutter pub get
flutter run -d R58M14MA7ZK
```

---

## ⚡ Résumé Ultra-Rapide

1. **Firebase Console** → Créer projet
2. **Ajouter app Android** → Package: `team.fitness.team_fitness_app`
3. **Télécharger** `google-services.json` → Mettre dans `android/app/`
4. **Copier clés** Firebase → Mettre dans `lib/firebase_options.dart`
5. **Hot restart** l'app (presser **R**)
6. **Vérifier logs**: "✅ FCM Token: ..."

**Temps estimé**: 15 minutes maximum.

---

Besoin d'aide? Consulter les logs dans le terminal ou les guides détaillés!
