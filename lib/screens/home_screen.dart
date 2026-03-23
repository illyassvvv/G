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
    _killMini();
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

  // ── Category toggle ──────────────────────────────────────────
  void _toggleCat(String name) {
    setState(() {
      _expanded.contains(name) ? _expanded.remove(name) : _expanded.add(name);
    });
  }

  // ── Channel selection ─────────────────────────────────────────
  void _select(Channel ch) {
    if (ch.streamUrl.isEmpty) {
      _showSnack('هذه القناة غير متوفرة حالياً', icon: Icons.tv_off_rounded);
      return;
    }
    if (_activeChannel?.id == ch.id) {
      _openFullscreen(ch);
      return;
    }
    // Kill old player completely before starting new one → no audio overlap
    _killMini();
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

    // Short delay ensures old controller is fully torn down
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted && _activeChannel?.id == ch.id) _startMini(ch);
    });
  }

  void _killMini() {
    _miniCtrl?.pause();
    _miniCtrl?.dispose();
    _miniCtrl = null;
  }

  void _startMini(Channel ch) {
    _miniCtrl = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        handleLifecycle: true,
        autoDispose: false,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls: false,
          showLoading: false,           // we show our own spinner
        ),
        eventListener: (event) {
          if (!mounted) return;
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
    _killMini();
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

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final c    = prov.colors;

    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(children: [
        // Ambient glows
        Positioned(top: -100, right: -100, child: _glow(AppTheme.green, 300, 0.06)),
        Positioned(top: -50,  left: -80,  child: _glow(AppTheme.accent, 250, 0.04)),

        // ── No internet banner ──────────────────────────────────
        if (!prov.hasInternet)
          Positioned(top: 0, left: 0, right: 0,
            child: Material(
              color: AppTheme.live.withOpacity(0.92),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: const [
                    Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('لا يوجد اتصال بالإنترنت',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ]),
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
                SliverToBoxAdapter(child: _buildMiniPlayer(c, prov)),

              // Search results
              if (_searchOpen && _searchCtrl.text.isNotEmpty)
                ..._buildSearchResults(prov, c)
              else ...[
                // Skeleton or real categories
                if (_loadingData)
                  ..._buildSkeletons(prov)
                else if (_dataError != null)
                  SliverFillRemaining(child: _buildError(c))
                else
                  ..._buildCategories(prov, c),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
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
      title: _searchOpen
          ? TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _onSearch,
              style: TextStyle(color: c.text, fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'ابحث عن قناة...',
                hintStyle: TextStyle(color: c.textDim, fontFamily: 'Cairo'),
                border: InputBorder.none,
              ),
            )
          : Row(children: [
              Container(width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 12)]),
                child: const Icon(Icons.live_tv_rounded, color: Colors.black, size: 20)),
              const SizedBox(width: 12),
              RichText(text: TextSpan(
                style: TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w900,
                    color: c.text, letterSpacing: -0.5),
                children: const [
                  TextSpan(text: 'ilyass '),
                  TextSpan(text: 'tv', style: TextStyle(color: AppTheme.accent)),
                ],
              )),
            ]),
      actions: [
        // Search toggle
        _AppBarBtn(
          icon: _searchOpen ? Icons.close_rounded : Icons.search_rounded,
          color: _searchOpen ? AppTheme.live : c.textDim,
          bg: c.surface2, border: c.border,
          onTap: () {
            if (_searchOpen) _closeSearch();
            else setState(() => _searchOpen = true);
          },
        ),
        const SizedBox(width: 6),
        // Dark/light toggle
        _AppBarBtn(
          icon: prov.isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
          color: prov.isDark ? AppTheme.accent : const Color(0xFF5B5BD6),
          bg: c.surface2, border: c.border,
          onTap: prov.toggleTheme,
          animated: true,
        ),
        const SizedBox(width: 6),
        // Refresh
        _AppBarBtn(
          icon: Icons.refresh_rounded,
          color: c.textDim,
          bg: c.surface2, border: c.border,
          onTap: _refresh,
        ),
        // Live badge
        Container(
          margin: const EdgeInsets.only(left: 6, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.live.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.live.withOpacity(0.3), width: 1)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _PulseDot(color: AppTheme.live),
            const SizedBox(width: 5),
            const Text('بث مباشر',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.live)),
          ]),
        ),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.transparent,
            AppTheme.accent.withOpacity(0.2),
            AppTheme.green.withOpacity(0.2),
            Colors.transparent,
          ])))),
    );
  }

  // ── Skeleton loading ─────────────────────────────────────────
  List<Widget> _buildSkeletons(AppProvider prov) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, i) => ChannelCardSkeleton(provider: prov),
            childCount: 6,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12,
            mainAxisSpacing: 12, childAspectRatio: 1.1,
          ),
        ),
      ),
    ];
  }

  // ── Error state ──────────────────────────────────────────────
  Widget _buildError(TC c) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.cloud_off_rounded, color: c.textDim, size: 52),
      const SizedBox(height: 16),
      Text('تعذر تحميل القنوات',
        style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('تحقق من اتصالك وحاول مجدداً',
        style: TextStyle(color: c.textDim, fontSize: 13)),
      const SizedBox(height: 20),
      GestureDetector(
        onTap: _loadChannels,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient, borderRadius: BorderRadius.circular(14)),
          child: const Text('إعادة المحاولة',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
        ),
      ),
    ]));
  }

  // ── Search results ───────────────────────────────────────────
  List<Widget> _buildSearchResults(AppProvider prov, TC c) {
    if (_searchResults.isEmpty) {
      return [SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(child: Text('لا توجد نتائج',
          style: TextStyle(color: c.textDim, fontSize: 15))),
      ))];
    }
    return [
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        child: Text('${_searchResults.length} نتيجة',
          style: TextStyle(color: c.textDim, fontSize: 13)),
      )),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate((_, i) {
            final ch = _searchResults[i];
            return ChannelCard(
              channel: ch, isActive: _activeChannel?.id == ch.id,
              onTap: () => _select(ch), index: i, provider: prov,
            );
          }, childCount: _searchResults.length),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 12,
            mainAxisSpacing: 12, childAspectRatio: 1.1,
          ),
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
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                c.surface.withOpacity(0.9),
                c.surface2.withOpacity(0.6),
              ], begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isExpanded ? AppTheme.accent.withOpacity(0.3) : c.border, width: 1),
              boxShadow: [BoxShadow(color: c.shadow, blurRadius: 10)],
            ),
            child: Row(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: isExpanded ? AppTheme.goldGradient
                      : LinearGradient(colors: [c.surface2, c.surface2]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isExpanded
                      ? [BoxShadow(color: AppTheme.accent.withOpacity(0.25), blurRadius: 10)]
                      : [],
                ),
                child: Icon(_catIcon(cat.icon),
                  color: isExpanded ? Colors.black : c.textDim, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cat.name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: isExpanded ? AppTheme.accent : c.text)),
                const SizedBox(height: 2),
                Text('${cat.channels.length} قنوات',
                  style: TextStyle(fontSize: 12, color: c.textDim)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isExpanded ? AppTheme.accent.withOpacity(0.15) : c.surface2,
                  borderRadius: BorderRadius.circular(10)),
                child: Text('${cat.channels.length}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: isExpanded ? AppTheme.accent : c.textDim))),
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((_, idx) {
              final ch = cat.channels[idx];
              return ChannelCard(
                channel: ch,
                isActive: _activeChannel?.id == ch.id,
                onTap:    () => _select(ch),
                index:    idx,
                provider: prov,
              );
            }, childCount: cat.channels.length),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 12,
              mainAxisSpacing: 12, childAspectRatio: 1.1,
            ),
          ),
        ));
      }
    }
    return widgets;
  }

  // ── Mini Player ──────────────────────────────────────────────
  Widget _buildMiniPlayer(TC c, AppProvider prov) {
    final ch = _activeChannel!;
    return GestureDetector(
      onTap: () => _openFullscreen(ch),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accent.withOpacity(0.2), width: 1),
          boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.08), blurRadius: 24)],
        ),
        child: Column(children: [
          // Video
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            child: AspectRatio(aspectRatio: 16 / 9, child: Stack(fit: StackFit.expand, children: [
              if (_miniCtrl != null && !_miniError)
                BetterPlayer(controller: _miniCtrl!),

              // Single loading spinner
              if (_miniLoading)
                Container(color: Colors.black, child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(width: 34, height: 34,
                      child: CircularProgressIndicator(
                        color: AppTheme.accent, strokeWidth: 2.5,
                        backgroundColor: AppTheme.accent.withOpacity(0.15),
                      )),
                    const SizedBox(height: 10),
                    Text('جاري التحميل...',
                      style: TextStyle(color: c.textDim, fontSize: 12)),
                  ]),
                )),

              // Error
              if (_miniError)
                Container(color: Colors.black, child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.wifi_off_rounded, color: AppTheme.live, size: 32),
                  const SizedBox(height: 8),
                  const Text('تعذر التحميل',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      _killMini();
                      setState(() { _miniLoading = true; _miniError = false; });
                      _startMini(ch);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient, borderRadius: BorderRadius.circular(8)),
                      child: const Text('إعادة',
                        style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w700)),
                    )),
                ])),

              // Fullscreen hint
              if (!_miniLoading && !_miniError)
                Positioned(bottom: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18))),
            ])),
          ),

          // Info row
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19))),
            child: Row(children: [
              // Logo
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.2), width: 1)),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(imageUrl: ch.logoUrl, fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => Icon(Icons.tv_rounded, color: c.textDim, size: 18))),
              const SizedBox(width: 12),
              // Name + live
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ch.name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c.text)),
                const SizedBox(height: 3),
                Row(children: [
                  _PulseDot(color: AppTheme.green, size: 5),
                  const SizedBox(width: 5),
                  const Text('بث مباشر الآن',
                    style: TextStyle(fontSize: 11, color: AppTheme.green, fontWeight: FontWeight.w700)),
                ]),
              ])),
              // Close
              _MiniBtn(
                icon: Icons.close_rounded,
                color: c.textDim, bg: c.surface2,
                onTap: _closeMini,
                margin: const EdgeInsets.only(right: 6),
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
      ).animate().fadeIn(duration: 280.ms).slideY(begin: -0.08, end: 0, duration: 280.ms),
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg, gradient: gradient, borderRadius: BorderRadius.circular(10)),
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(10),
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
