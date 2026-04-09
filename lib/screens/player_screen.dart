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
    if (!_resumed) _ctrl?.dispose();
    _ctrl = null;
    _resumed = false;

    _playerGeneration++;
    final myGeneration = _playerGeneration;

    if (mounted) setState(() { _loading = true; _hasError = false; });

    _ctrl = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        looping: false,
        fullScreenByDefault: false,
        allowedScreenSleep: false,
        // We do NOT set aspectRatio here.
        // The ratio is applied dynamically in build() via setOverriddenAspectRatio,
        // reading MediaQuery AFTER the device has actually rotated to landscape.
        // Setting it here (in initState) risks reading portrait dimensions.
        fit: BoxFit.fill,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          // Disable EVERY built-in control widget.
          // BetterPlayer still attaches internal GestureDetectors even when
          // showControls=false. We use IgnorePointer on the BetterPlayer widget
          // to block ALL of its touch handlers; our outer GestureDetector wins.
          showControls: false,
          enablePlayPause: false,
          enableMute: false,
          enableFullscreen: false,
          enableSkips: false,
          enableOverflowMenu: false,
          enableQualities: false,
          enableSubtitles: false,
          enableAudioTracks: false,
        ),
        eventListener: (event) {
          if (!mounted) return;
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
    // ── Aspect ratio: computed HERE in build, not in initState ──────────────
    //
    // Problem: setPreferredOrientations() is async. When _startPlayer() is
    // called during initState, the device has NOT rotated yet — MediaQuery
    // still returns portrait dimensions (e.g. 390×844 on iPhone 15 Pro).
    // Computing aspectRatio = width/height then gives ~0.46, which makes
    // BetterPlayer render a tiny portrait-shaped box on a landscape screen.
    //
    // Fix: Read MediaQuery inside build(). By the time Flutter calls build
    // after orientation settles, MediaQuery returns the correct landscape
    // dimensions. We then push the ratio to the controller immediately.
    //
    // We always use max(w,h)/min(w,h) so the ratio is always landscape
    // regardless of what orientation the OS reports at this exact moment.
    final mqSize = MediaQuery.of(context).size;
    final lsW = mqSize.width > mqSize.height ? mqSize.width : mqSize.height;
    final lsH = mqSize.width < mqSize.height ? mqSize.width : mqSize.height;
    final landscapeRatio = lsW / lsH;

    // Push ratio to controller every build. setOverriddenAspectRatio is
    // idempotent — calling it with the same value is a no-op internally.
    if (_ctrl != null) {
      _ctrl!.setOverriddenAspectRatio(landscapeRatio);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      // ── Gesture layer: wraps EVERYTHING ───────────────────────────────────
      //
      // GestureDetector must be the outermost widget so it covers the full
      // screen. The BetterPlayer widget below is wrapped in IgnorePointer
      // which prevents its internal GestureDetectors from ever receiving
      // touch events — our outer GD wins every gesture arena, guaranteed.
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 300) Navigator.pop(context);
        },
        onHorizontalDragEnd: (d) {
          if (widget.channelList.isEmpty) return;
          final v = d.primaryVelocity ?? 0;
          if (v < -300) _nextChannel();
          else if (v > 300) _prevChannel();
        },
        child: Stack(children: [

          // ── Video (IgnorePointer blocks BetterPlayer's internal touches) ──
          if (_ctrl != null)
            Positioned.fill(
              child: IgnorePointer(
                // IgnorePointer makes BetterPlayer invisible to the gesture
                // system. Its internal onTap / drag detectors can never fire.
                // Our outer GestureDetector is now the sole touch handler.
                child: BetterPlayer(key: _pipKey, controller: _ctrl!),
              ),
            ),

          // ── Loading ───────────────────────────────────────────────────────
          if (_loading)
            Container(
              color: Colors.black,
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 42, height: 42,
                  child: CircularProgressIndicator(
                    color: AppTheme.accent, strokeWidth: 2.5,
                    backgroundColor: AppTheme.accent.withOpacity(0.15))),
                const SizedBox(height: 16),
                Text('Loading ${_currentChannel.name}...',
                  style: const TextStyle(color: Colors.white70, fontSize: 13,
                    fontWeight: FontWeight.w600)),
              ]))),

          // ── Error ─────────────────────────────────────────────────────────
          if (_hasError)
            Container(
              color: Colors.black,
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.live.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.wifi_off_rounded, color: AppTheme.live, size: 32)),
                const SizedBox(height: 16),
                const Text('Failed to load channel',
                  style: TextStyle(color: Colors.white, fontSize: 17,
                    fontWeight: FontWeight.w700)),
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
                      boxShadow: [BoxShadow(
                        color: AppTheme.accent.withOpacity(0.3), blurRadius: 12)]),
                    child: const Text('Retry',
                      style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 14)))),
              ]))),

          // ── Top controls ──────────────────────────────────────────────────
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
                        _TopBtn(icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context)),
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
                                  style: const TextStyle(color: Colors.white,
                                    fontSize: 14, fontWeight: FontWeight.w700),
                                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.live.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(6)),
                                child: const Text('LIVE',
                                  style: TextStyle(color: Colors.white, fontSize: 10,
                                    fontWeight: FontWeight.w800, letterSpacing: 1))),
                            ]))),
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

          // ── Bottom gradient ───────────────────────────────────────────────
          Positioned(bottom: 0, left: 0, right: 0,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter)))))),

        ]),
      ),
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
