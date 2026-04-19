import 'dart:async';
import 'package:flutter/material.dart';
import '../core/motion.dart';

class SlideFade extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double beginOffset;
  final double beginScale;

  const SlideFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Motion.normal,
    this.beginOffset = 12,
    this.beginScale = 0.985,
  });

  @override
  State<SlideFade> createState() => _SlideFadeState();
}

class _SlideFadeState extends State<SlideFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    unawaited(Future<void>.delayed(widget.delay).then((_) {
      if (mounted) _controller.forward();
    }));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.beginOffset * (1 - t)),
            child: Transform.scale(
              scale: widget.beginScale + ((1 - widget.beginScale) * t),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
