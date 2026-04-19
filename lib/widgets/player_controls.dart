import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../services/favorites_service.dart';
import 'pressable.dart';
import 'minimal_progress_bar.dart';

class PlayerControls extends StatefulWidget {
  final VideoPlayerController controller;
  final String channelName;
  final int channelId;
  final bool isFullscreen;
  final VoidCallback onBack;
  final VoidCallback onToggleFullscreen;

  const PlayerControls({
    super.key,
    required this.controller,
    required this.channelName,
    required this.channelId,
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

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final isPlaying = ctrl.value.isPlaying;
    final position = ctrl.value.position;
    final duration = ctrl.value.duration;
    final isLive = duration == Duration.zero;

    final progress = (isLive || duration.inMilliseconds == 0)
        ? 1.0
        : position.inMilliseconds / duration.inMilliseconds;

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Dimmed overlay
          AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: Motion.normal,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC000000),
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xCC000000),
                  ],
                  stops: [0, 0.25, 0.75, 1],
                ),
              ),
            ),
          ),

          // ── TOP BAR ─────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: Motion.fast,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Back
                      _ControlButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: widget.onBack,
                      ),
                      const SizedBox(width: 8),
                      // Channel name
                      Expanded(
                        child: Text(
                          widget.channelName,
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
                      // Favorite
                      ValueListenableBuilder<Set<int>>(
                        valueListenable: FavoritesService.notifier,
                        builder: (_, ids, __) {
                          final isFav = ids.contains(widget.channelId);
                          return _ControlButton(
                            icon: isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFav ? AppColors.live : Colors.white,
                            onTap: () =>
                                FavoritesService.toggle(widget.channelId),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── CENTER PLAY/PAUSE ────────────────────────────────
          Center(
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: Motion.fast,
              child: Pressable(
                onTap: () {
                  isPlaying ? ctrl.pause() : ctrl.play();
                  _scheduleHide();
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),

          // ── BOTTOM BAR ──────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: Motion.fast,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress bar + time
                      Row(
                        children: [
                          // Elapsed time
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onHorizontalDragUpdate: isLive
                                  ? null
                                  : (d) {
                                      final box = context.findRenderObject()
                                          as RenderBox?;
                                      if (box == null) return;
                                      final pct =
                                          d.localPosition.dx / box.size.width;
                                      final target = duration * pct.clamp(0, 1);
                                      ctrl.seekTo(target);
                                      _scheduleHide();
                                    },
                              child: MinimalProgressBar(progress: progress),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Duration or LIVE badge
                          isLive
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.live,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('LIVE',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6)),
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
                      const SizedBox(height: 8),
                      // Action row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Fullscreen toggle
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
        ],
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
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
