import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../models/channel.dart';
import '../models/theme.dart';
import '../providers/app_provider.dart';

class ChannelCard extends StatefulWidget {
  final Channel channel;
  final ValueNotifier<int?> activeChannelNotifier;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;
  final int index;
  final AppProvider provider;

  const ChannelCard({
    super.key,
    required this.channel,
    required this.activeChannelNotifier,
    required this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
    required this.index,
    required this.provider,
  });

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final c = widget.provider.colors;
    final isDark = widget.provider.isDark;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: ValueListenableBuilder<int?>(
          valueListenable: widget.activeChannelNotifier,
          builder: (_, activeId, __) {
            final isActive = activeId == widget.channel.id;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isActive ? AppTheme.accent.withOpacity(0.7)
                      : isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                  width: isActive ? 1.5 : 1)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? LinearGradient(
                              colors: isDark
                                  ? [AppTheme.accent.withOpacity(0.14), AppTheme.primaryDeep.withOpacity(0.08)]
                                  : [AppTheme.accent.withOpacity(0.10), AppTheme.accent.withOpacity(0.03)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight)
                          : LinearGradient(
                              colors: isDark
                                  ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
                                  : [Colors.white.withOpacity(0.85), Colors.white.withOpacity(0.65)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(21)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 10, 8),
                          child: Row(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              width: 46, height: 46,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(isActive ? 0.1 : 0.06)
                                    : Colors.grey.withOpacity(isActive ? 0.1 : 0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isActive ? AppTheme.accent.withOpacity(0.4) : Colors.transparent, width: 1.5),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CachedNetworkImage(
                                imageUrl: widget.channel.logoUrl,
                                cacheKey: 'logo_${widget.channel.id}',
                                fit: BoxFit.contain, memCacheWidth: 96, memCacheHeight: 96,
                                fadeInDuration: const Duration(milliseconds: 150),
                                fadeOutDuration: const Duration(milliseconds: 100),
                                useOldImageOnUrlChange: true,
                                placeholder: (_, __) => Shimmer.fromColors(
                                  baseColor: c.surface2, highlightColor: c.surface2.withOpacity(0.5),
                                  child: Container(color: c.surface2)),
                                errorWidget: (_, __, ___) => Icon(Icons.tv_rounded, color: c.textDim, size: 22))),
                            const SizedBox(width: 10),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.channel.name,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text, letterSpacing: -0.2),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: isActive ? AppTheme.buttonGradient : null,
                                    color: isActive ? null : isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(7)),
                                  child: Text('CH ${widget.channel.number}',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600,
                                      color: isActive ? Colors.white : c.textDim, letterSpacing: 0.5))),
                              ])),
                            if (widget.onFavoriteToggle != null)
                              GestureDetector(
                                onTap: widget.onFavoriteToggle,
                                child: Padding(padding: const EdgeInsets.all(6),
                                  child: Icon(widget.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                                    size: 20, color: widget.isFavorite ? const Color(0xFFFBBF24) : c.textDim.withOpacity(0.5)))),
                          ])),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              isActive
                                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                                      SmoothEqualizer(color: AppTheme.accent, barCount: 3, width: 14, height: 12),
                                      const SizedBox(width: 6),
                                      const Text('NOW PLAYING',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.accent, letterSpacing: 0.8))])
                                  : LiveBadge(isDark: isDark),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  gradient: isActive ? AppTheme.buttonGradient : null,
                                  color: isActive ? null : isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
                                  shape: BoxShape.circle),
                                child: Icon(isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 18, color: isActive ? Colors.white : isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.7))),
                            ])),
                      ]))));
          },
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 50 * widget.index))
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.15, end: 0, duration: 280.ms, curve: Curves.easeOut);
  }
}

class LiveBadge extends StatelessWidget {
  final bool isDark;
  const LiveBadge({super.key, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppTheme.live.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.live.withOpacity(0.25), width: 0.5)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      PulseDot(color: AppTheme.live, size: 6),
      const SizedBox(width: 4),
      const Text('LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.live, letterSpacing: 1)),
    ]));
}

/// Smooth equalizer bars with staggered scaleY animation.
/// Smooth sinusoidal looping - no jumps or zig-zag.
class SmoothEqualizer extends StatefulWidget {
  final Color color;
  final int barCount;
  final double width;
  final double height;
  const SmoothEqualizer({
    super.key,
    required this.color,
    this.barCount = 3,
    this.width = 14,
    this.height = 12,
  });
  @override
  State<SmoothEqualizer> createState() => _SmoothEqualizerState();
}

class _SmoothEqualizerState extends State<SmoothEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
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
      builder: (_, __) => SizedBox(
        width: widget.width,
        height: widget.height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.barCount, (i) {
            // Staggered phase offsets per bar for natural feel
            final staggerDelay = i * 0.3;
            final phase = (_ctrl.value + staggerDelay) * 2 * pi;
            final normalized = (sin(phase) + 1) / 2;
            final h = (0.3 + 0.7 * normalized) * widget.height;
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
      ),
    );
  }
}

/// Legacy alias for backward compatibility
class MiniEqualizer extends SmoothEqualizer {
  const MiniEqualizer({
    super.key,
    required super.color,
    super.barCount = 3,
    super.width = 14,
    super.height = 12,
  });
}

class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulseDot({super.key, required this.color, this.size = 6});
  @override State<PulseDot> createState() => _PulseDotState();
}
class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  @override void initState() { super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => FadeTransition(opacity: _anim,
    child: Container(width: widget.size, height: widget.size,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)));
}

class ChannelCardSkeleton extends StatelessWidget {
  final AppProvider provider;
  const ChannelCardSkeleton({super.key, required this.provider});
  @override
  Widget build(BuildContext context) {
    final c = provider.colors;
    final isDark = provider.isDark;
    return Shimmer.fromColors(
      baseColor: c.surface2,
      highlightColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06))),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(14))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 13, width: double.infinity, decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(6))),
              const SizedBox(height: 8),
              Container(height: 10, width: 50, decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(6))),
            ]))]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(height: 10, width: 50, decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(5))),
            Container(width: 34, height: 34, decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle)),
          ])])));
  }
}
