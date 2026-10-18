import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';

class NativeTabItem {
  final String label;
  final String symbol;

  const NativeTabItem({required this.label, required this.symbol});
}

/// Barre d'onglets UIKit native : sous Xcode 26 / iOS 26 elle prend le rendu
/// Liquid Glass officiel d'Apple.
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        safeBottom > 0 ? safeBottom - 10 : 8,
      ),
      child: Center(
        heightFactor: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
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
    );
  }
}
