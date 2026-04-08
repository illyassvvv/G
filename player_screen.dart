import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player_plus/better_player_plus.dart';
import '../models/channel.dart';
import '../models/theme.dart';
import '../widgets/channel_card.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  final BetterPlayerController? existingController;
  final VoidCallback? onPipRequested;
  final List<Channel> channelList;
  final void Function(Channel)? onChannelChanged;

  const PlayerScreen({
    super.key,
    required this.channel,
    this.existingController,
    this.onPipRequested,
    this.channelList = const [],
    this.onChannelChanged,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  BetterPlayerController? _ctrl;
  bool _loading = true;
  bool _hasError = false;
  bool _resumed = false;
  bool _showControls = true;
  Timer? _hideTimer;
  final GlobalKey _pipKey = GlobalKey();
  late Channel _currentChannel;
  int _retryCount = 0;
  static const _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _currentChannel = widget.channel;

    if (widget.existingController != null) {
      _ctrl = widget.existingController;
      _resumed = true;
      setState(() => _loading = false);
    } else {
      _startPlayer();
    }

    // Auto-hide controls after 3s
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
    widget.onChannelChanged?.call(ch);
    if (_resumed && _ctrl != null) {
      // Reuse existing controller
      try {
        _ctrl!.videoPlayerController?.setVolume(0);
        _ctrl!.pause();
      } catch (_) {}
      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network, ch.streamUrl,
        liveStream: true,
        videoFormat: BetterPlayerVideoFormat.hls,
        // ─── SPOOFED HEADERS ADDED HERE ───────────────────────
        headers: const {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36",
          "Referer": "https://x.com/",
        },
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 2000, maxBufferMs: 10000,
          bufferForPlaybackMs: 1500, bufferForPlaybackAfterRebufferMs: 3000),
      );
      _ctrl!.setupDataSource(dataSource);
    } else {
      _resumed = false;
      _startPlayer();
    }
  }

  void _nextChannel() {
    if (widget.channelList.isEmpty) return;
    final idx = widget.channelList.indexWhere((c) => c.id == _currentChannel.id);
    if (idx < 0 || idx >= widget.channelList.length - 1) return;
    HapticFeedback.lightImpact();
    _switchToChannel(widget.channelList[idx + 1]);
  }

  void _prevChannel() {
    if (widget.channelList.isEmpty) return;
    final idx = widget.channelList.indexWhere((c) => c.id == _currentChannel.id);
    if (idx <= 0) return;
    HapticFeedback.lightImpact();
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
    if (!_resumed) _ctrl?.dispose();
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
          enableFullscreen: false,
          enablePlayPause: true,
          enableSkips: false,
          enableMute: true,
          enableAudioTracks: false,
          enableQualities: false,
          enableSubtitles: false,
          enableOverflowMenu: false,
          controlBarColor: Colors.black54,
          loadingColor: AppTheme.accent,
          progressBarPlayedColor: AppTheme.accent,
          progressBarBufferedColor: AppTheme.accent.withOpacity(0.3),
          progressBarBackgroundColor: Colors.white24,
          iconsColor: Colors.white,
          playIcon: Icons.play_arrow_rounded,
          pauseIcon: Icons.pause_rounded,
          liveTextColor: AppTheme.live,
          showControlsOnInitialize: false,
          loadingWidget: const SizedBox.shrink(),
        ),
        eventListener: (event) {
          if (!mounted) return;
          switch (event.betterPlayerEventType) {
            case BetterPlayerEventType.initialized:
              setState(() { _loading = false; _retryCount = 0; });
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
        // ─── SPOOFED HEADERS ADDED HERE ───────────────────────
        headers: const {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36",
          "Referer": "https://x.com/",
        },
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
    if (!_resumed) _ctrl?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
          if (_ctrl != null)
            Center(child: AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayer(key: _pipKey, controller: _ctrl!),
            )),

          if (_loading && !_resumed)
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
                const Text('Check your internet connection',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _startPlayer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.buttonGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 12)]),
                    child: const Text('Retry',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)))),
              ]))),

          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleControls,
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 300) {
                  Navigator.pop(context);
                }
              },
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null && widget.channelList.isNotEmpty) {
                  if (details.primaryVelocity! < -300) {
                    _nextChannel();
                  } else if (details.primaryVelocity! > 300) {
                    _prevChannel();
                  }
                }
              },
              child: const SizedBox.expand(),
            ),
          ),

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
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _TopBtn(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.1))),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              PulseDot(color: AppTheme.live, size: 8),
                              const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(_currentChannel.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
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
                            ])),
                        ),
                        const SizedBox(width: 12),
                        Row(children: [
                          _TopBtn(icon: Icons.picture_in_picture_alt_rounded,
                            onTap: () {
                              widget.onPipRequested?.call();
                              Navigator.pop(context);
                            }),
                          const SizedBox(width: 10),
                          _TopBtn(icon: Icons.close_rounded, size: 22,
                            onTap: () => Navigator.pop(context)),
                        ]),
                      ])))))),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter))),
              ),
            ),
          ),
        ]),
    );
  }
}

class _TopBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _TopBtn({required this.icon, required this.onTap, this.size = 20});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Icon(icon, color: Colors.white, size: size)));
}
