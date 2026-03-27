import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/channel.dart';
import '../services/stream_resolver_service.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  final List<Channel> channelList;

  const PlayerScreen({
    super.key,
    required this.channel,
    this.channelList = const [],
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with WidgetsBindingObserver {
  VideoPlayerController? _ctrl;
  bool _loading = true;
  bool _hasError = false;
  bool _showControls = true;
  Timer? _hideTimer;
  Timer? _loadingTimeout;
  late Channel _currentChannel;
  int _retryCount = 0;
  static const _maxRetries = 3;
  static const _loadingTimeoutDuration = Duration(seconds: 25);

  final FocusNode _playerFocus = FocusNode();
  bool _isPopping = false;
  bool _disposed = false;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentChannel = widget.channel;
    _startPlayer();
    _scheduleHideControls();
  }

  void _startPlayer() {
    _cancelLoadingTimeout();

    final oldCtrl = _ctrl;
    _ctrl = null;
    if (oldCtrl != null) {
      oldCtrl.removeListener(_playerListener);
      oldCtrl.dispose();
    }

    if (mounted) setState(() { _loading = true; _hasError = false; });

    debugPrint('[VargasTV] Starting player for: ${_currentChannel.name}');
    debugPrint('[VargasTV] Stream URL: ${_currentChannel.streamUrl}');
    debugPrint('[VargasTV] Platform: ${Platform.operatingSystem}');

    // Resolve token/redirect URLs before passing to the player
    _resolveAndPlay(_currentChannel.streamUrl);
  }

  Future<void> _resolveAndPlay(String originalUrl) async {
    try {
      final resolved = await StreamResolverService.resolveStreamUrl(originalUrl);
      if (_disposed || !mounted) return;

      debugPrint('[VargasTV] Resolved URL: ${resolved.url}');

      // Merge resolved headers with default Android TV headers
      final Map<String, String> streamHeaders = {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Android TV) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/120.0.0.0 Safari/537.36',
        'Accept': '*/*',
        'Connection': 'keep-alive',
        if (resolved.headers != null) ...resolved.headers!,
      };

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(resolved.url),
        httpHeaders: streamHeaders,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );

      _ctrl = controller;

      controller.initialize().then((_) {
        if (_disposed || !mounted) return;
        debugPrint('[VargasTV] Player initialized successfully');
        controller.play();
        _cancelLoadingTimeout();
        setState(() { _loading = false; _hasError = false; _retryCount = 0; });
      }).catchError((error) {
        if (_disposed || !mounted) return;
        debugPrint('[VargasTV] Player initialization error: $error');
        _cancelLoadingTimeout();
        setState(() { _loading = false; _hasError = true; });
        _autoRetry();
      });

      controller.addListener(_playerListener);

      _startLoadingTimeout();
      if (mounted) setState(() {});
    } catch (e) {
      if (_disposed || !mounted) return;
      debugPrint('[VargasTV] Stream resolution failed: $e');
      setState(() { _loading = false; _hasError = true; });
      _autoRetry();
    }
  }

  void _playerListener() {
    if (_disposed || !mounted || _ctrl == null) return;
    final value = _ctrl!.value;

    if (value.hasError) {
      debugPrint('[VargasTV] Playback error: ${value.errorDescription}');
      if (!_hasError) {
        _cancelLoadingTimeout();
        setState(() { _loading = false; _hasError = true; });
        _autoRetry();
      }
    } else if (value.isPlaying && _loading) {
      _cancelLoadingTimeout();
      setState(() { _loading = false; _hasError = false; _retryCount = 0; });
    } else if (value.isBuffering && !_loading && !_hasError) {
      setState(() { _loading = true; });
    } else if (!value.isBuffering && _loading && !_hasError && value.isInitialized) {
      setState(() { _loading = false; });
    }
  }

  void _switchToChannel(Channel ch) {
    if (ch.id == _currentChannel.id) return;
    _cancelLoadingTimeout();
    setState(() {
      _currentChannel = ch;
      _loading = true;
      _hasError = false;
      _retryCount = 0;
    });
    _startPlayer();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Only handle KeyDownEvent to prevent duplicate triggers from
    // KeyDown + KeyUp both firing the same action
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace) {
      _safeGoBack();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.channelUp) {
      _nextChannel();
      _showControlsBriefly();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.channelDown) {
      _prevChannel();
      _showControlsBriefly();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
      if (_hasError) {
        _retryCount = 0;
        _startPlayer();
      } else if (_ctrl != null && _ctrl!.value.isInitialized) {
        _ctrl!.value.isPlaying ? _ctrl!.pause() : _ctrl!.play();
        setState(() {});
      }
      _showControlsBriefly();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown) {
      _toggleControls();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _safeGoBack() {
    // Guard: prevent any duplicate back navigation
    if (_isPopping || _disposed || !mounted) return;

    // Debounce: ignore rapid back presses within 500ms
    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastBackPress = now;

    // Set flag IMMEDIATELY to block any subsequent calls
    _isPopping = true;
    _cancelLoadingTimeout();

    // Stop and clean up the player before navigating
    _cleanupPlayer();

    if (mounted) {
      Navigator.of(context).pop();
    }

    // Reset flag after a delay to handle edge cases
    Future.delayed(const Duration(milliseconds: 300), () {
      _isPopping = false;
    });
  }

  /// Safely cleans up the video player controller.
  void _cleanupPlayer() {
    final ctrl = _ctrl;
    _ctrl = null;
    if (ctrl != null) {
      try {
        ctrl.removeListener(_playerListener);
        ctrl.pause();
        ctrl.dispose();
      } catch (_) {}
    }
  }

  void _nextChannel() {
    if (widget.channelList.isEmpty) return;
    final idx = widget.channelList.indexWhere((c) => c.id == _currentChannel.id);
    if (idx < 0 || idx >= widget.channelList.length - 1) return;
    _switchToChannel(widget.channelList[idx + 1]);
  }

  void _prevChannel() {
    if (widget.channelList.isEmpty) return;
    final idx = widget.channelList.indexWhere((c) => c.id == _currentChannel.id);
    if (idx <= 0) return;
    _switchToChannel(widget.channelList[idx - 1]);
  }

  void _autoRetry() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      debugPrint('[VargasTV] Auto-retry #$_retryCount/$_maxRetries');
      Future.delayed(Duration(seconds: _retryCount), () {
        if (mounted && _hasError) _startPlayer();
      });
    }
  }

  void _startLoadingTimeout() {
    _cancelLoadingTimeout();
    _loadingTimeout = Timer(_loadingTimeoutDuration, () {
      if (mounted && _loading && !_hasError) {
        setState(() { _loading = false; _hasError = true; });
        _autoRetry();
      }
    });
  }

  void _cancelLoadingTimeout() {
    _loadingTimeout?.cancel();
    _loadingTimeout = null;
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHideControls();
  }

  void _showControlsBriefly() {
    setState(() => _showControls = true);
    _scheduleHideControls();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_ctrl == null || !_ctrl!.value.isInitialized) return;
    if (state == AppLifecycleState.paused) {
      _ctrl!.pause();
    } else if (state == AppLifecycleState.resumed) {
      _ctrl!.play();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _cancelLoadingTimeout();
    _playerFocus.dispose();
    // Only dispose if not already cleaned up by _safeGoBack
    _cleanupPlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // Only handle if not already popped — prevents double-pop
        // when both system back and key handler fire
        if (!didPop && !_isPopping) _safeGoBack();
      },
      child: Focus(
        focusNode: _playerFocus,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (_ctrl != null && _ctrl!.value.isInitialized)
                Center(
                  child: AspectRatio(
                    aspectRatio: _ctrl!.value.aspectRatio,
                    child: VideoPlayer(_ctrl!),
                  ),
                ),

              if (_loading)
                Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.green),
                        const SizedBox(height: 16),
                        Text('Loading ${_currentChannel.name}...',
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),

              if (_hasError)
                Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        const Text('Failed to load channel',
                            style: TextStyle(color: Colors.white, fontSize: 18)),
                        const SizedBox(height: 8),
                        const Text('Press OK to retry',
                            style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                ),

              Positioned(
                top: 0, left: 0, right: 0,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                      ),
                    ),
                    child: Text(
                      '${_currentChannel.number} - ${_currentChannel.name}',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 0, left: 0, right: 0,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    color: Colors.black.withOpacity(0.5),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RemoteHint(icon: Icons.arrow_left, label: 'Prev'),
                        SizedBox(width: 20),
                        _RemoteHint(icon: Icons.circle, label: 'OK'),
                        SizedBox(width: 20),
                        _RemoteHint(icon: Icons.arrow_right, label: 'Next'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoteHint extends StatelessWidget {
  final IconData icon;
  final String label;
  const _RemoteHint({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]);
}
