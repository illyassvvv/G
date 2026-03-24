import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../models/channel.dart';
import '../models/theme.dart';
import '../providers/app_provider.dart';

/// A channel card that listens to a [ValueNotifier<int?>] for the active
/// channel ID. Only the cards whose active state actually changes will
/// rebuild — the rest of the widget tree (including the heavy video player)
/// is untouched. This eliminates the "Sticky Green Color" lag.
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
    final isDark = provider.isDark;
    return GestureDetector(
      onTap: onTap,
      // Only rebuild when the active ID changes — O(1) check per card
      child: ValueListenableBuilder<int?>(
        valueListenable: activeChannelNotifier,
        builder: (_, activeId, __) {
          final isActive = activeId == channel.id;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isActive
                    ? AppTheme.accent.withOpacity(0.7)
                    : isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06),
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.25),
                        blurRadius: 24,
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.08),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: c.shadow,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: isDark ? 16 : 8,
                  sigmaY: isDark ? 16 : 8,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            colors: isDark
                                ? [
                                    AppTheme.accent.withOpacity(0.12),
                                    AppTheme.greenDim.withOpacity(0.06),
                                  ]
                                : [
                                    AppTheme.accent.withOpacity(0.08),
                                    AppTheme.accent.withOpacity(0.02),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: isDark
                                ? [
                                    Colors.white.withOpacity(0.05),
                                    Colors.white.withOpacity(0.02),
                                  ]
                                : [
                                    Colors.white.withOpacity(0.85),
                                    Colors.white.withOpacity(0.65),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Logo + name ──────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                        child: Row(children: [
                          // Logo container with subtle glow when active
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(isActive ? 0.1 : 0.06)
                                  : Colors.grey.withOpacity(isActive ? 0.1 : 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isActive
                                    ? AppTheme.accent.withOpacity(0.4)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: isActive
                                  ? [BoxShadow(
                                      color: AppTheme.accent.withOpacity(0.15),
                                      blurRadius: 12,
                                    )]
                                  : [],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CachedNetworkImage(
                              imageUrl: channel.logoUrl,
                              cacheKey: 'logo_${channel.id}',
                              fit: BoxFit.contain,
                              memCacheWidth: 96,
                              memCacheHeight: 96,
                              fadeInDuration: const Duration(milliseconds: 150),
                              fadeOutDuration: const Duration(milliseconds: 100),
                              useOldImageOnUrlChange: true,
                              placeholder: (_, __) => Shimmer.fromColors(
                                baseColor: c.surface2,
                                highlightColor: c.surface2.withOpacity(0.5),
                                child: Container(color: c.surface2),
                              ),
                              errorWidget: (_, __, ___) => Icon(
                                Icons.tv_rounded, color: c.textDim, size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(channel.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: c.text,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 5),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: isActive
                                      ? AppTheme.goldGradient
                                      : null,
                                  color: isActive
                                      ? null
                                      : isDark
                                          ? Colors.white.withOpacity(0.06)
                                          : Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('CH ${channel.number}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? Colors.black
                                        : c.textDim,
                                    letterSpacing: 0.5,
                                  )),
                              ),
                            ],
                          )),
                        ]),
                      ),

                      const Spacer(),

                      // ── Live + play indicator ──────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Live indicator or equalizer
                            isActive
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _MiniEqualizer(
                                        color: AppTheme.accent,
                                        barCount: 3,
                                        width: 14,
                                        height: 12,
                                      ),
                                      const SizedBox(width: 6),
                                      Text('يعمل الآن',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.accent,
                                        )),
                                    ],
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _PulseDot(color: c.textDim),
                                      const SizedBox(width: 5),
                                      Text('مباشر',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: c.textDim,
                                        )),
                                    ],
                                  ),
                            // Play/Pause button
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? AppTheme.goldGradient
                                    : null,
                                color: isActive
                                    ? null
                                    : isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.black.withOpacity(0.06),
                                shape: BoxShape.circle,
                                boxShadow: isActive
                                    ? [BoxShadow(
                                        color: AppTheme.accent.withOpacity(0.3),
                                        blurRadius: 8,
                                      )]
                                    : [],
                              ),
                              child: Icon(
                                isActive
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 17,
                                color: isActive
                                    ? Colors.black
                                    : c.textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    )
        .animate(delay: Duration(milliseconds: 55 * index))
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.18, end: 0, duration: 280.ms, curve: Curves.easeOut);
  }
}

// ── Mini Equalizer (playing indicator) ────────────────────────
class _MiniEqualizer extends StatefulWidget {
  final Color color;
  final int barCount;
  final double width;
  final double height;
  const _MiniEqualizer({
    required this.color,
    this.barCount = 3,
    this.width = 14,
    this.height = 12,
  });
  @override
  State<_MiniEqualizer> createState() => _MiniEqualizerState();
}

class _MiniEqualizerState extends State<_MiniEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barW = widget.width / (widget.barCount * 2 - 1);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.barCount, (i) {
              final phase = (i / widget.barCount + _ctrl.value) % 1.0;
              final h = (0.3 + 0.7 * _barCurve(phase)) * widget.height;
              return Container(
                width: barW,
                height: h,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(barW / 2),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  double _barCurve(double t) {
    return (1 + (2 * 3.14159 * t).abs() % 1.0) / 2.0;
  }
}

// ── Pulse dot ─────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(
      width: 6, height: 6,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}

// ── Shimmer skeleton card ─────────────────────────────────────
class ChannelCardSkeleton extends StatelessWidget {
  final AppProvider provider;
  const ChannelCardSkeleton({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final c = provider.colors;
    final isDark = provider.isDark;
    return Shimmer.fromColors(
      baseColor: c.surface2,
      highlightColor: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.white.withOpacity(0.8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 48, height: 48,
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(14),
              )),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 13, width: double.infinity,
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(6),
                  )),
                const SizedBox(height: 8),
                Container(height: 10, width: 50,
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(6),
                  )),
              ],
            )),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(height: 10, width: 50,
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(5),
              )),
            Container(width: 32, height: 32,
              decoration: BoxDecoration(
                color: c.surface2,
                shape: BoxShape.circle,
              )),
          ]),
        ]),
      ),
    );
  }
}
