import 'package:flutter/material.dart';
import '../../models/match.dart';
import '../../core/theme.dart';
import '../../core/motion.dart';
import '../../widgets/pressable.dart';
import '../../widgets/fade_switch.dart';
import '../../widgets/network_image_widget.dart';

class FeaturedCard extends StatelessWidget {
  final Match? match;
  final VoidCallback onTap;

  const FeaturedCard({super.key, required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLive = match?.isLive == true;
    final accent = isLive ? AppColors.live : AppColors.primary;

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.slow,
        curve: Motion.emphasized,
        height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLive
                ? [const Color(0xFF220809), const Color(0xFF2D0A0B), AppColors.surface]
                : [const Color(0xFF08111F), const Color(0xFF0B1530), AppColors.surface],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.18),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                left: -36,
                bottom: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.035),
                  ),
                ),
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
                                  padding: const EdgeInsets.only(right: 6),
                                  child: NetworkImageWidget(
                                    url: match!.leagueLogoUrl,
                                    size: 14,
                                    fallbackIcon: Icons.emoji_events,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  match!.league.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (match!.isLive) _LiveBadge(),
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
                                    const SizedBox(height: 6),
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
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
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
                                    const SizedBox(height: 6),
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
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
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
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.live.withOpacity(0.82 + _pulse.value * 0.18),
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
            const SizedBox(width: 4),
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
