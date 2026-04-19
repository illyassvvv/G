import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Luxury full-screen backdrop with soft atmosphere, depth, and no asset bloat.
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
    final base = dark ? AppColors.background : AppColors.backgroundLight;

    return DecoratedBox(
      decoration: BoxDecoration(color: base),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Core light wall.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? [
                        const Color(0xFF07090D),
                        const Color(0xFF0B1018),
                        const Color(0xFF07090D),
                      ]
                    : [
                        const Color(0xFFFDFCF9),
                        const Color(0xFFF3F0EA),
                        const Color(0xFFFDFCF9),
                      ],
              ),
            ),
          ),
          if (dark)
            const _DarkAtmosphere()
          else
            const _LightAtmosphere(),
          // Gentle tint wash that unifies the whole canvas.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? [
                        Colors.black.withOpacity(0.08),
                        Colors.transparent,
                        Colors.black.withOpacity(0.26),
                      ]
                    : [
                        Colors.white.withOpacity(0.26),
                        Colors.transparent,
                        Colors.white.withOpacity(0.18),
                      ],
              ),
            ),
          ),
          if (useBlur)
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 0.20, sigmaY: 0.20),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _DarkAtmosphere extends StatelessWidget {
  const _DarkAtmosphere();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: const [
          Positioned(
            top: -140,
            right: -100,
            child: _Glow(
              size: 320,
              color: Color(0x145D79F0),
            ),
          ),
          Positioned(
            top: 170,
            left: -120,
            child: _Glow(
              size: 320,
              color: Color(0x0EFF5D58),
            ),
          ),
          Positioned(
            bottom: 110,
            right: -120,
            child: _Glow(
              size: 300,
              color: Color(0x129B7BFF),
            ),
          ),
          Positioned(
            top: 260,
            right: -90,
            child: _Glow(
              size: 220,
              color: Color(0x0A8EA6FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _LightAtmosphere extends StatelessWidget {
  const _LightAtmosphere();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: const [
          Positioned(
            top: -140,
            right: -80,
            child: _Glow(
              size: 300,
              color: Color(0x147C96FF),
            ),
          ),
          Positioned(
            top: 220,
            left: -130,
            child: _Glow(
              size: 320,
              color: Color(0x12FF8A7A),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -120,
            child: _Glow(
              size: 290,
              color: Color(0x149B7BFF),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
