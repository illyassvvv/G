import 'package:flutter/material.dart';
import '../../models/match.dart';
import '../../core/theme.dart';
import '../../core/motion.dart';
import '../../widgets/pressable.dart';
import '../../widgets/fade_switch.dart';

class FeaturedCard extends StatelessWidget {
  final Match? match;
  final VoidCallback onTap;

  const FeaturedCard({
    super.key,
    required this.match,
    required this.onTap,
  });

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
                ? [const Color(0xFF1A0A0A), const Color(0xFF2A0808), AppColors.surface]
                : [const Color(0xFF0A0F1A), const Color(0xFF0D1628), AppColors.surface],
          ),
          boxShadow: [
            BoxShadow(
              color: (match?.isLive == true ? AppColors.live : AppColors.primary)
                  .withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Subtle top-right glow blob
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (match?.isLive == true ? AppColors.live : AppColors.primary)
                        .withOpacity(0.08),
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
                          // League + Live badge row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  match!.league.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              if (match!.isLive) _LiveBadge(),
                            ],
                          ),

                          const Spacer(),

                          // Teams + Score
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  match!.home,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: FadeSwitch(
                                  child: Text(
                                    match!.isLive ? match!.score : match!.time,
                                    key: ValueKey(
                                        match!.isLive ? match!.score : match!.time),
                                    style: TextStyle(
                                      color: match!.isLive
                                          ? AppColors.live
                                          : AppColors.textSecondary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  match!.away,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Watch button
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Watch Now',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
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
