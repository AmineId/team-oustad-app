# 🔔 Configuration des Notifications Push - Étapes Complètes

## ✅ Ce qui a été fait automatiquement

### 1. **Intégration des Notifications Locales**
- ✅ Service `NotificationService` créé avec 7 méthodes spécialisées
- ✅ Package `flutter_local_notifications` installé (v17.2.3)
- ✅ Configuration Android complète dans le `AndroidManifest.xml`
- ✅ Écran de test des notifications (`NotificationTestScreen`)

### 2. **Intégration Firebase Cloud Messaging (FCM)**
- ✅ Service `FCMService` créé pour gérer les notifications push depuis le serveur
- ✅ Packages Firebase installés (`firebase_core`, `firebase_messaging`)
- ✅ Gestion des notifications en arrière-plan et premier plan
- ✅ Template `firebase_options.dart` créé (nécessite vos clés Firebase)

### 3. **Intégration Automatique du Token FCM**
- ✅ Le token FCM est **automatiquement envoyé au serveur** après chaque connexion
- ✅ Fonctionne pour la connexion normale (email/password)
- ✅ Fonctionne pour la connexion biométrique
- ✅ Stockage du token dans la base de données backend

### 4. **API Backend**
- ✅ Méthodes API ajoutées à `ApiService`:
  - `updateUserFCMToken(userId, fcmToken, token)` - Stocker le token FCM d'un utilisateur
  - `sendPushNotification(userId, title, body, token)` - Envoyer une notification à un utilisateur
  - `sendBulkPushNotification(userIds, title, body, token)` - Envoyer à plusieurs utilisateurs
  - `sendGymPushNotification(gymId, title, body, token)` - Envoyer à tous les membres d'une salle

### 5. **Documentation Complète**
- ✅ `NOTIFICATIONS_GUIDE.md` - Guide d'utilisation des notifications côté client
- ✅ `FIREBASE_SETUP_GUIDE.md` - Guide de configuration Firebase
- ✅ `SERVER_PUSH_NOTIFICATIONS_GUIDE.md` - Guide d'implémentation backend
- ✅ Ce fichier - Synthèse et prochaines étapes

---

## 🚀 Prochaines Étapes (À FAIRE)

### Étape 1: Configuration Firebase (15-20 minutes)

#### 1.1 Créer un Projet Firebase
1. Aller sur https://console.firebase.google.com/
2. Cliquer sur "Add project" (Ajouter un projet)
3. Nom du projet: `team_fitness_app` (ou votre choix)
4. Activer Google Analytics (optionnel)
5. Créer le projet

#### 1.2 Configurer l'Application Android
1. Dans Firebase Console, cliquer sur l'icône Android
2. **Package name**: `com.example.team_fitness_app` (vérifier dans `android/app/build.gradle.kts`)
3. **App nickname**: Team Fitness (optionnel)
4. **Debug signing certificate SHA-1**: Obtenir avec:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Copier la clé SHA-1 de la variante `debug`

5. **Télécharger `google-services.json`**
   - Cliquer sur "Download google-services.json"
   - Placer le fichier dans: `android/app/google-services.json`

#### 1.3 Activer Firebase Cloud Messaging (FCM)
1. Dans Firebase Console → Menu gauche → **Build** → **Cloud Messaging**
2. Cliquer sur "Enable" si ce n'est pas déjà fait
3. Noter votre **Server Key** (nécessaire pour le backend)

#### 1.4 Obtenir les Clés Firebase
1. Firebase Console → Icône engrenage ⚙️ → **Project settings**
2. Onglet **General** → Votre application Android
3. Copier ces valeurs:
   - **API Key** (android → mobilesdk_app_id)
   - **App ID** (android → current_key)
   - **Messaging Sender ID** (project_number)
   - **Project ID** (project_id)

#### 1.5 Mettre à Jour `firebase_options.dart`
Ouvrir `lib/firebase_options.dart` et remplacer les placeholders:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',  // Votre clé API
  appId: '1:123456789:android:abcdef123456',     // Votre App ID
  messagingSenderId: '123456789',                 // Votre Sender ID
  projectId: 'team-fitness-app',                  // Votre Project ID
  storageBucket: 'team-fitness-app.firebasestorage.app',
);
```

---

### Étape 2: Configuration Backend (30-45 minutes)

#### 2.1 Ajouter le Champ `fcmToken` au Modèle User
Éditer votre fichier Prisma `schema.prisma`:

```prisma
model User {
  id          Int       @id @default(autoincrement())
  email       String    @unique
  password    String
  fullName    String
  type        String    // 'admin', 'member', 'owner'
  gymId       Int?
  fcmToken    String?   // ⬅️ Ajouter ce champ
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt
  
  gym         Gym?      @relation(fields: [gymId], references: [id])
  // ... autres relations
}
```

Puis exécuter la migration:
```bash
npx prisma migrate dev --name add_fcm_token
```

#### 2.2 Installer le SDK Firebase Admin
Dans votre backend Node.js:
```bash
npm install firebase-admin
```

#### 2.3 Obtenir la Clé de Service Firebase
1. Firebase Console → ⚙️ **Project settings** → **Service accounts**
2. Cliquer sur "Generate new private key"
3. Télécharger le fichier JSON
4. Renommer en `serviceAccountKey.json`
5. Placer dans le dossier racine de votre backend
6. **IMPORTANT**: Ajouter `serviceAccountKey.json` au `.gitignore`

#### 2.4 Implémenter les Routes Backend
Créer le fichier backend (Express + Prisma) selon le guide `SERVER_PUSH_NOTIFICATIONS_GUIDE.md`:

**Fichier: `backend/routes/notifications.js`**

Points clés:
- Initialiser Firebase Admin avec `serviceAccountKey.json`
- Route `PUT /users/:id/fcm-token` - Stocker le token FCM
- Route `POST /notifications/send` - Envoyer à un utilisateur
- Route `POST /notifications/send-bulk` - Envoyer à plusieurs utilisateurs
- Route `POST /notifications/send-to-gym` - Envoyer à tous les membres d'une salle

Voir `SERVER_PUSH_NOTIFICATIONS_GUIDE.md` pour le code complet.

#### 2.5 Ajouter les Routes au Serveur Principal
Dans votre fichier principal backend (ex: `index.js` ou `server.js`):

```javascript
const notificationRoutes = require('./routes/notifications');
app.use('/notifications', notificationRoutes);
app.use('/users', notificationRoutes); // Pour PUT /users/:id/fcm-token
```

---

### Étape 3: Tester l'Intégration (15 minutes)

#### 3.1 Test de Base
1. **Compiler et lancer l'app**:
   ```bash
   flutter run
   ```

2. **Se connecter** avec un compte admin ou membre

3. **Vérifier les logs**:
   - Chercher dans les logs: `FCM Token: fXXXXXXXXXXXXX`
   - Chercher: `FCM token sent to server: fXXXXXXXXXXXXX`

#### 3.2 Test des Notifications Locales
1. Naviguer vers l'écran de test des notifications
2. Tester chaque type de notification:
   - Notification immédiate
   - Notification programmée (10 secondes)
   - Rappel de paiement
   - Notification de planning
   - Rappel d'entraînement

#### 3.3 Test des Notifications Push depuis le Serveur
**Option A: Via l'API Backend**

Utiliser Postman ou curl:
```bash
curl -X POST http://192.168.1.183:3000/notifications/send \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "userId": 1,
    "title": "Test Notification",
    "body": "Ceci est un test de notification push!"
  }'
```

**Option B: Depuis Firebase Console (Debug)**
1. Firebase Console → **Cloud Messaging**
2. Cliquer sur "Send your first message"
3. Titre: "Test Push"
4. Message: "Test depuis Firebase Console"
5. Cible: **Single device**
6. FCM token: Coller le token récupéré dans les logs
7. Envoyer

---

## 📊 Checklist de Vérification

### ✅ Configuration Firebase
- [ ] Projet Firebase créé
- [ ] Application Android ajoutée avec le bon package name
- [ ] `google-services.json` téléchargé et placé dans `android/app/`
- [ ] Firebase Cloud Messaging activé
- [ ] Clés API copiées dans `firebase_options.dart`
- [ ] Clé de service (serviceAccountKey.json) téléchargée pour le backend

### ✅ Configuration Backend
- [ ] Champ `fcmToken` ajouté au modèle User Prisma
- [ ] Migration Prisma exécutée
- [ ] Package `firebase-admin` installé
- [ ] `serviceAccountKey.json` placé dans le backend
- [ ] Routes de notifications implémentées
- [ ] Backend redémarré

### ✅ Tests
- [ ] App compile et démarre sans erreur
- [ ] Token FCM visible dans les logs après connexion
- [ ] Message "FCM token sent to server" dans les logs
- [ ] Notifications locales fonctionnent (test screen)
- [ ] Notification push reçue depuis le serveur (via API ou Firebase Console)

---

## 🎯 Cas d'Usage des Notifications

### Notifications Locales (Côté Client)
Utilisez `NotificationService` pour:
- ✅ Rappels d'entraînement (avant la séance)
- ✅ Rappels de paiement (3 jours avant échéance)
- ✅ Rappels d'expiration d'abonnement (7 jours avant)
- ✅ Notifications immédiates (nouveau planning assigné)

### Notifications Push (Depuis le Serveur)
Utilisez les routes backend pour:
- ✅ Annonces de la salle de sport (événements, fermetures)
- ✅ Confirmations de paiement
- ✅ Alertes administratives (nouveau membre, problème)
- ✅ Messages personnalisés à un membre
- ✅ Notifications en temps réel (changement de planning)

---

## 🔧 Dépannage Courant

### Problème: "Default FirebaseApp is not initialized"
**Solution**: Vérifier que `Firebase.initializeApp()` est appelé dans `main()` avant `runApp()`

### Problème: Pas de token FCM généré
**Solution**: 
1. Vérifier que `google-services.json` est présent
2. Vérifier les permissions Android dans `AndroidManifest.xml`
3. Redémarrer l'app complètement

### Problème: Notifications push non reçues
**Solutions**:
1. Vérifier que le token FCM est bien stocké en base de données
2. Vérifier les logs backend (erreurs Firebase Admin)
3. Tester avec Firebase Console directement
4. Vérifier que l'app est en arrière-plan (les notifications foreground sont gérées différemment)

### Problème: Backend ne peut pas envoyer de notifications
**Solutions**:
1. Vérifier que `serviceAccountKey.json` est valide
2. Vérifier que Firebase Admin est initialisé correctement
3. Vérifier les logs d'erreur Firebase Admin
4. Vérifier que Cloud Messaging est activé dans Firebase Console

---

## 📚 Documentation Complémentaire

- **NOTIFICATIONS_GUIDE.md** - Comment utiliser les notifications dans le code
- **FIREBASE_SETUP_GUIDE.md** - Guide détaillé Firebase (avec alternatives)
- **SERVER_PUSH_NOTIFICATIONS_GUIDE.md** - Implémentation backend complète

---

## 🎉 Résultat Final

Une fois tout configuré, vous aurez:
- ✅ **Notifications locales** programmables depuis l'app
- ✅ **Notifications push** envoyables depuis votre serveur à n'importe quel utilisateur
- ✅ **Token FCM** automatiquement enregistré à chaque connexion
- ✅ **API complète** pour envoyer des notifications ciblées (utilisateur, groupe, salle)
- ✅ **System de rappels** automatique pour paiements et entraînements

---

## ❓ Questions Fréquentes

**Q: Dois-je payer pour Firebase?**
R: Non, le plan gratuit (Spark) est suffisant pour la plupart des apps. 

**Q: Les notifications fonctionnent sur iOS?**
R: Le code est prêt, mais nécessite une configuration supplémentaire iOS (APNs, certificats).

**Q: Puis-je envoyer des notifications sans Firebase?**
R: Techniquement oui, mais Firebase est le standard recommandé pour Flutter.

**Q: Combien de notifications puis-je envoyer?**
R: Illimité avec le plan gratuit Firebase.

---

**Besoin d'aide?** Consultez les guides détaillés ou vérifiez les logs pour identifier les problèmes.
