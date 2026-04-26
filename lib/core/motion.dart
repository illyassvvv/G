import 'package:flutter/material.dart';

/// A restrained premium motion system.
/// The goal is to feel smooth and expensive rather than flashy.
class Motion {
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 560);
  static const stagger = Duration(milliseconds: 70);

  /// Soft, modern ease for most transitions.
  static const curve = Cubic(0.22, 1.0, 0.36, 1.0);

  /// Slightly more emphatic iOS-like motion for route/page changes.
  static const emphasized = Cubic(0.16, 1.0, 0.24, 1.0);

  /// Gentle fade curve for overlays and switchers.
  static const fade = Cubic(0.12, 0.86, 0.18, 1.0);

  /// Subtle scale response, no bouncy overshoot.
  static const spring = Cubic(0.18, 0.95, 0.2, 1.0);
}
