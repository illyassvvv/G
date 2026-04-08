import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<ChannelCategory> _categories = [];
  bool _loadingData = true;
  String? _dataError;

  Channel? _activeChannel;
  BetterPlayerController? _miniCtrl;
  bool _miniLoading = false;
  bool _miniError = false;
  bool _miniPlayerVisible = false;
  bool _isExpanded = false;
  bool _isInFullscreen = false;
  bool _pipRequested = false;
  final GlobalKey _miniPlayerKey = GlobalKey();

  final ValueNotifier<int?> _activeIdNotifier = ValueNotifier<int?>(null);

  bool _showSearch = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<Channel> _searchResults = [];

  int _retryCount = 0;
  static const _maxRetries = 3;

  bool _isBuffering = false;

  Timer? _zapTimer;
  int _switchGen = 0;
  static const _zapDebounce = Duration(milliseconds: 350);

  final Set<String> _expanded = {};
  final ScrollController _scrollCtrl = ScrollController();
  final ScrollController _expandedListCtrl = ScrollController();

  late final AnimationController _miniPlayerAnimCtrl;
  late final Animation<Offset> _miniPlayerSlide;

  late final AnimationController _expandAnimCtrl;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _miniPlayerAnimCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
    _miniPlayerSlide = Tween<Offset>(
      begin: const Offset(0, 1), end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _miniPlayerAnimCtrl, curve: Curves.easeOutCubic));

    _expandAnimCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
    _expandAnim = CurvedAnimation(
      parent: _expandAnimCtrl, curve: Curves.easeInOut);

    _loadChannels();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _zapTimer?.cancel();
    _disposeController();
    _activeIdNotifier.dispose();
    _scrollCtrl.dispose();
    _expandedListCtrl.dispose();
    _miniPlayerAnimCtrl.dispose();
    _expandAnimCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    setState(() { _loadingData = true; _dataError = null; });
    try {
      final cats = await ChannelService.fetchCategories();
      if (mounted) {
        setState(() { _categories = cats; _loadingData = false; });
        _autoResumeLast();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loadingData = false; _dataError = e.toString(); });
      }
    }
  }

  void _autoResumeLast() {
    final prov = context.read<AppProvider>();
    if (prov.lastChannelId != null &&
        prov.lastChannelUrl != null &&
        _activeChannel == null) {
      for (final cat in _categories) {
        for (final ch in cat.channels) {
          if (ch.id == prov.lastChannelId) {
            _select(ch);
            return;
          }
        }
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text;
    if (query.isEmpty) {
      setState(() => _searchResults = []);
    } else {
      setState(() => _searchResults = ChannelService.search(_categories, query));
    }
  }

  Future<void> _refresh() async {
    final cats = await ChannelService.refreshCategories();
    if (mounted) setState(() => _categories = cats);
  }

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

  void _select(Channel ch) {
    HapticFeedback.lightImpact();
    if (ch.streamUrl.isEmpty) {
      _showSnack('Channel unavailable', icon: Icons.tv_off_rounded);
      return;
    }

    if (_activeChannel?.id == ch.id) {
      _scrollCtrl.animateTo(0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic);
      if (!_isExpanded) {
        setState(() => _isExpanded = true);
        _expandAnimCtrl.forward();
      }
      return;
    }

    _activeIdNotifier.value = ch.id;

    setState(() {
      _activeChannel = ch;
      _miniLoading = true;
      _miniError = false;
      _miniPlayerVisible = true;
    });

    _miniPlayerAnimCtrl.forward();

    final prov = context.read<AppProvider>();
    prov.setActiveChannel(ch);
    prov.saveLastChannel(
      id: ch.id, name: ch.name, url: ch.streamUrl,
      logo: ch.logoUrl, number: ch.number, category: ch.category);
    prov.addRecentChannel(ch);

    _zapTimer?.cancel();
    _zapTimer = Timer(_zapDebounce, () {
      if (mounted && _activeChannel?.id == ch.id) _switchChannel(ch);
    });
  }

  void _disposeController() {
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

  void _selectWithoutCollapse(Channel ch) {
    HapticFeedback.lightImpact();
    if (ch.streamUrl.isEmpty) return;
    if (_activeChannel?.id == ch.id) return;

    _activeIdNotifier.value = ch.id;
    setState(() {
      _activeChannel = ch;
      _miniLoading = true;
      _miniError = false;
    });

    final prov = context.read<AppProvider>();
    prov.setActiveChannel(ch);
    prov.saveLastChannel(
      id: ch.id, name: ch.name, url: ch.streamUrl,
      logo: ch.logoUrl, number: ch.number, category: ch.category);
    prov.addRecentChannel(ch);

    _zapTimer?.cancel();
    _zapTimer = Timer(_zapDebounce, () {
      if (mounted && _activeChannel?.id == ch.id) _switchChannel(ch);
    });
  }

  void _switchChannel(Channel ch) async {
    final gen = ++_switchGen;
    _retryCount = 0;
    final prov = context.read<AppProvider>();
    final dataSaver = prov.dataSaverEnabled;
    try {
      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network, ch.streamUrl,
        liveStream: true,
        videoFormat: BetterPlayerVideoFormat.hls,
        // ─── SPOOFED HEADERS ADDED HERE ───────────────────────
        headers: const {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36",
          "Referer": "https://x.com/",
        },
        bufferingConfiguration: BetterPlayerBufferingConfiguration(
          minBufferMs: dataSaver ? 1000 : 2000,
          maxBufferMs: dataSaver ? 6000 : 12000,
          bufferForPlaybackMs: dataSaver ? 1000 : 1500,
          bufferForPlaybackAfterRebufferMs: dataSaver ? 2000 : 3000));

      if (_miniCtrl != null) {
        setState(() { _miniLoading = true; _miniError = false; });
        try {
          _miniCtrl!.videoPlayerController?.setVolume(0);
          await _miniCtrl!.pause();
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 80));
        if (!mounted || gen != _switchGen) return;
        _miniCtrl!.setupDataSource(dataSource);
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && _miniLoading && gen == _switchGen) {
            setState(() { _miniLoading = false; _miniError = true; });
          }
        });
      } else {
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
              if (!mounted) return;
              if (event.betterPlayerEventType ==
                  BetterPlayerEventType.initialized) {
                if (mounted) {
                  setState(() { _miniLoading = false; _isBuffering = false; _retryCount = 0; });
                  final vol = context.read<AppProvider>().volumeLevel;
                  try {
                    _miniCtrl?.videoPlayerController?.setVolume(vol);
                    _miniCtrl?.play();
                  } catch (_) {}
                }
              } else if (event.betterPlayerEventType ==
                  BetterPlayerEventType.exception) {
                setState(() { _miniLoading = false; _miniError = true; });
                _autoRetryStream();
              } else if (event.betterPlayerEventType ==
                  BetterPlayerEventType.bufferingStart) {
                if (mounted) setState(() => _isBuffering = true);
              } else if (event.betterPlayerEventType ==
                  BetterPlayerEventType.bufferingEnd) {
                if (mounted) setState(() => _isBuffering = false);
              }
            }),
          betterPlayerDataSource: dataSource);
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() { _miniLoading = false; _miniError = true; });
        _autoRetryStream();
      }
    }
  }

  void _autoRetryStream() {
    if (_retryCount < _maxRetries && _activeChannel != null) {
      _retryCount++;
      Future.delayed(Duration(seconds: _retryCount), () {
        if (mounted && _miniError && _activeChannel != null) {
          _switchChannel(_activeChannel!);
        }
      });
    }
  }

  List<Channel> _getChannelListForCategory(String category) {
    return _categories
        .where((cat) => cat.name == category)
        .expand((cat) => cat.channels)
        .toList();
  }

  void _openFullscreen(Channel ch) {
    HapticFeedback.mediumImpact();
    if (_isExpanded) {
      setState(() => _isExpanded = false);
      _expandAnimCtrl.reverse();
    }
    setState(() => _isInFullscreen = true);

    final channelList = _getChannelListForCategory(ch.category);
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => PlayerScreen(
        channel: ch,
        existingController: _miniCtrl,
        onPipRequested: () => setState(() => _pipRequested = true),
        channelList: channelList,
        onChannelChanged: (newCh) {
          _activeIdNotifier.value = newCh.id;
          setState(() {
            _activeChannel = newCh;
            _miniLoading = true;
            _miniError = false;
          });
          final prov = context.read<AppProvider>();
          prov.setActiveChannel(newCh);
          prov.saveLastChannel(
            id: newCh.id, name: newCh.name, url: newCh.streamUrl,
            logo: newCh.logoUrl, number: newCh.number, category: newCh.category);
          prov.addRecentChannel(newCh);
        },
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    )).then((_) {
      if (mounted) {
        setState(() => _isInFullscreen = false);
        if (_activeChannel != null && _miniCtrl != null) {
          try { _miniCtrl!.play(); } catch (_) {}
          if (_pipRequested) {
            _pipRequested = false;
            Future.delayed(const Duration(milliseconds: 200), () {
              _miniCtrl?.enablePictureInPicture(_miniPlayerKey);
            });
          }
        }
      }
    });
  }

  void _closeMini() {
    if (_isExpanded) {
      _expandAnimCtrl.reverse();
    }
    _miniPlayerAnimCtrl.reverse().then((_) {
      _zapTimer?.cancel();
      _disposeController();
      _activeIdNotifier.value = null;
      final prov = context.read<AppProvider>();
      prov.clearLastChannel();
      prov.closePlayer();
      if (mounted) {
        setState(() {
          _activeChannel = null;
          _miniLoading = false;
          _miniError = false;
          _miniPlayerVisible = false;
          _isExpanded = false;
          _isInFullscreen = false;
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
        Positioned(top: -120, right: -80,
          child: _glow(AppTheme.accent, 350, prov.isDark ? 0.06 : 0.03)),
        Positioned(bottom: -150, left: -50,
          child: _glow(AppTheme.primaryDark, 300, prov.isDark ? 0.04 : 0.02)),

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

              if (_showSearch && _searchResults.isNotEmpty)
                ..._buildSearchResults(prov, c),

              if (!_showSearch && prov.favoriteIds.isNotEmpty && !_loadingData)
                ..._buildFavoritesSection(prov, c),

              if (!_showSearch && prov.recentChannels.isNotEmpty && !_loadingData)
                ..._buildRecentSection(prov, c),

              if (!_showSearch)
                if (_loadingData)
                  ..._buildSkeletons(prov)
                else if (_dataError != null)
                  SliverFillRemaining(child: _buildError(c))
                else
                  ..._buildCategories(prov, c),

              SliverToBoxAdapter(
                child: SizedBox(height: bottomPadding + 120)),
            ])),

        if (_miniPlayerVisible && _activeChannel != null && _isExpanded && !_isInFullscreen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _expandAnimCtrl.reverse().then((_) {
                  if (mounted) setState(() => _isExpanded = false);
                });
              },
              child: Container(color: Colors.black.withOpacity(0.3)))),

        if (_miniPlayerVisible && _activeChannel != null && _isExpanded && !_isInFullscreen)
          Positioned(left: 0, right: 0, bottom: 0,
            top: MediaQuery.of(context).size.height * 0.35,
            child: AnimatedBuilder(
              animation: _expandAnim,
              builder: (_, child) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1), end: Offset.zero,
                ).animate(_expandAnim),
                child: child,
              ),
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -300) {
                      _openFullscreen(_activeChannel!);
                    } else if (details.primaryVelocity! > 300) {
                      _expandAnimCtrl.reverse().then((_) {
                        if (mounted) setState(() => _isExpanded = false);
                      });
                    }
                  }
                },
                child: RepaintBoundary(child: _buildExpandedPlayer(c, prov))),
            )),

        if (_miniPlayerVisible && _activeChannel != null && !_isExpanded && !_isInFullscreen)
            Positioned(left: 0, right: 0, bottom: 0,
              child: RepaintBoundary(child: SlideTransition(
                position: _miniPlayerSlide,
                child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -300) {
                      setState(() => _isExpanded = true);
                      _expandAnimCtrl.forward();
                    } else if (details.primaryVelocity! > 300) {
                      _closeMini();
                    }
                  }
                },
                child: _buildMiniPlayer(c, prov.isDark))))),
      ]),
    );
  }

  SliverAppBar _buildAppBar(AppProvider prov, TC c) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: c.appBarBg,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0), end: Offset.zero,
            ).animate(anim),
            child: child)),
        child: _showSearch
            ? _buildInlineSearch(c, prov)
            : Row(key: const ValueKey('title'), children: [
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
      ),
      actions: _showSearch
          ? [
              _AppBarBtn(
                icon: Icons.close_rounded,
                color: AppTheme.live,
                bg: AppTheme.live.withOpacity(0.1),
                border: AppTheme.live.withOpacity(0.2),
                onTap: () => setState(() {
                  _showSearch = false;
                  _searchFocus.unfocus();
                  _searchCtrl.clear();
                  _searchResults = [];
                })),
              const SizedBox(width: 16),
            ]
          : [
              _AppBarBtn(
                icon: Icons.search_rounded,
                color: AppTheme.accent,
                bg: prov.isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04),
                border: prov.isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
                onTap: () => setState(() {
                  _showSearch = true;
                  Future.microtask(() => _searchFocus.requestFocus());
                })),
              const SizedBox(width: 8),
              _AppBarBtn(
                icon: prov.dataSaverEnabled
                    ? Icons.data_saver_on_rounded
                    : Icons.data_saver_off_rounded,
                color: AppTheme.accent,
                bg: prov.dataSaverEnabled
                    ? AppTheme.accent.withOpacity(0.15)
                    : prov.isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                border: prov.dataSaverEnabled
                    ? AppTheme.accent.withOpacity(0.3)
                    : prov.isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                onTap: () {
                  final willEnable = !prov.dataSaverEnabled;
                  prov.toggleDataSaver();
                  _showSnack(
                    willEnable ? 'Data Saver ON' : 'Data Saver OFF',
                    icon: Icons.data_saver_on_rounded);
                }),
              const SizedBox(width: 8),
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
              const SizedBox(width: 16),
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

  Widget _buildInlineSearch(TC c, AppProvider prov) {
    return Container(
      key: const ValueKey('search'),
      height: 40,
      decoration: BoxDecoration(
        color: prov.isDark
            ? Colors.white.withOpacity(0.07)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: prov.isDark
              ? AppTheme.accent.withOpacity(0.25)
              : AppTheme.accent.withOpacity(0.3),
          width: 1.2)),
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocus,
        style: TextStyle(
          color: c.text,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: 'Search channels...',
          hintStyle: TextStyle(
            color: c.textDim.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.w400),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(Icons.search_rounded,
              color: AppTheme.accent, size: 18)),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40, minHeight: 40),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchCtrl,
            builder: (_, val, __) => val.text.isEmpty
                ? const SizedBox.shrink()
                : GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _searchResults = []);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(Icons.cancel_rounded,
                        color: c.textDim.withOpacity(0.5), size: 17)))),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 36, minHeight: 40),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  List<Widget> _buildSearchResults(AppProvider prov, TC c) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: Text('${_searchResults.length} results',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: c.textDim)))),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate((_, idx) {
            final ch = _searchResults[idx];
            return ChannelCard(
              channel: ch,
              activeChannelNotifier: _activeIdNotifier,
              onTap: () => _select(ch),
              onFavoriteToggle: () => prov.toggleFavorite(ch.id),
              isFavorite: prov.isFavorite(ch.id),
              index: idx,
              provider: prov);
          }, childCount: _searchResults.length),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 14,
            mainAxisSpacing: 14, childAspectRatio: 1.05))),
    ];
  }

  List<Widget> _buildFavoritesSection(AppProvider prov, TC c) {
    final favChannels = prov.getFavoriteChannels(_categories);
    if (favChannels.isEmpty) return [];
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Row(children: [
            Icon(Icons.star_rounded, color: const Color(0xFFFBBF24), size: 18),
            const SizedBox(width: 8),
            Text('Favorites',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: c.textDim, letterSpacing: -0.2)),
          ]))),
      SliverToBoxAdapter(
        child: SizedBox(height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: favChannels.length,
            itemBuilder: (_, i) {
              final ch = favChannels[i];
              final isActive = _activeChannel?.id == ch.id;
              return GestureDetector(
                onTap: () => _select(ch),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
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
                    const SizedBox(width: 4),
                  ])));
            }))),
    ];
  }

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
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () => _select(ch),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
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
                        const SizedBox(width: 4),
                      ]))),
                  Positioned(
                    top: 0, right: 6,
                    child: GestureDetector(
                      onTap: () => prov.removeRecentChannel(ch.id),
                      child: Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          color: prov.isDark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.black.withOpacity(0.08),
                          shape: BoxShape.circle),
                        child: Icon(Icons.close_rounded,
                          size: 11,
                          color: prov.isDark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black.withOpacity(0.5))))),
                ]);
            }))),
    ];
  }

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

  List<Widget> _buildCategories(AppProvider prov, TC c) {
    final widgets = <Widget>[];
    for (int i = 0; i < _categories.length; i++) {
      final cat = _categories[i];
      final isExpanded = _expanded.contains(cat.name);

      widgets.add(SliverToBoxAdapter(
        child: GestureDetector(
          onTap: () => _toggleCat(cat.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: isExpanded
                  ? LinearGradient(colors: [
                      prov.isDark
                          ? AppTheme.accent.withOpacity(0.06)
                          : AppTheme.accent.withOpacity(0.04),
                      prov.isDark
                          ? AppTheme.accent.withOpacity(0.03)
                          : AppTheme.accent.withOpacity(0.02),
                    ], begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : LinearGradient(colors: [
                      prov.isDark
                          ? Colors.white.withOpacity(0.03)
                          : Colors.white.withOpacity(0.7),
                      prov.isDark
                          ? Colors.white.withOpacity(0.03)
                          : Colors.white.withOpacity(0.7),
                    ]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isExpanded
                    ? AppTheme.accent.withOpacity(0.35)
                    : prov.isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06),
                width: 1)),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: isExpanded
                      ? AppTheme.buttonGradient
                      : LinearGradient(colors: [
                          prov.isDark
                              ? Colors.white.withOpacity(0.06)
                              : Colors.black.withOpacity(0.04),
                          prov.isDark
                              ? Colors.white.withOpacity(0.03)
                              : Colors.black.withOpacity(0.02),
                        ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isExpanded
                        ? AppTheme.accent.withOpacity(0.6)
                        : AppTheme.accent.withOpacity(prov.isDark ? 0.15 : 0.08),
                    width: isExpanded ? 1.5 : 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withOpacity(isExpanded ? 0.45 : 0.0),
                      blurRadius: isExpanded ? 16.0 : 0.0,
                      spreadRadius: isExpanded ? -2.0 : 0.0,
                    ),
                  ],
                ),
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
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
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
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
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

  Widget _buildMiniPlayer(TC c, bool isDark) {
    final ch = _activeChannel!;
    return GestureDetector(
      onTap: () {
        setState(() => _isExpanded = true);
        _expandAnimCtrl.forward();
      },
      child: Container(
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
            Container(
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
                  if (_miniCtrl != null)
                    Opacity(
                      opacity: (!_miniError && !_miniLoading) ? 1.0 : 0.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: BetterPlayer(key: _miniPlayerKey, controller: _miniCtrl!))),
                  if (_miniLoading)
                    Center(child: SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(
                        color: AppTheme.accent, strokeWidth: 1.5))),
                  if (_miniError)
                    Center(child: Icon(Icons.error_outline,
                      color: AppTheme.live, size: 18)),
                ])),
            const SizedBox(width: 12),
            Expanded(child: Column(
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
                    const SizedBox(width: 6),
                    Icon(
                      _isBuffering ? Icons.wifi_rounded : Icons.wifi_rounded,
                      size: 12,
                      color: _miniError
                          ? AppTheme.live
                          : _isBuffering
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF22C55E)),
                  ]),
                ])),
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
          ])))));
  }

  Widget _buildExpandedPlayer(TC c, AppProvider prov) {
    final ch = _activeChannel!;
    final isDark = prov.isDark;
    final activeCat = ch.category;
    final allChannels = _categories
        .where((cat) => cat.name == activeCat)
        .expand((cat) => cat.channels)
        .toList();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(
          color: AppTheme.accent.withOpacity(0.2), width: 1))),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.15),
            borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.black,
                child: Stack(fit: StackFit.expand, children: [
                  if (_miniCtrl != null)
                    Opacity(
                      opacity: (!_miniError && !_miniLoading) ? 1.0 : 0.0,
                      child: BetterPlayer(controller: _miniCtrl!)),
                  if (_miniLoading)
                    Center(child: CircularProgressIndicator(
                      color: AppTheme.accent, strokeWidth: 2)),
                  if (_miniError)
                    Center(child: Icon(Icons.error_outline,
                      color: AppTheme.live, size: 32)),
                  Positioned(
                    top: 8, right: 8,
                    child: Row(children: [
                      GestureDetector(
                        onTap: () => _openFullscreen(ch),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.fullscreen_rounded,
                            color: Colors.white, size: 18))),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          _expandAnimCtrl.reverse().then((_) {
                            if (mounted) setState(() => _isExpanded = false);
                          });
                          _closeMini();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 18))),
                    ])),
                ]))))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ch.name,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  PulseDot(color: AppTheme.live, size: 5),
                  const SizedBox(width: 4),
                  Text('LIVE', style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w700, color: AppTheme.live, letterSpacing: 0.5)),
                ]),
              ])),
            GestureDetector(
              onTap: () {
                if (_miniCtrl != null) {
                  _miniCtrl!.isPlaying() == true ? _miniCtrl!.pause() : _miniCtrl!.play();
                  setState(() {});
                }
              },
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.buttonGradient, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 8)]),
                child: Icon(
                  _miniCtrl?.isPlaying() == true ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white, size: 22))),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _openFullscreen(ch),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                  shape: BoxShape.circle),
                child: Icon(Icons.fullscreen_rounded, color: c.textDim, size: 20))),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _expandAnimCtrl.reverse().then((_) {
                  if (mounted) setState(() => _isExpanded = false);
                });
              },
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                  shape: BoxShape.circle),
                child: Icon(Icons.keyboard_arrow_down_rounded, color: c.textDim, size: 20))),
          ])),
        Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
        Expanded(
          child: ListView.builder(
            controller: _expandedListCtrl,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: allChannels.length,
            itemBuilder: (_, i) {
              final listCh = allChannels[i];
              final isPlaying = listCh.id == ch.id;
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: listCh.logoUrl, width: 32, height: 32,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => Icon(Icons.tv, size: 18, color: c.textDim))),
                title: Text(listCh.name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: isPlaying ? AppTheme.accent : c.text),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: isPlaying
                    ? SmoothEqualizer(color: AppTheme.accent, width: 14, height: 12, barCount: 3)
                    : Text('CH ${listCh.number}',
                        style: TextStyle(fontSize: 10, color: c.textDim)),
                onTap: () {
                  _selectWithoutCollapse(listCh);
                });
            })),
      ]));
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
