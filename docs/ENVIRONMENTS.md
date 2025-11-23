# Configuration des Environnements

Ce guide explique comment utiliser les différents environnements de l'application Team Fitness.

## 🌍 Environnements Disponibles

L'application supporte trois environnements :

| Environnement | API URL | Description |
|---------------|---------|-------------|
| **dev** (défaut) | `http://localhost:3000` ou `http://10.0.2.2:3000` | Développement local |
| **pprod** | `https://api-pprod.team-oustad.com` | Pré-production (tests) |
| **prod** | `https://api.team-oustad.com` | Production |

## 🚀 Utilisation avec PowerShell Scripts

### Développement (Dev)

```powershell
# Lancer l'app sur Windows (dev par défaut)
.\scripts.ps1 run-windows

# Lancer l'app sur Android (dev)
.\scripts.ps1 run-android

# Lancer l'app sur Web (dev)
.\scripts.ps1 run-web
```

### Pré-Production (PProd)

```powershell
# Lancer l'app sur Windows en pprod
.\scripts.ps1 run-windows-pprod

# Lancer l'app sur Android en pprod
.\scripts.ps1 run-android-pprod

# Build APK pprod
.\scripts.ps1 build-apk-pprod

# Build Windows executable pprod
.\scripts.ps1 build-windows-pprod

# Build Web pprod
.\scripts.ps1 build-web-pprod
```

### Production (Prod)

```powershell
# ⚠️ ATTENTION: Commandes de production ⚠️

# Lancer l'app sur Windows en prod
.\scripts.ps1 run-windows-prod

# Build APK prod
.\scripts.ps1 build-apk-prod

# Build App Bundle prod (Google Play)
.\scripts.ps1 build-appbundle-prod

# Build Windows executable prod
.\scripts.ps1 build-windows-prod

# Build Web prod
.\scripts.ps1 build-web-prod
```

## 📱 Utilisation avec Flutter CLI

Si vous préférez utiliser directement les commandes Flutter :

### Développement

```bash
# Dev utilise les URLs par défaut (localhost ou 10.0.2.2)
flutter run
flutter run -d windows
flutter run -d chrome
```

### Pré-Production

```bash
# Ajouter --dart-define=ENVIRONMENT=pprod
flutter run --dart-define=ENVIRONMENT=pprod
flutter run -d windows --dart-define=ENVIRONMENT=pprod
flutter build apk --release --dart-define=ENVIRONMENT=pprod
```

### Production

```bash
# Ajouter --dart-define=ENVIRONMENT=prod
flutter run --dart-define=ENVIRONMENT=prod
flutter build apk --release --dart-define=ENVIRONMENT=prod
flutter build appbundle --release --dart-define=ENVIRONMENT=prod
```

## 🔧 URL Personnalisée

Pour utiliser une URL personnalisée (par exemple, un tunnel Cloudflare ou IP locale) :

```powershell
# Avec PowerShell script
.\scripts.ps1 run-windows -Url http://192.168.1.100:3000

# Avec Flutter CLI
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000
```

## 📋 Configuration dans le Code

La configuration est gérée par `lib/config/app_config.dart` :

```dart
import 'package:team_fitness_app/config/app_config.dart';

// Obtenir la configuration actuelle
final config = AppConfig.fromEnvironment();

print(config.environment);  // 'dev', 'pprod', ou 'prod'
print(config.apiBaseUrl);   // URL de l'API
print(config.supportEmail); // Email de support

// Vérifier l'environnement
if (config.isProduction) {
  // Code spécifique à la production
}

if (config.isDevelopment) {
  // Code spécifique au développement
}
```

## 🔍 Ordre de Priorité

L'API Service détermine l'URL dans cet ordre :

1. **Variable API_BASE_URL** (`--dart-define=API_BASE_URL=http://...`)
   - Permet de surcharger avec une URL personnalisée pour tous les environnements

2. **Variable ENVIRONMENT** (`--dart-define=ENVIRONMENT=pprod|prod|dev`)
   - Utilise la configuration correspondante via `AppConfig`
   - `dev`: URL adaptée à la plateforme (Android: `10.0.2.2:3000`, autres: `localhost:3000`)
   - `pprod`: `https://api-pprod.team-oustad.com`
   - `prod`: `https://api.team-oustad.com`
   - **Par défaut**: `dev` si non spécifié

**Note**: Les builds doivent toujours définir la variable `ENVIRONMENT` via `--dart-define`.

## 📦 Builds de Production

### Android APK

```powershell
# PProd
.\scripts.ps1 build-apk-pprod
# Fichier: build\app\outputs\flutter-apk\app-release.apk

# Prod
.\scripts.ps1 build-apk-prod
# Fichier: build\app\outputs\flutter-apk\app-release.apk
```

### Android App Bundle (Google Play)

```powershell
# PProd
.\scripts.ps1 build-appbundle-pprod
# Fichier: build\app\outputs\bundle\release\app-release.aab

# Prod
.\scripts.ps1 build-appbundle-prod
# Fichier: build\app\outputs\bundle\release\app-release.aab
```

### Windows Executable

```powershell
# PProd
.\scripts.ps1 build-windows-pprod
# Fichier: build\windows\x64\runner\Release\

# Prod
.\scripts.ps1 build-windows-prod
# Fichier: build\windows\x64\runner\Release\
```

### Web

```powershell
# PProd
.\scripts.ps1 build-web-pprod
# Fichier: build\web\

# Prod
.\scripts.ps1 build-web-prod
# Fichier: build\web\
```

## 🛠️ Commandes Utiles

```powershell
# Voir toutes les commandes disponibles
.\scripts.ps1

# Installer les dépendances
.\scripts.ps1 install

# Nettoyer les builds
.\scripts.ps1 clean

# Voir les devices connectés
.\scripts.ps1 devices

# Lancer un émulateur
.\scripts.ps1 launch
```

## 🔐 Sécurité

- **Ne jamais** commit des URLs de production dans le code
- Utiliser les variables d'environnement (`--dart-define`)
- Les URLs sont définies dans `app_config.dart`
- Les commandes de production affichent un avertissement ⚠️

## 📚 Documentation API

- **Dev**: Swagger local à `http://localhost:3000/api-docs`
- **PProd**: https://api-pprod.team-oustad.com/api-docs
- **Prod**: https://api.team-oustad.com/api-docs (si disponible)
