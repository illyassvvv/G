import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../models/channel.dart';
import '../models/theme.dart';
import '../providers/app_provider.dart';

/// Poster-style channel card inspired by premium streaming apps.
/// Tall card with centered logo, channel name below, and subtle
/// active glow. Listens to [ValueNotifier<int?>] for instant UI
/// feedback without rebuilding the widget tree.
class ChannelCard extends StatelessWidget {
  final Channel channel;
  final ValueNotifier<int?> activeChannelNotifier;
  final VoidCallback onTap;
  final int index;
  final AppProvider provider;

  const ChannelCard({
    super.key,
    required this.channel,
    required this.activeChannelNotifier,
    required this.onTap,
    required this.index,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final c = provider.colors;
    return GestureDetector(
      onTap: onTap,
      child: ValueListenableBuilder<int?>(
        valueListenable: activeChannelNotifier,
        builder: (_, activeId, __) {
          final isActive = activeId == channel.id;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Poster card ────────────────────────────────────
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? AppTheme.accent.withOpacity(0.7)
                          : Colors.transparent,
                      width: isActive ? 2 : 0,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppTheme.accent.withOpacity(0.2),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: Stack(
                    children: [
                      // Logo — centered and prominent
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: CachedNetworkImage(
                            imageUrl: channel.logoUrl,
                            cacheKey: 'logo_${channel.id}',
                            fit: BoxFit.contain,
                            memCacheWidth: 200,
                            memCacheHeight: 200,
                            fadeInDuration: const Duration(milliseconds: 150),
                            fadeOutDuration: const Duration(milliseconds: 100),
                            useOldImageOnUrlChange: true,
                            placeholder: (_, __) => Shimmer.fromColors(
                              baseColor: c.surface2,
                              highlightColor: c.surface2.withOpacity(0.4),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: c.surface2,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Icon(
                              Icons.live_tv_rounded,
                              color: c.textDim.withOpacity(0.5),
                              size: 36,
                            ),
                          ),
                        ),
                      ),

                      // Channel number badge — top left
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.accent.withOpacity(0.9)
                                : Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            channel.number,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isActive ? Colors.black : Colors.white70,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ),

                      // Live dot — top right (active only)
                      if (isActive)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.green,
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Play overlay — bottom right (active only)
                      if (isActive)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              gradient: AppTheme.goldGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Channel name below card ────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 2, right: 2),
                child: Text(
                  channel.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? c.text : c.textDim,
                    fontFamily: 'Cairo',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    )
        .animate(delay: Duration(milliseconds: 40 * index))
        .fadeIn(duration: 250.ms)
        .scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1, 1),
            duration: 250.ms);
  }
}

// ── Shimmer skeleton card (poster style) ──────────────────────
class ChannelCardSkeleton extends StatelessWidget {
  final AppProvider provider;
  const ChannelCardSkeleton({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final c = provider.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Shimmer.fromColors(
            baseColor: c.surface2,
            highlightColor: c.surface,
            child: Container(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Shimmer.fromColors(
          baseColor: c.surface2,
          highlightColor: c.surface,
          child: Container(
            height: 10,
            width: 60,
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}
