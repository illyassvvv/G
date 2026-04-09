// FIXED: Three bugs resolved:
// 1. Black screen with sound on switch → _resumed flag blocked loading overlay.
// 2. "!" error on working channel after broken one → stale event listener
//    from disposed controller still called setState(_hasError=true).
// 3. setupDataSource on broken controller inherited bad state.
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
  // _resumed: true ONLY while still on the original PiP controller (no switch yet).
  bool _resumed = false;
  bool _showControls = true;
  Timer? _hideTimer;
  final GlobalKey _pipKey = GlobalKey();
  late Channel _currentChannel;
  int _retryCount = 0;
  static const _maxRetries = 3;

  // Generation counter — bumped every time _startPlayer() runs.
  // Each event listener closure captures its own generation value; if
  // _playerGeneration has advanced the closure returns early, so a stale
  // (already-disposed) controller can never touch state.
  int _playerGeneration = 0;

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

    _scheduleHideControls();
  }

  // ─── Channel switching ────────────────────────────────────────────────────

  void _switchToChannel(Channel ch) {
    if (ch.id == _currentChannel.id) return;

    setState(() {
      _currentChannel = ch;
      _loading = true;
      _hasError = false;
      _retryCount = 0;
    });

    widget.onChannelChanged?.call(ch);

    // Always create a fresh controller on every channel switch.
    //
    // The old code called setupDataSource() on the existing controller when
    // _resumed was true.  That caused two problems:
    //   • _resumed stayed true → loading overlay (gated on !_resumed) never
    //     showed → black frame + audio = "black screen with sound" bug.
    //   • If the old channel had errored, setupDataSource inherited bad state
    //     and the new channel would also fail immediately.
    _startPlayer();
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

  // ─── Player lifecycle ─────────────────────────────────────────────────────

  void _startPlayer() {
    // Dispose previous controller only if we own it.
    // (_resumed is true only when still on the original PiP controller.)
    if (!_resumed) _ctrl?.dispose();
    _ctrl = null;

    // After the first switch we always own the controller.
    _resumed = false;

    // Bump generation so any pending events from the old controller are
    // ignored.  This is the fix for the "!" bleeding onto good channels:
    // the old errored controller's exception callback fires after dispose
    // and would call setState(_hasError=true) on the new channel's state.
    _playerGeneration++;
    final myGeneration = _playerGeneration;

    if (mounted) setState(() { _loading = true; _hasError = false; });

    _ctrl = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        looping: false,
        fullScreenByDefault: false,
        allowedScreenSleep: false,
        // FIX: fill instead of contain → no black bars on wide-screen phones.
        // autoDetectFullscreenAspectRatio removed (we manage our own fullscreen).
        fit: BoxFit.fill,
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
          // Drop events from any previous (disposed) controller generation.
          if (myGeneration != _playerGeneration) return;

          switch (event.betterPlayerEventType) {
            case BetterPlayerEventType.initialized:
              setState(() { _loading = false; _retryCount = 0; });
              break;
            case BetterPlayerEventType.exception:
              setState(() { _loading = false; _hasError = true; });
              _autoRetry(myGeneration);
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
        // FIX: Removed forced videoFormat: hls.
        // If a stream is MPEG-TS or another format, forcing HLS degrades quality.
        // BetterPlayer now auto-detects from the URL extension / response headers.
        headers: {
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36",
          "Referer": "https://x.com/",
        },
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 3000,
          maxBufferMs: 15000,
          bufferForPlaybackMs: 2000,
          bufferForPlaybackAfterRebufferMs: 4000,
        ),
      ),
    );

    if (mounted) setState(() {});
  }

  void _autoRetry(int generation) {
    if (_retryCount >= _maxRetries) return;
    _retryCount++;
    Future.delayed(Duration(seconds: _retryCount), () {
      // Only retry if: widget mounted, still in error state, AND this is
      // still the active generation (user hasn't switched channel away).
      if (mounted && _hasError && generation == _playerGeneration) {
        _startPlayer();
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    if (!_resumed) _ctrl?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ─── UI helpers ───────────────────────────────────────────────────────────

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

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // FIX: extendBody prevents Scaffold from adding bottom padding
      // on devices where the system nav bar briefly flashes before
      // immersiveSticky kicks in, which would push the video up.
      extendBody: true,
      body: Stack(children: [
          // FIX: Removed Center+AspectRatio(16/9) wrapper.
          // Forcing 16:9 on a 20:9 screen leaves black bars on sides.
          // Positioned.fill lets BetterPlayer occupy the entire screen;
          // fit: BoxFit.fill (set in configuration) fills edge-to-edge.
          if (_ctrl != null)
            Positioned.fill(
              child: BetterPlayer(key: _pipKey, controller: _ctrl!),
            ),

          // Loading overlay — was gated on (_loading && !_resumed).
          // That kept it hidden during channel switches because _resumed stayed
          // true, exposing the black frame + audio bug. Now it shows whenever
          // _loading is true.
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
