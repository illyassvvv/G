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
  double _landscapeRatio = 16 / 9; // updated in _startPlayer() to actual screen ratio

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
    if (_resumed) {
      // existingController (passed from home's mini player) — do NOT dispose it
      // (home screen still owns it), but silence it immediately so its audio
      // doesn't bleed into the new channel's playback.
      try {
        _ctrl?.videoPlayerController?.setVolume(0);
        _ctrl?.pause();
      } catch (_) {}
    } else {
      _ctrl?.dispose();
    }
    _ctrl = null;
    _resumed = false;
    _playerGeneration++;
    final myGeneration = _playerGeneration;

    if (mounted) setState(() { _loading = true; _hasError = false; });

    // ── Aspect ratio ──────────────────────────────────────────────────────
    // Use the device's PHYSICAL screen size to compute the true landscape
    // ratio. This is reliable in initState because it reads from the OS
    // directly, not from MediaQuery (which depends on orientation state).
    // We always use max(w,h)/min(w,h) to guarantee a landscape ratio ≥ 1.0.
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final phys = view.physicalSize;
    final dpr  = view.devicePixelRatio;
    final pw   = phys.width  / dpr;
    final ph   = phys.height / dpr;
    final landscapeRatio = (pw > ph ? pw : ph) / (pw > ph ? ph : pw);
    _landscapeRatio = landscapeRatio; // persist so build() uses the same ratio

    _ctrl = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        looping: false,
        fullScreenByDefault: false,
        allowedScreenSleep: false,
        // ── aspectRatio set to the exact landscape ratio of the screen ──
        // This tells BetterPlayer's internal AspectRatio widget to size the
        // video exactly as wide as the screen. Combined with fit=fill the
        // video texture is stretched to cover edge-to-edge with no bars.
        aspectRatio: landscapeRatio,
        fit: BoxFit.fill,
        // Fully disable all built-in controls & their gesture detectors.
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls:      false,
          enablePlayPause:   false,
          enableMute:        false,
          enableFullscreen:  false,
          enableSkips:       false,
          enableOverflowMenu: false,
          enableQualities:   false,
          enableSubtitles:   false,
          enableAudioTracks: false,
        ),
        eventListener: (event) {
          if (!mounted) return;
          if (myGeneration != _playerGeneration) return;
          switch (event.betterPlayerEventType) {
            case BetterPlayerEventType.initialized:
              // Re-assert the ratio after BetterPlayer finishes init, because
              // it sometimes resets aspectRatio to the video's encoded ratio.
              try { _ctrl?.setOverriddenAspectRatio(landscapeRatio); } catch (_) {}
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
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
              "(KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36",
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

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHideControls();
    else _hideTimer?.cancel();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Reapply the ratio on every build (e.g. after channel switch or init).
    // Wrapped in try-catch in case the method doesn't exist in this package version.
    if (_ctrl != null) {
      final view  = WidgetsBinding.instance.platformDispatcher.views.first;
      final phys  = view.physicalSize;
      final dpr   = view.devicePixelRatio;
      final pw    = phys.width  / dpr;
      final ph    = phys.height / dpr;
      final ratio = (pw > ph ? pw : ph) / (pw > ph ? ph : pw);
      // Keep _landscapeRatio in sync so SizedBox uses the same ratio as
      // setOverriddenAspectRatio. Critical for the existingController path
      // (mini→fullscreen tap) where _startPlayer() is never called and
      // _landscapeRatio stays at the 16/9 default → pillarboxing.
      _landscapeRatio = ratio;
      try { _ctrl!.setOverriddenAspectRatio(ratio); } catch (_) {}
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        removeLeft: true,
        removeRight: true,
        child: Stack(children: [

        // ── Layer 1 — Video ─────────────────────────────────────────────────
        // FittedBox(fill) is the critical piece:
        //   • BetterPlayer has an internal AspectRatio widget that sizes itself
        //     to fit the video's ratio inside its parent's constraints.
        //     Even with Positioned.fill, the internal AspectRatio makes the
        //     video smaller than the available area (black bars).
        //   • FittedBox measures BetterPlayer at its "natural" size (whatever
        //     the internal AspectRatio decides), then SCALES it to fill the
        //     parent perfectly. No black bars, no clipping.
        //   • BoxFit.fill stretches both axes — a 16:9 video on a 20:9 screen
        //     is stretched ~11% horizontally, which is barely perceptible.
        //     Use BoxFit.cover instead if you prefer uniform scaling with crop.
        if (_ctrl != null)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(
                // SizedBox MUST match _landscapeRatio so BetterPlayer's internal
                // AspectRatio fills it exactly — no black bars inside SizedBox.
                // Old hardcoded height=1080 (16:9) caused visible black edges
                // on 20:9 / 19.5:9 phones because BetterPlayer rendered a
                // smaller 16:9-safe area inside the 1920×1080 box, and
                // FittedBox scaled those bars to screen size.
                width:  1920,
                height: 1920 / _landscapeRatio,
                child: BetterPlayer(key: _pipKey, controller: _ctrl!),
              ),
            ),
          ),

        // ── Layer 2 — Touch interceptor ─────────────────────────────────────
        //
        // WHY a separate layer instead of IgnorePointer on the video:
        //
        // VideoPlayer on iOS renders via a native UIView (platform view).
        // IgnorePointer removes the widget from Flutter's hit-test tree, but
        // the native UIView still registers UIKit touch events independently —
        // they never reach Flutter's gesture arena. So IgnorePointer can't
        // stop the native player from eating swipes/taps.
        //
        // Solution: a transparent GestureDetector layer placed AFTER (visually
        // above) BetterPlayer in the Stack. Flutter's hit-test visits Stack
        // children in reverse order (last = highest z). Our GestureDetector is
        // found FIRST, handles the gesture, and the native UIView below it
        // never sees the touch event. This is the correct pattern for
        // intercepting touches over Flutter platform views.
        //
        // HitTestBehavior.opaque: this GD claims the hit even on transparent
        // areas (like the empty black edges).
        Positioned.fill(
          child: GestureDetector(
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
            child: const SizedBox.expand(),
          ),
        ),

        // ── Layer 3 — Loading ────────────────────────────────────────────────
        if (_loading)
          Container(color: Colors.black,
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

        // ── Layer 4 — Error ──────────────────────────────────────────────────
        if (_hasError)
          Container(color: Colors.black,
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 64, height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.live.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded,
                  color: AppTheme.live, size: 32)),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                      color: AppTheme.accent.withOpacity(0.3), blurRadius: 12)]),
                  child: const Text('Retry',
                    style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 14)))),
            ]))),

        // ── Layer 5 — Controls (top bar + bottom gradient) ──────────────────
        // IgnorePointer(ignoring: !_showControls) lets the touch interceptor
        // layer below handle taps when controls are hidden. When controls ARE
        // shown, IgnorePointer is disabled so buttons receive taps normally.
        // Buttons are at a higher z-order than Layer 2 → they win in the
        // gesture arena for their own tap area.
        AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: IgnorePointer(
            ignoring: !_showControls,
            child: Column(children: [
              // Top gradient + controls
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.75), Colors.transparent],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    stops: const [0.0, 1.0])),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _TopBtn(icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1))),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.live.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(6)),
                                child: const Text('LIVE',
                                  style: TextStyle(color: Colors.white,
                                    fontSize: 10, fontWeight: FontWeight.w800,
                                    letterSpacing: 1))),
                            ]))),
                        const SizedBox(width: 12),
                        Row(children: [
                          _TopBtn(
                            icon: Icons.picture_in_picture_alt_rounded,
                            onTap: () {
                              widget.onPipRequested?.call();
                              Navigator.pop(context);
                            }),
                          const SizedBox(width: 10),
                          _TopBtn(icon: Icons.close_rounded, size: 22,
                            onTap: () => Navigator.pop(context)),
                        ]),
                      ])))),
              // Spacer — lets the touch interceptor handle taps in the middle
              const Spacer(),
              // Bottom gradient
              Container(height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter))),
            ]))),
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
