import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/favorites_service.dart';
import '../widgets/app_backdrop.dart';
import '../widgets/channel_card.dart';
import '../widgets/slide_fade_transition.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        dark ? AppColors.textSecondary : AppColors.textSecondaryLight;

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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface.withOpacity(0.72),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Icon(
                          Icons.favorite_border_rounded,
                          size: 40,
                          color: textSecondary.withOpacity(0.55),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'No favorites yet',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap ♡ in the player to save a channel',
                        style: TextStyle(
                          color: textSecondary.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
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
