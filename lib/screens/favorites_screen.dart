import 'package:flutter/material.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../services/favorites_service.dart';
import '../widgets/app_backdrop.dart';
import '../widgets/channel_card.dart';
import '../widgets/premium_surface.dart';
import '../widgets/slide_fade_transition.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = dark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final textPrimary = dark ? AppColors.textPrimary : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackdrop(
        child: ValueListenableBuilder<Set<int>>(
          valueListenable: FavoritesService.notifier,
          builder: (context, __, ___) {
            final channels = FavoritesService.favoriteChannels;

            if (channels.isEmpty) {
              return Center(
                child: SlideFade(
                  beginOffset: 8,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: PremiumSurface(
                      glass: true,
                      blur: 16,
                      borderRadius: BorderRadius.circular(32),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.26),
                                  AppColors.primary.withOpacity(0.08),
                                  Colors.transparent,
                                ],
                              ),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Icon(
                              Icons.favorite_border_rounded,
                              size: 42,
                              color: textSecondary.withOpacity(0.68),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'No favorites yet',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the heart in the player to save a channel and bring it back here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textSecondary.withOpacity(0.86),
                              fontSize: 12.5,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: channels.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.84,
              ),
              itemBuilder: (_, i) => SlideFade(
                delay: Duration(milliseconds: 40 + (i * 40)),
                child: ChannelCard(channel: channels[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}
