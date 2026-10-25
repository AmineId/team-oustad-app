import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/common/glass.dart';
import '../../core/theme/theme.dart';
import '../../core/models/models.dart';
import '../../core/services/store_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  // Store data
  late final StoreService _storeService;
  late final AuthService _authService;
  List<StoreProduct> _products = [];
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();

    // Services
    _storeService = StoreService(ApiService.fromEnv());
    _authService = AuthService(ApiService.fromEnv());

    // Animation de pulsation pour le badge
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animation de rotation lente pour les éléments décoratifs
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Animation de flottement pour l'icône principale
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Charger les produits
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final token = await _authService.loadToken();
      _storeService.setToken(token);
      final products = await _storeService.getAvailableProducts();
      
      debugPrint('🛒 Store loaded ${products.length} products');
      for (var product in products) {
        debugPrint('🛒 Product: ${product.name}');
        debugPrint('🛒   imageUrl: ${product.imageUrl}');
        debugPrint('🛒   imageUrls.length: ${product.imageUrls.length}');
        debugPrint('🛒   hasImages: ${product.hasImages}');
      }
      
      if (mounted) {
        setState(() {
          _products = products;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading products: $e');
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    // Si on charge les produits, afficher un loading
    if (_isLoadingProducts) {
      return Scaffold(
        extendBodyBehindAppBar: glassExtendsBody,
        appBar: glassAppBar(context, title: const Text('Boutique')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si on a des produits, les afficher
    if (_products.isNotEmpty) {
      return Scaffold(
        extendBodyBehindAppBar: glassExtendsBody,
        appBar: glassAppBar(context, title: const Text('Boutique')),
        body: RefreshIndicator(
          onRefresh: _loadProducts,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + (glassExtendsBody ? kToolbarHeight : 0) + 16, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: _products.map((product) {
                    return SizedBox(
                      width: double.infinity,
                      child: _buildProductCard(product, isDark),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Sinon, afficher l'animation Coming Soon
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkBackground,
                    AppColors.darkSurface,
                    AppColors.primary.withValues(alpha: 0.1),
                  ]
                : [
                    AppColors.lightBackground,
                    AppColors.lightSurface,
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Éléments décoratifs flottants
              ...List.generate(
                6,
                (index) => _buildFloatingElement(index, size),
              ),

              // Contenu principal
              Column(
                children: [
                  // Header avec bouton retour
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Boutique',
                          style: AppTextStyles.h2.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contenu centré
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Icône animée principale avec flottement
                              AnimatedBuilder(
                                animation: _floatAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, _floatAnimation.value),
                                    child: child,
                                  );
                                },
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        context.palette.primaryFill,
                                        AppColors.primaryLight,
                                        AppColors.primaryDark,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 30,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    size: 80,
                                    color: context.palette.onPrimary,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 48),

                              // Badge "Coming Soon" animé avec pulsation
                              ScaleTransition(
                                scale: _pulseAnimation,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        context.palette.primaryFill,
                                        AppColors.primaryLight,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(50),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.rocket_launch_rounded,
                                        color: context.palette.onPrimary,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Coming Soon',
                                        style: AppTextStyles.h3.copyWith(
                                          color: context.palette.onPrimary,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Description
                              Text(
                                'Bientôt disponible',
                                style: AppTextStyles.h2.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 16),

                              Text(
                                'Notre boutique arrive avec des produits exclusifs, des équipements de sport premium et des offres spéciales pour nos membres.',
                                style: AppTextStyles.body1.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 48),

                              // Features à venir
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 500),
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _buildFeatureChip(
                                      Icons.shopping_bag_rounded,
                                      'Équipements',
                                      isDark,
                                    ),
                                    _buildFeatureChip(
                                      Icons.local_offer_rounded,
                                      'Offres exclusives',
                                      isDark,
                                    ),
                                    _buildFeatureChip(
                                      Icons.card_giftcard_rounded,
                                      'Récompenses',
                                      isDark,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingElement(int index, Size size) {
    final positions = [
      Offset(size.width * 0.1, size.height * 0.15),
      Offset(size.width * 0.85, size.height * 0.1),
      Offset(size.width * 0.05, size.height * 0.65),
      Offset(size.width * 0.9, size.height * 0.55),
      Offset(size.width * 0.15, size.height * 0.85),
      Offset(size.width * 0.75, size.height * 0.8),
    ];

    final sizes = [40.0, 30.0, 50.0, 35.0, 25.0, 45.0];
    final icons = [
      Icons.fitness_center,
      Icons.shopping_cart,
      Icons.star,
      Icons.favorite,
      Icons.sports_gymnastics,
      Icons.emoji_events,
    ];

    return Positioned(
      left: positions[index].dx,
      top: positions[index].dy,
      child: AnimatedBuilder(
        animation: _rotateController,
        builder: (context, child) {
          return Transform.rotate(
            angle:
                _rotateController.value * 2 * math.pi * (index.isEven ? 1 : -1),
            child: child,
          );
        },
        child: Opacity(
          opacity: 0.15,
          child: Icon(
            icons[index],
            size: sizes[index],
            color: context.palette.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: context.palette.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(StoreProduct product, bool isDark) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'fr_FR', symbol: 'MAD');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: InkWell(
        onTap: () => _showProductDetail(product, isDark),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carousel d'images
              if (product.imageUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageCarousel(product),
                )
              else if (product.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildProductImage(product),
                ),
              const SizedBox(height: 12),

              // Nom du produit
              Text(
                product.name,
                style: AppTextStyles.h3.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),

              // Description
              if (product.description != null &&
                  product.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  product.description!,
                  style: AppTextStyles.body2.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Prix et stock
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currencyFormatter.format(product.price),
                    style: AppTextStyles.h2.copyWith(
                      color: context.palette.primary,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: product.availableStock > 0
                          ? AppColors.success.withValues(alpha: 0.2)
                          : AppColors.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.availableStock > 0
                          ? 'Stock: ${product.availableStock}'
                          : 'Rupture',
                      style: AppTextStyles.caption.copyWith(
                        color: product.availableStock > 0
                            ? context.palette.success
                            : context.palette.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(StoreProduct product) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: product.imageUrls.length,
        itemBuilder: (context, index) {
          final imageUrl = product.imageUrls[index];
          // Accepter data:image et data:application/octet-stream
          if (imageUrl.startsWith('data:')) {
            try {
              String base64String = imageUrl.split(',').last;
              final bytes = base64Decode(base64String);
              return Image.memory(
                bytes,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return _buildProductImageFallback();
                },
              );
            } catch (e) {
              return _buildProductImageFallback();
            }
          } else {
            return Image.network(
              imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return _buildProductImageFallback();
              },
            );
          }
        },
      ),
    );
  }

  void _showProductDetail(StoreProduct product, bool isDark) {
    final currencyFormatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'MAD');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkTextSecondary.withValues(alpha: 0.3)
                    : AppColors.lightTextSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carousel d'images
                    if (product.imageUrls.isNotEmpty)
                    // Carousel d'images
                    if (product.imageUrls.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 300,
                          child: PageView.builder(
                            itemCount: product.imageUrls.length,
                            itemBuilder: (context, index) {
                              final imageUrl = product.imageUrls[index];
                              // Accepter data:image et data:application/octet-stream
                              if (imageUrl.startsWith('data:')) {
                                try {
                                  String base64String = imageUrl.split(',').last;
                                  final bytes = base64Decode(base64String);
                                  return Image.memory(
                                    bytes,
                                    height: 300,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                  );
                                } catch (e) {
                                  return _buildProductImageFallback();
                                }
                              } else {
                                return Image.network(
                                  imageUrl,
                                  height: 300,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildProductImageFallback();
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      )
                    else if (product.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildProductImage(product),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Nom
                    Text(
                      product.name,
                      style: AppTextStyles.h2.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Catégorie
                    if (product.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.category!,
                          style: AppTextStyles.caption.copyWith(
                            color: context.palette.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Prix
                    Text(
                      currencyFormatter.format(product.price),
                      style: AppTextStyles.h1.copyWith(
                        color: context.palette.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Stock
                    Row(
                      children: [
                        Icon(
                          product.availableStock > 0
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 20,
                          color: product.availableStock > 0
                              ? context.palette.success
                              : context.palette.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          product.availableStock > 0
                              ? 'En stock (${product.availableStock} disponibles)'
                              : 'Rupture de stock',
                          style: AppTextStyles.body2.copyWith(
                            color: product.availableStock > 0
                                ? context.palette.success
                                : context.palette.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    
                    if (product.description != null &&
                        product.description!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Description',
                        style: AppTextStyles.h3.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description!,
                        style: AppTextStyles.body1.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Bouton réserver
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: product.availableStock > 0
                            ? () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Fonctionnalité de réservation bientôt disponible'),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.palette.primaryFill,
                          foregroundColor: context.palette.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          product.availableStock > 0
                              ? 'Réserver'
                              : 'Indisponible',
                          style: AppTextStyles.h3.copyWith(
                            color: product.availableStock > 0
                                ? context.palette.onPrimary
                                : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(StoreProduct product) {
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      // Vérifier si c'est une image base64 (data:image ou data:application/octet-stream)
      if (product.imageUrl!.startsWith('data:')) {
        try {
          String base64String = product.imageUrl!.split(',').last;
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildProductImageFallback();
            },
          );
        } catch (e) {
          return _buildProductImageFallback();
        }
      } else {
        // Image URL normale
        return Image.network(
          product.imageUrl!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildProductImageFallback();
          },
        );
      }
    }
    return _buildProductImageFallback();
  }

  Widget _buildProductImageFallback() {
    return Container(
      height: 200,
      width: double.infinity,
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 64,
        color: AppColors.primary.withValues(alpha: 0.4),
      ),
    );
  }
}
