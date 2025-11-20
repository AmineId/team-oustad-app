import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class ThemeToggleButton extends StatelessWidget {
  final ThemeProvider themeProvider;
  
  const ThemeToggleButton({
    super.key,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, child) {
        return IconButton(
          onPressed: () => themeProvider.toggleTheme(),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return RotationTransition(
                turns: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              key: ValueKey(themeProvider.isDarkMode),
            ),
          ),
          tooltip: themeProvider.isDarkMode 
            ? 'Passer en mode clair' 
            : 'Passer en mode sombre',
        );
      },
    );
  }
}
