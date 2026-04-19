import 'package:flutter/material.dart';

/// Motion language tuned for a premium streaming feel:
/// - quick tactile responses for taps
/// - fluid, slightly springy page/card motion
/// - restrained fades for content changes
class Motion {
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 520);
  static const stagger = Duration(milliseconds: 70);

  /// Soft, modern ease for most transitions.
  static const curve = Curves.easeOutCubic;

  /// Stronger, iOS-like emphasis for route and selection motion.
  static const emphasized = Cubic(0.16, 1.0, 0.22, 1.0);

  /// Gentle content fade.
  static const fade = Cubic(0.12, 0.9, 0.2, 1.0);

  /// Small overshoot-free spring feel for chips/cards.
  static const spring = Cubic(0.2, 0.95, 0.2, 1.0);
}
