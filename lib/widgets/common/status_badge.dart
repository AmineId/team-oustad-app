import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

/// Badge moderne pour afficher des statuts
class StatusBadge extends StatelessWidget {
  final String text;
  final StatusBadgeType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    this.type = StatusBadgeType.info,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    
    switch (type) {
      case StatusBadgeType.success:
        backgroundColor = AppColors.success.withValues(alpha: 0.15);
        textColor = AppColors.successLight;
        break;
      case StatusBadgeType.error:
        backgroundColor = AppColors.error.withValues(alpha: 0.15);
        textColor = AppColors.errorLight;
        break;
      case StatusBadgeType.warning:
        backgroundColor = AppColors.warning.withValues(alpha: 0.15);
        textColor = AppColors.warningLight;
        break;
      case StatusBadgeType.info:
        backgroundColor = AppColors.info.withValues(alpha: 0.15);
        textColor = AppColors.infoLight;
        break;
      case StatusBadgeType.primary:
        backgroundColor = AppColors.primary.withValues(alpha: 0.15);
        textColor = AppColors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusBadgeType {
  success,
  error,
  warning,
  info,
  primary,
}
