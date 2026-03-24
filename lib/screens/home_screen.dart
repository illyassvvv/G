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

class _HomeScreenState extends State<HomeScreen> {
  // ── Data ────────────────────────────────────────────────────
  List<ChannelCategory> _categories = [];
  bool _loadingData = true;
  String? _dataError;

  // ── Player ──────────────────────────────────────────────────
  Channel? _activeChannel;
  BetterPlayerController? _miniCtrl;
  bool _miniLoading = false;
  bool _miniError   = false;

  // ── Micro-state: instant UI feedback via ValueNotifier ─────
  final ValueNotifier<int?> _activeIdNotifier = ValueNotifier<int?>(null);

  // ── Debounce timer for zapping engine ──────────────────────
  Timer? _zapTimer;
  static const _zapDebounce = Duration(milliseconds: 350);

  // ── UI state ────────────────────────────────────────────────
  final Set<String> _expanded = {};           // collapsed by default
  bool _searchOpen = false;
  final _searchCtrl = TextEditingController();
  List<Channel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  @override
  void dispose() {
    _zapTimer?.cancel();
    _killMini();
    _activeIdNotifier.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────
  Future<void> _loadChannels() async {
    setState(() { _loadingData = true; _dataError = null; });
    try {
      final cats = await ChannelService.fetchCategories();
      if (mounted) setState(() { _categories = cats; _loadingData = false; });
    } catch (e) {
      if (mounted) setState(() { _loadingData = false; _dataError = e.toString(); });
    }
  }

  Future<void> _refresh() async {
    final cats = await ChannelService.refreshCategories();
    if (mounted) setState(() => _categories = cats);
  }

  // ── Search ───────────────────────────────────────────────────
  void _onSearch(String q) {
    setState(() {
      _searchResults = ChannelService.search(_categories, q);
    });
  }

  void _closeSearch() {
    setState(() {
      _searchOpen   = false;
      _searchResults = [];
      _searchCtrl.clear();
    });
  }

  // ── Category toggle (accordion: only one open at a time) ─────
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

  // ── Channel selection (Bulletproof Zapping Engine) ─────────────
  void _select(Channel ch) {
    if (ch.streamUrl.isEmpty) {
      _showSnack('هذه القناة غير متوفرة حالياً', icon: Icons.tv_off_rounded);
      return;
    }
    if (_activeChannel?.id == ch.id) {
      _openFullscreen(ch);
      return;
    }

    // ─── STEP A: Instant UI feedback via ValueNotifier ───────
    // Updates ONLY the ChannelCards (<16ms) — no full tree rebuild.
    _activeIdNotifier.value = ch.id;

    // ─── STEP B: Immediately silence the old player ─────────
    _killMini();

    // Update data-level state + show loading overlay
    setState(() { _activeChannel = ch; _miniLoading = true; _miniError = false; });

    // Save to SharedPreferences
    context.read<AppProvider>().saveLastChannel(
      id:       ch.id,
      name:     ch.name,
      url:      ch.streamUrl,
      logo:     ch.logoUrl,
      number:   ch.number,
      category: ch.category,
    );

    // ─── STEP C: Cancel any pending zap timer ───────────────
    _zapTimer?.cancel();

    // ─── STEP D: Debounce — only start player after user stops zapping
    _zapTimer = Timer(_zapDebounce, () {
      if (mounted && _activeChannel?.id == ch.id) {
        _startMini(ch);
      }
    });
  }

  /// Safely tears down the current player.
  /// Mutes and pauses to silence audio within a single frame (<16ms),
  /// then schedules disposal in a microtask to avoid native platform
  /// exceptions when destroying a player that is mid-buffer.
  void _killMini() {
    final ctrl = _miniCtrl;
    _miniCtrl = null;
    if (ctrl == null) return;

    try {
      // Mute FIRST — guarantees zero audio bleed even if pause() is slow
      ctrl.videoPlayerController?.setVolume(0);
      ctrl.pause();
    } catch (_) {
      // Player may already be in a bad state — ignore.
    }

    // Deferred disposal: avoids native crashes when the ExoPlayer /
    // AVPlayer surface is still being torn down on the platform side.
    Future.microtask(() {
      try {
        ctrl.dispose();
      } catch (_) {
        // Swallow native dispose exceptions gracefully.
      }
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
            loadingWidget: const SizedBox.shrink(),
          ),
          eventListener: (event) {
            if (!mounted) return;
            // Guard: if user already zapped to another channel, ignore events
            if (_activeChannel?.id != ch.id) return;
            if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
              setState(() => _miniLoading = false);
            } else if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
              setState(() { _miniLoading = false; _miniError = true; });
            }
          },
        ),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          ch.streamUrl,
          liveStream: true,
          videoFormat: BetterPlayerVideoFormat.hls,
          bufferingConfiguration: const BetterPlayerBufferingConfiguration(
            minBufferMs: 2000, maxBufferMs: 12000,
            bufferForPlaybackMs: 1500, bufferForPlaybackAfterRebufferMs: 3000,
          ),
        ),
      );
      if (mounted) setState(() {});
    } catch (_) {
      // Catch malformed URL or controller init failures gracefully
      if (mounted) setState(() { _miniLoading = false; _miniError = true; });
    }
  }

  // ── Fullscreen: pass controller to resume (no rebuffer) ──────
  void _openFullscreen(Channel ch) {
    _miniCtrl?.pause();
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => PlayerScreen(
        channel: ch,
        existingController: _miniCtrl,
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    )).then((_) {
      if (_activeChannel != null && mounted) {
        _killMini();
        setState(() { _miniLoading = true; _miniError = false; });
        _startMini(_activeChannel!);
      }
    });
  }

  void _closeMini() {
    _zapTimer?.cancel();
    _killMini();
    _activeIdNotifier.value = null;
    context.read<AppProvider>().clearLastChannel();
    setState(() { _activeChannel = null; _miniLoading = false; _miniError = false; });
  }

  // ── Helpers ──────────────────────────────────────────────────
  void _showSnack(String msg, {IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        if (icon != null) ...[Icon(icon, color: AppTheme.accent, size: 18), const SizedBox(width: 8)],
        Text(msg),
      ]),
      duration: const Duration(seconds: 3),
    ));
  }

  IconData _catIcon(String name) {
    switch (name) {
      case 'sports_soccer':     return Icons.sports_soccer;
      case 'sports':            return Icons.sports;
      case 'sports_basketball': return Icons.sports_basketball;
      case 'sports_tennis':     return Icons.sports_tennis;
      case 'tv':                return Icons.tv;
      case 'movie':             return Icons.movie;
      case 'music_note':        return Icons.music_note;
      case 'news':              return Icons.newspaper;
      default:                  return Icons.live_tv;
    }
  }

  // ── Responsive grid helper for TV / tablet / phone ──────────
  SliverGridDelegate _responsiveGrid(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    int cols;
    double ratio;
    if (w >= 1200) {
      cols = 5; ratio = 1.1;       // Large TV
    } else if (w >= 900) {
      cols = 4; ratio = 1.05;      // Small TV / large tablet
    } else if (w >= 600) {
      cols = 3; ratio = 1.05;      // Tablet
    } else {
      cols = 2; ratio = 1.05;      // Phone
    }
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cols, crossAxisSpacing: 14,
      mainAxisSpacing: 14, childAspectRatio: ratio,
    );
  }

  bool _isTV(BuildContext context) => MediaQuery.of(context).size.width >= 900;

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final c    = prov.colors;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(children: [
        // Ambient glows — cinematic atmosphere
        Positioned(top: -120, right: -80,
          child: _glow(AppTheme.accent, 350, prov.isDark ? 0.08 : 0.04)),
        Positioned(top: -60, left: -100,
          child: _glow(AppTheme.green, 280, prov.isDark ? 0.05 : 0.03)),
        Positioned(bottom: -150, left: -50,
          child: _glow(AppTheme.accent, 300, prov.isDark ? 0.04 : 0.02)),

        // ── No internet banner ──────────────────────────────────
        if (!prov.hasInternet)
          Positioned(top: 0, left: 0, right: 0,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.live.withOpacity(0.95), AppTheme.live.withOpacity(0.85)],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(children: const [
                      Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 10),
                      Text('لا يوجد اتصال بالإنترنت',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ]),
                  ),
                ),
              ),
            ).animate().slideY(begin: -1, end: 0, duration: 300.ms),
          ),

        // ── Main scroll ─────────────────────────────────────────
        RefreshIndicator(
          onRefresh: _refresh,
          color: AppTheme.accent,
          backgroundColor: c.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              _buildAppBar(prov, c),

              // Mini player
              if (_activeChannel != null)
                SliverToBoxAdapter(child: _buildMiniPlayer(c, prov.isDark)),

              // Search results
              if (_searchOpen && _searchCtrl.text.isNotEmpty)
                ..._buildSearchResults(prov)
              else ...[
                // Skeleton or real categories
                if (_loadingData)
                  ..._buildSkeletons(prov)
                else if (_dataError != null)
                  SliverFillRemaining(child: _buildError(c))
                else
                  ..._buildCategories(prov, c),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ]),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────
  SliverAppBar _buildAppBar(AppProvider prov, TC c) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: c.appBarBg,
      surfaceTintColor: Colors.transparent,
      title: Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(color: AppTheme.accent.withOpacity(0.35), blurRadius: 16, spreadRadius: -2),
                  ]),
                child: const Icon(Icons.live_tv_rounded, color: Colors.black, size: 21)),
              const SizedBox(width: 12),
              RichText(text: TextSpan(
                style: TextStyle(fontFamily: 'Cairo', fontSize: 23, fontWeight: FontWeight.w900,
                    color: c.text, letterSpacing: -0.8),
                children: const [
                  TextSpan(text: 'ilyass '),
                  TextSpan(text: 'tv', style: TextStyle(color: AppTheme.accent)),
                ],
              )),
            ]),
      actions: [
        // Dark/light toggle
        _AppBarBtn(
          icon: prov.isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
          color: prov.isDark ? AppTheme.accent : const Color(0xFF6366F1),
          bg: prov.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
          border: prov.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
          onTap: prov.toggleTheme,
          animated: true,
        ),
        const SizedBox(width: 8),
        // Live badge
        Container(
          margin: const EdgeInsets.only(left: 6, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.live.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.live.withOpacity(0.25), width: 1)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _PulseDot(color: AppTheme.live),
            const SizedBox(width: 6),
            const Text('بث مباشر',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.live,
                letterSpacing: 0.3)),
          ]),
        ),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
        child: Container(height: 0.5, decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent,
            AppTheme.accent.withOpacity(0.15),
            AppTheme.accent.withOpacity(0.15),
            Colors.transparent,
          ])))),
    );
  }

  // ── Skeleton loading ─────────────────────────────────────────
  List<Widget> _buildSkeletons(AppProvider prov) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, i) => ChannelCardSkeleton(provider: prov),
            childCount: 6,
          ),
          gridDelegate: _responsiveGrid(context),
        ),
      ),
    ];
  }

  // ── Error state ──────────────────────────────────────────────
  Widget _buildError(TC c) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: c.surface2.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.cloud_off_rounded, color: c.textDim, size: 36),
      ),
      const SizedBox(height: 20),
      Text('تعذر تحميل القنوات',
        style: TextStyle(color: c.text, fontSize: 17, fontWeight: FontWeight.w800,
          letterSpacing: -0.3)),
      const SizedBox(height: 8),
      Text('تحقق من اتصالك وحاول مجدداً',
        style: TextStyle(color: c.textDim, fontSize: 13)),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: _loadChannels,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: const Text('إعادة المحاولة',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14)),
        ),
      ),
    ]));
  }

  // ── Search results ───────────────────────────────────────────
  List<Widget> _buildSearchResults(AppProvider prov) {
    final c = prov.colors;
    if (_searchResults.isEmpty) {
      return [SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, color: c.textDim, size: 40),
            const SizedBox(height: 12),
            Text('لا توجد نتائج',
              style: TextStyle(color: c.textDim, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        )),
      ))];
    }
    return [
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
        child: Text('${_searchResults.length} نتيجة',
          style: TextStyle(color: c.textDim, fontSize: 13, fontWeight: FontWeight.w600)),
      )),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate((_, i) {
            final ch = _searchResults[i];
            return ChannelCard(
              channel: ch,
              activeChannelNotifier: _activeIdNotifier,
              onTap: () => _select(ch),
              index: i,
              provider: prov,
            );
          }, childCount: _searchResults.length),
          gridDelegate: _responsiveGrid(context),
        ),
      ),
    ];
  }

  // ── Categories ───────────────────────────────────────────────
  List<Widget> _buildCategories(AppProvider prov, TC c) {
    final widgets = <Widget>[];
    for (int i = 0; i < _categories.length; i++) {
      final cat        = _categories[i];
      final isExpanded = _expanded.contains(cat.name);

      widgets.add(SliverToBoxAdapter(
        child: GestureDetector(
          onTap: () => _toggleCat(cat.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                width: 1,
              ),
              boxShadow: isExpanded
                  ? [
                      BoxShadow(color: AppTheme.accent.withOpacity(0.1), blurRadius: 16, spreadRadius: -2),
                      BoxShadow(color: c.shadow, blurRadius: 8),
                    ]
                  : [BoxShadow(color: c.shadow, blurRadius: 8)],
            ),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 46, height: 46,
                decoration: BoxDecoration(
                  gradient: isExpanded ? AppTheme.goldGradient : null,
                  color: isExpanded
                      ? null
                      : prov.isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isExpanded
                      ? [BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 12)]
                      : [],
                ),
                child: Icon(_catIcon(cat.icon),
                  color: isExpanded ? Colors.black : c.textDim, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cat.name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: isExpanded ? AppTheme.accent : c.text,
                    letterSpacing: -0.3)),
                const SizedBox(height: 3),
                Text('${cat.channels.length} قنوات',
                  style: TextStyle(fontSize: 12, color: c.textDim, fontWeight: FontWeight.w500)),
              ])),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isExpanded
                      ? AppTheme.accent.withOpacity(0.15)
                      : prov.isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12)),
                child: Text('${cat.channels.length}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: isExpanded ? AppTheme.accent : c.textDim)),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: Icon(Icons.keyboard_arrow_down_rounded,
                  color: isExpanded ? AppTheme.accent : c.textDim, size: 24)),
            ]),
          ).animate(delay: Duration(milliseconds: 70 * i))
              .fadeIn(duration: 300.ms)
              .slideX(begin: -0.04, end: 0, duration: 280.ms),
        ),
      ));

      if (isExpanded) {
        widgets.add(SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((_, idx) {
              final ch = cat.channels[idx];
              return ChannelCard(
                channel: ch,
                activeChannelNotifier: _activeIdNotifier,
                onTap:    () => _select(ch),
                index:    idx,
                provider: prov,
              );
            }, childCount: cat.channels.length),
            gridDelegate: _responsiveGrid(context),
          ),
        ));
      }
    }
    return widgets;
  }

  // ── Mini Player (Floating Island) ───────────────────────────
  Widget _buildMiniPlayer(TC c, bool isDark) {
    final ch = _activeChannel!;
    final isWide = _isTV(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 720 : double.infinity),
        child: GestureDetector(
      onTap: () => _openFullscreen(ch),
      child: Container(
        margin: EdgeInsets.fromLTRB(isWide ? 24 : 14, 18, isWide ? 24 : 14, 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A0A10) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? AppTheme.accent.withOpacity(0.15)
                : Colors.black.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withOpacity(isDark ? 0.12 : 0.06),
              blurRadius: 32,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: [
          // Video
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
            child: AspectRatio(aspectRatio: 16 / 9, child: Stack(fit: StackFit.expand, children: [
              if (_miniCtrl != null && !_miniError)
                BetterPlayer(controller: _miniCtrl!),

              // Loading spinner
              if (_miniLoading)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    gradient: LinearGradient(
                      colors: [Colors.black, const Color(0xFF0A0A14)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(width: 36, height: 36,
                        child: CircularProgressIndicator(
                          color: AppTheme.accent, strokeWidth: 2,
                          backgroundColor: AppTheme.accent.withOpacity(0.1),
                        )),
                      const SizedBox(height: 12),
                      Text('جاري التحميل...',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12,
                          letterSpacing: 0.3)),
                    ]),
                  ),
                ),

              // Error
              if (_miniError)
                Container(
                  color: Colors.black,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.live.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.wifi_off_rounded, color: AppTheme.live, size: 26),
                      ),
                      const SizedBox(height: 10),
                      const Text('تعذر التحميل',
                        style: TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          _zapTimer?.cancel();
                          _killMini();
                          setState(() { _miniLoading = true; _miniError = false; });
                          _startMini(ch);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: AppTheme.goldGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 8),
                            ],
                          ),
                          child: const Text('إعادة',
                            style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),

              // Fullscreen hint
              if (!_miniLoading && !_miniError)
                Positioned(bottom: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
                  ),
                ),

              // Top gradient overlay for depth
              if (!_miniLoading && !_miniError)
                Positioned(top: 0, left: 0, right: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
            ])),
          ),

          // Info row — polished floating bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      colors: [Color(0xFF0D0D14), Color(0xFF0A0A10)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFFAFAFA), Color(0xFFFFFFFF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(23)),
            ),
            child: Row(children: [
              // Logo
              Container(width: 42, height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accent.withOpacity(0.2), width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: ch.logoUrl,
                  cacheKey: 'logo_${ch.id}',
                  fit: BoxFit.contain,
                  memCacheWidth: 84,
                  memCacheHeight: 84,
                  fadeInDuration: const Duration(milliseconds: 150),
                  useOldImageOnUrlChange: true,
                  errorWidget: (_, __, ___) => Icon(Icons.tv_rounded, color: c.textDim, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              // Name + live badge
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ch.name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.text,
                    letterSpacing: -0.2)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.green.withOpacity(0.2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _PulseDot(color: AppTheme.green, size: 5),
                    const SizedBox(width: 5),
                    const Text('بث مباشر الآن',
                      style: TextStyle(fontSize: 10, color: AppTheme.green,
                        fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                  ]),
                ),
              ])),
              // Close
              _MiniBtn(
                icon: Icons.close_rounded,
                color: c.textDim,
                bg: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                onTap: _closeMini,
                margin: const EdgeInsets.only(right: 8),
              ),
              // Fullscreen
              _MiniBtn(
                icon: Icons.open_in_full_rounded,
                color: Colors.black, bg: null,
                gradient: AppTheme.goldGradient,
                onTap: () => _openFullscreen(ch),
              ),
            ]),
          ),
        ]),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.06, end: 0, duration: 300.ms),
    ),
    ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  Widget _glow(Color color, double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color.withOpacity(opacity), Colors.transparent]),
    ),
  );
}

// ── Reusable mini button ──────────────────────────────────────
class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? bg;
  final LinearGradient? gradient;
  final VoidCallback onTap;
  final EdgeInsets margin;

  const _MiniBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
    this.gradient,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: margin,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: bg, gradient: gradient, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 17),
    ),
  );
}

// ── AppBar icon button ────────────────────────────────────────
class _AppBarBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;
  final VoidCallback onTap;
  final bool animated;

  const _AppBarBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
    required this.onTap,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, color: color, size: 20);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1),
        ),
        child: animated
            ? AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: anim, child: FadeTransition(opacity: anim, child: child)),
                child: Icon(icon, key: ValueKey(icon), color: color, size: 20),
              )
            : iconWidget,
      ),
    );
  }
}

// ── Pulse dot ─────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const _PulseDot({required this.color, this.size = 6});
  @override State<_PulseDot> createState() => _PulseDotState();
}
class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _a = Tween(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _a,
    child: Container(width: widget.size, height: widget.size,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)));
}
