import 'package:flutter/material.dart';

class Motion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 400);
  static const stagger = Duration(milliseconds: 60);

  // Standard ease-out for most transitions
  static const curve = Curves.easeOut;

  // Overshoot-free spring-like curve — great for cards and page transitions
  static const emphasized = Cubic(0.16, 1.0, 0.3, 1.0);

  // Gentle ease for opacity fades
  static const fade = Cubic(0.25, 0.46, 0.45, 0.94);
}
