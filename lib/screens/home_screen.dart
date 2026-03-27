import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/channel.dart';
import '../models/theme.dart';
import '../providers/app_provider.dart';
import '../services/channel_service.dart';
import '../widgets/channel_card.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Data
  List<ChannelCategory> _categories = [];
  bool _loadingData = true;
  String? _dataError;

  // Currently selected category index in left sidebar
  int _selectedCatIndex = 0;

  // Debounce guard
  DateTime? _lastOpenTime;

  // Focus management for TV remote
  final FocusNode _sidebarFocus = FocusNode();
  final ScrollController _sidebarScrollCtrl = ScrollController();
  final ScrollController _gridScrollCtrl = ScrollController();

  // ── Resume last channel ───────────────────────────────────
  bool _resumePromptShown = false;

  // ── Channel number input on home screen ───────────────────
  String _numberInput = '';
  Timer? _numberTimer;

  // ── Screensaver ───────────────────────────────────────────
  bool _screensaverActive = false;
  Timer? _screensaverTimer;
  static const _screensaverDelay = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _loadChannels();
    _resetScreensaverTimer();
    // Listen for any key to reset screensaver
    HardwareKeyboard.instance.addHandler(_globalKeyHandler);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_globalKeyHandler);
    _sidebarFocus.dispose();
    _sidebarScrollCtrl.dispose();
    _gridScrollCtrl.dispose();
    _numberTimer?.cancel();
    _screensaverTimer?.cancel();
    super.dispose();
  }

  // ── Global key handler for screensaver + number input ─────
  bool _globalKeyHandler(KeyEvent event) {
    // Dismiss screensaver on any key
    if (_screensaverActive && event is KeyDownEvent) {
      setState(() => _screensaverActive = false);
      _resetScreensaverTimer();
      return true; // consume the event
    }
    // Reset inactivity timer on any key
    _resetScreensaverTimer();

    // Number input on home screen (only when not in screensaver)
    if (event is KeyDownEvent && !_screensaverActive) {
      const digitKeys = {
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
      if (digitKeys.containsKey(event.logicalKey)) {
        _onDigitPressed(digitKeys[event.logicalKey]!);
        return true;
      }
    }
    return false; // let other handlers process
  }

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
    // Search all channels across all categories
    for (final cat in _categories) {
      for (final ch in cat.channels) {
        if (ch.number == input || ch.number == input.padLeft(2, '0')) {
          _openPlayer(ch);
          return;
        }
      }
    }
  }

  void _resetScreensaverTimer() {
    _screensaverTimer?.cancel();
    _screensaverTimer = Timer(_screensaverDelay, () {
      if (mounted) setState(() => _screensaverActive = true);
    });
  }

  Future<void> _loadChannels() async {
    setState(() { _loadingData = true; _dataError = null; });
    try {
      final cats = await ChannelService.fetchCategories();
      if (mounted) {
        setState(() { _categories = cats; _loadingData = false; });
        // Show resume dialog after channels are loaded
        if (!_resumePromptShown) {
          _resumePromptShown = true;
          _showResumeDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loadingData = false; _dataError = e.toString(); });
      }
    }
  }

  void _showResumeDialog() {
    final prov = context.read<AppProvider>();
    final last = prov.lastChannel;
    if (last == null || last.streamUrl.isEmpty) return;
    // Wait a frame so the UI is fully built before showing the dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierColor: Colors.black54,
        builder: (ctx) => _ResumeDialog(
          channelName: last.name,
          channelNumber: last.number,
          onResume: () {
            Navigator.of(ctx).pop();
            _openPlayer(last);
          },
          onCancel: () => Navigator.of(ctx).pop(),
        ),
      );
    });
  }

  void _openPlayer(Channel ch) {
    if (ch.streamUrl.isEmpty) return;
    // Debounce: block rapid re-entry that can happen when key events from the
    // player screen bleed into the home screen on pop (Android TV key buffering).
    final now = DateTime.now();
    if (_lastOpenTime != null &&
        now.difference(_lastOpenTime!) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastOpenTime = now;
    final channelList = _categories
        .where((cat) => cat.name == ch.category)
        .expand((cat) => cat.channels)
        .toList();
    final prov = context.read<AppProvider>();
    prov.setActiveChannel(ch);
    prov.saveLastChannel(
      id: ch.id, name: ch.name, url: ch.streamUrl,
      logo: ch.logoUrl, number: ch.number, category: ch.category);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PlayerScreen(
        channel: ch,
        channelList: channelList,
      ),
    ));
  }

  void _toggleFavorite(Channel ch) {
    final prov = context.read<AppProvider>();
    prov.toggleFavorite(ch.id);
    setState(() {});
  }

  /// Build the display categories list, injecting Favorites at the top if any exist
  List<ChannelCategory> _getDisplayCategories(AppProvider prov) {
    final favIds = prov.favoriteIds;
    if (favIds.isEmpty) return _categories;
    // Collect all favorite channels from all categories
    final favChannels = <Channel>[];
    for (final cat in _categories) {
      for (final ch in cat.channels) {
        if (favIds.contains(ch.id)) {
          favChannels.add(ch);
        }
      }
    }
    if (favChannels.isEmpty) return _categories;
    final favCategory = ChannelCategory(
      name: 'Favorites',
      icon: 'favorite',
      channels: favChannels,
    );
    return [favCategory, ..._categories];
  }

  IconData _catIcon(String name) {
    switch (name) {
      case 'sports_soccer': return Icons.sports_soccer;
      case 'sports': return Icons.sports;
      case 'sports_basketball': return Icons.sports_basketball;
      case 'tv': return Icons.tv;
      case 'movie': return Icons.movie;
      case 'music_note': return Icons.music_note;
      case 'news': return Icons.newspaper;
      case 'favorite': return Icons.favorite_rounded;
      default: return Icons.live_tv;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final c = prov.colors;
    final displayCats = _getDisplayCategories(prov);

    // Handle back press on home screen — show exit confirmation dialog.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
          ),
        ),
        child: Stack(children: [
        // Ambient glows
        Positioned(top: -120, right: -80,
          child: _glow(AppTheme.accent, 350, prov.isDark ? 0.05 : 0.03)),
        Positioned(bottom: -150, left: -50,
          child: _glow(AppTheme.primaryDark, 300, prov.isDark ? 0.03 : 0.02)),

        // No internet banner
        if (!prov.hasInternet)
          Positioned(top: 0, left: 0, right: 0,
            child: Material(color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.live.withOpacity(0.95),
                      AppTheme.live.withOpacity(0.85),
                    ])),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                  child: Row(children: const [
                    Icon(Icons.wifi_off_rounded,
                      color: Colors.white, size: 16),
                    SizedBox(width: 10),
                    Text('No internet connection',
                      style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 13)),
                  ])))
              .animate()
              .slideY(begin: -1, end: 0, duration: 300.ms))),

        // Main TV layout: sidebar + content grid
        if (_loadingData)
          Center(child: CircularProgressIndicator(color: AppTheme.accent))
        else if (_dataError != null)
          _buildError(c)
        else
          Row(children: [
            _buildSidebar(prov, c, displayCats),
            Container(width: 1, color: c.border),
            Expanded(child: _buildChannelGrid(prov, c, displayCats)),
          ]),

        // ── Number input overlay ─────────────────────────────
        if (_numberInput.isNotEmpty)
          Positioned(
            top: 24, right: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
              ),
              child: Text(_numberInput,
                style: const TextStyle(color: Colors.white,
                  fontSize: 36, fontWeight: FontWeight.w700,
                  fontFamily: 'monospace', letterSpacing: 4)),
            ),
          ),

        // ── Screensaver overlay ──────────────────────────────
        if (_screensaverActive)
          const Positioned.fill(child: _ScreensaverOverlay()),
      ]),
      ),
    ),
    );
  }

  Widget _buildSidebar(AppProvider prov, TC c, List<ChannelCategory> displayCats) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF111111).withOpacity(0.7),
      ),
      child: Column(children: [
        // App title - Premium VargasTV header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 16, 20),
          child: Row(children: [
            RichText(text: TextSpan(
              children: [
                TextSpan(
                  text: 'Vargas',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'TV',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accent,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: AppTheme.accent.withOpacity(0.35),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ],
            )),
          ])),
        Container(height: 1, color: Colors.white.withOpacity(0.04)),
        // Category list
        Expanded(
          child: ListView.builder(
            controller: _sidebarScrollCtrl,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: displayCats.length,
            itemBuilder: (_, i) {
              final cat = displayCats[i];
              final isSelected = i == _selectedCatIndex;
              final isFav = cat.name == 'Favorites';
              return _TVFocusableItem(
                autofocus: i == 0,
                onSelect: () {
                  setState(() => _selectedCatIndex = i);
                  _gridScrollCtrl.jumpTo(0);
                },
                builder: (focused) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: (isSelected || focused)
                        ? LinearGradient(colors: [
                            (isFav ? AppTheme.live : AppTheme.accent).withOpacity(focused ? 0.25 : 0.12),
                            (isFav ? AppTheme.live : AppTheme.accent).withOpacity(focused ? 0.15 : 0.06),
                          ])
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: focused
                          ? (isFav ? AppTheme.live : AppTheme.accent).withOpacity(0.8)
                          : isSelected
                              ? (isFav ? AppTheme.live : AppTheme.accent).withOpacity(0.3)
                              : Colors.transparent,
                      width: focused ? 2 : 1),
                  ),
                  child: Row(children: [
                    // Left green indicator for selected category
                    if (isSelected && !focused)
                      Container(
                        width: 3,
                        height: 20,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    Icon(_catIcon(cat.icon),
                      color: (isSelected || focused)
                          ? (isFav ? AppTheme.live : AppTheme.accent)
                          : c.textDim,
                      size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(cat.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: (isSelected || focused) ? FontWeight.w700 : FontWeight.w500,
                        color: (isSelected || focused)
                            ? (isFav ? AppTheme.live : AppTheme.accent)
                            : c.text),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text('${cat.channels.length}',
                      style: TextStyle(fontSize: 11,
                        color: (isSelected || focused)
                            ? AppTheme.accent.withOpacity(0.7)
                            : c.textDim.withOpacity(0.5),
                        fontWeight: FontWeight.w600)),
                  ]),
                ),
              );
            }),
        ),
      ]),
    );
  }

  Widget _buildChannelGrid(AppProvider prov, TC c, List<ChannelCategory> displayCats) {
    if (displayCats.isEmpty) return const SizedBox.shrink();
    if (_selectedCatIndex >= displayCats.length) {
      // Schedule the state update for after the current build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedCatIndex = 0);
      });
      // Use 0 for this frame to avoid out-of-bounds
      return const SizedBox.shrink();
    }
    final cat = displayCats[_selectedCatIndex];
    final isFav = cat.name == 'Favorites';
    final accentColor = isFav ? AppTheme.live : AppTheme.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(children: [
            Icon(_catIcon(cat.icon), color: accentColor, size: 24),
            const SizedBox(width: 12),
            Text(cat.name,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                color: c.text, letterSpacing: -0.3)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
              child: Text('${cat.channels.length} channels',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: accentColor))),
            const Spacer(),
            // Hint for favorites
            Text('Hold OK = Favorite',
              style: TextStyle(fontSize: 11, color: c.textDim)),
          ])),
        // Channel grid
        Expanded(
          child: GridView.builder(
            controller: _gridScrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.15,
            ),
            itemCount: cat.channels.length,
            itemBuilder: (_, idx) {
              final ch = cat.channels[idx];
              return TVChannelCard(
                channel: ch,
                provider: prov,
                onSelect: () => _openPlayer(ch),
                onLongPress: () => _toggleFavorite(ch),
                isFavorite: prov.favoriteIds.contains(ch.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildError(TC c) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80,
        decoration: BoxDecoration(
          color: c.surface2.withOpacity(0.5), shape: BoxShape.circle),
        child: Icon(Icons.cloud_off_rounded,
          color: c.textDim, size: 36)),
      const SizedBox(height: 20),
      Text('Failed to load channels',
        style: TextStyle(color: c.text, fontSize: 17,
          fontWeight: FontWeight.w800, letterSpacing: -0.3)),
      const SizedBox(height: 8),
      Text('Check your connection and try again',
        style: TextStyle(color: c.textDim, fontSize: 13)),
      const SizedBox(height: 24),
      _TVFocusableItem(
        autofocus: true,
        onSelect: _loadChannels,
        builder: (focused) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(
            gradient: AppTheme.buttonGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: focused ? Colors.white : Colors.transparent,
              width: 2),
            boxShadow: [
              BoxShadow(color: AppTheme.accent.withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 4)),
            ]),
          child: const Text('Retry',
            style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 14))),
      ),
    ]));

  // ── Exit confirmation dialog ─────────────────────────────
  DateTime? _lastBackPress;

  void _showExitDialog() {
    // Debounce rapid back presses
    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastBackPress = now;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.6),
                  blurRadius: 40, spreadRadius: 8),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.live.withOpacity(0.12),
                  shape: BoxShape.circle),
                child: const Icon(Icons.exit_to_app_rounded,
                  color: AppTheme.live, size: 32),
              ),
              const SizedBox(height: 16),
              Text('Exit VargasTV?',
                style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 18,
                  fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Are you sure you want to exit?',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _TVFocusableItem(
                  autofocus: true,
                  onSelect: () => Navigator.of(ctx).pop(),
                  builder: (focused) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: focused
                          ? Colors.white.withOpacity(0.15)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: focused
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white.withOpacity(0.1)),
                    ),
                    child: const Text('Cancel',
                      style: TextStyle(color: Colors.white70, fontSize: 14,
                        fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 16),
                _TVFocusableItem(
                  onSelect: () {
                    Navigator.of(ctx).pop();
                    SystemNavigator.pop();
                  },
                  builder: (focused) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppTheme.live.withOpacity(focused ? 1.0 : 0.8),
                        AppTheme.live.withOpacity(focused ? 0.8 : 0.6),
                      ]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: focused ? Colors.white : Colors.transparent,
                        width: 2),
                    ),
                    child: const Text('Exit',
                      style: TextStyle(color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _glow(Color color, double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withOpacity(opacity), Colors.transparent])));
}

/// A focusable item for TV remote D-pad navigation.
class _TVFocusableItem extends StatefulWidget {
  final Widget Function(bool focused) builder;
  final VoidCallback onSelect;
  final bool autofocus;

  const _TVFocusableItem({
    required this.builder,
    required this.onSelect,
    this.autofocus = false,
  });

  @override
  State<_TVFocusableItem> createState() => _TVFocusableItemState();
}

class _TVFocusableItemState extends State<_TVFocusableItem> {
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

/// Dialog shown on app startup to resume last watched channel.
class _ResumeDialog extends StatelessWidget {
  final String channelName;
  final String channelNumber;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  const _ResumeDialog({
    required this.channelName,
    required this.channelNumber,
    required this.onResume,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.6),
                blurRadius: 40, spreadRadius: 8),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                shape: BoxShape.circle),
              child: const Icon(Icons.play_circle_outline_rounded,
                color: AppTheme.accent, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Resume Watching?',
              style: TextStyle(color: Colors.white, fontSize: 18,
                fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('$channelNumber - $channelName',
              style: TextStyle(color: AppTheme.accent.withOpacity(0.8),
                fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _TVFocusableItem(
                onSelect: onCancel,
                builder: (focused) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: focused
                        ? Colors.white.withOpacity(0.15)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: focused
                          ? Colors.white.withOpacity(0.5)
                          : Colors.white.withOpacity(0.1)),
                  ),
                  child: const Text('Cancel',
                    style: TextStyle(color: Colors.white70, fontSize: 14,
                      fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 16),
              _TVFocusableItem(
                autofocus: true,
                onSelect: onResume,
                builder: (focused) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: focused ? Colors.white : Colors.transparent,
                      width: 2),
                    boxShadow: [
                      BoxShadow(color: AppTheme.accent.withOpacity(0.3),
                        blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Text('Resume',
                    style: TextStyle(color: Colors.white, fontSize: 14,
                      fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// OLED-friendly screensaver with bouncing VargasTV logo.
class _ScreensaverOverlay extends StatefulWidget {
  const _ScreensaverOverlay();

  @override
  State<_ScreensaverOverlay> createState() => _ScreensaverOverlayState();
}

class _ScreensaverOverlayState extends State<_ScreensaverOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  double _dx = 1.0, _dy = 1.0;
  double _x = 100, _y = 100;
  static const _logoW = 160.0, _logoH = 50.0;
  static const _speed = 1.2;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _x = rng.nextDouble() * 300 + 50;
    _y = rng.nextDouble() * 200 + 50;
    _dx = rng.nextBool() ? _speed : -_speed;
    _dy = rng.nextBool() ? _speed : -_speed;
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tick)
     ..repeat();
  }

  void _tick() {
    final size = MediaQuery.of(context).size;
    setState(() {
      _x += _dx;
      _y += _dy;
      if (_x <= 0 || _x + _logoW >= size.width) _dx = -_dx;
      if (_y <= 0 || _y + _logoH >= size.height) _dy = -_dy;
      _x = _x.clamp(0, size.width - _logoW);
      _y = _y.clamp(0, size.height - _logoH);
    });
  }

  @override
  void dispose() {
    _anim.removeListener(_tick);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(children: [
        Positioned(
          left: _x, top: _y,
          child: Opacity(
            opacity: 0.7,
            child: RichText(text: TextSpan(children: [
              TextSpan(
                text: 'Vargas',
                style: GoogleFonts.poppins(
                  fontSize: 28, fontWeight: FontWeight.w700,
                  color: Colors.white, letterSpacing: -0.5),
              ),
              TextSpan(
                text: 'TV',
                style: GoogleFonts.poppins(
                  fontSize: 28, fontWeight: FontWeight.w700,
                  color: AppTheme.accent, letterSpacing: -0.5),
              ),
            ])),
          ),
        ),
        const Positioned(
          bottom: 32, left: 0, right: 0,
          child: Text('Press any button to dismiss',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 12)),
        ),
      ]),
    );
  }
}
