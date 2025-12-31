import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/theme/theme.dart';

/// Carte de bannière clickable
class BannerCard extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback? onTap;
  final bool showStatistics;
  final double? height;
  final EdgeInsets? margin;

  const BannerCard({
    super.key,
    required this.banner,
    this.onTap,
    this.showStatistics = false,
    this.height,
    this.margin,
  });

  Color _getBackgroundColor(BuildContext context) {
    if (banner.backgroundColor != null) {
      try {
        return Color(int.parse(banner.backgroundColor!.replaceFirst('#', '0xFF')));
      } catch (e) {
        // Fallback to theme color if parsing fails
      }
    }
    return Theme.of(context).cardTheme.color ?? Colors.grey[800]!;
  }

  Color _getTextColor(BuildContext context) {
    if (banner.textColor != null) {
      try {
        return Color(int.parse(banner.textColor!.replaceFirst('#', '0xFF')));
      } catch (e) {
        // Fallback to theme color if parsing fails
      }
    }
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
  }

  IconData _getTypeIcon() {
    switch (banner.type) {
      case BannerType.seasonal:
        return Icons.celebration;
      case BannerType.event:
        return Icons.event;
      case BannerType.promotion:
        return Icons.local_offer;
      case BannerType.info:
        return Icons.info_outline;
      case BannerType.announcement:
        return Icons.campaign;
    }
  }

  String _getTypeName() {
    switch (banner.type) {
      case BannerType.seasonal:
        return 'Saisonnier';
      case BannerType.event:
        return 'Événement';
      case BannerType.promotion:
        return 'Promotion';
      case BannerType.info:
        return 'Info';
      case BannerType.announcement:
        return 'Annonce';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor(context);
    final textColor = _getTextColor(context);

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: height ?? 180,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Image de fond
                Positioned.fill(
                  child: _buildBannerImage(),
                ),
                
                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Contenu
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Badge de type
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getTypeIcon(),
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getTypeName(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Titre
                        Text(
                          banner.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Description
                        if (banner.description != null && banner.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            banner.description!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              shadows: const [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        
                        // Statistiques (mode admin)
                        if (showStatistics) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStat(Icons.visibility, '${banner.viewCount}'),
                              const SizedBox(width: 12),
                              _buildStat(Icons.touch_app, '${banner.clickCount}'),
                              const SizedBox(width: 12),
                              _buildStat(
                                Icons.trending_up,
                                '${banner.clickThroughRate.toStringAsFixed(1)}%',
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Icône de clic (si action disponible)
                if (banner.action.type != BannerActionType.none)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerImage() {
    // Si l'image est en base64, l'afficher directement
    if (banner.imageBase64 != null && banner.imageBase64!.isNotEmpty) {
      try {
        final imageData = banner.imageBase64!.contains('base64,')
            ? banner.imageBase64!.split('base64,')[1]
            : banner.imageBase64!;
        return Image.memory(
          base64Decode(imageData),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } catch (e) {
        return _buildPlaceholder();
      }
    }

    // Sinon, afficher depuis l'URL
    if (banner.imageUrl.isNotEmpty) {
      return Image.network(
        banner.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.2),
      child: Center(
        child: Icon(
          _getTypeIcon(),
          size: 64,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
