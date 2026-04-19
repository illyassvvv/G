import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../core/motion.dart';
import 'pressable.dart';
import 'minimal_progress_bar.dart';

class PlayerControls extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onBack;

  const PlayerControls({
    super.key,
    required this.controller,
    required this.onBack,
  });

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  bool _visible = true;

  void _toggle() {
    setState(() => _visible = !_visible);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: Motion.normal,
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: Motion.fast,
              child: Pressable(
                onTap: widget.onBack,
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
          Center(
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: Motion.fast,
              child: Pressable(
                onTap: () {
                  if (widget.controller.value.isPlaying) {
                    widget.controller.pause();
                  } else {
                    widget.controller.play();
                  }
                  setState(() {});
                },
                child: Icon(
                  widget.controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: Motion.fast,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MinimalProgressBar(
                    progress: widget.controller.value.duration.inMilliseconds == 0
                        ? 0
                        : widget.controller.value.position.inMilliseconds /
                            widget.controller.value.duration.inMilliseconds,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}