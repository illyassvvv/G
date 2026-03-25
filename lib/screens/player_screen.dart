import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player_plus/better_player_plus.dart';
import '../models/channel.dart';
import '../models/theme.dart';
import '../widgets/channel_card.dart';

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

class _PlayerScreenState extends State<PlayerScreen> {
  BetterPlayerController? _ctrl;
  bool _loading = true;
  bool _hasError = false;
  bool _showControls = true;
  Timer? _hideTimer;
  late Channel _currentChannel;
  int _retryCount = 0;
  static const _maxRetries = 3;

  // Focus node for capturing D-pad events on the player
  final FocusNode _playerFocus = FocusNode();

  // Guard against double-pop from system back + our handler
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;
    _startPlayer();
    _scheduleHideControls();
  }

  void _switchToChannel(Channel ch) {
    if (ch.id == _currentChannel.id) return;
    setState(() {
      _currentChannel = ch;
      _loading = true;
      _hasError = false;
      _retryCount = 0;
    });
    if (_ctrl != null) {
      try {
        _ctrl!.videoPlayerController?.setVolume(0);
        _ctrl!.pause();
      } catch (_) {}
      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network, ch.streamUrl,
        liveStream: true,
        videoFormat: BetterPlayerVideoFormat.hls,
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 2000, maxBufferMs: 10000,
          bufferForPlaybackMs: 1500, bufferForPlaybackAfterRebufferMs: 3000),
      );
      _ctrl!.setupDataSource(dataSource);
    } else {
      _startPlayer();
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
      Future.delayed(Duration(seconds: _retryCount), () {
        if (mounted && _hasError) _startPlayer();
      });
    }
  }

  void _startPlayer() {
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
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
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
                setState(() { _loading = false; _retryCount = 0; });
              }
              break;
            case BetterPlayerEventType.exception:
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
        _currentChannel.streamUrl,
        liveStream: true,
        videoFormat: BetterPlayerVideoFormat.hls,
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 2000, maxBufferMs: 10000,
          bufferForPlaybackMs: 1500, bufferForPlaybackAfterRebufferMs: 3000,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _playerFocus.dispose();
    _ctrl?.dispose();
    super.dispose();
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _scheduleHideControls();
    } else {
      _hideTimer?.cancel();
    }
  }

  /// Handle D-pad key events for TV remote
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    // Back button — go back to home (guarded against double-pop)
    if (key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.escape) {
      _safeGoBack();
      return KeyEventResult.handled;
    }

    // D-pad Right or Channel Up → next channel
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.channelUp) {
      _nextChannel();
      _showControlsBriefly();
      return KeyEventResult.handled;
    }

    // D-pad Left or Channel Down → previous channel
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.channelDown) {
      _prevChannel();
      _showControlsBriefly();
      return KeyEventResult.handled;
    }

    // Center/Enter/Select → toggle play/pause
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.gameButtonA) {
      if (_ctrl != null) {
        _ctrl!.isPlaying() == true ? _ctrl!.pause() : _ctrl!.play();
        setState(() {});
      }
      _showControlsBriefly();
      return KeyEventResult.handled;
    }

    // D-pad Up/Down → show/hide controls
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      _toggleControls();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _showControlsBriefly() {
    setState(() => _showControls = true);
    _scheduleHideControls();
  }

  void _safeGoBack() {
    if (_isPopping || !mounted) return;
    _isPopping = true;
    Navigator.pop(context);
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
        body: Stack(children: [
            // Video
            if (_ctrl != null)
              Center(child: AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _ctrl!),
              )),

            // Loading
            if (_loading)
              Container(color: Colors.black, child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(width: 42, height: 42,
                    child: CircularProgressIndicator(
                      color: AppTheme.accent, strokeWidth: 2.5,
                      backgroundColor: AppTheme.accent.withOpacity(0.15))),
                  const SizedBox(height: 16),
                  Text('Loading ${_currentChannel.name}...',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                ]))),

            // Error
            if (_hasError)
              Container(color: Colors.black, child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 64, height: 64,
                    decoration: BoxDecoration(color: AppTheme.live.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.wifi_off_rounded, color: AppTheme.live, size: 32)),
                  const SizedBox(height: 16),
                  const Text('Failed to load channel',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Press OK to retry  |  LEFT/RIGHT to switch channel',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
                ]))),

            // Top bar overlay (channel info + navigation hints)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Channel info + LIVE badge
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.1))),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              PulseDot(color: AppTheme.live, size: 8),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(_currentChannel.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.live.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(6)),
                                child: const Text('LIVE',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1))),
                              const SizedBox(width: 10),
                              Text('CH ${_currentChannel.number}',
                                style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                            ])),
                        ),
                      ]))))),

            // Bottom bar with remote hints
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RemoteHint(icon: Icons.arrow_left_rounded, label: 'Prev'),
                        const SizedBox(width: 24),
                        _RemoteHint(icon: Icons.radio_button_checked, label: 'Play/Pause'),
                        const SizedBox(width: 24),
                        _RemoteHint(icon: Icons.arrow_right_rounded, label: 'Next'),
                        const SizedBox(width: 24),
                        _RemoteHint(icon: Icons.arrow_back_rounded, label: 'Back'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Small widget showing remote control hints at the bottom of the player
class _RemoteHint extends StatelessWidget {
  final IconData icon;
  final String label;
  const _RemoteHint({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6)),
      child: Icon(icon, color: Colors.white70, size: 16)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
  ]);
}
