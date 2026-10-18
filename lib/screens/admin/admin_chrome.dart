import 'package:flutter/material.dart';

/// Écrans admin utilisés à la fois en onglet (onBack fourni) et en route poussée.
/// En onglet, le body passe sous la barre glass du shell : on décale le sous-écran
/// sous le header et au-dessus de la navbar pour éviter tout chevauchement.
Widget adminFrame(
  BuildContext context, {
  required bool embedded,
  required Widget child,
}) {
  if (!embedded) return child;
  final mq = MediaQuery.of(context);
  return Padding(
    padding: EdgeInsets.only(top: mq.padding.top, bottom: mq.padding.bottom),
    child: MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: child,
    ),
  );
}
