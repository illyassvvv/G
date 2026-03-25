import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/channel.dart';
import '../models/theme.dart';
import '../services/external_player_service.dart';
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
  bool _launching = true;
  bool _hasError = false;
  bool _showControls = true;
  Timer? _hideTimer;
  late Channel _currentChannel;
  int _retryCount = 0;
  static const _maxRetries = 3;

  final FocusNode _playerFocus = FocusNode();
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;
    _launchExternalPlayer();
    _scheduleHideControls();
  }

  Future<void> _launchExternalPlayer() async {
    if (mounted) setState(() { _launching = true; _hasError = false; });

    final isInstalled = await ExternalPlayerService.isMxPlayerInstalled();
    if (!isInstalled) {
      if (mounted) setState(() { _launching = false; _hasError = true; });
      if (mounted) _showInstallDialog();
      return;
    }

    final launched = await ExternalPlayerService.launchMxPlayer(
      url: _currentChannel.streamUrl,
      title: '${_currentChannel.number} - ${_currentChannel.name}',
    );

    if (mounted) {
      setState(() {
        _launching = false;
        _hasError = !launched;
      });
      if (!launched) _autoRetry();
    }
  }

  void _showInstallDialog() {
    final c = const TC(true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return _MxPlayerInstallDialog(
          colors: c,
          onDownload: () {
            ExternalPlayerService.openMxPlayerStore();
          },
          onClose: () {
            Navigator.of(ctx).pop();
            _safeGoBack();
          },
        );
      },
    );
  }

  void _switchToChannel(Channel ch) {
    if (ch.id == _currentChannel.id) return;
    setState(() {
      _currentChannel = ch;
      _launching = true;
      _hasError = false;
      _retryCount = 0;
    });
    _launchExternalPlayer();
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
        if (mounted && _hasError) _launchExternalPlayer();
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _playerFocus.dispose();
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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.handled;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.escape) {
      _safeGoBack();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.channelUp) {
      _nextChannel();
      _showControlsBriefly();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.channelDown) {
      _prevChannel();
      _showControlsBriefly();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.gameButtonA) {
      if (_hasError) {
        _retryCount = 0;
      }
      _launchExternalPlayer();
      _showControlsBriefly();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      _toggleControls();
      return KeyEventResult.handled;
    }

    return KeyEventResult.handled;
  }

  void _showControlsBriefly() {
    setState(() => _showControls = true);
    _scheduleHideControls();
  }

  void _safeGoBack() {
    if (_isPopping || !mounted) return;
    _isPopping = true;
    Navigator.of(context).pop();
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
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    AppTheme.primaryDeep.withOpacity(0.3),
                    Colors.black,
                  ],
                ),
              ),
            ),

            // Launching state
            if (_launching)
              Container(color: Colors.black, child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(width: 42, height: 42,
                    child: CircularProgressIndicator(
                      color: AppTheme.accent, strokeWidth: 2.5,
                      backgroundColor: AppTheme.accent.withOpacity(0.15))),
                  const SizedBox(height: 16),
                  Text('Opening ${_currentChannel.name} in MX Player...',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                ]))),

            // Error state
            if (_hasError && !_launching)
              Container(color: Colors.black, child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 64, height: 64,
                    decoration: BoxDecoration(color: AppTheme.live.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.wifi_off_rounded, color: AppTheme.live, size: 32)),
                  const SizedBox(height: 16),
                  const Text('Failed to launch player',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(_retryCount < _maxRetries
                    ? 'Retrying... ($_retryCount/$_maxRetries)'
                    : 'Press OK to retry  |  LEFT/RIGHT to switch channel',
                    style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ]))),

            // Now playing state (returned from MX Player)
            if (!_launching && !_hasError)
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      gradient: AppTheme.buttonGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(color: AppTheme.accent.withOpacity(0.3),
                          blurRadius: 20, spreadRadius: -4),
                      ],
                    ),
                    child: const Icon(Icons.ondemand_video_rounded,
                      color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text(_currentChannel.name,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('Press OK to play again  |  LEFT/RIGHT to switch',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
                ]),
              ),

            // Top bar overlay (channel info + LIVE badge)
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
                                style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _RemoteHint(icon: Icons.arrow_left_rounded, label: 'Prev'),
                        SizedBox(width: 24),
                        _RemoteHint(icon: Icons.radio_button_checked, label: 'Play'),
                        SizedBox(width: 24),
                        _RemoteHint(icon: Icons.arrow_right_rounded, label: 'Next'),
                        SizedBox(width: 24),
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

/// MX Player install dialog with full TV remote D-pad support
class _MxPlayerInstallDialog extends StatelessWidget {
  final TC colors;
  final VoidCallback onDownload;
  final VoidCallback onClose;

  const _MxPlayerInstallDialog({
    required this.colors,
    required this.onDownload,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return FocusScope(
      autofocus: true,
      child: Focus(
        autofocus: false,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.goBack ||
               event.logicalKey == LogicalKeyboardKey.escape ||
               event.logicalKey == LogicalKeyboardKey.backspace)) {
            onClose();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppTheme.accent.withOpacity(0.3), width: 1.5),
          ),
          contentPadding: const EdgeInsets.all(32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: AppTheme.buttonGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withOpacity(0.4),
                      blurRadius: 20, spreadRadius: -4),
                  ],
                ),
                child: const Icon(Icons.ondemand_video_rounded,
                  color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text('MX Player Required',
                style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: c.text, letterSpacing: -0.5),
                textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'MX Player is required to watch channels.\nPlease install it to continue.',
                style: TextStyle(fontSize: 14, color: c.textDim, height: 1.5),
                textAlign: TextAlign.center),
              const SizedBox(height: 28),
              _DialogFocusButton(
                autofocus: true,
                onSelect: onDownload,
                builder: (focused) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: focused ? Colors.white : Colors.transparent,
                      width: 2.5),
                    boxShadow: focused
                        ? [BoxShadow(
                            color: AppTheme.accent.withOpacity(0.5),
                            blurRadius: 16, spreadRadius: -2)]
                        : [BoxShadow(
                            color: AppTheme.accent.withOpacity(0.3),
                            blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_rounded,
                        color: Colors.white, size: focused ? 22 : 20),
                      const SizedBox(width: 10),
                      Text('Download MX Player',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: focused ? 16 : 15)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _DialogFocusButton(
                onSelect: onClose,
                builder: (focused) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: focused
                        ? c.surface2.withOpacity(0.8)
                        : c.surface2.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: focused
                          ? AppTheme.accent.withOpacity(0.6)
                          : Colors.transparent,
                      width: 1.5),
                  ),
                  child: Text('Close',
                    style: TextStyle(
                      color: focused ? AppTheme.accent : c.textDim,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Focusable button for dialog with full D-pad support
class _DialogFocusButton extends StatefulWidget {
  final Widget Function(bool focused) builder;
  final VoidCallback onSelect;
  final bool autofocus;

  const _DialogFocusButton({
    required this.builder,
    required this.onSelect,
    this.autofocus = false,
  });

  @override
  State<_DialogFocusButton> createState() => _DialogFocusButtonState();
}

class _DialogFocusButtonState extends State<_DialogFocusButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
             event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          widget.onSelect();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        child: widget.builder(_focused),
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
