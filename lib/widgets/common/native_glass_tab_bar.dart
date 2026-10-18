import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';
import 'glass.dart';

class NativeTabItem {
  final String label;
  final String symbol;

  const NativeTabItem({required this.label, required this.symbol});
}

/// Barre d'onglets UIKit native : sous Xcode 26 / iOS 26 elle prend le rendu
/// Liquid Glass officiel d'Apple. Un flou progressif transparent adoucit
/// l'endroit où le contenu passe derrière la barre.
class NativeGlassTabBar extends StatelessWidget {
  final List<NativeTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NativeGlassTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          top: -56,
          child: const IgnorePointer(
            child: GlassBar(top: false, opacity: 0.45),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            safeBottom > 0 ? safeBottom - 10 : 8,
          ),
          child: Center(
            heightFactor: 1,
            child: CNTabBar(
              items: [
                for (final item in items)
                  CNTabBarItem(label: item.label, icon: CNSymbol(item.symbol)),
              ],
              currentIndex: currentIndex,
              onTap: onTap,
              tint: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
