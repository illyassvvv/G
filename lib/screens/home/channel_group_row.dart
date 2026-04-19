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
                  color: AppColors.primary.withOpacity(0.9),
                  shape: BoxShape.circle,
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
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 162,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: channels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              return SizedBox(
                width: 122,
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
