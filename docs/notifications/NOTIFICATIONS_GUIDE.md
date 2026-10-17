# Guide d'utilisation des Notifications

## Configuration

Les notifications sont déjà configurées dans l'application. Le service `NotificationService` est initialisé au démarrage de l'app.

## Utilisation basique

### 1. Importer le service

```dart
import 'package:team_fitness_app/services/notification_service.dart';
```

### 2. Obtenir une instance

```dart
final notificationService = NotificationService();
```

### 3. Envoyer une notification immédiate

```dart
await notificationService.showNotification(
  id: 1,
  title: 'Titre de la notification',
  body: 'Message de la notification',
  payload: 'data_optionnelle', // Pour identifier la notification quand l'utilisateur clique dessus
);
```

### 4. Planifier une notification

```dart
final scheduledDate = DateTime.now().add(Duration(hours: 2));

await notificationService.scheduleNotification(
  id: 2,
  title: 'Rappel',
  body: 'N\'oubliez pas votre rendez-vous',
  scheduledDate: scheduledDate,
  payload: 'appointment_123',
);
```

## Cas d'usage spécifiques

### Rappel de paiement

```dart
await notificationService.schedulePaymentReminder(
  paymentId: 123,
  memberName: 'Jean Dupont',
  amount: 49.99,
  dueDate: DateTime(2025, 11, 20),
);
```

Cette méthode crée automatiquement 2 notifications :
- Une notification 3 jours avant la date d'échéance
- Une notification le jour même

### Nouveau planning créé

```dart
await notificationService.notifyNewPlanning(
  memberId: 456,
  memberName: 'Marie Martin',
  planningTitle: 'Programme Full Body',
);
```

### Rappel d'entraînement

```dart
final tomorrow8am = DateTime.now().add(Duration(days: 1)).copyWith(hour: 8, minute: 0);

await notificationService.scheduleWorkoutReminder(
  memberId: 789,
  workoutDay: 'Jour de jambes',
  reminderTime: tomorrow8am,
);
```

### Expiration d'abonnement

```dart
await notificationService.scheduleSubscriptionExpiryReminder(
  subscriptionId: 321,
  memberName: 'Pierre Dubois',
  expiryDate: DateTime(2026, 1, 15),
);
```

Cette méthode crée automatiquement 2 notifications :
- Une notification 7 jours avant l'expiration
- Une notification le jour de l'expiration

## Gestion des notifications

### Annuler une notification spécifique

```dart
await notificationService.cancelNotification(123);
```

### Annuler toutes les notifications

```dart
await notificationService.cancelAllNotifications();
```

### Voir les notifications en attente

```dart
final pending = await notificationService.getPendingNotifications();
for (var notification in pending) {
  print('ID: ${notification.id}, Titre: ${notification.title}');
}
```

## Intégration dans les écrans

### Exemple : Lors de la création d'un abonnement

```dart
// Dans admin_create_subscription_screen.dart

Future<void> _createSubscription() async {
  // ... création de l'abonnement ...
  
  final result = await _apiService.createSubscription(...);
  
  if (result != null) {
    // Notification de succès
    await NotificationService().showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Abonnement créé',
      body: 'L\'abonnement a été créé avec succès',
    );
    
    // Planifier les rappels de paiement
    if (result['payments'] != null) {
      for (var payment in result['payments']) {
        await NotificationService().schedulePaymentReminder(
          paymentId: payment['id'],
          memberName: memberName,
          amount: payment['amount'],
          dueDate: DateTime.parse(payment['dueDate']),
        );
      }
    }
  }
}
```

### Exemple : Lors de la création d'un planning

```dart
// Dans admin_create_planning_screen.dart

Future<void> _createPlanning() async {
  // ... création du planning ...
  
  final result = await _apiService.createPlanning(...);
  
  if (result != null) {
    // Notifier le membre
    await NotificationService().notifyNewPlanning(
      memberId: memberId,
      memberName: memberName,
      planningTitle: titleController.text,
    );
    
    // Planifier des rappels d'entraînement pour chaque jour de la semaine
    for (int i = 0; i < 7; i++) {
      final nextOccurrence = _getNextDayOfWeek(i);
      await NotificationService().scheduleWorkoutReminder(
        memberId: memberId,
        workoutDay: _getDayName(i),
        reminderTime: nextOccurrence.copyWith(hour: 8, minute: 0),
      );
    }
  }
}
```

## Écran de test

Un écran de test est disponible : `NotificationTestScreen`

Pour y accéder, ajoutez-le à votre navigation :

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const NotificationTestScreen(),
  ),
);
```

Cet écran permet de :
- Tester les notifications immédiates
- Tester les notifications planifiées
- Tester tous les types de notifications spécifiques
- Voir les notifications en attente
- Annuler toutes les notifications

## Permissions

### Android
Les permissions sont automatiquement demandées au démarrage de l'app (Android 13+).

### iOS
Les permissions sont demandées la première fois qu'une notification est envoyée.

## Notes importantes

1. **IDs uniques** : Assurez-vous que chaque notification a un ID unique pour éviter les conflits
2. **Timezone** : Les notifications planifiées utilisent le fuseau horaire local de l'appareil
3. **Boot** : Sur Android, les notifications planifiées sont automatiquement reprogrammées après un redémarrage
4. **Background** : Les notifications fonctionnent même quand l'app est fermée

## Dépannage

### Les notifications n'apparaissent pas
1. Vérifiez les permissions dans les paramètres de l'appareil
2. Vérifiez que l'ID de la notification est unique
3. Pour les notifications planifiées, vérifiez que la date est dans le futur

### Les notifications planifiées ne fonctionnent pas après un redémarrage
- Assurez-vous que le receiver est bien configuré dans AndroidManifest.xml
- Vérifiez que la permission RECEIVE_BOOT_COMPLETED est présente

### Les notifications ne s'affichent pas en premier plan sur Android
- Vérifiez que l'importance du canal est définie sur `Importance.high`
