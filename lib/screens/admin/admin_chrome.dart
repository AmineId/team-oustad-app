import 'package:flutter/material.dart';

/// Écrans admin utilisés à la fois en onglet (onBack fourni) et en route poussée.
/// En onglet, le body passe sous la barre glass du shell : on décale le sous-écran
/// sous le header et au-dessus de la navbar pour éviter tout chevauchement.
Widget adminFrame(
  BuildContext context, {
  required bool embedded,
  required Widget child,
  bool padBottom = true,
}) {
  if (!embedded) return child;
  final mq = MediaQuery.of(context);
  return Padding(
    padding: EdgeInsets.only(top: mq.padding.top, bottom: padBottom ? mq.padding.bottom : 0),
    child: MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: padBottom,
      child: child,
    ),
  );
}
