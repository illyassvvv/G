import 'package:flutter/material.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../models/channel.dart';
import '../../widgets/channel_card.dart';
import '../../widgets/slide_fade_transition.dart';

class ChannelGroupRow extends StatelessWidget {
  final String title;
  final List<Channel> channels;

  const ChannelGroupRow({
    super.key,
    required this.title,
    required this.channels,
  });

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) return const SizedBox.shrink();

    final dark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = dark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.92),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Text(
                '${channels.length}',
                style: TextStyle(
                  color: textSecondary.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 164,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: channels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              return SizedBox(
                width: 124,
                child: SlideFade(
                  delay: Duration(milliseconds: Motion.stagger.inMilliseconds * i),
                  child: ChannelCard(channel: channels[i]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }
}
