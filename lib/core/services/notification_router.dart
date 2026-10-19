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

  static void open(String? type) {
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
