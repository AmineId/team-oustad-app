import 'dart:ui';

import 'package:flutter/material.dart';

/// Autorise le glisser à la souris / trackpad sur les carrousels : par défaut
/// Flutter web et desktop ne font défiler un [PageView] qu'au toucher.
/// À appliquer localement (pas au [MaterialApp]) pour ne pas gêner la
/// sélection de texte dans les listes.
class CarouselScrollBehavior extends MaterialScrollBehavior {
  const CarouselScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
}
