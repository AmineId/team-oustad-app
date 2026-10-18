import 'package:flutter/material.dart';

/// Retour interactif par glissement depuis le bord, comme le geste natif iOS,
/// pour les sous-vues commutées par état (sans route Navigator).
class SwipeBack extends StatefulWidget {
  final Widget child;
  final VoidCallback onBack;
  final bool enabled;

  const SwipeBack({
    super.key,
    required this.child,
    required this.onBack,
    this.enabled = true,
  });

  @override
  State<SwipeBack> createState() => _SwipeBackState();
}

class _SwipeBackState extends State<SwipeBack>
    with SingleTickerProviderStateMixin {
  static const double _edgeWidth = 24;
  static const double _commitFraction = 0.35;
  static const double _commitVelocity = 700;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  double _width = 1;
  bool _rtl = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onUpdate(DragUpdateDetails d) {
    final delta = _rtl ? -d.delta.dx : d.delta.dx;
    _controller.value = (_controller.value + delta / _width).clamp(0.0, 1.0);
  }

  Future<void> _onEnd(DragEndDetails d) async {
    final v = _rtl
        ? -d.velocity.pixelsPerSecond.dx
        : d.velocity.pixelsPerSecond.dx;
    if (_controller.value > _commitFraction || v > _commitVelocity) {
      await _controller.animateTo(1, curve: Curves.easeOut);
      if (mounted) widget.onBack();
    } else {
      await _controller.animateBack(0, curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (!widget.enabled || !isIOS) return widget.child;
    _rtl = Directionality.of(context) == TextDirection.rtl;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 1;
        return Stack(
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value;
                return Stack(
                  children: [
                    if (t > 0)
                      Positioned.fill(
                        child: ColoredBox(
                          color: Color.alphaBlend(
                            Colors.black.withValues(alpha: 0.12 * (1 - t)),
                            bg,
                          ),
                        ),
                      ),
                    Transform.translate(
                      offset: Offset((_rtl ? -1 : 1) * t * _width, 0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: t > 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 18,
                                  ),
                                ]
                              : null,
                        ),
                        child: child,
                      ),
                    ),
                  ],
                );
              },
              child: widget.child,
            ),
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              width: _edgeWidth,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: _onUpdate,
                onHorizontalDragEnd: _onEnd,
                onHorizontalDragCancel: () => _controller.animateBack(0),
              ),
            ),
          ],
        );
      },
    );
  }
}
