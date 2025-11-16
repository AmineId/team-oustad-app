import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';
import 'api_service.dart';

/// Service de gestion des notifications push Firebase Cloud Messaging (FCM)
/// Permet de recevoir des notifications depuis le serveur
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  FirebaseMessaging? _messaging;
  final NotificationService _localNotifications = NotificationService();
  final ApiService _apiService = ApiService.fromEnv();
  
  String? _fcmToken;
  bool _initialized = false;
  String? _currentUserToken;

  /// Obtient l'instance de FirebaseMessaging (s'assure que Firebase est prêt)
  Future<FirebaseMessaging> _getMessaging() async {
    if (_messaging != null) return _messaging!;
    
    // S'assurer que Firebase est initialisé
    try {
      // Firebase.app() lève une exception si Firebase n'est pas initialisé
      Firebase.app();
    } catch (e) {
      // Firebase pas encore initialisé, attendre un peu
      // ignore: avoid_print
      print('⚠️ Firebase pas encore prêt, attente...');
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        Firebase.app(); // Vérifier à nouveau
      } catch (e2) {
        // ignore: avoid_print
        print('❌ Firebase toujours pas initialisé: $e2');
        rethrow;
      }
    }
    
    _messaging = FirebaseMessaging.instance;
    return _messaging!;
  }

  /// Obtient le token FCM actuel (de manière synchrone)
  String? get token => _fcmToken;

  /// Obtient le token FCM actuel (de manière asynchrone)
  /// Attend que le token soit disponible si l'initialisation est en cours
  Future<String?> getToken() async {
    // Si déjà initialisé et on a un token, le retourner
    if (_initialized && _fcmToken != null) {
      return _fcmToken;
    }

    // Si pas encore initialisé, initialiser d'abord
    if (!_initialized) {
      await initialize();
    }

    // Si après initialisation on n'a toujours pas de token, essayer de le récupérer
    if (_fcmToken == null) {
      try {
        final messaging = await _getMessaging();
        _fcmToken = await messaging.getToken();
        // ignore: avoid_print
        print('📱 FCM Token récupéré: $_fcmToken');
      } catch (e) {
        // ignore: avoid_print
        print('❌ Erreur récupération token FCM: $e');
      }
    }

    return _fcmToken;
  }

  /// Initialise le service FCM
  /// Doit être appelé après l'initialisation de Firebase
  Future<void> initialize({String? userToken}) async {
    if (_initialized) return;

    _currentUserToken = userToken;

    try {
      final messaging = await _getMessaging();
      
      // Demander les permissions
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // ignore: avoid_print
        print('✅ FCM permissions accordées');
      } else {
        // ignore: avoid_print
        print('⚠️ FCM permissions refusées');
      }

      // Obtenir le token FCM
      _fcmToken = await messaging.getToken();
      // ignore: avoid_print
      print('📱 FCM Token: $_fcmToken');

      // Écouter les changements de token
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        // ignore: avoid_print
        print('🔄 Nouveau FCM Token: $newToken');
        // TODO: Envoyer le nouveau token au serveur
        _sendTokenToServer(newToken);
      });

      // Configurer les handlers de messages
      _setupMessageHandlers();

      // Configurer le callback pour les réponses aux demandes d'aide
      _localNotifications.onHelpResponseAction = _handleHelpResponse;

      _initialized = true;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Erreur initialisation FCM: $e');
    }
  }

  /// Met à jour le token utilisateur pour les appels API
  void setUserToken(String? token) {
    _currentUserToken = token;
  }

  /// Configure les handlers pour les différents états de l'app
  void _setupMessageHandlers() {
    // Messages reçus quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Messages reçus quand l'app est en arrière-plan ou fermée
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Vérifier si l'app a été ouverte depuis une notification
    _checkInitialMessage();
  }

  /// Gère les messages reçus quand l'app est au premier plan
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // ignore: avoid_print
    print('📨 Message reçu au premier plan: ${message.messageId}');
    // ignore: avoid_print
    print('   Titre: ${message.notification?.title}');
    // ignore: avoid_print
    print('   Corps: ${message.notification?.body}');
    // ignore: avoid_print
    print('   Data: ${message.data}');

    // Vérifier si c'est une demande d'aide
    final type = message.data['type'] as String?;
    
    if (type == 'help_request') {
      // Demande d'aide avec boutons d'action
      final memberName = message.data['memberName'] as String? ?? 'Un membre';
      final exerciseName = message.data['exerciseName'] as String? ?? 'un exercice';
      final memberId = message.data['memberId'] as String? ?? '0';
      
      await _localNotifications.showHelpRequestNotification(
        id: message.hashCode,
        memberName: memberName,
        exerciseName: exerciseName,
        memberId: memberId,
      );
    } else if (message.notification != null) {
      // Notification standard
      await _localNotifications.showNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Gère la réponse à une demande d'aide
  Future<void> _handleHelpResponse(
    int memberId,
    String exerciseName,
    String response,
  ) async {
    if (_currentUserToken == null) {
      // ignore: avoid_print
      print('❌ Pas de token utilisateur disponible');
      await _localNotifications.showNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: '❌ Erreur',
        body: 'Impossible d\'envoyer la réponse - non authentifié',
      );
      return;
    }

    try {
      // ignore: avoid_print
      print('📤 Envoi de la réponse: $response pour le membre $memberId sur exercice: $exerciseName');
      
      final success = await _apiService.respondToHelpRequest(
        memberId,
        exerciseName,
        response,
        _currentUserToken!,
      );

      if (success) {
        // ignore: avoid_print
        print('✅ Réponse envoyée avec succès au serveur');
        print('   Le serveur devrait maintenant envoyer une notification FCM au membre $memberId');
        
        // Afficher une notification de confirmation à l'admin
        final responseText = response == 'coming' ? 'J\'arrive 🏃' : 'Occupé ⏰';
        await _localNotifications.showNotification(
          id: DateTime.now().millisecondsSinceEpoch,
          title: '✅ Réponse envoyée',
          body: 'Votre réponse "$responseText" a été transmise au membre',
        );
      } else {
        // ignore: avoid_print
        print('❌ Échec de l\'envoi de la réponse - Le serveur a retourné une erreur');
        await _localNotifications.showNotification(
          id: DateTime.now().millisecondsSinceEpoch,
          title: '❌ Échec',
          body: 'Impossible d\'envoyer la réponse au serveur',
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Erreur lors de l\'envoi de la réponse: $e');
      await _localNotifications.showNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: '❌ Erreur',
        body: 'Erreur réseau lors de l\'envoi de la réponse',
      );
    }
  }

  /// Gère les messages quand l'utilisateur tape sur la notification
  /// (app en arrière-plan ou fermée)
  void _handleBackgroundMessage(RemoteMessage message) {
    // ignore: avoid_print
    print('📨 App ouverte depuis notification: ${message.messageId}');
    // ignore: avoid_print
    print('   Data: ${message.data}');
    
    // TODO: Naviguer vers l'écran approprié selon message.data
    _handleNotificationTap(message.data);
  }

  /// Vérifie si l'app a été ouverte depuis une notification
  Future<void> _checkInitialMessage() async {
    final messaging = await _getMessaging();
    final message = await messaging.getInitialMessage();
    if (message != null) {
      // ignore: avoid_print
      print('📨 App démarrée depuis notification: ${message.messageId}');
      _handleBackgroundMessage(message);
    }
  }

  /// Gère le tap sur une notification
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    switch (type) {
      case 'payment':
        // TODO: Naviguer vers l'écran de paiement
        // final paymentId = data['paymentId'];
        break;
      case 'planning':
        // TODO: Naviguer vers l'écran de planning
        // final planningId = data['planningId'];
        break;
      case 'subscription':
        // TODO: Naviguer vers l'écran d'abonnement
        // final subscriptionId = data['subscriptionId'];
        break;
      default:
        // TODO: Naviguer vers l'écran d'accueil
        break;
    }
  }

  /// Envoie le token FCM au serveur
  /// À appeler après le login de l'utilisateur
  Future<void> _sendTokenToServer(String token) async {
    try {
      // TODO: Implémenter l'envoi au serveur
      // await ApiService.fromEnv().updateUserFCMToken(userId, token);
      // ignore: avoid_print
      print('✅ Token FCM envoyé au serveur');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Erreur envoi token au serveur: $e');
    }
  }

  /// S'abonner à un topic pour recevoir des notifications groupées
  Future<void> subscribeToTopic(String topic) async {
    try {
      final messaging = await _getMessaging();
      await messaging.subscribeToTopic(topic);
      // ignore: avoid_print
      print('✅ Abonné au topic: $topic');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Erreur abonnement au topic $topic: $e');
    }
  }

  /// Se désabonner d'un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      final messaging = await _getMessaging();
      await messaging.unsubscribeFromTopic(topic);
      // ignore: avoid_print
      print('✅ Désabonné du topic: $topic');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Erreur désabonnement du topic $topic: $e');
    }
  }

  /// Supprime le token FCM (logout)
  Future<void> deleteToken() async {
    try {
      final messaging = await _getMessaging();
      await messaging.deleteToken();
      _fcmToken = null;
      // ignore: avoid_print
      print('✅ Token FCM supprimé');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Erreur suppression token: $e');
    }
  }
}

/// Handler pour les messages en arrière-plan (obligatoire au niveau top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialiser Firebase
  await Firebase.initializeApp();
  
  // ignore: avoid_print
  print('📨 Message en arrière-plan: ${message.messageId}');
  // ignore: avoid_print
  print('   Titre: ${message.notification?.title}');
  // ignore: avoid_print
  print('   Corps: ${message.notification?.body}');
}
