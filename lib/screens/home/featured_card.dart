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
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.normal,
        curve: Motion.emphasized,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: match?.isLive == true
                ? [const Color(0xFF1E0808), const Color(0xFF2A0A0A), AppColors.surface]
                : [const Color(0xFF080F1E), const Color(0xFF0A1228), AppColors.surface],
          ),
          boxShadow: [
            BoxShadow(
              color: (match?.isLive == true ? AppColors.live : AppColors.primary)
                  .withOpacity(0.15),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Ambient glow blob
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (match?.isLive == true ? AppColors.live : AppColors.primary)
                        .withOpacity(0.07),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: match == null
                    ? const Center(
                        child: Text('No match available',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // League + live badge
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
                          // Teams with logos — NO Watch Now button
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
                                        match!.isLive ? match!.score : match!.time),
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
                          const SizedBox(height: 4),
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
          color: AppColors.live.withOpacity(0.85 + _pulse.value * 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            const Text('LIVE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }
}
