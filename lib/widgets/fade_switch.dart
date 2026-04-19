import 'package:flutter/material.dart';
import '../core/motion.dart';

class FadeSwitch extends StatelessWidget {
  final Widget child;

  const FadeSwitch({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.normal,
      switchInCurve: Motion.curve,
      switchOutCurve: Motion.curve,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: child,
    );
  }
}