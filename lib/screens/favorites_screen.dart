import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/channel.dart';
import '../services/favorites_service.dart';
import '../widgets/channel_card.dart';
import '../widgets/slide_fade_transition.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ValueListenableBuilder<Set<int>>(
        valueListenable: FavoritesService.notifier,
        builder: (context, ids, _) {
          final channels = FavoritesService.favoriteChannels;

          if (channels.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border_rounded,
                      size: 56,
                      color: AppColors.textSecondary.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text(
                    'No favorites yet',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap ♡ in the player to save a channel',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
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
              childAspectRatio: 0.85,
            ),
            itemBuilder: (_, i) => SlideFade(
              child: ChannelCard(channel: channels[i]),
            ),
          );
        },
      ),
    );
  }
}
