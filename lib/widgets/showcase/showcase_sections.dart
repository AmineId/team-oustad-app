import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/models.dart';
import '../../core/theme/theme.dart';
import '../common/common_widgets.dart';
import '../responsive/responsive_widgets.dart';

/// Rendu des sections de contenu CMS du site vitrine ([ShowcaseSection]),
/// partagé par la page d'accueil, la fiche salle et l'aperçu de l'éditeur.
/// Habillage "brand" sombre + doré : à afficher sous [AppTheme.darkTheme].
///
/// Les sections intégrées ([ShowcaseSectionType.isBuiltin]) sont rendues par
/// l'écran hôte, qui détient les données correspondantes.
class ShowcaseContentSection extends StatelessWidget {
  final ShowcaseSection section;

  /// Alterne image/texte des blocs "feature" successifs.
  final bool reverse;

  /// true : la section gère sa largeur max et ses marges (page d'accueil).
  /// false : l'hôte fournit déjà le conteneur (fiche salle, aperçu).
  final bool standalone;

  const ShowcaseContentSection({
    super.key,
    required this.section,
    this.reverse = false,
    this.standalone = true,
  });

  @override
  Widget build(BuildContext context) {
    // Le bandeau défilant est pleine largeur, sans conteneur.
    if (section.type == ShowcaseSectionType.marquee) {
      final words = section.strings('words');
      return words.isEmpty
          ? const SizedBox.shrink()
          : MarqueeBand(words: words);
    }
    final content = _buildContent();
    if (content == null) return const SizedBox.shrink();
    if (!standalone) return content;
    return ResponsiveContainer(
      maxWidth: 1200,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, _topSpacing, 20, 16),
        child: content,
      ),
    );
  }

  double get _topSpacing {
    switch (section.type) {
      case ShowcaseSectionType.categories:
        return 36;
      case ShowcaseSectionType.cta:
        return 48;
      default:
        return 64;
    }
  }

  Widget? _buildContent() {
    final s = section;
    switch (s.type) {
      case ShowcaseSectionType.markdown:
        if (s.text('body').isEmpty && s.text('title').isEmpty) return null;
        return RevealOnVisible(
          child: ShowcaseMarkdownCard(
            title: s.text('title'),
            data: s.text('body'),
          ),
        );
      case ShowcaseSectionType.feature:
        return _FeatureBlock(
          eyebrow: s.text('eyebrow'),
          title: s.text('title'),
          body: s.text('body'),
          points: s.strings('points'),
          icon: showcaseIcon(s.data['icon'] as String?),
          tag: s.text('tag'),
          reverse: reverse,
        );
      case ShowcaseSectionType.testimonials:
        final items = s
            .items('items')
            .where((t) => (t['quote'] as String?)?.trim().isNotEmpty == true)
            .toList();
        if (items.isEmpty) return null;
        return _TestimonialsSection(
          eyebrow: s.text('eyebrow'),
          title: s.text('title'),
          items: items,
        );
      case ShowcaseSectionType.categories:
        final items = s
            .items('items')
            .where((c) => (c['label'] as String?)?.trim().isNotEmpty == true)
            .toList();
        if (items.isEmpty) return null;
        return _CategoryTiles(items: items);
      case ShowcaseSectionType.cta:
        if (s.text('text').isEmpty && s.text('eyebrow').isEmpty) return null;
        return _CallToAction(
          eyebrow: s.text('eyebrow'),
          text: s.text('text'),
          buttonLabel: s.text('buttonLabel'),
          url: s.text('url'),
        );
      default:
        return null;
    }
  }
}

/// Contenu saisi dans le CMS : on n'ouvre que des liens web (et, dans le
/// markdown, mailto/tel) — jamais javascript:, data:, file:, intent:…
Uri? _safeUri(String? raw, {bool allowContact = false}) {
  if (raw == null || raw.trim().isEmpty) return null;
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return null;
  const web = {'http', 'https'};
  const contact = {'mailto', 'tel'};
  final scheme = uri.scheme.toLowerCase();
  if (web.contains(scheme) && uri.host.isNotEmpty) return uri;
  if (allowContact && contact.contains(scheme)) return uri;
  return null;
}

/// Barre dorée + sur-titre + titre, en tête des sections de la vitrine.
class ShowcaseSectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;

  const ShowcaseSectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
  });

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
        if (eyebrow.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            eyebrow,
            style: GoogleFonts.barlow(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: AppColors.primary,
            ),
          ),
        ],
        if (title.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.anton(fontSize: 32, color: Colors.white),
          ),
        ],
      ],
    );
  }
}

/// Rendu markdown aux couleurs de la vitrine (pas de HTML brut).
class ShowcaseMarkdown extends StatelessWidget {
  final String data;

  const ShowcaseMarkdown({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final body = GoogleFonts.barlow(
      fontSize: 15,
      height: 1.6,
      color: Colors.white.withValues(alpha: 0.85),
    );
    return MarkdownBody(
      data: data,
      onTapLink: (text, href, title) {
        final uri = _safeUri(href, allowContact: true);
        if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: body,
        listBullet: body,
        strong: body.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
        a: body.copyWith(color: AppColors.primary),
        h1: GoogleFonts.anton(fontSize: 22, color: Colors.white),
        h2: GoogleFonts.anton(fontSize: 18, color: AppColors.primary),
        h3: GoogleFonts.barlow(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        tableBody: body,
        tableHead: body.copyWith(fontWeight: FontWeight.w700),
        tableBorder: TableBorder.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
        ),
      ),
    );
  }
}

class ShowcaseMarkdownCard extends StatelessWidget {
  final String title;
  final String data;

  const ShowcaseMarkdownCard({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: GoogleFonts.anton(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 12),
          ],
          if (data.isNotEmpty) ShowcaseMarkdown(data: data),
        ],
      ),
    );
  }
}

/// Bandeau défilant en continu (contenu dupliqué une fois, la boucle se fait
/// exactement à la largeur d'une copie — pas de saut visible). Pur effet de
/// marque : pas d'info exclusive, donc pas de lecteur d'écran dédié requis
/// au-delà du contenu déjà annoncé par les cartes.
class MarqueeBand extends StatefulWidget {
  final List<String> words;

  const MarqueeBand({super.key, required this.words});

  @override
  State<MarqueeBand> createState() => _MarqueeBandState();
}

class _MarqueeBandState extends State<MarqueeBand>
    with SingleTickerProviderStateMixin {
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
      children: [for (final w in widget.words) _wordChip(w)],
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
            w.toUpperCase(),
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

class _CategoryTiles extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _CategoryTiles({required this.items});

  @override
  Widget build(BuildContext context) {
    return RevealOnVisible(
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          for (final c in items)
            _CategoryTile(
              label: (c['label'] as String).trim(),
              icon: showcaseIcon(c['icon'] as String?),
            ),
        ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 820;

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
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        );
      },
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
            if (tag.isNotEmpty)
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
        if (eyebrow.isNotEmpty) ...[
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
        ],
        if (title.isNotEmpty)
          Text(
            title,
            style: GoogleFonts.anton(
              fontSize: 28,
              color: Colors.white,
              height: 1.05,
            ),
          ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            body,
            style: GoogleFonts.barlow(
              fontSize: 14.5,
              height: 1.6,
              color: AppColors.darkTextSecondary,
            ),
          ),
        ],
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
  final String eyebrow;
  final String title;
  final List<Map<String, dynamic>> items;

  const _TestimonialsSection({
    required this.eyebrow,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RevealOnVisible(
          child: ShowcaseSectionHeading(eyebrow: eyebrow, title: title),
        ),
        const SizedBox(height: 28),
        ResponsiveGrid(
          spacing: 20,
          runSpacing: 20,
          children: [
            for (final t in items)
              RevealOnVisible(
                child: _TestimonialCard(
                  name: (t['name'] as String?)?.trim() ?? '',
                  meta: (t['meta'] as String?)?.trim() ?? '',
                  quote: (t['quote'] as String).trim(),
                ),
              ),
          ],
        ),
      ],
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
          if (name.isNotEmpty) ...[
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
                      name[0].toUpperCase(),
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
                      if (meta.isNotEmpty)
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
        ],
      ),
    );
  }
}

class _CallToAction extends StatelessWidget {
  final String eyebrow;
  final String text;
  final String buttonLabel;
  final String url;

  const _CallToAction({
    required this.eyebrow,
    required this.text,
    required this.buttonLabel,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final uri = _safeUri(url);
    return RevealOnVisible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (eyebrow.isNotEmpty) ...[
                    Text(
                      eyebrow,
                      style: GoogleFonts.barlow(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: AppColors.darkBackground.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (text.isNotEmpty)
                    Text(
                      text,
                      style: GoogleFonts.barlow(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBackground,
                        height: 1.3,
                      ),
                    ),
                ],
              ),
            ),
            if (uri != null && buttonLabel.isNotEmpty) ...[
              const SizedBox(width: 16),
              Material(
                color: AppColors.darkBackground,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          buttonLabel,
                          style: GoogleFonts.barlow(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
