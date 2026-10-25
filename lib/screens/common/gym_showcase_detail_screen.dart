import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/models.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/banner_service.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';
import '../admin/showcase_editor_screen.dart';

bool get _reduceMotion => SchedulerBinding
    .instance
    .platformDispatcher
    .accessibilityFeatures
    .disableAnimations;

/// Fiche détaillée d'une salle sur la page vitrine publique. Même habillage
/// "brand" sombre + doré que [GymShowcaseListScreen], fixé indépendamment du
/// thème clair/sombre de l'app.
class GymShowcaseDetailScreen extends StatefulWidget {
  final String slugOrId;

  const GymShowcaseDetailScreen({super.key, required this.slugOrId});

  @override
  State<GymShowcaseDetailScreen> createState() =>
      _GymShowcaseDetailScreenState();
}

class _GymShowcaseDetailScreenState extends State<GymShowcaseDetailScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  late final AuthService _authService = AuthService(_apiService);
  Map<String, dynamic>? _gym;
  List<BannerModel> _banners = [];
  List<dynamic> _subscriptions = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _canEdit = false; // owner ou admin autorisé

  @override
  void initState() {
    super.initState();
    _loadGym();
    _checkEditPermission();
  }

  Future<void> _checkEditPermission() async {
    final canEdit = await _authService.hasAdminAccess();
    if (!mounted) return;
    setState(() => _canEdit = canEdit);
  }

  Future<void> _loadGym() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final gym = await _apiService.getPublicGym(widget.slugOrId);
    if (!mounted) return;
    setState(() {
      _gym = gym;
      _hasError = gym == null;
      _isLoading = false;
    });
    final rawId = gym?['id'];
    if (rawId != null) {
      final gymId = rawId is int ? rawId : int.tryParse(rawId.toString());
      if (gymId != null) {
        _loadBanners(gymId);
        _loadSubscriptions();
      }
    }
  }

  Future<void> _loadBanners(int gymId) async {
    final banners = await BannerService(
      _apiService,
    ).getAllBanners(gymId: gymId, activeOnly: true);
    if (!mounted) return;
    setState(() => _banners = banners);
  }

  Future<void> _loadSubscriptions() async {
    final subs = await _apiService.getSubscriptionTypes();
    if (!mounted) return;
    setState(() => _subscriptions = subs ?? []);
  }

  Future<void> _share(String name, String slugOrId) async {
    final text =
        'Découvrez $name sur Team Oustad : https://team-oustad.com/gyms/$slugOrId';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Lien copié dans le presse-papier'),
        backgroundColor: AppColors.darkCard,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _whatsApp(String number) async {
    final clean = number.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openMaps(String address) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri);
  }

  String _dayName(int dayOfWeek) {
    const days = [
      'Dimanche',
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
    ];
    return days[dayOfWeek % 7];
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'owner':
        return 'Gérant';
      case 'admin':
        return 'Coach';
      default:
        return 'Équipe';
    }
  }

  /// Rendu d'une section de la page, précédée de son espacement. Liste vide
  /// si la section n'a rien à afficher (pas d'adresse, pas d'offres…).
  List<Widget> _buildSection(
    ShowcaseSection section, {
    required String? description,
    required String address,
    required String? phone,
    required String? whatsappNumber,
    required List<Map<String, dynamic>> openingHours,
    required List<Map<String, dynamic>> team,
  }) {
    Widget? child;
    switch (section.type) {
      case ShowcaseSectionType.gymAbout:
        if (description != null && description.trim().isNotEmpty) {
          child = ShowcaseMarkdown(data: description);
        }
      case ShowcaseSectionType.gymPromos:
        if (_banners.isNotEmpty) child = _PromosSection(banners: _banners);
      case ShowcaseSectionType.gymInfo:
        final hasPhone = phone != null && phone.isNotEmpty;
        if (address.isEmpty && !hasPhone) break;
        child = Column(
          children: [
            _ActionsCard(
              address: address,
              phone: phone,
              whatsappNumber: whatsappNumber,
              onMap: address.isNotEmpty ? () => _openMaps(address) : null,
              onCall: hasPhone ? () => _call(phone) : null,
              onWhatsApp: (whatsappNumber != null && whatsappNumber.isNotEmpty)
                  ? () => _whatsApp(whatsappNumber)
                  : null,
            ),
            if (address.isNotEmpty) ...[
              const SizedBox(height: 16),
              GymMapEmbed(address: address),
            ],
          ],
        );
      case ShowcaseSectionType.gymHours:
        if (openingHours.isNotEmpty) {
          child = _OpeningHoursCard(hours: openingHours, dayName: _dayName);
        }
      case ShowcaseSectionType.gymTeam:
        if (team.isNotEmpty) {
          child = _TeamSection(team: team, roleLabel: _roleLabel);
        }
      case ShowcaseSectionType.gymSubscriptions:
        if (_subscriptions.isNotEmpty) {
          child = _SubscriptionsSection(subscriptions: _subscriptions);
        }
      default:
        return [
          const SizedBox(height: 28),
          ShowcaseContentSection(
            key: ValueKey(section.id),
            section: section,
            standalone: false,
          ),
        ];
    }
    if (child == null) return const [];
    return [const SizedBox(height: 28), RevealOnVisible(child: child)];
  }

  @override
  Widget build(BuildContext context) {
    final gymId = _gym != null
        ? (_gym!['id'] is int
              ? _gym!['id'] as int
              : int.tryParse(_gym!['id'].toString()))
        : null;
    final gymName = _gym?['name'] as String? ?? 'Salle';

    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: _buildBody(context),
        floatingActionButton: (_canEdit && gymId != null)
            ? FloatingActionButton.extended(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShowcaseEditorScreen.gym(
                        gymId: gymId,
                        gymName: gymName,
                      ),
                    ),
                  );
                  _loadGym(); // rafraîchit après édition
                },
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Modifier'),
              )
            : null,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return Stack(
        children: [
          const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          _FloatingBackButton(),
        ],
      );
    }
    if (_hasError || _gym == null) {
      return Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Cette salle n\'est pas disponible.',
                style: TextStyle(color: AppColors.darkTextTertiary),
              ),
            ),
          ),
          _FloatingBackButton(),
        ],
      );
    }

    final gym = _gym!;
    final name = gym['name'] as String? ?? 'Salle';
    final address = gym['address'] as String? ?? '';
    final phone = gym['phone'] as String?;
    final whatsappNumber =
        (gym['whatsappNumber'] as String?)?.isNotEmpty == true
        ? gym['whatsappNumber'] as String
        : phone;
    final gymSlug = (gym['slug'] as String?) ?? gym['id'].toString();
    final description = gym['description'] as String?;
    // Sections CMS (ShowcaseEditorScreen) ; défaut = ordre historique.
    final page = ShowcasePage.fromJson(
      ShowcasePageKind.gym,
      gym['showcase'] as Map<String, dynamic>?,
    );
    final memberCountDisplay = gym['memberCountDisplay'] as String?;
    final photos = ((gym['photos'] as List<dynamic>?) ?? [])
        .map((p) => p as Map<String, dynamic>)
        .toList();
    final openingHours =
        ((gym['openingHours'] as List<dynamic>?) ?? [])
            .map((h) => h as Map<String, dynamic>)
            .toList()
          ..sort(
            (a, b) => (a['dayOfWeek'] as int).compareTo(b['dayOfWeek'] as int),
          );
    final team = ((gym['team'] as List<dynamic>?) ?? [])
        .map((t) => t as Map<String, dynamic>)
        .toList();

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: isDesktop ? 460 : 380,
          backgroundColor: AppColors.darkSurface,
          elevation: 0,
          leading: const Padding(
            padding: EdgeInsets.all(8),
            child: _FloatingBackButton(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
              child: SafeArea(
                bottom: false,
                child: LiquidGlass(
                  borderRadius: BorderRadius.circular(999),
                  child: IconButton(
                    icon: const Icon(Icons.share_rounded, color: Colors.white),
                    tooltip: 'Partager',
                    onPressed: () => _share(name, gymSlug),
                  ),
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Stack(
              fit: StackFit.expand,
              children: [
                _PhotoCarousel(photos: photos),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black87,
                      ],
                      stops: [0, 0.45, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: RevealOnLoad(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (memberCountDisplay != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _MemberPill(display: memberCountDisplay),
                          ),
                        Text(
                          name,
                          style: GoogleFonts.anton(
                            fontSize: isDesktop ? 50 : 36,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ResponsiveContainer(
            maxWidth: 900,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final section in page.visibleSections)
                    ..._buildSection(
                      section,
                      description: description,
                      address: address,
                      phone: phone,
                      whatsappNumber: whatsappNumber,
                      openingHours: openingHours,
                      team: team,
                    ),
                  const SizedBox(height: 28),
                  RevealOnVisible(
                    child: Center(
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'TEAM OUSTAD',
                            style: GoogleFonts.anton(
                              fontSize: 14,
                              color: AppColors.darkTextTertiary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

int? _parseMinutes(String? hhmm) {
  if (hhmm == null) return null;
  final parts = hhmm.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

bool? _isOpenNow(Map<String, dynamic>? todayHours) {
  if (todayHours == null) return null;
  if (todayHours['isClosed'] == true) return false;
  final open = _parseMinutes(todayHours['openTime'] as String?);
  final close = _parseMinutes(todayHours['closeTime'] as String?);
  if (open == null || close == null) return null;
  final now = TimeOfDay.now();
  final nowMinutes = now.hour * 60 + now.minute;
  if (close > open) {
    return nowMinutes >= open && nowMinutes < close;
  }
  // Plage à cheval sur minuit (ex: 22:00 - 02:00).
  return nowMinutes >= open || nowMinutes < close;
}

class _PromosSection extends StatefulWidget {
  final List<BannerModel> banners;

  const _PromosSection({required this.banners});

  @override
  State<_PromosSection> createState() => _PromosSectionState();
}

class _PromosSectionState extends State<_PromosSection> {
  late final PageController _pageController;
  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    if (!_reduceMotion && widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        final next = (_page + 1) % widget.banners.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'OFFRES & ÉVÉNEMENTS',
              style: GoogleFonts.barlow(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) => BannerCard(
              banner: widget.banners[index],
              height: 160,
              margin: const EdgeInsets.only(right: 10),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                widget.banners.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.primary : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FloatingBackButton extends StatelessWidget {
  const _FloatingBackButton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: LiquidGlass(
        borderRadius: BorderRadius.circular(999),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}

class _PhotoCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> photos;

  const _PhotoCarousel({required this.photos});

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return ColoredBox(
        color: AppColors.darkElevated,
        child: Center(
          child: Icon(
            Icons.fitness_center_rounded,
            color: AppColors.primary.withValues(alpha: 0.5),
            size: 64,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.photos.length,
          onPageChanged: (page) => setState(() => _page = page),
          itemBuilder: (context, index) {
            final url = widget.photos[index]['url'] as String?;
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _PhotoFullscreenViewer(
                    photos: widget.photos,
                    initialIndex: index,
                  ),
                ),
              ),
              child: Image.network(
                url ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => ColoredBox(
                  color: AppColors.darkElevated,
                  child: const Icon(
                    Icons.broken_image_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.photos.length > 1)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      widget.photos.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: index == _page ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: index == _page
                              ? AppColors.primary
                              : Colors.white38,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MemberPill extends StatelessWidget {
  final String display;

  const _MemberPill({required this.display});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 5),
              Text(
                '$display membres',
                style: GoogleFonts.barlow(
                  fontSize: 12,
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

class _ActionsCard extends StatelessWidget {
  final String address;
  final String? phone;
  final String? whatsappNumber;
  final VoidCallback? onMap;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  const _ActionsCard({
    required this.address,
    required this.phone,
    this.whatsappNumber,
    required this.onMap,
    required this.onCall,
    this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (address.isNotEmpty) _infoLine(Icons.location_on_rounded, address),
          if (phone != null && phone!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoLine(Icons.phone_rounded, phone!),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (onMap != null)
                _GlowButton(
                  icon: Icons.map_rounded,
                  label: 'Itinéraire',
                  onTap: onMap!,
                  filled: true,
                ),
              if (onCall != null)
                _GlowButton(
                  icon: Icons.call_rounded,
                  label: 'Appeler',
                  onTap: onCall!,
                ),
              if (onWhatsApp != null)
                _GlowButton(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  onTap: onWhatsApp!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.barlow(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _GlowButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : AppColors.darkCard,
            borderRadius: BorderRadius.circular(28),
            border: filled
                ? null
                : Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: filled ? AppColors.darkBackground : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.barlow(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: filled ? AppColors.darkBackground : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpeningHoursCard extends StatefulWidget {
  final List<Map<String, dynamic>> hours;
  final String Function(int) dayName;

  const _OpeningHoursCard({required this.hours, required this.dayName});

  @override
  State<_OpeningHoursCard> createState() => _OpeningHoursCardState();
}

class _OpeningHoursCardState extends State<_OpeningHoursCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (_reduceMotion) {
      _pulse.value = 1;
    } else {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String? _nextOpenText(int todayIndex) {
    const dayNames = [
      'dimanche',
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
    ];
    for (var offset = 1; offset <= 7; offset++) {
      final dayIndex = (todayIndex + offset) % 7;
      Map<String, dynamic>? slot;
      for (final h in widget.hours) {
        if (h['dayOfWeek'] == dayIndex) {
          slot = h;
          break;
        }
      }
      if (slot == null || slot['isClosed'] == true) continue;
      final openTime = slot['openTime'] as String?;
      if (openTime == null) continue;
      final label = offset == 1 ? 'Demain' : 'Le ${dayNames[dayIndex]}';
      return 'Ouvre $label à $openTime';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final todayIndex = DateTime.now().weekday % 7;
    Map<String, dynamic>? todayHours;
    for (final h in widget.hours) {
      if (h['dayOfWeek'] == todayIndex) {
        todayHours = h;
        break;
      }
    }
    final openNow = _isOpenNow(todayHours);
    final nextOpen = openNow == false ? _nextOpenText(todayIndex) : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Horaires d\'ouverture',
                  style: GoogleFonts.anton(fontSize: 20, color: Colors.white),
                ),
              ),
              if (openNow != null) _StatusChip(open: openNow, pulse: _pulse),
            ],
          ),
          if (nextOpen != null) ...[
            const SizedBox(height: 6),
            Text(
              nextOpen,
              style: GoogleFonts.barlow(
                fontSize: 12,
                color: AppColors.darkTextTertiary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          ...widget.hours.map((hour) {
            final isToday = hour['dayOfWeek'] == todayIndex;
            final isClosed = hour['isClosed'] == true;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: EdgeInsets.symmetric(
                horizontal: isToday ? 10 : 0,
                vertical: 8,
              ),
              decoration: isToday
                  ? BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    )
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.dayName(hour['dayOfWeek'] as int),
                    style: GoogleFonts.barlow(
                      fontSize: 14,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                      color: isToday
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    isClosed
                        ? 'Fermé'
                        : '${hour['openTime']} - ${hour['closeTime']}',
                    style: GoogleFonts.barlow(
                      fontSize: 14,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                      color: isClosed
                          ? AppColors.errorLight
                          : (isToday
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.7)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool open;
  final Animation<double> pulse;

  const _StatusChip({required this.open, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final color = open ? AppColors.success : AppColors.errorLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulse,
            builder: (context, child) =>
                Opacity(opacity: 0.5 + 0.5 * pulse.value, child: child),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            open ? 'Ouvert maintenant' : 'Fermé',
            style: GoogleFonts.barlow(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamSection extends StatelessWidget {
  final List<Map<String, dynamic>> team;
  final String Function(String?) roleLabel;

  const _TeamSection({required this.team, required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'La team',
          style: GoogleFonts.anton(fontSize: 20, color: Colors.white),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            for (final member in team)
              RevealOnVisible(
                beginOffset: const Offset(0, 0.15),
                child: _TeamMember(member: member, roleLabel: roleLabel),
              ),
          ],
        ),
      ],
    );
  }
}

class _TeamMember extends StatefulWidget {
  final Map<String, dynamic> member;
  final String Function(String?) roleLabel;

  const _TeamMember({required this.member, required this.roleLabel});

  @override
  State<_TeamMember> createState() => _TeamMemberState();
}

class _TeamMemberState extends State<_TeamMember> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.member['photoUrl'] as String?;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: SizedBox(
          width: 100,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(
                      alpha: _hovered ? 0.9 : 0.4,
                    ),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.darkElevated,
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.member['fullName'] as String? ?? '',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.barlow(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              Text(
                widget.roleLabel(widget.member['role'] as String?),
                style: GoogleFonts.barlow(
                  fontSize: 11,
                  color: AppColors.darkTextTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Photo fullscreen viewer ────────────────────────────────────────────────

class _PhotoFullscreenViewer extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final int initialIndex;

  const _PhotoFullscreenViewer({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_PhotoFullscreenViewer> createState() => _PhotoFullscreenViewerState();
}

class _PhotoFullscreenViewerState extends State<_PhotoFullscreenViewer> {
  late final PageController _controller;
  late int _page;

  @override
  void initState() {
    super.initState();
    _page = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              final url = widget.photos[index]['url'] as String?;
              return InteractiveViewer(
                child: Center(
                  child: Image.network(
                    url ?? '',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LiquidGlass(
                    borderRadius: BorderRadius.circular(999),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  if (widget.photos.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_page + 1} / ${widget.photos.length}',
                        style: GoogleFonts.barlow(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Subscriptions section ──────────────────────────────────────────────────

class _SubscriptionsSection extends StatelessWidget {
  final List<dynamic> subscriptions;

  const _SubscriptionsSection({required this.subscriptions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'FORMULES D\'ABONNEMENT',
              style: GoogleFonts.barlow(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < subscriptions.length; i++)
                _SubscriptionCard(
                  sub: subscriptions[i] as Map<String, dynamic>,
                  highlighted: i == 0,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final Map<String, dynamic> sub;
  final bool highlighted;

  const _SubscriptionCard({required this.sub, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final name = sub['name'] as String? ?? '';
    final price = sub['price'];
    final duration =
        sub['durationMonths'] ?? sub['duration'] ?? sub['durationDays'];
    final priceStr = price != null ? '$price€' : '';
    final durationLabel = sub['durationMonths'] != null
        ? '${sub['durationMonths']} mois'
        : (sub['durationDays'] != null ? '${sub['durationDays']} jours' : '');

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.08),
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlighted)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'POPULAIRE',
                style: GoogleFonts.barlow(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: AppColors.darkBackground,
                ),
              ),
            ),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.barlow(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (priceStr.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              priceStr,
              style: GoogleFonts.anton(
                fontSize: 22,
                color: AppColors.primary,
                height: 1.0,
              ),
            ),
          ],
          if (durationLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              durationLabel,
              style: GoogleFonts.barlow(
                fontSize: 12,
                color: AppColors.darkTextTertiary,
              ),
            ),
          ],
          if (duration == null && priceStr.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Voir en salle',
              style: GoogleFonts.barlow(
                fontSize: 12,
                color: AppColors.darkTextTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
