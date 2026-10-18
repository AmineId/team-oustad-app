import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hauteur de la capsule de navigation flottante (style Liquid Glass iOS 26).
const double glassTabBarHeight = 64;

/// Espace vertical total réservé en bas pour la capsule, hors zone sûre.
const double glassTabBarReserved = glassTabBarHeight + 8 + 12;

/// iOS 26+ : la vraie barre native Liquid Glass (UIKit) est utilisée.
final bool supportsNativeLiquidGlass = _detectIos26();

bool _detectIos26() {
  if (!Platform.isIOS) return false;
  final match = RegExp(
    r'Version (\d+)',
  ).firstMatch(Platform.operatingSystemVersion);
  return (int.tryParse(match?.group(1) ?? '') ?? 0) >= 26;
}

/// Espace à réserver en bas (hors zone sûre) selon la barre d'onglets utilisée.
double get glassBottomReserved =>
    supportsNativeLiquidGlass ? 72 : glassTabBarReserved;

const List<double> _saturate = <double>[
  1.6, -0.3, -0.3, 0, 0, //
  -0.3, 1.6, -0.3, 0, 0, //
  -0.3, -0.3, 1.6, 0, 0, //
  0, 0, 0, 1, 0, //
];

ImageFilter _glassFilter(double sigma) => ImageFilter.compose(
  outer: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
  inner: const ColorFilter.matrix(_saturate),
);

/// Surface "Liquid Glass" : flou saturé, voile dégradé, bord réfléchissant.
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double sigma;
  final EdgeInsetsGeometry? padding;

  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(32)),
    this.sigma = 28,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const tint = Colors.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: _glassFilter(sigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withValues(alpha: isDark ? 0.16 : 0.55),
                  tint.withValues(alpha: isDark ? 0.05 : 0.30),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.22 : 0.7),
                width: 0.8,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Header translucide : le flou s'estompe vers le bas, sans trait de séparation.
class GlassBar extends StatelessWidget {
  final Widget? child;
  final bool top;
  final double opacity;

  const GlassBar({super.key, this.child, this.top = true, this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        begin: top ? Alignment.topCenter : Alignment.bottomCenter,
        end: top ? Alignment.bottomCenter : Alignment.topCenter,
        colors: const [Colors.black, Colors.black, Colors.transparent],
        stops: const [0, 0.7, 1],
      ).createShader(rect),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: top ? Alignment.topCenter : Alignment.bottomCenter,
                end: top ? Alignment.bottomCenter : Alignment.topCenter,
                colors: [
                  bg.withValues(alpha: 0.85 * opacity),
                  bg.withValues(alpha: 0.35 * opacity),
                ],
              ),
            ),
            child: child ?? const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

/// Fond uni commun à toutes les pages, identique à la teinte des barres glass.
BoxDecoration appBackgroundDecoration(BuildContext context) =>
    BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor);

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

class GlassTabItem {
  final Widget icon;
  final Widget activeIcon;
  final String label;

  const GlassTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Barre d'onglets flottante en capsule, style Liquid Glass iOS 26.
class GlassTabBar extends StatelessWidget {
  final List<GlassTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        safeBottom > 0 ? safeBottom - 10 : 12,
      ),
      child: SizedBox(
        height: glassTabBarHeight,
        child: LiquidGlass(
          borderRadius: BorderRadius.circular(glassTabBarHeight / 2),
          padding: const EdgeInsets.all(5),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (i != currentIndex) HapticFeedback.selectionClick();
                      onTap(i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          (glassTabBarHeight - 10) / 2,
                        ),
                        color: i == currentIndex
                            ? Colors.white.withValues(alpha: 0.14)
                            : Colors.transparent,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconTheme(
                            data: IconThemeData(
                              size: 24,
                              color: i == currentIndex ? primary : muted,
                            ),
                            child: i == currentIndex
                                ? items[i].activeIcon
                                : items[i].icon,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: i == currentIndex
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: i == currentIndex ? primary : muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
