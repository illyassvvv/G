import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'luxury_atmosphere_art.dart';

/// Premium full-screen atmospheric backdrop.
///
/// This layer gives the app a more luxurious, cinematic presence by combining
/// rich gradient walls, embedded texture art, and soft glow overlays.
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
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: dark ? 0.88 : 0.92,
                child: Image.memory(
                  dark ? LuxuryAtmosphereArt.darkBytes : LuxuryAtmosphereArt.lightBytes,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: dark
                      ? [
                          const Color(0xEE05070B),
                          const Color(0x99090E16),
                          const Color(0xEE05070B),
                        ]
                      : [
                          const Color(0xF7F6F2),
                          const Color(0xDCF2F4F8),
                          const Color(0xF7F6F2),
                        ],
                ),
              ),
            ),
          ),
          if (dark)
            const _DarkAtmosphere()
          else
            const _LightAtmosphere(),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: dark
                      ? [
                          Colors.black.withOpacity(0.10),
                          Colors.transparent,
                          Colors.black.withOpacity(0.28),
                        ]
                      : [
                          Colors.white.withOpacity(0.30),
                          Colors.transparent,
                          Colors.white.withOpacity(0.18),
                        ],
                ),
              ),
            ),
          ),
          if (useBlur)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.18, sigmaY: 0.18),
                child: const SizedBox.expand(),
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
        children: [
          Positioned(
            top: -120,
            right: -70,
            child: _Glow(
              size: 280,
              color: const Color(0xFF5D79F0).withOpacity(0.12),
            ),
          ),
          Positioned(
            top: 180,
            left: -120,
            child: _Glow(
              size: 300,
              color: const Color(0xFFFF5D58).withOpacity(0.06),
            ),
          ),
          Positioned(
            bottom: 140,
            right: -100,
            child: _Glow(
              size: 260,
              color: const Color(0xFF9B7BFF).withOpacity(0.08),
            ),
          ),
          Positioned(
            top: 300,
            right: -120,
            child: _Glow(
              size: 220,
              color: const Color(0xFF8EA6FF).withOpacity(0.05),
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
        children: [
          Positioned(
            top: -120,
            right: -60,
            child: _Glow(
              size: 260,
              color: const Color(0xFF7C96FF).withOpacity(0.11),
            ),
          ),
          Positioned(
            top: 220,
            left: -130,
            child: _Glow(
              size: 300,
              color: const Color(0xFFFF8A7A).withOpacity(0.055),
            ),
          ),
          Positioned(
            bottom: 110,
            right: -120,
            child: _Glow(
              size: 280,
              color: const Color(0xFFC59BFF).withOpacity(0.065),
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

  const _Glow({
    required this.size,
    required this.color,
  });

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
