# 🚀 Guide Rapide - Déploiement Play Store

Guide en français pour déployer automatiquement votre app vers Google Play Console.

---

## ⚡ Configuration Rapide (5 étapes)

### 1️⃣ Créer le Keystore de Production

```powershell
cd android
.\create-keystore.ps1
```

Suivez les instructions à l'écran. Le script va créer :
- `upload-keystore.jks` (votre certificat)
- `key.properties` (les mots de passe)

⚠️ **IMPORTANT** : Sauvegardez ces fichiers en lieu sûr !

---

### 2️⃣ Configurer les Secrets GitHub (Signature)

```powershell
.\setup-github-secrets.ps1
```

Le script va copier automatiquement chaque secret dans votre presse-papier.
Ajoutez-les sur : https://github.com/TeamFitness/mobile-app/settings/secrets/actions

Secrets à ajouter :
- `KEYSTORE_BASE64`
- `KEYSTORE_PASSWORD`
- `KEY_PASSWORD`
- `KEY_ALIAS`

---

### 3️⃣ Créer un Service Account Google Cloud

1. Allez sur https://console.cloud.google.com/
2. Sélectionnez votre projet (ou créez-en un)
3. Menu **IAM & Admin** > **Service Accounts**
4. **+ CREATE SERVICE ACCOUNT**
5. Nom : `github-actions-play-deploy`
6. **CREATE AND CONTINUE** > **DONE**
7. Cliquez sur le service account créé
8. Onglet **KEYS** > **ADD KEY** > **Create new key**
9. Sélectionnez **JSON** > **CREATE**
10. 📥 Téléchargez le fichier JSON

---

### 4️⃣ Lier le Service Account à Play Console

1. Allez sur https://play.google.com/console
2. Sélectionnez votre app
3. **Setup** > **API access**
4. **Link service account** (suivez les instructions)
5. Retournez dans **Setup** > **Users and permissions**
6. **Invite new users**
7. Collez l'email du service account (format: `xxx@xxx.iam.gserviceaccount.com`)
8. Cochez les permissions :
   - ✅ View app information
   - ✅ Manage production releases
   - ✅ Manage testing track releases
9. **Invite user** > **Send invite**

---

### 5️⃣ Ajouter le Secret Play Store sur GitHub

1. Ouvrez le fichier JSON téléchargé à l'étape 3
2. Copiez **tout le contenu** du fichier
3. Allez sur https://github.com/TeamFitness/mobile-app/settings/secrets/actions
4. **New repository secret**
5. Nom : `PLAY_STORE_SERVICE_ACCOUNT_JSON`
6. Valeur : Collez le contenu JSON complet
7. **Add secret**

---

## 📱 Premier Upload (REQUIS)

⚠️ Le premier upload DOIT être manuel (exigence de Google).

### Builder l'AAB

```powershell
# Depuis la racine du projet
flutter build appbundle --release --dart-define=ENVIRONMENT=pprod
```

### Uploader sur Play Console

1. Fichier généré : `build\app\outputs\bundle\release\app-release.aab`
2. Play Console > **Testing** > **Internal testing**
3. **Create new release**
4. Uploadez le fichier AAB
5. Remplissez les infos et **Start rollout to Internal testing**

✅ **C'est fait !** Les prochains déploiements seront automatiques.

---

## 🎯 Utilisation Quotidienne

### Déployer automatiquement

Faites simplement un commit sur `staging` :

```bash
git add .
git commit -m "feat: nouvelle fonctionnalité"
git push origin staging
```

Le CI/CD va automatiquement :
1. ✅ Créer une nouvelle version (semantic-release)
2. ✅ Builder l'APK signé (pour OTA)
3. ✅ Builder l'AAB signé (pour Play Store)
4. ✅ Déployer vers Play Store Internal Testing
5. ✅ Déployer vers le serveur OTA

---

## 📊 Vérifier le Déploiement

### GitHub Actions

https://github.com/TeamFitness/mobile-app/actions

Vérifiez que toutes les étapes passent :
- ✅ Version & Changelog
- ✅ Build APK
- ✅ Deploy to Play Store Internal Testing
- ✅ Deploy OTA

### Play Console

https://play.google.com/console

Menu **Testing** > **Internal testing**

Vous verrez la nouvelle version déployée ! 🎉

---

## 🧪 Tester la Version

### Ajouter des testeurs

1. Play Console > **Testing** > **Internal testing**
2. Onglet **Testers**
3. **Create email list**
4. Ajoutez les emails
5. Copiez le lien d'opt-in et partagez-le

### Les testeurs doivent :

1. Ouvrir le lien
2. **Become a tester**
3. Télécharger depuis le Play Store
4. L'app aura un badge "Internal test"

---

## 🔄 Workflow des Branches

```
┌─────────┐
│  staging │  → Internal Testing (auto)
└─────────┘
     ↓
  (tests)
     ↓
┌─────────┐
│   main   │  → Internal Testing (auto)
└─────────┘
     ↓
  (promotion manuelle dans Play Console)
     ↓
┌─────────┐
│   Beta   │
└─────────┘
     ↓
┌─────────┐
│Production│
└─────────┘
```

---

## ❓ FAQ

### Erreur "Service account not linked"
➡️ Vérifiez l'étape 4 (lier le service account)

### Erreur "Invalid signature"
➡️ Vérifiez les secrets `KEYSTORE_*` sur GitHub

### Erreur "First upload must be manual"
➡️ Faites le premier upload manuellement (étape 📱)

### Erreur "Permission denied"
➡️ Vérifiez les permissions du service account dans Play Console

### Comment promouvoir vers Beta/Production ?
➡️ Manuellement dans Play Console : Internal → Beta → Production

---

## 📚 Documentation Complète

Pour plus de détails, voir :
- `GOOGLE_PLAY_SETUP.md` - Guide détaillé complet
- `BACKUP_ANDROID_SIGNING_CONFIG.md` - Configuration de signature

---

## ✅ Checklist Complète

- [ ] Keystore créé (`.\create-keystore.ps1`)
- [ ] Secrets GitHub configurés (`.\setup-github-secrets.ps1`)
- [ ] Service Account Google créé
- [ ] Service Account lié dans Play Console
- [ ] Secret `PLAY_STORE_SERVICE_ACCOUNT_JSON` ajouté
- [ ] Premier upload manuel effectué
- [ ] Testeurs ajoutés dans Play Console
- [ ] Déploiement automatique testé

---

**Besoin d'aide ?** Consultez `GOOGLE_PLAY_SETUP.md` pour le guide complet !
