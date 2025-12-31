import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

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

  @override
  void initState() {
    super.initState();

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
                                      AppColors.primary,
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
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  size: 80,
                                  color: Colors.white,
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
                                      AppColors.primary,
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
                                    const Icon(
                                      Icons.rocket_launch_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Coming Soon',
                                      style: AppTextStyles.h3.copyWith(
                                        color: Colors.white,
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
                            Wrap(
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
                          ],
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
            color: AppColors.primary,
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
          Icon(icon, size: 18, color: AppColors.primary),
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
}
