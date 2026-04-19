import 'package:flutter/material.dart';
import '../core/motion.dart';

class FadeSwitch extends StatelessWidget {
  final Widget child;

  const FadeSwitch({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.normal,
      reverseDuration: Motion.fast,
      switchInCurve: Motion.emphasized,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final fade = CurvedAnimation(parent: animation, curve: Motion.fade);
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation);
        final scale = Tween<double>(begin: 0.985, end: 1.0).animate(animation);

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: ScaleTransition(scale: scale, child: child),
          ),
        );
      },
      child: child,
    );
  }
}
