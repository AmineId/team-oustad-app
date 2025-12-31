import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/services/banner_service.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/theme.dart';
import 'banner_card.dart';
import 'package:url_launcher/url_launcher.dart';

/// Carrousel de bannières avec auto-scroll
class BannerCarousel extends StatefulWidget {
  final int? gymId;
  final BannerType? filterType;
  final double height;
  final Duration autoScrollDuration;
  final bool autoScroll;
  final bool showStatistics;
  final VoidCallback? onBannerTap;

  const BannerCarousel({
    super.key,
    this.gymId,
    this.filterType,
    this.height = 180,
    this.autoScrollDuration = const Duration(seconds: 5),
    this.autoScroll = true,
    this.showStatistics = false,
    this.onBannerTap,
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
  final Set<int> _viewedBanners = {};

  @override
  void initState() {
    super.initState();
    _loadBanners();
    _setupAutoScroll();
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
      final banners = await _bannerService.getActiveBanners(
        type: widget.filterType,
        gymId: widget.gymId,
      );

      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoading = false;
        });

        // Tracker la vue de la première bannière
        if (_banners.isNotEmpty) {
          _trackView(_banners[0].id);
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
    if (!widget.autoScroll) return;

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

  void _trackView(int bannerId) {
    if (_viewedBanners.contains(bannerId)) return;
    
    _viewedBanners.add(bannerId);
    _bannerService.trackView(bannerId);
  }

  Future<void> _handleBannerTap(BannerModel banner) async {
    // Tracker le clic
    await _bannerService.trackClick(banner.id);

    // Exécuter l'action
    switch (banner.action.type) {
      case BannerActionType.navigate:
        if (banner.action.data != null && mounted) {
          // Navigation vers une route
          Navigator.pushNamed(
            context,
            banner.action.data!,
            arguments: banner.action.params,
          );
        }
        break;

      case BannerActionType.externalUrl:
        if (banner.action.data != null) {
          final url = Uri.parse(banner.action.data!);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
        break;

      case BannerActionType.showDetails:
        if (mounted) {
          _showBannerDetails(banner);
        }
        break;

      case BannerActionType.none:
        // Aucune action, mais appeler le callback si fourni
        widget.onBannerTap?.call();
        break;
    }
  }

  void _showBannerDetails(BannerModel banner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    if (banner.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          banner.imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 20),
                    
                    // Titre
                    Text(
                      banner.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Description
                    if (banner.description != null && banner.description!.isNotEmpty)
                      Text(
                        banner.description!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          height: 1.5,
                        ),
                      ),
                    const SizedBox(height: 20),
                    
                    // Dates
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Valable du ${_formatDate(banner.startDate)} au ${_formatDate(banner.endDate)}',
                    ),
                    
                    // Type
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      _getTypeIcon(banner.type),
                      _getTypeName(banner.type),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bouton de fermeture
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getTypeIcon(BannerType type) {
    switch (type) {
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

  String _getTypeName(BannerType type) {
    switch (type) {
      case BannerType.seasonal:
        return 'Bannière saisonnière';
      case BannerType.event:
        return 'Événement';
      case BannerType.promotion:
        return 'Promotion';
      case BannerType.info:
        return 'Information';
      case BannerType.announcement:
        return 'Annonce';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeleton();
    }

    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _trackView(_banners[index].id);
            },
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return BannerCard(
                banner: banner,
                height: widget.height,
                showStatistics: widget.showStatistics,
                onTap: () => _handleBannerTap(banner),
              );
            },
          ),
          
          // Indicateurs de page
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
                          ? AppColors.primary
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

  Widget _buildSkeleton() {
    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }
}
