import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/models.dart';
import '../../core/services/banner_service.dart';
import '../../core/services/api_service.dart';

/// Carrousel de bannières simplifié et modulaire
///
/// Usage:
/// ```dart
/// BannerCarousel(
///   height: 140,
///   onBannerTap: (banner) => handleNavigation(banner),
/// )
/// ```
class BannerCarousel extends StatefulWidget {
  final double height;
  final Duration autoScrollDuration;
  final bool autoScroll;
  final void Function(BannerModel)? onBannerTap;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final int? gymId;
  final bool activeOnly;

  const BannerCarousel({
    super.key,
    this.height = 140,
    this.autoScrollDuration = const Duration(seconds: 5),
    this.autoScroll = true,
    this.onBannerTap,
    this.margin,
    this.borderRadius,
    this.gymId,
    this.activeOnly = true,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController();
  final BannerService _bannerService = BannerService(ApiService.fromEnv());

  List<BannerModel> _banners = [];
  bool _isLoading = true;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    setState(() => _isLoading = true);

    try {
      final banners = await _bannerService.getAllBanners(
        gymId: widget.gymId,
        activeOnly: widget.activeOnly,
      );
      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoading = false;
        });
        if (banners.isNotEmpty && widget.autoScroll) {
          _setupAutoScroll();
        }
      }
    } catch (e) {
      debugPrint('Error loading banners: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(widget.autoScrollDuration, (timer) {
      if (!mounted || _banners.isEmpty) return;

      final nextPage = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _handleBannerTap(BannerModel banner) async {
    // Track click if banner has an ID
    if (banner.id != null) {
      await _bannerService.trackClick(banner.id!);
    }

    // Custom callback
    if (widget.onBannerTap != null) {
      widget.onBannerTap!(banner);
      return;
    }

    // Default action handling using BannerAction
    final action = banner.action;
    if (action != null && action.data != null && action.data!.isNotEmpty) {
      if (action.type == BannerActionType.externalUrl) {
        final url = Uri.parse(action.data!);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } else if (action.type == BannerActionType.navigate) {
        if (mounted) {
          Navigator.pushNamed(context, action.data!);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show nothing while loading or if no banners
    if (_isLoading || _banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return BannerCard(
                banner: _banners[index],
                onTap: () => _handleBannerTap(_banners[index]),
                height: widget.height,
                margin: widget.margin,
                borderRadius: widget.borderRadius,
              );
            },
          ),

          // Page indicators
          if (_banners.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _banners.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Carte de bannière individuelle
class BannerCard extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback? onTap;
  final double? height;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;

  const BannerCard({
    super.key,
    required this.banner,
    this.onTap,
    this.height,
    this.margin,
    this.borderRadius,
  });

  Color? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;
    try {
      // Handle hex colors like #FFFFFF or FFFFFF
      String hex = colorString.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(banner.backgroundColor);
    final txtColor = _parseColor(banner.textColor) ?? Colors.white;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(16);

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: height ?? 140,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveBorderRadius,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: effectiveBorderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: effectiveBorderRadius,
              child: Stack(
                children: [
                  // Background image or color
                  Positioned.fill(
                    child: _buildBackgroundImage(bgColor),
                  ),

                  // Modern gradient overlay - plus subtil et élégant
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content - style moderne et compact
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            banner.title,
                            style: TextStyle(
                              color: txtColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 6),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (banner.description != null &&
                              banner.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              banner.description!,
                              style: TextStyle(
                                color: txtColor.withValues(alpha: 0.95),
                                fontSize: 13,
                                shadows: const [
                                  Shadow(color: Colors.black, blurRadius: 4),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Arrow indicator if action is defined - style moderne
                  if (banner.action != null &&
                      banner.action!.type != BannerActionType.none &&
                      banner.action!.data != null &&
                      banner.action!.data!.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: bgColor ?? Colors.black87,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Construire l'image de fond (URL ou base64)
  Widget _buildBackgroundImage(Color? fallbackColor) {
    // Vérifier si c'est une image base64
    if (banner.imageBase64 != null && banner.imageBase64!.isNotEmpty) {
      try {
        // Extraire les données base64
        String base64String = banner.imageBase64!;
        if (base64String.contains(',')) {
          base64String = base64String.split(',').last;
        }
        
        final bytes = const Base64Decoder().convert(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(fallbackColor),
        );
      } catch (e) {
        return _buildFallback(fallbackColor);
      }
    }
    
    // Vérifier si c'est une URL
    if (banner.imageUrl != null && banner.imageUrl!.isNotEmpty) {
      return Image.network(
        banner.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallback(fallbackColor),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: fallbackColor ?? Colors.grey[800],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    }
    
    return _buildFallback(fallbackColor);
  }

  Widget _buildFallback(Color? color) {
    return Container(
      color: color ?? Colors.grey[800],
      child: const Icon(
        Icons.campaign_rounded,
        size: 48,
        color: Colors.white54,
      ),
    );
  }
}
