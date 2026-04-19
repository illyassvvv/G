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
    final dark = Theme.of(context).brightness == Brightness.dark;

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
          overlayColor: dark
              ? const Color(0xFF121826)
              : const Color(0xFFFFFFFF),
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.22 : 0.08),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
          child: Stack(
            children: [
              Positioned(
                top: -18,
                right: -18,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(dark ? 0.16 : 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Align(
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
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 2),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: dark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.black.withOpacity(0.025),
                      border: Border.all(
                        color: dark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(dark ? 0.18 : 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: NetworkImageWidget(
                        url: channel.logoUrl,
                        size: 46,
                        fallbackIcon: Icons.tv,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    channel.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: dark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      height: 1.22,
                      letterSpacing: 0.05,
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
