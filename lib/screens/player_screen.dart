import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isFullscreen = false;
  int _initToken = 0;

  static const _streamHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/139.0.0.0 Safari/537.36',
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.9,ar;q=0.8',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
    'Origin': 'https://www.beinsports.com',
    'Referer': 'https://www.beinsports.com/',
  };

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _init();
  }

  Future<void> _restoreSystemUi() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _init() async {
    final streamUri = Uri.tryParse(widget.channel.streamUrl);
    if (streamUri == null ||
        !(streamUri.scheme == 'http' || streamUri.scheme == 'https')) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
      return;
    }

    final previous = _controller;
    _controller = null;
    await previous?.dispose();

    final token = ++_initToken;
    final controller = VideoPlayerController.networkUrl(
      streamUri,
      httpHeaders: _streamHeaders,
      videoPlayerOptions: const VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
    );
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted || token != _initToken) {
        await controller.dispose();
        return;
      }
      await controller.play();
      if (!mounted || token != _initToken) return;
      setState(() => _loading = false);
    } catch (_) {
      await controller.dispose();
      if (!mounted || token != _initToken) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _toggleFullscreen() async {
    final entering = !_isFullscreen;
    if (mounted) {
      setState(() => _isFullscreen = entering);
    }

    if (entering) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await _restoreSystemUi();
    }
  }

  Future<void> _pop() async {
    await _restoreSystemUi();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _initToken++;
    _controller?.dispose();
    _restoreSystemUi();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          _restoreSystemUi();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _loading
            ? _buildLoading()
            : _error
                ? _buildError()
                : _buildPlayer(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          const SizedBox(height: 20),
          Text(
            widget.channel.name,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.signal_wifi_off_rounded,
                color: Colors.white30, size: 64),
            const SizedBox(height: 20),
            const Text(
              'Stream unavailable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.channel.name,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 32),
            _ErrorButton(
              icon: Icons.arrow_back_rounded,
              label: 'Go Back',
              onTap: _pop,
              primary: true,
            ),
            const SizedBox(height: 12),
            _ErrorButton(
              icon: Icons.refresh_rounded,
              label: 'Retry',
              onTap: () {
                setState(() {
                  _loading = true;
                  _error = false;
                });
                _init();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    final controller = _controller;
    if (controller == null) {
      return _buildLoading();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
        PlayerControls(
          controller: controller,
          channel: widget.channel,
          isFullscreen: _isFullscreen,
          onBack: _pop,
          onToggleFullscreen: _toggleFullscreen,
        ),
      ],
    );
  }
}

class _ErrorButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _ErrorButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: primary ? Colors.white : Colors.white12,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: primary ? Colors.black : Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: primary ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
