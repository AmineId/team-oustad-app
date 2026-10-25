# 🔐 Configuration Rapide - Play Store Secret

## Ce que vous devez faire maintenant :

### 1️⃣ Télécharger la clé JSON du Service Account

Si vous ne l'avez pas encore fait :

1. Allez sur https://console.cloud.google.com/iam-admin/serviceaccounts
2. Cliquez sur le service account `github-actions-play-deploy@...`
3. Onglet **KEYS** (Clés)
4. **ADD KEY** → **Create new key** → **JSON**
5. 📥 Téléchargez le fichier (ex: `team-fitness-app-29fa1-xxxxx.json`)

⚠️ **Si vous avez déjà le fichier JSON**, passez à l'étape 2.

### 2️⃣ Ajouter le secret sur GitHub

**Option A : Via l'interface web** (le plus simple)

1. Allez sur : https://github.com/AmineId/team-oustad-app/settings/secrets/actions
2. Cliquez **New repository secret**
3. Name: `PLAY_STORE_SERVICE_ACCOUNT_JSON`
4. Value: Ouvrez le fichier JSON et **copiez-collez tout le contenu**
5. **Add secret**

**Option B : Via GitHub CLI** (si vous avez `gh` installé)

```powershell
# Remplacez le chemin par votre fichier JSON téléchargé
Get-Content "C:\Downloads\team-fitness-app-xxxxx.json" -Raw | gh secret set PLAY_STORE_SERVICE_ACCOUNT_JSON
```

### 3️⃣ Vérifier les autres secrets

Vérifiez que vous avez aussi les secrets de signature Android :

```powershell
gh secret list
```

Vous devez avoir :
- ✅ `PLAY_STORE_SERVICE_ACCOUNT_JSON`
- ✅ `KEYSTORE_BASE64`
- ✅ `KEYSTORE_PASSWORD`
- ✅ `KEY_PASSWORD`
- ✅ `KEY_ALIAS`

Si les secrets Android manquent, exécutez :
```powershell
cd android
.\setup-github-secrets.ps1
```

---

## 🚀 Étapes suivantes

Une fois les secrets configurés :

### 1. Premier upload manuel (OBLIGATOIRE)

Play Store exige que la première version soit uploadée manuellement :

```powershell
# Créer le keystore si pas déjà fait
cd android
.\create-keystore.ps1

# Retour à la racine
cd ..

# Build l'AAB
flutter build appbundle --release --dart-define=ENVIRONMENT=pprod
```

Puis uploadez `build\app\outputs\bundle\release\app-release.aab` sur Play Console → Internal Testing

### 2. Tester le déploiement automatique

```powershell
git add .
git commit -m "feat: configuration Play Store déploiement automatique"
git push origin staging
```

Regardez les logs : https://github.com/AmineId/team-oustad-app/actions

---

## ✅ Checklist

- [x] Service account créé
- [x] Service account invité dans Play Console avec permissions
- [ ] Fichier JSON téléchargé
- [ ] Secret PLAY_STORE_SERVICE_ACCOUNT_JSON ajouté sur GitHub
- [ ] Secrets de signature Android configurés
- [ ] Premier upload manuel sur Play Console
- [ ] Test du déploiement automatique

---

**Où en êtes-vous ?** Avez-vous déjà le fichier JSON du service account ?
