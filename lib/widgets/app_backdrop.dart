import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme.dart';

class AppBackdrop extends StatelessWidget {
  final Widget child;
  final bool useBlur;

  const AppBackdrop({
    super.key,
    required this.child,
    this.useBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: dark
          ? const [
              AppColors.background,
              AppColors.backgroundAlt,
              AppColors.background,
            ]
          : const [
              AppColors.backgroundLight,
              AppColors.backgroundLightAlt,
              AppColors.backgroundLight,
            ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: _Glow(
              size: 240,
              color: dark
                  ? const Color(0xFF5F7BFF).withOpacity(0.12)
                  : const Color(0xFF5F7BFF).withOpacity(0.14),
            ),
          ),
          Positioned(
            top: 180,
            left: -120,
            child: _Glow(
              size: 260,
              color: dark
                  ? const Color(0xFFFF4A3D).withOpacity(0.05)
                  : const Color(0xFFFF4A3D).withOpacity(0.08),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -100,
            child: _Glow(
              size: 220,
              color: dark
                  ? const Color(0xFF9D7BFF).withOpacity(0.05)
                  : const Color(0xFF9D7BFF).withOpacity(0.07),
            ),
          ),
          if (useBlur)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.01, sigmaY: 0.01),
                child: const SizedBox.expand(),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
