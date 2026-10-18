import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Barre translucide (blur) dont la teinte vient de la couleur de fond du thème,
/// pour se fondre dans le dégradé de la page au lieu de former une bande noire.
class GlassBar extends StatelessWidget {
  final Widget? child;
  final bool top;

  const GlassBar({super.key, this.child, this.top = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final line = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07);
    final side = BorderSide(color: line, width: 0.5);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.62),
            border: top ? Border(bottom: side) : Border(top: side),
          ),
          child: child ?? const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Fond dégradé commun à toutes les pages (même départ/arrivée partout).
BoxDecoration appBackgroundDecoration(BuildContext context) {
  final theme = Theme.of(context);
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [theme.scaffoldBackgroundColor, theme.cardTheme.color!],
    ),
  );
}

/// AppBar pour les écrans poussés avec Navigator.push : glass sur iOS,
/// AppBar standard ailleurs. À utiliser avec `extendBodyBehindAppBar: glassExtendsBody`.
PreferredSizeWidget glassAppBar(
  BuildContext context, {
  required Widget title,
  List<Widget>? actions,
  Widget? leading,
  bool centerTitle = true,
}) {
  final isIOS = Platform.isIOS;
  return AppBar(
    title: title,
    actions: actions,
    leading: leading,
    centerTitle: centerTitle,
    backgroundColor: isIOS ? Colors.transparent : null,
    elevation: isIOS ? 0 : null,
    scrolledUnderElevation: isIOS ? 0 : null,
    forceMaterialTransparency: isIOS,
    flexibleSpace: isIOS ? const GlassBar() : null,
  );
}

bool get glassExtendsBody => Platform.isIOS;

/// Sur iOS le body passe sous l'AppBar glass : ajoute la hauteur de la barre
/// au padding haut pour que les scroll views démarrent en dessous.
Widget glassBodyInsets(BuildContext context, Widget child) {
  if (!Platform.isIOS) return child;
  final mq = MediaQuery.of(context);
  return MediaQuery(
    data: mq.copyWith(
      padding: mq.padding.copyWith(top: mq.padding.top + kToolbarHeight),
    ),
    child: child,
  );
}
