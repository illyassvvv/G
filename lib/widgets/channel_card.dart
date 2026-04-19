import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../core/theme.dart';
import '../screens/player_screen.dart';
import '../widgets/page_transition.dart';
import 'network_image_widget.dart';
import 'pressable.dart';

class ChannelCard extends StatelessWidget {
  final Channel channel;

  const ChannelCard({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        Navigator.push(
          context,
          buildPageRoute(PlayerScreen(channel: channel)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use logoUrl getter — comes from GitHub JSON directly
            NetworkImageWidget(
              url: channel.logoUrl,
              size: 56,
              fallbackIcon: Icons.tv,
            ),
            const SizedBox(height: 10),
            Text(
              channel.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
