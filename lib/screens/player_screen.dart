import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../models/theme.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;

  const PlayerScreen({
    super.key,
    required this.channel,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  BetterPlayerController? _ctrl;
  bool _loading = true;
  bool _hasError = false;
  bool _showControls = true;
  Timer? _hideTimer;
  Timer? _loadingTimeout;
  int _retryCount = 0;
  static const _maxRetries = 3;
  static const _loadingTimeoutDuration = Duration(seconds: 20);

  final FocusNode _playerFocus = FocusNode();
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    _startPlayer();
    _scheduleHideControls();
  }

  void _startPlayer() {
    _cancelLoadingTimeout();
    _ctrl?.dispose();
    _ctrl = null;
    if (mounted) setState(() { _loading = true; _hasError = false; });

    _ctrl = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        looping: false,
        fullScreenByDefault: false,
        allowedScreenSleep: false,
        autoDetectFullscreenAspectRatio: true,
        fit: BoxFit.fill,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false,
          loadingWidget: const SizedBox.shrink(),
        ),
        eventListener: (event) {
          if (!mounted) return;
          switch (event.betterPlayerEventType) {
            case BetterPlayerEventType.initialized:
            case BetterPlayerEventType.play:
            case BetterPlayerEventType.bufferingEnd:
              if (_loading) {
                _cancelLoadingTimeout();
                setState(() { _loading = false; _hasError = false; _retryCount = 0; });
              }
              break;
            case BetterPlayerEventType.exception:
              _cancelLoadingTimeout();
              setState(() { _loading = false; _hasError = true; });
              _autoRetry();
              break;
            default:
              break;
          }
        },
      ),
      betterPlayerDataSource: BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.channel.streamUrl,
        liveStream: true,
        videoFormat: BetterPlayerVideoFormat.hls,
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        },
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 2000,
          maxBufferMs: 15000,
          bufferForPlaybackMs: 2500,
          bufferForPlaybackAfterRebufferMs: 4000,
        ),
      ),
    );
    _startLoadingTimeout();
    if (mounted) setState(() {});
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    // Back button is handled ONLY via PopScope to prevent double-pop
    // Do NOT handle goBack/escape/backspace here

    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
      if (_hasError) {
        _retryCount = 0;
        _startPlayer();
      } else if (_ctrl != null) {
        _ctrl!.isPlaying() == true ? _ctrl!.pause() : _ctrl!.play();
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
    if (_isPopping || !mounted) return;
    _isPopping = true;
    _cancelLoadingTimeout();

    if (_ctrl != null) {
      _ctrl!.pause();
      _ctrl!.dispose();
      _ctrl = null;
    }

    Navigator.of(context).pop();
  }

  void _autoRetry() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
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
  void dispose() {
    _hideTimer?.cancel();
    _cancelLoadingTimeout();
    _playerFocus.dispose();
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _safeGoBack();
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
              // Video player
              if (_ctrl != null)
                Center(
                  child: BetterPlayer(controller: _ctrl!),
                ),

              // Loading overlay with channel logo
              if (_loading)
                Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: widget.channel.logoUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Icon(
                              Icons.live_tv_rounded,
                              color: Colors.white54,
                              size: 40,
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.live_tv_rounded,
                              color: Colors.white54,
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(color: Colors.green),
                        const SizedBox(height: 16),
                        Text('Loading ${widget.channel.name}...',
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),

              // Error overlay
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

              // Top bar with channel info and logo
              Positioned(
                top: 0, left: 0, right: 0,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                      ),
                    ),
                    child: Row(
                      children: [
                        // Channel logo
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: widget.channel.logoUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Icon(
                              Icons.live_tv_rounded,
                              color: Colors.white54,
                              size: 22,
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.live_tv_rounded,
                              color: Colors.white54,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.channel.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'CH ${widget.channel.number}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // LIVE badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.live.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.live.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: AppTheme.live, size: 8),
                              SizedBox(width: 6),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  color: AppTheme.live,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom bar
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: Colors.black.withOpacity(0.5),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RemoteHint(icon: Icons.arrow_back, label: 'Back'),
                        SizedBox(width: 24),
                        _RemoteHint(icon: Icons.circle, label: 'Play/Pause'),
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
