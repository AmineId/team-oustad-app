import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

/// Card moderne avec ombres et bordures cohérentes
class ModernCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final bool elevated;

  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
      final card = Container(
      margin: margin ?? const EdgeInsets.all(8),
      child: Material(
        color: color ?? theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        elevation: elevated ? 2 : 0,
        shadowColor: theme.brightness == Brightness.dark 
          ? AppColors.darkShadow 
          : AppColors.lightShadow,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: theme.brightness == Brightness.light
                  ? Border.all(color: AppColors.lightBorder.withValues(alpha: 0.5))
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );

    return card;
  }
}
