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
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  @override
  void dispose() {
    _killMini();
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

  // ── Category toggle (exclusive – only one open at a time) ────
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

  // ── Channel selection ─────────────────────────────────────────
  void _select(Channel ch) {
    if (ch.streamUrl.isEmpty) {
      _showSnack('هذه القناة غير متوفرة حالياً');
      return;
    }
    if (_activeChannel?.id == ch.id) {
      _openFullscreen(ch);
      return;
    }
    _killMini();
    setState(() { _activeChannel = ch; _miniLoading = true; _miniError = false; });

    context.read<AppProvider>().saveLastChannel(
      id:       ch.id,
      name:     ch.name,
      url:      ch.streamUrl,
      logo:     ch.logoUrl,
      number:   ch.number,
      category: ch.category,
    );

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

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
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
        // Subtle ambient glow
        Positioned(top: -120, right: -80,
          child: Container(width: 260, height: 260,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppTheme.accent.withOpacity(0.05), Colors.transparent])))),

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

              if (_activeChannel != null)
                SliverToBoxAdapter(child: _buildMiniPlayer(c, prov)),

              if (_loadingData)
                ..._buildSkeletons(prov)
              else if (_dataError != null)
                SliverFillRemaining(child: _buildError(c))
              else
                ..._buildCategories(prov, c),

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
      title: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(
            gradient: AppTheme.accentGradient,
            borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.live_tv_rounded, color: Colors.black, size: 19)),
        const SizedBox(width: 10),
        RichText(text: TextSpan(
          style: TextStyle(fontFamily: 'Cairo', fontSize: 21, fontWeight: FontWeight.w900,
              color: c.text, letterSpacing: -0.5),
          children: const [
            TextSpan(text: 'ilyass '),
            TextSpan(text: 'tv', style: TextStyle(color: AppTheme.accent)),
          ],
        )),
      ]),
      actions: [
        // Dark/light toggle with sun↔moon animation
        _ThemeToggleBtn(
          isDark: prov.isDark,
          bg: c.surface2, border: c.border,
          onTap: prov.toggleTheme,
        ),
        // Live badge
        Container(
          margin: const EdgeInsets.only(left: 8, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.live.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.live.withOpacity(0.25), width: 1)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _PulseDot(color: AppTheme.live),
            const SizedBox(width: 5),
            const Text('LIVE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                color: AppTheme.live, letterSpacing: 0.5)),
          ]),
        ),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
        child: Container(height: 0.5, color: c.border)),
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
      Icon(Icons.cloud_off_rounded, color: c.textDim, size: 48),
      const SizedBox(height: 16),
      Text('تعذر تحميل القنوات',
        style: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text('تحقق من اتصالك وحاول مجدداً',
        style: TextStyle(color: c.textDim, fontSize: 13)),
      const SizedBox(height: 20),
      GestureDetector(
        onTap: _loadChannels,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            gradient: AppTheme.accentGradient,
            borderRadius: BorderRadius.circular(12)),
          child: const Text('إعادة المحاولة',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14)),
        ),
      ),
    ]));
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
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isExpanded ? AppTheme.accent.withOpacity(0.4) : c.border, width: 1),
              boxShadow: [BoxShadow(color: c.shadow, blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: isExpanded
                      ? AppTheme.accent.withOpacity(0.15)
                      : c.surface2,
                  borderRadius: BorderRadius.circular(12)),
                child: Icon(_catIcon(cat.icon),
                  color: isExpanded ? AppTheme.accent : c.textDim, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cat.name,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                    color: c.text)),
                const SizedBox(height: 2),
                Text('${cat.channels.length} قنوات',
                  style: TextStyle(fontSize: 12, color: c.textDim)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isExpanded ? AppTheme.accent.withOpacity(0.12) : c.surface2,
                  borderRadius: BorderRadius.circular(8)),
                child: Text('${cat.channels.length}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: isExpanded ? AppTheme.accent : c.textDim))),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: Icon(Icons.keyboard_arrow_down_rounded,
                  color: isExpanded ? AppTheme.accent : c.textDim, size: 22)),
            ]),
          ).animate(delay: Duration(milliseconds: 60 * i))
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.06, end: 0, duration: 280.ms),
        ),
      ));

      if (isExpanded) {
        widgets.add(SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.accent.withOpacity(0.15), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16)],
        ),
        child: Column(children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            child: AspectRatio(aspectRatio: 16 / 9, child: Stack(fit: StackFit.expand, children: [
              if (_miniCtrl != null && !_miniError)
                BetterPlayer(controller: _miniCtrl!),

              if (_miniLoading)
                Container(color: Colors.black, child: Center(
                  child: SizedBox(width: 32, height: 32,
                    child: CircularProgressIndicator(
                      color: AppTheme.accent, strokeWidth: 2.5,
                      backgroundColor: AppTheme.accent.withOpacity(0.15))))),

              if (_miniError)
                Container(color: Colors.black, child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.wifi_off_rounded, color: AppTheme.live, size: 28),
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
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(8)),
                      child: const Text('إعادة',
                        style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w700)))),
                ])),

              if (!_miniLoading && !_miniError)
                Positioned(bottom: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18))),
            ])),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17))),
            child: Row(children: [
              Container(width: 38, height: 38,
                decoration: BoxDecoration(color: c.surface2,
                  borderRadius: BorderRadius.circular(10)),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(imageUrl: ch.logoUrl, fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => Icon(Icons.tv_rounded, color: c.textDim, size: 18))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ch.name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c.text)),
                const SizedBox(height: 2),
                Row(children: [
                  _PulseDot(color: AppTheme.accent, size: 5),
                  const SizedBox(width: 5),
                  Text('بث مباشر',
                    style: TextStyle(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.w600)),
                ]),
              ])),
              GestureDetector(
                onTap: _closeMini,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.close_rounded, color: c.textDim, size: 20))),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _openFullscreen(ch),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.open_in_full_rounded, color: Colors.black, size: 16))),
            ]),
          ),
        ]),
      ).animate().fadeIn(duration: 280.ms).slideY(begin: -0.06, end: 0, duration: 280.ms),
    );
  }
}

// ── Theme toggle with sun/moon crossfade + rotation ──────────
class _ThemeToggleBtn extends StatelessWidget {
  final bool isDark;
  final Color bg;
  final Color border;
  final VoidCallback onTap;

  const _ThemeToggleBtn({
    required this.isDark,
    required this.bg,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1)),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) {
            return RotationTransition(
              turns: Tween(begin: 0.75, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
              child: FadeTransition(opacity: anim, child: child),
            );
          },
          child: Icon(
            isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            key: ValueKey(isDark),
            color: isDark ? const Color(0xFFFFD54F) : const Color(0xFF5C6BC0),
            size: 20,
          ),
        ),
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
