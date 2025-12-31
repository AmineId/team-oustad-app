import 'dart:async';
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
///   height: 180,
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

  const BannerCarousel({
    super.key,
    this.height = 180,
    this.autoScrollDuration = const Duration(seconds: 5),
    this.autoScroll = true,
    this.onBannerTap,
    this.margin,
    this.borderRadius,
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
      final banners = await _bannerService.getActiveBanners();
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
    // Track click
    await _bannerService.trackClick(banner.id);

    // Custom callback
    if (widget.onBannerTap != null) {
      widget.onBannerTap!(banner);
      return;
    }

    // Default action handling
    if (banner.actionUrl != null && banner.actionUrl!.isNotEmpty) {
      if (banner.isExternalUrl) {
        final url = Uri.parse(banner.actionUrl!);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } else {
        if (mounted) {
          Navigator.pushNamed(context, banner.actionUrl!);
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

  @override
  Widget build(BuildContext context) {
    final style = banner.style;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(16);

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: height ?? 180,
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
                  // Background image
                  Positioned.fill(
                    child: Image.network(
                      banner.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.image, size: 64, color: Colors.white54),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[800],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Custom gradient overlay
                  if (style != null && style.gradientStart != null && style.gradientEnd != null)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              style.gradientStart!.withValues(alpha: style.overlayOpacity),
                              style.gradientEnd!.withValues(alpha: style.overlayOpacity),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    // Default gradient
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
                  
                  // Content
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            banner.title,
                            style: TextStyle(
                              color: style?.textColor ?? Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              shadows: const [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (banner.description != null && banner.description!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              banner.description!,
                              style: TextStyle(
                                color: (style?.textColor ?? Colors.white).withValues(alpha: 0.9),
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
                        ],
                      ),
                    ),
                  ),
                  
                  // Arrow indicator if clickable
                  if (banner.actionUrl != null && banner.actionUrl!.isNotEmpty)
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
      ),
    );
  }
}
