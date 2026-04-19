import 'package:flutter/material.dart';
import '../core/motion.dart';

PageRoute<T> buildPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: Motion.normal,
    reverseTransitionDuration: Motion.fast,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final eased = CurvedAnimation(parent: animation, curve: Motion.emphasized);
      final fade = CurvedAnimation(parent: animation, curve: Motion.fade);
      final slide = Tween<Offset>(
        begin: const Offset(0.05, 0),
        end: Offset.zero,
      ).animate(eased);
      final scale = Tween<double>(begin: 0.985, end: 1.0).animate(eased);

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: ScaleTransition(
            scale: scale,
            child: child,
          ),
        ),
      );
    },
  );
}
