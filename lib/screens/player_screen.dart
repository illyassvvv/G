import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/channel.dart';
import '../widgets/player_controls.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;

  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.channel.streamUrl));
      _controller = controller;
      await controller.initialize();
      controller.play();
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? const Center(
                  child: Text(
                    'Failed to load stream',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Stack(
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                    PlayerControls(
                      controller: _controller!,
                      onBack: () => Navigator.pop(context),
                    ),
                  ],
                ),
    );
  }
}