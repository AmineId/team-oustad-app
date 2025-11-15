# Configuration Serveur pour Notifications Push

## 1. Installation des dépendances (Node.js/Express)

```bash
npm install firebase-admin
```

## 2. Configuration Firebase Admin SDK

```javascript
// server/config/firebase.js
const admin = require('firebase-admin');

// Téléchargez votre fichier de clé de service depuis Firebase Console:
// Paramètres du projet > Comptes de service > Générer une nouvelle clé privée
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const messaging = admin.messaging();

module.exports = { admin, messaging };
```

## 3. Modèle de base de données (Prisma)

Ajoutez ces champs à votre modèle `User` dans `schema.prisma`:

```prisma
model User {
  id          Int      @id @default(autoincrement())
  email       String   @unique
  fullName    String
  role        String
  gymId       Int
  
  // Nouveau champ pour FCM
  fcmToken    String?  @db.VarChar(255)
  
  // ... autres champs
}
```

Puis exécutez:
```bash
npx prisma migrate dev --name add_fcm_token
```

## 4. Routes API pour les notifications

```javascript
// server/routes/notifications.js
const express = require('express');
const router = express.Router();
const { messaging } = require('../config/firebase');
const { PrismaClient } = require('@prisma/client');
const { authenticateToken } = require('../middleware/auth');

const prisma = new PrismaClient();

/**
 * Envoyer une notification à un utilisateur spécifique
 * POST /notifications/send
 */
router.post('/send', authenticateToken, async (req, res) => {
  try {
    const { userId, title, body, data } = req.body;

    // Récupérer le token FCM de l'utilisateur
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true, fullName: true },
    });

    if (!user || !user.fcmToken) {
      return res.status(404).json({ 
        error: 'Utilisateur non trouvé ou sans token FCM' 
      });
    }

    // Préparer le message
    const message = {
      notification: {
        title,
        body,
      },
      data: data || {},
      token: user.fcmToken,
    };

    // Envoyer la notification
    const response = await messaging.send(message);
    
    console.log(`✅ Notification envoyée à ${user.fullName}:`, response);
    
    res.json({ 
      success: true, 
      messageId: response 
    });
  } catch (error) {
    console.error('❌ Erreur envoi notification:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Envoyer une notification à plusieurs utilisateurs
 * POST /notifications/send-bulk
 */
router.post('/send-bulk', authenticateToken, async (req, res) => {
  try {
    const { userIds, title, body, data } = req.body;

    // Récupérer les tokens FCM
    const users = await prisma.user.findMany({
      where: { 
        id: { in: userIds },
        fcmToken: { not: null },
      },
      select: { fcmToken: true },
    });

    const tokens = users.map(u => u.fcmToken).filter(Boolean);

    if (tokens.length === 0) {
      return res.status(404).json({ 
        error: 'Aucun utilisateur avec token FCM trouvé' 
      });
    }

    // Préparer le message
    const message = {
      notification: { title, body },
      data: data || {},
      tokens,
    };

    // Envoyer la notification
    const response = await messaging.sendEachForMulticast(message);
    
    console.log(`✅ ${response.successCount}/${tokens.length} notifications envoyées`);
    
    res.json({ 
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
  } catch (error) {
    console.error('❌ Erreur envoi notifications bulk:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Envoyer une notification à tous les membres d'une salle
 * POST /notifications/send-to-gym
 */
router.post('/send-to-gym', authenticateToken, async (req, res) => {
  try {
    const { gymId, title, body, data } = req.body;

    // Vérifier les permissions (admin ou owner)
    if (req.user.role === 'member') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    // Récupérer tous les membres de la salle avec un token FCM
    const users = await prisma.user.findMany({
      where: { 
        gymId,
        fcmToken: { not: null },
      },
      select: { fcmToken: true },
    });

    const tokens = users.map(u => u.fcmToken).filter(Boolean);

    if (tokens.length === 0) {
      return res.status(404).json({ 
        error: 'Aucun membre avec token FCM dans cette salle' 
      });
    }

    // Préparer le message
    const message = {
      notification: { title, body },
      data: data || {},
      tokens,
    };

    // Envoyer la notification
    const response = await messaging.sendEachForMulticast(message);
    
    console.log(`✅ ${response.successCount}/${tokens.length} notifications envoyées à la salle ${gymId}`);
    
    res.json({ 
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
    });
  } catch (error) {
    console.error('❌ Erreur envoi notifications gym:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
```

## 5. Route pour mettre à jour le token FCM

```javascript
// server/routes/users.js
/**
 * Mettre à jour le token FCM d'un utilisateur
 * PUT /users/:id/fcm-token
 */
router.put('/:id/fcm-token', authenticateToken, async (req, res) => {
  try {
    const userId = parseInt(req.params.id);
    const { fcmToken } = req.body;

    // Vérifier les permissions
    if (req.user.id !== userId && req.user.role === 'member') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    // Mettre à jour le token
    await prisma.user.update({
      where: { id: userId },
      data: { fcmToken },
    });

    console.log(`✅ Token FCM mis à jour pour user ${userId}`);
    
    res.json({ success: true });
  } catch (error) {
    console.error('❌ Erreur mise à jour token FCM:', error);
    res.status(500).json({ error: error.message });
  }
});
```

## 6. Exemples d'utilisation dans votre serveur

### Notifier lors de la création d'un abonnement

```javascript
// server/routes/subscriptions.js
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { memberId, subscriptionTypeId } = req.body;
    
    // Créer l'abonnement
    const subscription = await prisma.subscription.create({
      data: { memberId, subscriptionTypeId, /* ... */ },
      include: { member: true, subscriptionType: true },
    });

    // Envoyer une notification au membre
    if (subscription.member.fcmToken) {
      await messaging.send({
        notification: {
          title: 'Nouvel abonnement',
          body: `Votre abonnement ${subscription.subscriptionType.name} a été activé`,
        },
        data: {
          type: 'subscription',
          subscriptionId: subscription.id.toString(),
        },
        token: subscription.member.fcmToken,
      });
    }

    res.status(201).json(subscription);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

### Notifier lors d'un rappel de paiement

```javascript
// server/cron/payment-reminders.js
const cron = require('node-cron');
const { messaging } = require('../config/firebase');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Exécuter tous les jours à 9h
cron.schedule('0 9 * * *', async () => {
  console.log('🔔 Vérification des paiements à venir...');

  const threeDaysFromNow = new Date();
  threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3);

  // Trouver les paiements dus dans 3 jours
  const upcomingPayments = await prisma.payment.findMany({
    where: {
      status: 'pending',
      dueDate: {
        gte: new Date(),
        lte: threeDaysFromNow,
      },
    },
    include: {
      subscription: {
        include: {
          member: true,
        },
      },
    },
  });

  // Envoyer les notifications
  for (const payment of upcomingPayments) {
    const member = payment.subscription.member;
    
    if (member.fcmToken) {
      await messaging.send({
        notification: {
          title: 'Rappel de paiement',
          body: `Votre paiement de ${payment.amount}€ est dû dans 3 jours`,
        },
        data: {
          type: 'payment',
          paymentId: payment.id.toString(),
        },
        token: member.fcmToken,
      });
      
      console.log(`✅ Notification envoyée à ${member.fullName}`);
    }
  }
});
```

## 7. Enregistrer les routes

```javascript
// server/app.js ou server/index.js
const notificationsRoutes = require('./routes/notifications');

app.use('/notifications', notificationsRoutes);
```

## 8. Variables d'environnement

Ajoutez à votre `.env`:

```env
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=your-client-email
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

## Test avec cURL

```bash
# Envoyer une notification à un utilisateur
curl -X POST http://localhost:3000/notifications/send \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "userId": 123,
    "title": "Test",
    "body": "Ceci est un test",
    "data": {
      "type": "test"
    }
  }'
```
