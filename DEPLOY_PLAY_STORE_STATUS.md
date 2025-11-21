# 📱 Configuration Déploiement Play Store - Résumé

**Date**: 2025-11-21  
**Branch**: staging  
**Status**: ✅ Configuration terminée - Prêt pour test

---

## ✨ Ce qui a été fait

### 📦 Fichiers créés

#### Documentation
- ✅ `GOOGLE_PLAY_SETUP.md` - Guide détaillé complet (en anglais)
- ✅ `GUIDE_RAPIDE_PLAY_STORE.md` - Guide rapide 5 étapes (en français)

#### Configuration Fastlane
- ✅ `android/fastlane/Fastfile` - Définition des lanes de déploiement
- ✅ `android/fastlane/Appfile` - Configuration de l'app
- ✅ `android/fastlane/.gitignore` - Protection des fichiers sensibles
- ✅ `android/fastlane/README.md` - Documentation Fastlane

#### Scripts PowerShell
- ✅ `android/create-keystore.ps1` - Création du keystore de production
- ✅ `android/setup-github-secrets.ps1` - Configuration des secrets GitHub
- ✅ `android/test-config.ps1` - Test de la configuration
- ✅ `android/key.properties.template` - Template de configuration

#### Configuration Android
- ✅ `android/app/build.gradle.kts` - Mise à jour avec signature de production
- ✅ `android/.gitignore` - Mise à jour pour protéger les secrets

#### CI/CD
- ✅ `.github/workflows/semantic-release.yml` - Ajout du déploiement Play Store

#### Documentation Projet
- ✅ `README.md` - Mise à jour avec section déploiement Play Store

---

## 🔄 Workflow de Déploiement

### Branches
```
staging → Internal Testing (automatique)
main    → Internal Testing (automatique)
         → Beta/Production (promotion manuelle dans Play Console)
```

### Pipeline CI/CD

Quand vous pushez sur `staging` ou `main` :

1. **Version** (semantic-release)
   - Analyse les commits conventionnels
   - Génère une nouvelle version (semantic versioning)
   - Met à jour `pubspec.yaml` et `version-metadata.json`
   - Crée un tag Git et un CHANGELOG

2. **Build**
   - Configure Firebase selon l'environnement
   - Configure la signature de production
   - Build APK signé (pour OTA)
   - Build AAB signé (pour Play Store)
   - Upload des artifacts

3. **Deploy Play Store**
   - Setup Fastlane
   - Configure le service account Google
   - Déploie vers Internal Testing
   - Nettoyage des credentials

4. **Deploy OTA**
   - Déploie l'APK vers le serveur OTA
   - Met à jour `version.json`

---

## 📋 Checklist de Configuration

### ✅ Fait (dans le code)

- [x] Configuration Fastlane créée
- [x] Scripts PowerShell créés
- [x] build.gradle.kts mis à jour
- [x] Workflow GitHub Actions mis à jour
- [x] Documentation complète créée
- [x] .gitignore mis à jour

### 📝 À faire (par vous)

#### 1. Créer le Keystore Local
```powershell
cd android
.\create-keystore.ps1
```
Sauvegardez précieusement :
- `android/upload-keystore.jks`
- `android/key.properties`

#### 2. Configurer GitHub Secrets
```powershell
cd android
.\setup-github-secrets.ps1
```
À ajouter sur : https://github.com/TeamFitness/mobile-app/settings/secrets/actions
- `KEYSTORE_BASE64`
- `KEYSTORE_PASSWORD`
- `KEY_PASSWORD`
- `KEY_ALIAS`

#### 3. Google Cloud Service Account
1. Aller sur https://console.cloud.google.com/
2. Créer un projet (ou utiliser existant)
3. IAM & Admin > Service Accounts > CREATE SERVICE ACCOUNT
4. Nom : `github-actions-play-deploy`
5. CREATE AND CONTINUE > DONE
6. Cliquer sur le service account
7. KEYS > ADD KEY > Create new key > JSON
8. Télécharger le fichier JSON

#### 4. Play Console Configuration
1. https://play.google.com/console
2. Créer l'application (si pas déjà fait)
3. Setup > API access > Link service account
4. Setup > Users and permissions > Invite new users
5. Email du service account (xxx@xxx.iam.gserviceaccount.com)
6. Permissions :
   - ✅ View app information
   - ✅ Manage production releases
   - ✅ Manage testing track releases
7. Invite user > Send invite

#### 5. GitHub Secret Play Store
1. Ouvrir le JSON du service account
2. Copier tout le contenu
3. https://github.com/TeamFitness/mobile-app/settings/secrets/actions
4. New repository secret
5. Nom : `PLAY_STORE_SERVICE_ACCOUNT_JSON`
6. Valeur : Contenu JSON complet
7. Add secret

#### 6. Premier Upload Manuel
```powershell
flutter build appbundle --release --dart-define=ENVIRONMENT=pprod
```
Fichier : `build\app\outputs\bundle\release\app-release.aab`

Play Console > Testing > Internal testing > Create new release
Uploader le AAB

---

## 🧪 Tester la Configuration

### 1. Tester localement
```powershell
cd android
.\test-config.ps1
```

Doit afficher : ✅ Configuration complète et prête pour le déploiement !

### 2. Tester le build local
```powershell
flutter build appbundle --release --dart-define=ENVIRONMENT=pprod
```

Doit générer : `build\app\outputs\bundle\release\app-release.aab`

### 3. Vérifier la signature
```powershell
cd android
keytool -printcert -jarfile ..\build\app\outputs\bundle\release\app-release.aab
```

Doit afficher votre certificat avec CN=Team Fitness

### 4. Tester le déploiement automatique

1. Faire un commit conventionnel :
   ```bash
   git add .
   git commit -m "feat: Configuration déploiement automatique Play Store"
   git push origin staging
   ```

2. Vérifier GitHub Actions :
   https://github.com/TeamFitness/mobile-app/actions

3. Vérifier Play Console :
   https://play.google.com/console → Testing → Internal testing

---

## 📚 Documentation Disponible

### Guides Utilisateur
- **GUIDE_RAPIDE_PLAY_STORE.md** - Pour démarrer rapidement (5 étapes)
- **GOOGLE_PLAY_SETUP.md** - Guide détaillé complet

### Documentation Technique
- **android/fastlane/README.md** - Documentation Fastlane
- **BACKUP_ANDROID_SIGNING_CONFIG.md** - Configuration de signature
- **README.md** - Mis à jour avec section déploiement

### Scripts Disponibles
```powershell
# Configuration
android/create-keystore.ps1          # Créer le keystore
android/setup-github-secrets.ps1     # Configurer GitHub Secrets
android/test-config.ps1              # Tester la configuration

# Build
flutter build apk --release          # APK pour OTA
flutter build appbundle --release    # AAB pour Play Store
```

---

## 🔐 Fichiers Sensibles (Protégés)

Ces fichiers sont dans `.gitignore` et ne seront **JAMAIS** commitées :

```
android/upload-keystore.jks               # Votre certificat de production
android/key.properties                    # Mots de passe du keystore
android/fastlane/service-account-key.json # Credentials Google Cloud
android/github-secrets-instructions.txt   # Instructions avec secrets
```

⚠️ **IMPORTANT** : Sauvegardez ces fichiers de manière sécurisée !

---

## 🚀 Utilisation Quotidienne

Une fois tout configuré, vous n'avez plus qu'à coder normalement :

```bash
# Développement sur staging
git checkout staging
# ... faire vos modifications ...
git add .
git commit -m "feat: nouvelle fonctionnalité"
git push origin staging
```

Le CI/CD s'occupe automatiquement de :
1. ✅ Créer une nouvelle version
2. ✅ Builder et signer l'APK/AAB
3. ✅ Déployer vers Play Store Internal Testing
4. ✅ Déployer vers le serveur OTA

---

## 📊 Monitoring

### GitHub Actions
https://github.com/TeamFitness/mobile-app/actions

Vérifiez que les jobs passent :
- ✅ Version & Changelog
- ✅ Build APK
- ✅ Deploy to Play Store Internal Testing
- ✅ Deploy OTA

### Play Console
https://play.google.com/console

Menu Testing > Internal testing
Vous verrez les nouvelles versions automatiquement déployées

---

## ❓ Support

### Problèmes Courants

**Erreur "Service account not linked"**
→ Vérifiez l'étape 4 (Play Console Configuration)

**Erreur "Invalid signature"**
→ Vérifiez les secrets GitHub (étape 2)

**Erreur "First upload must be manual"**
→ Faites le premier upload (étape 6)

**Erreur "Permission denied"**
→ Vérifiez les permissions du service account (étape 4)

### Besoin d'aide ?

1. Consultez `GOOGLE_PLAY_SETUP.md` (guide détaillé)
2. Consultez `GUIDE_RAPIDE_PLAY_STORE.md` (guide rapide)
3. Exécutez `android/test-config.ps1` (test de configuration)

---

## 🎯 Prochaines Étapes

1. [ ] Exécuter `android/create-keystore.ps1`
2. [ ] Exécuter `android/setup-github-secrets.ps1`
3. [ ] Créer le Service Account Google Cloud
4. [ ] Configurer Play Console
5. [ ] Ajouter le secret `PLAY_STORE_SERVICE_ACCOUNT_JSON`
6. [ ] Faire le premier upload manuel
7. [ ] Tester le déploiement automatique
8. [ ] Ajouter des testeurs internes

---

**✅ Configuration code complétée !**  
**📝 Actions manuelles requises (voir checklist ci-dessus)**

---

Bon déploiement ! 🚀
