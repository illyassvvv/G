import 'package:flutter/material.dart';
import '../../models/match.dart';
import '../../core/theme.dart';
import '../../widgets/fade_switch.dart';
import '../../widgets/network_image_widget.dart';

class MatchRow extends StatelessWidget {
  final Match match;

  const MatchRow({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: match.isLive
            ? Border.all(color: AppColors.live.withOpacity(0.35), width: 1)
            : null,
      ),
      child: Column(
        children: [
          // League row
          Row(
            children: [
              if (match.leagueLogoUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: NetworkImageWidget(
                    url: match.leagueLogoUrl,
                    size: 14,
                    fallbackIcon: Icons.sports_soccer,
                  ),
                ),
              if (match.isLive) ...[
                _LiveDot(),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  match.league,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Teams row
          Row(
            children: [
              // Home team
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
                          fontWeight: FontWeight.w600,
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
              // Score / Time
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FadeSwitch(
                  child: Text(
                    match.isLive ? match.score : match.time,
                    key: ValueKey(match.isLive ? match.score : match.time),
                    style: TextStyle(
                      color: match.isLive
                          ? AppColors.live
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              // Away team
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
                          fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
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
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.live.withOpacity(0.6 + _ctrl.value * 0.4),
        ),
      ),
    );
  }
}
