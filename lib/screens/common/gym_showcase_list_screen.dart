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
    .instance
    .platformDispatcher
    .accessibilityFeatures
    .disableAnimations;

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
                      scrollController: _scrollController,
                      onDiscoverTap: _scrollToContent,
                    ),
                  ),
                  const SliverToBoxAdapter(child: _MarqueeBand()),
                  const SliverToBoxAdapter(child: _CategoryTiles()),
                  SliverToBoxAdapter(
                    child: KeyedSubtree(
                      key: _contentKey,
                      child: _buildContent(context),
                    ),
                  ),
                  const SliverToBoxAdapter(child: _FeatureShowcase()),
                  const SliverToBoxAdapter(child: _TestimonialsSection()),
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
      return RevealOnVisible(
        child: _buildMessage(
          icon: Icons.wifi_off_rounded,
          title: 'Connexion impossible',
          message: 'Impossible de charger les salles pour le moment.',
          onRetry: _loadGyms,
        ),
      );
    }
    if (_gyms.isEmpty) {
      return RevealOnVisible(
        child: _buildMessage(
          icon: Icons.fitness_center_rounded,
          title: 'Bientôt disponible',
          message: 'Aucune salle à afficher pour le moment.',
        ),
      );
    }

    return ResponsiveContainer(
      maxWidth: 1200,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RevealOnVisible(child: _SectionHeader()),
            const SizedBox(height: 28),
            ResponsiveGrid(
              spacing: 20,
              runSpacing: 20,
              children: [
                for (final gym in _gyms)
                  RevealOnVisible(child: _GymShowcaseCard(gym: gym)),
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
            style: GoogleFonts.anton(
              fontSize: 22,
              color: Colors.white,
              letterSpacing: 0.5,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    style: GoogleFonts.anton(
                      fontSize: 15,
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
  final ScrollController scrollController;
  final VoidCallback onDiscoverTap;

  const _ShowcaseHero({
    required this.glowController,
    required this.scrollController,
    required this.onDiscoverTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final isTablet = width >= 600;
    final height = isDesktop ? 560.0 : (isTablet ? 500.0 : 480.0);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.darkBackground),
            AnimatedBuilder(
              animation: Listenable.merge([glowController, scrollController]),
              builder: (context, _) {
                final t = glowController.value;
                final parallax = scrollController.hasClients
                    ? scrollController.offset * 0.35
                    : 0.0;
                return Stack(
                  children: [
                    Positioned(
                      top: -140 + 36 * t + parallax,
                      left: -120 + 50 * t,
                      child: _glowBlob(AppColors.primary, 420),
                    ),
                    Positioned(
                      bottom: -160 - 24 * t - parallax,
                      right: -140 - 36 * t,
                      child: _glowBlob(AppColors.primaryDark, 480),
                    ),
                    Positioned(
                      right: -70,
                      bottom: -30 - parallax * 0.6,
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
                  ],
                );
              },
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
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 24),
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

/// Bandeau défilant en continu (contenu dupliqué une fois, la boucle se fait
/// exactement à la largeur d'une copie — pas de saut visible). Pur effet de
/// marque : pas d'info exclusive, donc pas de lecteur d'écran dédié requis
/// au-delà du contenu déjà annoncé par les cartes.
class _MarqueeBand extends StatefulWidget {
  const _MarqueeBand();

  @override
  State<_MarqueeBand> createState() => _MarqueeBandState();
}

class _MarqueeBandState extends State<_MarqueeBand>
    with SingleTickerProviderStateMixin {
  static const _words = [
    'MUSCULATION',
    'CROSSFIT',
    'COACHING',
    'CARDIO',
    'NUTRITION',
    'COMMUNAUTÉ',
  ];
  static const _speedPxPerSec = 46.0;

  final _scrollController = ScrollController();
  Ticker? _ticker;
  Duration? _lastElapsed;

  @override
  void initState() {
    super.initState();
    // Bandeau continu à faible amplitude : on le garde même en mode
    // "réduire les animations" (contrairement aux autres animations de
    // cette page), ce n'est ni large ni parallax, donc pas concerné par
    // les risques que ce réglage cible.
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) {
      _lastElapsed = elapsed;
      return;
    }
    final dtSeconds = _lastElapsed == null
        ? 0.0
        : (elapsed - _lastElapsed!).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    var next = _scrollController.offset + _speedPxPerSec * dtSeconds;
    if (next >= max) next -= max;
    _scrollController.jumpTo(next);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final block = Row(
      mainAxisSize: MainAxisSize.min,
      children: [for (final w in _words) _wordChip(w)],
    );

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(mainAxisSize: MainAxisSize.min, children: [block, block]),
      ),
    );
  }

  Widget _wordChip(String w) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            w,
            style: GoogleFonts.anton(
              fontSize: 21,
              color: AppColors.darkBackground,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 16),
          const Icon(
            Icons.fitness_center_rounded,
            size: 16,
            color: AppColors.darkBackground,
          ),
        ],
      ),
    );
  }
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

/// "TEAM" (police Vlavour, légèrement incliné) et "OUSTAD" (Roboto Black)
/// sur une seule ligne. FittedBox garantit que ça tient sur une ligne même
/// sur petit écran (réduction proportionnelle plutôt que retour à la ligne).
class _Wordmark extends StatelessWidget {
  final bool isDesktop;

  const _Wordmark({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final size = isDesktop ? 72.0 : 46.0;

    final oustadStyle = GoogleFonts.roboto(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      letterSpacing: 1,
    );

    final teamStyle = TextStyle(
      fontFamily: 'Vlavour',
      fontSize: size * 1.15,
      color: AppColors.primary,
      shadows: [
        Shadow(
          color: AppColors.primary.withValues(alpha: 0.55),
          blurRadius: 28,
        ),
      ],
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.rotate(angle: -0.08, child: Text('TEAM', style: teamStyle)),
          SizedBox(width: size * 0.22),
          Text('OUSTAD', style: oustadStyle),
        ],
      ),
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
          style: GoogleFonts.anton(fontSize: 36, color: Colors.white),
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
              builder: (context) => GymShowcaseDetailScreen(slugOrId: slugOrId),
            ),
          );
        },
        child: Semantics(
          button: true,
          label: '$name${address.isNotEmpty ? ', $address' : ''}',
          child: AnimatedRotation(
            turns: _hovered ? -0.006 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: AnimatedScale(
              scale: _hovered ? 1.03 : 1.0,
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
                            style: GoogleFonts.anton(
                              fontSize: 23,
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
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
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

class _CategoryTiles extends StatelessWidget {
  const _CategoryTiles();

  static const _categories = [
    (label: 'Musculation', icon: Icons.fitness_center_rounded),
    (label: 'CrossFit', icon: Icons.whatshot_rounded),
    (label: 'Coaching', icon: Icons.groups_rounded),
    (label: 'Cardio', icon: Icons.directions_run_rounded),
    (label: 'Nutrition', icon: Icons.restaurant_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      maxWidth: 1200,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
        child: RevealOnVisible(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              for (final c in _categories)
                _CategoryTile(label: c.label, icon: c.icon),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final String label;
  final IconData icon;

  const _CategoryTile({required this.label, required this.icon});

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: Container(
          width: 128,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.08),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(
                    alpha: _hovered ? 0.22 : 0.12,
                  ),
                ),
                child: Icon(widget.icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.anton(
                  fontSize: 13,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureShowcase extends StatelessWidget {
  const _FeatureShowcase();

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      maxWidth: 1200,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FeatureBlock(
              eyebrow: 'EXPÉRIENCE',
              title: 'Du matériel qui tient ses promesses',
              body:
                  'Chaque salle est découpée en zones claires — musculation, '
                  'cardio, fonctionnel, récupération — avec du matériel '
                  'entretenu et contrôlé chaque semaine, jamais entassé.',
              points: const [
                'Zones dédiées, jamais de queue aux machines clés',
                'Contrôle et entretien hebdomadaire du matériel',
                'Espace étirements et récupération à part',
              ],
              icon: Icons.fitness_center_rounded,
              tag: 'STUDIO MUSCULATION',
              reverse: false,
            ),
            const SizedBox(height: 56),
            _FeatureBlock(
              eyebrow: 'COMMUNAUTÉ',
              title: 'Une team, pas juste une salle',
              body:
                  'On connaît les prénoms, on suit les progrès, on célèbre '
                  'les paliers. Les coachs sont présents sur le plateau aux '
                  'heures de pointe, pas planqués dans un bureau.',
              points: const [
                'Coachs présents sur le plateau, pas qu\'au bureau',
                'Suivi de progression personnalisé',
                'Communauté active, événements réguliers',
              ],
              icon: Icons.groups_rounded,
              tag: 'ESPRIT TEAM',
              reverse: true,
            ),
            const SizedBox(height: 56),
            _FeatureBlock(
              eyebrow: 'ACCOMPAGNEMENT',
              title: 'Des objectifs, un plan',
              body:
                  'Perte de poids, prise de masse, remise en forme : un '
                  'programme ajusté à ton rythme, revu avec ton coach au '
                  'fil des séances.',
              points: const [
                'Bilan initial et objectifs définis ensemble',
                'Programme ajusté toutes les 4 semaines',
                'Suivi dans l\'app, entre les séances',
              ],
              icon: Icons.track_changes_rounded,
              tag: 'COACHING',
              reverse: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureBlock extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;
  final List<String> points;
  final IconData icon;
  final String tag;
  final bool reverse;

  const _FeatureBlock({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.points,
    required this.icon,
    required this.tag,
    required this.reverse,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 860;

    final image = RevealOnVisible(
      beginOffset: Offset(reverse ? 0.06 : -0.06, 0),
      child: _FeatureImage(icon: icon, tag: tag),
    );
    final copy = RevealOnVisible(
      beginOffset: Offset(reverse ? -0.06 : 0.06, 0),
      child: _FeatureCopy(
        eyebrow: eyebrow,
        title: title,
        body: body,
        points: points,
      ),
    );

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [image, const SizedBox(height: 28), copy],
      );
    }

    final children = reverse
        ? [
            Expanded(child: copy),
            const SizedBox(width: 56),
            Expanded(child: image),
          ]
        : [
            Expanded(child: image),
            const SizedBox(width: 56),
            Expanded(child: copy),
          ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
}

class _FeatureImage extends StatelessWidget {
  final IconData icon;
  final String tag;

  const _FeatureImage({required this.icon, required this.tag});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: const Border(
            left: BorderSide(color: AppColors.primary, width: 5),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.darkElevated,
              AppColors.darkCard,
              AppColors.primaryDark.withValues(alpha: 0.5),
            ],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Center(
              child: Icon(
                icon,
                size: 64,
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            Positioned(
              left: 18,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkBackground.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.barlow(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCopy extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;
  final List<String> points;

  const _FeatureCopy({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          eyebrow,
          style: GoogleFonts.barlow(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: GoogleFonts.anton(
            fontSize: 28,
            color: Colors.white,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          body,
          style: GoogleFonts.barlow(
            fontSize: 14.5,
            height: 1.6,
            color: AppColors.darkTextSecondary,
          ),
        ),
        const SizedBox(height: 18),
        for (final p in points)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2, right: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: Text(
                    p,
                    style: GoogleFonts.barlow(
                      fontSize: 13.5,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection();

  static const _testimonials = [
    (
      name: 'Sarah M.',
      meta: 'Membre depuis 8 mois',
      quote:
          'Les coachs corrigent la posture sans qu\'on demande. Ambiance '
          'sérieuse, jamais intimidante.',
    ),
    (
      name: 'Yanis B.',
      meta: 'Membre depuis 1 an',
      quote:
          'Salle ouverte tard, c\'est ce qui me permet de tenir le rythme '
          'avec le travail. Jamais bondé après 20h.',
    ),
    (
      name: 'Léa D.',
      meta: 'Membre depuis 5 mois',
      quote:
          'Mon programme a été revu trois fois en six mois, toujours selon '
          'mes vraies progressions. Ça change tout.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      maxWidth: 1200,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RevealOnVisible(
              child: Column(
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
                    'LA TEAM PARLE',
                    style: GoogleFonts.barlow(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ce qu\'en disent les membres',
                    style: GoogleFonts.anton(fontSize: 32, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            ResponsiveGrid(
              spacing: 20,
              runSpacing: 20,
              children: [
                for (final t in _testimonials)
                  RevealOnVisible(
                    child: _TestimonialCard(
                      name: t.name,
                      meta: t.meta,
                      quote: t.quote,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String name;
  final String meta;
  final String quote;

  const _TestimonialCard({
    required this.name,
    required this.meta,
    required this.quote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(
              5,
              (_) => const Icon(
                Icons.star_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '"$quote"',
            style: GoogleFonts.barlow(
              fontSize: 14,
              height: 1.55,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name[0],
                    style: GoogleFonts.anton(
                      fontSize: 15,
                      color: AppColors.darkBackground,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.barlow(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      meta,
                      style: GoogleFonts.barlow(
                        fontSize: 11.5,
                        color: AppColors.darkTextTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
            style: GoogleFonts.anton(
              fontSize: 16,
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
