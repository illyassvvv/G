import 'dart:async';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GestureBinding.instance.resamplingEnabled = true;
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const StreamGoApp());
}

abstract class D {
  static const bg   = Color(0xFF010101);
  static const s1   = Color(0xFF080809);
  static const s2   = Color(0xFF0F0F11);
  static const s3   = Color(0xFF181819);
  static const s4   = Color(0xFF222224);
  static const s5   = Color(0xFF2E2E30);
  static const lbl  = Color(0xFFFFFFFF);
  static const lbl2 = Color(0xFF8E8E95);
  static const lbl3 = Color(0xFF48484E);
  static const lbl4 = Color(0xFF2D2D31);
  static const blue  = Color(0xFF0A84FF);
  static const red   = Color(0xFFFF453A);
  static const green = Color(0xFF30D158);

  static const r6   =  6.0;
  static const r8   =  8.0;
  static const r10  = 10.0;
  static const r12  = 12.0;
  static const r14  = 14.0;
  static const r16  = 16.0;
  static const r20  = 20.0;
  static const r24  = 24.0;
  static const r32  = 32.0;
  static const r36  = 36.0;
  static const rMax = 999.0;

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

  static const snap   = Cubic(0.16, 1.00, 0.30, 1.00);
  static const spring = Cubic(0.34, 1.56, 0.64, 1.00);
  static const smooth = Cubic(0.25, 0.46, 0.45, 0.94);

  static const _base = TextStyle(
    decoration: TextDecoration.none,
    decorationColor: Colors.transparent,
    fontFamily: 'SF Pro Display',
  );
  static TextStyle get hero     => _base.copyWith(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.4, height: 1.08, color: lbl);
  static TextStyle get title1   => _base.copyWith(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.8, height: 1.15, color: lbl);
  static TextStyle get title2   => _base.copyWith(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.20, color: lbl);
  static TextStyle get title3   => _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.30, color: lbl);
  static TextStyle get headline => _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2, height: 1.40, color: lbl);
  static TextStyle get body     => _base.copyWith(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.1, height: 1.50, color: lbl);
  static TextStyle get callout  => _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing:  0.0, height: 1.40, color: lbl);
  static TextStyle get caption  => _base.copyWith(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing:  0.1, height: 1.30, color: lbl2);
  static TextStyle get micro    => _base.copyWith(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing:  0.3, height: 1.20, color: lbl2);
}

class Channel {
  final int id;
  final String name, number, logo, streamUrl;
  const Channel({required this.id, required this.name, required this.number, required this.logo, required this.streamUrl});
  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
    id: j['id'] as int, name: j['name'] as String,
    number: j['number']?.toString() ?? '', logo: j['logo'] as String? ?? '',
    streamUrl: j['stream'] as String? ?? '',
  );
}

class ChannelGroup {
  final String name;
  final IconData icon;
  final List<Channel> channels;
  const ChannelGroup({required this.name, required this.icon, required this.channels});
  factory ChannelGroup.fromJson(Map<String, dynamic> j) => ChannelGroup(
    name: j['name'] as String,
    icon: _iconFor(j['icon'] as String? ?? 'tv'),
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
  final String id, league, home, homeEn, homeLogo, away, awayEn, awayLogo, score, time;
  final DateTime date;
  final bool isLive, hasChannels;
  const Match({
    required this.id, required this.league,
    required this.home, required this.homeEn, required this.homeLogo,
    required this.away, required this.awayEn, required this.awayLogo,
    required this.score, required this.time, required this.date,
    required this.isLive, required this.hasChannels,
  });
  factory Match.fromJson(Map<String, dynamic> j) {
    DateTime d; try { d = DateTime.parse(j['date'] as String? ?? ''); } catch (_) { d = DateTime.now(); }
    return Match(
      id: j['id']?.toString() ?? '', league: j['league'] as String? ?? '',
      home: j['home'] as String? ?? '', homeEn: j['home_en'] as String? ?? '',
      homeLogo: j['home_logo'] as String? ?? '', away: j['away'] as String? ?? '',
      awayEn: j['away_en'] as String? ?? '', awayLogo: j['away_logo'] as String? ?? '',
      score: j['score'] as String? ?? '0 - 0', time: j['time'] as String? ?? '', date: d,
      isLive: (j['status']?.toString() ?? '0') == '1',
      hasChannels: (j['has_channels']?.toString() ?? '0') == '1',
    );
  }
  String get homeLogoUrl => 'https://img.kora-api.space/uploads/team/$homeLogo';
  String get awayLogoUrl => 'https://img.kora-api.space/uploads/team/$awayLogo';
  String get homeDisplay => homeEn.isNotEmpty ? homeEn : home;
  String get awayDisplay => awayEn.isNotEmpty ? awayEn : away;
}

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
    const Channel(id: 7, name: 'Al Jazeera', number: '07', logo: 'https://upload.wikimedia.org/wikipedia/en/thumb/b/b2/Al_Jazeera_Logo_2006.svg/200px-Al_Jazeera_Logo_2006.svg.png', streamUrl: _kStream),
    const Channel(id: 8, name: 'Sky News',   number: '08', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/Sky_News_Arabia_logo.svg/200px-Sky_News_Arabia_logo.svg.png', streamUrl: _kStream),
    const Channel(id: 9, name: 'Al Arabiya', number: '09', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/29/Al_Arabiya_logo.svg/200px-Al_Arabiya_logo.svg.png', streamUrl: _kStream),
  ]),
  ChannelGroup(name: 'Entertainment', icon: CupertinoIcons.tv_fill, channels: [
    const Channel(id: 10, name: 'MBC 1',         number: '10', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/MBC1HD.png/200px-MBC1HD.png', streamUrl: _kStream),
    const Channel(id: 11, name: 'MBC 2',         number: '11', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/MBC1HD.png/200px-MBC1HD.png', streamUrl: _kStream),
    const Channel(id: 12, name: 'Rotana Cinema', number: '12', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/94/Rotana_logo.svg/200px-Rotana_logo.svg.png', streamUrl: _kStream),
  ]),
];

final List<Match> _kMockMatches = [
  Match(id:'1', league:'UEFA Champions League', home:'Real Madrid',   homeEn:'Real Madrid',   homeLogo:'real_madrid.png', away:'Man City',    awayEn:'Man City',    awayLogo:'man_city.png',  score:'2 - 1', time:'21:00', date:DateTime.now(),                             isLive:true,  hasChannels:true),
  Match(id:'2', league:'Premier League',        home:'Liverpool',     homeEn:'Liverpool',     homeLogo:'liverpool.png',   away:'Arsenal',     awayEn:'Arsenal',     awayLogo:'arsenal.png',   score:'1 - 1', time:'22:45', date:DateTime.now(),                             isLive:true,  hasChannels:true),
  Match(id:'3', league:'La Liga',               home:'Barcelona',     homeEn:'Barcelona',     homeLogo:'barca.png',       away:'Atletico',    awayEn:'Atletico',    awayLogo:'atletico.png',  score:'',      time:'23:00', date:DateTime.now(),                             isLive:false, hasChannels:true),
  Match(id:'4', league:'Bundesliga',            home:'Bayern Munich', homeEn:'Bayern Munich', homeLogo:'bayern.png',      away:'Dortmund',    awayEn:'Dortmund',    awayLogo:'dortmund.png',  score:'',      time:'20:30', date:DateTime.now().add(const Duration(days:1)), isLive:false, hasChannels:false),
  Match(id:'5', league:'Ligue 1',               home:'PSG',           homeEn:'PSG',           homeLogo:'psg.png',         away:'Marseille',   awayEn:'Marseille',   awayLogo:'marseille.png', score:'',      time:'21:45', date:DateTime.now().add(const Duration(days:1)), isLive:false, hasChannels:false),
  Match(id:'6', league:'UEFA Champions League', home:'Juventus',      homeEn:'Juventus',      homeLogo:'juve.png',        away:'Inter Milan', awayEn:'Inter Milan', awayLogo:'inter.png',     score:'',      time:'22:00', date:DateTime.now().add(const Duration(days:2)), isLive:false, hasChannels:false),
];

class Prefs {
  static const _kFav = 'favs_v3';
  static const _kSet = 'settings_v2';
  static Future<Set<int>> loadFavs() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_kFav) ?? []).map((e) => int.tryParse(e) ?? -1).toSet();
  }
  static Future<bool> toggleFav(int id) async {
    final p = await SharedPreferences.getInstance();
    final s = await loadFavs();
    s.contains(id) ? s.remove(id) : s.add(id);
    await p.setStringList(_kFav, s.map((e) => '$e').toList());
    return s.contains(id);
  }
  static Future<Map<String, dynamic>> loadSettings() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kSet);
    if (raw == null) return _def();
    try { return jsonDecode(raw) as Map<String, dynamic>; } catch (_) { return _def(); }
  }
  static Future<void> saveSettings(Map<String, dynamic> s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSet, jsonEncode(s));
  }
  static Map<String, dynamic> _def() => {'autoPlay': true, 'showScores': true, 'quality': 'auto'};
}

class StreamGoApp extends StatelessWidget {
  const StreamGoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'StreamGo',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: D.bg,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(primary: D.blue, surface: D.s1),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      }),
    ),
    home: const RootShell(),
  );
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with TickerProviderStateMixin {
  int _tab = 0;
  Set<int>            _favIds   = {};
  List<ChannelGroup>  _groups   = [];
  List<Match>         _matches  = [];
  Map<String,dynamic> _settings = {'autoPlay': true, 'showScores': true, 'quality': 'auto'};
  bool _groupsLoading = true;
  bool _matchLoading  = true;
  late final AnimationController _tabBarAnim;
  OverlayEntry? _toast;

  @override
  void initState() {
    super.initState();
    _tabBarAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _init();
  }
  @override
  void dispose() { _tabBarAnim.dispose(); super.dispose(); }

  Future<void> _init() => Future.wait([_loadFavs(), _loadSettings(), _loadGroups(), _loadMatches()]);

  Future<void> _loadFavs() async {
    final f = await Prefs.loadFavs();
    if (mounted) setState(() => _favIds = f);
  }
  Future<void> _loadSettings() async {
    final s = await Prefs.loadSettings();
    if (mounted) setState(() => _settings = s);
  }
  Future<void> _loadGroups() async {
    if (mounted) setState(() => _groupsLoading = true);
    try {
      final r = await http.get(Uri.parse('https://raw.githubusercontent.com/illyassvvv/G/refs/heads/main/channels.json')).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final list = ((jsonDecode(r.body) as Map)['categories'] as List).map((c) => ChannelGroup.fromJson(c)).toList();
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
      final r = await http.get(Uri.parse('https://ws.kora-api.space/api/matches/$ds/1')).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final list = (((jsonDecode(r.body) as Map)['matches'] as List?) ?? []).map((m) => Match.fromJson(m)).toList();
        if (mounted) setState(() { _matches = list; _matchLoading = false; });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() { _matches = _kMockMatches; _matchLoading = false; });
  }
  Future<void> _refresh() => Future.wait([_loadGroups(), _loadMatches()]);

  Future<void> _toggleFav(int id) async {
    HapticFeedback.lightImpact();
    final added = await Prefs.toggleFav(id);
    if (!mounted) return;
    setState(() => added ? _favIds.add(id) : _favIds.remove(id));
    _showToast(added ? '❤️  Added to Favorites' : 'Removed from Favorites');
  }

  void _openPlayer(Channel ch) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(_premiumRoute(PlayerScreen(
      channel: ch,
      isFavorite:  _favIds.contains(ch.id),
      autoPlay:    _settings['autoPlay'] as bool? ?? true,
      onToggleFav: () => _toggleFav(ch.id),
    )));
  }

  void _showToast(String msg) {
    _toast?.remove(); _toast = null;
    final e = OverlayEntry(builder: (_) => _Toast(message: msg, onDone: () { _toast?.remove(); _toast = null; }));
    _toast = e;
    Overlay.of(context).insert(e);
  }

  List<Channel> get _allCh  => _groups.expand((g) => g.channels).toList();
  List<Channel> get _favChs => _allCh.where((c) => _favIds.contains(c.id)).toList();

  void _setTab(int i) {
    if (i == _tab) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: D.bg,
    body: Stack(children: [
      IndexedStack(
        index: _tab,
        children: [
          HomeScreen(
            groups: _groups, matches: _matches,
            groupsLoading: _groupsLoading, matchLoading: _matchLoading,
            onOpenPlayer: _openPlayer,
            onGoMatches: () => _setTab(1),
            onRefresh: _refresh,
          ),
          MatchesScreen(
            matches: _matches, loading: _matchLoading,
            showScores: _settings['showScores'] as bool? ?? true,
            onRefresh: _loadMatches,
          ),
          FavoritesScreen(
            channels: _favChs, onOpenPlayer: _openPlayer, onToggleFav: _toggleFav,
          ),
          SettingsScreen(
            settings: _settings,
            onChanged: (s) async { setState(() => _settings = s); await Prefs.saveSettings(s); },
          ),
        ],
      ),
      Positioned(
        bottom: 0, left: 0, right: 0,
        child: RepaintBoundary(
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: _tabBarAnim, curve: D.snap)),
            child: _PillTabBar(selected: _tab, onTap: _setTab),
          ),
        ),
      ),
    ]),
  );
}

class _PillTabBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _PillTabBar({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 0, 22, math.max(bottom, 8) + 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(D.r36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 64, sigmaY: 64),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFF161618).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(D.r36),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.72), blurRadius: 64, spreadRadius: -8, offset: const Offset(0, 24)),
                BoxShadow(color: D.blue.withValues(alpha: 0.05), blurRadius: 40),
              ],
            ),
            child: Stack(children: [
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(D.r36),
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: const Alignment(0, 0.4),
                  colors: [Colors.white.withValues(alpha: 0.06), Colors.transparent],
                ),
              ))),
              LayoutBuilder(builder: (_, c) {
                final itemW = c.maxWidth / 4;
                return Stack(children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: selected.toDouble(), end: selected.toDouble()),
                    duration: const Duration(milliseconds: 360),
                    curve: D.spring,
                    builder: (_, pos, __) => Positioned(
                      left: pos * itemW + 6, top: 8, bottom: 8, width: itemW - 12,
                      child: DecoratedBox(decoration: BoxDecoration(
                        color: D.blue.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: D.blue.withValues(alpha: 0.32), width: 0.5),
                        boxShadow: [BoxShadow(color: D.blue.withValues(alpha: 0.24), blurRadius: 14)],
                      )),
                    ),
                  ),
                  Row(children: [
                    _TabItem(index: 0, selected: selected, icon: CupertinoIcons.house,       activeIcon: CupertinoIcons.house_fill,       label: 'Home',      onTap: onTap),
                    _TabItem(index: 1, selected: selected, icon: CupertinoIcons.sportscourt, activeIcon: CupertinoIcons.sportscourt_fill, label: 'Matches',   onTap: onTap),
                    _TabItem(index: 2, selected: selected, icon: CupertinoIcons.heart,       activeIcon: CupertinoIcons.heart_fill,       label: 'Favorites', onTap: onTap),
                    _TabItem(index: 3, selected: selected, icon: CupertinoIcons.gear_alt,    activeIcon: CupertinoIcons.gear_alt_fill,    label: 'Settings',  onTap: onTap),
                  ]),
                ]);
              }),
            ]),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final int index, selected;
  final IconData icon, activeIcon;
  final String label;
  final ValueChanged<int> onTap;
  const _TabItem({required this.index, required this.selected, required this.icon, required this.activeIcon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = index == selected;
    return Expanded(
      child: _Tap(
        onTap: () => onTap(index),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: Tween(begin: 0.55, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Icon(active ? activeIcon : icon, key: ValueKey(active), size: 22, color: active ? D.blue : D.lbl3),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? D.blue : D.lbl3, letterSpacing: -0.2,
              decoration: TextDecoration.none,
            ),
            child: Text(label),
          ),
        ]),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final List<ChannelGroup> groups;
  final List<Match>        matches;
  final bool               groupsLoading, matchLoading;
  final Function(Channel)  onOpenPlayer;
  final VoidCallback       onGoMatches;
  final Future<void> Function() onRefresh;
  const HomeScreen({super.key, required this.groups, required this.matches, required this.groupsLoading, required this.matchLoading, required this.onOpenPlayer, required this.onGoMatches, required this.onRefresh});

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 5)  return 'Late night 🌙';
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: onRefresh),
        SliverToBoxAdapter(child: SizedBox(height: top + D.g8)),
        SliverToBoxAdapter(child: _Reveal(delay: 0, child: Padding(
          padding: const EdgeInsets.fromLTRB(D.g20, 0, D.g20, D.g24),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_greet(), style: D.caption.copyWith(color: D.lbl2, fontSize: 13)),
              const SizedBox(height: 2),
              Text('StreamGo', style: D.hero),
            ]),
            _AvatarBtn(),
          ]),
        ))),
        SliverToBoxAdapter(child: _Reveal(delay: 60, child: Padding(
          padding: const EdgeInsets.fromLTRB(D.g16, 0, D.g16, D.g32),
          child: _FeaturedCard(matches: matches, loading: matchLoading, onGoMatches: onGoMatches),
        ))),
        if (groupsLoading)
          const SliverToBoxAdapter(child: _ShimmerList())
        else
          ...groups.asMap().entries.map((e) => SliverToBoxAdapter(
            child: _Reveal(delay: 80 + e.key * 50, child: _ChannelGroupRow(group: e.value, onOpen: onOpenPlayer)),
          )),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _AvatarBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1C6EF2), Color(0xFF0A50C8)]),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(color: D.blue.withValues(alpha: 0.42), blurRadius: 18, offset: const Offset(0, 5))],
    ),
    child: const Icon(CupertinoIcons.person_fill, size: 20, color: Colors.white),
  );
}

class _FeaturedCard extends StatefulWidget {
  final List<Match> matches;
  final bool loading;
  final VoidCallback onGoMatches;
  const _FeaturedCard({required this.matches, required this.loading, required this.onGoMatches});
  @override State<_FeaturedCard> createState() => _FeaturedCardState();
}
class _FeaturedCardState extends State<_FeaturedCard> with SingleTickerProviderStateMixin {
  late final AnimationController _glow;
  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
  }
  @override void dispose() { _glow.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return _ShimmerBox(height: 210, radius: D.r24);
    }
    final live     = widget.matches.where((m) => m.isLive).toList();
    final featured = live.isNotEmpty ? live.first : (widget.matches.isNotEmpty ? widget.matches.first : null);
    return _Tap(
      onTap: widget.onGoMatches,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _glow,
          builder: (_, child) => Container(
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(D.r24),
              gradient: LinearGradient(
                begin: Alignment.topRight, end: Alignment.bottomLeft,
                colors: [
                  const Color(0xFF0D2847),
                  Color.lerp(const Color(0xFF0A1E35), const Color(0xFF0E2244), _glow.value)!,
                  const Color(0xFF030810),
                ],
              ),
              boxShadow: [
                BoxShadow(color: D.blue.withValues(alpha: 0.08 + 0.10 * _glow.value), blurRadius: 44, offset: const Offset(0, 16)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 24, offset: const Offset(0, 6)),
              ],
            ),
            child: child,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(D.r24),
            child: Stack(children: [
              Positioned.fill(child: CustomPaint(painter: _GridPainter())),
              Positioned(top: -70, right: -70, child: _GlowOrb(size: 200, color: Colors.white, opacity: 0.045)),
              Positioned(bottom: -50, left: -50, child: _GlowOrb(size: 160, color: D.blue, opacity: 0.07)),
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(D.r24),
                gradient: LinearGradient(begin: Alignment.topCenter, end: const Alignment(0, 0.5), colors: [Colors.white.withValues(alpha: 0.05), Colors.transparent]),
              ))),
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(D.r24), border: Border.all(color: Colors.white.withValues(alpha: 0.09), width: 0.5)))),
              Padding(padding: const EdgeInsets.all(D.g20), child: featured != null ? _CardMatch(match: featured) : const _CardDefault()),
            ]),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size, opacity;
  final Color color;
  const _GlowOrb({required this.size, required this.color, required this.opacity});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withValues(alpha: opacity), Colors.transparent])),
  );
}

class _CardMatch extends StatelessWidget {
  final Match match;
  const _CardMatch({required this.match});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      if (match.isLive) ...[const _LivePulse(), const SizedBox(width: D.g6)],
      _Badge(label: match.isLive ? 'Live Now' : 'Upcoming', color: match.isLive ? D.red : D.blue),
      const SizedBox(width: D.g8),
      Expanded(child: Text(match.league, style: D.caption.copyWith(color: D.lbl2), maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]),
    const Spacer(),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _TeamBlock(name: match.homeDisplay, logoUrl: match.homeLogoUrl),
      Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: Tween(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)), child: child),
          ),
          child: Text(
            match.isLive ? match.score : match.time,
            key: ValueKey(match.isLive ? match.score : match.time),
            style: match.isLive ? D.title1.copyWith(letterSpacing: 5, fontSize: 32) : D.title3.copyWith(color: D.lbl2, letterSpacing: 1),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: D.g4),
        Text('vs', style: D.micro.copyWith(color: D.lbl3)),
      ])),
      _TeamBlock(name: match.awayDisplay, logoUrl: match.awayLogoUrl),
    ]),
    const Spacer(),
  ]);
}

class _CardDefault extends StatelessWidget {
  const _CardDefault();
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Row(children: [_LivePulse(), SizedBox(width: D.g6), _Badge(label: 'Live', color: D.red)]),
    const Spacer(),
    Text("Today's Matches", style: D.title2),
    const SizedBox(height: D.g4),
    Text('Tap to view all matches', style: D.caption),
    const Spacer(),
  ]);
}

class _TeamBlock extends StatelessWidget {
  final String name, logoUrl;
  const _TeamBlock({required this.name, required this.logoUrl});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 82,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      _NetImg(url: logoUrl, w: 48, h: 48),
      const SizedBox(height: D.g6),
      Text(name, style: D.caption.copyWith(fontWeight: FontWeight.w500, color: D.lbl), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _ChannelGroupRow extends StatelessWidget {
  final ChannelGroup group;
  final Function(Channel) onOpen;
  const _ChannelGroupRow({required this.group, required this.onOpen});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: D.g28),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(D.g20, 0, D.g20, D.g14),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(D.r8),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [D.blue.withValues(alpha: 0.28), D.blue.withValues(alpha: 0.08)]),
                  borderRadius: BorderRadius.circular(D.r8),
                  border: Border.all(color: D.blue.withValues(alpha: 0.22), width: 0.5),
                ),
                child: Icon(group.icon, size: 15, color: D.blue),
              ),
            ),
          ),
          const SizedBox(width: D.g10),
          Text(group.name, style: D.title3),
          const Spacer(),
          Text('${group.channels.length} channels', style: D.caption.copyWith(color: D.lbl3, fontSize: 11)),
          const SizedBox(width: D.g4),
          const Icon(CupertinoIcons.chevron_forward, size: 10, color: D.lbl3),
        ]),
      ),
      SizedBox(
        height: 168,
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
  final Channel channel;
  final VoidCallback onTap;
  const _ChannelCard({required this.channel, required this.onTap});
  @override
  Widget build(BuildContext context) => _Tap(
    onTap: onTap,
    child: Container(
      width: 114, margin: const EdgeInsets.symmetric(horizontal: D.g6),
      child: Column(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [D.s3, D.s2]),
              borderRadius: BorderRadius.circular(D.r20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09), width: 0.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: Stack(children: [
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(D.r20),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withValues(alpha: 0.07), Colors.transparent, Colors.black.withValues(alpha: 0.10)]),
              ))),
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(D.r20),
                gradient: LinearGradient(begin: Alignment.topCenter, end: const Alignment(0, 0.4), colors: [Colors.white.withValues(alpha: 0.04), Colors.transparent]),
              ))),
              Center(child: Padding(padding: const EdgeInsets.all(D.g16), child: _NetImg(url: channel.logo, w: 64, h: 64))),
              if (channel.number.isNotEmpty)
                Positioned(top: D.g8, right: D.g8, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: D.blue.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(D.r6), border: Border.all(color: D.blue.withValues(alpha: 0.32), width: 0.5)),
                  child: Text(channel.number, style: D.micro.copyWith(color: D.blue, fontSize: 9)),
                )),
            ]),
          ),
        ),
        const SizedBox(height: D.g8),
        Text(channel.name, style: D.caption.copyWith(fontWeight: FontWeight.w500, color: D.lbl), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

class MatchesScreen extends StatelessWidget {
  final List<Match> matches;
  final bool loading, showScores;
  final Future<void> Function() onRefresh;
  const MatchesScreen({super.key, required this.matches, required this.loading, required this.showScores, required this.onRefresh});

  String _d(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final now = DateTime.now();
    final today = _d(now), tomorrow = _d(now.add(const Duration(days: 1)));
    final grouped = <String, List<Match>>{};
    for (final m in matches) {
      final k = _d(m.date) == today ? 'Today' : _d(m.date) == tomorrow ? 'Tomorrow' : _d(m.date);
      grouped.putIfAbsent(k, () => []).add(m);
    }
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: onRefresh),
        SliverToBoxAdapter(child: SizedBox(height: top + D.g8)),
        SliverToBoxAdapter(child: _Reveal(delay: 0, child: Padding(padding: const EdgeInsets.fromLTRB(D.g20, 0, D.g20, D.g24), child: Text('Matches', style: D.hero)))),
        if (loading)
          const SliverToBoxAdapter(child: _ShimmerList())
        else if (matches.isEmpty)
          const SliverFillRemaining(child: _EmptyView(icon: CupertinoIcons.sportscourt, label: 'No matches today'))
        else
          ...grouped.entries.toList().asMap().entries.map((me) => SliverToBoxAdapter(
            child: _Reveal(delay: 60 + me.key * 60, child: _MatchSection(label: me.value.key, matches: me.value.value, showScores: showScores)),
          )),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _MatchSection extends StatelessWidget {
  final String label;
  final List<Match> matches;
  final bool showScores;
  const _MatchSection({required this.label, required this.matches, required this.showScores});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(D.g16, 0, D.g16, D.g24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: D.g4, bottom: D.g12),
        child: Row(children: [
          if (label == 'Today') ...[const _LivePulse(), const SizedBox(width: D.g6)],
          ClipRRect(
            borderRadius: BorderRadius.circular(D.rMax),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: D.g10, vertical: 5),
                decoration: BoxDecoration(
                  color: label == 'Today' ? D.red.withValues(alpha: 0.12) : D.s3.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(D.rMax),
                  border: Border.all(color: label == 'Today' ? D.red.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.07), width: 0.5),
                ),
                child: Text(label, style: D.caption.copyWith(color: label == 'Today' ? D.red : D.lbl2, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
          ),
        ]),
      ),
      _GlassCard(children: matches.asMap().entries.map((e) => _MatchRow(match: e.value, showScore: showScores, isLast: e.key == matches.length - 1)).toList()),
    ]),
  );
}

class _MatchRow extends StatelessWidget {
  final Match match;
  final bool showScore, isLast;
  const _MatchRow({required this.match, required this.showScore, required this.isLast});
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: D.g16, vertical: D.g16),
      child: Column(children: [
        Text(match.league, style: D.caption.copyWith(color: D.lbl3, fontSize: 11), textAlign: TextAlign.center),
        const SizedBox(height: D.g12),
        Row(children: [
          Expanded(child: Column(children: [
            _NetImg(url: match.homeLogoUrl, w: 44, h: 44),
            const SizedBox(height: D.g6),
            Text(match.homeDisplay, style: D.caption.copyWith(fontWeight: FontWeight.w600, color: D.lbl), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: D.g8),
            child: match.isLive
                ? Column(children: [
                    const Row(mainAxisSize: MainAxisSize.min, children: [_LivePulse(), SizedBox(width: D.g4), _Badge(label: 'Live', color: D.red)]),
                    const SizedBox(height: D.g8),
                    if (showScore) AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)), child: child),
                      ),
                      child: Text(match.score, key: ValueKey(match.score), style: D.title2.copyWith(letterSpacing: 3)),
                    ),
                  ])
                : Text(match.time, style: D.headline.copyWith(color: D.lbl2, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
          Expanded(child: Column(children: [
            _NetImg(url: match.awayLogoUrl, w: 44, h: 44),
            const SizedBox(height: D.g6),
            Text(match.awayDisplay, style: D.caption.copyWith(fontWeight: FontWeight.w600, color: D.lbl), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ]),
    ),
    if (!isLast) Container(height: 0.5, color: Colors.white.withValues(alpha: 0.055), margin: const EdgeInsets.symmetric(horizontal: D.g16)),
  ]);
}

class FavoritesScreen extends StatelessWidget {
  final List<Channel> channels;
  final Function(Channel) onOpenPlayer;
  final Function(int) onToggleFav;
  const FavoritesScreen({super.key, required this.channels, required this.onOpenPlayer, required this.onToggleFav});
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: top + D.g8)),
        SliverToBoxAdapter(child: _Reveal(delay: 0, child: Padding(
          padding: const EdgeInsets.fromLTRB(D.g20, 0, D.g20, D.g24),
          child: Row(children: [
            Text('Favorites', style: D.hero),
            if (channels.isNotEmpty) ...[const SizedBox(width: D.g12), _Badge(label: '${channels.length}', color: D.red)],
          ]),
        ))),
        if (channels.isEmpty)
          SliverFillRemaining(child: _Reveal(delay: 60, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            _GlassCircle(child: const Icon(CupertinoIcons.heart, size: 36, color: D.lbl3)),
            const SizedBox(height: D.g20),
            Text('No favorites yet', style: D.body.copyWith(color: D.lbl2)),
            const SizedBox(height: D.g8),
            Text('Tap ♡ on any channel to add it', style: D.caption.copyWith(color: D.lbl3)),
          ])))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: D.g16),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (_, i) {
                final ch = channels[i];
                return _Reveal(delay: 40 + i * 40, child: _FavRow(
                  channel: ch, isFirst: i == 0, isLast: i == channels.length - 1,
                  onTap: () => onOpenPlayer(ch), onRemove: () => onToggleFav(ch.id),
                ));
              },
              childCount: channels.length,
            )),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _FavRow extends StatelessWidget {
  final Channel channel;
  final bool isFirst, isLast;
  final VoidCallback onTap, onRemove;
  const _FavRow({required this.channel, required this.isFirst, required this.isLast, required this.onTap, required this.onRemove});
  @override
  Widget build(BuildContext context) => _Tap(
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 0.8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [D.s3, D.s2]),
        borderRadius: BorderRadius.vertical(top: isFirst ? const Radius.circular(D.r16) : Radius.zero, bottom: isLast ? const Radius.circular(D.r16) : Radius.zero),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: D.g16, vertical: D.g12),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [D.s4, D.s3]), borderRadius: BorderRadius.circular(D.r10), border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.5)),
            child: ClipRRect(borderRadius: BorderRadius.circular(D.r10), child: _NetImg(url: channel.logo, w: 48, h: 48)),
          ),
          const SizedBox(width: D.g12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(channel.name, style: D.callout.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('Ch. ${channel.number}', style: D.caption.copyWith(fontSize: 11, color: D.lbl3)),
          ])),
          _Tap(onTap: onRemove, child: Padding(padding: const EdgeInsets.all(D.g8), child: const Icon(CupertinoIcons.heart_fill, color: D.red, size: 20))),
          const Icon(CupertinoIcons.chevron_forward, size: 12, color: D.lbl3),
        ]),
      ),
    ),
  );
}

class SettingsScreen extends StatelessWidget {
  final Map<String, dynamic> settings;
  final ValueChanged<Map<String, dynamic>> onChanged;
  const SettingsScreen({super.key, required this.settings, required this.onChanged});
  void _set(String k, dynamic v) => onChanged(Map<String, dynamic>.from(settings)..[k] = v);
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: top + D.g8)),
        SliverToBoxAdapter(child: _Reveal(delay: 0, child: Padding(padding: const EdgeInsets.fromLTRB(D.g20, 0, D.g20, D.g32), child: Text('Settings', style: D.hero)))),
        SliverToBoxAdapter(child: _Reveal(delay: 50, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: D.g16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SecLabel('Playback'),
            _GlassCard(children: [
              _TogRow(icon: CupertinoIcons.play_circle_fill, color: D.red,   title: 'Auto Play',   sub: 'Start streaming immediately on open', val: settings['autoPlay'] as bool? ?? true,   onChange: (v) => _set('autoPlay', v)),
              _TogRow(icon: CupertinoIcons.sportscourt_fill, color: D.green, title: 'Show Scores', sub: 'Display live scores on match cards',   val: settings['showScores'] as bool? ?? true, onChange: (v) => _set('showScores', v)),
            ]),
            const SizedBox(height: D.g28),
            _SecLabel('Stream Quality'),
            _GlassCard(children: [
              for (final q in [('auto','Auto'), ('hd','HD'), ('sd','SD')])
                _QRow(label: q.$2, active: (settings['quality'] as String? ?? 'auto') == q.$1, isLast: q.$1 == 'sd', onTap: () => _set('quality', q.$1)),
            ]),
            const SizedBox(height: D.g28),
            _SecLabel('About'),
            _GlassCard(children: [
              _IRow(label: 'App',       value: 'StreamGo'),
              _IRow(label: 'Version',   value: '3.0.0'),
              _IRow(label: 'Developer', value: 'StreamGo Team', isLast: true),
            ]),
            const SizedBox(height: D.g32),
          ]),
        ))),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _SecLabel extends StatelessWidget {
  final String text;
  const _SecLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: D.g6, bottom: D.g10),
    child: Text(text.toUpperCase(), style: D.micro.copyWith(color: D.lbl3, letterSpacing: 0.8)),
  );
}

class _TogRow extends StatelessWidget {
  final IconData icon; final Color color; final String title, sub; final bool val; final ValueChanged<bool> onChange;
  const _TogRow({required this.icon, required this.color, required this.title, required this.sub, required this.val, required this.onChange});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: D.g16, vertical: D.g14),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, Color.lerp(color, Colors.black, 0.22)!]),
          borderRadius: BorderRadius.circular(D.r8),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.32), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
      const SizedBox(width: D.g14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: D.callout.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(sub, style: D.caption.copyWith(fontSize: 11, color: D.lbl3)),
      ])),
      CupertinoSwitch(value: val, onChanged: onChange, activeColor: D.blue),
    ]),
  );
}

class _QRow extends StatelessWidget {
  final String label; final bool active, isLast; final VoidCallback onTap;
  const _QRow({required this.label, required this.active, required this.isLast, required this.onTap});
  @override
  Widget build(BuildContext context) => Column(children: [
    _Tap(onTap: onTap, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: D.g16, vertical: D.g16),
      child: Row(children: [
        Expanded(child: Text(label, style: D.callout.copyWith(fontWeight: FontWeight.w500, color: active ? D.blue : D.lbl))),
        if (active) const Icon(CupertinoIcons.checkmark, color: D.blue, size: 17),
      ]),
    )),
    if (!isLast) Container(height: 0.5, color: Colors.white.withValues(alpha: 0.055), margin: const EdgeInsets.only(left: D.g16)),
  ]);
}

class _IRow extends StatelessWidget {
  final String label, value; final bool isLast;
  const _IRow({required this.label, required this.value, this.isLast = false});
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: D.g16, vertical: D.g16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: D.callout.copyWith(fontWeight: FontWeight.w500)),
        Text(value, style: D.callout.copyWith(color: D.lbl3)),
      ]),
    ),
    if (!isLast) Container(height: 0.5, color: Colors.white.withValues(alpha: 0.055), margin: const EdgeInsets.only(left: D.g16)),
  ]);
}

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  final bool isFavorite, autoPlay;
  final VoidCallback onToggleFav;
  const PlayerScreen({super.key, required this.channel, required this.isFavorite, required this.autoPlay, required this.onToggleFav});
  @override State<PlayerScreen> createState() => _PlayerState();
}

class _PlayerState extends State<PlayerScreen> with TickerProviderStateMixin {
  VideoPlayerController? _vpc;
  ChewieController?      _cc;
  bool _loading = true, _error = false, _ctrlsOn = true;
  late bool _isFav;
  Timer? _hideTimer;

  late final AnimationController _ctrlsCtrl;
  late final Animation<double>   _ctrlsFade;
  late final AnimationController _favCtrl;
  late final Animation<double>   _favScale;
  late final AnimationController _tick;

  static const _kUA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36';

  @override
  void initState() {
    super.initState();
    _isFav = widget.isFavorite;
    _ctrlsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _ctrlsFade = CurvedAnimation(parent: _ctrlsCtrl, curve: Curves.easeOut);
    _ctrlsCtrl.forward();
    _favCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _favScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 70),
    ]).animate(_favCtrl);
    _tick = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _initPlayer();
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _ctrlsCtrl.dispose(); _favCtrl.dispose(); _tick.dispose();
    _cc?.dispose(); _vpc?.dispose();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _ctrlsOn) { setState(() => _ctrlsOn = false); _ctrlsCtrl.reverse(); }
    });
  }

  void _tapScreen() {
    HapticFeedback.selectionClick();
    setState(() => _ctrlsOn = !_ctrlsOn);
    _ctrlsOn ? _ctrlsCtrl.forward() : _ctrlsCtrl.reverse();
    if (_ctrlsOn) _scheduleHide();
  }

  Future<void> _initPlayer() async {
    if (widget.channel.streamUrl.isEmpty) { if (mounted) setState(() { _loading = false; _error = true; }); return; }
    if (mounted) setState(() { _loading = true; _error = false; });
    try {
      _vpc = VideoPlayerController.networkUrl(Uri.parse(widget.channel.streamUrl), httpHeaders: {'User-Agent': _kUA, 'Referer': 'https://streamgo.tv/', 'Origin': 'https://streamgo.tv'});
      await _vpc!.initialize();
      _cc = ChewieController(videoPlayerController: _vpc!, autoPlay: widget.autoPlay, looping: true, allowFullScreen: false, allowMuting: true, showControls: false, placeholder: const Center(child: CupertinoActivityIndicator(radius: 16, color: Colors.white)), errorBuilder: (_, __) => _PError(onRetry: _retry));
      if (mounted) setState(() => _loading = false);
    } catch (_) { if (mounted) setState(() { _loading = false; _error = true; }); }
  }

  void _retry() { _cc?.dispose(); _vpc?.dispose(); _cc = null; _vpc = null; _initPlayer(); }
  void _tapFav() { widget.onToggleFav(); HapticFeedback.mediumImpact(); setState(() => _isFav = !_isFav); _favCtrl.forward(from: 0); }
  void _toggleFS(bool isLand) { HapticFeedback.lightImpact(); SystemChrome.setPreferredOrientations(isLand ? [DeviceOrientation.portraitUp] : [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]); }

  bool     get _playing  => _vpc?.value.isPlaying ?? false;
  Duration get _position => _vpc?.value.position  ?? Duration.zero;
  Duration get _duration => _vpc?.value.duration  ?? Duration.zero;
  double   get _progress { final ms = _duration.inMilliseconds; return ms == 0 ? 0 : (_position.inMilliseconds / ms).clamp(0.0, 1.0); }
  String   _fmt(Duration d) { final m = d.inMinutes.remainder(60).toString().padLeft(2,'0'); final s = d.inSeconds.remainder(60).toString().padLeft(2,'0'); return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s'; }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: mq.orientation == Orientation.landscape ? _land(mq) : _port(mq),
      ),
    );
  }

  Widget _land(MediaQueryData mq) => GestureDetector(
    onTap: _tapScreen, behavior: HitTestBehavior.opaque,
    child: Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: Colors.black),
      _vidWidget(),
      Positioned(top: 0,    left: 0, right: 0, height: 160, child: const _Scrim(top: true)),
      Positioned(bottom: 0, left: 0, right: 0, height: 160, child: const _Scrim(top: false)),
      IgnorePointer(ignoring: !_ctrlsOn, child: FadeTransition(opacity: _ctrlsFade, child: SafeArea(child: _ctrlsWidget(0, true)))),
    ]),
  );

  Widget _port(MediaQueryData mq) {
    final topPad = mq.padding.top;
    final videoH = mq.size.width * 9.0 / 16.0;
    return Column(children: [
      GestureDetector(
        onTap: _tapScreen, behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: double.infinity, height: topPad + videoH,
          child: Stack(fit: StackFit.expand, children: [
            const ColoredBox(color: Colors.black),
            Positioned(top: topPad, left: 0, right: 0, height: videoH, child: _vidWidget()),
            Positioned(top: 0,    left: 0, right: 0, height: topPad + 100, child: const _Scrim(top: true)),
            Positioned(bottom: 0, left: 0, right: 0, height: 120,          child: const _Scrim(top: false)),
            IgnorePointer(ignoring: !_ctrlsOn, child: FadeTransition(opacity: _ctrlsFade, child: _ctrlsWidget(topPad, false))),
          ]),
        ),
      ),
      Expanded(child: _infoPanel()),
    ]);
  }

  Widget _vidWidget() {
    if (_loading) return const Center(child: CupertinoActivityIndicator(radius: 18, color: Colors.white));
    if (_error)   return _PError(onRetry: _retry);
    if (_cc != null) return Chewie(controller: _cc!);
    return const Center(child: CupertinoActivityIndicator(radius: 18, color: Colors.white));
  }

  Widget _ctrlsWidget(double topOff, bool isLand) => Stack(children: [
    Positioned(top: topOff + D.g10, left: 0, right: 0, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: D.g16),
      child: Row(children: [
        _GBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.of(context).pop()),
        const SizedBox(width: D.g12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(widget.channel.name, style: D.headline.copyWith(color: Colors.white, shadows: [const Shadow(blurRadius: 12)]), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          const Row(children: [_LivePulse(), SizedBox(width: D.g4), Text('Live', style: TextStyle(color: Colors.white70, fontSize: 12, decoration: TextDecoration.none))]),
        ])),
        ScaleTransition(scale: _favScale, child: _GBtn(icon: _isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart, iconColor: _isFav ? D.red : Colors.white, onTap: _tapFav)),
      ]),
    )),
    if (!_loading && !_error)
      Center(child: AnimatedBuilder(
        animation: _tick,
        builder: (_, __) => _GBtn(
          icon: _playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
          size: 64, iconSize: 28,
          onTap: () { HapticFeedback.lightImpact(); _playing ? _vpc!.pause() : _vpc!.play(); setState(() {}); _scheduleHide(); },
        ),
      )),
    if (!_loading && !_error)
      Positioned(bottom: D.g14, left: 0, right: 0, child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: D.g16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedBuilder(animation: _tick, builder: (_, __) => _ProgBar(progress: _progress)),
          const SizedBox(height: D.g8),
          AnimatedBuilder(animation: _tick, builder: (_, __) => Row(children: [
            Text(_fmt(_position), style: D.micro.copyWith(color: Colors.white70, fontWeight: FontWeight.w500)),
            const Spacer(),
            _GBtn(icon: isLand ? CupertinoIcons.arrow_down_right_arrow_up_left : CupertinoIcons.arrow_up_left_arrow_down_right, size: 32, iconSize: 15, onTap: () => _toggleFS(isLand)),
            const Spacer(),
            Text(_fmt(_duration), style: D.micro.copyWith(color: Colors.white38)),
          ])),
        ]),
      )),
  ]);

  Widget _infoPanel() => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [D.s1, D.bg])),
    child: SafeArea(top: false, child: Padding(
      padding: const EdgeInsets.all(D.g20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [D.s3, D.s2]), borderRadius: BorderRadius.circular(D.r16), border: Border.all(color: Colors.white.withValues(alpha: 0.09), width: 0.5), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.50), blurRadius: 16, offset: const Offset(0, 5))]),
            child: ClipRRect(borderRadius: BorderRadius.circular(D.r16), child: _NetImg(url: widget.channel.logo, w: 64, h: 64)),
          ),
          const SizedBox(width: D.g16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(widget.channel.name, style: D.title3, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: D.g8),
            ClipRRect(borderRadius: BorderRadius.circular(D.rMax), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: Container(
              padding: const EdgeInsets.symmetric(horizontal: D.g10, vertical: D.g4),
              decoration: BoxDecoration(color: D.red.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(D.rMax), border: Border.all(color: D.red.withValues(alpha: 0.26), width: 0.5)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [_LivePulse(), SizedBox(width: D.g6), Text('Live', style: TextStyle(color: D.red, fontWeight: FontWeight.w600, fontSize: 12, decoration: TextDecoration.none))]),
            ))),
          ])),
          const SizedBox(width: D.g12),
          _Tap(onTap: _tapFav, child: ScaleTransition(scale: _favScale, child: ClipRRect(borderRadius: BorderRadius.circular(D.rMax), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: D.s3.withValues(alpha: 0.80), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.09), width: 0.5)),
            child: AnimatedSwitcher(duration: const Duration(milliseconds: 240), transitionBuilder: (c, a) => ScaleTransition(scale: Tween(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)), child: FadeTransition(opacity: a, child: c)), child: Icon(_isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart, key: ValueKey(_isFav), color: _isFav ? D.red : D.lbl2, size: 22)),
          ))))),
        ]),
        const SizedBox(height: D.g20),
        ClipRRect(borderRadius: BorderRadius.circular(D.r14), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: Container(
          padding: const EdgeInsets.symmetric(horizontal: D.g16, vertical: D.g12),
          decoration: BoxDecoration(color: D.s2.withValues(alpha: 0.62), borderRadius: BorderRadius.circular(D.r14), border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.5)),
          child: Row(children: [
            _Chip(icon: CupertinoIcons.tv, label: 'Ch. ${widget.channel.number}'),
            const SizedBox(width: D.g16),
            const _Chip(icon: CupertinoIcons.waveform, label: 'HLS'),
            const Spacer(),
            _Tap(onTap: _retry, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: D.g12, vertical: D.g6),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [D.blue.withValues(alpha: 0.22), D.blue.withValues(alpha: 0.09)]), borderRadius: BorderRadius.circular(D.rMax), border: Border.all(color: D.blue.withValues(alpha: 0.30), width: 0.5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(CupertinoIcons.refresh, size: 12, color: D.blue), const SizedBox(width: D.g4), Text('Reload', style: D.micro.copyWith(color: D.blue, fontWeight: FontWeight.w600))]),
            )),
          ]),
        ))),
      ]),
    )),
  );
}

class _Scrim extends StatelessWidget {
  final bool top;
  const _Scrim({required this.top});
  @override
  Widget build(BuildContext context) => DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
    begin: top ? Alignment.topCenter : Alignment.bottomCenter,
    end:   top ? Alignment.bottomCenter : Alignment.topCenter,
    colors: [Colors.black.withValues(alpha: 0.82), Colors.transparent],
  )));
}

class _ProgBar extends StatelessWidget {
  final double progress;
  const _ProgBar({required this.progress});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
    final w = c.maxWidth;
    return SizedBox(height: 22, child: Stack(alignment: Alignment.centerLeft, children: [
      Container(height: 2.5, width: w, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(2))),
      Container(height: 2.5, width: w * progress, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), gradient: const LinearGradient(colors: [Color(0xFF0A84FF), Color(0xFF30D158)]), boxShadow: [BoxShadow(color: D.blue.withValues(alpha: 0.60), blurRadius: 8)])),
      Positioned(left: (w * progress - 5).clamp(0.0, w - 10), child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: D.blue.withValues(alpha: 0.70), blurRadius: 10, spreadRadius: 1)]))),
    ]));
  });
}

class _GBtn extends StatelessWidget {
  final IconData icon; final Color? iconColor; final VoidCallback onTap; final double size, iconSize;
  const _GBtn({required this.icon, required this.onTap, this.iconColor, this.size = 44, this.iconSize = 21});
  @override
  Widget build(BuildContext context) => _Tap(onTap: onTap, child: ClipRRect(borderRadius: BorderRadius.circular(D.rMax), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: Container(
    width: size, height: size,
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 0.5)),
    child: Stack(alignment: Alignment.center, children: [
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withValues(alpha: 0.09), Colors.transparent])))),
      Icon(icon, color: iconColor ?? Colors.white, size: iconSize),
    ]),
  ))));
}

class _PError extends StatelessWidget {
  final VoidCallback onRetry;
  const _PError({required this.onRetry});
  @override
  Widget build(BuildContext context) => Container(color: Colors.black, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    _GlassCircle(child: const Icon(CupertinoIcons.wifi_slash, size: 34, color: Colors.white38)),
    const SizedBox(height: 20),
    const Text('Connection Failed', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3, decoration: TextDecoration.none)),
    const SizedBox(height: 8),
    const Text('Unable to load stream', style: TextStyle(color: Colors.white54, fontSize: 14, decoration: TextDecoration.none)),
    const SizedBox(height: 28),
    _Tap(onTap: onRetry, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1C6EF2), Color(0xFF0A50C8)]), borderRadius: BorderRadius.circular(D.rMax), boxShadow: [BoxShadow(color: D.blue.withValues(alpha: 0.48), blurRadius: 24, offset: const Offset(0, 6))]),
      child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15, decoration: TextDecoration.none)),
    )),
  ])));
}

class _GlassCard extends StatelessWidget {
  final List<Widget> children;
  const _GlassCard({required this.children});
  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(D.r16), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: Container(
    decoration: BoxDecoration(
      color: D.s2.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(D.r16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.30), blurRadius: 22, offset: const Offset(0, 5))],
    ),
    child: Stack(children: [
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(D.r16), gradient: LinearGradient(begin: Alignment.topCenter, end: const Alignment(0, 0.4), colors: [Colors.white.withValues(alpha: 0.05), Colors.transparent])))),
      Column(children: children),
    ]),
  )));
}

class _GlassCircle extends StatelessWidget {
  final Widget child;
  const _GlassCircle({required this.child});
  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(D.rMax), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: Container(
    width: 80, height: 80,
    decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [D.s3, D.s2]), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.09), width: 0.5)),
    child: child,
  )));
}

class _LivePulse extends StatefulWidget {
  const _LivePulse();
  @override State<_LivePulse> createState() => _LivePulseState();
}
class _LivePulseState extends State<_LivePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _a = Tween(begin: 0.20, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _a, child: Container(width: 6, height: 6, decoration: BoxDecoration(color: D.red, shape: BoxShape.circle, boxShadow: [BoxShadow(color: D.red.withValues(alpha: 0.65), blurRadius: 5, spreadRadius: 1)])));
}

class _Badge extends StatelessWidget {
  final String label; final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(D.rMax), border: Border.all(color: color.withValues(alpha: 0.28), width: 0.5)),
    child: Text(label, style: D.micro.copyWith(color: color, fontWeight: FontWeight.w700)),
  );
}

class _Chip extends StatelessWidget {
  final IconData icon; final String label;
  const _Chip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: D.lbl3), const SizedBox(width: D.g4), Text(label, style: D.caption.copyWith(fontSize: 11, color: D.lbl2))]);
}

class _NetImg extends StatelessWidget {
  final String url; final double w, h;
  const _NetImg({required this.url, required this.w, required this.h});
  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return Icon(CupertinoIcons.tv, size: math.min(w, h) * 0.45, color: D.lbl4);
    return SizedBox(width: w, height: h, child: Image.network(url, width: w, height: h, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(CupertinoIcons.tv, size: math.min(w, h) * 0.45, color: D.lbl4)));
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon; final String label;
  const _EmptyView({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    _GlassCircle(child: Icon(icon, size: 34, color: D.lbl3)),
    const SizedBox(height: 20),
    Text(label, style: D.body.copyWith(color: D.lbl2), textAlign: TextAlign.center),
  ]));
}

class _ShimmerBox extends StatefulWidget {
  final double height, radius;
  const _ShimmerBox({required this.height, required this.radius});
  @override State<_ShimmerBox> createState() => _ShimmerBoxState();
}
class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _x;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(); _x = Tween(begin: -1.5, end: 2.5).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _x, builder: (_, __) => Container(
    height: widget.height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(widget.radius),
      gradient: LinearGradient(begin: Alignment(_x.value - 1, 0), end: Alignment(_x.value, 0), colors: [D.s2, D.s4.withValues(alpha: 0.70), D.s2]),
    ),
  ));
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: D.g16, vertical: D.g8),
    child: Column(children: [
      _ShimmerBox(height: 210, radius: D.r24),
      const SizedBox(height: D.g24),
      ...List.generate(4, (i) => Padding(padding: const EdgeInsets.only(bottom: 1), child: _ShimmerBox(height: 68, radius: i == 0 ? D.r16 : (i == 3 ? D.r16 : D.r8)))),
    ]),
  );
}

class _Reveal extends StatefulWidget {
  final Widget child; final int delay;
  const _Reveal({required this.child, required this.delay});
  @override State<_Reveal> createState() => _RevealState();
}
class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opa, _dy;
  @override
  void initState() {
    super.initState();
    _c   = AnimationController(vsync: this, duration: const Duration(milliseconds: 440));
    _opa = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _dy  = Tween(begin: 20.0, end: 0.0).animate(CurvedAnimation(parent: _c, curve: const Cubic(0.16, 1.00, 0.30, 1.00)));
    if (widget.delay == 0) {
      _c.forward();
    } else {
      Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _c.forward(); });
    }
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, child) => Opacity(opacity: _opa.value, child: Transform.translate(offset: Offset(0, _dy.value), child: child)),
    child: widget.child,
  );
}

class _Tap extends StatefulWidget {
  final Widget child; final VoidCallback? onTap;
  const _Tap({required this.child, this.onTap});
  @override State<_Tap> createState() => _TapState();
}
class _TapState extends State<_Tap> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  static const _pressIn  = Cubic(0.40, 0.00, 1.00, 1.00);
  static const _release  = Cubic(0.34, 1.56, 0.64, 1.00);
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, lowerBound: -0.3, upperBound: 1.0); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  void _down(_) { HapticFeedback.lightImpact(); _c.animateTo(1.0, duration: const Duration(milliseconds: 72), curve: _pressIn); }
  void _up(_)   { widget.onTap?.call(); _c.animateTo(0.0, duration: const Duration(milliseconds: 480), curve: _release); }
  void _cancel(){ _c.animateTo(0.0, duration: const Duration(milliseconds: 280), curve: Curves.easeOut); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: _down, onTapUp: _up, onTapCancel: _cancel,
    child: AnimatedBuilder(animation: _c, builder: (_, child) => Transform.scale(scale: 1.0 - 0.07 * _c.value, child: child), child: widget.child),
  );
}

class _Toast extends StatefulWidget {
  final String message; final VoidCallback onDone;
  const _Toast({required this.message, required this.onDone});
  @override State<_Toast> createState() => _ToastState();
}
class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opa, _dy;
  @override
  void initState() {
    super.initState();
    _c   = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _opa = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _dy  = Tween(begin: 22.0, end: 0.0).animate(CurvedAnimation(parent: _c, curve: const Cubic(0.16, 1.00, 0.30, 1.00)));
    _c.forward();
    Future.delayed(const Duration(milliseconds: 2200), () { if (mounted) _c.reverse().then((_) => widget.onDone()); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 106;
    return Positioned(
      bottom: bottom, left: 28, right: 28,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Opacity(opacity: _opa.value, child: Transform.translate(offset: Offset(0, _dy.value), child: child)),
        child: ClipRRect(borderRadius: BorderRadius.circular(D.r20), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 52, sigmaY: 52), child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: D.s4.withValues(alpha: 0.88), borderRadius: BorderRadius.circular(D.r20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.40), blurRadius: 32, offset: const Offset(0, 10))],
          ),
          child: Stack(children: [
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(D.r20), gradient: LinearGradient(begin: Alignment.topCenter, end: const Alignment(0, 0.5), colors: [Colors.white.withValues(alpha: 0.06), Colors.transparent])))),
            Text(widget.message, style: D.callout.copyWith(fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ]),
        ))),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.020)..strokeWidth = 0.5;
    for (double x = 0; x < size.width;  x += 28) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 28) canvas.drawLine(Offset(0, y), Offset(size.width,  y),  p);
  }
  @override bool shouldRepaint(_) => false;
}

PageRoute<R> _premiumRoute<R>(Widget page) => PageRouteBuilder<R>(
  pageBuilder: (_, a, __) => page,
  transitionDuration:        const Duration(milliseconds: 420),
  reverseTransitionDuration: const Duration(milliseconds: 340),
  transitionsBuilder: (_, a, __, child) => FadeTransition(
    opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
    child: ScaleTransition(
      scale: Tween(begin: 0.93, end: 1.0).animate(CurvedAnimation(parent: a, curve: const Cubic(0.16, 1.00, 0.30, 1.00))),
      child: child,
    ),
  ),
);
