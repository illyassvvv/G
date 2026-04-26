import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/channel.dart';
import '../screens/player_screen.dart';
import '../services/favorites_service.dart';
import '../widgets/page_transition.dart';
import '../widgets/premium_surface.dart';
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
      child: Hero(
        tag: 'channel-card-${channel.id}',
        child: PremiumSurface(
          borderRadius: BorderRadius.circular(26),
          padding: const EdgeInsets.all(14),
          overlayColor: Colors.white.withOpacity(0.02),
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
          child: Stack(
            children: [
              Positioned(
                top: -18,
                right: -18,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.10),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.03),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: ValueListenableBuilder<Set<int>>(
                      valueListenable: FavoritesService.notifier,
                      builder: (_, ids, __) => AnimatedOpacity(
                        opacity: ids.contains(channel.id) ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 12,
                          color: AppColors.live,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Hero(
                    tag: 'channel-logo-${channel.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: NetworkImageWidget(
                        url: channel.logoUrl,
                        size: 50,
                        fallbackIcon: Icons.tv_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    channel.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.25,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
