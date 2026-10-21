import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'notification_router.dart';

/// Service de gestion des notifications locales
/// Permet d'envoyer des notifications immédiates et planifiées
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialise le service de notifications
  /// Doit être appelé au démarrage de l'application
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialiser les fuseaux horaires
    tz.initializeTimeZones();

    // Configuration Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration iOS avec catégories d'actions
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'help_request',
          actions: [
            DarwinNotificationAction.plain(
              'coming',
              'J\'arrive 🏃',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              'busy',
              'Occupé ⏰',
              options: {
                DarwinNotificationActionOption.foreground,
              },
            ),
          ],
        ),
      ],
    );

    // Configuration globale
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialiser le plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Créer le canal de notification pour les demandes d'aide avec actions
    const AndroidNotificationChannel helpChannel = AndroidNotificationChannel(
      'team_fitness_help_channel',
      'Demandes d\'aide',
      description: 'Notifications de demandes d\'aide des membres avec actions rapides',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Enregistrer le canal
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(helpChannel);
    }

    _initialized = true;
  }

  /// Demande les permissions de notification (iOS principalement)
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    // iOS
    final iosImplementation = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    // Android 13+
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }

    return true; // Pour les versions Android plus anciennes
  }

  /// Callback appelé quand l'utilisateur tape sur une notification ou un bouton d'action
  void _onNotificationTapped(NotificationResponse response) {
    // ignore: avoid_print
    debugPrint('Notification tapped: ${response.payload}');
    // ignore: avoid_print
    debugPrint('Action ID: ${response.actionId}');
    
    // Traiter les actions des boutons
    if (response.actionId != null && response.payload != null) {
      _handleNotificationAction(response.actionId!, response.payload!);
      return;
    }
    
    // Tap sur le corps de la notification : ouvrir l'onglet concerné.
    NotificationRouter.open(_payloadType(response.payload));
  }

  /// Type d'une notification d'après son payload : data FCM encodé en JSON,
  /// ou format local `type|…` / `type_<id>` (help_request, payment, planning…).
  static String? _payloadType(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    if (payload.startsWith('{')) {
      try {
        final data = jsonDecode(payload);
        return data is Map<String, dynamic> ? data['type'] as String? : null;
      } catch (_) {
        return null;
      }
    }
    final type = payload.split('|').first;
    if (type != payload) return type;
    final underscore = payload.lastIndexOf('_');
    return underscore > 0 ? payload.substring(0, underscore) : payload;
  }

  /// Gestionnaire d'actions de notification (pour les réponses aux demandes d'aide)
  void _handleNotificationAction(String actionId, String payload) {
    // ignore: avoid_print
    debugPrint('Handling notification action: $actionId with payload: $payload');
    
    // Le payload est au format: help_request|memberId|exerciseName
    if (payload.startsWith('help_request|')) {
      final parts = payload.split('|');
      if (parts.length >= 3) {
        final memberId = int.tryParse(parts[1]);
        final exerciseName = parts[2];
        
        if (memberId != null) {
          // Notifier via un stream ou callback que l'action a été déclenchée
          // Le FCMService écoutera cet événement pour envoyer la réponse au serveur
          onHelpResponseAction?.call(memberId, exerciseName, actionId);
        }
      }
    }
  }

  /// Callback pour gérer les réponses aux demandes d'aide
  /// Sera défini par FCMService pour envoyer la réponse au serveur
  Function(int memberId, String exerciseName, String response)? onHelpResponseAction;

  /// Affiche une notification immédiate
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'team_fitness_channel',
      'Team Oustad',
      channelDescription: 'Notifications de l\'application Team Oustad',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Affiche une notification avec des boutons d'action
  /// Utilisé pour les demandes d'aide où l'admin peut répondre directement
  Future<void> showNotificationWithActions({
    required int id,
    required String title,
    required String body,
    String? payload,
    List<AndroidNotificationAction>? actions,
  }) async {
    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'team_fitness_help_channel',
      'Demandes d\'aide',
      channelDescription: 'Notifications de demandes d\'aide des membres',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      actions: actions,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Affiche une notification de demande d'aide avec les boutons J'arrive / Occupé
  Future<void> showHelpRequestNotification({
    required int id,
    required String memberName,
    required String exerciseName,
    required String memberId,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'team_fitness_help_channel',
      'Demandes d\'aide',
      channelDescription: 'Notifications de demandes d\'aide des membres',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      actions: [
        AndroidNotificationAction(
          'coming',
          'J\'arrive 🏃',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'busy',
          'Occupé ⏰',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'help_request',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      '🆘 Demande d\'aide',
      '$memberName a besoin d\'aide pour: $exerciseName',
      details,
      payload: 'help_request|$memberId|$exerciseName',
    );
  }

  /// Affiche une notification de réponse à une demande d'aide
  Future<void> showHelpResponseNotification({
    required int id,
    required String adminName,
    required String response,
  }) async {
    if (!_initialized) await initialize();

    String title;
    String body;
    
    if (response == 'coming') {
      title = '✅ Aide en route';
      body = '$adminName arrive pour vous aider !';
    } else if (response == 'busy') {
      title = '⏰ Coach occupé';
      body = '$adminName est actuellement occupé';
    } else {
      title = '📬 Réponse du coach';
      body = adminName;
    }

    await showNotification(
      id: id,
      title: title,
      body: body,
      payload: 'help_response|$response',
    );
  }

  /// Planifie une notification pour une date/heure spécifique
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'team_fitness_channel',
      'Team Oustad',
      channelDescription: 'Notifications de l\'application Team Oustad',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Notification de rappel de paiement
  Future<void> schedulePaymentReminder({
    required int paymentId,
    required String memberName,
    required double amount,
    required DateTime dueDate,
  }) async {
    // Notification 3 jours avant
    final reminder3Days = dueDate.subtract(const Duration(days: 3));
    if (reminder3Days.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: paymentId * 10 + 1,
        title: 'Rappel de paiement',
        body: 'Le paiement de $amount MAD pour $memberName est dû dans 3 jours',
        scheduledDate: reminder3Days,
        payload: 'payment_$paymentId',
      );
    }

    // Notification le jour même
    if (dueDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: paymentId * 10 + 2,
        title: 'Paiement dû aujourd\'hui',
        body: 'Le paiement de $amount MAD pour $memberName est dû aujourd\'hui',
        scheduledDate: dueDate,
        payload: 'payment_$paymentId',
      );
    }
  }

  /// Notification de nouveau planning
  Future<void> notifyNewPlanning({
    required int memberId,
    required String memberName,
    required String planningTitle,
  }) async {
    await showNotification(
      id: memberId,
      title: 'Nouveau planning',
      body: 'Un nouveau planning "$planningTitle" a été créé pour $memberName',
      payload: 'planning_$memberId',
    );
  }

  /// Notification de rappel d'entraînement
  Future<void> scheduleWorkoutReminder({
    required int memberId,
    required String workoutDay,
    required DateTime reminderTime,
  }) async {
    await scheduleNotification(
      id: memberId * 100,
      title: 'Rappel d\'entraînement',
      body: 'N\'oubliez pas votre séance d\'aujourd\'hui: $workoutDay',
      scheduledDate: reminderTime,
      payload: 'workout_$memberId',
    );
  }

  /// Notification d'expiration d'abonnement
  Future<void> scheduleSubscriptionExpiryReminder({
    required int subscriptionId,
    required String memberName,
    required DateTime expiryDate,
  }) async {
    // Notification 7 jours avant
    final reminder7Days = expiryDate.subtract(const Duration(days: 7));
    if (reminder7Days.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: subscriptionId * 20 + 1,
        title: 'Abonnement bientôt expiré',
        body: 'L\'abonnement de $memberName expire dans 7 jours',
        scheduledDate: reminder7Days,
        payload: 'subscription_$subscriptionId',
      );
    }

    // Notification le jour de l'expiration
    if (expiryDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: subscriptionId * 20 + 2,
        title: 'Abonnement expiré',
        body: 'L\'abonnement de $memberName expire aujourd\'hui',
        scheduledDate: expiryDate,
        payload: 'subscription_$subscriptionId',
      );
    }
  }

  /// Annule une notification spécifique
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Annule toutes les notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Obtient les notifications en attente
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}




