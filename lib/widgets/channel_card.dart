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
    return Pressable(
      onTap: () => Navigator.push(
        context,
        buildPageRoute(PlayerScreen(channel: channel)),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface.withOpacity(0.96),
              AppColors.surfaceElevated.withOpacity(0.9),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.24),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Positioned(
              top: -10,
              right: -10,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.08),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 12, height: 12),
                    ValueListenableBuilder<Set<int>>(
                      valueListenable: FavoritesService.notifier,
                      builder: (_, ids, __) => ids.contains(channel.id)
                          ? const Icon(Icons.favorite_rounded,
                              size: 12, color: AppColors.live)
                          : const SizedBox(width: 12, height: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Hero(
                  tag: 'channel-logo-${channel.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: NetworkImageWidget(
                      url: channel.logoUrl,
                      size: 48,
                      fallbackIcon: Icons.tv,
                    ),
                  ),
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
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
