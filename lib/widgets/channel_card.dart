import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/channel.dart';
import '../models/theme.dart';

class ChannelCard extends StatelessWidget {
  final Channel channel;
  final bool isActive;
  final VoidCallback onTap;
  final int index;

  const ChannelCard({super.key, required this.channel, required this.isActive, required this.onTap, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: isActive
            ? LinearGradient(colors: [AppTheme.card, AppTheme.greenDim.withOpacity(0.3)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
          color: isActive ? null : AppTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isActive ? AppTheme.accent : AppTheme.border, width: isActive ? 1.5 : 1),
          boxShadow: isActive ? [
            BoxShadow(color: AppTheme.accent.withOpacity(0.15), blurRadius: 20),
            BoxShadow(color: AppTheme.green.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 10)),
          ] : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surface2, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isActive ? AppTheme.accent.withOpacity(0.3) : Colors.transparent, width: 1)),
                padding: const EdgeInsets.all(6),
                child: CachedNetworkImage(imageUrl: channel.logoUrl, fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => const Icon(Icons.tv_rounded, color: AppTheme.textDim, size: 22))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(channel.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.text), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: isActive ? AppTheme.goldGradient : null,
                    color: isActive ? null : AppTheme.surface2,
                    borderRadius: BorderRadius.circular(6)),
                  child: Text('CH ${channel.number}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isActive ? Colors.black : AppTheme.textDim))),
              ])),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                _LiveDot(active: isActive), const SizedBox(width: 5),
                Text('مباشر', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: isActive ? AppTheme.green : AppTheme.textDim)),
              ]),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200), width: 30, height: 30,
                decoration: BoxDecoration(
                  gradient: isActive ? AppTheme.goldGradient : const LinearGradient(colors: [AppTheme.surface2, AppTheme.surface2]),
                  shape: BoxShape.circle),
                child: Icon(isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 17, color: isActive ? Colors.black : AppTheme.textDim)),
            ]),
          ),
        ]),
      ),
    ).animate(delay: Duration(milliseconds: 60 * index)).fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}

class _LiveDot extends StatefulWidget {
  final bool active;
  const _LiveDot({required this.active});
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _anim,
      child: Container(width: 6, height: 6,
        decoration: BoxDecoration(color: widget.active ? AppTheme.green : AppTheme.textDim, shape: BoxShape.circle)));
  }
}
