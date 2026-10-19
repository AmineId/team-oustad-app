import 'package:flutter/widgets.dart';

/// Navigator racine, pour afficher un dialog hors de l'écran qui l'a déclenché
/// (ex. vérification de version lancée depuis le splash, déjà remplacé).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
