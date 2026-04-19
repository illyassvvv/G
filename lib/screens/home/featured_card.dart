import 'package:flutter/material.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../models/match.dart';
import '../../widgets/fade_switch.dart';
import '../../widgets/network_image_widget.dart';
import '../../widgets/premium_surface.dart';

class FeaturedCard extends StatelessWidget {
  final Match? match;
  const FeaturedCard({
    super.key,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = match?.isLive == true;
    final accent = isLive ? AppColors.live : AppColors.primary;

    final content = PremiumSurface(
      glass: false,
      borderRadius: BorderRadius.circular(30),
      padding: EdgeInsets.zero,
      overlayColor: null,
      shadows: [
        BoxShadow(
          color: accent.withOpacity(0.12),
          blurRadius: 36,
          offset: const Offset(0, 16),
        ),
      ],
      child: AnimatedContainer(
        duration: Motion.slow,
        curve: Motion.emphasized,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLive
                ? [
                    const Color(0xFF1E090A),
                    const Color(0xFF2A0B0C),
                    AppColors.surface,
                  ]
                : [
                    const Color(0xFF08111F),
                    const Color(0xFF0A1630),
                    AppColors.surface,
                  ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              Positioned(
                top: -48,
                right: -36,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.10),
                  ),
                ),
              ),
              Positioned(
                left: -44,
                bottom: -44,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.035),
                  ),
                ),
              ),
              if (match?.isLive == true)
                Positioned(
                  top: 18,
                  right: 18,
                  child: _LiveBadge(),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: match == null
                    ? const Center(
                        child: Text(
                          'No match available',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (match!.leagueLogoUrl.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: NetworkImageWidget(
                                    url: match!.leagueLogoUrl,
                                    size: 15,
                                    fallbackIcon: Icons.emoji_events,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  match!.league,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.0,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    NetworkImageWidget(
                                      url: match!.homeLogoUrl,
                                      size: 44,
                                      fallbackIcon: Icons.shield_outlined,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      match!.home,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: FadeSwitch(
                                  child: Text(
                                    match!.isLive ? match!.score : match!.time,
                                    key: ValueKey(
                                      match!.isLive ? match!.score : match!.time,
                                    ),
                                    style: TextStyle(
                                      color: match!.isLive
                                          ? AppColors.live
                                          : AppColors.textSecondary,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    NetworkImageWidget(
                                      url: match!.awayLogoUrl,
                                      size: 44,
                                      fallbackIcon: Icons.shield_outlined,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      match!.away,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );

    return content;
  }
}

class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.live.withOpacity(0.80 + _pulse.value * 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 0.9 + (_pulse.value * 0.12),
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
