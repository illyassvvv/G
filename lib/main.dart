// StreamGo — Flagship Flutter IPTV App
// Single file: paste into lib/main.dart
// pubspec.yaml deps needed:
//   http: ^1.2.0
//   shared_preferences: ^2.2.2
//   video_player: ^2.8.3
//   chewie: ^1.7.4
// Android: add <uses-permission android:name="android.permission.INTERNET"/> to AndroidManifest.xml

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

// ═══════════════════════════════════════════════════════════════
// ENTRY POINT
// ═══════════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
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

// ═══════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ═══════════════════════════════════════════════════════════════
abstract class T {
  static const ink    = Color(0xFF000000);
  static const void_ = Color(0xFF050506);
  static const s1    = Color(0xFF0C0C0E);
  static const s2    = Color(0xFF141416);
  static const s3    = Color(0xFF1C1C1F);
  static const s4    = Color(0xFF2C2C2F);
  static const sep   = Color(0xFF2A2A2D);
  static const lbl   = Color(0xFFFFFFFF);
  static const lbl2  = Color(0xFF8E8E95);
  static const lbl3  = Color(0xFF48484E);
  static const lbl4  = Color(0xFF2D2D31);
  static const accent     = Color(0xFF0A84FF);
  static const accentSoft = Color(0xFF1A3A5C);
  static const red   = Color(0xFFFF453A);
  static const green = Color(0xFF30D158);
  static const gold  = Color(0xFFFFD60A);

  static const r4   =  4.0;
  static const r8   =  8.0;
  static const r12  = 12.0;
  static const r16  = 16.0;
  static const r20  = 20.0;
  static const r24  = 24.0;
  static const rFull = 999.0;

  static const p4  =  4.0;
  static const p6  =  6.0;
  static const p8  =  8.0;
  static const p10 = 10.0;
  static const p12 = 12.0;
  static const p14 = 14.0;
  static const p16 = 16.0;
  static const p20 = 20.0;
  static const p24 = 24.0;
  static const p28 = 28.0;
  static const p32 = 32.0;
  static const p40 = 40.0;
  static const p48 = 48.0;

  static TextStyle get display  => const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.0, height: 1.1, color: lbl);
  static TextStyle get title1   => const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6, height: 1.15, color: lbl);
  static TextStyle get title2   => const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.2,  color: lbl);
  static TextStyle get title3   => const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.3,  color: lbl);
  static TextStyle get headline => const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2, height: 1.4,  color: lbl);
  static TextStyle get body     => const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.1, height: 1.5,  color: lbl);
  static TextStyle get callout  => const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing:  0.0, height: 1.4,  color: lbl);
  static TextStyle get caption  => const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing:  0.1, height: 1.3,  color: lbl2);
  static TextStyle get micro    => const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing:  0.3, height: 1.2,  color: lbl2);
}

// ═══════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════
class Channel {
  final int id;
  final String name, number, logo, streamUrl;
  bool isFavorite;
  Channel({required this.id, required this.name, required this.number, required this.logo, required this.streamUrl, this.isFavorite = false});
  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
    id: j['id'] as int,
    name: j['name'] as String,
    number: j['number']?.toString() ?? '',
    logo: j['logo'] as String? ?? '',
    streamUrl: j['stream'] as String? ?? '',
  );
}

class AppCategory {
  final String name;
  final IconData icon;
  final List<Channel> channels;
  AppCategory({required this.name, required this.icon, required this.channels});
  factory AppCategory.fromJson(Map<String, dynamic> j) => AppCategory(
    name: j['name'] as String,
    icon: _icon(j['icon'] as String? ?? 'tv'),
    channels: (j['channels'] as List).map((c) => Channel.fromJson(c)).toList(),
  );
  static IconData _icon(String s) => const {
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
  Match({required this.id, required this.league, required this.home, required this.homeEn, required this.homeLogo, required this.away, required this.awayEn, required this.awayLogo, required this.score, required this.time, required this.date, required this.isLive, required this.hasChannels});
  factory Match.fromJson(Map<String, dynamic> j) {
    DateTime d; try { d = DateTime.parse(j['date'] as String? ?? ''); } catch (_) { d = DateTime.now(); }
    return Match(
      id: j['id']?.toString() ?? '', league: j['league'] as String? ?? '',
      home: j['home'] as String? ?? '', homeEn: j['home_en'] as String? ?? '', homeLogo: j['home_logo'] as String? ?? '',
      away: j['away'] as String? ?? '', awayEn: j['away_en'] as String? ?? '', awayLogo: j['away_logo'] as String? ?? '',
      score: j['score'] as String? ?? '0 - 0', time: j['time'] as String? ?? '', date: d,
      isLive: (j['status']?.toString() ?? '0') == '1',
      hasChannels: (j['has_channels']?.toString() ?? '0') == '1',
    );
  }
  String get homeLogoUrl => 'https://img.kora-api.space/uploads/team/$homeLogo';
  String get awayLogoUrl => 'https://img.kora-api.space/uploads/team/$awayLogo';
}

// ═══════════════════════════════════════════════════════════════
// MOCK DATA
// ═══════════════════════════════════════════════════════════════
final List<AppCategory> _mock = [
  AppCategory(name: 'رياضة', icon: CupertinoIcons.sportscourt_fill, channels: [
    Channel(id: 1,  name: 'beIN Sports 1',    number: '101', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/BeIN_Sports_logo.svg/200px-BeIN_Sports_logo.svg.png', streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8'),
    Channel(id: 2,  name: 'beIN Sports 2',    number: '102', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/BeIN_Sports_logo.svg/200px-BeIN_Sports_logo.svg.png', streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8'),
    Channel(id: 3,  name: 'SSC 1',            number: '103', logo: 'https://upload.wikimedia.org/wikipedia/ar/a/a7/SSC_Sports_Logo.png', streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8'),
    Channel(id: 4,  name: 'SSC 2',            number: '104', logo: 'https://upload.wikimedia.org/wikipedia/ar/a/a7/SSC_Sports_Logo.png', streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8'),
    Channel(id: 5,  name: 'MBC Sport',        number: '105', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/MBC_Sports_logo.svg/200px-MBC_Sports_logo.svg.png', streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8'),
    Channel(id: 6,  name: 'Abu Dhabi Sports', number: '106', logo: 'https://upload.wikimedia.org/wikipedia/ar/a/a3/AbuDhabiSports1.png', streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8'),
  ]),
  AppCategory(name: 'أخبار', icon: CupertinoIcons.news_solid, channels: [
    Channel(id: 7,  name: 'Al Jazeera',       number: '201', logo: 'https://upload.wikimedia.org/wikipedia/en/thumb/b/b2/Al_Jazeera_Logo_2006.svg/200px-Al_Jazeera_Logo_2006.svg.png', streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8'),
    Channel(id: 8,  name: 'Sky News Arabia',  number: '202', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/Sky_News_Arabia_logo.svg/200px-Sky_News_Arabia_logo.svg.png', streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8'),
    Channel(id: 9,  name: 'العربية',          number: '203', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/29/Al_Arabiya_logo.svg/200px-Al_Arabiya_logo.svg.png', streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8'),
  ]),
  AppCategory(name: 'ترفيه', icon: CupertinoIcons.tv_fill, channels: [
    Channel(id: 10, name: 'MBC 1',            number: '301', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/MBC1HD.png/200px-MBC1HD.png', streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8'),
    Channel(id: 11, name: 'MBC 2',            number: '302', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/MBC1HD.png/200px-MBC1HD.png', streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8'),
    Channel(id: 12, name: 'MBC Drama',        number: '303', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/MBC1HD.png/200px-MBC1HD.png', streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8'),
    Channel(id: 13, name: 'Rotana Cinema',    number: '304', logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/94/Rotana_logo.svg/200px-Rotana_logo.svg.png', streamUrl: 'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8'),
  ]),
];

final List<Match> _mockMatches = [
  Match(id:'1', league:'دوري أبطال أوروبا',   home:'ريال مدريد',         homeEn:'Real Madrid', homeLogo:'real_madrid.png', away:'مانشستر سيتي',    awayEn:'Man City',   awayLogo:'man_city.png',  score:'2 - 1', time:'21:00', date: DateTime.now(),                           isLive:true,  hasChannels:true),
  Match(id:'2', league:'الدوري الإنجليزي',    home:'ليفربول',             homeEn:'Liverpool',   homeLogo:'liverpool.png',   away:'أرسنال',           awayEn:'Arsenal',    awayLogo:'arsenal.png',   score:'1 - 1', time:'22:45', date: DateTime.now(),                           isLive:true,  hasChannels:true),
  Match(id:'3', league:'الدوري الإسباني',     home:'برشلونة',             homeEn:'Barcelona',   homeLogo:'barca.png',       away:'أتلتيكو مدريد',   awayEn:'Atletico',   awayLogo:'atletico.png',  score:'',      time:'23:00', date: DateTime.now(),                           isLive:false, hasChannels:true),
  Match(id:'4', league:'الدوري الألماني',     home:'بايرن ميونيخ',        homeEn:'Bayern',      homeLogo:'bayern.png',       away:'دورتموند',         awayEn:'Dortmund',   awayLogo:'dortmund.png',  score:'',      time:'20:30', date: DateTime.now().add(const Duration(days:1)), isLive:false, hasChannels:false),
  Match(id:'5', league:'الدوري الفرنسي',     home:'باريس سان جيرمان',    homeEn:'PSG',         homeLogo:'psg.png',          away:'مارسيليا',         awayEn:'Marseille',  awayLogo:'marseille.png', score:'',      time:'21:45', date: DateTime.now().add(const Duration(days:1)), isLive:false, hasChannels:false),
  Match(id:'6', league:'دوري أبطال أوروبا',  home:'يوفنتوس',             homeEn:'Juventus',    homeLogo:'juve.png',         away:'إنتر ميلان',      awayEn:'Inter',      awayLogo:'inter.png',     score:'',      time:'22:00', date: DateTime.now().add(const Duration(days:2)), isLive:false, hasChannels:false),
];

// ═══════════════════════════════════════════════════════════════
// PERSISTENCE
// ═══════════════════════════════════════════════════════════════
class Prefs {
  static const _fk = 'favs_v3';
  static const _sk = 'settings_v2';

  static Future<Set<int>> loadFavs() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_fk) ?? []).map((e) => int.tryParse(e) ?? -1).toSet();
  }
  static Future<bool> toggleFav(int id) async {
    final p = await SharedPreferences.getInstance();
    final set = await loadFavs();
    set.contains(id) ? set.remove(id) : set.add(id);
    await p.setStringList(_fk, set.map((e) => '$e').toList());
    return set.contains(id);
  }
  static Future<Map<String, dynamic>> loadSettings() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_sk);
    if (raw == null) return {'autoPlay': true, 'showScores': true, 'quality': 'auto'};
    try { return jsonDecode(raw) as Map<String, dynamic>; } catch (_) { return {'autoPlay': true, 'showScores': true, 'quality': 'auto'}; }
  }
  static Future<void> saveSettings(Map<String, dynamic> s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_sk, jsonEncode(s));
  }
}

// ═══════════════════════════════════════════════════════════════
// APP ROOT
// ═══════════════════════════════════════════════════════════════
class StreamGoApp extends StatelessWidget {
  const StreamGoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'StreamGo',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: T.void_,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(primary: T.accent, surface: T.s1),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      }),
    ),
    builder: (ctx, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    home: const RootShell(),
  );
}

// ═══════════════════════════════════════════════════════════════
// ROOT SHELL
// ═══════════════════════════════════════════════════════════════
class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with TickerProviderStateMixin {
  int _tab = 0;
  Set<int> _favIds = {};
  Map<String, dynamic> _settings = {'autoPlay': true, 'showScores': true, 'quality': 'auto'};
  List<AppCategory> _categories = [];
  List<Match> _matches = [];
  bool _catsLoading = true, _matchesLoading = true;
  late AnimationController _tabBarSlide;
  OverlayEntry? _toast;

  @override
  void initState() {
    super.initState();
    _tabBarSlide = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _init();
  }

  @override
  void dispose() { _tabBarSlide.dispose(); super.dispose(); }

  Future<void> _init() async {
    await Future.wait([_loadFavs(), _loadSettings(), _loadChannels(), _loadMatches()]);
  }

  Future<void> _loadFavs() async {
    final f = await Prefs.loadFavs();
    if (mounted) setState(() => _favIds = f);
  }

  Future<void> _loadSettings() async {
    final s = await Prefs.loadSettings();
    if (mounted) setState(() => _settings = s);
  }

  Future<void> _loadChannels() async {
    if (mounted) setState(() => _catsLoading = true);
    try {
      final r = await http.get(Uri.parse('https://raw.githubusercontent.com/illyassvvv/G/refs/heads/main/channels.json')).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final cats = (body['categories'] as List).map((c) => AppCategory.fromJson(c)).toList();
        if (mounted) setState(() { _categories = cats; _catsLoading = false; });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() { _categories = _mock; _catsLoading = false; });
  }

  Future<void> _loadMatches() async {
    if (mounted) setState(() => _matchesLoading = true);
    final now = DateTime.now();
    final ds = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
    try {
      final r = await http.get(Uri.parse('https://ws.kora-api.space/api/matches/$ds/1')).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final list = ((body['matches'] as List?) ?? []).map((m) => Match.fromJson(m)).toList();
        if (mounted) setState(() { _matches = list; _matchesLoading = false; });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() { _matches = _mockMatches; _matchesLoading = false; });
  }

  Future<void> _refresh() async { await Future.wait([_loadChannels(), _loadMatches()]); }

  Future<void> _toggleFav(int id) async {
    HapticFeedback.lightImpact();
    final is_ = await Prefs.toggleFav(id);
    if (mounted) {
      setState(() => is_ ? _favIds.add(id) : _favIds.remove(id));
      _showToast(is_ ? '❤️  أُضيفت للمفضلة' : 'تمت الإزالة من المفضلة');
    }
  }

  void _showToast(String msg) {
    _toast?.remove(); _toast = null;
    final e = OverlayEntry(builder: (_) => _Toast(message: msg, onDone: () { _toast?.remove(); _toast = null; }));
    _toast = e;
    Overlay.of(context).insert(e);
  }

  void _openPlayer(Channel ch) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(_zoomFade(PlayerScreen(
      channel: ch,
      isFavorite: _favIds.contains(ch.id),
      autoPlay: _settings['autoPlay'] as bool? ?? true,
      onToggleFav: () => _toggleFav(ch.id),
    )));
  }

  List<Channel> get _all  => _categories.expand((c) => c.channels).toList();
  List<Channel> get _favs => _all.where((c) => _favIds.contains(c.id)).toList();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: T.void_,
    body: Stack(children: [
      // Pages
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
        child: KeyedSubtree(
          key: ValueKey(_tab),
          child: [
            _HomeTab(categories: _categories, matches: _matches, favIds: _favIds, catsLoading: _catsLoading, matchesLoading: _matchesLoading, onToggleFav: _toggleFav, onOpenPlayer: _openPlayer, onGoMatches: () => setState(() => _tab = 3), onRefresh: _refresh),
            _ChannelsTab(categories: _categories, favIds: _favIds, loading: _catsLoading, onToggleFav: _toggleFav, onOpenPlayer: _openPlayer, onRefresh: _loadChannels),
            _FavoritesTab(channels: _favs, onToggleFav: _toggleFav, onOpenPlayer: _openPlayer),
            _MatchesTab(matches: _matches, loading: _matchesLoading, showScores: _settings['showScores'] as bool? ?? true, onRefresh: _loadMatches),
            _SettingsTab(settings: _settings, onChanged: (s) async { setState(() => _settings = s); await Prefs.saveSettings(s); }),
          ][_tab],
        ),
      ),
      // Tab Bar
      Positioned(
        bottom: 0, left: 0, right: 0,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: _tabBarSlide, curve: Curves.easeOutCubic)),
          child: _TabBar(selected: _tab, onTap: (i) { HapticFeedback.selectionClick(); setState(() => _tab = i); }),
        ),
      ),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════
// TAB BAR
// ═══════════════════════════════════════════════════════════════
class _TabBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _TabBar({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.76),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 50,
            child: Row(children: [
              _item(0, CupertinoIcons.house_fill,      CupertinoIcons.house,      'الرئيسية'),
              _item(1, CupertinoIcons.tv_fill,         CupertinoIcons.tv,         'القنوات'),
              _item(2, CupertinoIcons.heart_fill,      CupertinoIcons.heart,      'المفضلة'),
              _item(3, CupertinoIcons.sportscourt_fill,CupertinoIcons.sportscourt,'المباريات'),
              _item(4, CupertinoIcons.gear_alt_fill,   CupertinoIcons.gear_alt,   'الإعدادات'),
            ]),
          ),
        ),
      ),
    ),
  );

  Widget _item(int i, IconData on, IconData off, String label) {
    final active = selected == i;
    return Expanded(
      child: _Tap(
        onTap: () => onTap(i),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
            child: Icon(active ? on : off, key: ValueKey(active), size: 22, color: active ? T.accent : T.lbl3),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? T.accent : T.lbl3, letterSpacing: -0.1)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HOME TAB
// ═══════════════════════════════════════════════════════════════
class _HomeTab extends StatelessWidget {
  final List<AppCategory> categories;
  final List<Match> matches;
  final Set<int> favIds;
  final bool catsLoading, matchesLoading;
  final Function(int) onToggleFav;
  final Function(Channel) onOpenPlayer;
  final VoidCallback onGoMatches;
  final Future<void> Function() onRefresh;

  const _HomeTab({
    required this.categories, required this.matches, required this.favIds,
    required this.catsLoading, required this.matchesLoading,
    required this.onToggleFav, required this.onOpenPlayer,
    required this.onGoMatches, required this.onRefresh,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'صباح الخير ☀️';
    if (h < 18) return 'مساء الخير 🌤️';
    return 'مساء النور 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return RefreshIndicator(
      color: T.accent, backgroundColor: T.s3,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: top + T.p16)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(T.p20, 0, T.p20, T.p24),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_greeting(), style: T.caption.copyWith(color: T.lbl2)),
                  const SizedBox(height: 2),
                  Text('StreamGo', style: T.display),
                ]),
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [T.accent, Color(0xFF30A2FF)])),
                  child: const Icon(CupertinoIcons.person_fill, size: 20, color: Colors.white),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(T.p16, 0, T.p16, T.p32),
              child: _HeroCard(matches: matches, onGoMatches: onGoMatches),
            ),
          ),
          if (catsLoading)
            const SliverToBoxAdapter(child: _Shimmer())
          else
            ...categories.map((cat) => SliverToBoxAdapter(child: _CatRow(
              category: cat, favIds: favIds,
              onToggleFav: onToggleFav, onOpenPlayer: onOpenPlayer,
            ))),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HERO CARD
// ═══════════════════════════════════════════════════════════════
class _HeroCard extends StatefulWidget {
  final List<Match> matches;
  final VoidCallback onGoMatches;
  const _HeroCard({required this.matches, required this.onGoMatches});
  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> with SingleTickerProviderStateMixin {
  late AnimationController _glow;
  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
  }
  @override
  void dispose() { _glow.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final live = widget.matches.where((m) => m.isLive).toList();
    final featured = live.isNotEmpty ? live.first : (widget.matches.isNotEmpty ? widget.matches.first : null);

    return _Tap(
      onTap: widget.onGoMatches,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (_, child) => Container(
          height: 188,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(T.r24),
            gradient: LinearGradient(
              begin: Alignment.topRight, end: Alignment.bottomLeft,
              colors: [
                const Color(0xFF0D2847),
                Color.lerp(const Color(0xFF0A1E35), const Color(0xFF0D2040), _glow.value)!,
                const Color(0xFF040A14),
              ],
            ),
            boxShadow: [BoxShadow(color: T.accent.withValues(alpha: 0.10 + 0.08 * _glow.value), blurRadius: 28, offset: const Offset(0, 8))],
          ),
          child: child,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(T.r24),
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(T.r24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.5),
            ))),
            Padding(
              padding: const EdgeInsets.all(T.p20),
              child: featured != null ? _liveContent(featured) : _defaultContent(),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _liveContent(Match m) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      if (m.isLive) ...[_PulseDot(), const SizedBox(width: T.p6)],
      _Pill(label: m.isLive ? 'مباشر الآن' : 'قادم', color: m.isLive ? T.red : T.accent),
      const SizedBox(width: T.p8),
      Expanded(child: Text(m.league, style: T.caption.copyWith(color: T.lbl2), maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]),
    const Spacer(),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _MiniTeam(name: m.home, logoUrl: m.homeLogoUrl),
      Expanded(child: Column(children: [
        Text(m.isLive ? m.score : m.time,
          style: m.isLive ? T.title1.copyWith(letterSpacing: 4, fontSize: 30) : T.title3.copyWith(color: T.lbl2),
          textAlign: TextAlign.center),
        const SizedBox(height: T.p4),
        Text('vs', style: T.micro.copyWith(color: T.lbl3)),
      ])),
      _MiniTeam(name: m.away, logoUrl: m.awayLogoUrl),
    ]),
    const Spacer(),
  ]);

  Widget _defaultContent() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [_PulseDot(), const SizedBox(width: T.p6), _Pill(label: 'بث مباشر', color: T.red)]),
    const Spacer(),
    Text('مباريات اليوم', style: T.title2),
    const SizedBox(height: T.p4),
    Text('اضغط لعرض جميع المباريات', style: T.caption),
    const Spacer(),
  ]);
}

class _MiniTeam extends StatelessWidget {
  final String name, logoUrl;
  const _MiniTeam({required this.name, required this.logoUrl});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 78,
    child: Column(children: [
      _NetImg(url: logoUrl, w: 42, h: 42, radius: T.rFull),
      const SizedBox(height: T.p6),
      Text(name, style: T.caption.copyWith(fontWeight: FontWeight.w500, color: T.lbl), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY ROW (HORIZONTAL SCROLL)
// ═══════════════════════════════════════════════════════════════
class _CatRow extends StatelessWidget {
  final AppCategory category;
  final Set<int> favIds;
  final Function(int) onToggleFav;
  final Function(Channel) onOpenPlayer;
  const _CatRow({required this.category, required this.favIds, required this.onToggleFav, required this.onOpenPlayer});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: T.p28),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(T.p20, 0, T.p20, T.p12),
        child: Row(children: [
          Icon(category.icon, size: 15, color: T.accent),
          const SizedBox(width: T.p8),
          Text(category.name, style: T.title3),
          const Spacer(),
          Text('${category.channels.length} قناة', style: T.caption.copyWith(color: T.lbl2)),
        ]),
      ),
      SizedBox(
        height: 153,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: T.p16),
          itemCount: category.channels.length,
          itemBuilder: (_, i) {
            final ch = category.channels[i];
            return _ChannelCard(channel: ch, isFav: favIds.contains(ch.id), onToggleFav: () => onToggleFav(ch.id), onTap: () => onOpenPlayer(ch));
          },
        ),
      ),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════
// CHANNEL CARD (GRID)
// ═══════════════════════════════════════════════════════════════
class _ChannelCard extends StatelessWidget {
  final Channel channel;
  final bool isFav;
  final VoidCallback onToggleFav, onTap;
  const _ChannelCard({required this.channel, required this.isFav, required this.onToggleFav, required this.onTap});

  @override
  Widget build(BuildContext context) => _Tap(
    onTap: onTap,
    child: Container(
      width: 106,
      margin: const EdgeInsets.symmetric(horizontal: T.p6),
      child: Column(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: T.s3,
              borderRadius: BorderRadius.circular(T.r20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Stack(children: [
              Padding(padding: const EdgeInsets.all(T.p16), child: Center(child: _NetImg(url: channel.logo, w: 54, h: 54))),
              Positioned(
                top: T.p6, left: T.p6,
                child: _Tap(
                  onTap: onToggleFav,
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                      child: Icon(isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart, key: ValueKey(isFav), size: 13, color: isFav ? T.red : T.lbl3),
                    ),
                  ),
                ),
              ),
              if (channel.number.isNotEmpty)
                Positioned(
                  top: T.p6, right: T.p6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(T.r4)),
                    child: Text(channel.number, style: T.micro.copyWith(color: T.accent, fontSize: 9)),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(height: T.p8),
        Text(channel.name, style: T.caption.copyWith(fontWeight: FontWeight.w500, color: T.lbl), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// CHANNELS TAB
// ═══════════════════════════════════════════════════════════════
class _ChannelsTab extends StatefulWidget {
  final List<AppCategory> categories;
  final Set<int> favIds;
  final bool loading;
  final Function(int) onToggleFav;
  final Function(Channel) onOpenPlayer;
  final Future<void> Function() onRefresh;
  const _ChannelsTab({required this.categories, required this.favIds, required this.loading, required this.onToggleFav, required this.onOpenPlayer, required this.onRefresh});
  @override
  State<_ChannelsTab> createState() => _ChannelsTabState();
}

class _ChannelsTabState extends State<_ChannelsTab> {
  String _q = '';
  String? _cat;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    List<Channel> all = widget.categories.expand((c) => c.channels).toList();
    if (_cat != null) {
      final catChannels = widget.categories.where((c) => c.name == _cat).expand((c) => c.channels).toList();
      all = catChannels;
    }
    final filtered = _q.isEmpty ? all : all.where((ch) => ch.name.contains(_q) || ch.number.contains(_q)).toList();

    return RefreshIndicator(
      color: T.accent, backgroundColor: T.s3,
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: top + T.p16)),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(T.p20, 0, T.p20, T.p20), child: Text('القنوات', style: T.display))),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(T.p16, 0, T.p16, T.p16), child: _SearchBar(onChanged: (v) => setState(() => _q = v)))),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: T.p16),
                children: [
                  _FilterPill(label: 'الكل', active: _cat == null, onTap: () => setState(() => _cat = null)),
                  ...widget.categories.map((c) => _FilterPill(label: c.name, active: _cat == c.name, onTap: () => setState(() => _cat = _cat == c.name ? null : c.name))),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: T.p16)),
          if (widget.loading)
            const SliverToBoxAdapter(child: _Shimmer())
          else if (filtered.isEmpty)
            SliverToBoxAdapter(child: _EmptyState(icon: CupertinoIcons.tv, text: 'لا توجد قنوات'))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _ChRow(channel: filtered[i], isFav: widget.favIds.contains(filtered[i].id), isFirst: i == 0, isLast: i == filtered.length - 1, onToggleFav: () => widget.onToggleFav(filtered[i].id), onTap: () => widget.onOpenPlayer(filtered[i])),
                childCount: filtered.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterPill({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => _Tap(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 240), curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(left: T.p8),
      padding: const EdgeInsets.symmetric(horizontal: T.p16, vertical: T.p6),
      decoration: BoxDecoration(
        color: active ? T.accent : T.s3,
        borderRadius: BorderRadius.circular(T.rFull),
        border: active ? null : Border.all(color: T.sep, width: 0.5),
      ),
      child: Text(label, style: T.callout.copyWith(color: active ? Colors.white : T.lbl2, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
    ),
  );
}

// Channel Row (List)
class _ChRow extends StatelessWidget {
  final Channel channel;
  final bool isFav, isFirst, isLast;
  final VoidCallback onToggleFav, onTap;
  const _ChRow({required this.channel, required this.isFav, required this.isFirst, required this.isLast, required this.onToggleFav, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: T.p16),
    child: _Tap(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : 1),
        decoration: BoxDecoration(
          color: T.s2,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(T.r16) : Radius.zero,
            bottom: isLast ? const Radius.circular(T.r16) : Radius.zero,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: T.p16, vertical: T.p12),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: T.s4, borderRadius: BorderRadius.circular(T.r8)),
              child: ClipRRect(borderRadius: BorderRadius.circular(T.r8), child: _NetImg(url: channel.logo, w: 46, h: 46)),
            ),
            const SizedBox(width: T.p12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(channel.name, style: T.callout.copyWith(fontWeight: FontWeight.w500, color: T.lbl), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('قناة ${channel.number}', style: T.caption.copyWith(fontSize: 11)),
            ])),
            _Tap(
              onTap: onToggleFav,
              child: Padding(
                padding: const EdgeInsets.all(T.p8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: Icon(isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart, key: ValueKey(isFav), color: isFav ? T.red : T.lbl3, size: 20),
                ),
              ),
            ),
            const Icon(CupertinoIcons.chevron_forward, size: 12, color: T.lbl3),
          ]),
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// FAVORITES TAB
// ═══════════════════════════════════════════════════════════════
class _FavoritesTab extends StatelessWidget {
  final List<Channel> channels;
  final Function(int) onToggleFav;
  final Function(Channel) onOpenPlayer;
  const _FavoritesTab({required this.channels, required this.onToggleFav, required this.onOpenPlayer});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: top + T.p16)),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(T.p20, 0, T.p20, T.p24),
          child: Row(children: [
            Text('المفضلة', style: T.display),
            if (channels.isNotEmpty) ...[const SizedBox(width: T.p12), _Pill(label: '${channels.length}', color: T.red)],
          ]),
        )),
        if (channels.isEmpty)
          SliverFillRemaining(child: _EmptyState(icon: CupertinoIcons.heart, text: 'لا توجد قنوات مفضلة\nاضغط ❤ لإضافة قناة'))
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _ChRow(channel: channels[i], isFav: true, isFirst: i == 0, isLast: i == channels.length - 1, onToggleFav: () => onToggleFav(channels[i].id), onTap: () => onOpenPlayer(channels[i])),
              childCount: channels.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MATCHES TAB
// ═══════════════════════════════════════════════════════════════
class _MatchesTab extends StatelessWidget {
  final List<Match> matches;
  final bool loading;
  final bool showScores;
  final Future<void> Function() onRefresh;
  const _MatchesTab({required this.matches, required this.loading, required this.showScores, required this.onRefresh});

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final now = DateTime.now();
    final today = _fmt(now);
    final tomorrow = _fmt(now.add(const Duration(days: 1)));

    final grouped = <String, List<Match>>{};
    for (final m in matches) {
      final d = _fmt(m.date);
      String key = d == today ? 'اليوم' : d == tomorrow ? 'غداً' : d;
      grouped.putIfAbsent(key, () => []).add(m);
    }

    return RefreshIndicator(
      color: T.accent, backgroundColor: T.s3,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: top + T.p16)),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(T.p20, 0, T.p20, T.p24), child: Text('المباريات', style: T.display))),
          if (loading)
            const SliverToBoxAdapter(child: _Shimmer())
          else if (matches.isEmpty)
            SliverFillRemaining(child: _EmptyState(icon: CupertinoIcons.sportscourt, text: 'لا توجد مباريات اليوم'))
          else
            ...grouped.entries.map((e) => SliverToBoxAdapter(child: _MatchGroup(label: e.key, matches: e.value, showScores: showScores))),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }
}

class _MatchGroup extends StatelessWidget {
  final String label;
  final List<Match> matches;
  final bool showScores;
  const _MatchGroup({required this.label, required this.matches, required this.showScores});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(T.p16, 0, T.p16, T.p24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(right: T.p4, bottom: T.p10),
        child: Row(children: [
          if (label == 'اليوم') ...[_PulseDot(), const SizedBox(width: T.p6)],
          Text(label, style: T.headline.copyWith(color: label == 'اليوم' ? T.red : T.lbl2)),
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
      padding: const EdgeInsets.symmetric(horizontal: T.p16, vertical: T.p14),
      child: Row(children: [
        Expanded(child: Column(children: [
          _NetImg(url: match.homeLogoUrl, w: 38, h: 38, radius: T.rFull),
          const SizedBox(height: T.p6),
          Text(match.home, style: T.caption.copyWith(fontWeight: FontWeight.w500, color: T.lbl), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: T.p10),
          child: Column(children: [
            if (match.isLive) ...[
              Row(mainAxisSize: MainAxisSize.min, children: [_PulseDot(), const SizedBox(width: T.p4), _Pill(label: 'مباشر', color: T.red)]),
              const SizedBox(height: T.p6),
              if (showScore) Text(match.score, style: T.title2.copyWith(letterSpacing: 3)),
            ] else
              Text(match.time, style: T.headline.copyWith(color: T.lbl2, fontWeight: FontWeight.w700)),
          ]),
        ),
        Expanded(child: Column(children: [
          _NetImg(url: match.awayLogoUrl, w: 38, h: 38, radius: T.rFull),
          const SizedBox(height: T.p6),
          Text(match.away, style: T.caption.copyWith(fontWeight: FontWeight.w500, color: T.lbl), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    ),
    if (!isLast) Container(height: 0.5, color: T.sep.withValues(alpha: 0.5), margin: const EdgeInsets.only(right: T.p16)),
  ]);
}

// ═══════════════════════════════════════════════════════════════
// SETTINGS TAB
// ═══════════════════════════════════════════════════════════════
class _SettingsTab extends StatelessWidget {
  final Map<String, dynamic> settings;
  final ValueChanged<Map<String, dynamic>> onChanged;
  const _SettingsTab({required this.settings, required this.onChanged});

  void _update(String key, dynamic val) => onChanged(Map<String, dynamic>.from(settings)..[key] = val);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: top + T.p16)),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(T.p20, 0, T.p20, T.p32), child: Text('الإعدادات', style: T.display))),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: T.p16),
          child: Column(children: [
            _SecLabel('التشغيل'),
            _GlassCard(children: [
              _TogRow(icon: CupertinoIcons.play_circle_fill, bg: T.red,   title: 'تشغيل تلقائي',      sub: 'تشغيل البث فور اختيار القناة',          val: settings['autoPlay']  as bool? ?? true,  onChange: (v) => _update('autoPlay', v)),
              _TogRow(icon: CupertinoIcons.sportscourt_fill, bg: T.green, title: 'نتائج المباريات',    sub: 'إظهار النتيجة على بطاقة المباراة',        val: settings['showScores'] as bool? ?? true,  onChange: (v) => _update('showScores', v)),
            ]),
            const SizedBox(height: T.p28),
            _SecLabel('جودة البث'),
            _GlassCard(children: [
              for (final q in [('auto','تلقائي'), ('hd','عالي HD'), ('sd','عادي SD')])
                _QRow(label: q.$2, active: (settings['quality'] as String? ?? 'auto') == q.$1, onTap: () => _update('quality', q.$1)),
            ]),
            const SizedBox(height: T.p28),
            _SecLabel('حول التطبيق'),
            _GlassCard(children: [
              _IRow(label: 'التطبيق', value: 'StreamGo'),
              _IRow(label: 'الإصدار', value: '2.0.0'),
              _IRow(label: 'المطوّر', value: 'StreamGo Team', isLast: true),
            ]),
          ]),
        )),
        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
    );
  }
}

class _SecLabel extends StatelessWidget {
  final String text;
  const _SecLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: T.p4, bottom: T.p8),
    child: Text(text.toUpperCase(), style: T.micro.copyWith(color: T.lbl3, letterSpacing: 0.8)),
  );
}

class _TogRow extends StatelessWidget {
  final IconData icon; final Color bg; final String title, sub; final bool val; final ValueChanged<bool> onChange;
  const _TogRow({required this.icon, required this.bg, required this.title, required this.sub, required this.val, required this.onChange});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: T.p16, vertical: T.p12),
    child: Row(children: [
      Container(width: 30, height: 30, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(T.r8)), child: Icon(icon, color: Colors.white, size: 16)),
      const SizedBox(width: T.p12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: T.callout.copyWith(fontWeight: FontWeight.w500, color: T.lbl)),
        Text(sub, style: T.caption.copyWith(fontSize: 11)),
      ])),
      CupertinoSwitch(value: val, onChanged: onChange, activeColor: T.accent),
    ]),
  );
}

class _QRow extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  const _QRow({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => _Tap(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: T.p16, vertical: T.p14),
      child: Row(children: [
        Expanded(child: Text(label, style: T.callout.copyWith(fontWeight: FontWeight.w500))),
        if (active) const Icon(CupertinoIcons.checkmark, color: T.accent, size: 18),
      ]),
    ),
  );
}

class _IRow extends StatelessWidget {
  final String label, value; final bool isLast;
  const _IRow({required this.label, required this.value, this.isLast = false});
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: T.p16, vertical: T.p14),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: T.callout.copyWith(fontWeight: FontWeight.w500)),
        Text(value, style: T.callout.copyWith(color: T.lbl2)),
      ]),
    ),
    if (!isLast) Container(height: 0.5, color: T.sep.withValues(alpha: 0.5), margin: const EdgeInsets.only(right: T.p16)),
  ]);
}

// ═══════════════════════════════════════════════════════════════
// PLAYER SCREEN  —  Premium iOS-grade overhaul
// Architecture: Scaffold → Stack (fills screen)
//   Layer 0 : black background
//   Layer 1 : centered AspectRatio video
//   Layer 2 : gradient scrims (top + bottom)
//   Layer 3 : animated controls (SafeArea, glass, gradients)
//   Layer 4 : portrait info panel pinned to bottom
// ═══════════════════════════════════════════════════════════════
class PlayerScreen extends StatefulWidget {
  final Channel channel;
  final bool isFavorite, autoPlay;
  final VoidCallback onToggleFav;
  const PlayerScreen({
    super.key,
    required this.channel,
    required this.isFavorite,
    required this.autoPlay,
    required this.onToggleFav,
  });
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _vpc;
  ChewieController?      _cc;
  bool _loading = true, _error = false, _isFav = false, _ctrlsVisible = true;

  // Controls fade+scale
  late AnimationController _ctrlsAnim;
  late Animation<double>   _ctrlsOpa, _ctrlsScl;

  // Favourite spring
  late AnimationController _favAnim;
  late Animation<double>   _favScl;

  // Progress ticker (drives the thin scrubber while playing)
  late AnimationController _progressTicker;

  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/139.0.0.0 Safari/537.36';

  // ── lifecycle ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _isFav = widget.isFavorite;

    _ctrlsAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _ctrlsOpa = CurvedAnimation(parent: _ctrlsAnim, curve: Curves.easeOut);
    _ctrlsScl = Tween(begin: 0.96, end: 1.0).animate(
        CurvedAnimation(parent: _ctrlsAnim, curve: Curves.easeOutCubic));
    _ctrlsAnim.forward();

    _favAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _favScl = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.5)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 35),
      TweenSequenceItem(
          tween: Tween(begin: 1.5, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 65),
    ]).animate(_favAnim);

    _progressTicker = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat();

    _initPlayer();
    _scheduleHide();
  }

  @override
  void dispose() {
    _ctrlsAnim.dispose();
    _favAnim.dispose();
    _progressTicker.dispose();
    _cc?.dispose();
    _vpc?.dispose();
    super.dispose();
  }

  // ── controls visibility ────────────────────────────────────
  void _scheduleHide() => Future.delayed(const Duration(seconds: 4), () {
        if (mounted && _ctrlsVisible) {
          setState(() => _ctrlsVisible = false);
          _ctrlsAnim.reverse();
        }
      });

  void _tapScreen() {
    HapticFeedback.selectionClick();
    final nowVisible = !_ctrlsVisible;
    setState(() => _ctrlsVisible = nowVisible);
    nowVisible ? _ctrlsAnim.forward() : _ctrlsAnim.reverse();
    if (nowVisible) _scheduleHide();
  }

  // ── stream init ────────────────────────────────────────────
  Future<void> _initPlayer() async {
    if (widget.channel.streamUrl.isEmpty) {
      setState(() { _loading = false; _error = true; });
      return;
    }
    setState(() { _loading = true; _error = false; });
    try {
      final headers = {
        'User-Agent': _ua,
        'Referer': 'https://streamgo.tv/',
        'Origin': 'https://streamgo.tv',
      };
      _vpc = VideoPlayerController.networkUrl(
          Uri.parse(widget.channel.streamUrl),
          httpHeaders: headers);
      await _vpc!.initialize();
      _cc = ChewieController(
        videoPlayerController: _vpc!,
        autoPlay: widget.autoPlay,
        looping: true,
        allowFullScreen: true,
        allowMuting: true,
        // We supply our own overlay; tell Chewie NOT to draw its controls
        // so we avoid the double-controls issue.
        showControls: false,
        placeholder: const Center(
            child: CupertinoActivityIndicator(
                radius: 16, color: Colors.white)),
        errorBuilder: (_, __) => _PError(onRetry: _retry),
      );
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  void _retry() {
    _cc?.dispose();
    _vpc?.dispose();
    _cc = null;
    _vpc = null;
    _initPlayer();
  }

  void _tapFav() {
    widget.onToggleFav();
    HapticFeedback.mediumImpact();
    setState(() => _isFav = !_isFav);
    _favAnim.forward(from: 0);
  }

  // ── helpers ────────────────────────────────────────────────
  Duration get _position  => _vpc?.value.position  ?? Duration.zero;
  Duration get _duration  => _vpc?.value.duration  ?? Duration.zero;
  bool     get _isPlaying => _vpc?.value.isPlaying ?? false;

  double get _progress {
    final dur = _duration.inMilliseconds;
    if (dur == 0) return 0;
    return (_position.inMilliseconds / dur).clamp(0.0, 1.0);
  }

  String _fmtDuration(Duration d) {
    final h  = d.inHours;
    final m  = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s  = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  // ── build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq     = MediaQuery.of(context);
    final isLand = mq.orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      // Force status-bar icons white over the black player
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
          onTap: _tapScreen,
          behavior: HitTestBehavior.opaque,
          child: isLand ? _buildLandscape() : _buildPortrait(),
        ),
      ),
    );
  }

  // ── PORTRAIT layout ────────────────────────────────────────
  Widget _buildPortrait() => Column(
    children: [
      // ── video zone (16:9 + full controls stack on top) ──
      AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildVideoStack(isLand: false),
      ),
      // ── info panel below video ──
      Expanded(child: _buildInfoPanel()),
    ],
  );

  // ── LANDSCAPE layout ───────────────────────────────────────
  Widget _buildLandscape() => Stack(
    fit: StackFit.expand,
    children: [
      _buildVideoStack(isLand: true),
    ],
  );

  // ── VIDEO STACK (the centrepiece) ──────────────────────────
  // Root is a Stack.  Video is centered in AspectRatio.
  // Gradient scrims + glass controls float above it.
  Widget _buildVideoStack({required bool isLand}) => Stack(
    fit: StackFit.expand,
    children: [
      // ── 0: pure black canvas ──────────────────────────────
      const ColoredBox(color: Colors.black),

      // ── 1: video, perfectly centered ─────────────────────
      Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _buildVideoContent(),
        ),
      ),

      // ── 2a: top scrim (protects controls from bright video)
      Positioned(
        top: 0, left: 0, right: 0,
        child: _GradientScrim(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          height: 140,
        ),
      ),

      // ── 2b: bottom scrim ──────────────────────────────────
      Positioned(
        bottom: 0, left: 0, right: 0,
        child: _GradientScrim(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          height: 140,
        ),
      ),

      // ── 3: animated controls overlay ─────────────────────
      FadeTransition(
        opacity: _ctrlsOpa,
        child: ScaleTransition(
          scale: _ctrlsScl,
          child: SafeArea(
            child: Stack(
              children: [
                // Top bar: back + title + fav
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: _buildTopBar(),
                ),
                // Centre play/pause
                Center(child: _buildCentrePlayPause()),
                // Bottom bar: progress + time
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: _buildBottomBar(),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  // ── video content (loading / error / player) ───────────────
  Widget _buildVideoContent() {
    if (_loading) {
      return const Center(
          child: CupertinoActivityIndicator(radius: 18, color: Colors.white));
    }
    if (_error) return _PError(onRetry: _retry);
    if (_cc != null) return Chewie(controller: _cc!);
    return const Center(
        child: CupertinoActivityIndicator(radius: 18, color: Colors.white));
  }

  // ── TOP BAR ───────────────────────────────────────────────
  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: T.p16, vertical: T.p12),
    child: Row(
      children: [
        // Back button — always on the LEFT (leading side in LTR,
        // but since the app is RTL we use Directionality.ltr locally)
        Directionality(
          textDirection: TextDirection.ltr,
          child: _PlayerBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: T.p12),
        // Channel info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.channel.name,
                style: T.headline.copyWith(
                    color: Colors.white,
                    shadows: [const Shadow(blurRadius: 8)]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(children: [
                _PulseDot(),
                const SizedBox(width: T.p4),
                Text('بث مباشر',
                    style: T.caption
                        .copyWith(color: Colors.white70)),
              ]),
            ],
          ),
        ),
        // Favourite button
        ScaleTransition(
          scale: _favScl,
          child: _PlayerBtn(
            icon: _isFav
                ? CupertinoIcons.heart_fill
                : CupertinoIcons.heart,
            iconColor: _isFav ? T.red : Colors.white,
            onTap: _tapFav,
          ),
        ),
      ],
    ),
  );

  // ── CENTRE PLAY/PAUSE ─────────────────────────────────────
  Widget _buildCentrePlayPause() {
    if (_loading || _error) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _progressTicker,
      builder: (_, __) {
        final playing = _isPlaying;
        return _PlayerBtn(
          size: 56,
          iconSize: 28,
          icon: playing
              ? CupertinoIcons.pause_fill
              : CupertinoIcons.play_fill,
          onTap: () {
            HapticFeedback.lightImpact();
            playing ? _vpc!.pause() : _vpc!.play();
            setState(() {});
            _scheduleHide();
          },
        );
      },
    );
  }

  // ── BOTTOM BAR: progress + time ────────────────────────────
  Widget _buildBottomBar() => Padding(
    padding: const EdgeInsets.fromLTRB(T.p16, 0, T.p16, T.p16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ultra-thin progress bar with glow
        AnimatedBuilder(
          animation: _progressTicker,
          builder: (_, __) => _ThinProgressBar(progress: _progress),
        ),
        const SizedBox(height: T.p8),
        // Time labels
        AnimatedBuilder(
          animation: _progressTicker,
          builder: (_, __) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmtDuration(_position),
                style: T.micro.copyWith(
                    color: Colors.white70, fontWeight: FontWeight.w500),
              ),
              Text(
                _fmtDuration(_duration),
                style: T.micro.copyWith(color: Colors.white38),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // ── INFO PANEL (portrait only, below video) ────────────────
  Widget _buildInfoPanel() => Container(
    color: T.void_,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(T.p20, T.p20, T.p20, T.p20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Channel logo + name row
            Row(children: [
              // Logo with glass border
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: T.s3,
                  borderRadius: BorderRadius.circular(T.r16),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 0.5),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(T.r16),
                  child: _NetImg(
                      url: widget.channel.logo, w: 60, h: 60),
                ),
              ),
              const SizedBox(width: T.p16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.channel.name,
                        style: T.title3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: T.p6),
                    // Glass status pill
                    ClipRRect(
                      borderRadius: BorderRadius.circular(T.rFull),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                            sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: T.p10, vertical: T.p4),
                          decoration: BoxDecoration(
                            color: T.red.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(T.rFull),
                            border: Border.all(
                                color:
                                    T.red.withValues(alpha: 0.3),
                                width: 0.5),
                          ),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _PulseDot(),
                                const SizedBox(width: T.p6),
                                Text('بث مباشر',
                                    style: T.caption.copyWith(
                                        color: T.red,
                                        fontWeight:
                                            FontWeight.w600)),
                              ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: T.p12),
              // Favourite button
              _Tap(
                onTap: _tapFav,
                child: ScaleTransition(
                  scale: _favScl,
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(T.rFull),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                          sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: T.s3
                              .withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white
                                  .withValues(alpha: 0.08),
                              width: 0.5),
                        ),
                        child: AnimatedSwitcher(
                          duration:
                              const Duration(milliseconds: 250),
                          transitionBuilder: (c, a) =>
                              ScaleTransition(
                                  scale: a,
                                  child: FadeTransition(
                                      opacity: a, child: c)),
                          child: Icon(
                            _isFav
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            key: ValueKey(_isFav),
                            color: _isFav ? T.red : T.lbl2,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: T.p20),
            // Glass quality/channel info strip
            ClipRRect(
              borderRadius: BorderRadius.circular(T.r12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: T.p16, vertical: T.p12),
                  decoration: BoxDecoration(
                    color: T.s2.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(T.r12),
                    border: Border.all(
                        color:
                            Colors.white.withValues(alpha: 0.06),
                        width: 0.5),
                  ),
                  child: Row(children: [
                    _InfoChip(
                        icon: CupertinoIcons.tv,
                        label: 'قناة ${widget.channel.number}'),
                    const SizedBox(width: T.p16),
                    _InfoChip(
                        icon: CupertinoIcons.waveform,
                        label: 'HLS'),
                    const Spacer(),
                    // Retry button
                    _Tap(
                      onTap: _retry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: T.p12, vertical: T.p6),
                        decoration: BoxDecoration(
                          color: T.accent.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(T.rFull),
                          border: Border.all(
                              color: T.accent.withValues(alpha: 0.3),
                              width: 0.5),
                        ),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.refresh,
                                  size: 12, color: T.accent),
                              const SizedBox(width: T.p4),
                              Text('إعادة',
                                  style: T.micro.copyWith(
                                      color: T.accent,
                                      fontWeight: FontWeight.w600)),
                            ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Thin progress bar with glow ────────────────────────────────
class _ThinProgressBar extends StatelessWidget {
  final double progress;
  const _ThinProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final w = constraints.maxWidth;
      return GestureDetector(
        // Intentionally no-op: scrub handled by Chewie internally
        // This is purely a visual track element
        child: SizedBox(
          height: 20,
          child: Stack(alignment: Alignment.centerLeft, children: [
            // Track
            Container(
              height: 2.5,
              width: w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Fill
            Container(
              height: 2.5,
              width: w * progress,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A84FF), Color(0xFF30D158)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: T.accent.withValues(alpha: 0.55),
                    blurRadius: 6,
                    offset: Offset.zero,
                  ),
                ],
              ),
            ),
            // Thumb dot
            Positioned(
              left: (w * progress - 5).clamp(0.0, w - 10),
              child: Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: T.accent.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      );
    },
  );
}

// ── Gradient scrim ─────────────────────────────────────────────
class _GradientScrim extends StatelessWidget {
  final AlignmentGeometry begin, end;
  final double height;
  const _GradientScrim({
    required this.begin,
    required this.end,
    required this.height,
  });
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: begin,
        end: end,
        colors: [
          Colors.black.withValues(alpha: 0.72),
          Colors.black.withValues(alpha: 0.0),
        ],
      ),
    ),
  );
}

// ── Glass player button (Back / Play / Fav) ────────────────────
class _PlayerBtn extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  final double size, iconSize;
  const _PlayerBtn({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.size = 42,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) => _Tap(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(T.rFull),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 0.5),
          ),
          child: Icon(icon,
              color: iconColor ?? Colors.white, size: iconSize),
        ),
      ),
    ),
  );
}

// ── Small info chip inside info panel ─────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: T.lbl3),
      const SizedBox(width: T.p4),
      Text(label, style: T.caption.copyWith(fontSize: 11, color: T.lbl2)),
    ],
  );
}

// ── Error overlay ──────────────────────────────────────────────
class _PError extends StatelessWidget {
  final VoidCallback onRetry;
  const _PError({required this.onRetry});
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black,
    child: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.1), width: 0.5),
          ),
          child: const Icon(CupertinoIcons.wifi_slash,
              size: 32, color: Colors.white38),
        ),
        const SizedBox(height: T.p20),
        const Text('تعذّر الاتصال',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3)),
        const SizedBox(height: T.p8),
        const Text('حدث خطأ في البث',
            style: TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: T.p28),
        _Tap(
          onTap: onRetry,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(T.rFull),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: T.p28, vertical: T.p14),
                decoration: BoxDecoration(
                  color: T.accent.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(T.rFull),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 0.5),
                  boxShadow: [
                    BoxShadow(
                        color: T.accent.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: const Text('إعادة المحاولة',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
              ),
            ),
          ),
        ),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// SHARED MICRO-COMPONENTS
// ═══════════════════════════════════════════════════════════════
class _GlassCard extends StatelessWidget {
  final List<Widget> children;
  const _GlassCard({required this.children});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(T.r16),
    child: Container(
      decoration: BoxDecoration(
        color: T.s2,
        borderRadius: BorderRadius.circular(T.r16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
      ),
      child: Column(children: children),
    ),
  );
}

class _GBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => _Tap(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(T.rFull),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.24), width: 0.5)),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    ),
  );
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}
class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _a = Tween(begin: 0.35, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: T.red, shape: BoxShape.circle)),
  );
}

class _Pill extends StatelessWidget {
  final String label; final Color color;
  const _Pill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(T.rFull), border: Border.all(color: color.withValues(alpha: 0.28), width: 0.5)),
    child: Text(label, style: T.micro.copyWith(color: color, fontWeight: FontWeight.w700)),
  );
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: T.s3, borderRadius: BorderRadius.circular(T.r12)),
    child: TextField(
      onChanged: onChanged, textDirection: TextDirection.rtl,
      style: T.body.copyWith(color: T.lbl),
      decoration: InputDecoration(
        hintText: 'بحث...', hintStyle: T.body.copyWith(color: T.lbl3),
        prefixIcon: const Icon(CupertinoIcons.search, color: T.lbl3, size: 18),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: T.p16, vertical: T.p12),
      ),
    ),
  );
}

class _NetImg extends StatelessWidget {
  final String url;
  final double w, h;
  final double? radius;
  const _NetImg({required this.url, required this.w, required this.h, this.radius});
  @override
  Widget build(BuildContext context) {
    final widget_ = url.isNotEmpty
        ? Image.network(url, width: w, height: h, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _ph())
        : _ph();
    if (radius != null) return ClipRRect(borderRadius: BorderRadius.circular(radius!), child: SizedBox(width: w, height: h, child: widget_));
    return SizedBox(width: w, height: h, child: widget_);
  }
  Widget _ph() => Icon(CupertinoIcons.tv, color: T.lbl4, size: math.min(w, h) * 0.5);
}

class _EmptyState extends StatelessWidget {
  final IconData icon; final String text;
  const _EmptyState({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 76, height: 76, decoration: const BoxDecoration(color: T.s3, shape: BoxShape.circle), child: Icon(icon, size: 34, color: T.lbl3)),
    const SizedBox(height: T.p20),
    Text(text, style: T.body.copyWith(color: T.lbl2), textAlign: TextAlign.center),
  ]));
}

// Tap Scale
class _Tap extends StatefulWidget {
  final Widget child; final VoidCallback? onTap;
  const _Tap({required this.child, this.onTap});
  @override State<_Tap> createState() => _TapState();
}
class _TapState extends State<_Tap> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 115));
    _s = Tween(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _c.forward(),
    onTapUp: (_) { _c.reverse(); widget.onTap?.call(); },
    onTapCancel: () => _c.reverse(),
    child: ScaleTransition(scale: _s, child: widget.child),
  );
}

// Toast
class _Toast extends StatefulWidget {
  final String message; final VoidCallback onDone;
  const _Toast({required this.message, required this.onDone});
  @override State<_Toast> createState() => _ToastState();
}
class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _o;
  late Animation<double> _y;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _o = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _y = Tween(begin: 20.0, end: 0.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
    Future.delayed(const Duration(milliseconds: 2300), () { if (mounted) _c.reverse().then((_) => widget.onDone()); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 82;
    return Positioned(
      bottom: bottom, left: T.p32, right: T.p32,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Opacity(opacity: _o.value, child: Transform.translate(offset: Offset(0, _y.value), child: child)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(T.r20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: T.p20, vertical: T.p14),
              decoration: BoxDecoration(
                color: T.s4.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(T.r20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.32), blurRadius: 22, offset: const Offset(0, 8))],
              ),
              child: Text(widget.message, style: T.callout.copyWith(fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}

// Shimmer
class _Shimmer extends StatefulWidget {
  const _Shimmer();
  @override State<_Shimmer> createState() => _ShimmerState();
}
class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _a = Tween(begin: -1.5, end: 2.5).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: T.p16, vertical: T.p8),
    child: Column(children: List.generate(5, (_) => AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(
        height: 62, margin: const EdgeInsets.only(bottom: 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(T.r8),
          gradient: LinearGradient(
            begin: Alignment(_a.value - 1, 0), end: Alignment(_a.value, 0),
            colors: [T.s2, T.s4.withValues(alpha: 0.65), T.s2],
          ),
        ),
      ),
    ))),
  );
}

// Grid Painter (hero texture)
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.025)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 28) canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }
  @override bool shouldRepaint(_) => false;
}

// Route: zoom + fade in/out
PageRoute<T_> _zoomFade<T_>(Widget page) => PageRouteBuilder<T_>(
  pageBuilder: (_, a, __) => page,
  transitionDuration: const Duration(milliseconds: 400),
  reverseTransitionDuration: const Duration(milliseconds: 360),
  transitionsBuilder: (_, a, __, child) {
    final scale = Tween(begin: 0.93, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic));
    final opa   = CurvedAnimation(parent: a, curve: Curves.easeOut);
    return FadeTransition(opacity: opa, child: ScaleTransition(scale: scale, child: child));
  },
);
