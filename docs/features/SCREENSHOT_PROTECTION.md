# 🔒 Protection contre les Screenshots et Enregistrements d'Écran

## Vue d'ensemble

L'application Team Oustad est protégée contre :
- ✅ **Screenshots** (captures d'écran)
- ✅ **Screen Recording** (enregistrement d'écran)
- ✅ **Affichage dans le task switcher** (aperçu des apps récentes)

Cette protection est active sur **toutes les plateformes** et **tous les écrans** de l'application.

---

## 🤖 Android

### Implémentation

La protection Android utilise le **FLAG_SECURE** qui empêche :
- La capture d'écran par l'utilisateur
- L'enregistrement d'écran
- L'affichage du contenu dans le task switcher (aperçu des applications)

### Code

**Dart (lib/main.dart)** :
```dart
const platform = MethodChannel('team.fitness.security');
await platform.invokeMethod('disableScreenCapture');
```

**Kotlin (android/app/src/main/kotlin/.../MainActivity.kt)** :
```kotlin
window.setFlags(
    WindowManager.LayoutParams.FLAG_SECURE,
    WindowManager.LayoutParams.FLAG_SECURE
)
```

### Comportement

- **Screenshot** : L'utilisateur voit un écran noir ou reçoit un message "Impossible de capturer l'écran"
- **Screen Recording** : L'enregistrement affiche un écran noir pour cette application
- **Task Switcher** : L'aperçu de l'app montre un écran noir

### Test Android

1. Lancer l'application
2. Essayer de prendre un screenshot (Power + Volume Down)
3. Résultat attendu : Message d'erreur ou écran noir

---

## 🍎 iOS

### Implémentation

La protection iOS utilise plusieurs techniques :

1. **Détection de screenshots** : Log quand un screenshot est pris
2. **Masquage dans le task switcher** : Overlay sombre quand l'app passe en arrière-plan
3. **Détection d'enregistrement d'écran** : Alert quand l'enregistrement est actif

### Code

```swift
// ios/Runner/AppDelegate.swift

// 1. Détection de screenshots
NotificationCenter.default.addObserver(
  forName: UIApplication.userDidTakeScreenshotNotification,
  object: nil,
  queue: .main
) { _ in
  print("⚠️ Screenshot détecté!")
}

// 2. Masquage dans task switcher
NotificationCenter.default.addObserver(
  forName: UIApplication.willResignActiveNotification,
  object: nil,
  queue: .main
) { [weak self] _ in
  self?.hideScreenContent()
}

// 3. Détection enregistrement d'écran
NotificationCenter.default.addObserver(
  forName: UIScreen.capturedDidChangeNotification,
  object: nil,
  queue: .main
) { _ in
  if UIScreen.main.isCaptured {
    print("⚠️ Enregistrement d'écran détecté!")
  }
}
```

### Comportement

- **Screenshot** : L'utilisateur peut prendre un screenshot, mais c'est détecté et loggé
- **Screen Recording** : Détecté et peut être bloqué ou signalé
- **Task Switcher** : Affiche "Team Oustad" sur fond sombre au lieu du contenu

### Limitations iOS

⚠️ **Important** : iOS ne permet PAS de bloquer complètement les screenshots au niveau système (contrairement à Android). 

Les options disponibles :
1. **Détecter** : On peut savoir quand un screenshot est pris
2. **Logger** : Enregistrer l'événement
3. **Alerter** : Afficher un message à l'utilisateur
4. **Masquer dans task switcher** : Protéger l'aperçu de l'app

### Test iOS

1. Lancer l'application
2. Essayer de prendre un screenshot (Power + Volume Up)
3. Vérifier les logs : devrait afficher "⚠️ Screenshot détecté!"
4. Mettre l'app en arrière-plan et vérifier le task switcher : devrait afficher "Team Oustad" au lieu du contenu

---

## 📦 Implémentation Native

### MethodChannel

**Type** : Implémentation native personnalisée (pas de package externe)

**Plateformes** : 
- ✅ Android : FLAG_SECURE via WindowManager
- ✅ iOS : Notification observers dans AppDelegate

**Avantages** :
- Aucune dépendance externe
- Compatible avec toutes les versions d'Android Gradle Plugin
- Contrôle total sur le comportement
- Pas de risque de package obsolète

---

## 🔧 Configuration Requise

### Android

Aucune configuration supplémentaire nécessaire. Le FLAG_SECURE est appliqué automatiquement au démarrage.

### iOS

Le code est déjà dans `ios/Runner/AppDelegate.swift`. Aucune configuration Info.plist nécessaire.

---

## 🧪 Tests

### Vérifier que la protection fonctionne

#### Installation
```bash
# Installer les dépendances
flutter pub get

# Compiler l'app
flutter build apk  # ou flutter run
```

#### Android
```bash
# Lancer l'app
flutter run

# Essayer de prendre un screenshot
# Résultat attendu : Écran noir ou message d'erreur

# Ouvrir le task switcher (Recent Apps)
# Résultat attendu : Aperçu noir de l'application
```

#### iOS
```bash
# Lancer l'app
flutter run

# Essayer de prendre un screenshot
# Vérifier les logs Xcode
# Résultat attendu : Log "⚠️ Screenshot détecté!"

# Mettre l'app en background et vérifier le task switcher
# Résultat attendu : "Team Oustad" affiché au lieu du contenu
```

---

## 🛠️ Personnalisation

### Modifier le message iOS du task switcher

Éditez `ios/Runner/AppDelegate.swift` :

```swift
private func hideScreenContent() {
  // ...
  label.text = "Votre Message Personnalisé"  // ← Modifier ici
  label.textColor = .white
  label.font = UIFont.boldSystemFont(ofSize: 24)
  // ...
}
```

### Ajouter une action lors d'un screenshot iOS

```swift
NotificationCenter.default.addObserver(
  forName: UIApplication.userDidTakeScreenshotNotification,
  object: nil,
  queue: .main
) { _ in
  print("⚠️ Screenshot détecté!")
  
  // Ajouter votre action ici :
  // - Afficher une alerte
  // - Envoyer une notification au serveur
  // - Déconnecter l'utilisateur
  // - etc.
}
```

---

## ⚠️ Limitations Connues

### Android
- ✅ Protection complète contre screenshots et enregistrements
- ✅ Fonctionne sur toutes les versions d'Android

### iOS
- ⚠️ Impossible de bloquer complètement les screenshots (limitation Apple)
- ✅ Détection des screenshots possible
- ✅ Protection de l'aperçu dans le task switcher
- ⚠️ L'enregistrement d'écran peut être détecté mais pas bloqué

### Web / Desktop
- ❌ Aucune protection (impossible techniquement)
- Les utilisateurs peuvent prendre des screenshots librement

---

## 🔐 Sécurité

### Ce que cette protection empêche :

✅ Utilisateur lambda essayant de capturer l'écran (Android)  
✅ Contenu visible dans le task switcher (Android + iOS)  
✅ Enregistrement d'écran accidentel (Android)  

### Ce que cette protection N'empêche PAS :

❌ Utilisateur avec un téléphone rooté/jailbreaké  
❌ Capture via un autre appareil (photo avec un autre téléphone)  
❌ Outils de debugging avancés  
❌ Screenshots sur iOS (seulement détection)  

---

## 📝 Notes Importantes

1. **Android** : Protection très efficace grâce au FLAG_SECURE
2. **iOS** : Protection partielle (détection + masquage task switcher)
3. **Performance** : Impact négligeable sur les performances
4. **Compatibilité** : Fonctionne sur toutes les versions supportées
5. **Tests** : Toujours tester sur des appareils réels, pas seulement les émulateurs

---

## 🆘 Dépannage

### La protection ne fonctionne pas sur Android

1. Vérifier que `MainActivity.kt` contient bien le MethodChannel
2. Rebuild complet : `flutter clean && flutter build apk`
3. Vérifier les logs : devrait afficher "🔒 Protection des screenshots activée (Android)"
4. Tester sur un appareil réel (les émulateurs peuvent ne pas respecter FLAG_SECURE)

### La protection ne fonctionne pas sur iOS

1. Vérifier que le code est dans `AppDelegate.swift`
2. Rebuild complet : `flutter clean && flutter build ios`
3. Vérifier les logs Xcode pour les messages de détection

### Le contenu est toujours visible dans le task switcher iOS

1. Vérifier que les observers sont bien enregistrés
2. Tester en mettant l'app en background (pas juste lock screen)
3. Le délai peut être de quelques millisecondes

---

## 📚 Ressources

- [Flutter MethodChannel Documentation](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [Android FLAG_SECURE Documentation](https://developer.android.com/reference/android/view/WindowManager.LayoutParams#FLAG_SECURE)
- [iOS Screenshot Detection](https://developer.apple.com/documentation/uikit/uiapplication/1622966-userdidtakescreenshotnotificatio)
- [iOS Screen Capture Detection](https://developer.apple.com/documentation/uikit/uiscreen/2921651-iscaptured)

---

**Dernière mise à jour** : 15 novembre 2025  
**Version** : 1.0.0
