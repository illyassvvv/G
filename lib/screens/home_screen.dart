import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:better_player_plus/better_player_plus.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Data
  List<ChannelCategory> _categories = [];
  bool _loadingData = true;
  String? _dataError;

  // Player (SINGLE SOURCE OF TRUTH - never duplicated)
  Channel? _activeChannel;
  BetterPlayerController? _miniCtrl;
  bool _miniLoading = false;
  bool _miniError = false;
  bool _miniPlayerVisible = false;

  // Active channel notifier for efficient card updates
  final ValueNotifier<int?> _activeIdNotifier = ValueNotifier<int?>(null);

  // Zapping debounce
  Timer? _zapTimer;
  static const _zapDebounce = Duration(milliseconds: 350);

  // UI state
  final Set<String> _expanded = {};
  final ScrollController _scrollCtrl = ScrollController();

  // Mini player animation
  late final AnimationController _miniPlayerAnimCtrl;
  late final Animation<Offset> _miniPlayerSlide;

  @override
  void initState() {
    super.initState();
    _miniPlayerAnimCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350));
    _miniPlayerSlide = Tween<Offset>(
      begin: const Offset(0, 1), end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _miniPlayerAnimCtrl, curve: Curves.easeOutCubic));
    _loadChannels();
  }

  @override
  void dispose() {
    _zapTimer?.cancel();
    _killMini();
    _activeIdNotifier.dispose();
    _scrollCtrl.dispose();
    _miniPlayerAnimCtrl.dispose();
    super.dispose();
  }

  // -- Data loading
  Future<void> _loadChannels() async {
    setState(() { _loadingData = true; _dataError = null; });
    try {
      final cats = await ChannelService.fetchCategories();
      if (mounted) setState(() { _categories = cats; _loadingData = false; });
    } catch (e) {
      if (mounted) {
        setState(() { _loadingData = false; _dataError = e.toString(); });
      }
    }
  }

  Future<void> _refresh() async {
    final cats = await ChannelService.refreshCategories();
    if (mounted) setState(() => _categories = cats);
  }

  // -- Category toggle
  void _toggleCat(String name) {
    setState(() {
      if (_expanded.contains(name)) {
        _expanded.remove(name);
      } else {
        _expanded.clear();
        _expanded.add(name);
      }
    });
  }

  // -- Channel selection
  void _select(Channel ch) {
    if (ch.streamUrl.isEmpty) {
      _showSnack('Channel unavailable', icon: Icons.tv_off_rounded);
      return;
    }
    if (_activeChannel?.id == ch.id) {
      _openFullscreen(ch);
      return;
    }

    // Instant UI feedback
    _activeIdNotifier.value = ch.id;

    // Kill old player
    _killMini();

    setState(() {
      _activeChannel = ch;
      _miniLoading = true;
      _miniError = false;
      _miniPlayerVisible = true;
    });

    // Show mini player with animation
    _miniPlayerAnimCtrl.forward();

    // Scroll to top smoothly
    _scrollCtrl.animateTo(0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic);

    // Save to prefs + add to recent
    final prov = context.read<AppProvider>();
    prov.saveLastChannel(
      id: ch.id, name: ch.name, url: ch.streamUrl,
      logo: ch.logoUrl, number: ch.number, category: ch.category);
    prov.addRecentChannel(ch);

    // Debounced start
    _zapTimer?.cancel();
    _zapTimer = Timer(_zapDebounce, () {
      if (mounted && _activeChannel?.id == ch.id) _startMini(ch);
    });
  }

  void _killMini() {
    final ctrl = _miniCtrl;
    _miniCtrl = null;
    if (ctrl == null) return;
    try {
      ctrl.videoPlayerController?.setVolume(0);
      ctrl.pause();
    } catch (_) {}
    Future.microtask(() {
      try { ctrl.dispose(); } catch (_) {}
    });
  }

  void _startMini(Channel ch) {
    try {
      _miniCtrl = BetterPlayerController(
        BetterPlayerConfiguration(
          autoPlay: true,
          aspectRatio: 16 / 9,
          fit: BoxFit.contain,
          handleLifecycle: true,
          autoDispose: false,
          controlsConfiguration: BetterPlayerControlsConfiguration(
            showControls: false,
            loadingWidget: const SizedBox.shrink()),
          eventListener: (event) {
            if (!mounted || _activeChannel?.id != ch.id) return;
            if (event.betterPlayerEventType ==
                BetterPlayerEventType.initialized) {
              setState(() => _miniLoading = false);
            } else if (event.betterPlayerEventType ==
                BetterPlayerEventType.exception) {
              setState(() { _miniLoading = false; _miniError = true; });
            }
          }),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network, ch.streamUrl,
          liveStream: true,
          videoFormat: BetterPlayerVideoFormat.hls,
          bufferingConfiguration: const BetterPlayerBufferingConfiguration(
            minBufferMs: 2000, maxBufferMs: 12000,
            bufferForPlaybackMs: 1500,
            bufferForPlaybackAfterRebufferMs: 3000)));
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() { _miniLoading = false; _miniError = true; });
      }
    }
  }

  void _openFullscreen(Channel ch) {
    _miniCtrl?.pause();
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => PlayerScreen(
        channel: ch, existingController: _miniCtrl),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    )).then((_) {
      if (_activeChannel != null && mounted) {
        _killMini();
        setState(() { _miniLoading = true; _miniError = false; });
        _startMini(_activeChannel!);
      }
    });
  }

  void _closeMini() {
    _miniPlayerAnimCtrl.reverse().then((_) {
      _zapTimer?.cancel();
      _killMini();
      _activeIdNotifier.value = null;
      context.read<AppProvider>().clearLastChannel();
      if (mounted) {
        setState(() {
          _activeChannel = null;
          _miniLoading = false;
          _miniError = false;
          _miniPlayerVisible = false;
        });
      }
    });
  }

  void _showSnack(String msg, {IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        if (icon != null) ...[
          Icon(icon, color: AppTheme.accent, size: 18),
          const SizedBox(width: 8),
        ],
        Text(msg),
      ]),
      duration: const Duration(seconds: 3)));
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
      default: return Icons.live_tv;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final c = prov.colors;
    final bottomPadding = _miniPlayerVisible ? 90.0 : 0.0;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(children: [
        // Ambient glows
        Positioned(top: -120, right: -80,
          child: _glow(AppTheme.accent, 350, prov.isDark ? 0.06 : 0.03)),
        Positioned(bottom: -150, left: -50,
          child: _glow(AppTheme.primaryDark, 300, prov.isDark ? 0.04 : 0.02)),

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
                child: SafeArea(bottom: false,
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
                    ]))))
              .animate()
              .slideY(begin: -1, end: 0, duration: 300.ms))),

        // Main scroll content
        RefreshIndicator(
          onRefresh: _refresh,
          color: AppTheme.accent,
          backgroundColor: c.surface,
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
            slivers: [
              _buildAppBar(prov, c),

              // Recently watched section
              if (prov.recentChannels.isNotEmpty && !_loadingData)
                ..._buildRecentSection(prov, c),

              // Categories
              if (_loadingData)
                ..._buildSkeletons(prov)
              else if (_dataError != null)
                SliverFillRemaining(child: _buildError(c))
              else
                ..._buildCategories(prov, c),

              SliverToBoxAdapter(
                child: SizedBox(height: bottomPadding + 120)),
            ])),

        // MINI PLAYER - fixed at bottom (NEVER duplicated, NEVER in scroll)
        if (_miniPlayerVisible && _activeChannel != null)
          Positioned(left: 0, right: 0, bottom: 0,
            child: SlideTransition(
              position: _miniPlayerSlide,
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -300) {
                      _openFullscreen(_activeChannel!);
                    } else if (details.primaryVelocity! > 300) {
                      _closeMini();
                    }
                  }
                },
                child: _buildMiniPlayer(c, prov.isDark)))),
      ]),
    );
  }

  // -- App Bar
  SliverAppBar _buildAppBar(AppProvider prov, TC c) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: c.appBarBg,
      surfaceTintColor: Colors.transparent,
      title: Row(children: [
        Container(width: 38, height: 38,
          decoration: BoxDecoration(
            gradient: AppTheme.buttonGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: AppTheme.accent.withOpacity(0.3),
                blurRadius: 14, spreadRadius: -2),
            ]),
          child: const Icon(Icons.live_tv_rounded,
            color: Colors.white, size: 20)),
        const SizedBox(width: 12),
        RichText(text: TextSpan(
          style: TextStyle(fontFamily: 'Inter', fontSize: 22,
            fontWeight: FontWeight.w800, color: c.text,
            letterSpacing: -0.5),
          children: const [
            TextSpan(text: 'VarGas'),
            TextSpan(text: 'Tv',
              style: TextStyle(color: AppTheme.accent)),
          ])),
      ]),
      actions: [
        _AppBarBtn(
          icon: prov.themeMode == ThemeMode.dark
              ? Icons.wb_sunny_rounded
              : prov.themeMode == ThemeMode.light
                  ? Icons.nightlight_round
                  : Icons.brightness_auto_rounded,
          color: AppTheme.accent,
          bg: prov.isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
          border: prov.isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
          onTap: prov.toggleTheme),
        const SizedBox(width: 8),
        // LIVE badge
        Container(
          margin: const EdgeInsets.only(left: 4, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.live.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.live.withOpacity(0.25), width: 1)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            PulseDot(color: AppTheme.live, size: 7),
            const SizedBox(width: 6),
            const Text('LIVE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                color: AppTheme.live, letterSpacing: 1)),
          ])),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 0.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent,
              AppTheme.accent.withOpacity(0.15),
              AppTheme.accent.withOpacity(0.15),
              Colors.transparent,
            ])))),
    );
  }

  // -- Recently Watched
  List<Widget> _buildRecentSection(AppProvider prov, TC c) {
    final recentChannels = prov.getRecentAsChannels();
    if (recentChannels.isEmpty) return [];
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Row(children: [
            Icon(Icons.history_rounded, color: c.textDim, size: 18),
            const SizedBox(width: 8),
            Text('Recently Watched',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: c.textDim, letterSpacing: -0.2)),
          ]))),
      SliverToBoxAdapter(
        child: SizedBox(height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recentChannels.length,
            itemBuilder: (_, i) {
              final ch = recentChannels[i];
              final isActive = _activeChannel?.id == ch.id;
              return GestureDetector(
                onTap: () => _select(ch),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.accent.withOpacity(0.15)
                        : prov.isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? AppTheme.accent.withOpacity(0.4)
                          : prov.isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.06))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: ch.logoUrl, width: 28, height: 28,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) =>
                            Icon(Icons.tv, size: 16, color: c.textDim))),
                    const SizedBox(width: 8),
                    Text(ch.name,
                      style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? AppTheme.accent : c.text)),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      MiniEqualizer(color: AppTheme.accent,
                        width: 12, height: 10, barCount: 3),
                    ],
                  ])));
            }))),
    ];
  }

  // -- Skeletons
  List<Widget> _buildSkeletons(AppProvider prov) => [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, i) => ChannelCardSkeleton(provider: prov),
          childCount: 6),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 14,
          mainAxisSpacing: 14, childAspectRatio: 1.05)))];

  // -- Error
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
      GestureDetector(onTap: _loadChannels,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 28, vertical: 13),
          decoration: BoxDecoration(
            gradient: AppTheme.buttonGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: AppTheme.accent.withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 4)),
            ]),
          child: const Text('Retry',
            style: TextStyle(color: Colors.white,
              fontWeight: FontWeight.w800, fontSize: 14)))),
    ]));

  // -- Categories
  List<Widget> _buildCategories(AppProvider prov, TC c) {
    final widgets = <Widget>[];
    for (int i = 0; i < _categories.length; i++) {
      final cat = _categories[i];
      final isExpanded = _expanded.contains(cat.name);

      widgets.add(SliverToBoxAdapter(
        child: GestureDetector(
          onTap: () => _toggleCat(cat.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: isExpanded
                  ? (prov.isDark
                      ? AppTheme.accent.withOpacity(0.06)
                      : AppTheme.accent.withOpacity(0.04))
                  : (prov.isDark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.white.withOpacity(0.7)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isExpanded
                    ? AppTheme.accent.withOpacity(0.35)
                    : prov.isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06),
                width: 1),
              boxShadow: isExpanded
                  ? [
                      BoxShadow(
                        color: AppTheme.accent.withOpacity(0.1),
                        blurRadius: 16, spreadRadius: -2),
                      BoxShadow(color: c.shadow, blurRadius: 8),
                    ]
                  : [BoxShadow(color: c.shadow, blurRadius: 8)]),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: isExpanded
                      ? AppTheme.buttonGradient : null,
                  color: isExpanded ? null
                      : prov.isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: isExpanded
                      ? [BoxShadow(
                          color: AppTheme.accent.withOpacity(0.3),
                          blurRadius: 12)]
                      : []),
                child: Icon(_catIcon(cat.icon),
                  color: isExpanded ? Colors.white : c.textDim,
                  size: 21)),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.name,
                    style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isExpanded ? AppTheme.accent : c.text,
                      letterSpacing: -0.3)),
                  const SizedBox(height: 3),
                  Text('${cat.channels.length} channels',
                    style: TextStyle(fontSize: 12,
                      color: c.textDim,
                      fontWeight: FontWeight.w500)),
                ])),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isExpanded
                      ? AppTheme.accent.withOpacity(0.15)
                      : prov.isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12)),
                child: Text('${cat.channels.length}',
                  style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isExpanded ? AppTheme.accent : c.textDim))),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: Icon(Icons.keyboard_arrow_down_rounded,
                  color: isExpanded ? AppTheme.accent : c.textDim,
                  size: 24)),
            ]))
          .animate(delay: Duration(milliseconds: 60 * i))
              .fadeIn(duration: 300.ms)
              .slideX(begin: -0.04, end: 0, duration: 280.ms))));

      if (isExpanded) {
        widgets.add(SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((_, idx) {
              final ch = cat.channels[idx];
              return ChannelCard(
                channel: ch,
                activeChannelNotifier: _activeIdNotifier,
                onTap: () => _select(ch),
                onFavoriteToggle: () => prov.toggleFavorite(ch.id),
                isFavorite: prov.isFavorite(ch.id),
                index: idx,
                provider: prov);
            }, childCount: cat.channels.length),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 14,
              mainAxisSpacing: 14, childAspectRatio: 1.05))));
      }
    }
    return widgets;
  }

  // -- Mini Player (FIXED at bottom - never duplicated)
  Widget _buildMiniPlayer(TC c, bool isDark) {
    final ch = _activeChannel!;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        border: Border(top: BorderSide(
          color: isDark
              ? AppTheme.accent.withOpacity(0.15)
              : Colors.black.withOpacity(0.06))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.12),
            blurRadius: 20, offset: const Offset(0, -4)),
          BoxShadow(
            color: AppTheme.accent.withOpacity(isDark ? 0.08 : 0.04),
            blurRadius: 30, offset: const Offset(0, -8)),
        ]),
      child: SafeArea(top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(children: [
            // Thumbnail
            GestureDetector(
              onTap: () => _openFullscreen(ch),
              child: Container(
                width: 56, height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.accent.withOpacity(0.2))),
                clipBehavior: Clip.antiAlias,
                child: Stack(fit: StackFit.expand, children: [
                  if (_miniCtrl != null &&
                      !_miniError && !_miniLoading)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: BetterPlayer(controller: _miniCtrl!)),
                  if (_miniLoading)
                    Center(child: SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                        color: AppTheme.accent, strokeWidth: 1.5))),
                  if (_miniError)
                    Center(child: Icon(Icons.error_outline,
                      color: AppTheme.live, size: 18)),
                ]))),
            const SizedBox(width: 12),
            // Channel info
            Expanded(child: GestureDetector(
              onTap: () => _openFullscreen(ch),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ch.name,
                    style: TextStyle(fontSize: 13,
                      fontWeight: FontWeight.w700, color: c.text),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(children: [
                    PulseDot(color: AppTheme.live, size: 5),
                    const SizedBox(width: 4),
                    Text('LIVE NOW',
                      style: TextStyle(fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.live, letterSpacing: 0.5)),
                  ]),
                ]))),
            // Play/Pause
            GestureDetector(
              onTap: () {
                if (_miniCtrl != null) {
                  if (_miniCtrl!.isPlaying() == true) {
                    _miniCtrl!.pause();
                  } else {
                    _miniCtrl!.play();
                  }
                  setState(() {});
                }
              },
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.buttonGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppTheme.accent.withOpacity(0.3),
                      blurRadius: 8),
                  ]),
                child: Icon(
                  _miniCtrl?.isPlaying() == true
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white, size: 20))),
            const SizedBox(width: 8),
            // Expand
            GestureDetector(
              onTap: () => _openFullscreen(ch),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
                  shape: BoxShape.circle),
                child: Icon(Icons.open_in_full_rounded,
                  color: c.textDim, size: 16))),
            const SizedBox(width: 8),
            // Close
            GestureDetector(
              onTap: _closeMini,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
                  shape: BoxShape.circle),
                child: Icon(Icons.close_rounded,
                  color: c.textDim, size: 18))),
          ]))));
  }

  Widget _glow(Color color, double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withOpacity(opacity), Colors.transparent])));
}

class _AppBarBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;
  final VoidCallback onTap;
  const _AppBarBtn({
    required this.icon, required this.color, required this.bg,
    required this.border, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1)),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: anim,
          child: FadeTransition(opacity: anim, child: child)),
        child: Icon(icon, key: ValueKey(icon),
          color: color, size: 20))));
}
