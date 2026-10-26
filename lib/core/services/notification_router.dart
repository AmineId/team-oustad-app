import 'package:flutter/foundation.dart';

/// Relais entre le tap sur une notification (FCM ou locale) et l'écran
/// d'accueil : le service publie le `type` reçu dans les données, l'accueil
/// membre ou admin l'écoute et bascule sur l'onglet concerné.
class NotificationRouter {
  NotificationRouter._();

  /// Type de la dernière notification ouverte, en attente de traitement.
  /// Reste posé si l'app démarre depuis une notification avant que l'accueil
  /// ne soit construit ; l'accueil le consomme alors dans son initState.
  static final ValueNotifier<String?> pending = ValueNotifier<String?>(null);

  /// Données de la dernière notification ouverte (ex. `incidentId`).
  static Map<String, dynamic> data = const {};

  /// Données des messages FCM reçus au premier plan : l'écran ouvert (fil
  /// d'incident…) se rafraîchit sans attendre son polling.
  static final ValueNotifier<Map<String, dynamic>?> received =
      ValueNotifier<Map<String, dynamic>?>(null);

  /// Incident dont le fil est affiché : ses messages ne déclenchent pas de
  /// notification locale.
  static int? openIncidentId;

  static int? incidentIdOf(Map<String, dynamic> data) =>
      int.tryParse('${data['incidentId']}');

  static void open(String? type, [Map<String, dynamic> data = const {}]) {
    NotificationRouter.data = data;
    // Repasser par null garantit une notification même si le type est identique.
    pending.value = null;
    pending.value = type ?? 'home';
  }

  /// Retourne le type en attente et le marque comme traité.
  static String? take() {
    final type = pending.value;
    pending.value = null;
    return type;
  }
}
