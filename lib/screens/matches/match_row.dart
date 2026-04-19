import 'package:flutter/material.dart';
import '../../models/match.dart';
import '../../core/theme.dart';
import '../../widgets/fade_switch.dart';

class MatchRow extends StatelessWidget {
  final Match match;

  const MatchRow({
    super.key,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: match.isLive
            ? Border.all(color: AppColors.live.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (match.isLive) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.live,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                match.league,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  match.home,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: FadeSwitch(
                  child: Text(
                    match.isLive ? match.score : match.time,
                    key: ValueKey(match.isLive ? match.score : match.time),
                    style: TextStyle(
                      color: match.isLive ? AppColors.live : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  match.away,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
