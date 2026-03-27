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
  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final AnimationController _glowCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _arabicFadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<Offset> _arabicSlideAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    // Main fade in over 1 second
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Slide animation
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Glow pulse animation
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // "VargasTv" fades in and slides up
    _fadeAnim = CurvedAnimation(
      parent: _fadeCtrl,
      curve: Curves.easeOutCubic,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideCtrl,
      curve: Curves.easeOutCubic,
    ));

    // "فاركاس" fades in slightly delayed
    _arabicFadeAnim = CurvedAnimation(
      parent: _fadeCtrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    );

    _arabicSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideCtrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    // Glow pulse
    _glowAnim = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeCtrl.forward();
    _slideCtrl.forward();

    // Navigate to home after 4 seconds total
    Future.delayed(const Duration(seconds: 4), () {
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
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          // Ambient green glow behind text
          Center(
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accent.withOpacity(_glowAnim.value * 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Text content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "VargasTv" - green with slide + fade
                SlideTransition(
                  position: _slideAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppTheme.accent2, AppTheme.accent, AppTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'VargasTv',
                        style: GoogleFonts.poppins(
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 2.0,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // "فاركاس" - white with delayed slide + fade
                SlideTransition(
                  position: _arabicSlideAnim,
                  child: FadeTransition(
                    opacity: _arabicFadeAnim,
                    child: Text(
                      '\u0641\u0627\u0631\u0643\u0627\u0633',
                      style: GoogleFonts.cairo(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 4.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Thin accent line that fades in
                FadeTransition(
                  opacity: _arabicFadeAnim,
                  child: Container(
                    width: 60,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
