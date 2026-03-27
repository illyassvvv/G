import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Master timeline controller (2.5 seconds total)
  late final AnimationController _master;

  // Logo animations
  late final Animation<double> _vargasFade;
  late final Animation<double> _tvFade;
  late final Animation<double> _logoScale;

  // Glow animation
  late final Animation<double> _glowAnim;

  // Tagline animation
  late final Animation<double> _taglineFade;

  // Loading dots
  late final AnimationController _dotsController;

  // Ambient gradient rotation
  late final AnimationController _gradientController;

  @override
  void initState() {
    super.initState();

    // ── Master timeline (0 → 2500ms) ──────────────────────────
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // "Vargas" fades in: 0ms → 600ms
    _vargasFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _master,
        curve: const Interval(0, 0.24, curve: Curves.easeOut)),
    );

    // "TV" fades in: 400ms → 900ms (overlaps slightly)
    _tvFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _master,
        curve: const Interval(0.16, 0.36, curve: Curves.easeOut)),
    );

    // Logo scale: subtle zoom 0.85 → 1.0 over 0 → 1000ms
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _master,
        curve: const Interval(0, 0.4, curve: Curves.easeOutCubic)),
    );

    // Glow pulse: 500ms → 1500ms
    _glowAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _master,
        curve: const Interval(0.2, 0.6, curve: Curves.easeInOut)),
    );

    // Tagline fade in: 1000ms → 1600ms
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _master,
        curve: const Interval(0.4, 0.64, curve: Curves.easeOut)),
    );

    // ── Loading dots loop ─────────────────────────────────────
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // ── Ambient gradient slow rotation ────────────────────────
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Start master animation
    _master.forward();

    // Navigate after 2.8 seconds
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _master.dispose();
    _dotsController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: AnimatedBuilder(
        animation: Listenable.merge([_master, _dotsController, _gradientController]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Animated gradient background ──────────────
              _buildAnimatedBackground(),

              // ── Main content ──────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo with glow
                    Transform.scale(
                      scale: _logoScale.value,
                      child: _buildLogo(),
                    ),
                    const SizedBox(height: 20),
                    // Tagline
                    Opacity(
                      opacity: _taglineFade.value,
                      child: Text(
                        'Your Premium TV Experience',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.4),
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Loading dots
                    Opacity(
                      opacity: _taglineFade.value,
                      child: _buildLoadingDots(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    final angle = _gradientController.value * 2 * pi;
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(
            0.3 * cos(angle),
            0.3 * sin(angle),
          ),
          radius: 1.2,
          colors: [
            AppTheme.primaryDeep.withOpacity(0.4),
            const Color(0xFF0A0A0A),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow behind the text
        Opacity(
          opacity: _glowAnim.value * 0.6,
          child: Container(
            width: 200,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withOpacity(0.25),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
          ),
        ),
        // Logo text
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: 'Vargas',
              style: GoogleFonts.poppins(
                fontSize: 52,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(_vargasFade.value),
                letterSpacing: -1.5,
              ),
            ),
            TextSpan(
              text: 'TV',
              style: GoogleFonts.poppins(
                fontSize: 52,
                fontWeight: FontWeight.w700,
                color: AppTheme.accent.withOpacity(_tvFade.value),
                letterSpacing: -1.5,
                shadows: _glowAnim.value > 0.3
                    ? [
                        Shadow(
                          color: AppTheme.accent.withOpacity(_glowAnim.value * 0.5),
                          blurRadius: 20,
                        ),
                      ]
                    : null,
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        // Each dot animates with a phase offset
        final phase = (_dotsController.value + i * 0.25) % 1.0;
        // Smooth bounce: 0→1→0 using sin curve
        final t = sin(phase * pi);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.accent.withOpacity(0.3 + t * 0.7),
          ),
        );
      }),
    );
  }
}
