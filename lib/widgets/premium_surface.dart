import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme.dart';

class PremiumSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final bool glass;
  final double blur;
  final Color? overlayColor;
  final Color? borderColor;
  final List<BoxShadow>? shadows;

  const PremiumSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.glass = false,
    this.blur = 18,
    this.overlayColor,
    this.borderColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? AppColors.surface : AppColors.surfaceLight;
    final elevated = dark ? AppColors.surfaceElevated : AppColors.surfaceLightAlt;
    final outline = borderColor ??
        (dark ? Colors.white.withOpacity(0.08) : const Color(0x18000000));

    final boxDecoration = BoxDecoration(
      borderRadius: borderRadius,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          overlayColor ?? base.withOpacity(dark ? 0.98 : 1),
          elevated.withOpacity(dark ? 0.98 : 1),
        ],
      ),
      border: Border.all(color: outline),
      boxShadow: shadows ??
          [
            BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.22 : 0.08),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
    );

    Widget content = Container(
      padding: padding,
      decoration: boxDecoration,
      child: child,
    );

    if (!glass) return ClipRRect(borderRadius: borderRadius, child: content);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );
  }
}
