import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player_plus/better_player_plus.dart';
import '../models/channel.dart';
import '../models/theme.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  /// Pass the existing mini-player controller to resume stream seamlessly
  final BetterPlayerController? existingController;

  const PlayerScreen({
    super.key,
    required this.channel,
    this.existingController,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  BetterPlayerController? _ctrl;
  bool _loading  = true;
  bool _hasError = false;
  bool _resumed  = false; // true = using existingController (don't dispose it)
  final GlobalKey _pipKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (widget.existingController != null) {
      // Resume: reuse the same controller — no rebuffering, no double spinner
      _ctrl    = widget.existingController;
      _resumed = true;
      _ctrl!.play();
      setState(() => _loading = false);
    } else {
      _startPlayer();
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
        ),
        eventListener: (event) {
          if (!mounted) return;
          switch (event.betterPlayerEventType) {
            case BetterPlayerEventType.initialized:
              setState(() => _loading = false);
              break;
            case BetterPlayerEventType.exception:
              setState(() { _loading = false; _hasError = true; });
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
    // Only dispose if WE created the controller
    if (!_resumed) _ctrl?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [

        // ── Video ──────────────────────────────────────────────
        if (_ctrl != null)
          Center(child: AspectRatio(
            key: _pipKey,
            aspectRatio: 16 / 9,
            child: BetterPlayer(controller: _ctrl!),
          )),

        // ── Loading (only when we start fresh) ─────────────────
        if (_loading && !_resumed)
          Container(color: Colors.black, child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(width: 42, height: 42,
                child: CircularProgressIndicator(
                  color: AppTheme.accent,
                  strokeWidth: 2.5,
                  backgroundColor: AppTheme.accent.withOpacity(0.15),
                )),
              const SizedBox(height: 16),
              Text('جاري تحميل ${widget.channel.name}...',
                style: const TextStyle(
                  color: AppTheme.live, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          )),

        // ── Error ──────────────────────────────────────────────
        if (_hasError)
          Container(color: Colors.black, child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.wifi_off_rounded, color: AppTheme.live, size: 52),
              const SizedBox(height: 14),
              const Text('تعذر تحميل القناة',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('تحقق من اتصالك بالإنترنت',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _startPlayer,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('إعادة المحاولة',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ),
            ]),
          )),

        // ── Top bar ────────────────────────────────────────────
        Positioned(top: 16, left: 0, right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Channel + LIVE badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _LiveDotSmall(),
                    const SizedBox(width: 7),
                    Text(widget.channel.name,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.live, borderRadius: BorderRadius.circular(4)),
                      child: const Text('LIVE',
                        style: TextStyle(
                          color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ),
                  ]),
                ),

                // Action buttons
                Row(children: [
                  _TopBtn(
                    icon: Icons.picture_in_picture_alt_rounded,
                    onTap: () => _ctrl?.enablePictureInPicture(_pipKey),
                  ),
                  const SizedBox(width: 8),
                  _TopBtn(
                    icon: Icons.keyboard_arrow_down_rounded,
                    size: 24,
                    onTap: () => Navigator.pop(context),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _LiveDotSmall extends StatefulWidget {
  @override
  State<_LiveDotSmall> createState() => _LiveDotSmallState();
}
class _LiveDotSmallState extends State<_LiveDotSmall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _a = Tween(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _a,
    child: Container(width: 7, height: 7,
      decoration: const BoxDecoration(color: AppTheme.live, shape: BoxShape.circle)));
}

class _TopBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _TopBtn({required this.icon, required this.onTap, this.size = 19});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: Colors.white, size: size),
    ),
  );
}
