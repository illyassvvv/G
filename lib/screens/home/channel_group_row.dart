import 'package:flutter/material.dart';
import '../../models/channel.dart';
import '../../core/theme.dart';
import '../../widgets/channel_card.dart';

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
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: channels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              return SizedBox(
                width: 120,
                child: ChannelCard(channel: channels[i]),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}