import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const StreamGoApp());
}

// ═══════════════════════════════════════════
//  DESIGN TOKENS — iOS 26 Precision System
// ═══════════════════════════════════════════
class DS {
  // Colors
  static const bg = Color(0xFF000000);
  static const surface1 = Color(0xFF0A0A0A);
  static const surface2 = Color(0xFF111111);
  static const surface3 = Color(0xFF1C1C1E);
  static const elevated = Color(0xFF2C2C2E);
  static const label = Color(0xFFFFFFFF);
  static const label2 = Color(0xFF8E8E93);
  static const label3 = Color(0xFF48484A);
  static const tint = Color(0xFF0A84FF);
  static const red = Color(0xFFFF453A);
  static const green = Color(0xFF30D158);
  static const separator = Color(0xFF38383A);

  // Typography — SF Pro rhythm
  static const tsLargeTitle =
      TextStyle(fontFamily: 'SF Pro Display', fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: 0.37, height: 1.2, color: label);
  static const tsTitle1 =
      TextStyle(fontFamily: 'SF Pro Display', fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 0.36, height: 1.2, color: label);
  static const tsTitle2 =
      TextStyle(fontFamily: 'SF Pro Display', fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0.35, height: 1.3, color: label);
  static const tsTitle3 =
      TextStyle(fontFamily: 'SF Pro Text', fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.38, height: 1.3, color: label);
  static const tsHeadline =
      TextStyle(fontFamily: 'SF Pro Text', fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.41, height: 1.4, color: label);
  static const tsBody =
      TextStyle(fontFamily: 'SF Pro Text', fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: -0.41, height: 1.5, color: label);
  static const tsCallout =
      TextStyle(fontFamily: 'SF Pro Text', fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: -0.32, height: 1.5, color: label);
  static const tsSubhead =
      TextStyle(fontFamily: 'SF Pro Text', fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.24, height: 1.5, color: label);
  static const tsFootnote =
      TextStyle(fontFamily: 'SF Pro Text', fontSize: 13, fontWeight: FontWeight.w400, letterSpacing: -0.08, height: 1.4, color: label2);
  static const tsCaption1 =
      TextStyle(fontFamily: 'SF Pro Text', fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.0, height: 1.4, color: label2);
  static const tsCaption2 =
      TextStyle(fontFamily: 'SF Pro Text', fontSize: 11, fontWeight: FontWeight.w400, letterSpacing: 0.07, height: 1.3, color: label2);

  // Spacing — 8pt grid
  static const s2 = 2.0;
  static const s4 = 4.0;
  static const s6 = 6.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s40 = 40.0;
  static const s48 = 48.0;
  static const s56 = 56.0;
  static const s64 = 64.0;

  // Radii
  static const rSmall = 8.0;
  static const rMed = 12.0;
  static const rLarge = 16.0;
  static const rXL = 20.0;
  static const rFull = 100.0;

  // Blur
  static const blurLight = 20.0;
  static const blurMed = 40.0;
  static const blurHeavy = 80.0;
}

// ═══════════════════════════════════════════
//  FAVORITES + SETTINGS PERSISTENCE
// ═══════════════════════════════════════════
class FavoritesManager {
  static const _key = 'fav_ids_v2';
  static Future<Set<int>> load() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_key) ?? []).map((e) => int.tryParse(e) ?? -1).toSet();
  }

  static Future<bool> toggle(int id) async {
    final p = await SharedPreferences.getInstance();
    final set = await load();
    set.contains(id) ? set.remove(id) : set.add(id);
    await p.setStringList(_key, set.map((e) => '$e').toList());
    return set.contains(id);
  }
}

class AppSettings {
  bool autoPlay;
  bool showScores;
  String quality;
  AppSettings({this.autoPlay = true, this.showScores = true, this.quality = 'auto'});

  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AppSettings(
      autoPlay: p.getBool('ap') ?? true,
      showScores: p.getBool('ss') ?? true,
      quality: p.getString('q') ?? 'auto',
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('ap', autoPlay);
    await p.setBool('ss', showScores);
    await p.setString('q', quality);
  }
}

// ═══════════════════════════════════════════
//  MODELS
// ═══════════════════════════════════════════
class Channel {
  final int id;
  final String name;
  final String number;
  final String logo;
  final String streamUrl;
  const Channel({required this.id, required this.name, required this.number, required this.logo, required this.streamUrl});
  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
        id: j['id'] as int,
        name: j['name'] as String,
        number: j['number']?.toString() ?? '',
        logo: j['logo'] as String? ?? '',
        streamUrl: j['stream'] as String? ?? '',
      );
}

class Category {
  final String name;
  final IconData icon;
  final List<Channel> channels;
  const Category({required this.name, required this.icon, required this.channels});
  factory Category.fromJson(Map<String, dynamic> j) => Category(
        name: j['name'] as String,
        icon: _icon(j['icon'] as String? ?? 'tv'),
        channels: (j['channels'] as List).map((c) => Channel.fromJson(c)).toList(),
      );
  static IconData _icon(String n) => const {
        'sports_soccer': CupertinoIcons.sportscourt_fill,
        'sports': CupertinoIcons.sportscourt,
        'tv': CupertinoIcons.tv_fill,
        'movie': CupertinoIcons.film_fill,
        'star': CupertinoIcons.star_fill,
        'flash_on': CupertinoIcons.bolt_fill,
      }[n] ??
      CupertinoIcons.tv_fill;
}

class Match {
  final String id, league, leagueEn, home, homeEn, homeLogo, away, awayEn, awayLogo, score, date, time;
  final int status;
  final bool hasChannels;
  const Match({
    required this.id, required this.league, required this.leagueEn,
    required this.home, required this.homeEn, required this.homeLogo,
    required this.away, required this.awayEn, required this.awayLogo,
    required this.score, required this.date, required this.time,
    required this.status, required this.hasChannels,
  });
  factory Match.fromJson(Map<String, dynamic> j) => Match(
        id: j['id']?.toString() ?? '',
        league: j['league'] as String? ?? '',
        leagueEn: j['league_en'] as String? ?? '',
        home: j['home'] as String? ?? '',
        homeEn: j['home_en'] as String? ?? '',
        homeLogo: j['home_logo'] as String? ?? '',
        away: j['away'] as String? ?? '',
        awayEn: j['away_en'] as String? ?? '',
        awayLogo: j['away_logo'] as String? ?? '',
        score: j['score'] as String? ?? '0 - 0',
        date: j['date'] as String? ?? '',
        time: j['time'] as String? ?? '',
        status: int.tryParse(j['status']?.toString() ?? '0') ?? 0,
        hasChannels: (j['has_channels']?.toString() ?? '0') == '1',
      );
  bool get isLive => status == 1;
  String get homeLogoUrl => 'https://img.kora-api.space/uploads/team/$homeLogo';
  String get awayLogoUrl => 'https://img.kora-api.space/uploads/team/$awayLogo';
}

// ═══════════════════════════════════════════
//  SERVICES
// ═══════════════════════════════════════════
class ChannelService {
  static const _url = 'https://raw.githubusercontent.com/illyassvvv/G/refs/heads/main/channels.json';
  static Future<List<Category>> fetch() async {
    final r = await http.get(Uri.parse(_url));
    if (r.statusCode != 200) throw Exception('fetch_failed');
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return (body['categories'] as List).map((c) => Category.fromJson(c)).toList();
  }
}

class MatchService {
  static Future<List<Match>> fetch(String date) async {
    final r = await http.get(Uri.parse('https://ws.kora-api.space/api/matches/$date/1'));
    if (r.statusCode != 200) throw Exception('fetch_failed');
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    return ((body['matches'] as List?) ?? []).map((m) => Match.fromJson(m)).toList();
  }
}

// ═══════════════════════════════════════════
//  APP ROOT
// ═══════════════════════════════════════════
class StreamGoApp extends StatelessWidget {
  const StreamGoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreamGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: DS.bg,
        fontFamily: 'SF Pro Text',
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(primary: DS.tint, surface: DS.surface1),
      ),
      builder: (ctx, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const RootShell(),
    );
  }
}

// ═══════════════════════════════════════════
//  ROOT SHELL
// ═══════════════════════════════════════════
class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with TickerProviderStateMixin {
  int _tab = 0;
  late AnimationController _tabAnimCtrl;
  late Future<List<Category>> _catsFuture;
  late Future<List<Match>> _matchesFuture;
  Set<int> _favIds = {};
  AppSettings _settings = AppSettings();
  List<Channel> _allChannels = [];
  final List<GlobalKey<NavigatorState>> _navKeys = List.generate(5, (_) => GlobalKey());

  // Toast
  OverlayEntry? _toastEntry;

  @override
  void initState() {
    super.initState();
    _tabAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _catsFuture = ChannelService.fetch();
    _matchesFuture = MatchService.fetch(_today());
    _loadFavs();
    _loadSettings();
  }

  @override
  void dispose() {
    _tabAnimCtrl.dispose();
    super.dispose();
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadFavs() async {
    final f = await FavoritesManager.load();
    if (mounted) setState(() => _favIds = f);
  }

  Future<void> _loadSettings() async {
    final s = await AppSettings.load();
    if (mounted) setState(() => _settings = s);
  }

  void _reload() => setState(() {
        _catsFuture = ChannelService.fetch();
        _matchesFuture = MatchService.fetch(_today());
      });

  Future<void> _toggleFav(int id) async {
    final isFav = await FavoritesManager.toggle(id);
    HapticFeedback.lightImpact();
    if (mounted) setState(() => isFav ? _favIds.add(id) : _favIds.remove(id));
    _showToast(isFav ? '❤️  أُضيفت إلى المفضلة' : 'تمت الإزالة من المفضلة');
  }

  void _showToast(String message) {
    _toastEntry?.remove();
    _toastEntry = null;
    final entry = OverlayEntry(
      builder: (_) => _ToastWidget(message: message, onDone: () {
        _toastEntry?.remove();
        _toastEntry = null;
      }),
    );
    _toastEntry = entry;
    Overlay.of(context).insert(entry);
  }

  void _openPlayer(Channel ch) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      _slideRoute(VideoPlayerScreen(
        channel: ch,
        isFavorite: _favIds.contains(ch.id),
        onToggleFav: () => _toggleFav(ch.id),
        autoPlay: _settings.autoPlay,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DS.bg,
      body: FutureBuilder<List<Category>>(
        future: _catsFuture,
        builder: (ctx, snap) {
          if (snap.hasData) {
            _allChannels = snap.data!.expand((c) => c.channels).toList();
          }
          return Stack(
            children: [
              // ── Tab Pages ──
              IndexedStack(
                index: _tab,
                children: [
                  _HomeTab(
                    catsFuture: _catsFuture,
                    matchesFuture: _matchesFuture,
                    favIds: _favIds,
                    onToggleFav: _toggleFav,
                    onOpenPlayer: _openPlayer,
                    onGoMatches: () => setState(() => _tab = 3),
                    onReload: _reload,
                  ),
                  _ChannelsTab(
                    channels: _allChannels,
                    favIds: _favIds,
                    onToggleFav: _toggleFav,
                    onOpenPlayer: _openPlayer,
                    loading: snap.connectionState == ConnectionState.waiting,
                    error: snap.hasError,
                    onReload: _reload,
                  ),
                  _FavoritesTab(
                    channels: _allChannels,
                    favIds: _favIds,
                    onToggleFav: _toggleFav,
                    onOpenPlayer: _openPlayer,
                  ),
                  _MatchesTab(
                    matchesFuture: _matchesFuture,
                    onGoChannels: () => setState(() => _tab = 1),
                    onReload: _reload,
                    showScores: _settings.showScores,
                  ),
                  _SettingsTab(
                    settings: _settings,
                    onChanged: () async {
                      await _settings.save();
                      setState(() {});
                    },
                  ),
                ],
              ),
              // ── Tab Bar ──
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: _IOSTabBar(
                  selectedIndex: _tab,
                  onTap: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _tab = i);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════
//  iOS TAB BAR
// ═══════════════════════════════════════════
class _IOSTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _IOSTabBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DS.blurHeavy, sigmaY: DS.blurHeavy),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 0.5)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 49,
              child: Row(
                children: [
                  _tab(0, CupertinoIcons.house_fill, CupertinoIcons.house, 'الرئيسية'),
                  _tab(1, CupertinoIcons.tv_fill, CupertinoIcons.tv, 'القنوات'),
                  _tab(2, CupertinoIcons.heart_fill, CupertinoIcons.heart, 'المفضلة'),
                  _tab(3, CupertinoIcons.sportscourt_fill, CupertinoIcons.sportscourt, 'المباريات'),
                  _tab(4, CupertinoIcons.gear_alt_fill, CupertinoIcons.gear_alt, 'الإعدادات'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int idx, IconData filledIcon, IconData outlineIcon, String label) {
    final active = selectedIndex == idx;
    return Expanded(
      child: _TapScale(
        onTap: () => onTap(idx),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                active ? filledIcon : outlineIcon,
                key: ValueKey(active),
                size: 24,
                color: active ? DS.tint : DS.label2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'SF Pro Text',
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? DS.tint : DS.label2,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
//  HOME TAB
// ═══════════════════════════════════════════
class _HomeTab extends StatelessWidget {
  final Future<List<Category>> catsFuture;
  final Future<List<Match>> matchesFuture;
  final Set<int> favIds;
  final Function(int) onToggleFav;
  final Function(Channel) onOpenPlayer;
  final VoidCallback onGoMatches;
  final VoidCallback onReload;

  const _HomeTab({
    required this.catsFuture, required this.matchesFuture, required this.favIds,
    required this.onToggleFav, required this.onOpenPlayer, required this.onGoMatches, required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Category>>(
      future: catsFuture,
      builder: (ctx, snap) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ── Large Title Nav ──
            _SliverLargeTitle(title: 'StreamGo', onRefresh: onReload),
            // ── Live Hero Card ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(DS.s16, DS.s8, DS.s16, DS.s24),
                child: _HeroMatchCard(matchesFuture: matchesFuture, onGoMatches: onGoMatches),
              ),
            ),
            // ── Section Header ──
            if (snap.hasData) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(DS.s16, 0, DS.s16, DS.s12),
                  child: Text('القنوات', style: DS.tsTitle2),
                ),
              ),
              ...snap.data!.map((cat) => SliverToBoxAdapter(
                    child: _CategoryRow(
                      category: cat, favIds: favIds,
                      onToggleFav: onToggleFav, onOpenPlayer: onOpenPlayer,
                    ),
                  )),
            ] else if (snap.connectionState == ConnectionState.waiting)
              const SliverToBoxAdapter(child: _LoadingShimmer())
            else if (snap.hasError)
              SliverToBoxAdapter(child: _ErrorCard(onRetry: onReload)),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════
//  CHANNELS TAB
// ═══════════════════════════════════════════
class _ChannelsTab extends StatefulWidget {
  final List<Channel> channels;
  final Set<int> favIds;
  final Function(int) onToggleFav;
  final Function(Channel) onOpenPlayer;
  final bool loading, error;
  final VoidCallback onReload;
  const _ChannelsTab({
    required this.channels, required this.favIds, required this.onToggleFav,
    required this.onOpenPlayer, required this.loading, required this.error, required this.onReload,
  });
  @override
  State<_ChannelsTab> createState() => _ChannelsTabState();
}

class _ChannelsTabState extends State<_ChannelsTab> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final filtered = widget.channels
        .where((ch) => _query.isEmpty || ch.name.contains(_query) || ch.number.contains(_query))
        .toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        _SliverLargeTitle(title: 'القنوات', onRefresh: widget.onReload),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(DS.s16, 0, DS.s16, DS.s16),
            child: _IOSSearchBar(
              placeholder: 'بحث عن قناة...',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
        if (widget.loading)
          const SliverToBoxAdapter(child: _LoadingShimmer())
        else if (widget.error)
          SliverToBoxAdapter(child: _ErrorCard(onRetry: widget.onReload))
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _ChannelRow(
                channel: filtered[i],
                isFav: widget.favIds.contains(filtered[i].id),
                onToggleFav: () => widget.onToggleFav(filtered[i].id),
                onTap: () => widget.onOpenPlayer(filtered[i]),
                isLast: i == filtered.length - 1,
              ),
              childCount: filtered.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

// ═══════════════════════════════════════════
//  FAVORITES TAB
// ═══════════════════════════════════════════
class _FavoritesTab extends StatelessWidget {
  final List<Channel> channels;
  final Set<int> favIds;
  final Function(int) onToggleFav;
  final Function(Channel) onOpenPlayer;
  const _FavoritesTab({required this.channels, required this.favIds, required this.onToggleFav, required this.onOpenPlayer});

  @override
  Widget build(BuildContext context) {
    final favs = channels.where((ch) => favIds.contains(ch.id)).toList();
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        _SliverLargeTitle(title: 'المفضلة'),
        if (favs.isEmpty)
          const SliverFillRemaining(child: _EmptyFavorites())
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _ChannelRow(
                channel: favs[i],
                isFav: true,
                onToggleFav: () => onToggleFav(favs[i].id),
                onTap: () => onOpenPlayer(favs[i]),
                isLast: i == favs.length - 1,
              ),
              childCount: favs.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

// ═══════════════════════════════════════════
//  MATCHES TAB
// ═══════════════════════════════════════════
class _MatchesTab extends StatelessWidget {
  final Future<List<Match>> matchesFuture;
  final VoidCallback onGoChannels, onReload;
  final bool showScores;
  const _MatchesTab({required this.matchesFuture, required this.onGoChannels, required this.onReload, required this.showScores});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Match>>(
      future: matchesFuture,
      builder: (ctx, snap) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _SliverLargeTitle(title: 'المباريات', onRefresh: onReload),
            if (snap.connectionState == ConnectionState.waiting)
              const SliverToBoxAdapter(child: _LoadingShimmer())
            else if (snap.hasError)
              SliverToBoxAdapter(child: _ErrorCard(onRetry: onReload))
            else ..._buildMatchGroups(snap.data!, showScores, onGoChannels),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        );
      },
    );
  }

  List<Widget> _buildMatchGroups(List<Match> matches, bool showScores, VoidCallback onGoChannels) {
    final grouped = <String, List<Match>>{};
    for (final m in matches) grouped.putIfAbsent(m.league, () => []).add(m);

    return grouped.entries.map((e) => SliverToBoxAdapter(
          child: _LeagueGroup(league: e.key, matches: e.value, showScores: showScores, onGoChannels: onGoChannels),
        )).toList();
  }
}

// ═══════════════════════════════════════════
//  SETTINGS TAB
// ═══════════════════════════════════════════
class _SettingsTab extends StatelessWidget {
  final AppSettings settings;
  final VoidCallback onChanged;
  const _SettingsTab({required this.settings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        _SliverLargeTitle(title: 'الإعدادات'),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(DS.s16, DS.s8, DS.s16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _settingsSection('التشغيل', [
                  _IOSToggleRow(
                    icon: CupertinoIcons.play_circle_fill,
                    iconColor: DS.red,
                    title: 'تشغيل تلقائي',
                    subtitle: 'تشغيل البث فور اختيار القناة',
                    value: settings.autoPlay,
                    onChanged: (v) { settings.autoPlay = v; onChanged(); },
                  ),
                  _IOSToggleRow(
                    icon: CupertinoIcons.sportscourt_fill,
                    iconColor: DS.green,
                    title: 'نتائج المباريات',
                    subtitle: 'إظهار النتيجة على بطاقة المباراة',
                    value: settings.showScores,
                    onChanged: (v) { settings.showScores = v; onChanged(); },
                  ),
                ]),
                const SizedBox(height: DS.s32),
                _settingsSection('جودة الفيديو', [
                  _QualitySelector(current: settings.quality, onSelect: (v) { settings.quality = v; onChanged(); }),
                ]),
                const SizedBox(height: DS.s32),
                _settingsSection('حول التطبيق', [
                  _InfoRow(label: 'الإصدار', value: '2.0'),
                  _InfoRow(label: 'المطوّر', value: 'StreamGo'),
                ]),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _settingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: DS.s16, bottom: DS.s8),
          child: Text(title.toUpperCase(), style: DS.tsCaption1.copyWith(color: DS.label2, letterSpacing: 0.5)),
        ),
        _IOSGroupedCard(children: children),
      ],
    );
  }
}

// ═══════════════════════════════════════════
//  VIDEO PLAYER SCREEN
// ═══════════════════════════════════════════
class VideoPlayerScreen extends StatefulWidget {
  final Channel channel;
  final bool isFavorite, autoPlay;
  final VoidCallback onToggleFav;
  const VideoPlayerScreen({super.key, required this.channel, required this.isFavorite, required this.onToggleFav, required this.autoPlay});
  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with TickerProviderStateMixin {
  VideoPlayerController? _vpc;
  ChewieController? _cc;
  bool _loading = true, _error = false, _isFav = false;
  late AnimationController _favAnimCtrl;
  late Animation<double> _favScale;

  @override
  void initState() {
    super.initState();
    _isFav = widget.isFavorite;
    _favAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _favScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 60),
    ]).animate(_favAnimCtrl);
    _initPlayer();
  }

  @override
  void dispose() {
    _favAnimCtrl.dispose();
    _cc?.dispose();
    _vpc?.dispose();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    if (widget.channel.streamUrl.isEmpty) {
      setState(() { _loading = false; _error = true; });
      return;
    }
    setState(() { _loading = true; _error = false; });
    try {
      _vpc = VideoPlayerController.networkUrl(Uri.parse(widget.channel.streamUrl));
      await _vpc!.initialize();
      _cc = ChewieController(
        videoPlayerController: _vpc!,
        autoPlay: widget.autoPlay,
        looping: true,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: const Center(child: CupertinoActivityIndicator(radius: 14, color: Colors.white)),
        errorBuilder: (ctx, msg) => _PlayerErrorView(onRetry: _retry),
      );
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  void _retry() {
    _cc?.dispose(); _vpc?.dispose();
    _cc = null; _vpc = null;
    _initPlayer();
  }

  void _tapFav() {
    widget.onToggleFav();
    HapticFeedback.mediumImpact();
    setState(() => _isFav = !_isFav);
    _favAnimCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isLand = MediaQuery.of(context).orientation == Orientation.landscape;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // ── VIDEO CONTAINER ──
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Player / Loading / Error
                if (_loading)
                  const _PlayerLoadingView()
                else if (_error)
                  _PlayerErrorView(onRetry: _retry)
                else if (_cc != null)
                  Chewie(controller: _cc!)
                else
                  const _PlayerLoadingView(),

                // Top Controls Overlay
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: _VideoTopControls(topPadding: isLand ? top : 0, onBack: () => Navigator.pop(context)),
                ),
              ],
            ),
          ),

          // ── CHANNEL INFO ──
          if (!isLand)
            Expanded(
              child: _ChannelInfoPanel(
                channel: widget.channel,
                isFav: _isFav,
                favScale: _favScale,
                onToggleFav: _tapFav,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Player Sub-views ───
class _PlayerLoadingView extends StatelessWidget {
  const _PlayerLoadingView();
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black,
    child: const Center(child: CupertinoActivityIndicator(radius: 16, color: Colors.white)),
  );
}

class _PlayerErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _PlayerErrorView({required this.onRetry});
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.wifi_slash, size: 44, color: Colors.white54),
          const SizedBox(height: DS.s16),
          const Text('تعذّر الاتصال', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'SF Pro Text')),
          const SizedBox(height: DS.s8),
          const Text('حدث خطأ في البث', style: TextStyle(color: Colors.white54, fontSize: 14, fontFamily: 'SF Pro Text')),
          const SizedBox(height: DS.s24),
          _TapScale(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: DS.s24, vertical: DS.s12),
              decoration: BoxDecoration(color: DS.tint, borderRadius: BorderRadius.circular(DS.rFull)),
              child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'SF Pro Text')),
            ),
          ),
        ],
      ),
    ),
  );
}

class _VideoTopControls extends StatelessWidget {
  final double topPadding;
  final VoidCallback onBack;
  const _VideoTopControls({required this.topPadding, required this.onBack});
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(DS.s16, math.max(topPadding + DS.s16, DS.s16), DS.s16, DS.s16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _GlassButton(icon: CupertinoIcons.back, onTap: onBack),
      ],
    ),
  );
}

class _ChannelInfoPanel extends StatelessWidget {
  final Channel channel;
  final bool isFav;
  final Animation<double> favScale;
  final VoidCallback onToggleFav;
  const _ChannelInfoPanel({required this.channel, required this.isFav, required this.favScale, required this.onToggleFav});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(DS.s20, DS.s20, DS.s20, DS.s16),
    child: Row(
      children: [
        // Logo
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: DS.surface3,
            borderRadius: BorderRadius.circular(DS.rMed),
          ),
          clipBehavior: Clip.antiAlias,
          child: channel.logo.isNotEmpty
              ? Image.network(channel.logo, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.tv, color: DS.label3, size: 28))
              : const Icon(CupertinoIcons.tv, color: DS.label3, size: 28),
        ),
        const SizedBox(width: DS.s16),
        // Title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(channel.name, style: DS.tsHeadline, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: DS.s4),
              Row(
                children: [
                  _LiveDot(),
                  const SizedBox(width: DS.s6),
                  Text('بث مباشر', style: DS.tsCaption1.copyWith(color: DS.label2)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: DS.s16),
        // Fav button
        _TapScale(
          onTap: onToggleFav,
          child: ScaleTransition(
            scale: favScale,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                key: ValueKey(isFav),
                color: isFav ? DS.red : DS.label2,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════
//  REUSABLE UI COMPONENTS
// ═══════════════════════════════════════════

// ── Sliver Large Title (iOS Navigation) ──
class _SliverLargeTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onRefresh;
  const _SliverLargeTitle({required this.title, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(DS.s20, top + DS.s8, DS.s20, DS.s16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: DS.tsLargeTitle),
            if (onRefresh != null)
              _TapScale(
                onTap: onRefresh!,
                child: Icon(CupertinoIcons.refresh, color: DS.tint, size: 22),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Hero Match Card ──
class _HeroMatchCard extends StatelessWidget {
  final Future<List<Match>> matchesFuture;
  final VoidCallback onGoMatches;
  const _HeroMatchCard({required this.matchesFuture, required this.onGoMatches});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Match>>(
      future: matchesFuture,
      builder: (ctx, snap) {
        Match? featured;
        if (snap.hasData) {
          final live = snap.data!.where((m) => m.isLive).toList();
          if (live.isNotEmpty) featured = live.first;
        }

        return _TapScale(
          onTap: onGoMatches,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DS.rXL),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF1A2A4A), Color(0xFF0D1B35), Color(0xFF050A14)],
              ),
            ),
            child: Stack(
              children: [
                // Background noise texture feel
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(DS.rXL),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(DS.s20),
                  child: featured != null ? _liveMatchContent(featured) : _defaultContent(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _liveMatchContent(Match m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LiveDot(),
            const SizedBox(width: DS.s6),
            Text('مباشر', style: DS.tsCaption1.copyWith(color: DS.red)),
            const SizedBox(width: DS.s8),
            Expanded(child: Text(m.league, style: DS.tsCaption1, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SmallTeamLogo(url: m.homeLogoUrl),
            const SizedBox(width: DS.s12),
            Expanded(
              child: Column(
                children: [
                  Text(m.score, style: DS.tsTitle1.copyWith(fontSize: 32, letterSpacing: 2)),
                  Text('${m.home} - ${m.away}', style: DS.tsCaption1, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: DS.s12),
            _SmallTeamLogo(url: m.awayLogoUrl),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _defaultContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LiveDot(),
            const SizedBox(width: DS.s6),
            Text('بث مباشر', style: DS.tsCaption1.copyWith(color: DS.red)),
          ],
        ),
        const Spacer(),
        Text('مباريات اليوم', style: DS.tsTitle2),
        const SizedBox(height: DS.s4),
        Text('اضغط لعرض جميع المباريات', style: DS.tsFootnote),
        const Spacer(),
      ],
    );
  }
}

// ── Category Row (Horizontal Scroll) ──
class _CategoryRow extends StatelessWidget {
  final Category category;
  final Set<int> favIds;
  final Function(int) onToggleFav;
  final Function(Channel) onOpenPlayer;
  const _CategoryRow({required this.category, required this.favIds, required this.onToggleFav, required this.onOpenPlayer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DS.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(DS.s20, 0, DS.s20, DS.s12),
            child: Row(
              children: [
                Icon(category.icon, size: 16, color: DS.tint),
                const SizedBox(width: DS.s8),
                Text(category.name, style: DS.tsTitle3),
              ],
            ),
          ),
          SizedBox(
            height: 148,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: DS.s16),
              itemCount: category.channels.length,
              itemBuilder: (ctx, i) => _ChannelCard(
                channel: category.channels[i],
                isFav: favIds.contains(category.channels[i].id),
                onToggleFav: () => onToggleFav(category.channels[i].id),
                onTap: () => onOpenPlayer(category.channels[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Channel Card (Grid/Horizontal) ──
class _ChannelCard extends StatelessWidget {
  final Channel channel;
  final bool isFav;
  final VoidCallback onToggleFav, onTap;
  const _ChannelCard({required this.channel, required this.isFav, required this.onToggleFav, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _TapScale(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: DS.s6),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: DS.surface3,
                  borderRadius: BorderRadius.circular(DS.rLarge),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.5),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(DS.s16),
                      child: Center(
                        child: channel.logo.isNotEmpty
                            ? Image.network(channel.logo, fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.tv, color: DS.label3, size: 32))
                            : const Icon(CupertinoIcons.tv, color: DS.label3, size: 32),
                      ),
                    ),
                    Positioned(
                      top: DS.s6, left: DS.s6,
                      child: _TapScale(
                        onTap: onToggleFav,
                        child: Icon(
                          isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                          color: isFav ? DS.red : DS.label3,
                          size: 14,
                        ),
                      ),
                    ),
                    Positioned(
                      top: DS.s6, right: DS.s6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(DS.s4),
                        ),
                        child: Text(channel.number, style: DS.tsCaption2.copyWith(color: DS.tint, fontSize: 9, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DS.s8),
            Text(channel.name, style: DS.tsCaption1.copyWith(fontWeight: FontWeight.w500, color: DS.label), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ── Channel Row (List) ──
class _ChannelRow extends StatelessWidget {
  final Channel channel;
  final bool isFav, isLast;
  final VoidCallback onToggleFav, onTap;
  const _ChannelRow({required this.channel, required this.isFav, required this.isLast, required this.onToggleFav, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DS.s16),
      child: _TapScale(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 1),
          decoration: BoxDecoration(
            color: DS.surface3,
            borderRadius: isLast
                ? const BorderRadius.vertical(bottom: Radius.circular(DS.rLarge))
                : BorderRadius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DS.s16, vertical: DS.s12),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: DS.elevated,
                    borderRadius: BorderRadius.circular(DS.rSmall),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: channel.logo.isNotEmpty
                      ? Image.network(channel.logo, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.tv, color: DS.label3, size: 20))
                      : const Icon(CupertinoIcons.tv, color: DS.label3, size: 20),
                ),
                const SizedBox(width: DS.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(channel.name, style: DS.tsCallout.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('قناة ${channel.number}', style: DS.tsCaption1),
                    ],
                  ),
                ),
                const SizedBox(width: DS.s8),
                _TapScale(
                  onTap: onToggleFav,
                  child: Padding(
                    padding: const EdgeInsets.all(DS.s8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                        key: ValueKey(isFav),
                        color: isFav ? DS.red : DS.label3,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const Icon(CupertinoIcons.chevron_forward, size: 14, color: DS.label3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── League Group ──
class _LeagueGroup extends StatelessWidget {
  final String league;
  final List<Match> matches;
  final bool showScores;
  final VoidCallback onGoChannels;
  const _LeagueGroup({required this.league, required this.matches, required this.showScores, required this.onGoChannels});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(DS.s16, 0, DS.s16, DS.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: DS.s4, bottom: DS.s8),
            child: Text(league, style: DS.tsFootnote.copyWith(color: DS.label2, letterSpacing: 0.3)),
          ),
          _IOSGroupedCard(
            children: matches.asMap().entries.map((e) => _MatchRow(
              match: e.value,
              showScore: showScores,
              isLast: e.key == matches.length - 1,
              onGoChannels: onGoChannels,
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Match Row ──
class _MatchRow extends StatelessWidget {
  final Match match;
  final bool showScore, isLast;
  final VoidCallback onGoChannels;
  const _MatchRow({required this.match, required this.showScore, required this.isLast, required this.onGoChannels});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DS.s16, vertical: DS.s12),
      child: Row(
        children: [
          _SmallTeamLogo(url: match.homeLogoUrl, size: 36),
          const SizedBox(width: DS.s10),
          Expanded(
            child: Text(match.home, style: DS.tsCallout.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DS.s8),
            child: Column(
              children: [
                if (match.isLive) ...[
                  _LiveDot(),
                  const SizedBox(height: DS.s4),
                  if (showScore)
                    Text(match.score, style: DS.tsHeadline.copyWith(letterSpacing: 1)),
                ] else ...[
                  Text(match.time, style: DS.tsSubhead.copyWith(fontWeight: FontWeight.w600)),
                ],
                if (match.hasChannels) ...[
                  const SizedBox(height: DS.s6),
                  _TapScale(
                    onTap: onGoChannels,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: DS.s10, vertical: DS.s4),
                      decoration: BoxDecoration(color: DS.tint, borderRadius: BorderRadius.circular(DS.rFull)),
                      child: Text('شاهد', style: DS.tsCaption2.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Text(match.away, style: DS.tsCallout.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ),
          const SizedBox(width: DS.s10),
          _SmallTeamLogo(url: match.awayLogoUrl, size: 36),
        ],
      ),
    );
  }
}

// ── iOS Grouped Card ──
class _IOSGroupedCard extends StatelessWidget {
  final List<Widget> children;
  const _IOSGroupedCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DS.rLarge),
      child: Column(
        children: children.asMap().entries.map((e) {
          final isLast = e.key == children.length - 1;
          return Column(
            children: [
              Container(color: DS.surface3, child: e.value),
              if (!isLast) Container(height: 0.5, color: DS.separator.withValues(alpha: 0.5), margin: const EdgeInsets.only(right: DS.s16)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── iOS Toggle Row ──
class _IOSToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _IOSToggleRow({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DS.s16, vertical: DS.s12),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(DS.rSmall)),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: DS.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DS.tsCallout.copyWith(fontWeight: FontWeight.w500)),
                Text(subtitle, style: DS.tsCaption1),
              ],
            ),
          ),
          CupertinoSwitch(value: value, onChanged: onChanged, activeColor: DS.tint),
        ],
      ),
    );
  }
}

class _QualitySelector extends StatelessWidget {
  final String current;
  final ValueChanged<String> onSelect;
  const _QualitySelector({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final opts = [('auto', 'تلقائي', CupertinoIcons.waveform), ('hd', 'عالي HD', CupertinoIcons.tv), ('sd', 'عادي SD', CupertinoIcons.tv_music_note)];
    return Column(
      children: opts.asMap().entries.map((e) {
        final isSelected = current == e.value.$1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: DS.s16, vertical: DS.s12),
          child: _TapScale(
            onTap: () => onSelect(e.value.$1),
            child: Row(
              children: [
                Icon(e.value.$3, color: isSelected ? DS.tint : DS.label2, size: 20),
                const SizedBox(width: DS.s12),
                Expanded(child: Text(e.value.$2, style: DS.tsCallout.copyWith(fontWeight: FontWeight.w500))),
                if (isSelected) const Icon(CupertinoIcons.checkmark, color: DS.tint, size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: DS.s16, vertical: DS.s14),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: DS.tsCallout.copyWith(fontWeight: FontWeight.w500)),
        Text(value, style: DS.tsCallout.copyWith(color: DS.label2)),
      ],
    ),
  );
}

// ── iOS Search Bar ──
class _IOSSearchBar extends StatelessWidget {
  final String placeholder;
  final ValueChanged<String> onChanged;
  const _IOSSearchBar({required this.placeholder, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: DS.surface3, borderRadius: BorderRadius.circular(DS.rMed)),
      child: TextField(
        onChanged: onChanged,
        textDirection: TextDirection.rtl,
        style: DS.tsBody.copyWith(color: DS.label),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: DS.tsBody.copyWith(color: DS.label3),
          prefixIcon: const Icon(CupertinoIcons.search, color: DS.label3, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: DS.s16, vertical: DS.s12),
        ),
      ),
    );
  }
}

// ── Live Dot (Pulsing) ──
class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(
      width: 6, height: 6,
      decoration: const BoxDecoration(color: DS.red, shape: BoxShape.circle),
    ),
  );
}

// ── Glass Button ──
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => _TapScale(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(DS.rFull),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: DS.blurLight, sigmaY: DS.blurLight),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    ),
  );
}

// ── Small Team Logo ──
class _SmallTeamLogo extends StatelessWidget {
  final String url;
  final double size;
  const _SmallTeamLogo({required this.url, this.size = 40});

  @override
  Widget build(BuildContext context) => ClipOval(
    child: Container(
      width: size, height: size, color: DS.surface3,
      child: Image.network(url, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.sportscourt, color: DS.label3, size: 18)),
    ),
  );
}

// ── Loading Shimmer ──
class _LoadingShimmer extends StatefulWidget {
  const _LoadingShimmer();
  @override
  State<_LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<_LoadingShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _anim = Tween(begin: -1.0, end: 2.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DS.s16, vertical: DS.s8),
      child: Column(children: List.generate(4, (_) => _shimmerItem())),
    );
  }
  Widget _shimmerItem() {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, _) => Container(
        height: 60, margin: const EdgeInsets.only(bottom: 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DS.rMed),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value, 0),
            colors: [DS.surface3, DS.elevated.withValues(alpha: 0.6), DS.surface3],
          ),
        ),
      ),
    );
  }
}

// ── Error Card ──
class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorCard({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(DS.s48),
      child: Column(
        children: [
          const Icon(CupertinoIcons.wifi_slash, size: 48, color: DS.label3),
          const SizedBox(height: DS.s16),
          const Text('تعذّر الاتصال', style: DS.tsHeadline),
          const SizedBox(height: DS.s8),
          const Text('حدث خطأ في الاتصال', style: DS.tsFootnote, textAlign: TextAlign.center),
          const SizedBox(height: DS.s24),
          _TapScale(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: DS.s24, vertical: DS.s12),
              decoration: BoxDecoration(color: DS.tint, borderRadius: BorderRadius.circular(DS.rFull)),
              child: const Text('إعادة المحاولة', style: DS.tsCallout),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Empty Favorites ──
class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(CupertinoIcons.heart, size: 56, color: DS.label3),
        const SizedBox(height: DS.s16),
        const Text('لا توجد مفضلات', style: DS.tsHeadline),
        const SizedBox(height: DS.s8),
        Text('اضغط ❤ على أي قناة لإضافتها', style: DS.tsFootnote.copyWith(color: DS.label3), textAlign: TextAlign.center),
      ],
    ),
  );
}

// ── Toast Widget ──
class _ToastWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDone;
  const _ToastWidget({required this.message, required this.onDone});
  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) _ctrl.reverse().then((_) => widget.onDone());
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 80;
    return Positioned(
      bottom: bottom, left: DS.s32, right: DS.s32,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DS.rXL),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: DS.blurMed, sigmaY: DS.blurMed),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: DS.s20, vertical: DS.s14),
                decoration: BoxDecoration(
                  color: DS.surface3.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(DS.rXL),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Text(widget.message, style: DS.tsCallout.copyWith(fontWeight: FontWeight.w500), textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
//  UTILITIES
// ═══════════════════════════════════════════

// Tap Scale Animation (iOS press feel)
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _TapScale({required this.child, this.onTap});
  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ctrl.forward(),
    onTapUp: (_) { _ctrl.reverse(); widget.onTap?.call(); },
    onTapCancel: () => _ctrl.reverse(),
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}

// Slide Route (iOS-style right-to-left)
PageRoute _slideRoute(Widget page) => PageRouteBuilder(
  pageBuilder: (_, anim, __) => page,
  transitionsBuilder: (_, anim, __, child) {
    const begin = Offset(1.0, 0.0);
    final tween = Tween(begin: begin, end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic));
    return SlideTransition(position: anim.drive(tween), child: child);
  },
  transitionDuration: const Duration(milliseconds: 380),
);

// SizedBox helper
extension on EdgeInsets {
  static EdgeInsets fromLTRB(double l, double t, double r, double b) => EdgeInsets.fromLTRB(l, t, r, b);
}

extension _SpacingExt on double {
  static const s14 = 14.0;
  static const s10 = 10.0;
}

const _s14 = 14.0;
const _s10 = 10.0;
