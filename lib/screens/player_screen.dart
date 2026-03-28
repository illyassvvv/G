import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/channel.dart';
import '../models/theme.dart';
import '../providers/app_provider.dart';
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

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  // ── media_kit core objects ─────────────────────────────────────────────
  late final Player _player;
  late final VideoController _videoController;

  // Stream subscriptions (replace video_player addListener)
  StreamSubscription<bool>? _subPlaying;
  StreamSubscription<bool>? _subBuffering;
  StreamSubscription<String>? _subError;

  // ── UI state ───────────────────────────────────────────────────────────
  bool _isInitialized = false;
  bool _loading = true;
  bool _hasError = false;
  bool _isPlaying = false;
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

  // ── OSD overlay ────────────────────────────────────────────────────────
  bool _showOSD = false;
  Timer? _osdTimer;

  // ── Channel number input ───────────────────────────────────────────────
  String _numberInput = '';
  Timer? _numberTimer;

  // ── DVR / Time-shift ───────────────────────────────────────────────────
  bool _isDvrStream = false;

  // ── Buffering debounce ─────────────────────────────────────────────────
  Timer? _bufferDebounce;

  // ───────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ───────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _currentChannel = widget.channel;
    _isDvrStream = _checkDvr(_currentChannel.streamUrl);

    // ONE Player + VideoController for the entire lifetime of this screen.
    _player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 16 * 1024 * 1024, // 16 MB — good for variable-bitrate IPTV
        logLevel: MPVLogLevel.warn,
        pitch: false,
      ),
    );
    _videoController = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );

    _setupStreamListeners();

    WakelockPlus.enable();
    _startPlayer();
    _scheduleHideControls();
    _showOSDOverlay();
  }

  // ── media_kit stream listeners ─────────────────────────────────────────

  void _setupStreamListeners() {
    _subPlaying = _player.stream.playing.listen((playing) {
      if (_disposed || !mounted) return;
      // Fast path: skip setState during steady playback (no state change)
      if (playing == _isPlaying && !_loading && !_hasError) return;

      if (playing && _loading) {
        _cancelLoadingTimeout();
        _bufferDebounce?.cancel();
        setState(() {
          _isPlaying = true;
          _isInitialized = true;
          _loading = false;
          _hasError = false;
          _retryCount = 0;
        });
      } else {
        if (_isPlaying != playing) setState(() => _isPlaying = playing);
      }
    });

    _subBuffering = _player.stream.buffering.listen((buffering) {
      if (_disposed || !mounted) return;
      if (buffering && !_loading && !_hasError) {
        // Debounce: show loading spinner only after 500 ms of sustained
        // buffering. Prevents the overlay from flickering on every keyframe
        // boundary — which forces a GPU re-composite and drops frames.
        _bufferDebounce?.cancel();
        _bufferDebounce = Timer(const Duration(milliseconds: 500), () {
          if (!_disposed && mounted && _player.state.buffering) {
            setState(() => _loading = true);
          }
        });
      } else if (!buffering && _loading && !_hasError) {
        _bufferDebounce?.cancel();
        setState(() => _loading = false);
      }
    });

    _subError = _player.stream.error.listen((error) {
      if (_disposed || !mounted) return;
      debugPrint('[VargasTV] media_kit error: $error');
      if (!_hasError) {
        _bufferDebounce?.cancel();
        _cancelLoadingTimeout();
        setState(() { _loading = false; _hasError = true; });
        _autoRetry();
      }
    });
  }

  // ───────────────────────────────────────────────────────────────────────
  // Playback control
  // ───────────────────────────────────────────────────────────────────────

  void _startPlayer() {
    _cancelLoadingTimeout();
    _bufferDebounce?.cancel();
    if (mounted) setState(() { _loading = true; _hasError = false; });
    debugPrint('[VargasTV] Starting player for: ${_currentChannel.name}');
    _resolveAndPlay(_currentChannel.streamUrl);
  }

  Future<void> _resolveAndPlay(String originalUrl) async {
    try {
      final resolved =
          await StreamResolverService.resolveStreamUrl(originalUrl);
      if (_disposed || !mounted) return;

      debugPrint('[VargasTV] Resolved URL: ${resolved.url}');

      final Map<String, String> streamHeaders = {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Android TV) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/120.0.0.0 Safari/537.36',
        'Accept': '*/*',
        'Connection': 'keep-alive',
        if (resolved.headers != null) ...resolved.headers!,
      };

      // media_kit accepts HTTP headers directly in the Media object.
      await _player.open(
        Media(resolved.url, httpHeaders: streamHeaders),
        play: true,
      );

      if (_disposed || !mounted) return;
      _startLoadingTimeout();
    } catch (e) {
      if (_disposed || !mounted) return;
      debugPrint('[VargasTV] Stream resolution failed: $e');
      setState(() { _loading = false; _hasError = true; });
      _autoRetry();
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
      _isInitialized = false;
      _isPlaying = false;
      _isDvrStream = _checkDvr(ch.streamUrl);
    });
    final prov = context.read<AppProvider>();
    prov.setActiveChannel(ch);
    prov.saveLastChannel(
      id: ch.id, name: ch.name, url: ch.streamUrl,
      logo: ch.logoUrl, number: ch.number, category: ch.category);
    _showOSDOverlay();
    _startPlayer();
  }

  bool _checkDvr(String url) {
    final lower = url.toLowerCase();
    return lower.contains('dvr') || lower.contains('timeshift');
  }

  // ── DVR seek ───────────────────────────────────────────────────────────

  void _seekRelative(Duration offset) {
    if (!_isInitialized) return;
    final current = _player.state.position;
    final duration = _player.state.duration;
    var target = current + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (duration > Duration.zero && target > duration) target = duration;
    _player.seek(target);
    _showControlsBriefly();
  }

  // ── Channel navigation ─────────────────────────────────────────────────

  void _nextChannel() {
    if (widget.channelList.isEmpty) return;
    final idx =
        widget.channelList.indexWhere((c) => c.id == _currentChannel.id);
    if (idx < 0 || idx >= widget.channelList.length - 1) return;
    _switchToChannel(widget.channelList[idx + 1]);
  }

  void _prevChannel() {
    if (widget.channelList.isEmpty) return;
    final idx =
        widget.channelList.indexWhere((c) => c.id == _currentChannel.id);
    if (idx <= 0) return;
    _switchToChannel(widget.channelList[idx - 1]);
  }

  // ── Retry logic ────────────────────────────────────────────────────────

  void _autoRetry() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      debugPrint('[VargasTV] Auto-retry #$_retryCount/$_maxRetries');
      Future.delayed(Duration(seconds: _retryCount), () {
        if (!_disposed && mounted && _hasError) _startPlayer();
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

  // ── OSD ────────────────────────────────────────────────────────────────

  void _showOSDOverlay() {
    _osdTimer?.cancel();
    setState(() => _showOSD = true);
    _osdTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showOSD = false);
    });
  }

  // ── Channel number input ───────────────────────────────────────────────

  void _onDigitPressed(int digit) {
    _numberTimer?.cancel();
    setState(() {
      _numberInput += digit.toString();
      if (_numberInput.length > 3) {
        _numberInput = _numberInput.substring(_numberInput.length - 3);
      }
    });
    _numberTimer = Timer(const Duration(seconds: 2), _tryNavigateToNumber);
  }

  void _tryNavigateToNumber() {
    if (_numberInput.isEmpty) return;
    final input = _numberInput;
    setState(() => _numberInput = '');
    final target = widget.channelList.cast<Channel?>().firstWhere(
      (ch) => ch!.number == input || ch.number == input.padLeft(2, '0'),
      orElse: () => null,
    );
    if (target != null && target.id != _currentChannel.id) {
      _switchToChannel(target);
    }
  }

  // ── Controls visibility ────────────────────────────────────────────────

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

  // ── Key handling (UNCHANGED from original) ─────────────────────────────

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace) {
      _safeGoBack();
      return KeyEventResult.handled;
    }

    final digitKeys = {
      LogicalKeyboardKey.digit0: 0, LogicalKeyboardKey.digit1: 1,
      LogicalKeyboardKey.digit2: 2, LogicalKeyboardKey.digit3: 3,
      LogicalKeyboardKey.digit4: 4, LogicalKeyboardKey.digit5: 5,
      LogicalKeyboardKey.digit6: 6, LogicalKeyboardKey.digit7: 7,
      LogicalKeyboardKey.digit8: 8, LogicalKeyboardKey.digit9: 9,
      LogicalKeyboardKey.numpad0: 0, LogicalKeyboardKey.numpad1: 1,
      LogicalKeyboardKey.numpad2: 2, LogicalKeyboardKey.numpad3: 3,
      LogicalKeyboardKey.numpad4: 4, LogicalKeyboardKey.numpad5: 5,
      LogicalKeyboardKey.numpad6: 6, LogicalKeyboardKey.numpad7: 7,
      LogicalKeyboardKey.numpad8: 8, LogicalKeyboardKey.numpad9: 9,
    };
    if (digitKeys.containsKey(key)) {
      _onDigitPressed(digitKeys[key]!);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.mediaRewind) {
      _seekRelative(const Duration(seconds: -30));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.mediaFastForward) {
      _seekRelative(const Duration(seconds: 30));
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.channelUp) {
      if (_showControls && _isDvrStream) {
        _seekRelative(const Duration(seconds: 30));
      } else {
        _nextChannel();
      }
      _showControlsBriefly();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.channelDown) {
      if (_showControls && _isDvrStream) {
        _seekRelative(const Duration(seconds: -30));
      } else {
        _prevChannel();
      }
      _showControlsBriefly();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter) {
      if (_hasError) {
        _retryCount = 0;
        _startPlayer();
      } else if (_isInitialized) {
        _isPlaying ? _player.pause() : _player.play();
      }
      _showControlsBriefly();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      _toggleControls();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // ── Back / Pop ─────────────────────────────────────────────────────────

  void _safeGoBack() {
    if (_isPopping || _disposed || !mounted) return;
    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) <
            const Duration(milliseconds: 500)) {
      return;
    }
    _lastBackPress = now;
    _isPopping = true;
    _cancelLoadingTimeout();
    _cleanupPlayer();
    if (mounted) Navigator.of(context).pop();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_disposed) _isPopping = false;
    });
  }

  void _cleanupPlayer() {
    _bufferDebounce?.cancel();
    try {
      _player.stop();
    } catch (_) {}
  }

  // ── App lifecycle ──────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;
    if (state == AppLifecycleState.paused) {
      _player.pause();
      WakelockPlus.disable();
    } else if (state == AppLifecycleState.resumed) {
      _player.play();
      WakelockPlus.enable();
    }
  }

  // ── Dispose ────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;
    WakelockPlus.disable();
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _osdTimer?.cancel();
    _numberTimer?.cancel();
    _bufferDebounce?.cancel();
    _cancelLoadingTimeout();
    _playerFocus.dispose();
    _subPlaying?.cancel();
    _subBuffering?.cancel();
    _subError?.cancel();
    _player.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────
  // BUILD  —  UI is IDENTICAL to the original; only the video widget changes
  // ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
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

              // ── VIDEO SURFACE ─────────────────────────────────────────
              // RepaintBoundary isolates the GL texture from Flutter UI
              // layer repaints — prevents frame drops on TV hardware.
              RepaintBoundary(
                child: Video(
                  controller: _videoController,
                  // BoxFit.contain = same visual behaviour as the old
                  // AspectRatio + VideoPlayer widget combination.
                  fit: BoxFit.contain,
                  // Disable media_kit's built-in overlay controls;
                  // we use our own remote-friendly controls below.
                  controls: NoVideoControls,
                  // We manage the wakelock ourselves via WakelockPlus.
                  wakelock: false,
                ),
              ),

              // ── LOADING OVERLAY ───────────────────────────────────────
              if (_loading)
                Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                            color: Colors.green),
                        const SizedBox(height: 16),
                        Text(
                          'Loading ${_currentChannel.name}...',
                          style: const TextStyle(
                              color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── ERROR OVERLAY ─────────────────────────────────────────
              if (_hasError)
                Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text('Failed to load channel',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18)),
                        SizedBox(height: 8),
                        Text('Press OK to retry',
                            style:
                                TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                ),

              // ── OSD: top channel info bar ─────────────────────────────
              if (_showControls || _showOSD)
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: IgnorePointer(
                    ignoring: !(_showControls || _showOSD),
                    child: AnimatedOpacity(
                      opacity:
                          (_showControls || _showOSD) ? 1.0 : 0.0,
                      duration:
                          const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(
                            24, 20, 24, 28),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.85),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(children: [
                          // Channel logo
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color:
                                  Colors.white.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.accent
                                      .withOpacity(0.3)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _currentChannel
                                    .logoUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl:
                                        _currentChannel.logoUrl,
                                    fit: BoxFit.contain,
                                    memCacheWidth: 96,
                                    memCacheHeight: 96,
                                    errorWidget: (_, __, ___) =>
                                        const Icon(
                                            Icons.tv_rounded,
                                            color: Colors.white54,
                                            size: 24),
                                  )
                                : const Icon(Icons.tv_rounded,
                                    color: Colors.white54,
                                    size: 24),
                          ),
                          const SizedBox(width: 16),
                          // Channel name + badges
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_currentChannel.number}  ${_currentChannel.name}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets
                                        .symmetric(
                                            horizontal: 8,
                                            vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent
                                          .withOpacity(0.2),
                                      borderRadius:
                                          BorderRadius.circular(
                                              6),
                                    ),
                                    child: Text(
                                      _currentChannel.category,
                                      style: TextStyle(
                                        color: AppTheme.accent,
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (_isDvrStream) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets
                                          .symmetric(
                                              horizontal: 8,
                                              vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue
                                            .withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(
                                                6),
                                      ),
                                      child: const Text('DVR',
                                          style: TextStyle(
                                            color: Colors
                                                .lightBlueAccent,
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.w600,
                                          )),
                                    ),
                                  ],
                                ]),
                              ],
                            ),
                          ),
                          // LIVE badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.live
                                  .withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppTheme.live
                                      .withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration:
                                      const BoxDecoration(
                                    color: AppTheme.live,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('LIVE',
                                    style: TextStyle(
                                      color: AppTheme.live,
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.w800,
                                      letterSpacing: 1,
                                    )),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),

              // ── Number input overlay (top-right) ──────────────────────
              if (_numberInput.isNotEmpty)
                Positioned(
                  top: 80, right: 32,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              AppTheme.accent.withOpacity(0.5)),
                    ),
                    child: Text(
                      _numberInput,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),

              // ── Bottom controls bar ───────────────────────────────────
              if (_showControls)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration:
                        const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.85),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: _isDvrStream
                            ? const [
                                _RemoteHint(
                                    icon: Icons
                                        .fast_rewind_rounded,
                                    label: '-30s'),
                                SizedBox(width: 32),
                                _RemoteHint(
                                    icon: Icons.circle,
                                    label: 'Play/Pause'),
                                SizedBox(width: 32),
                                _RemoteHint(
                                    icon: Icons
                                        .fast_forward_rounded,
                                    label: '+30s'),
                              ]
                            : const [
                                _RemoteHint(
                                    icon: Icons
                                        .arrow_left_rounded,
                                    label: 'Prev'),
                                SizedBox(width: 32),
                                _RemoteHint(
                                    icon: Icons.circle,
                                    label: 'OK'),
                                SizedBox(width: 32),
                                _RemoteHint(
                                    icon: Icons
                                        .arrow_right_rounded,
                                    label: 'Next'),
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
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 12)),
      ]);
}
