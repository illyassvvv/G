import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../models/channel.dart';
import '../models/theme.dart';
import '../providers/app_provider.dart';

class ChannelCard extends StatelessWidget {
  final Channel channel;
  final bool isActive;
  final VoidCallback onTap;
  final int index;
  final AppProvider provider;

  const ChannelCard({
    super.key,
    required this.channel,
    required this.isActive,
    required this.onTap,
    required this.index,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final c = provider.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isActive ? null : c.card,
          gradient: isActive
              ? LinearGradient(colors: [
                  c.card,
                  AppTheme.greenDim.withOpacity(0.25),
                ], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? AppTheme.accent : c.border,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(color: AppTheme.accent.withOpacity(0.15), blurRadius: 20),
                  BoxShadow(color: AppTheme.green.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 8)),
                ]
              : [BoxShadow(color: c.shadow, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Logo + name ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(children: [
              // Logo with shimmer placeholder
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? AppTheme.accent.withOpacity(0.3) : Colors.transparent,
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: channel.logoUrl,
                  fit: BoxFit.contain,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  memCacheWidth: 200,
                  placeholder: (_, __) => Icon(
                    Icons.tv_rounded, color: c.textDim.withOpacity(0.3), size: 22,
                  ),
                  errorWidget: (_, __, ___) => Icon(
                    Icons.tv_rounded, color: c.textDim, size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Name + CH badge
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(channel.name,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.text),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: isActive ? AppTheme.accentGradient : null,
                      color: isActive ? null : c.surface2,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('CH ${channel.number}',
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: isActive ? Colors.black : c.textDim,
                      )),
                  ),
                ],
              )),
            ]),
          ),

          // ── Live + play button ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  _PulseDot(color: isActive ? AppTheme.green : c.textDim),
                  const SizedBox(width: 5),
                  Text('مباشر',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: isActive ? AppTheme.green : c.textDim,
                    )),
                ]),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? AppTheme.accentGradient
                        : LinearGradient(colors: [c.surface2, c.surface2]),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 17,
                    color: isActive ? Colors.black : c.textDim,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    )
        .animate(delay: Duration(milliseconds: 55 * index))
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.18, end: 0, duration: 280.ms, curve: Curves.easeOut);
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
    return Shimmer.fromColors(
      baseColor: c.surface2,
      highlightColor: c.surface,
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(12))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 12, width: double.infinity, color: c.surface2),
              const SizedBox(height: 6),
              Container(height: 10, width: 50, color: c.surface2),
            ])),
          ]),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(height: 10, width: 50, color: c.surface2),
            Container(width: 30, height: 30, decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle)),
          ]),
        ]),
      ),
    );
  }
}
