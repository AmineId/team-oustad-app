import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

bool get _revealReduceMotion => SchedulerBinding
    .instance
    .platformDispatcher
    .accessibilityFeatures
    .disableAnimations;

/// Fait apparaître [child] en fondu + léger glissement vertical au montage.
/// Utiliser [delay] pour échelonner l'entrée d'une liste/grille (effet
/// "stagger"). Respecte les préférences d'accessibilité : si l'utilisateur a
/// désactivé les animations système, le contenu apparaît directement.
class RevealOnLoad extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset beginOffset;

  const RevealOnLoad({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 0.08),
  });

  @override
  State<RevealOnLoad> createState() => _RevealOnLoadState();
}

class _RevealOnLoadState extends State<RevealOnLoad>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final reduceMotion = _revealReduceMotion;
    _controller = AnimationController(
      vsync: this,
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 520),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = curved;
    _slide = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(curved);

    if (reduceMotion) {
      _controller.value = 1;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Comme [RevealOnLoad], mais se déclenche quand [child] entre dans le
/// viewport de l'ancêtre scrollable (une seule fois), plutôt qu'après un
/// délai fixe au montage. Pensé pour le contenu sous la ligne de flottaison
/// (grilles, sections) pour un effet d'entrée pendant le scroll.
class RevealOnVisible extends StatefulWidget {
  final Widget child;
  final Offset beginOffset;

  /// Fraction de la hauteur du viewport à partir de laquelle le contenu est
  /// considéré "visible" (1 = doit atteindre le bas du viewport, 0.8 =
  /// se déclenche un peu avant d'être pleinement visible).
  final double visibleFraction;

  const RevealOnVisible({
    super.key,
    required this.child,
    this.beginOffset = const Offset(0, 0.1),
    this.visibleFraction = 0.9,
  });

  @override
  State<RevealOnVisible> createState() => _RevealOnVisibleState();
}

class _RevealOnVisibleState extends State<RevealOnVisible>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  ScrollPosition? _position;
  bool _played = false;

  @override
  void initState() {
    super.initState();
    final reduceMotion = _revealReduceMotion;
    _controller = AnimationController(
      vsync: this,
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 520),
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = curved;
    _slide = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(curved);
    if (reduceMotion) {
      _controller.value = 1;
      _played = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_played) return;
    final newPosition = Scrollable.maybeOf(context)?.position;
    if (newPosition != _position) {
      _position?.removeListener(_check);
      _position = newPosition;
      _position?.addListener(_check);
    }
  }

  void _check() {
    if (_played || !mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return;
    final viewportHeight =
        View.of(context).physicalSize.height /
        View.of(context).devicePixelRatio;
    final top = renderObject.localToGlobal(Offset.zero).dy;
    if (top < viewportHeight * widget.visibleFraction) {
      _played = true;
      _position?.removeListener(_check);
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
