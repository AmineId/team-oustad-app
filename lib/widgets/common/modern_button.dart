import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/theme.dart';

/// Bouton primaire moderne — scale on press + haptic + variants thématisés
class ModernButton extends StatefulWidget {
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

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  VoidCallback? get _onPressed {
    if (widget.onPressed == null || widget.isLoading) return null;
    return () {
      HapticFeedback.lightImpact();
      widget.onPressed!();
    };
  }

  void _down(_) { if (_onPressed != null) _ctrl.forward(); }
  void _up(_)   => _ctrl.reverse();
  void _cancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final buttonChild = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _spinnerColor(colorScheme),
              ),
            ),
          )
        else if (widget.icon != null)
          Icon(widget.icon, size: 20),
        if (widget.isLoading || widget.icon != null) const SizedBox(width: 8),
        Text(widget.text),
      ],
    );

    Widget button;
    switch (widget.variant) {
      case ModernButtonVariant.primary:
        button = ElevatedButton(onPressed: _onPressed, child: buttonChild);
        break;
      case ModernButtonVariant.secondary:
        button = OutlinedButton(onPressed: _onPressed, child: buttonChild);
        break;
      case ModernButtonVariant.text:
        button = TextButton(onPressed: _onPressed, child: buttonChild);
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
      case ModernButtonVariant.accent:
        button = ElevatedButton(
          onPressed: _onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            foregroundColor: Colors.white,
          ),
          child: buttonChild,
        );
        break;
      case ModernButtonVariant.premium:
        button = ElevatedButton(
          onPressed: _onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentViolet,
            foregroundColor: Colors.white,
          ),
          child: buttonChild,
        );
        break;
    }

    if (widget.fullWidth) button = SizedBox(width: double.infinity, child: button);

    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      child: ScaleTransition(scale: _scale, child: button),
    );
  }

  Color _spinnerColor(ColorScheme cs) {
    switch (widget.variant) {
      case ModernButtonVariant.secondary:
      case ModernButtonVariant.text:
        return cs.primary;
      default:
        return Colors.white;
    }
  }
}

enum ModernButtonVariant {
  primary,
  secondary,
  text,
  danger,
  success,
  accent,
  premium,
}
