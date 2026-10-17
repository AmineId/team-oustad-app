import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/theme.dart';

/// Bouton primaire moderne avec style cohérent
class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final ModernButtonVariant variant;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.variant = ModernButtonVariant.primary,
  });

  VoidCallback? get _onPressed {
    if (onPressed == null || isLoading) return null;
    return () {
      HapticFeedback.mediumImpact();
      onPressed!();
    };
  }

  @override
  Widget build(BuildContext context) {
    final buttonChild = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                (variant == ModernButtonVariant.primary ||
                        variant == ModernButtonVariant.danger ||
                        variant == ModernButtonVariant.success)
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        else if (icon != null)
          Icon(icon, size: 20),
        if (isLoading || icon != null) const SizedBox(width: 8),
        Text(text),
      ],
    );

    Widget button;
    switch (variant) {
      case ModernButtonVariant.primary:
        button = ElevatedButton(
          onPressed: _onPressed,
          child: buttonChild,
        );
        break;
      case ModernButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: _onPressed,
          child: buttonChild,
        );
        break;
      case ModernButtonVariant.text:
        button = TextButton(
          onPressed: _onPressed,
          child: buttonChild,
        );
        break;
      case ModernButtonVariant.danger:
        button = ElevatedButton(
          onPressed: _onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: buttonChild,
        );
        break;
      case ModernButtonVariant.success:
        button = ElevatedButton(
          onPressed: _onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
          child: buttonChild,
        );
        break;
    }

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

enum ModernButtonVariant {
  primary,
  secondary,
  text,
  danger,
  success,
}
