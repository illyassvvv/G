import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/channel.dart';
import '../models/theme.dart';
import '../providers/app_provider.dart';

/// TV-optimized channel card with focus highlight for D-pad navigation.
class TVChannelCard extends StatefulWidget {
  final Channel channel;
  final AppProvider provider;
  final VoidCallback onSelect;

  const TVChannelCard({
    super.key,
    required this.channel,
    required this.provider,
    required this.onSelect,
  });

  @override
  State<TVChannelCard> createState() => _TVChannelCardState();
}

class _TVChannelCardState extends State<TVChannelCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.provider.colors;
    final isDark = widget.provider.isDark;

    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
             event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          widget.onSelect();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedScale(
          scale: _focused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _focused
                    ? AppTheme.accent.withOpacity(0.9)
                    : isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                width: _focused ? 2.5 : 1),
              gradient: _focused
                  ? LinearGradient(
                      colors: isDark
                          ? [AppTheme.accent.withOpacity(0.18), AppTheme.primaryDeep.withOpacity(0.10)]
                          : [AppTheme.accent.withOpacity(0.12), AppTheme.accent.withOpacity(0.04)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : LinearGradient(
                      colors: isDark
                          ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)]
                          : [Colors.white.withOpacity(0.85), Colors.white.withOpacity(0.65)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: _focused
                  ? [BoxShadow(
                      color: AppTheme.accent.withOpacity(0.4),
                      blurRadius: 20, spreadRadius: -2)]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Channel logo
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(_focused ? 0.12 : 0.06)
                        : Colors.grey.withOpacity(_focused ? 0.12 : 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _focused ? AppTheme.accent.withOpacity(0.5) : Colors.transparent,
                      width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: widget.channel.logoUrl,
                    cacheKey: 'logo_${widget.channel.id}',
                    fit: BoxFit.contain,
                    memCacheWidth: 96, memCacheHeight: 96,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: c.surface2,
                      highlightColor: c.surface2.withOpacity(0.5),
                      child: Container(color: c.surface2)),
                    errorWidget: (_, __, ___) => Icon(Icons.tv_rounded, color: c.textDim, size: 24)),
                ),
                const SizedBox(height: 10),
                // Channel name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(widget.channel.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _focused ? FontWeight.w800 : FontWeight.w600,
                      color: _focused ? AppTheme.accent : c.text,
                      letterSpacing: -0.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center),
                ),
                const SizedBox(height: 4),
                // Channel number badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: _focused ? AppTheme.buttonGradient : null,
                    color: _focused ? null : isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text('CH ${widget.channel.number}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                      color: _focused ? Colors.white : c.textDim, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
