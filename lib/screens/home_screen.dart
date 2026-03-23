import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:better_player_plus/better_player_plus.dart';
import '../models/channel.dart';
import '../models/theme.dart';
import '../services/channel_service.dart';
import '../widgets/channel_card.dart';
import '../main.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChannelCategory> _categories = [];
  bool _isLoading = true;
  String? _error;
  Channel? _activeChannel;
  BetterPlayerController? _miniController;
  bool _miniLoading = false;
  bool _miniError = false;

  // Categories collapsed by default — user taps to expand
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_onThemeChange);
    _loadChannels();
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadChannels() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final cats = await ChannelService.fetchCategories();
      if (mounted) setState(() { _categories = cats; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Future<void> _refreshChannels() async {
    final cats = await ChannelService.refreshCategories();
    if (mounted) setState(() => _categories = cats);
  }

  void _toggleCategory(String name) {
    setState(() {
      if (_expandedCategories.contains(name)) {
        _expandedCategories.remove(name);
      } else {
        _expandedCategories.add(name);
      }
    });
  }

  // ── Select channel: properly dispose old controller FIRST ──
  void _selectChannel(Channel ch) {
    if (ch.streamUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('هذه القناة غير متوفرة حالياً'),
        backgroundColor: ThemeColors(themeNotifier.isDark).surface2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    if (_activeChannel?.id == ch.id) {
      _openFullscreen(ch);
      return;
    }

    // CRITICAL: dispose old controller completely before creating new one
    // This kills the old audio stream immediately
    _miniController?.pause();
    _miniController?.dispose();
    _miniController = null;

    setState(() {
      _activeChannel = ch;
      _miniLoading = true;
      _miniError = false;
    });

    // Small delay to ensure old controller is fully disposed
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && _activeChannel?.id == ch.id) {
        _loadMiniPlayer(ch);
      }
    });
  }

  void _loadMiniPlayer(Channel ch) {
    final ds = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network, ch.streamUrl,
      liveStream: true, videoFormat: BetterPlayerVideoFormat.hls,
      bufferingConfiguration: const BetterPlayerBufferingConfiguration(
        minBufferMs: 2000, maxBufferMs: 12000,
        bufferForPlaybackMs: 1500, bufferForPlaybackAfterRebufferMs: 3000,
      ),
    );
    _miniController = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true, aspectRatio: 16 / 9, fit: BoxFit.contain,
        handleLifecycle: true, autoDispose: false,
        controlsConfiguration: const BetterPlayerControlsConfiguration(showControls: false),
        eventListener: (event) {
          if (!mounted) return;
          if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
            setState(() => _miniLoading = false);
          } else if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
            setState(() { _miniLoading = false; _miniError = true; });
          }
        },
      ),
      betterPlayerDataSource: ds,
    );
    if (mounted) setState(() {});
  }

  // ── Open fullscreen: PASS existing controller to resume stream ──
  void _openFullscreen(Channel ch) {
    // Pause mini but keep controller alive to hand off
    _miniController?.pause();

    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => PlayerScreen(
        channel: ch,
        existingController: _miniController, // resume same stream
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 200),
    )).then((_) {
      // Back from fullscreen → reload mini with same channel
      if (_activeChannel != null && mounted) {
        _miniController?.dispose();
        _miniController = null;
        setState(() { _miniLoading = true; _miniError = false; });
        _loadMiniPlayer(_activeChannel!);
      }
    });
  }

  void _closeMiniPlayer() {
    _miniController?.pause();
    _miniController?.dispose();
    _miniController = null;
    setState(() {
      _activeChannel = null;
      _miniLoading = false;
      _miniError = false;
    });
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'sports_soccer': return Icons.sports_soccer;
      case 'sports': return Icons.sports;
      case 'sports_basketball': return Icons.sports_basketball;
      case 'sports_tennis': return Icons.sports_tennis;
      case 'tv': return Icons.tv;
      case 'movie': return Icons.movie;
      case 'music_note': return Icons.music_note;
      case 'news': return Icons.newspaper;
      default: return Icons.live_tv;
    }
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChange);
    _miniController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors(themeNotifier.isDark);
    return Scaffold(
      backgroundColor: c.bg,
      body: Stack(children: [
        // Background glow
        Positioned(top: -100, right: -100,
          child: Container(width: 300, height: 300,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppTheme.green.withOpacity(0.06), Colors.transparent])))),
        Positioned(top: -50, left: -80,
          child: Container(width: 250, height: 250,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppTheme.accent.withOpacity(0.04), Colors.transparent])))),

        RefreshIndicator(
          onRefresh: _refreshChannels,
          color: AppTheme.accent, backgroundColor: c.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              _buildAppBar(c),
              if (_activeChannel != null)
                SliverToBoxAdapter(child: _buildMiniPlayer(c)),
              if (_isLoading)
                SliverFillRemaining(child: Center(
                  child: CircularProgressIndicator(color: AppTheme.accent))),
              if (_error != null)
                SliverFillRemaining(child: Center(child: Column(
                  mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.cloud_off_rounded, color: c.textDim, size: 48),
                    const SizedBox(height: 16),
                    Text('تعذر تحميل القنوات', style: TextStyle(color: c.text, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _loadChannels,
                      child: const Text('إعادة المحاولة',
                        style: TextStyle(color: AppTheme.accent))),
                  ]))),
              if (!_isLoading && _error == null) ..._buildCategories(c),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ]),
    );
  }

  SliverAppBar _buildAppBar(ThemeColors c) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: c.bg.withOpacity(0.95),
      title: Row(children: [
        Container(width: 38, height: 38,
          decoration: BoxDecoration(
            gradient: AppTheme.goldGradient,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 12)]),
          child: const Icon(Icons.live_tv_rounded, color: Colors.black, size: 20)),
        const SizedBox(width: 12),
        RichText(text: TextSpan(
          style: TextStyle(fontFamily: 'Cairo', fontSize: 22,
            fontWeight: FontWeight.w900, color: c.text, letterSpacing: -0.5),
          children: const [
            TextSpan(text: 'ilyass '),
            TextSpan(text: 'tv', style: TextStyle(color: AppTheme.accent)),
          ],
        )),
      ]),
      actions: [
        // ── Dark/Light Toggle ──
        GestureDetector(
          onTap: () => themeNotifier.toggle(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.border, width: 1),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: anim, child: FadeTransition(opacity: anim, child: child)),
              child: Icon(
                themeNotifier.isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                key: ValueKey(themeNotifier.isDark),
                color: themeNotifier.isDark ? AppTheme.accent : const Color(0xFF5B5BD6),
                size: 20,
              ),
            ),
          ),
        ),
        // Refresh
        GestureDetector(
          onTap: _refreshChannels,
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.refresh_rounded, color: c.textDim, size: 20),
          ),
        ),
        // Live badge
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.live.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.live.withOpacity(0.3), width: 1),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _PulseDot(color: AppTheme.live),
            const SizedBox(width: 5),
            const Text('بث مباشر',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.live)),
          ]),
        ),
      ],
      bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
        child: Container(height: 1,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [
            Colors.transparent,
            AppTheme.accent.withOpacity(0.2),
            AppTheme.green.withOpacity(0.2),
            Colors.transparent,
          ])))),
    );
  }

  List<Widget> _buildCategories(ThemeColors c) {
    final widgets = <Widget>[];
    for (int i = 0; i < _categories.length; i++) {
      final cat = _categories[i];
      final isExpanded = _expandedCategories.contains(cat.name);

      // Category header
      widgets.add(SliverToBoxAdapter(
        child: GestureDetector(
          onTap: () => _toggleCategory(cat.name),
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
                color: isExpanded ? AppTheme.accent.withOpacity(0.3) : c.border,
                width: 1,
              ),
              boxShadow: [BoxShadow(color: c.cardShadow, blurRadius: 10)],
            ),
            child: Row(children: [
              Container(width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: isExpanded ? AppTheme.goldGradient
                      : LinearGradient(colors: [c.surface2, c.surface2]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isExpanded
                      ? [BoxShadow(color: AppTheme.accent.withOpacity(0.2), blurRadius: 10)]
                      : [],
                ),
                child: Icon(_getCategoryIcon(cat.icon),
                  color: isExpanded ? Colors.black : c.textDim, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cat.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                  color: isExpanded ? AppTheme.accent : c.text)),
                const SizedBox(height: 2),
                Text('${cat.channels.length} قنوات',
                  style: TextStyle(fontSize: 12, color: c.textDim)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isExpanded ? AppTheme.accent.withOpacity(0.15) : c.surface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${cat.channels.length}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: isExpanded ? AppTheme.accent : c.textDim))),
              const SizedBox(width: 8),
              AnimatedRotation(turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: Icon(Icons.keyboard_arrow_down_rounded,
                  color: isExpanded ? AppTheme.accent : c.textDim, size: 24)),
            ]),
          ).animate(delay: Duration(milliseconds: 80 * i))
              .fadeIn(duration: 300.ms)
              .slideX(begin: -0.05, end: 0, duration: 300.ms),
        ),
      ));

      // Channels grid — only if expanded
      if (isExpanded) {
        widgets.add(SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((ctx, idx) {
              final ch = cat.channels[idx];
              return ChannelCard(
                channel: ch,
                isActive: _activeChannel?.id == ch.id,
                onTap: () => _selectChannel(ch),
                index: idx,
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

  Widget _buildMiniPlayer(ThemeColors c) {
    final ch = _activeChannel!;
    return GestureDetector(
      onTap: () => _openFullscreen(ch),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accent.withOpacity(0.2), width: 1),
          boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.08), blurRadius: 20)],
        ),
        child: Column(children: [
          // Video area
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(fit: StackFit.expand, children: [
                // Player
                if (_miniController != null && !_miniError)
                  BetterPlayer(controller: _miniController!),

                // Loading — single spinner, no duplicate
                if (_miniLoading)
                  Container(color: Colors.black,
                    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(width: 32, height: 32,
                        child: CircularProgressIndicator(
                          color: AppTheme.accent, strokeWidth: 2.5,
                          backgroundColor: AppTheme.accent.withOpacity(0.15),
                        )),
                      const SizedBox(height: 10),
                      Text('جاري التحميل...', style: TextStyle(color: c.textDim, fontSize: 12)),
                    ]))),

                // Error
                if (_miniError)
                  Container(color: Colors.black,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.wifi_off_rounded, color: AppTheme.live, size: 32),
                      const SizedBox(height: 8),
                      const Text('تعذر التحميل',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          _miniController?.dispose();
                          _miniController = null;
                          setState(() { _miniLoading = true; _miniError = false; });
                          _loadMiniPlayer(ch);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('إعادة', style: TextStyle(color: AppTheme.accent, fontSize: 11))),
                      ),
                    ])),

                // Fullscreen hint (bottom-left)
                if (!_miniLoading && !_miniError)
                  Positioned(bottom: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18))),
              ]),
            ),
          ),

          // Info bar
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
            ),
            child: Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.2), width: 1)),
                padding: const EdgeInsets.all(5),
                child: CachedNetworkImage(imageUrl: ch.logoUrl, fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => Icon(Icons.tv_rounded, color: c.textDim, size: 18))),
              const SizedBox(width: 12),
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
              GestureDetector(
                onTap: _closeMiniPlayer,
                child: Container(
                  padding: const EdgeInsets.all(7), margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.close_rounded, color: c.textDim, size: 16))),
              // Fullscreen
              GestureDetector(
                onTap: () => _openFullscreen(ch),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(gradient: AppTheme.goldGradient, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.open_in_full_rounded, color: Colors.black, size: 18))),
            ]),
          ),
        ]),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0, duration: 300.ms),
    );
  }
}

// ── Pulse dot ─────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const _PulseDot({required this.color, this.size = 6});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _a = Tween(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child: Container(
      width: widget.size, height: widget.size,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}
