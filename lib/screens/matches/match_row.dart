import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/match.dart';
import '../../widgets/fade_switch.dart';
import '../../widgets/network_image_widget.dart';
import '../../widgets/premium_surface.dart';

class MatchRow extends StatelessWidget {
  final Match match;

  const MatchRow({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      borderRadius: BorderRadius.circular(28),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              if (match.leagueLogoUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: NetworkImageWidget(
                    url: match.leagueLogoUrl,
                    size: 15,
                    fallbackIcon: Icons.sports_soccer_rounded,
                  ),
                ),
              if (match.isLive) ...[
                _LiveDot(),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  match.league,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (match.isLive)
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: AppColors.live,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                )
              else
                Text(
                  match.time,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        match.home,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    NetworkImageWidget(
                      url: match.homeLogoUrl,
                      size: 32,
                      fallbackIcon: Icons.shield_outlined,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    FadeSwitch(
                      child: Text(
                        match.isLive ? match.score : match.time,
                        key: ValueKey(match.isLive ? match.score : match.time),
                        style: TextStyle(
                          color: match.isLive ? AppColors.live : AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 28,
                      height: 2,
                      decoration: BoxDecoration(
                        color: match.isLive ? AppColors.live.withOpacity(0.75) : AppColors.primary.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    NetworkImageWidget(
                      url: match.awayLogoUrl,
                      size: 32,
                      fallbackIcon: Icons.shield_outlined,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        match.away,
                        textAlign: TextAlign.left,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (match.isLive) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: null,
                backgroundColor: Colors.white.withOpacity(0.06),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.live),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: 0.92 + (_ctrl.value * 0.16),
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.live.withOpacity(0.55 + _ctrl.value * 0.38),
          ),
        ),
      ),
    );
  }
}
