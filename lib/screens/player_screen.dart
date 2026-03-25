import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player_plus/better_player_plus.dart';
import '../models/channel.dart';
import '../models/theme.dart';

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
  Timer? _loadingTimeout;
  late Channel _currentChannel;
  int _retryCount = 0;
  static const _maxRetries = 3;
  static const _loadingTimeoutDuration = Duration(seconds: 20);

  final FocusNode _playerFocus = FocusNode();
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;
    _startPlayer();
    _scheduleHideControls();
  }

  // 1. تعديل إعدادات المشغل لإصلاح الـ Full Screen والـ Loading
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
        
        // الحل لمشكلة الحواف السوداء: BoxFit.fill يمد الفيديو ليملأ الشاشة تماماً
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
        _currentChannel.streamUrl,
        liveStream: true,
        
        // الحل لمشكلة عدم اشتغال الستريم: تحديد التنسيق وإضافة Headers (الوكيل)
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

  void _switchToChannel(Channel ch) {
    if (ch.id == _currentChannel.id) return;
    _cancelLoadingTimeout();
    setState(() {
      _currentChannel = ch;
      _loading = true;
      _hasError = false;
      _retryCount = 0;
    });
    _startPlayer(); // إعادة تشغيل المشغل بالكامل للقناة الجديدة
  }

  // 2. إصلاح مشكلة زر الرجوع والخروج من التطبيق
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    // معالجة زر الرجوع لمرة واحدة فقط واستهلاكه (Handled)
    if (key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace) {
      _safeGoBack();
      return KeyEventResult.handled; // هذا السطر يمنع الخروج من التطبيق
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
    
    // إيقاف المشغل وتنظيف الذاكرة قبل الخروج
    if (_ctrl != null) {
      _ctrl!.pause();
      _ctrl!.dispose();
      _ctrl = null;
    }
    
    Navigator.of(context).pop();
  }

  // بقية الدوال المساعدة...
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
            fit: StackFit.expand, // يضمن أن الـ Stack يملأ الشاشة
            children: [
              // الفيديو بملء الشاشة
              if (_ctrl != null)
                Center(
                  child: BetterPlayer(controller: _ctrl!),
                ),

              // دائرة التحميل
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

              // رسالة الخطأ
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
                        Text('Press OK to retry',
                            style: const TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                ),

              // واجهة التحكم العلوية
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

              // واجهة التحكم السفلية (تلميحات الريموت)
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
