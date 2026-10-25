import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

/// Simplified stat card for smartwatch displays
class WatchStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const WatchStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact action button for watch
class WatchActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const WatchActionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.palette.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 12),
          ],
        ),
      ),
    );
  }
}

/// Simple list item for watch
class WatchListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;

  const WatchListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: context.palette.primary, size: 16),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Watch header section
class WatchHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const WatchHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white60,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

