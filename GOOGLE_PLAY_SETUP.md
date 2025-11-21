# 🚀 Configuration Google Play Console - Déploiement Automatique

Ce guide explique comment configurer le déploiement automatique vers Google Play Console (test interne) via GitHub Actions.

---

## 📋 Prérequis

1. **Compte Google Play Console** avec accès développeur
2. **Application créée** dans Play Console avec l'ID `team.fitness.team_fitness_app`
3. **Keystore de production** (voir `BACKUP_ANDROID_SIGNING_CONFIG.md`)

---

## 🔑 Étape 1 : Créer un Service Account Google Cloud

### 1.1 Créer le Service Account

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Sélectionnez ou créez un projet lié à votre app
3. Menu **IAM & Admin** > **Service Accounts**
4. Cliquez **+ CREATE SERVICE ACCOUNT**
5. Remplissez :
   - **Name**: `github-actions-play-deploy`
   - **Description**: `Service account pour déployer depuis GitHub Actions`
6. Cliquez **CREATE AND CONTINUE**
7. Ne donnez pas de rôles pour l'instant → **DONE**

### 1.2 Créer la clé JSON

1. Dans la liste des Service Accounts, cliquez sur celui que vous venez de créer
2. Onglet **KEYS** > **ADD KEY** > **Create new key**
3. Sélectionnez **JSON** → **CREATE**
4. 📥 Un fichier JSON sera téléchargé (ex: `github-actions-play-deploy-xxxxx.json`)
5. ⚠️ **IMPORTANT** : Sauvegardez ce fichier de manière sécurisée !

---

## 🎮 Étape 2 : Lier le Service Account à Play Console

### 2.1 Ajouter l'utilisateur dans Play Console

1. Allez sur [Google Play Console](https://play.google.com/console)
2. Sélectionnez votre application
3. Menu **Setup** > **API access** (ou **Accès API**)
4. Section **Service accounts**
5. Cliquez **Link service account** (ou **Associer un compte de service**)
6. Cliquez **View service accounts** → Vous serez redirigé vers Google Cloud
7. Copiez l'**email** de votre service account (format: `xxx@xxx.iam.gserviceaccount.com`)

### 2.2 Donner les permissions

1. Retournez dans **Play Console** > **Setup** > **Users and permissions** (Utilisateurs et autorisations)
2. Cliquez **Invite new users** (Inviter des utilisateurs)
3. Collez l'email du service account
4. Dans **Account permissions**, cochez :
   - ✅ **View app information** (Voir les infos de l'app)
   - ✅ **Manage production releases** (Gérer les versions de production)
   - ✅ **Manage testing track releases** (Gérer les versions de test)
5. Cliquez **Invite user** puis **Send invite**

---

## 🔐 Étape 3 : Configurer les Secrets GitHub

### 3.1 Service Account JSON

1. Ouvrez le fichier JSON téléchargé à l'étape 1.2
2. Copiez **tout le contenu** du fichier JSON
3. Allez sur [Secrets GitHub](https://github.com/TeamFitness/mobile-app/settings/secrets/actions)
4. Cliquez **New repository secret**
5. Nom : `PLAY_STORE_SERVICE_ACCOUNT_JSON`
6. Valeur : Collez le contenu JSON complet
7. Cliquez **Add secret**

### 3.2 Secrets de Signature Android (si pas déjà fait)

Si vous n'avez pas encore configuré la signature Android :

```powershell
cd android
.\create-keystore.ps1
.\setup-github-secrets.ps1
```

Les secrets nécessaires :
- `KEYSTORE_BASE64`
- `KEYSTORE_PASSWORD`
- `KEY_PASSWORD`
- `KEY_ALIAS`

---

## 🛠️ Étape 4 : Mettre à jour le Workflow GitHub Actions

Le workflow `.github/workflows/semantic-release.yml` va être mis à jour pour :

1. **Builder un AAB signé** (Android App Bundle - format requis par Play Store)
2. **Déployer automatiquement** vers le test interne

Les changements incluent :
- Configuration de la signature de production
- Build du AAB au lieu de l'APK
- Déploiement via Fastlane

---

## 📦 Étape 5 : Premier Upload Manuel (REQUIS)

⚠️ **IMPORTANT** : Google Play Console exige que la **première version** soit uploadée manuellement.

### 5.1 Builder l'AAB manuellement

```powershell
# Assurez-vous d'avoir créé le keystore
cd android
.\create-keystore.ps1

# Retournez à la racine
cd ..

# Build l'AAB de production
flutter build appbundle --release --dart-define=ENVIRONMENT=pprod
```

L'AAB sera généré dans : `build\app\outputs\bundle\release\app-release.aab`

### 5.2 Uploader sur Play Console

1. Allez sur [Google Play Console](https://play.google.com/console)
2. Sélectionnez votre application
3. Menu **Testing** > **Internal testing** (Test interne)
4. Onglet **Releases** → **Create new release**
5. Uploadez le fichier `app-release.aab`
6. Remplissez les informations requises :
   - Nom de la version
   - Notes de version
7. Cliquez **Review release** puis **Start rollout to Internal testing**

✅ Une fois le premier upload fait, les suivants pourront être automatiques via CI/CD.

---

## 🚀 Étape 6 : Tester le Déploiement Automatique

### 6.1 Faire un commit

```bash
git add .
git commit -m "feat: Configuration déploiement automatique Play Store"
git push origin staging
```

### 6.2 Vérifier le Workflow

1. Allez sur [GitHub Actions](https://github.com/TeamFitness/mobile-app/actions)
2. Sélectionnez le workflow **🚀 Release & Deploy**
3. Vérifiez que toutes les étapes passent :
   - ✅ Version & Changelog
   - ✅ Build AAB
   - ✅ Deploy to Play Store Internal

### 6.3 Vérifier dans Play Console

1. Allez sur [Google Play Console](https://play.google.com/console)
2. Menu **Testing** > **Internal testing**
3. Vous devriez voir la nouvelle version déployée automatiquement ! 🎉

---

## 🔄 Workflow de Déploiement

### Branches et Environnements

| Branche | Environnement | Destination Play Store | Déclencheur |
|---------|---------------|------------------------|-------------|
| `staging` | Pré-production (pprod) | Internal Testing | Push automatique |
| `main` | Production (prod) | Internal Testing (puis promouvoir manuellement) | Push automatique |

### Processus de Release

1. **Développement** → Merge dans `staging`
2. **CI/CD** → Build et déploie vers **Internal Testing** automatiquement
3. **Tests internes** → L'équipe teste la version
4. **Validation** → Merge `staging` dans `main`
5. **Production** → Build et déploie vers **Internal Testing**
6. **Promotion manuelle** → De Internal Testing → Beta → Production (dans Play Console)

---

## 📱 Tester la Version Interne

### Ajouter des testeurs

1. Play Console > **Testing** > **Internal testing**
2. Onglet **Testers**
3. Cliquez **Create email list**
4. Ajoutez les emails des testeurs
5. Copiez le lien d'opt-in et partagez-le avec les testeurs

### Les testeurs doivent :

1. Ouvrir le lien d'opt-in
2. Cliquer **Become a tester**
3. Télécharger l'app depuis le Play Store
4. L'app apparaîtra avec une badge "Internal test"

---

## 🛡️ Sécurité

### Fichiers sensibles (NE JAMAIS COMMITER)

Ces fichiers sont dans `.gitignore` :

```
android/upload-keystore.jks
android/key.properties
android/fastlane/service-account-key.json
```

### Bonnes pratiques

- ✅ Toujours utiliser des secrets GitHub pour les credentials
- ✅ Ne jamais hardcoder de mots de passe dans le code
- ✅ Sauvegarder le keystore et le JSON de service account de manière sécurisée
- ✅ Restreindre les permissions du service account au strict minimum
- ✅ Rotationner les clés périodiquement

---

## 📊 Monitoring

### Logs GitHub Actions

Vérifiez les logs pour chaque déploiement :
- https://github.com/TeamFitness/mobile-app/actions

### Statut Play Console

Vérifiez le statut de vos releases :
- https://play.google.com/console → **Testing** → **Internal testing**

---

## 🐛 Dépannage

### Erreur : "Service account not linked"

➡️ Vérifiez que le service account est bien lié dans Play Console (Étape 2)

### Erreur : "Invalid signature"

➡️ Vérifiez que les secrets `KEYSTORE_*` sont correctement configurés

### Erreur : "First upload must be manual"

➡️ Uploadez la première version manuellement (Étape 5)

### Erreur : "Permission denied"

➡️ Vérifiez les permissions du service account dans Play Console

---

## 📚 Ressources

- [Fastlane pour Android](https://docs.fastlane.tools/getting-started/android/setup/)
- [Google Play API](https://developers.google.com/android-publisher)
- [Flutter Deployment](https://docs.flutter.dev/deployment/android)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)

---

## ✅ Checklist

- [ ] Service Account créé et JSON téléchargé
- [ ] Service Account lié dans Play Console avec bonnes permissions
- [ ] Secret `PLAY_STORE_SERVICE_ACCOUNT_JSON` ajouté sur GitHub
- [ ] Secrets de signature Android configurés
- [ ] Keystore de production créé
- [ ] Premier upload manuel effectué
- [ ] Workflow GitHub Actions mis à jour
- [ ] Déploiement automatique testé
- [ ] Testeurs internes ajoutés dans Play Console

---

**Date de création** : 2025-11-21
**Auteur** : GitHub Copilot
**Statut** : ✅ Prêt pour déploiement
