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

    return PremiumSurface(
      glass: true,
      blur: 18,
      borderRadius: BorderRadius.circular(34),
      padding: EdgeInsets.zero,
      overlayColor: null,
      shadows: [
        BoxShadow(
          color: accent.withOpacity(0.14),
          blurRadius: 36,
          offset: const Offset(0, 16),
        ),
      ],
      child: AnimatedContainer(
        duration: Motion.slow,
        curve: Motion.emphasized,
        height: 232,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLive
                ? [
                    const Color(0xFF1D0A0B),
                    const Color(0xFF271112),
                    AppColors.surface,
                  ]
                : [
                    const Color(0xFF09111E),
                    const Color(0xFF0D1B34),
                    AppColors.surface,
                  ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: Stack(
            children: [
              Positioned(
                top: -48,
                right: -32,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.12),
                  ),
                ),
              ),
              Positioned(
                left: -40,
                bottom: -46,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.06),
                        Colors.transparent,
                        Colors.black.withOpacity(0.14),
                      ],
                      stops: const [0, 0.52, 1],
                    ),
                  ),
                ),
              ),
              if (isLive)
                const Positioned(
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
                                    fallbackIcon: Icons.emoji_events_rounded,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  match!.league,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
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
                                      size: 48,
                                      fallbackIcon: Icons.shield_outlined,
                                    ),
                                    const SizedBox(height: 10),
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
                                    isLive ? match!.score : match!.time,
                                    key: ValueKey(isLive ? match!.score : match!.time),
                                    style: TextStyle(
                                      color: isLive ? AppColors.live : AppColors.textSecondary,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    NetworkImageWidget(
                                      url: match!.awayLogoUrl,
                                      size: 48,
                                      fallbackIcon: Icons.shield_outlined,
                                    ),
                                    const SizedBox(height: 10),
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
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
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
