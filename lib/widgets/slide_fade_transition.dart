import 'package:flutter/material.dart';
import '../core/motion.dart';

class SlideFade extends StatelessWidget {
  final Widget child;

  const SlideFade({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.normal,
      curve: Motion.spring,
      builder: (_, value, child) {
        final eased = Curves.easeOutCubic.transform(value);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - eased)),
            child: Transform.scale(
              scale: 0.985 + (0.015 * eased),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
