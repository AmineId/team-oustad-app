# 🚀 Implémentation Backend FCM - Guide Complet

## 📋 Table des Matières
1. [Prérequis](#prérequis)
2. [Configuration Firebase Admin](#configuration-firebase-admin)
3. [Migration Base de Données](#migration-base-de-données)
4. [Endpoints à Implémenter](#endpoints-à-implémenter)
5. [Code Complet](#code-complet)
6. [Tests](#tests)

---

## 1. Prérequis

### Packages NPM Requis
```bash
npm install firebase-admin
```

### Fichiers Firebase
- `serviceAccountKey.json` - Clé de service Firebase (à télécharger depuis Firebase Console)
- Placer dans le dossier racine du backend
- **IMPORTANT**: Ajouter à `.gitignore`

---

## 2. Configuration Firebase Admin

### Initialisation Firebase (à faire une seule fois au démarrage)

**Fichier: `server.js` ou `index.js`**

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialiser Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

console.log('✅ Firebase Admin SDK initialisé');
```

---

## 3. Migration Base de Données

### 3.1 Mettre à Jour le Schéma Prisma

**Fichier: `prisma/schema.prisma`**

```prisma
model User {
  id          Int       @id @default(autoincrement())
  email       String    @unique
  password    String
  fullName    String
  type        String    // 'admin', 'member', 'owner'
  uniqueCode  String    @unique
  gymId       Int?
  fcmToken    String?   // ⬅️ AJOUTER CE CHAMP
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt
  
  gym         Gym?      @relation(fields: [gymId], references: [id])
  // ... autres relations
}
```

### 3.2 Créer et Appliquer la Migration

```bash
npx prisma migrate dev --name add_fcm_token_to_users
npx prisma generate
```

---

## 4. Endpoints à Implémenter

D'après votre `swagger.yml`, voici les endpoints nécessaires:

### 📍 Endpoints FCM Token Management

1. **PUT `/users/fcm-token`** - Mettre à jour le token FCM de l'utilisateur connecté
2. **DELETE `/users/fcm-token`** - Supprimer le token FCM (déconnexion notifications)

### 📍 Endpoints Notifications (À CRÉER)

3. **POST `/notifications/send`** - Envoyer une notification à un utilisateur
4. **POST `/notifications/send-bulk`** - Envoyer une notification à plusieurs utilisateurs
5. **POST `/notifications/send-to-gym`** - Envoyer une notification à tous les membres d'une salle

---

## 5. Code Complet

### 5.1 Routes FCM Token Management

**Fichier: `routes/users.js` (ou votre fichier de routes users)**

```javascript
const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const authenticateToken = require('../middleware/auth'); // Votre middleware d'authentification

// PUT /users/fcm-token - Mettre à jour le token FCM
router.put('/fcm-token', authenticateToken, async (req, res) => {
  try {
    const { fcmToken } = req.body;
    const userId = req.user.id; // Extrait du JWT par le middleware

    if (!fcmToken) {
      return res.status(400).json({ 
        error: 'Token FCM requis',
        details: { fcmToken: 'Ce champ est obligatoire' }
      });
    }

    // Mettre à jour le token FCM de l'utilisateur
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
      select: {
        id: true,
        email: true,
        fullName: true,
        fcmToken: true
      }
    });

    console.log(`✅ Token FCM mis à jour pour l'utilisateur ${userId}`);

    res.json({
      message: 'Token FCM mis à jour avec succès',
      user: {
        id: updatedUser.id,
        email: updatedUser.email,
        fullName: updatedUser.fullName,
        fcmToken: updatedUser.fcmToken
      }
    });
  } catch (error) {
    console.error('❌ Erreur mise à jour token FCM:', error);
    res.status(500).json({ 
      error: 'Erreur lors de la mise à jour du token FCM',
      details: error.message 
    });
  }
});

// DELETE /users/fcm-token - Supprimer le token FCM (logout)
router.delete('/fcm-token', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    await prisma.user.update({
      where: { id: userId },
      data: { fcmToken: null }
    });

    console.log(`✅ Token FCM supprimé pour l'utilisateur ${userId}`);

    res.json({
      message: 'Token FCM supprimé avec succès'
    });
  } catch (error) {
    console.error('❌ Erreur suppression token FCM:', error);
    res.status(500).json({ 
      error: 'Erreur lors de la suppression du token FCM',
      details: error.message 
    });
  }
});

module.exports = router;
```

### 5.2 Routes Notifications

**Fichier: `routes/notifications.js` (NOUVEAU FICHIER)**

```javascript
const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const authenticateToken = require('../middleware/auth');

/**
 * Helper: Envoyer une notification FCM à un token
 */
async function sendFCMNotification(fcmToken, title, body, data = {}) {
  const message = {
    token: fcmToken,
    notification: {
      title: title,
      body: body
    },
    data: {
      ...data,
      timestamp: Date.now().toString()
    },
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        channelId: 'default'
      }
    }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log(`✅ Notification envoyée avec succès: ${response}`);
    return { success: true, messageId: response };
  } catch (error) {
    console.error(`❌ Erreur envoi notification: ${error.message}`);
    return { success: false, error: error.message };
  }
}

/**
 * POST /notifications/send - Envoyer une notification à un utilisateur
 * Body: { userId, title, body, data }
 */
router.post('/send', authenticateToken, async (req, res) => {
  try {
    const { userId, title, body, data } = req.body;
    const senderId = req.user.id;
    const senderType = req.user.type;

    // Validation
    if (!userId || !title || !body) {
      return res.status(400).json({
        error: 'Paramètres manquants',
        details: 'userId, title et body sont requis'
      });
    }

    // Récupérer l'utilisateur destinataire
    const recipient = await prisma.user.findUnique({
      where: { id: parseInt(userId) },
      select: { id: true, fullName: true, fcmToken: true, gymId: true }
    });

    if (!recipient) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    // Vérification des permissions
    // Admins peuvent envoyer uniquement aux membres de leur salle
    // Owners peuvent envoyer à tous
    if (senderType === 'admin') {
      const sender = await prisma.user.findUnique({
        where: { id: senderId },
        select: { gymId: true }
      });
      
      if (sender.gymId !== recipient.gymId) {
        return res.status(403).json({
          error: 'Accès refusé',
          details: 'Vous ne pouvez envoyer des notifications qu\'aux membres de votre salle'
        });
      }
    } else if (senderType === 'member') {
      return res.status(403).json({
        error: 'Accès refusé',
        details: 'Les membres ne peuvent pas envoyer de notifications'
      });
    }

    // Vérifier que l'utilisateur a un token FCM
    if (!recipient.fcmToken) {
      return res.status(400).json({
        error: 'Token FCM manquant',
        details: `L'utilisateur ${recipient.fullName} n'a pas de token FCM enregistré`
      });
    }

    // Envoyer la notification
    const result = await sendFCMNotification(
      recipient.fcmToken,
      title,
      body,
      data || {}
    );

    if (result.success) {
      res.json({
        message: 'Notification envoyée avec succès',
        recipient: {
          id: recipient.id,
          fullName: recipient.fullName
        },
        messageId: result.messageId
      });
    } else {
      res.status(500).json({
        error: 'Échec de l\'envoi de la notification',
        details: result.error
      });
    }
  } catch (error) {
    console.error('❌ Erreur envoi notification:', error);
    res.status(500).json({
      error: 'Erreur serveur',
      details: error.message
    });
  }
});

/**
 * POST /notifications/send-bulk - Envoyer une notification à plusieurs utilisateurs
 * Body: { userIds: [1, 2, 3], title, body, data }
 */
router.post('/send-bulk', authenticateToken, async (req, res) => {
  try {
    const { userIds, title, body, data } = req.body;
    const senderId = req.user.id;
    const senderType = req.user.type;

    // Validation
    if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
      return res.status(400).json({
        error: 'userIds requis',
        details: 'userIds doit être un tableau non vide'
      });
    }

    if (!title || !body) {
      return res.status(400).json({
        error: 'Paramètres manquants',
        details: 'title et body sont requis'
      });
    }

    // Récupérer les utilisateurs
    const recipients = await prisma.user.findMany({
      where: {
        id: { in: userIds.map(id => parseInt(id)) },
        fcmToken: { not: null } // Seulement ceux qui ont un token
      },
      select: { id: true, fullName: true, fcmToken: true, gymId: true }
    });

    if (recipients.length === 0) {
      return res.status(404).json({
        error: 'Aucun destinataire trouvé',
        details: 'Aucun utilisateur avec un token FCM n\'a été trouvé'
      });
    }

    // Vérification des permissions
    if (senderType === 'admin') {
      const sender = await prisma.user.findUnique({
        where: { id: senderId },
        select: { gymId: true }
      });

      // Filtrer uniquement les membres de la même salle
      const validRecipients = recipients.filter(r => r.gymId === sender.gymId);
      
      if (validRecipients.length === 0) {
        return res.status(403).json({
          error: 'Accès refusé',
          details: 'Aucun destinataire dans votre salle'
        });
      }

      // Envoyer uniquement aux membres autorisés
      const results = await Promise.all(
        validRecipients.map(recipient =>
          sendFCMNotification(recipient.fcmToken, title, body, data || {})
        )
      );

      const successCount = results.filter(r => r.success).length;

      res.json({
        message: `Notifications envoyées à ${successCount}/${validRecipients.length} utilisateurs`,
        recipients: validRecipients.map(r => ({ id: r.id, fullName: r.fullName })),
        successCount,
        totalCount: validRecipients.length
      });
    } else if (senderType === 'owner') {
      // Owners peuvent envoyer à tous
      const results = await Promise.all(
        recipients.map(recipient =>
          sendFCMNotification(recipient.fcmToken, title, body, data || {})
        )
      );

      const successCount = results.filter(r => r.success).length;

      res.json({
        message: `Notifications envoyées à ${successCount}/${recipients.length} utilisateurs`,
        recipients: recipients.map(r => ({ id: r.id, fullName: r.fullName })),
        successCount,
        totalCount: recipients.length
      });
    } else {
      return res.status(403).json({
        error: 'Accès refusé',
        details: 'Les membres ne peuvent pas envoyer de notifications'
      });
    }
  } catch (error) {
    console.error('❌ Erreur envoi notifications en masse:', error);
    res.status(500).json({
      error: 'Erreur serveur',
      details: error.message
    });
  }
});

/**
 * POST /notifications/send-to-gym - Envoyer une notification à tous les membres d'une salle
 * Body: { gymId, title, body, data }
 */
router.post('/send-to-gym', authenticateToken, async (req, res) => {
  try {
    const { gymId, title, body, data } = req.body;
    const senderId = req.user.id;
    const senderType = req.user.type;

    // Validation
    if (!gymId || !title || !body) {
      return res.status(400).json({
        error: 'Paramètres manquants',
        details: 'gymId, title et body sont requis'
      });
    }

    // Vérification des permissions
    if (senderType === 'admin') {
      const sender = await prisma.user.findUnique({
        where: { id: senderId },
        select: { gymId: true }
      });

      if (sender.gymId !== parseInt(gymId)) {
        return res.status(403).json({
          error: 'Accès refusé',
          details: 'Vous ne pouvez envoyer des notifications qu\'aux membres de votre salle'
        });
      }
    } else if (senderType === 'member') {
      return res.status(403).json({
        error: 'Accès refusé',
        details: 'Les membres ne peuvent pas envoyer de notifications'
      });
    }

    // Récupérer tous les membres de la salle avec un token FCM
    const members = await prisma.user.findMany({
      where: {
        gymId: parseInt(gymId),
        type: 'member',
        fcmToken: { not: null }
      },
      select: { id: true, fullName: true, fcmToken: true }
    });

    if (members.length === 0) {
      return res.status(404).json({
        error: 'Aucun membre trouvé',
        details: 'Aucun membre avec un token FCM dans cette salle'
      });
    }

    // Envoyer les notifications
    const results = await Promise.all(
      members.map(member =>
        sendFCMNotification(member.fcmToken, title, body, data || {})
      )
    );

    const successCount = results.filter(r => r.success).length;

    res.json({
      message: `Notifications envoyées à ${successCount}/${members.length} membres`,
      gymId: parseInt(gymId),
      recipients: members.map(m => ({ id: m.id, fullName: m.fullName })),
      successCount,
      totalCount: members.length
    });
  } catch (error) {
    console.error('❌ Erreur envoi notifications à la salle:', error);
    res.status(500).json({
      error: 'Erreur serveur',
      details: error.message
    });
  }
});

module.exports = router;
```

### 5.3 Intégrer les Routes dans le Serveur Principal

**Fichier: `server.js` ou `index.js`**

```javascript
const express = require('express');
const app = express();

// ... autres imports et configurations

// Import des routes
const usersRoutes = require('./routes/users');
const notificationsRoutes = require('./routes/notifications');

// Utiliser les routes
app.use('/users', usersRoutes);
app.use('/notifications', notificationsRoutes);

// ... reste du code
```

---

## 6. Tests

### 6.1 Test Mise à Jour Token FCM

```bash
curl -X PUT http://192.168.1.183:3000/users/fcm-token \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "fcmToken": "duh0Sb9ZR8Kg5hdi3Enqij:APA91bFT..."
  }'
```

**Réponse attendue:**
```json
{
  "message": "Token FCM mis à jour avec succès",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "fullName": "John Doe",
    "fcmToken": "duh0Sb9ZR8Kg5hdi3Enqij:APA91bFT..."
  }
}
```

### 6.2 Test Envoi Notification à un Utilisateur

```bash
curl -X POST http://192.168.1.183:3000/notifications/send \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "userId": 5,
    "title": "Test Notification",
    "body": "Ceci est un test de notification push!",
    "data": {
      "type": "test",
      "timestamp": "2025-11-11T12:00:00Z"
    }
  }'
```

**Réponse attendue:**
```json
{
  "message": "Notification envoyée avec succès",
  "recipient": {
    "id": 5,
    "fullName": "Jane Smith"
  },
  "messageId": "projects/team-fitness-app/messages/0:1699..."
}
```

### 6.3 Test Envoi Notification en Masse

```bash
curl -X POST http://192.168.1.183:3000/notifications/send-bulk \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "userIds": [5, 12, 18],
    "title": "Annonce Importante",
    "body": "La salle sera fermée dimanche pour maintenance",
    "data": {
      "type": "announcement"
    }
  }'
```

### 6.4 Test Envoi à Toute une Salle

```bash
curl -X POST http://192.168.1.183:3000/notifications/send-to-gym \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "gymId": 1,
    "title": "Événement Spécial",
    "body": "Cours de yoga gratuit samedi à 10h!",
    "data": {
      "type": "event",
      "eventId": "123"
    }
  }'
```

---

## 7. Cas d'Usage Pratiques

### 7.1 Rappel de Paiement (3 jours avant échéance)

```javascript
// À exécuter via un cron job quotidien
async function sendPaymentReminders() {
  const threeDaysFromNow = new Date();
  threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3);

  const upcomingPayments = await prisma.payment.findMany({
    where: {
      dueDate: {
        gte: new Date(),
        lte: threeDaysFromNow
      },
      status: 'pending'
    },
    include: {
      subscription: {
        include: {
          member: {
            select: { id: true, fullName: true, fcmToken: true }
          }
        }
      }
    }
  });

  for (const payment of upcomingPayments) {
    if (payment.subscription.member.fcmToken) {
      await sendFCMNotification(
        payment.subscription.member.fcmToken,
        '💳 Rappel de Paiement',
        `Votre paiement de ${payment.amount}€ est dû dans 3 jours`,
        {
          type: 'payment',
          paymentId: payment.id.toString(),
          amount: payment.amount.toString()
        }
      );
    }
  }
}
```

### 7.2 Notification Nouveau Planning

```javascript
async function notifyNewPlanning(planningId) {
  const planning = await prisma.planning.findUnique({
    where: { id: planningId },
    include: {
      member: {
        select: { id: true, fullName: true, fcmToken: true }
      }
    }
  });

  if (planning.member.fcmToken) {
    await sendFCMNotification(
      planning.member.fcmToken,
      '🏋️ Nouveau Planning',
      `Un nouveau planning "${planning.title}" vous a été assigné!`,
      {
        type: 'planning',
        planningId: planning.id.toString()
      }
    );
  }
}
```

### 7.3 Expiration Abonnement (7 jours avant)

```javascript
async function sendSubscriptionExpiryReminders() {
  const sevenDaysFromNow = new Date();
  sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);

  const expiringSubscriptions = await prisma.subscription.findMany({
    where: {
      endDate: {
        gte: new Date(),
        lte: sevenDaysFromNow
      },
      status: 'active'
    },
    include: {
      member: {
        select: { id: true, fullName: true, fcmToken: true }
      }
    }
  });

  for (const subscription of expiringSubscriptions) {
    if (subscription.member.fcmToken) {
      await sendFCMNotification(
        subscription.member.fcmToken,
        '⏰ Abonnement Bientôt Expiré',
        `Votre abonnement expire dans 7 jours. Pensez à le renouveler!`,
        {
          type: 'subscription',
          subscriptionId: subscription.id.toString()
        }
      );
    }
  }
}
```

---

## 8. Gestion des Erreurs Courantes

### Erreur: "Registration token not found"
**Cause**: Le token FCM est invalide ou l'utilisateur a désinstallé l'app  
**Solution**: Supprimer le token de la base de données

```javascript
if (result.error && result.error.includes('registration-token-not-registered')) {
  await prisma.user.update({
    where: { fcmToken: invalidToken },
    data: { fcmToken: null }
  });
}
```

### Erreur: "Requested entity was not found"
**Cause**: Le projet Firebase n'est pas correctement configuré  
**Solution**: Vérifier `serviceAccountKey.json`

---

## 9. Sécurité

### ✅ Bonnes Pratiques

1. **Ne jamais commiter `serviceAccountKey.json`**
   ```bash
   echo "serviceAccountKey.json" >> .gitignore
   ```

2. **Valider les permissions** avant d'envoyer des notifications

3. **Limiter le rate limiting** pour éviter les abus
   ```javascript
   const rateLimit = require('express-rate-limit');
   
   const notificationLimiter = rateLimit({
     windowMs: 15 * 60 * 1000, // 15 minutes
     max: 100 // max 100 notifications par 15 min
   });
   
   app.use('/notifications', notificationLimiter);
   ```

4. **Logger toutes les notifications** pour audit
   ```javascript
   await prisma.notificationLog.create({
     data: {
       senderId: req.user.id,
       recipientId: userId,
       title,
       body,
       status: 'sent',
       sentAt: new Date()
     }
   });
   ```

---

## 10. Checklist de Déploiement

- [ ] Firebase Admin SDK installé (`npm install firebase-admin`)
- [ ] `serviceAccountKey.json` téléchargé et placé dans le dossier backend
- [ ] `serviceAccountKey.json` ajouté au `.gitignore`
- [ ] Migration Prisma appliquée (champ `fcmToken` ajouté)
- [ ] Firebase initialisé dans `server.js`
- [ ] Routes `/users/fcm-token` implémentées
- [ ] Routes `/notifications/*` implémentées
- [ ] Middleware d'authentification en place
- [ ] Tests manuels effectués (Postman/curl)
- [ ] Logs de debug activés
- [ ] Rate limiting configuré (optionnel)

---

## 📞 Support

En cas de problème:
1. Vérifier les logs Firebase Admin SDK
2. Vérifier que le token FCM est valide (tester avec Firebase Console)
3. Vérifier les permissions utilisateur
4. Consulter la documentation Firebase: https://firebase.google.com/docs/cloud-messaging

---

**Guide créé le**: 11 novembre 2025  
**Version**: 1.0  
**Backend**: Express.js + Prisma + Firebase Admin SDK
