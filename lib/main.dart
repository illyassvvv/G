// StreamGo — Production Flutter App  (English, 2-tab, fixed player)
// lib/main.dart
//
// pubspec.yaml deps:
//   http: ^1.2.0
//   shared_preferences: ^2.2.2
//   video_player: ^2.8.3
//   chewie: ^1.7.4
//
// AndroidManifest.xml:
//   <uses-permission android:name="android.permission.INTERNET"/>

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

// ═══════════════════════════════════════════════════════════════════════════
// ENTRY POINT
// ═══════════════════════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:                Colors.transparent,
    statusBarBrightness:           Brightness.dark,
    statusBarIconBrightness:       Brightness.light,
    systemNavigationBarColor:      Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const StreamGoApp());
}

// ═══════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════════════════
abstract class D {
  // Palette
  static const bg     = Color(0xFF030303);
  static const s1     = Color(0xFF0A0A0C);
  static const s2     = Color(0xFF111113);
  static const s3     = Color(0xFF1A1A1D);
  static const s4     = Color(0xFF252528);
  static const sep    = Color(0xFF2A2A2D);
  static const white  = Color(0xFFFFFFFF);
  static const lbl    = Color(0xFFFFFFFF);
  static const lbl2   = Color(0xFF8E8E95);
  static const lbl3   = Color(0xFF48484E);
  static const lbl4   = Color(0xFF2D2D31);
  static const blue   = Color(0xFF0A84FF);
  static const red    = Color(0xFFFF453A);
  static const green  = Color(0xFF30D158);

  // Radii
  static const r6   =  6.0;
  static const r8   =  8.0;
  static const r10  = 10.0;
  static const r12  = 12.0;
  static const r14  = 14.0;
  static const r16  = 16.0;
  static const r20  = 20.0;
  static const r24  = 24.0;
  static const r32  = 32.0;
  static const rMax = 999.0;

  // Spacing
  static const g4  =  4.0;
  static const g6  =  6.0;
  static const g8  =  8.0;
  static const g10 = 10.0;
  static const g12 = 12.0;
  static const g14 = 14.0;
  static const g16 = 16.0;
  static const g20 = 20.0;
  static const g24 = 24.0;
  static const g28 = 28.0;
  static const g32 = 32.0;

  // Typography
  static TextStyle get hero     => const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.4, height: 1.08, color: lbl);
  static TextStyle get title1   => const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.8, height: 1.15, color: lbl);
  static TextStyle get title2   => const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2,  color: lbl);
  static TextStyle get title3   => const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.3,  color: lbl);
  static TextStyle get headline => const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2, height: 1.4,  color: lbl);
  static TextStyle get body     => const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.1, height: 1.5,  color: lbl);
  static TextStyle get callout  => const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing:  0.0, height: 1.4,  color: lbl);
  static TextStyle get caption  => const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing:  0.1, height: 1.3,  color: lbl2);
  static TextStyle get micro    => const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing:  0.3, height: 1.2,  color: lbl2);
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════
class Channel {
  final int    id;
  final String name, number, logo, streamUrl;

  const Channel({
    required this.id,
    required this.name,
    required this.number,
    required this.logo,
    required this.streamUrl,
  });

  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
    id:        j['id'] as int,
    name:      j['name'] as String,
    number:    j['number']?.toString() ?? '',
    logo:      j['logo']   as String? ?? '',
    streamUrl: j['stream'] as String? ?? '',
  );
}

class ChannelGroup {
  final String   name;
  final IconData icon;
  final List<Channel> channels;

  const ChannelGroup({required this.name, required this.icon, required this.channels});

  factory ChannelGroup.fromJson(Map<String, dynamic> j) => ChannelGroup(
    name:     j['name'] as String,
    icon:     _iconFor(j['icon'] as String? ?? 'tv'),
    channels: (j['channels'] as List).map((c) => Channel.fromJson(c)).toList(),
  );

  static IconData _iconFor(String s) => const {
    'sports_soccer': CupertinoIcons.sportscourt_fill,
    'sports':        CupertinoIcons.sportscourt,
    'tv':            CupertinoIcons.tv_fill,
    'movie':         CupertinoIcons.film_fill,
    'star':          CupertinoIcons.star_fill,
    'flash_on':      CupertinoIcons.bolt_fill,
  }[s] ?? CupertinoIcons.tv_fill;
}

class Match {
  final String   id, league, home, homeEn, homeLogo, away, awayEn, awayLogo, score, time;
  final DateTime date;
  final bool     isLive, hasChannels;

  const Match({
    required this.id,       required this.league,
    required this.home,     required this.homeEn,  required this.homeLogo,
    required this.away,     required this.awayEn,  required this.awayLogo,
    required this.score,    required this.time,    required this.date,
    required this.isLive,   required this.hasChannels,
  });

  factory Match.fromJson(Map<String, dynamic> j) {
    DateTime d;
    try { d = DateTime.parse(j['date'] as String? ?? ''); }
    catch (_) { d = DateTime.now(); }
    return Match(
      id:          j['id']?.toString()   ?? '',
      league:      j['league']           as String? ?? '',
      home:        j['home']             as String? ?? '',
      homeEn:      j['home_en']          as String? ?? '',
      homeLogo:    j['home_logo']        as String? ?? '',
      away:        j['away']             as String? ?? '',
      awayEn:      j['away_en']          as String? ?? '',
      awayLogo:    j['away_logo']        as String? ?? '',
      score:       j['score']            as String? ?? '0 - 0',
      time:        j['time']             as String? ?? '',
      date:        d,
      isLive:      (j['status']?.toString() ?? '0') == '1',
      hasChannels: (j['has_channels']?.toString() ?? '0') == '1',
    );
  }

  String get homeLogoUrl => 'https://img.kora-api.space/uploads/team/$homeLogo';
  String get awayLogoUrl => 'https://img.kora-api.space/uploads/team/$awayLogo';

  /// Best display name: English first, fall back to original
  String get homeDisplay => homeEn.isNotEmpty ? homeEn : home;
  String get awayDisplay => awayEn.isNotEmpty ? awayEn : away;
}

// ═══════════════════════════════════════════════════════════════════════════
// MOCK DATA
// ═══════════════════════════════════════════════════════════════════════════
const _kStream = 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8';

final List<ChannelGroup> _kMockGroups = [
  ChannelGroup(name: 'Sports', icon: CupertinoIcons.sportscourt_fill, channels: [
    const Channel(id: 1, name: 'beIN Sports 1', number: '01', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/BeIN_Sports_logo.svg/200px-BeIN_Sports_logo.svg.png', streamUrl: _kStream),
    const Channel(id: 2, name: 'beIN Sports 2', number: '02', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/BeIN_Sports_logo.svg/200px-BeIN_Sports_logo.svg.png', streamUrl: _kStream),
    const Channel(id: 3, name: 'beIN Sports 3', number: '03', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/BeIN_Sports_logo.svg/200px-BeIN_Sports_logo.svg.png', streamUrl: _kStream),
    const Channel(id: 4, name: 'SSC 1',         number: '04', logo: 'https://upload.wikimedia.org/wikipedia/ar/a/a7/SSC_Sports_Logo.png', streamUrl: _kStream),
    const Channel(id: 5, name: 'SSC 2',         number: '05', logo: 'https://upload.wikimedia.org/wikipedia/ar/a/a7/SSC_Sports_Logo.png', streamUrl: _kStream),
    const Channel(id: 6, name: 'MBC Sport',     number: '06', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/MBC_Sports_logo.svg/200px-MBC_Sports_logo.svg.png', streamUrl: _kStream),
  ]),
  ChannelGroup(name: 'News', icon: CupertinoIcons.news_solid, channels: [
    const Channel(id: 7, name: 'Al Jazeera',   number: '07', logo: 'https://upload.wikimedia.org/wikipedia/en/thumb/b/b2/Al_Jazeera_Logo_2006.svg/200px-Al_Jazeera_Logo_2006.svg.png', streamUrl: _kStream),
    const Channel(id: 8, name: 'Sky News',     number: '08', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/Sky_News_Arabia_logo.svg/200px-Sky_News_Arabia_logo.svg.png', streamUrl: _kStream),
    const Channel(id: 9, name: 'Al Arabiya',   number: '09', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/29/Al_Arabiya_logo.svg/200px-Al_Arabiya_logo.svg.png', streamUrl: _kStream),
  ]),
  ChannelGroup(name: 'Entertainment', icon: CupertinoIcons.tv_fill, channels: [
    const Channel(id: 10, name: 'MBC 1',         number: '10', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/MBC1HD.png/200px-MBC1HD.png', streamUrl: _kStream),
    const Channel(id: 11, name: 'MBC 2',         number: '11', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/MBC1HD.png/200px-MBC1HD.png', streamUrl: _kStream),
    const Channel(id: 12, name: 'Rotana Cinema', number: '12', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/94/Rotana_logo.svg/200px-Rotana_logo.svg.png', streamUrl: _kStream),
  ]),
];

final List<Match> _kMockMatches = [
  Match(id:'1', league:'UEFA Champions League', home:'Real Madrid',    homeEn:'Real Madrid',    homeLogo:'real_madrid.png', away:'Man City',     awayEn:'Man City',    awayLogo:'man_city.png',  score:'2 - 1', time:'21:00', date:DateTime.now(),                              isLive:true,  hasChannels:true),
  Match(id:'2', league:'Premier League',        home:'Liverpool',      homeEn:'Liverpool',      homeLogo:'liverpool.png',   away:'Arsenal',      awayEn:'Arsenal',     awayLogo:'arsenal.png',   score:'1 - 1', time:'22:45', date:DateTime.now(),                              isLive:true,  hasChannels:true),
  Match(id:'3', league:'La Liga',               home:'Barcelona',      homeEn:'Barcelona',      homeLogo:'barca.png',       away:'Atletico',     awayEn:'Atletico',    awayLogo:'atletico.png',  score:'',      time:'23:00', date:DateTime.now(),                              isLive:false, hasChannels:true),
  Match(id:'4', league:'Bundesliga',            home:'Bayern Munich',  homeEn:'Bayern Munich',  homeLogo:'bayern.png',      away:'Dortmund',     awayEn:'Dortmund',    awayLogo:'dortmund.png',  score:'',      time:'20:30', date:DateTime.now().add(const Duration(days:1)),  isLive:false, hasChannels:false),
  Match(id:'5', league:'Ligue 1',               home:'PSG',            homeEn:'PSG',            homeLogo:'psg.png',         away:'Marseille',    awayEn:'Marseille',   awayLogo:'marseille.png', score:'',      time:'21:45', date:DateTime.now().add(const Duration(days:1)),  isLive:false, hasChannels:false),
  Match(id:'6', league:'UEFA Champions League', home:'Juventus',       homeEn:'Juventus',       homeLogo:'juve.png',        away:'Inter Milan',  awayEn:'Inter Milan', awayLogo:'inter.png',     score:'',      time:'22:00', date:DateTime.now().add(const Duration(days:2)),  isLive:false, hasChannels:false),
];

// ═══════════════════════════════════════════════════════════════════════════
// PERSISTENCE
// ═══════════════════════════════════════════════════════════════════════════
class Prefs {
  static const _kFavKey = 'favs_v3';

  static Future<Set<int>> loadFavs() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_kFavKey) ?? [])
        .map((e) => int.tryParse(e) ?? -1)
        .toSet();
  }

  static Future<bool> toggleFav(int id) async {
    final p   = await SharedPreferences.getInstance();
    final set = await loadFavs();
    set.contains(id) ? set.remove(id) : set.add(id);
    await p.setStringList(_kFavKey, set.map((e) => '$e').toList());
    return set.contains(id);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ROOT APP
// ═══════════════════════════════════════════════════════════════════════════
class StreamGoApp extends StatelessWidget {
  const StreamGoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'StreamGo',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness:              Brightness.dark,
      scaffoldBackgroundColor: D.bg,
      splashFactory:           NoSplash.splashFactory,
      splashColor:             Colors.transparent,
      highlightColor:          Colors.transparent,
      colorScheme:             const ColorScheme.dark(primary: D.blue, surface: D.s1),
      pageTransitionsTheme:    const PageTransitionsTheme(builders: {
        TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      }),
    ),
    // ← LTR: no Directionality wrapper, English only
    home: const RootShell(),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ROOT SHELL  —  2 tabs: Home | Matches
// ═══════════════════════════════════════════════════════════════════════════
class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with TickerProviderStateMixin {
  int _tab = 0;

  // Data
  Set<int>          _favIds        = {};
  List<ChannelGroup> _groups       = [];
  List<Match>       _matches       = [];
  bool              _groupsLoading = true;
  bool              _matchLoading  = true;

  // Tab bar slide-in
  late final AnimationController _tabAnim;

  // Overlay toast
  OverlayEntry? _toast;

  // ── lifecycle ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _init();
  }

  @override
  void dispose() {
    _tabAnim.dispose();
    super.dispose();
  }

  Future<void> _init() async =>
      Future.wait([_loadFavs(), _loadGroups(), _loadMatches()]);

  // ── data loaders ───────────────────────────────────────────
  Future<void> _loadFavs() async {
    final f = await Prefs.loadFavs();
    if (mounted) setState(() => _favIds = f);
  }

  Future<void> _loadGroups() async {
    if (mounted) setState(() => _groupsLoading = true);
    try {
      final r = await http
          .get(Uri.parse(
              'https://raw.githubusercontent.com/illyassvvv/G/refs/heads/main/channels.json'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final list = (body['categories'] as List)
            .map((c) => ChannelGroup.fromJson(c))
            .toList();
        if (mounted) setState(() { _groups = list; _groupsLoading = false; });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() { _groups = _kMockGroups; _groupsLoading = false; });
  }

  Future<void> _loadMatches() async {
    if (mounted) setState(() => _matchLoading = true);
    final now = DateTime.now();
    final ds  = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
    try {
      final r = await http
          .get(Uri.parse('https://ws.kora-api.space/api/matches/$ds/1'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final list = ((body['matches'] as List?) ?? [])
            .map((m) => Match.fromJson(m))
            .toList();
        if (mounted) setState(() { _matches = list; _matchLoading = false; });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() { _matches = _kMockMatches; _matchLoading = false; });
  }

  Future<void> _refresh() => Future.wait([_loadGroups(), _loadMatches()]);

  // ── actions ────────────────────────────────────────────────
  Future<void> _toggleFav(int id) async {
    HapticFeedback.lightImpact();
    final added = await Prefs.toggleFav(id);
    if (!mounted) return;
    setState(() => added ? _favIds.add(id) : _favIds.remove(id));
    _showToast(added ? '❤️  Added to Favorites' : 'Removed from Favorites');
  }

  void _openPlayer(Channel ch) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(_fadeZoomRoute(PlayerScreen(
      channel:     ch,
      isFavorite:  _favIds.contains(ch.id),
      onToggleFav: () => _toggleFav(ch.id),
    )));
  }

  void _showToast(String msg) {
    _toast?.remove(); _toast = null;
    final entry = OverlayEntry(builder: (_) => _Toast(
      message: msg,
      onDone: () { _toast?.remove(); _toast = null; },
    ));
    _toast = entry;
    Overlay.of(context).insert(entry);
  }

  // ── build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: D.bg,
      body: Stack(
        children: [
          // ── pages ────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 270),
            switchInCurve:  Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
              child: child,
            ),
            child: KeyedSubtree(
              key: ValueKey(_tab),
              child: [
                HomeScreen(
                  groups:       _groups,
                  matches:      _matches,
                  groupsLoading: _groupsLoading,
                  matchLoading:  _matchLoading,
                  onOpenPlayer: _openPlayer,
                  onGoMatches:  () => setState(() => _tab = 1),
                  onRefresh:    _refresh,
                ),
                MatchesScreen(
                  matches:    _matches,
                  loading:    _matchLoading,
                  onRefresh:  _loadMatches,
                ),
              ][_tab],
            ),
          ),
          // ── floating pill tab bar ────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _tabAnim, curve: Curves.easeOutCubic)),
              child: _PillTabBar(
                selected: _tab,
                onTap: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _tab = i);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PILL TAB BAR  (floating glass, 2 items)
// ═══════════════════════════════════════════════════════════════════════════
class _PillTabBar extends StatelessWidget {
  final int             selected;
  final ValueChanged<int> onTap;
  const _PillTabBar({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(26, 0, 26, math.max(bottomInset, 8) + 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(D.r32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 44, sigmaY: 44),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B1D).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(D.r32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.58),
                  blurRadius: 52, spreadRadius: -4, offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: D.blue.withValues(alpha: 0.05),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Row(children: [
              _PillItem(
                index: 0, selected: selected,
                icon: CupertinoIcons.house, activeIcon: CupertinoIcons.house_fill,
                label: 'Home', onTap: onTap,
              ),
              _PillItem(
                index: 1, selected: selected,
                icon: CupertinoIcons.sportscourt, activeIcon: CupertinoIcons.sportscourt_fill,
                label: 'Matches', onTap: onTap,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PillItem extends StatelessWidget {
  final int index, selected;
  final IconData icon, activeIcon;
  final String label;
  final ValueChanged<int> onTap;
  const _PillItem({
    required this.index,  required this.selected,
    required this.icon,   required this.activeIcon,
    required this.label,  required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == selected;
    return Expanded(
      child: _SpringTap(
        onTap: () => onTap(index),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Icon with spring pop on activate
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: Tween(begin: 0.60, end: 1.0)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Icon(
              active ? activeIcon : icon,
              key: ValueKey(active),
              size: 24,
              color: active ? D.blue : D.lbl3,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? D.blue : D.lbl3,
              letterSpacing: -0.1,
            ),
            child: Text(label),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HOME SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class HomeScreen extends StatelessWidget {
  final List<ChannelGroup> groups;
  final List<Match>        matches;
  final bool               groupsLoading, matchLoading;
  final Function(Channel)  onOpenPlayer;
  final VoidCallback       onGoMatches;
  final Future<void> Function() onRefresh;

  const HomeScreen({
    super.key,
    required this.groups,       required this.matches,
    required this.groupsLoading, required this.matchLoading,
    required this.onOpenPlayer,  required this.onGoMatches,
    required this.onRefresh,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h <  5) return 'Late night 🌙';
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // Native iOS pull-to-refresh
        CupertinoSliverRefreshControl(onRefresh: onRefresh),

        // Status-bar spacer
        SliverToBoxAdapter(child: SizedBox(height: topPad + D.g8)),

        // ── Header ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(D.g20, 0, D.g20, D.g24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_greeting(), style: D.caption.copyWith(color: D.lbl2, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('StreamGo', style: D.hero),
                ]),
                // Avatar
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF1C6EF2), Color(0xFF0A50C8)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(color: D.blue.withValues(alpha: 0.38), blurRadius: 14, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(CupertinoIcons.person_fill, size: 20, color: Colors.white),
                ),
              ],
            ),
          ),
        ),

        // ── Featured match card ──────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(D.g16, 0, D.g16, D.g32),
            child: _FeaturedCard(
              matches:    matches,
              loading:    matchLoading,
              onGoMatches: onGoMatches,
            ),
          ),
        ),

        // ── Live Channels ────────────────────────────────────
        if (groupsLoading)
          const SliverToBoxAdapter(child: _Skeleton())
        else
          ...groups.map((g) => SliverToBoxAdapter(
            child: _ChannelGroupRow(group: g, onOpen: onOpenPlayer),
          )),

        // Bottom spacer for tab bar
        const SliverToBoxAdapter(child: SizedBox(height: 116)),
      ],
    );
  }
}

// ─── Featured match card ─────────────────────────────────────────────────
class _FeaturedCard extends StatefulWidget {
  final List<Match> matches;
  final bool        loading;
  final VoidCallback onGoMatches;
  const _FeaturedCard({required this.matches, required this.loading, required this.onGoMatches});
  @override State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
  }
  @override void dispose() { _glow.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(color: D.s2, borderRadius: BorderRadius.circular(D.r24)),
      );
    }

    final live     = widget.matches.where((m) => m.isLive).toList();
    final featured = live.isNotEmpty ? live.first : (widget.matches.isNotEmpty ? widget.matches.first : null);

    return _SpringTap(
      onTap: widget.onGoMatches,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (_, child) => Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(D.r24),
            gradient: LinearGradient(
              begin: Alignment.topRight, end: Alignment.bottomLeft,
              colors: [
                const Color(0xFF0D2847),
                Color.lerp(const Color(0xFF0A1E35), const Color(0xFF0D2040), _glow.value)!,
                const Color(0xFF040A14),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: D.blue.withValues(alpha: 0.09 + 0.08 * _glow.value),
                blurRadius: 36, offset: const Offset(0, 12),
              ),
              BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 22, offset: const Offset(0, 6)),
            ],
          ),
          child: child,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(D.r24),
          child: Stack(children: [
            // Texture grid
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            // Highlight orb
            Positioned(
              top: -50, right: -50,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Colors.white.withValues(alpha: 0.045),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            // Glass border
            Positioned.fill(child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(D.r24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
              ),
            )),
            Padding(
              padding: const EdgeInsets.all(D.g20),
              child: featured != null
                  ? _CardMatchContent(match: featured)
                  : _CardDefault(),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CardMatchContent extends StatelessWidget {
  final Match match;
  const _CardMatchContent({required this.match});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // League + status row
      Row(children: [
        if (match.isLive) ...[const _LivePulse(), const SizedBox(width: D.g6)],
        _Badge(label: match.isLive ? 'Live Now' : 'Upcoming', color: match.isLive ? D.red : D.blue),
        const SizedBox(width: D.g8),
        Expanded(child: Text(match.league, style: D.caption.copyWith(color: D.lbl2), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
      const Spacer(),
      // Teams
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _MiniTeam(name: match.homeDisplay, logoUrl: match.homeLogoUrl),
        Expanded(child: Column(children: [
          Text(
            match.isLive ? match.score : match.time,
            style: match.isLive
                ? D.title1.copyWith(letterSpacing: 5, fontSize: 32)
                : D.title3.copyWith(color: D.lbl2, letterSpacing: 1),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: D.g4),
          Text('vs', style: D.micro.copyWith(color: D.lbl3)),
        ])),
        _MiniTeam(name: match.awayDisplay, logoUrl: match.awayLogoUrl),
      ]),
      const Spacer(),
    ],
  );
}

class _CardDefault extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [const _LivePulse(), const SizedBox(width: D.g6), const _Badge(label: 'Live', color: D.red)]),
      const Spacer(),
      Text("Today's Matches", style: D.title2),
      const SizedBox(height: D.g4),
      Text('Tap to view all matches', style: D.caption),
      const Spacer(),
    ],
  );
}

class _MiniTeam extends StatelessWidget {
  final String name, logoUrl;
  const _MiniTeam({required this.name, required this.logoUrl});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 80,
    child: Column(children: [
      _NetworkImage(url: logoUrl, w: 46, h: 46),
      const SizedBox(height: D.g6),
      Text(name,
        style: D.caption.copyWith(fontWeight: FontWeight.w500, color: D.lbl),
        textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

// ─── Channel group row ───────────────────────────────────────────────────
class _ChannelGroupRow extends StatelessWidget {
  final ChannelGroup      group;
  final Function(Channel) onOpen;
  const _ChannelGroupRow({required this.group, required this.onOpen});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: D.g28),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Row header
      Padding(
        padding: const EdgeInsets.fromLTRB(D.g20, 0, D.g20, D.g14),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [D.blue.withValues(alpha: 0.30), D.blue.withValues(alpha: 0.10)]),
              borderRadius: BorderRadius.circular(D.r8),
              border: Border.all(color: D.blue.withValues(alpha: 0.25), width: 0.5),
            ),
            child: Icon(group.icon, size: 14, color: D.blue),
          ),
          const SizedBox(width: D.g10),
          Text(group.name, style: D.title3),
          const Spacer(),
          Text('${group.channels.length} channels', style: D.caption.copyWith(color: D.lbl3, fontSize: 11)),
          const SizedBox(width: D.g4),
          const Icon(CupertinoIcons.chevron_forward, size: 10, color: D.lbl3),
        ]),
      ),
      // Horizontal channel cards
      SizedBox(
        height: 162,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: D.g16),
          itemCount: group.channels.length,
          itemBuilder: (_, i) {
            final ch = group.channels[i];
            return _ChannelCard(channel: ch, onTap: () => onOpen(ch));
          },
        ),
      ),
    ]),
  );
}

class _ChannelCard extends StatelessWidget {
  final Channel  channel;
  final VoidCallback onTap;
  const _ChannelCard({required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context) => _SpringTap(
    onTap: onTap,
    child: Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: D.g6),
      child: Column(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [D.s3, D.s2],
              ),
              borderRadius: BorderRadius.circular(D.r20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.38), blurRadius: 14, offset: const Offset(0, 7)),
              ],
            ),
            child: Stack(children: [
              // Glass sheen overlay
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(D.r20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Colors.white.withValues(alpha: 0.055), Colors.transparent, Colors.black.withValues(alpha: 0.08)],
                ),
              ))),
              // Logo
              Padding(padding: const EdgeInsets.all(D.g16), child: Center(child: _NetworkImage(url: channel.logo, w: 58, h: 58))),
              // Number badge
              if (channel.number.isNotEmpty)
                Positioned(
                  top: D.g8, right: D.g8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: D.blue.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(D.r6),
                      border: Border.all(color: D.blue.withValues(alpha: 0.32), width: 0.5),
                    ),
                    child: Text(channel.number, style: D.micro.copyWith(color: D.blue, fontSize: 9)),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(height: D.g8),
        Text(channel.name,
          style: D.caption.copyWith(fontWeight: FontWeight.w500, color: D.lbl),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// MATCHES SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class MatchesScreen extends StatelessWidget {
  final List<Match> matches;
  final bool        loading;
  final Future<void> Function() onRefresh;

  const MatchesScreen({
    super.key,
    required this.matches,
    required this.loading,
    required this.onRefresh,
  });

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    final topPad   = MediaQuery.of(context).padding.top;
    final now      = DateTime.now();
    final today    = _fmtDate(now);
    final tomorrow = _fmtDate(now.add(const Duration(days: 1)));

    // Group by day label
    final grouped = <String, List<Match>>{};
    for (final m in matches) {
      final d   = _fmtDate(m.date);
      final key = d == today ? 'Today' : d == tomorrow ? 'Tomorrow' : d;
      grouped.putIfAbsent(key, () => []).add(m);
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: onRefresh),
        SliverToBoxAdapter(child: SizedBox(height: topPad + D.g8)),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(D.g20, 0, D.g20, D.g24),
          child: Text('Matches', style: D.hero),
        )),
        if (loading)
          const SliverToBoxAdapter(child: _Skeleton())
        else if (matches.isEmpty)
          const SliverFillRemaining(
            child: _EmptyView(icon: CupertinoIcons.sportscourt, label: 'No matches today'),
          )
        else
          ...grouped.entries.map((e) => SliverToBoxAdapter(
            child: _MatchDaySection(label: e.key, matches: e.value),
          )),
        const SliverToBoxAdapter(child: SizedBox(height: 116)),
      ],
    );
  }
}

class _MatchDaySection extends StatelessWidget {
  final String       label;
  final List<Match>  matches;
  const _MatchDaySection({required this.label, required this.matches});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(D.g16, 0, D.g16, D.g24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Day header pill
      Padding(
        padding: const EdgeInsets.only(left: D.g4, bottom: D.g12),
        child: Row(children: [
          if (label == 'Today') ...[const _LivePulse(), const SizedBox(width: D.g6)],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: D.g10, vertical: 5),
            decoration: BoxDecoration(
              color: label == 'Today' ? D.red.withValues(alpha: 0.12) : D.s3,
              borderRadius: BorderRadius.circular(D.rMax),
              border: Border.all(
                color: label == 'Today' ? D.red.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            child: Text(label, style: D.caption.copyWith(
              color: label == 'Today' ? D.red : D.lbl2,
              fontWeight: FontWeight.w600, fontSize: 13,
            )),
          ),
        ]),
      ),
      _GlassCard(children: matches.asMap().entries.map((e) =>
        _MatchRow(match: e.value, isLast: e.key == matches.length - 1),
      ).toList()),
    ]),
  );
}

class _MatchRow extends StatelessWidget {
  final Match match;
  final bool  isLast;
  const _MatchRow({required this.match, required this.isLast});

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: D.g16, vertical: D.g16),
      child: Column(children: [
        Text(match.league, style: D.caption.copyWith(color: D.lbl3, fontSize: 11), textAlign: TextAlign.center),
        const SizedBox(height: D.g12),
        Row(children: [
          // Home team
          Expanded(child: Column(children: [
            _NetworkImage(url: match.homeLogoUrl, w: 42, h: 42),
            const SizedBox(height: D.g6),
            Text(match.homeDisplay,
              style: D.caption.copyWith(fontWeight: FontWeight.w600, color: D.lbl),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          // Score / time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: D.g8),
            child: match.isLive
                ? Column(children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const _LivePulse(), const SizedBox(width: D.g4),
                      const _Badge(label: 'Live', color: D.red),
                    ]),
                    const SizedBox(height: D.g8),
                    Text(match.score, style: D.title2.copyWith(letterSpacing: 3)),
                  ])
                : Text(match.time, style: D.headline.copyWith(color: D.lbl2, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
          // Away team
          Expanded(child: Column(children: [
            _NetworkImage(url: match.awayLogoUrl, w: 42, h: 42),
            const SizedBox(height: D.g6),
            Text(match.awayDisplay,
              style: D.caption.copyWith(fontWeight: FontWeight.w600, color: D.lbl),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ]),
    ),
    if (!isLast) Container(
      height: 0.5,
      color: Colors.white.withValues(alpha: 0.055),
      margin: const EdgeInsets.symmetric(horizontal: D.g16),
    ),
  ]);
}

// ═══════════════════════════════════════════════════════════════════════════
// PLAYER SCREEN
//
// Architecture  (FIXED — all controls ON the video, nothing below controls):
//
//   Scaffold(black)
//   └── Column
//       ├── [PORTRAIT] SizedBox(statusBar + 16:9)   ← GestureDetector
//       │   └── Stack (StackFit.expand)
//       │       ├── ColoredBox (black)
//       │       ├── Positioned(top=statusBarH)  ← actual video
//       │       ├── Positioned top  ← gradient scrim
//       │       ├── Positioned bot  ← gradient scrim
//       │       └── FadeTransition  ← ALL controls (back, play, progress)
//       │
//       └── Expanded  ← channel info panel (not controls)
//
//   [LANDSCAPE] single GestureDetector + Stack fills whole screen
// ═══════════════════════════════════════════════════════════════════════════
class PlayerScreen extends StatefulWidget {
  final Channel  channel;
  final bool     isFavorite;
  final VoidCallback onToggleFav;

  const PlayerScreen({
    super.key,
    required this.channel,
    required this.isFavorite,
    required this.onToggleFav,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  // Player state
  VideoPlayerController? _vpc;
  ChewieController?      _cc;
  bool _loading = true, _error = false, _ctrlsVisible = true;
  late bool _isFav;

  // Controls fade
  late final AnimationController _ctrlsCtrl;
  late final Animation<double>   _ctrlsFade;

  // Favourite heart spring
  late final AnimationController _favCtrl;
  late final Animation<double>   _favScale;

  // 1-sec tick to redraw progress bar
  late final AnimationController _tick;

  static const _kUA =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/139.0.0.0 Safari/537.36';

  // ── lifecycle ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _isFav = widget.isFavorite;

    _ctrlsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _ctrlsFade = CurvedAnimation(parent: _ctrlsCtrl, curve: Curves.easeOut);
    _ctrlsCtrl.forward();

    _favCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _favScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 70),
    ]).animate(_favCtrl);

    _tick = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

    _initPlayer();
    _autoHideControls();
  }

  @override
  void dispose() {
    _ctrlsCtrl.dispose();
    _favCtrl.dispose();
    _tick.dispose();
    _cc?.dispose();
    _vpc?.dispose();
    super.dispose();
  }

  // ── controls visibility ────────────────────────────────────
  void _autoHideControls() => Future.delayed(const Duration(seconds: 4), () {
    if (mounted && _ctrlsVisible) {
      setState(() => _ctrlsVisible = false);
      _ctrlsCtrl.reverse();
    }
  });

  void _toggleControls() {
    HapticFeedback.selectionClick();
    setState(() => _ctrlsVisible = !_ctrlsVisible);
    _ctrlsVisible ? _ctrlsCtrl.forward() : _ctrlsCtrl.reverse();
    if (_ctrlsVisible) _autoHideControls();
  }

  // ── player init ────────────────────────────────────────────
  Future<void> _initPlayer() async {
    if (widget.channel.streamUrl.isEmpty) {
      if (mounted) setState(() { _loading = false; _error = true; });
      return;
    }
    if (mounted) setState(() { _loading = true; _error = false; });
    try {
      _vpc = VideoPlayerController.networkUrl(
        Uri.parse(widget.channel.streamUrl),
        httpHeaders: {
          'User-Agent': _kUA,
          'Referer':    'https://streamgo.tv/',
          'Origin':     'https://streamgo.tv',
        },
      );
      await _vpc!.initialize();
      _cc = ChewieController(
        videoPlayerController: _vpc!,
        autoPlay:         true,
        looping:          true,
        allowFullScreen:  true,
        allowMuting:      true,
        showControls:     false,          // ← we draw our own controls
        placeholder:      const Center(child: CupertinoActivityIndicator(radius: 16, color: Colors.white)),
        errorBuilder:     (_, __) => _PlayerError(onRetry: _retry),
      );
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  void _retry() {
    _cc?.dispose(); _vpc?.dispose();
    _cc = null;     _vpc = null;
    _initPlayer();
  }

  void _tapFav() {
    widget.onToggleFav();
    HapticFeedback.mediumImpact();
    setState(() => _isFav = !_isFav);
    _favCtrl.forward(from: 0);
  }

  // ── helpers ────────────────────────────────────────────────
  bool     get _playing  => _vpc?.value.isPlaying ?? false;
  Duration get _position => _vpc?.value.position  ?? Duration.zero;
  Duration get _duration => _vpc?.value.duration  ?? Duration.zero;

  double get _progress {
    final ms = _duration.inMilliseconds;
    return ms == 0 ? 0 : (_position.inMilliseconds / ms).clamp(0.0, 1.0);
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  // ── root build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq     = MediaQuery.of(context);
    final isLand = mq.orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: isLand ? _buildLandscape(mq) : _buildPortrait(mq),
      ),
    );
  }

  // ── LANDSCAPE: full-screen stack ───────────────────────────
  Widget _buildLandscape(MediaQueryData mq) => GestureDetector(
    onTap: _toggleControls,
    behavior: HitTestBehavior.opaque,
    child: Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: Colors.black),
      _videoContent(),
      // Top scrim
      Positioned(
        top: 0, left: 0, right: 0, height: 160,
        child: _GradScrim(fromTop: true),
      ),
      // Bottom scrim
      Positioned(
        bottom: 0, left: 0, right: 0, height: 160,
        child: _GradScrim(fromTop: false),
      ),
      // Controls overlaid on video
      FadeTransition(
        opacity: _ctrlsFade,
        SafeArea(child: _controlsStack(0)),
      ),
    ]),
  );

  // ── PORTRAIT: video zone (16:9 + status bar) + info panel ──
  Widget _buildPortrait(MediaQueryData mq) {
    final topPad = mq.padding.top;
    final videoH = mq.size.width * 9.0 / 16.0;

    return Column(children: [
      // ╔════════════════════════════════════════════════════╗
      // ║  VIDEO ZONE — all controls are ON the video here  ║
      // ╚════════════════════════════════════════════════════╝
      GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: double.infinity,
          height: topPad + videoH,
          child: Stack(fit: StackFit.expand, children: [
            // Black canvas
            const ColoredBox(color: Colors.black),

            // Actual video — positioned below the status bar
            Positioned(
              top: topPad, left: 0, right: 0, height: videoH,
              child: _videoContent(),
            ),

            // Top scrim (covers status bar + upper video edge)
            Positioned(
              top: 0, left: 0, right: 0, height: topPad + 88,
              child: _GradScrim(fromTop: true),
            ),

            // Bottom scrim (lower video edge, above progress bar)
            Positioned(
              bottom: 0, left: 0, right: 0, height: 100,
              child: _GradScrim(fromTop: false),
            ),

            // ──────────────────────────────────────────────
            // ALL CONTROLS overlaid directly ON the video
            // ──────────────────────────────────────────────
            FadeTransition(
              opacity: _ctrlsFade,
              child: _controlsStack(topOffset: topPad),
            ),
          ]),
        ),
      ),

      // ─────────────────────────────────────────────────────
      // INFO PANEL — channel details, NOT interactive controls
      // ─────────────────────────────────────────────────────
      Expanded(child: _infoPanel()),
    ]);
  }

  // ── Video content widget ───────────────────────────────────
  Widget _videoContent() {
    if (_loading) return const Center(child: CupertinoActivityIndicator(radius: 18, color: Colors.white));
    if (_error)   return _PlayerError(onRetry: _retry);
    if (_cc != null) return Chewie(controller: _cc!);
    return const Center(child: CupertinoActivityIndicator(radius: 18, color: Colors.white));
  }

  // ── Controls stack (back, play/pause, progress) ────────────
  // topOffset = status-bar height (portrait) or 0 (landscape/SafeArea)
  Widget _controlsStack(double topOffset) => Stack(children: [
    // — Top bar: back + channel name + fav ——————————————————
    Positioned(
      top: topOffset + D.g8, left: 0, right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: D.g16),
        child: Row(children: [
          // Back button (forced LTR so arrow always points left)
          Directionality(
            textDirection: TextDirection.ltr,
            child: _GlassCircleBtn(
              icon:  Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: D.g12),
          // Channel name + live badge
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(
                widget.channel.name,
                style: D.headline.copyWith(color: Colors.white, shadows: [const Shadow(blurRadius: 10)]),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(children: [
                const _LivePulse(),
                const SizedBox(width: D.g4),
                Text('Live', style: D.caption.copyWith(color: Colors.white70)),
              ]),
            ]),
          ),
          // Favourite button
          ScaleTransition(
            scale: _favScale,
            child: _GlassCircleBtn(
              icon:      _isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              iconColor: _isFav ? D.red : Colors.white,
              onTap:     _tapFav,
            ),
          ),
        ]),
      ),
    ),

    // — Centre play/pause ————————————————————————————————
    if (!_loading && !_error)
      Center(
        child: AnimatedBuilder(
          animation: _tick,
          builder: (_, __) => _GlassCircleBtn(
            icon: _playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
            size: 60, iconSize: 28,
            onTap: () {
              HapticFeedback.lightImpact();
              _playing ? _vpc!.pause() : _vpc!.play();
              setState(() {});
              _autoHideControls();
            },
          ),
        ),
      ),

    // — Bottom: progress bar + time stamps ────────────────
    if (!_loading && !_error)
      Positioned(
        bottom: D.g14, left: 0, right: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: D.g16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _tick,
              builder: (_, __) => _ProgressBar(progress: _progress),
            ),
            const SizedBox(height: D.g6),
            AnimatedBuilder(
              animation: _tick,
              builder: (_, __) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmtDuration(_position), style: D.micro.copyWith(color: Colors.white70, fontWeight: FontWeight.w500)),
                  Text(_fmtDuration(_duration), style: D.micro.copyWith(color: Colors.white38)),
                ],
              ),
            ),
          ]),
        ),
      ),
  ]);

  // ── Info panel (portrait only, NOT controls) ───────────────
  Widget _infoPanel() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [D.s1, D.bg],
      ),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(D.g20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          // Channel row
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Logo container
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [D.s3, D.s2]),
                borderRadius: BorderRadius.circular(D.r16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(D.r16),
                child: _NetworkImage(url: widget.channel.logo, w: 64, h: 64),
              ),
            ),
            const SizedBox(width: D.g16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(widget.channel.name, style: D.title3, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: D.g8),
              // Glass live badge
              ClipRRect(
                borderRadius: BorderRadius.circular(D.rMax),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: D.g10, vertical: D.g4),
                    decoration: BoxDecoration(
                      color: D.red.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(D.rMax),
                      border: Border.all(color: D.red.withValues(alpha: 0.28), width: 0.5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const _LivePulse(), const SizedBox(width: D.g6),
                      Text('Live', style: D.caption.copyWith(color: D.red, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
            ])),
            const SizedBox(width: D.g12),
            // Fav toggle button
            _SpringTap(
              onTap: _tapFav,
              child: ScaleTransition(
                scale: _favScale,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(D.rMax),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: D.s3.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        transitionBuilder: (c, a) => ScaleTransition(
                          scale: Tween(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
                          child: FadeTransition(opacity: a, child: c),
                        ),
                        child: Icon(
                          _isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                          key: ValueKey(_isFav),
                          color: _isFav ? D.red : D.lbl2, size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: D.g20),
          // Meta + reload strip
          ClipRRect(
            borderRadius: BorderRadius.circular(D.r14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: D.g16, vertical: D.g12),
                decoration: BoxDecoration(
                  color: D.s2.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(D.r14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
                ),
                child: Row(children: [
                  _Chip(icon: CupertinoIcons.tv,       label: 'Ch. ${widget.channel.number}'),
                  const SizedBox(width: D.g16),
                  const _Chip(icon: CupertinoIcons.waveform, label: 'HLS'),
                  const Spacer(),
                  // Reload button
                  _SpringTap(
                    onTap: _retry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: D.g12, vertical: D.g6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [D.blue.withValues(alpha: 0.22), D.blue.withValues(alpha: 0.10)]),
                        borderRadius: BorderRadius.circular(D.rMax),
                        border: Border.all(color: D.blue.withValues(alpha: 0.30), width: 0.5),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(CupertinoIcons.refresh, size: 12, color: D.blue),
                        const SizedBox(width: D.g4),
                        Text('Reload', style: D.micro.copyWith(color: D.blue, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// PLAYER SUB-WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Gradient scrim — covers top or bottom of the video
class _GradScrim extends StatelessWidget {
  final bool fromTop;
  const _GradScrim({required this.fromTop});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: fromTop ? Alignment.topCenter    : Alignment.bottomCenter,
        end:   fromTop ? Alignment.bottomCenter : Alignment.topCenter,
        colors: [Colors.black.withValues(alpha: 0.78), Colors.transparent],
      ),
    ),
  );
}

/// Thin progress track with glow + thumb dot
class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, c) {
      final w = c.maxWidth;
      return SizedBox(
        height: 22,
        child: Stack(alignment: Alignment.centerLeft, children: [
          // Track
          Container(
            height: 2.5, width: w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Fill
          Container(
            height: 2.5, width: w * progress,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(colors: [Color(0xFF0A84FF), Color(0xFF30D158)]),
              boxShadow: [BoxShadow(color: D.blue.withValues(alpha: 0.55), blurRadius: 7)],
            ),
          ),
          // Thumb
          Positioned(
            left: (w * progress - 5).clamp(0.0, w - 10),
            child: Container(
              width: 11, height: 11,
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: D.blue.withValues(alpha: 0.65), blurRadius: 8, spreadRadius: 1)],
              ),
            ),
          ),
        ]),
      );
    },
  );
}

/// Glass circular button used in player controls
class _GlassCircleBtn extends StatelessWidget {
  final IconData   icon;
  final Color?     iconColor;
  final VoidCallback onTap;
  final double     size, iconSize;

  const _GlassCircleBtn({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.size     = 44,
    this.iconSize = 21,
  });

  @override
  Widget build(BuildContext context) => _SpringTap(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(D.rMax),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 0.5),
          ),
          child: Icon(icon, color: iconColor ?? Colors.white, size: iconSize),
        ),
      ),
    ),
  );
}

/// Error overlay inside player
class _PlayerError extends StatelessWidget {
  final VoidCallback onRetry;
  const _PlayerError({required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black,
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
        ),
        child: const Icon(CupertinoIcons.wifi_slash, size: 32, color: Colors.white38),
      ),
      const SizedBox(height: 20),
      const Text('Connection Failed',
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3)),
      const SizedBox(height: 8),
      const Text('Unable to load stream',
        style: TextStyle(color: Colors.white54, fontSize: 14)),
      const SizedBox(height: 28),
      _SpringTap(
        onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1C6EF2), Color(0xFF0A50C8)]),
            borderRadius: BorderRadius.circular(D.rMax),
            boxShadow: [BoxShadow(color: D.blue.withValues(alpha: 0.45), blurRadius: 22, offset: const Offset(0, 6))],
          ),
          child: const Text('Try Again',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      ),
    ])),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED UI COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

/// Glass frosted card
class _GlassCard extends StatelessWidget {
  final List<Widget> children;
  const _GlassCard({required this.children});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(D.r16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        decoration: BoxDecoration(
          color: D.s2.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(D.r16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 4))],
        ),
        child: Column(children: children),
      ),
    ),
  );
}

/// Animated pulsing live dot
class _LivePulse extends StatefulWidget {
  const _LivePulse();
  @override State<_LivePulse> createState() => _LivePulseState();
}
class _LivePulseState extends State<_LivePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double>   _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _a = Tween(begin: 0.28, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child: Container(
      width: 6, height: 6,
      decoration: BoxDecoration(
        color: D.red, shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: D.red.withValues(alpha: 0.55), blurRadius: 4, spreadRadius: 1)],
      ),
    ),
  );
}

/// Rounded status badge
class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(D.rMax),
      border: Border.all(color: color.withValues(alpha: 0.28), width: 0.5),
    ),
    child: Text(label, style: D.micro.copyWith(color: color, fontWeight: FontWeight.w700)),
  );
}

/// Icon + label chip (used in info strip)
class _Chip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: D.lbl3),
    const SizedBox(width: D.g4),
    Text(label, style: D.caption.copyWith(fontSize: 11, color: D.lbl2)),
  ]);
}

/// Network image with icon fallback
class _NetworkImage extends StatelessWidget {
  final String url;
  final double w, h;
  const _NetworkImage({required this.url, required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return Icon(CupertinoIcons.tv, size: math.min(w, h) * 0.45, color: D.lbl4);
    return SizedBox(
      width: w, height: h,
      child: Image.network(
        url, width: w, height: h, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(CupertinoIcons.tv, size: math.min(w, h) * 0.45, color: D.lbl4),
      ),
    );
  }
}

/// Empty state view
class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _EmptyView({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 78, height: 78,
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [D.s3, D.s2]),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.5),
        ),
        child: Icon(icon, size: 34, color: D.lbl3),
      ),
      const SizedBox(height: 20),
      Text(label, style: D.body.copyWith(color: D.lbl2), textAlign: TextAlign.center),
    ]),
  );
}

/// Shimmer skeleton loading
class _Skeleton extends StatefulWidget {
  const _Skeleton();
  @override State<_Skeleton> createState() => _SkeletonState();
}
class _SkeletonState extends State<_Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double>   _x;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _x = Tween(begin: -1.5, end: 2.5).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: D.g16, vertical: D.g8),
    child: Column(
      children: List.generate(5, (_) => AnimatedBuilder(
        animation: _x,
        builder: (_, __) => Container(
          height: 66, margin: const EdgeInsets.only(bottom: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(D.r8),
            gradient: LinearGradient(
              begin: Alignment(_x.value - 1, 0), end: Alignment(_x.value, 0),
              colors: [D.s2, D.s4.withValues(alpha: 0.65), D.s2],
            ),
          ),
        ),
      )),
    ),
  );
}

/// Spring-press tap (no Material ripple, iOS feel)
class _SpringTap extends StatefulWidget {
  final Widget    child;
  final VoidCallback? onTap;
  const _SpringTap({required this.child, this.onTap});
  @override State<_SpringTap> createState() => _SpringTapState();
}
class _SpringTapState extends State<_SpringTap> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double>   _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween(begin: 1.0, end: 0.94).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:  (_) => _c.forward(),
    onTapUp:    (_) { _c.reverse(); widget.onTap?.call(); },
    onTapCancel: () => _c.reverse(),
    child: ScaleTransition(scale: _s, child: widget.child),
  );
}

/// Glass toast notification
class _Toast extends StatefulWidget {
  final String   message;
  final VoidCallback onDone;
  const _Toast({required this.message, required this.onDone});
  @override State<_Toast> createState() => _ToastState();
}
class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double>   _opa, _dy;
  @override
  void initState() {
    super.initState();
    _c   = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _opa = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _dy  = Tween(begin: 20.0, end: 0.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) _c.reverse().then((_) => widget.onDone());
    });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom + 100;
    return Positioned(
      bottom: bottomPad, left: 32, right: 32,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Opacity(
          opacity: _opa.value,
          child: Transform.translate(offset: Offset(0, _dy.value), child: child),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(D.r20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: D.s4.withValues(alpha: 0.93),
                borderRadius: BorderRadius.circular(D.r20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: Text(widget.message, style: D.callout.copyWith(fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// UTILITY
// ═══════════════════════════════════════════════════════════════════════════

/// Subtle grid texture painter (used on hero card)
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color      = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width;  x += 28) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 28) canvas.drawLine(Offset(0, y), Offset(size.width,  y),  p);
  }
  @override bool shouldRepaint(_) => false;
}

/// Fade + zoom page route (replaces default Material slide)
PageRoute<R> _fadeZoomRoute<R>(Widget page) => PageRouteBuilder<R>(
  pageBuilder: (_, a, __) => page,
  transitionDuration:        const Duration(milliseconds: 390),
  reverseTransitionDuration: const Duration(milliseconds: 320),
  transitionsBuilder: (_, a, __, child) => FadeTransition(
    opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
    child: ScaleTransition(
      scale: Tween(begin: 0.94, end: 1.0)
          .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
      child: child,
    ),
  ),
);

// end of StreamGo main.dart
