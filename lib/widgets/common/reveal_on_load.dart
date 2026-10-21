import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

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
    final reduceMotion =
        SchedulerBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _controller = AnimationController(
      vsync: this,
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 520),
    );
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _fade = curved;
    _slide = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero).animate(curved);

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
