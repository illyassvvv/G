import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../models/channel.dart';
import '../services/favorites_service.dart';
import 'minimal_progress_bar.dart';
import 'network_image_widget.dart';
import 'pressable.dart';
import 'premium_surface.dart';

class PlayerControls extends StatefulWidget {
  final VideoPlayerController controller;
  final Channel channel;
  final bool isFullscreen;
  final VoidCallback onBack;
  final VoidCallback onToggleFullscreen;

  const PlayerControls({
    super.key,
    required this.controller,
    required this.channel,
    required this.isFullscreen,
    required this.onBack,
    required this.onToggleFullscreen,
  });

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  bool _visible = true;
  Timer? _hideTimer;
  Duration? _pendingSeek;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && widget.controller.value.isPlaying) {
        setState(() => _visible = false);
      }
    });
  }

  void _onTap() {
    setState(() => _visible = !_visible);
    if (_visible) _scheduleHide();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startSeek(double positionFraction, Duration duration) {
    final bounded = positionFraction.clamp(0.0, 1.0);
    _pendingSeek = duration * bounded;
    setState(() {});
  }

  Future<void> _commitSeek() async {
    final seekTarget = _pendingSeek;
    _pendingSeek = null;
    if (seekTarget != null) {
      await widget.controller.seekTo(seekTarget);
    }
    if (mounted) setState(() {});
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final isPlaying = value.isPlaying;
        final position = value.position;
        final duration = value.duration;
        final isLive = duration == Duration.zero;
        final displayedPosition = _pendingSeek ?? position;
        final progress = (isLive || duration.inMilliseconds == 0)
            ? 1.0
            : displayedPosition.inMilliseconds / duration.inMilliseconds;

        return GestureDetector(
          onTap: _onTap,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: _visible ? 1 : 0,
                  duration: Motion.normal,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x99000000),
                          Colors.transparent,
                          Colors.transparent,
                          Color(0xAA000000),
                        ],
                        stops: [0, 0.18, 0.76, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: AnimatedSlide(
                    offset: _visible ? Offset.zero : const Offset(0, -0.06),
                    duration: Motion.normal,
                    curve: Motion.emphasized,
                    child: AnimatedOpacity(
                      opacity: _visible ? 1 : 0,
                      duration: Motion.fast,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: _GlassPanel(
                          child: Row(
                            children: [
                              _ControlButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: widget.onBack,
                              ),
                              const SizedBox(width: 8),
                              if (widget.channel.logoUrl.isNotEmpty)
                                Hero(
                                  tag: 'channel-logo-${widget.channel.id}',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: NetworkImageWidget(
                                        url: widget.channel.logoUrl,
                                        size: 26,
                                        fallbackIcon: Icons.tv,
                                      ),
                                    ),
                                  ),
                                ),
                              if (widget.channel.logoUrl.isNotEmpty)
                                const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.channel.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(color: Colors.black54, blurRadius: 8)
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ValueListenableBuilder<Set<int>>(
                                valueListenable: FavoritesService.notifier,
                                builder: (_, ids, __) {
                                  final isFav = ids.contains(widget.channel.id);
                                  return _ControlButton(
                                    icon: isFav
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isFav ? AppColors.live : Colors.white,
                                    onTap: () =>
                                        FavoritesService.toggle(widget.channel),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: AnimatedOpacity(
                  opacity: _visible ? 1 : 0,
                  duration: Motion.fast,
                  child: AnimatedScale(
                    scale: _visible ? 1.0 : 0.92,
                    duration: Motion.fast,
                    curve: Motion.spring,
                    child: Pressable(
                      onTap: () {
                        isPlaying
                            ? widget.controller.pause()
                            : widget.controller.play();
                        _scheduleHide();
                      },
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.42),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.24),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: AnimatedSlide(
                    offset: _visible ? Offset.zero : const Offset(0, 0.06),
                    duration: Motion.normal,
                    curve: Motion.emphasized,
                    child: AnimatedOpacity(
                      opacity: _visible ? 1 : 0,
                      duration: Motion.fast,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: PremiumSurface(
                          glass: true,
                          blur: 16,
                          borderRadius: BorderRadius.circular(26),
                          overlayColor: Colors.black.withOpacity(0.16),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _formatDuration(displayedPosition),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return GestureDetector(
                                            onHorizontalDragUpdate: isLive
                                                ? null
                                                : (d) {
                                                    final width =
                                                        constraints.maxWidth;
                                                    if (width <= 0) return;
                                                    _startSeek(
                                                      d.localPosition.dx / width,
                                                      duration,
                                                    );
                                                  },
                                            onHorizontalDragEnd: isLive
                                                ? null
                                                : (_) {
                                                    unawaited(_commitSeek());
                                                  },
                                            child: MinimalProgressBar(
                                              progress: progress,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    isLive
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.live,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: const Text(
                                              'LIVE',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.6,
                                              ),
                                            ),
                                          )
                                        : Text(
                                            _formatDuration(duration),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _ControlButton(
                                      icon: widget.isFullscreen
                                          ? Icons.fullscreen_exit_rounded
                                          : Icons.fullscreen_rounded,
                                      onTap: widget.onToggleFullscreen,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;

  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.22),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
