import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';

enum SnackBarType { success, error, info, warning }

class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final (Color color, IconData icon) = switch (type) {
      SnackBarType.success => (context.palette.success, Icons.check_circle_outline),
      SnackBarType.error   => (context.palette.error,   Icons.error_outline),
      SnackBarType.warning => (context.palette.warning,  Icons.warning_amber_outlined),
      SnackBarType.info    => (context.palette.info,     Icons.info_outline),
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withValues(alpha: 0.5)),
          ),
          content: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: textColor, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: SnackBarType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: SnackBarType.error);

  static void info(BuildContext context, String message) =>
      show(context, message, type: SnackBarType.info);

  static void warning(BuildContext context, String message) =>
      show(context, message, type: SnackBarType.warning);
}
