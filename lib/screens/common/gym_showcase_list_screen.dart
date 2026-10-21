import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';
import 'gym_showcase_detail_screen.dart';

bool get _reduceMotion => SchedulerBinding
    .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

/// Page vitrine publique — liste des salles publiées. Build web dédié
/// (team-oustad.com), voir WEB_TARGET dans lib/main.dart. Habillage "brand"
/// volontairement fixé en sombre + doré, indépendant du thème clair/sombre
/// de l'app (c'est une page marketing, pas un écran applicatif).
class GymShowcaseListScreen extends StatefulWidget {
  const GymShowcaseListScreen({super.key});

  @override
  State<GymShowcaseListScreen> createState() => _GymShowcaseListScreenState();
}

class _GymShowcaseListScreenState extends State<GymShowcaseListScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService.fromEnv();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _contentKey = GlobalKey();
  late final AnimationController _glowController;

  List<Map<String, dynamic>> _gyms = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (_reduceMotion) {
      _glowController.value = 1;
    } else {
      _glowController.repeat(reverse: true);
    }
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 32;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    });
    _loadGyms();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGyms() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final gyms = await _apiService.getPublicGyms();
    if (!mounted) return;
    setState(() {
      _gyms = (gyms ?? []).map((g) => g as Map<String, dynamic>).toList();
      _hasError = gyms == null;
      _isLoading = false;
    });
  }

  void _scrollToContent() {
    final ctx = _contentKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Stack(
          children: [
            RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.darkSurface,
              onRefresh: _loadGyms,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _ShowcaseHero(
                      glowController: _glowController,
                      onDiscoverTap: _scrollToContent,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: KeyedSubtree(
                      key: _contentKey,
                      child: _buildContent(context),
                    ),
                  ),
                  const SliverToBoxAdapter(child: _ShowcaseFooter()),
                ],
              ),
            ),
            _TopBar(visible: _scrolled),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 120),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    if (_hasError) {
      return _buildMessage(
        icon: Icons.wifi_off_rounded,
        title: 'Connexion impossible',
        message: 'Impossible de charger les salles pour le moment.',
        onRetry: _loadGyms,
      );
    }
    if (_gyms.isEmpty) {
      return _buildMessage(
        icon: Icons.fitness_center_rounded,
        title: 'Bientôt disponible',
        message: 'Aucune salle à afficher pour le moment.',
      );
    }

    return ResponsiveContainer(
      maxWidth: 1200,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RevealOnLoad(child: _SectionHeader()),
            const SizedBox(height: 28),
            ResponsiveGrid(
              spacing: 20,
              runSpacing: 20,
              children: [
                for (var i = 0; i < _gyms.length; i++)
                  RevealOnLoad(
                    delay: Duration(milliseconds: 60 * i.clamp(0, 8)),
                    child: _GymShowcaseCard(gym: _gyms[i]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.barlowCondensed(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.barlow(
              fontSize: 14,
              color: AppColors.darkTextTertiary,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Barre flottante qui apparaît une fois le hero dépassé (ancrage visuel
/// pendant le scroll, style "liquid glass" déjà utilisé ailleurs dans l'app).
class _TopBar extends StatelessWidget {
  final bool visible;

  const _TopBar({required this.visible});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        child: IgnorePointer(
          ignoring: !visible,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: LiquidGlass(
              borderRadius: BorderRadius.circular(18),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'TEAM OUSTAD',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
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

class _ShowcaseHero extends StatelessWidget {
  final AnimationController glowController;
  final VoidCallback onDiscoverTap;

  const _ShowcaseHero({
    required this.glowController,
    required this.onDiscoverTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final isTablet = width >= 600;
    final height = isDesktop ? 680.0 : (isTablet ? 600.0 : 560.0);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.darkBackground),
            AnimatedBuilder(
              animation: glowController,
              builder: (context, _) {
                final t = glowController.value;
                return Stack(
                  children: [
                    Positioned(
                      top: -140 + 36 * t,
                      left: -120 + 50 * t,
                      child: _glowBlob(AppColors.primary, 420),
                    ),
                    Positioned(
                      bottom: -160 - 24 * t,
                      right: -140 - 36 * t,
                      child: _glowBlob(AppColors.primaryDark, 480),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              right: -70,
              bottom: -30,
              child: Opacity(
                opacity: 0.08,
                child: Transform.rotate(
                  angle: -0.06,
                  child: Image.asset(
                    'assets/images/logo-1-transparent.png',
                    width: isDesktop ? 480 : 320,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 160,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.darkBackground],
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 48 : 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const RevealOnLoad(
                      delay: Duration(milliseconds: 80),
                      child: _Eyebrow(),
                    ),
                    const SizedBox(height: 22),
                    RevealOnLoad(
                      delay: const Duration(milliseconds: 180),
                      child: _Wordmark(isDesktop: isDesktop),
                    ),
                    const SizedBox(height: 18),
                    RevealOnLoad(
                      delay: const Duration(milliseconds: 320),
                      child: Text(
                        'Choisis ta salle. Dépasse tes limites.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.barlow(
                          fontSize: isDesktop ? 20 : 16,
                          color: AppColors.darkTextSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: RevealOnLoad(
                delay: const Duration(milliseconds: 520),
                child: _ScrollCue(onTap: onDiscoverTap),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _glowBlob(Color color, double size) {
  return ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.38),
      ),
    ),
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'VITRINE TEAM OUSTAD',
            style: GoogleFonts.barlow(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  final bool isDesktop;

  const _Wordmark({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final size = isDesktop ? 96.0 : 58.0;
    return Column(
      children: [
        Text(
          'TEAM',
          style: GoogleFonts.barlowCondensed(
            fontSize: size,
            fontWeight: FontWeight.w800,
            height: 0.95,
            color: AppColors.primary,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: AppColors.primary.withValues(alpha: 0.55),
                blurRadius: 40,
              ),
            ],
          ),
        ),
        Text(
          'OUSTAD',
          style: GoogleFonts.barlowCondensed(
            fontSize: size,
            fontWeight: FontWeight.w800,
            height: 0.95,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _ScrollCue extends StatefulWidget {
  final VoidCallback onTap;

  const _ScrollCue({required this.onTap});

  @override
  State<_ScrollCue> createState() => _ScrollCueState();
}

class _ScrollCueState extends State<_ScrollCue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (!_reduceMotion) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Découvrir nos salles',
                  style: GoogleFonts.barlow(
                    fontSize: 12,
                    color: AppColors.darkTextTertiary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, 6 * _controller.value),
                    child: child,
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'NOS ÉTABLISSEMENTS',
          style: GoogleFonts.barlow(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choisis ta salle',
          style: GoogleFonts.barlowCondensed(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _GymShowcaseCard extends StatefulWidget {
  final Map<String, dynamic> gym;

  const _GymShowcaseCard({required this.gym});

  @override
  State<_GymShowcaseCard> createState() => _GymShowcaseCardState();
}

class _GymShowcaseCardState extends State<_GymShowcaseCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final gym = widget.gym;
    final name = gym['name'] as String? ?? 'Salle';
    final address = gym['address'] as String? ?? '';
    final memberCountDisplay = gym['memberCountDisplay'] as String?;
    final coverPhotoUrl = gym['coverPhotoUrl'] as String?;
    final slugOrId = (gym['slug'] as String?) ?? gym['id'].toString();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  GymShowcaseDetailScreen(slugOrId: slugOrId),
            ),
          );
        },
        child: Semantics(
          button: true,
          label: '$name${address.isNotEmpty ? ', $address' : ''}',
          child: AnimatedScale(
            scale: _hovered ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _hovered
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.3),
                    blurRadius: _hovered ? 28 : 14,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: _hovered
                      ? AppColors.primary.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 5,
                    child: coverPhotoUrl != null
                        ? Image.network(
                            coverPhotoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) =>
                                _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.88),
                          ],
                          stops: const [0, 0.4, 1],
                        ),
                      ),
                    ),
                  ),
                  if (memberCountDisplay != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _MemberBadge(display: memberCountDisplay),
                    ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.barlow(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          alignment: Alignment.topLeft,
                          child: _hovered
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Voir la salle',
                                        style: GoogleFonts.barlow(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox(width: double.infinity),
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
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.darkElevated,
      child: Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: AppColors.primary.withValues(alpha: 0.5),
          size: 44,
        ),
      ),
    );
  }
}

class _MemberBadge extends StatelessWidget {
  final String display;

  const _MemberBadge({required this.display});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.people_alt_rounded,
                size: 12,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '$display membres',
                style: GoogleFonts.barlow(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShowcaseFooter extends StatelessWidget {
  const _ShowcaseFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 36,
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 10),
          Text(
            'TEAM OUSTAD',
            style: GoogleFonts.barlowCondensed(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Dépasse tes limites.',
            style: GoogleFonts.barlow(
              fontSize: 12,
              color: AppColors.darkTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
