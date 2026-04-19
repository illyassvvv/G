import 'package:flutter/material.dart';
import '../core/motion.dart';

PageRoute<T> buildPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: Motion.normal,
    reverseTransitionDuration: Motion.fast,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: Motion.curve,
      );

      final scale = Tween<double>(begin: 0.98, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Motion.emphasized),
      );

      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: scale,
          child: child,
        ),
      );
    },
  );
}