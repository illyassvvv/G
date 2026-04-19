import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../core/theme.dart';
import '../screens/player_screen.dart';
import '../widgets/page_transition.dart'; // FIX: import smooth transition
import 'network_image_widget.dart';
import 'pressable.dart'; // FIX: use Pressable for scale press animation

class ChannelCard extends StatelessWidget {
  final Channel channel;

  const ChannelCard({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    // FIX: was using bare GestureDetector + MaterialPageRoute
    // Now: Pressable (scale animation) + buildPageRoute (fade+scale transition)
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
            NetworkImageWidget(url: channel.logo, size: 56),
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
