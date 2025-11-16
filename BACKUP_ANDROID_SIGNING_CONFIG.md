# 🔐 BACKUP - Configuration Android Signing & OTA Installation
**Date:** 2025-11-16
**Branche:** staging
**Status:** À appliquer plus tard

## 📋 Résumé des changements

Cette backup contient toute la configuration pour :
1. ✅ Installation automatique de l'APK OTA (avec `open_file`)
2. ✅ Signature de production Android (keystore)
3. ✅ Scripts de création et configuration
4. ✅ Documentation complète

---

## 📦 1. Package `open_file` pour installation APK

### `pubspec.yaml`
Ajouter après `path_provider: ^2.1.5` :
```yaml
  # Path provider for file downloads
  path_provider: ^2.1.5
  
  # Open files for OTA APK installation
  open_file: ^3.5.9
```

Puis exécuter : `flutter pub get`

---

## 🔧 2. Service OTA - Installation automatique

### `lib/core/services/ota_update_service.dart`

**Import à ajouter** (ligne 7) :
```dart
import 'package:open_file/open_file.dart';
```

**Remplacer la méthode `_installApk()`** (lignes ~172-189) :
```dart
  /// Installe l'APK téléchargé (Android uniquement)
  Future<void> _installApk(String filePath) async {
    if (!Platform.isAndroid) return;

    try {
      debugPrint('📦 Ouverture de l\'installateur APK: $filePath');
      
      // Utiliser open_file pour ouvrir l'installateur Android
      final result = await OpenFile.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );
      
      if (result.type == ResultType.done) {
        debugPrint('✅ Installateur APK ouvert avec succès');
      } else {
        debugPrint('⚠️ Résultat de l\'ouverture: ${result.type} - ${result.message}');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'ouverture de l\'installateur: $e');
    }
  }
```

---

## 🔐 3. Configuration Android Signing

### `android/app/build.gradle.kts`

**Remplacer tout le début jusqu'à la fin du bloc android {}** :
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Charger les propriétés de signature depuis key.properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "team.fitness.team_fitness_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "team.fitness.team_fitness_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Configuration de la signature
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Utiliser la signature de production si disponible, sinon debug
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
```

---

## 🔑 4. Script de création keystore

### `android/create-keystore.ps1`
```powershell
# Script pour créer un keystore de production Android
# Ce keystore sera utilisé pour signer l'application en production

Write-Host "🔐 Création du keystore de production pour Team Fitness App" -ForegroundColor Cyan
Write-Host ""

# Vérifier que keytool est disponible
$keytoolPath = "keytool"
try {
    $null = & $keytoolPath -version 2>&1
} catch {
    Write-Host "❌ keytool n'est pas trouvé. Assurez-vous que Java JDK est installé." -ForegroundColor Red
    Write-Host "Téléchargez Java JDK depuis: https://www.oracle.com/java/technologies/downloads/" -ForegroundColor Yellow
    exit 1
}

Write-Host "📋 Informations requises pour le certificat:" -ForegroundColor Yellow
Write-Host ""

# Demander les informations
$keystorePassword = Read-Host "Mot de passe du keystore (minimum 6 caractères)" -AsSecureString
$keystorePasswordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($keystorePassword)
)

$keyPassword = Read-Host "Mot de passe de la clé (minimum 6 caractères)" -AsSecureString
$keyPasswordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPassword)
)

$commonName = Read-Host "Nom (CN) [par défaut: Team Fitness]"
if ([string]::IsNullOrWhiteSpace($commonName)) { $commonName = "Team Fitness" }

$orgUnit = Read-Host "Unité organisationnelle (OU) [par défaut: Development]"
if ([string]::IsNullOrWhiteSpace($orgUnit)) { $orgUnit = "Development" }

$org = Read-Host "Organisation (O) [par défaut: Team Fitness]"
if ([string]::IsNullOrWhiteSpace($org)) { $org = "Team Fitness" }

$city = Read-Host "Ville (L) [par défaut: Paris]"
if ([string]::IsNullOrWhiteSpace($city)) { $city = "Paris" }

$state = Read-Host "État/Province (ST) [par défaut: Ile-de-France]"
if ([string]::IsNullOrWhiteSpace($state)) { $state = "Ile-de-France" }

$country = Read-Host "Code pays (C) [par défaut: FR]"
if ([string]::IsNullOrWhiteSpace($country)) { $country = "FR" }

Write-Host ""
Write-Host "🔨 Génération du keystore..." -ForegroundColor Cyan

# Créer le keystore
$keystorePath = Join-Path $PSScriptRoot "upload-keystore.jks"
$dname = "CN=$commonName, OU=$orgUnit, O=$org, L=$city, ST=$state, C=$country"

try {
    & keytool -genkeypair `
        -v `
        -storetype JKS `
        -keyalg RSA `
        -keysize 2048 `
        -validity 10000 `
        -alias upload `
        -keystore $keystorePath `
        -storepass $keystorePasswordText `
        -keypass $keyPasswordText `
        -dname $dname

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Keystore créé avec succès: $keystorePath" -ForegroundColor Green
        Write-Host ""
        
        # Créer le fichier key.properties
        $keyPropertiesPath = Join-Path $PSScriptRoot "key.properties"
        $keyPropertiesContent = @"
storePassword=$keystorePasswordText
keyPassword=$keyPasswordText
keyAlias=upload
storeFile=upload-keystore.jks
"@
        
        $keyPropertiesContent | Out-File -FilePath $keyPropertiesPath -Encoding UTF8
        
        Write-Host "✅ Fichier key.properties créé" -ForegroundColor Green
        Write-Host ""
        Write-Host "⚠️  IMPORTANT: Sauvegardez ces fichiers de manière sécurisée:" -ForegroundColor Yellow
        Write-Host "   - $keystorePath" -ForegroundColor White
        Write-Host "   - $keyPropertiesPath" -ForegroundColor White
        Write-Host ""
        Write-Host "⚠️  NE COMMITEZ PAS ces fichiers dans Git!" -ForegroundColor Red
        Write-Host "   (Ils sont déjà dans .gitignore)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "📦 Vous pouvez maintenant builder l'APK de production avec:" -ForegroundColor Cyan
        Write-Host "   flutter build apk --release" -ForegroundColor White
        
    } else {
        throw "Erreur lors de la création du keystore"
    }
} catch {
    Write-Host ""
    Write-Host "❌ Erreur: $_" -ForegroundColor Red
    exit 1
}
```

---

## 🔧 5. Script configuration GitHub Secrets

### `android/setup-github-secrets.ps1`
```powershell
# Script pour configurer les secrets GitHub Actions pour la signature Android
# Ce script encode le keystore en base64 et affiche les commandes pour ajouter les secrets

Write-Host "🔐 Configuration des secrets GitHub Actions pour la signature Android" -ForegroundColor Cyan
Write-Host ""

# Vérifier que le keystore existe
$keystorePath = Join-Path $PSScriptRoot "upload-keystore.jks"
if (-not (Test-Path $keystorePath)) {
    Write-Host "❌ Keystore non trouvé: $keystorePath" -ForegroundColor Red
    Write-Host "Exécutez d'abord: .\create-keystore.ps1" -ForegroundColor Yellow
    exit 1
}

# Vérifier que key.properties existe
$keyPropertiesPath = Join-Path $PSScriptRoot "key.properties"
if (-not (Test-Path $keyPropertiesPath)) {
    Write-Host "❌ key.properties non trouvé: $keyPropertiesPath" -ForegroundColor Red
    Write-Host "Exécutez d'abord: .\create-keystore.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "📖 Lecture des propriétés..." -ForegroundColor Cyan

# Lire les propriétés
$properties = @{}
Get-Content $keyPropertiesPath | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        $properties[$matches[1]] = $matches[2]
    }
}

# Encoder le keystore en base64
Write-Host "🔄 Encodage du keystore en base64..." -ForegroundColor Cyan
$keystoreBytes = [System.IO.File]::ReadAllBytes($keystorePath)
$keystoreBase64 = [System.Convert]::ToBase64String($keystoreBytes)

Write-Host ""
Write-Host "✅ Configuration prête!" -ForegroundColor Green
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""
Write-Host "📋 SECRETS À AJOUTER DANS GITHUB" -ForegroundColor Yellow
Write-Host ""
Write-Host "Allez sur: https://github.com/TeamFitness/mobile-app/settings/secrets/actions" -ForegroundColor Cyan
Write-Host "Cliquez sur 'New repository secret' pour chaque secret ci-dessous:" -ForegroundColor Gray
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""

# Secret 1: KEYSTORE_BASE64
Write-Host "1️⃣  Secret Name: " -ForegroundColor White -NoNewline
Write-Host "KEYSTORE_BASE64" -ForegroundColor Green
Write-Host "   Secret Value: " -ForegroundColor Gray -NoNewline
Write-Host "[Copié dans le presse-papier]" -ForegroundColor Yellow
$keystoreBase64 | Set-Clipboard
Read-Host "   Appuyez sur Entrée pour continuer (le secret est dans votre presse-papier)"
Write-Host ""

# Secret 2: KEYSTORE_PASSWORD
Write-Host "2️⃣  Secret Name: " -ForegroundColor White -NoNewline
Write-Host "KEYSTORE_PASSWORD" -ForegroundColor Green
Write-Host "   Secret Value: " -ForegroundColor Gray -NoNewline
Write-Host $properties['storePassword'] -ForegroundColor Yellow
$properties['storePassword'] | Set-Clipboard
Read-Host "   Appuyez sur Entrée pour continuer (le secret est dans votre presse-papier)"
Write-Host ""

# Secret 3: KEY_PASSWORD
Write-Host "3️⃣  Secret Name: " -ForegroundColor White -NoNewline
Write-Host "KEY_PASSWORD" -ForegroundColor Green
Write-Host "   Secret Value: " -ForegroundColor Gray -NoNewline
Write-Host $properties['keyPassword'] -ForegroundColor Yellow
$properties['keyPassword'] | Set-Clipboard
Read-Host "   Appuyez sur Entrée pour continuer (le secret est dans votre presse-papier)"
Write-Host ""

# Secret 4: KEY_ALIAS
Write-Host "4️⃣  Secret Name: " -ForegroundColor White -NoNewline
Write-Host "KEY_ALIAS" -ForegroundColor Green
Write-Host "   Secret Value: " -ForegroundColor Gray -NoNewline
Write-Host $properties['keyAlias'] -ForegroundColor Yellow
$properties['keyAlias'] | Set-Clipboard
Read-Host "   Appuyez sur Entrée pour continuer (le secret est dans votre presse-papier)"
Write-Host ""

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""
Write-Host "✅ Tous les secrets ont été copiés dans le presse-papier (un par un)" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  N'oubliez pas d'ajouter aussi le secret OTA_BEARER_TOKEN si ce n'est pas déjà fait!" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔒 Une fois les secrets ajoutés, le workflow GitHub Actions signera automatiquement" -ForegroundColor Cyan
Write-Host "   les APKs avec votre certificat de production." -ForegroundColor Cyan
Write-Host ""

# Sauvegarder les instructions dans un fichier
$instructionsPath = Join-Path $PSScriptRoot "github-secrets-instructions.txt"
$instructions = @"
SECRETS GITHUB ACTIONS - Team Fitness App
========================================

Repository: https://github.com/TeamFitness/mobile-app/settings/secrets/actions

Secrets à ajouter:
------------------

1. KEYSTORE_BASE64
   Value: $($keystoreBase64.Substring(0, 50))... (voir fichier complet)

2. KEYSTORE_PASSWORD
   Value: $($properties['storePassword'])

3. KEY_PASSWORD
   Value: $($properties['keyPassword'])

4. KEY_ALIAS
   Value: $($properties['keyAlias'])

5. OTA_BEARER_TOKEN (si pas encore ajouté)
   Value: [Votre token OTA server]

Notes importantes:
-----------------
- Ne partagez JAMAIS ces valeurs publiquement
- Sauvegardez ce fichier dans un endroit sécurisé
- Supprimez ce fichier après avoir configuré les secrets

Date de génération: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

$instructions | Out-File -FilePath $instructionsPath -Encoding UTF8
Write-Host "💾 Instructions sauvegardées dans: $instructionsPath" -ForegroundColor Gray
Write-Host "   ⚠️  Supprimez ce fichier après configuration!" -ForegroundColor Red
Write-Host ""
```

---

## 📄 6. Template key.properties

### `android/key.properties.template`
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

---

## 🔄 7. Workflow GitHub Actions

### `.github/workflows/semantic-release.yml`

**Ajouter après "Install Flutter dependencies" (avant "Build APK")** :
```yaml
      - name: 🔐 Setup Android signing
        if: steps.semantic_dry.outputs.skip_release != 'true'
        run: |
          # Décoder le keystore depuis base64 si disponible
          if [[ -n "${{ secrets.KEYSTORE_BASE64 }}" ]]; then
            echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/upload-keystore.jks
            
            # Créer le fichier key.properties
            cat > android/key.properties << EOF
          storePassword=${{ secrets.KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.KEY_PASSWORD }}
          keyAlias=${{ secrets.KEY_ALIAS }}
          storeFile=upload-keystore.jks
          EOF
            
            echo "✅ Android signing configured with production keystore"
          else
            echo "⚠️ No keystore configured, using debug signing"
          fi
```

---

## 📚 8. Documentation créée

Fichiers à référencer plus tard :
- `ANDROID_CERTIFICATION.md` - Guide complet de certification
- `android/README.md` - Documentation du dossier Android

---

## 🚀 Pour appliquer plus tard

1. **Restaurer les changements de code** :
   - Copier les modifications depuis cette backup
   - Appliquer dans l'ordre : pubspec.yaml → ota_update_service.dart → build.gradle.kts → workflow

2. **Exécuter** :
   ```powershell
   flutter pub get
   cd android
   .\create-keystore.ps1
   ```

3. **Tester localement** :
   ```powershell
   flutter build apk --release --dart-define=ENVIRONMENT=pprod
   keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
   ```

4. **Configurer CI/CD** :
   ```powershell
   cd android
   .\setup-github-secrets.ps1
   ```

---

## ⚠️ Important

- Les scripts PowerShell sont prêts à l'emploi
- Les fichiers `.gitignore` protègent déjà les secrets
- Le keystore doit être sauvegardé de manière sécurisée
- GitHub Secrets : https://github.com/TeamFitness/mobile-app/settings/secrets/actions
