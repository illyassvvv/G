import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../core/theme.dart';
import '../screens/player_screen.dart';
import '../widgets/page_transition.dart';
import '../services/favorites_service.dart';
import 'network_image_widget.dart';
import 'pressable.dart';

class ChannelCard extends StatelessWidget {
  final Channel channel;

  const ChannelCard({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    // Cache every channel we render so FavoritesScreen can look them up
    FavoritesService.cacheChannel(channel);

    return Pressable(
      onTap: () => Navigator.push(
        context,
        buildPageRoute(PlayerScreen(channel: channel)),
      ),
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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Favorite dot indicator
            ValueListenableBuilder<Set<int>>(
              valueListenable: FavoritesService.notifier,
              builder: (_, ids, __) => ids.contains(channel.id)
                  ? const Align(
                      alignment: Alignment.topRight,
                      child: Icon(Icons.favorite_rounded,
                          size: 12, color: AppColors.live),
                    )
                  : const SizedBox(height: 12),
            ),
            NetworkImageWidget(
              url: channel.logoUrl,
              size: 48,
              fallbackIcon: Icons.tv,
            ),
            const SizedBox(height: 8),
            Text(
              channel.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
