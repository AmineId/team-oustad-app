import 'package:flutter/material.dart';
import 'package:team_fitness_app/core/utils/platform_utils.dart';
import '../../core/theme/theme.dart';

/// A card widget that adapts its styling based on device type
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double? elevation;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.color,
    this.elevation,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final deviceType = PlatformUtils.getDeviceType(context);
    
    final responsivePadding = padding ?? (
      deviceType == DeviceType.watch
          ? const EdgeInsets.all(8.0)
          : deviceType == DeviceType.mobile
              ? const EdgeInsets.all(16.0)
              : const EdgeInsets.all(20.0)
    );
    
    final responsiveElevation = elevation ?? (
      deviceType == DeviceType.watch ? 2.0 : 4.0
    );
    
    final responsiveBorderRadius = borderRadius ?? BorderRadius.circular(
      deviceType == DeviceType.watch ? 8.0 : 16.0
    );

    return Card(
      color: color ?? (isDark ? AppColors.darkCard : AppColors.lightCard),
      elevation: responsiveElevation,
      shape: RoundedRectangleBorder(
        borderRadius: responsiveBorderRadius,
      ),
      child: Padding(
        padding: responsivePadding,
        child: child,
      ),
    );
  }
}

/// A responsive elevated button that adapts size based on device
class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ResponsiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = PlatformUtils.getDeviceType(context);
    
    final padding = deviceType == DeviceType.watch
        ? const EdgeInsets.symmetric(vertical: 12, horizontal: 16)
        : const EdgeInsets.symmetric(vertical: 16, horizontal: 24);
    
    final fontSize = deviceType == DeviceType.watch ? 12.0 : 16.0;
    final iconSize = deviceType == DeviceType.watch ? 16.0 : 24.0;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.primary,
        foregroundColor: foregroundColor ?? Colors.white,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            deviceType == DeviceType.watch ? 8 : 12,
          ),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: iconSize,
              height: iconSize,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: iconSize),
                  SizedBox(width: deviceType == DeviceType.watch ? 4 : 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Responsive icon button with appropriate sizing
class ResponsiveIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;

  const ResponsiveIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = PlatformUtils.getIconSize(context);

    return IconButton(
      icon: Icon(icon),
      iconSize: iconSize,
      color: color,
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}

/// A responsive app bar title that adapts font size
class ResponsiveAppBarTitle extends StatelessWidget {
  final String title;

  const ResponsiveAppBarTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final deviceType = PlatformUtils.getDeviceType(context);
    
    final fontSize = deviceType == DeviceType.watch
        ? 14.0
        : deviceType == DeviceType.mobile
            ? 20.0
            : 24.0;

    return Text(
      title,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}
