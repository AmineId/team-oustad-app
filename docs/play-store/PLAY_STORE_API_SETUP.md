# 🎯 Configuration API Play Store - Guide Visuel 2025

## 🔍 Trouver "API Access" dans Play Console

Google a changé l'interface. Voici les **3 façons** de trouver l'API Access :

### **Méthode 1 : Lien Direct** ⚡ (Le plus rapide)

Ouvrez ce lien directement :
```
https://play.google.com/console/developers/VOTRE_DEVELOPER_ID/api-access
```

Ou utilisez ce lien générique qui vous redirigera :
```
https://play.google.com/console/u/0/developers/api-access
```

### **Méthode 2 : Via le Menu** 📱

1. Allez sur https://play.google.com/console
2. **NE PAS** sélectionner d'application
3. En haut à gauche, cliquez sur le menu hamburger (☰)
4. Cherchez **"Setup"** ou **"Configuration"**
5. Puis **"API access"** ou **"Accès à l'API"**

⚠️ **Important** : L'API Access est au niveau du **compte développeur**, pas au niveau de l'app !

### **Méthode 3 : Via All Applications** 🏠

1. Allez sur https://play.google.com/console
2. Cliquez sur **"All applications"** en haut à gauche
3. Dans le menu latéral, cherchez **"Setup"** → **"API access"**

---

## 📋 Ce que vous devez faire sur la page API Access

### 1️⃣ Lier le Service Account

Sur la page API Access, vous verrez :

```
┌─────────────────────────────────────────┐
│  API Access                             │
├─────────────────────────────────────────┤
│  Service accounts                       │
│  ┌───────────────────────────────────┐  │
│  │ No service accounts linked        │  │
│  │ [Link service account]  button    │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

Cliquez sur **"Link service account"** ou **"Associer un compte de service"**

### 2️⃣ Suivre les instructions

Vous serez redirigé vers Google Cloud Console.

Là, copiez l'**email du service account** que vous avez créé :
- Format : `github-actions-play-deploy@XXXX.iam.gserviceaccount.com`

### 3️⃣ Retourner dans Play Console

Une fois l'email copié, retournez dans Play Console et :

1. Allez dans **"Users and permissions"** (dans le menu Setup)
2. Cliquez **"Invite new users"**
3. Collez l'email du service account
4. Cochez les permissions :
   - ✅ **View app information**
   - ✅ **Manage testing track releases**
5. **Send invite**

---

## 🚨 Si vous ne trouvez toujours pas "API Access"

### Vérifiez votre compte

Vous devez être **Admin** ou **Account Owner** du Play Console pour voir l'API Access.

### Alternative : Utiliser le Google Cloud Console directement

Si vous ne trouvez vraiment pas "API Access", vous pouvez configurer les permissions directement :

1. Allez sur https://console.cloud.google.com/
2. Sélectionnez votre projet
3. **IAM & Admin** → **IAM**
4. Ajoutez le service account avec le rôle **"Service Account User"**

Puis dans Play Console :
1. **Users and permissions**
2. Invitez le service account avec les bonnes permissions

---

## ✅ Vérification

Une fois configuré, vous devriez voir dans Play Console → API Access :

```
Service accounts
┌──────────────────────────────────────────────┐
│ github-actions-play-deploy@xxx.iam.g...     │
│ Status: Active                               │
│ Linked: [Date]                               │
└──────────────────────────────────────────────┘
```

---

## 📞 Besoin d'aide ?

Si vous êtes bloqué, faites-moi savoir à quelle étape et je vous aiderai !
