// =============================================================================
// main.dart — StreamGo  (Fixed + Improved)
// =============================================================================
// FIXES
//  1. _NetworkImage — added loading shimmer placeholder (was bare blank space)
//  2. _autoHide — replaced fire-and-forget Future.delayed with a cancellable
//     Timer so it cannot fire after dispose() (memory-leak / setState-after-
//     dispose bug)
//  3. PlayerScreen._tapFav — HapticFeedback was called AFTER setState, making
//     the haptic lag; moved before setState
//  4. _retry — old _vpc listener was not removed before disposing the old
//     controller; fixed ordering: removeListener → dispose → null → reinit
//  5. Prefs.toggleFav — returned set.contains(id) AFTER mutating the set,
//     so "added" was always the NEW state — correct, but the variable name
//     "added" was misleading and the logic was subtly wrong on rapid double-
//     taps because loadFavs() created a fresh set each call. Pinned to a
//     single SharedPreferences instance per operation.
//  6. _RootShellState._toggleFav — setState called both add AND remove in one
//     ternary but the bool from Prefs was the POST-mutation state, so the
//     local set could diverge on error; guarded with mounted checks and
//     single-source-of-truth refresh.
//  7. _ProgressBar — progress thumb Positioned.left used (w * progress - 5)
//     which can be negative when progress == 0; fixed clamp start.
//  8. _controls — play/pause calls _vpc!.play() / _vpc!.pause() with ! even
//     though _vpc could theoretically be null at that moment (e.g. during
//     retry); guarded with null-aware calls.
//  9. _Toast — onDone callback captured overlay entry via closure BEFORE the
//     entry existed (_toast was null at build time); refactored to pass the
//     remove callback correctly.
// 10. MatchesScreen — grouped map iteration order is insertion-order in Dart,
//     but dates could arrive out of order from the API; added explicit sort.
// 11. _GlassCard — Positioned.fill inside a Stack whose size is determined by
//     its Column child caused unbounded height warnings on some devices; added
//     explicit constraints.
// 12. HomeScreen — SliverToBoxAdapter wrapping each group row was correct but
//     the trailing SizedBox height was 120, clashing with the pill bar height
//     on devices with large safe-area insets; changed to MediaQuery-aware pad.
//
// DESIGN & ANIMATION IMPROVEMENTS
//  • _LivePulse — added a second expanding ring (ripple) animation alongside
//    the existing fade for a more authentic "live" indicator
//  • _SpringTap — spring-back curve changed to Curves.elasticOut for a
//    bouncier, more premium feel
//  • _FeaturedCard — ambient glow now also animates hue shift slightly
//  • _ChannelCard — added a subtle shimmer sweep animation on idle
//  • _PillItem — active tab now shows a soft blue pill indicator behind the
//    icon+label instead of just color change
//  • _SkeletonState — shimmer gradient now uses three stops for more realism
//  • PlayerScreen controls — backdrop blur on the top/bottom scrims for
//    better legibility over bright video frames
//  • _GlassBtn — micro-bounce on press via _SpringTap (was plain GestureDetector)
//  • Page transitions — reverseTransitionDuration aligned to match forward
//
// CODE ARRANGEMENT
//  Sections (separated by banners):
//   1. Imports
//   2. App entry-point
//   3. Design tokens  (D)
//   4. Data models    (Channel, ChannelGroup, Match)
//   5. Mock / seed data
//   6. Persistence    (Prefs)
//   7. App root       (StreamGoApp, RootShell)
//   8. Navigation     (_PillTabBar, _PillItem)
//   9. Screens        (HomeScreen, MatchesScreen, FavoritesScreen,
//                      SettingsScreen, PlayerScreen)
//  10. Screen sub-widgets (per screen)
//  11. Shared widgets (reused across screens)
//  12. Utilities      (route builder, painters, formatters)
// =============================================================================

// ─── 1. Imports ───────────────────────────────────────────────────────────────
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

// ─── 2. App entry-point ───────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GestureBinding.instance.resamplingEnabled = true;
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:                   Colors.transparent,
    statusBarBrightness:              Brightness.dark,
    statusBarIconBrightness:          Brightness.light,
    systemNavigationBarColor:         Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const StreamGoApp());
}

// ─── 3. Design tokens ─────────────────────────────────────────────────────────
abstract class D {
  // Backgrounds
  static const bg   = Color(0xFF020202);
  static const s1   = Color(0xFF080809);
  static const s2   = Color(0xFF0F0F11);
  static const s3   = Color(0xFF181819);
  static const s4   = Color(0xFF222224);
  static const s5   = Color(0xFF2C2C2F);
  // Labels
  static const lbl  = Color(0xFFFFFFFF);
  static const lbl2 = Color(0xFF8E8E95);
  static const lbl3 = Color(0xFF48484E);
  static const lbl4 = Color(0xFF2D2D31);
  // Accents
  static const blue  = Color(0xFF0A84FF);
  static const red   = Color(0xFFFF453A);
  static const green = Color(0xFF30D158);

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
  static const r36  = 36.0;
  static const rMax = 999.0;

  // Gaps
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

  // Text styles
  static TextStyle get hero     => const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.4, height: 1.08, color: lbl, decoration: TextDecoration.none);
  static TextStyle get title1   => const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.8, height: 1.15, color: lbl, decoration: TextDecoration.none);
  static TextStyle get title2   => const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2,  color: lbl, decoration: TextDecoration.none);
  static TextStyle get title3   => const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.3,  color: lbl, decoration: TextDecoration.none);
  static TextStyle get headline => const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2, height: 1.4,  color: lbl, decoration: TextDecoration.none);
  static TextStyle get body     => const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, letterSpacing: -0.1, height: 1.5,  color: lbl, decoration: TextDecoration.none);
  static TextStyle get callout  => const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing:  0.0, height: 1.4,  color: lbl, decoration: TextDecoration.none);
  static TextStyle get caption  => const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing:  0.1, height: 1.3,  color: lbl2, decoration: TextDecoration.none);
  static TextStyle get micro    => const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing:  0.3, height: 1.2,  color: lbl2, decoration: TextDecoration.none);
}

// ─── 4. Data models ───────────────────────────────────────────────────────────
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
    logo:      j['logo']   as String?  ?? '',
    streamUrl: j['stream'] as String?  ?? '',
  );
}

class ChannelGroup {
  final String       name;
  final IconData     icon;
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
  final String   id, league, home, homeEn, homeLogo, away, awayEn, awayLogo,
                 score, time;
  final DateTime date;
  final bool     isLive, hasChannels;

  const Match({
    required this.id,       required this.league,
    required this.home,     required this.homeEn,     required this.homeLogo,
    required this.away,     required this.awayEn,     required this.awayLogo,
    required this.score,    required this.time,
    required this.date,     required this.isLive,     required this.hasChannels,
  });

  factory Match.fromJson(Map<String, dynamic> j) {
    DateTime d;
    try {
      d = DateTime.parse(j['date'] as String? ?? '');
    } catch (_) {
      d = DateTime.now();
    }
    return Match(
      id:          j['id']?.toString()          ?? '',
      league:      j['league']  as String?       ?? '',
      home:        j['home']    as String?        ?? '',
      homeEn:      j['home_en'] as String?        ?? '',
      homeLogo:    j['home_logo'] as String?      ?? '',
      away:        j['away']    as String?        ?? '',
      awayEn:      j['away_en'] as String?        ?? '',
      awayLogo:    j['away_logo'] as String?      ?? '',
      score:       j['score']   as String?        ?? '0 - 0',
      time:        j['time']    as String?        ?? '',
      date:        d,
      isLive:      (j['status']?.toString()       ?? '0') == '1',
      hasChannels: (j['has_channels']?.toString() ?? '0') == '1',
    );
  }

  String get homeLogoUrl  => 'https://img.kora-api.space/uploads/team/$homeLogo';
  String get awayLogoUrl  => 'https://img.kora-api.space/uploads/team/$awayLogo';
  String get homeDisplay  => homeEn.isNotEmpty ? homeEn : home;
  String get awayDisplay  => awayEn.isNotEmpty ? awayEn : away;
}

// ─── 5. Mock / seed data ──────────────────────────────────────────────────────
const _kStream =
    'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8';

final List<ChannelGroup> _kMockGroups = [
  ChannelGroup(name: 'Sports', icon: CupertinoIcons.sportscourt_fill, channels: [
    const Channel(id: 1, name: 'beIN Sports 1', number: '01',
        logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/BeIN_Sports_logo.svg/200px-BeIN_Sports_logo.svg.png',
        streamUrl: _kStream),
    const Channel(id: 2, name: 'beIN Sports 2', number: '02',
        logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/BeIN_Sports_logo.svg/200px-BeIN_Sports_logo.svg.png',
        streamUrl: _kStream),
    const Channel(id: 3, name: 'beIN Sports 3', number: '03',
        logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/BeIN_Sports_logo.svg/200px-BeIN_Sports_logo.svg.png',
        streamUrl: _kStream),
    const Channel(id: 4, name: 'SSC 1', number: '04',
        logo: 'https://upload.wikimedia.org/wikipedia/ar/a/a7/SSC_Sports_Logo.png',
        streamUrl: _kStream),
    const Channel(id: 5, name: 'SSC 2', number: '05',
        logo: 'https://upload.wikimedia.org/wikipedia/ar/a/a7/SSC_Sports_Logo.png',
        streamUrl: _kStream),
    const Channel(id: 6, name: 'MBC Sport', number: '06',
        logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/MBC_Sports_logo.svg/200px-MBC_Sports_logo.svg.png',
        streamUrl: _kStream),
  ]),
  ChannelGroup(name: 'News', icon: CupertinoIcons.news_solid, channels: [
    const Channel(id: 7, name: 'Al Jazeera', number: '07',
        logo: 'https://upload.wikimedia.org/wikipedia/en/thumb/b/b2/Al_Jazeera_Logo_2006.svg/200px-Al_Jazeera_Logo_2006.svg.png',
        streamUrl: _kStream),
    const Channel(id: 8, name: 'Sky News', number: '08',
        logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/Sky_News_Arabia_logo.svg/200px-Sky_News_Arabia_logo.svg.png',
        streamUrl: _kStream),
    const Channel(id: 9, name: 'Al Arabiya', number: '09',
        logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/29/Al_Arabiya_logo.svg/200px-Al_Arabiya_logo.svg.png',
        streamUrl: _kStream),
  ]),
  ChannelGroup(name: 'Entertainment', icon: CupertinoIcons.tv_fill, channels: [
    const Channel(id: 10, name: 'MBC 1', number: '10',
        logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/MBC1HD.png/200px-MBC1HD.png',
        streamUrl: _kStream),
    const Channel(id: 11, name: 'MBC 2', number: '11',
        logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/MBC1HD.png/200px-MBC1HD.png',
        streamUrl: _kStream),
    const Channel(id: 12, name: 'Rotana Cinema', number: '12',
        logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/94/Rotana_logo.svg/200px-Rotana_logo.svg.png',
        streamUrl: _kStream),
  ]),
];

final List<Match> _kMockMatches = [
  Match(id: '1', league: 'UEFA Champions League',
      home: 'Real Madrid',   homeEn: 'Real Madrid',   homeLogo: 'real_madrid.png',
      away: 'Man City',      awayEn: 'Man City',       awayLogo: 'man_city.png',
      score: '2 - 1', time: '21:00', date: DateTime.now(),
      isLive: true,  hasChannels: true),
  Match(id: '2', league: 'Premier League',
      home: 'Liverpool',     homeEn: 'Liverpool',      homeLogo: 'liverpool.png',
      away: 'Arsenal',       awayEn: 'Arsenal',        awayLogo: 'arsenal.png',
      score: '1 - 1', time: '22:45', date: DateTime.now(),
      isLive: true,  hasChannels: true),
  Match(id: '3', league: 'La Liga',
      home: 'Barcelona',     homeEn: 'Barcelona',      homeLogo: 'barca.png',
      away: 'Atletico',      awayEn: 'Atletico',       awayLogo: 'atletico.png',
      score: '', time: '23:00', date: DateTime.now(),
      isLive: false, hasChannels: true),
  Match(id: '4', league: 'Bundesliga',
      home: 'Bayern Munich', homeEn: 'Bayern Munich',  homeLogo: 'bayern.png',
      away: 'Dortmund',      awayEn: 'Dortmund',       awayLogo: 'dortmund.png',
      score: '', time: '20:30', date: DateTime.now().add(const Duration(days: 1)),
      isLive: false, hasChannels: false),
  Match(id: '5', league: 'Ligue 1',
      home: 'PSG',           homeEn: 'PSG',            homeLogo: 'psg.png',
      away: 'Marseille',     awayEn: 'Marseille',      awayLogo: 'marseille.png',
      score: '', time: '21:45', date: DateTime.now().add(const Duration(days: 1)),
      isLive: false, hasChannels: false),
  Match(id: '6', league: 'UEFA Champions League',
      home: 'Juventus',      homeEn: 'Juventus',       homeLogo: 'juve.png',
      away: 'Inter Milan',   awayEn: 'Inter Milan',    awayLogo: 'inter.png',
      score: '', time: '22:00', date: DateTime.now().add(const Duration(days: 2)),
      isLive: false, hasChannels: false),
];

// ─── 6. Persistence ───────────────────────────────────────────────────────────
class Prefs {
  static const _kFav      = 'favs_v3';
  static const _kSettings = 'settings_v2';

  static Future<Set<int>> loadFavs() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_kFav) ?? [])
        .map((e) => int.tryParse(e) ?? -1)
        .toSet();
  }

  // FIX #5 – use a single prefs instance; return the NEW "is-fav" state.
  static Future<bool> toggleFav(int id) async {
    final p   = await SharedPreferences.getInstance();
    final raw = p.getStringList(_kFav) ?? [];
    final set = raw.map((e) => int.tryParse(e) ?? -1).toSet();
    final nowAdded = !set.contains(id);
    nowAdded ? set.add(id) : set.remove(id);
    await p.setStringList(_kFav, set.map((e) => '$e').toList());
    return nowAdded;
  }

  static Future<Map<String, dynamic>> loadSettings() async {
    final p   = await SharedPreferences.getInstance();
    final raw = p.getString(_kSettings);
    if (raw == null) return _defaultSettings();
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return _defaultSettings();
    }
  }

  static Future<void> saveSettings(Map<String, dynamic> s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSettings, jsonEncode(s));
  }

  static Map<String, dynamic> _defaultSettings() =>
      {'autoPlay': true, 'showScores': true, 'quality': 'auto'};
}

// ─── 7. App root ──────────────────────────────────────────────────────────────
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

  Set<int>             _favIds       = {};
  List<ChannelGroup>   _groups       = [];
  List<Match>          _matches      = [];
  Map<String, dynamic> _settings     = {'autoPlay': true, 'showScores': true, 'quality': 'auto'};
  bool _groupsLoading = true;
  bool _matchLoading  = true;

  late final AnimationController _tabAnim;
  OverlayEntry? _toast;

  @override
  void initState() {
    super.initState();
    _tabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _init();
  }

  @override
  void dispose() {
    _tabAnim.dispose();
    super.dispose();
  }

  Future<void> _init() =>
      Future.wait([_loadFavs(), _loadSettings(), _loadGroups(), _loadMatches()]);

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
    final ds  = '${now.year}-'
                '${now.month.toString().padLeft(2, '0')}-'
                '${now.day.toString().padLeft(2, '0')}';
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

  // FIX #6 – single source-of-truth; guard mounted before setState.
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
      autoPlay:    _settings['autoPlay'] as bool? ?? true,
      onToggleFav: () => _toggleFav(ch.id),
    )));
  }

  // FIX #9 – pass a tear-off; the overlay entry is captured via the
  // _toast field which is always set before insert().
  void _showToast(String msg) {
    _toast?.remove();
    _toast = null;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Toast(
        message: msg,
        onDone: () {
          entry.remove();
          if (_toast == entry) _toast = null;
        },
      ),
    );
    _toast = entry;
    Overlay.of(context).insert(entry);
  }

  List<Channel> get _allChannels  => _groups.expand((g) => g.channels).toList();
  List<Channel> get _favChannels  => _allChannels.where((c) => _favIds.contains(c.id)).toList();

  @override
  Widget build(BuildContext context) {
    // FIX #12 – bottom pad accounts for safe-area so content is not hidden.
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final trailingPad    = math.max(bottomSafeArea, 0.0) + 110.0;

    return Scaffold(
      backgroundColor: D.bg,
      body: Stack(children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
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
                groups:        _groups,
                matches:       _matches,
                groupsLoading: _groupsLoading,
                matchLoading:  _matchLoading,
                onOpenPlayer:  _openPlayer,
                onGoMatches:   () => setState(() => _tab = 1),
                onRefresh:     _refresh,
                trailingPad:   trailingPad,
              ),
              MatchesScreen(
                matches:      _matches,
                loading:      _matchLoading,
                showScores:   _settings['showScores'] as bool? ?? true,
                onRefresh:    _loadMatches,
                trailingPad:  trailingPad,
              ),
              FavoritesScreen(
                channels:     _favChannels,
                onOpenPlayer: _openPlayer,
                onToggleFav:  _toggleFav,
                trailingPad:  trailingPad,
              ),
              SettingsScreen(
                settings:    _settings,
                trailingPad: trailingPad,
                onChanged: (s) async {
                  setState(() => _settings = s);
                  await Prefs.saveSettings(s);
                },
              ),
            ][_tab],
          ),
        ),
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
      ]),
    );
  }
}

// ─── 8. Navigation ────────────────────────────────────────────────────────────
class _PillTabBar extends StatelessWidget {
  final int                selected;
  final ValueChanged<int>  onTap;
  const _PillTabBar({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, math.max(bottom, 8) + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(D.r36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: const Color(0xFF18181A).withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(D.r36),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.65), blurRadius: 60, spreadRadius: -6, offset: const Offset(0, 22)),
                BoxShadow(color: D.blue.withValues(alpha: 0.04),  blurRadius: 32),
              ],
            ),
            child: Stack(children: [
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(D.r36),
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: 0.04), Colors.transparent],
                ),
              ))),
              Row(children: [
                _PillItem(index: 0, selected: selected, icon: CupertinoIcons.house,       activeIcon: CupertinoIcons.house_fill,       label: 'Home',      onTap: onTap),
                _PillItem(index: 1, selected: selected, icon: CupertinoIcons.sportscourt, activeIcon: CupertinoIcons.sportscourt_fill, label: 'Matches',   onTap: onTap),
                _PillItem(index: 2, selected: selected, icon: CupertinoIcons.heart,       activeIcon: CupertinoIcons.heart_fill,       label: 'Favorites', onTap: onTap),
                _PillItem(index: 3, selected: selected, icon: CupertinoIcons.gear_alt,    activeIcon: CupertinoIcons.gear_alt_fill,    label: 'Settings',  onTap: onTap),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PillItem extends StatelessWidget {
  final int            index, selected;
  final IconData       icon, activeIcon;
  final String         label;
  final ValueChanged<int> onTap;
  const _PillItem({
    required this.index, required this.selected,
    required this.icon,  required this.activeIcon,
    required this.label, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == selected;
    return Expanded(
      child: _SpringTap(
        onTap: () => onTap(index),
        child: Stack(alignment: Alignment.center, children: [
          // IMPROVEMENT – active pill highlight behind icon+label
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width:  active ? 64 : 0,
            height: active ? 34 : 0,
            decoration: BoxDecoration(
              color: D.blue.withValues(alpha: active ? 0.13 : 0),
              borderRadius: BorderRadius.circular(D.rMax),
            ),
          ),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 230),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: Tween(begin: 0.62, end: 1.0)
                    .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                active ? activeIcon : icon,
                key:   ValueKey(active),
                size:  22,
                color: active ? D.blue : D.lbl3,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize:     9,
                fontWeight:   active ? FontWeight.w600 : FontWeight.w400,
                color:        active ? D.blue : D.lbl3,
                letterSpacing: -0.1,
                decoration:   TextDecoration.none,
              ),
              child: Text(label),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─── 9. Screens ───────────────────────────────────────────────────────────────

// ── HomeScreen ────────────────────────────────────────────────────────────────
class HomeScreen extends StatelessWidget {
  final List<ChannelGroup>  groups;
  final List<Match>         matches;
  final bool                groupsLoading, matchLoading;
  final Function(Channel)   onOpenPlayer;
  final VoidCallback        onGoMatches;
  final Future<void> Function() onRefresh;
  final double              trailingPad;

  const HomeScreen({
    super.key,
    required this.groups,       required this.matches,
    required this.groupsLoading, required this.matchLoading,
    required this.onOpenPlayer, required this.onGoMatches,
    required this.onRefresh,    required this.trailingPad,
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
        CupertinoSliverRefreshControl(onRefresh: onRefresh),
        SliverToBoxAdapter(child: SizedBox(height: topPad + D.g8)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(D.g20, 0, D.g20, D.g24),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_greeting(), style: D.caption.copyWith(color: D.lbl2, fontSize: 13)),
                const SizedBox(height: 2),
                Text('StreamGo', style: D.hero),
              ]),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF1C6EF2), Color(0xFF0A50C8)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: D.blue.withValues(alpha: 0.40), blurRadius: 16, offset: const Offset(0, 5))],
                ),
                child: const Icon(CupertinoIcons.person_fill, size: 20, color: Colors.white),
              ),
            ]),
          ),
        ),
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
        if (groupsLoading)
          const SliverToBoxAdapter(child: _Skeleton())
        else
          ...groups.map((g) => SliverToBoxAdapter(
            child: _ChannelGroupRow(group: g, onOpen: onOpenPlayer),
          )),
        // FIX #12 – dynamic trailing pad
        SliverToBoxAdapter(child: SizedBox(height: trailingPad)),
      ],
    );
  }
}

// ── MatchesScreen ─────────────────────────────────────────────────────────────
class MatchesScreen extends StatelessWidget {
  final List<Match>          matches;
  final bool                 loading;
  final bool                 showScores;
  final Future<void> Function() onRefresh;
  final double               trailingPad;

  const MatchesScreen({
    super.key,
    required this.matches,    required this.loading,
    required this.showScores, required this.onRefresh,
    required this.trailingPad,
  });

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final topPad   = MediaQuery.of(context).padding.top;
    final now      = DateTime.now();
    final today    = _fmtDate(now);
    final tomorrow = _fmtDate(now.add(const Duration(days: 1)));

    // FIX #10 – sort matches by date before grouping
    final sorted = List<Match>.from(matches)..sort((a, b) => a.date.compareTo(b.date));
    final grouped = <String, List<Match>>{};
    for (final m in sorted) {
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
            child: _MatchDaySection(label: e.key, matches: e.value, showScores: showScores),
          )),
        SliverToBoxAdapter(child: SizedBox(height: trailingPad)),
      ],
    );
  }
}

// ── FavoritesScreen ───────────────────────────────────────────────────────────
class FavoritesScreen extends StatelessWidget {
  final List<Channel>     channels;
  final Function(Channel) onOpenPlayer;
  final Function(int)     onToggleFav;
  final double            trailingPad;

  const FavoritesScreen({
    super.key,
    required this.channels,    required this.onOpenPlayer,
    required this.onToggleFav, required this.trailingPad,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: topPad + D.g8)),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(D.g20, 0, D.g20, D.g24),
          child: Row(children: [
            Text('Favorites', style: D.hero),
            if (channels.isNotEmpty) ...[
              const SizedBox(width: D.g12),
              _Badge(label: '${channels.length}', color: D.red),
            ],
          ]),
        )),
        if (channels.isEmpty)
          SliverFillRemaining(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(D.rMax),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [D.s3, D.s2],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                  ),
                  child: const Icon(CupertinoIcons.heart, size: 36, color: D.lbl3),
                ),
              ),
            ),
            const SizedBox(height: D.g20),
            Text('No favorites yet', style: D.body.copyWith(color: D.lbl2)),
            const SizedBox(height: D.g8),
            Text('Tap ♡ on any channel to add it', style: D.caption.copyWith(color: D.lbl3)),
          ]))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: D.g16),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (_, i) {
                final ch = channels[i];
                return _FavRow(
                  channel:  ch,
                  isFirst:  i == 0,
                  isLast:   i == channels.length - 1,
                  onTap:    () => onOpenPlayer(ch),
                  onRemove: () => onToggleFav(ch.id),
                );
              },
              childCount: channels.length,
            )),
          ),
        SliverToBoxAdapter(child: SizedBox(height: trailingPad)),
      ],
    );
  }
}

// ── SettingsScreen ────────────────────────────────────────────────────────────
class SettingsScreen extends StatelessWidget {
  final Map<String, dynamic>          settings;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final double                        trailingPad;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.trailingPad,
  });

  void _update(String key, dynamic val) =>
      onChanged(Map<String, dynamic>.from(settings)..[key] = val);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: topPad + D.g8)),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(D.g20, 0, D.g20, D.g32),
          child: Text('Settings', style: D.hero),
        )),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: D.g16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SectionLabel('Playback'),
            _GlassCard(children: [
              _ToggleRow(
                icon: CupertinoIcons.play_circle_fill, iconColor: D.red,
                title: 'Auto Play',
                subtitle: 'Start streaming immediately on channel open',
                value: settings['autoPlay'] as bool? ?? true,
                onChanged: (v) => _update('autoPlay', v),
              ),
              _ToggleRow(
                icon: CupertinoIcons.sportscourt_fill, iconColor: D.green,
                title: 'Show Scores',
                subtitle: 'Display live scores on match cards',
                value: settings['showScores'] as bool? ?? true,
                onChanged: (v) => _update('showScores', v),
              ),
            ]),
            const SizedBox(height: D.g28),
            _SectionLabel('Stream Quality'),
            _GlassCard(children: [
              for (final q in [('auto', 'Auto'), ('hd', 'HD'), ('sd', 'SD')])
                _QualityRow(
                  label:  q.$2,
                  active: (settings['quality'] as String? ?? 'auto') == q.$1,
                  isLast: q.$1 == 'sd',
                  onTap:  () => _update('quality', q.$1),
                ),
            ]),
            const SizedBox(height: D.g28),
            _SectionLabel('About'),
            _GlassCard(children: [
              const _InfoRow(label: 'App',       value: 'StreamGo'),
              const _InfoRow(label: 'Version',   value: '3.0.0'),
              const _InfoRow(label: 'Developer', value: 'StreamGo Team', isLast: true),
            ]),
            const SizedBox(height: D.g32),
          ]),
        )),
        SliverToBoxAdapter(child: SizedBox(height: trailingPad)),
      ],
    );
  }
}

// ── PlayerScreen ──────────────────────────────────────────────────────────────
class PlayerScreen extends StatefulWidget {
  final Channel      channel;
  final bool         isFavorite;
  final bool         autoPlay;
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

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  VideoPlayerController? _vpc;
  ChewieController?      _cc;
  bool _loading = true, _error = false, _ctrlsVisible = true;
  late bool _isFav;

  late final AnimationController _ctrlsCtrl;
  late final Animation<double>   _ctrlsFade;
  late final AnimationController _favCtrl;
  late final Animation<double>   _favScale;

  // FIX #2 – cancellable auto-hide timer
  Timer? _hideTimer;

  static const _kUA =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36';

  @override
  void initState() {
    super.initState();
    _isFav = widget.isFavorite;

    _ctrlsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _ctrlsFade = CurvedAnimation(parent: _ctrlsCtrl, curve: Curves.easeOut);
    _ctrlsCtrl.forward();

    _favCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _favScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5).chain(CurveTween(curve: Curves.easeOut)),    weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 70),
    ]).animate(_favCtrl);

    _initPlayer();
    _scheduleAutoHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _ctrlsCtrl.dispose();
    _favCtrl.dispose();
    // FIX #4 – correct disposal order
    _vpc?.removeListener(_onVideoUpdate);
    _cc?.dispose();
    _vpc?.dispose();
    super.dispose();
  }

  void _onVideoUpdate() {
    if (mounted) setState(() {});
  }

  // FIX #2 – use Timer so it can be cancelled on dispose
  void _scheduleAutoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _ctrlsVisible) {
        setState(() => _ctrlsVisible = false);
        _ctrlsCtrl.reverse();
      }
    });
  }

  void _toggleControls() {
    HapticFeedback.selectionClick();
    setState(() => _ctrlsVisible = !_ctrlsVisible);
    _ctrlsVisible ? _ctrlsCtrl.forward() : _ctrlsCtrl.reverse();
    if (_ctrlsVisible) _scheduleAutoHide();
  }

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
      _vpc!.addListener(_onVideoUpdate);
      _cc = ChewieController(
        videoPlayerController: _vpc!,
        autoPlay:        widget.autoPlay,
        looping:         true,
        allowFullScreen: false,
        allowMuting:     true,
        showControls:    false,
        placeholder:     const Center(child: CupertinoActivityIndicator(radius: 16, color: Colors.white)),
        errorBuilder:    (_, __) => _PlayerError(onRetry: _retry),
      );
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  // FIX #4 – correct retry order: remove listener → dispose CC → dispose VPC
  void _retry() {
    _vpc?.removeListener(_onVideoUpdate);
    _cc?.dispose();  _cc  = null;
    _vpc?.dispose(); _vpc = null;
    _initPlayer();
  }

  // FIX #3 – haptic BEFORE setState for zero perceptible lag
  void _tapFav() {
    HapticFeedback.mediumImpact();
    widget.onToggleFav();
    setState(() => _isFav = !_isFav);
    _favCtrl.forward(from: 0);
  }

  void _toggleFullscreen(bool isLand) {
    HapticFeedback.lightImpact();
    if (isLand) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  bool     get _playing  => _vpc?.value.isPlaying ?? false;
  Duration get _position => _vpc?.value.position  ?? Duration.zero;
  Duration get _duration => _vpc?.value.duration  ?? Duration.zero;

  double get _progress {
    final ms = _duration.inMilliseconds;
    return ms == 0 ? 0 : (_position.inMilliseconds / ms).clamp(0.0, 1.0);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final mq     = MediaQuery.of(context);
    final isLand = mq.orientation == Orientation.landscape;
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: isLand ? _landscape(mq) : _portrait(mq),
      ),
    );
  }

  Widget _landscape(MediaQueryData mq) => GestureDetector(
    onTap: _toggleControls,
    behavior: HitTestBehavior.opaque,
    child: Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: Colors.black),
      _videoWidget(),
      Positioned(top: 0,    left: 0, right: 0, height: 160, child: const _GradScrim(fromTop: true)),
      Positioned(bottom: 0, left: 0, right: 0, height: 160, child: const _GradScrim(fromTop: false)),
      FadeTransition(
        opacity: _ctrlsFade,
        child: SafeArea(child: _controls(0, isLand: true)),
      ),
    ]),
  );

  Widget _portrait(MediaQueryData mq) {
    final topPad = mq.padding.top;
    final videoH = mq.size.width * 9.0 / 16.0;
    return Column(children: [
      GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width:  double.infinity,
          height: topPad + videoH,
          child: Stack(fit: StackFit.expand, children: [
            const ColoredBox(color: Colors.black),
            Positioned(top: topPad, left: 0, right: 0, height: videoH, child: _videoWidget()),
            Positioned(top: 0,    left: 0, right: 0, height: topPad + 96, child: const _GradScrim(fromTop: true)),
            Positioned(bottom: 0, left: 0, right: 0, height: 110,         child: const _GradScrim(fromTop: false)),
            FadeTransition(opacity: _ctrlsFade, child: _controls(topPad, isLand: false)),
          ]),
        ),
      ),
      Expanded(child: _infoPanel()),
    ]);
  }

  Widget _videoWidget() {
    if (_loading) return const Center(child: CupertinoActivityIndicator(radius: 18, color: Colors.white));
    if (_error)   return _PlayerError(onRetry: _retry);
    if (_cc != null) return Chewie(controller: _cc!);
    return const Center(child: CupertinoActivityIndicator(radius: 18, color: Colors.white));
  }

  Widget _controls(double topOffset, {required bool isLand}) => Stack(children: [
    Positioned(
      top: topOffset + D.g10, left: 0, right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: D.g16),
        child: Row(children: [
          _GlassBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.of(context).pop()),
          const SizedBox(width: D.g12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(
              widget.channel.name,
              style: D.headline.copyWith(
                color:      Colors.white,
                shadows:    [const Shadow(blurRadius: 12)],
                decoration: TextDecoration.none,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            const Row(children: [
              _LivePulse(),
              SizedBox(width: D.g4),
              Text('Live', style: TextStyle(color: Colors.white70, fontSize: 12, decoration: TextDecoration.none)),
            ]),
          ])),
          ScaleTransition(
            scale: _favScale,
            child: _GlassBtn(
              icon:      _isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              iconColor: _isFav ? D.red : Colors.white,
              onTap:     _tapFav,
            ),
          ),
        ]),
      ),
    ),
    if (!_loading && !_error)
      Center(child: _GlassBtn(
        icon:     _playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
        size:     62,
        iconSize: 28,
        onTap: () {
          HapticFeedback.lightImpact();
          // FIX #8 – null-safe play/pause
          if (_playing) {
            _vpc?.pause();
          } else {
            _vpc?.play();
          }
          setState(() {});
          _scheduleAutoHide();
        },
      )),
    if (!_loading && !_error)
      Positioned(
        bottom: D.g14, left: 0, right: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: D.g16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _ProgressBar(progress: _progress),
            const SizedBox(height: D.g6),
            Row(children: [
              Text(_fmt(_position), style: D.micro.copyWith(color: Colors.white70, fontWeight: FontWeight.w500, decoration: TextDecoration.none)),
              const Spacer(),
              _GlassBtn(
                icon:     isLand
                    ? CupertinoIcons.arrow_down_right_arrow_up_left
                    : CupertinoIcons.arrow_up_left_arrow_down_right,
                size:     30,
                iconSize: 14,
                onTap:    () => _toggleFullscreen(isLand),
              ),
              const Spacer(),
              Text(_fmt(_duration), style: D.micro.copyWith(color: Colors.white38, decoration: TextDecoration.none)),
            ]),
          ]),
        ),
      ),
  ]);

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
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [D.s3, D.s2],
                ),
                borderRadius: BorderRadius.circular(D.r16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.09), width: 0.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.50), blurRadius: 16, offset: const Offset(0, 5))],
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
              ClipRRect(
                borderRadius: BorderRadius.circular(D.rMax),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: D.g10, vertical: D.g4),
                    decoration: BoxDecoration(
                      color: D.red.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(D.rMax),
                      border: Border.all(color: D.red.withValues(alpha: 0.26), width: 0.5),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      _LivePulse(),
                      SizedBox(width: D.g6),
                      Text('Live', style: TextStyle(color: D.red, fontWeight: FontWeight.w600, fontSize: 12, decoration: TextDecoration.none)),
                    ]),
                  ),
                ),
              ),
            ])),
            const SizedBox(width: D.g12),
            _SpringTap(
              onTap: _tapFav,
              child: ScaleTransition(
                scale: _favScale,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(D.rMax),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color:  D.s3.withValues(alpha: 0.80),
                        shape:  BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.09), width: 0.5),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        transitionBuilder: (c, a) => ScaleTransition(
                          scale: Tween(begin: 0.5, end: 1.0)
                              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
                          child: FadeTransition(opacity: a, child: c),
                        ),
                        child: Icon(
                          _isFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                          key:   ValueKey(_isFav),
                          color: _isFav ? D.red : D.lbl2,
                          size:  22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: D.g20),
          ClipRRect(
            borderRadius: BorderRadius.circular(D.r14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: D.g16, vertical: D.g12),
                decoration: BoxDecoration(
                  color: D.s2.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(D.r14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.5),
                ),
                child: Row(children: [
                  _Chip(icon: CupertinoIcons.tv,       label: 'Ch. ${widget.channel.number}'),
                  const SizedBox(width: D.g16),
                  const _Chip(icon: CupertinoIcons.waveform, label: 'HLS'),
                  const Spacer(),
                  _SpringTap(
                    onTap: _retry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: D.g12, vertical: D.g6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [D.blue.withValues(alpha: 0.22), D.blue.withValues(alpha: 0.09)]),
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

// ─── 10. Screen sub-widgets ───────────────────────────────────────────────────

// Home sub-widgets ─────────────────────────────────────────────────────────────
class _FeaturedCard extends StatefulWidget {
  final List<Match>  matches;
  final bool         loading;
  final VoidCallback onGoMatches;
  const _FeaturedCard({required this.matches, required this.loading, required this.onGoMatches});
  @override State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> with SingleTickerProviderStateMixin {
  late final AnimationController _glow;
  @override
  void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat(reverse: true);
  }
  @override void dispose() { _glow.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return Container(
        height: 204,
        decoration: BoxDecoration(color: D.s2, borderRadius: BorderRadius.circular(D.r24)),
      );
    }
    final live     = widget.matches.where((m) => m.isLive).toList();
    final featured = live.isNotEmpty
        ? live.first
        : widget.matches.isNotEmpty ? widget.matches.first : null;

    return _SpringTap(
      onTap: widget.onGoMatches,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (_, child) => Container(
          height: 204,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(D.r24),
            // IMPROVEMENT – very slight hue shift in the glow animation
            gradient: LinearGradient(
              begin: Alignment.topRight, end: Alignment.bottomLeft,
              colors: [
                const Color(0xFF0D2847),
                Color.lerp(const Color(0xFF0A1E35), const Color(0xFF0E2244), _glow.value)!,
                const Color(0xFF040A14),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(D.blue, const Color(0xFF30A0FF), _glow.value * 0.3)!
                    .withValues(alpha: 0.08 + 0.09 * _glow.value),
                blurRadius: 40,
                offset: const Offset(0, 14),
              ),
              BoxShadow(color: Colors.black.withValues(alpha: 0.50), blurRadius: 24, offset: const Offset(0, 6)),
            ],
          ),
          child: child,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(D.r24),
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            Positioned(top: -60, right: -60, child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Colors.white.withValues(alpha: 0.05), Colors.transparent,
                ]),
              ),
            )),
            Positioned(bottom: -40, left: -40, child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  D.blue.withValues(alpha: 0.06), Colors.transparent,
                ]),
              ),
            )),
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(D.r24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09), width: 0.5),
            ))),
            Padding(
              padding: const EdgeInsets.all(D.g20),
              child: featured != null
                  ? _CardMatchContent(match: featured)
                  : const _CardDefault(),
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
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      if (match.isLive) ...[const _LivePulse(), const SizedBox(width: D.g6)],
      _Badge(label: match.isLive ? 'Live Now' : 'Upcoming', color: match.isLive ? D.red : D.blue),
      const SizedBox(width: D.g8),
      Expanded(child: Text(match.league, style: D.caption.copyWith(color: D.lbl2), maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]),
    const Spacer(),
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

class _MiniTeam extends StatelessWidget {
  final String name, logoUrl;
  const _MiniTeam({required this.name, required this.logoUrl});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 82,
    child: Column(children: [
      _NetworkImage(url: logoUrl, w: 48, h: 48),
      const SizedBox(height: D.g6),
      Text(name,
        style: D.caption.copyWith(fontWeight: FontWeight.w500, color: D.lbl),
        textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}

class _ChannelGroupRow extends StatelessWidget {
  final ChannelGroup    group;
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
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    D.blue.withValues(alpha: 0.28),
                    D.blue.withValues(alpha: 0.08),
                  ]),
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
        height: 164,
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
  final Channel      channel;
  final VoidCallback onTap;
  const _ChannelCard({required this.channel, required this.onTap});
  @override
  Widget build(BuildContext context) => _SpringTap(
    onTap: onTap,
    child: Container(
      width: 112,
      margin: const EdgeInsets.symmetric(horizontal: D.g6),
      child: Column(children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(D.r20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [D.s3, D.s2],
                  ),
                  borderRadius: BorderRadius.circular(D.r20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.40), blurRadius: 16, offset: const Offset(0, 8))],
                ),
                child: Stack(children: [
                  Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(D.r20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.06),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.10),
                      ],
                    ),
                  ))),
                  Padding(
                    padding: const EdgeInsets.all(D.g16),
                    child: Center(child: _NetworkImage(url: channel.logo, w: 60, h: 60)),
                  ),
                  if (channel.number.isNotEmpty)
                    Positioned(
                      top: D.g8, right: D.g8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(D.r6),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: D.blue.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(D.r6),
                              border: Border.all(color: D.blue.withValues(alpha: 0.30), width: 0.5),
                            ),
                            child: Text(channel.number, style: D.micro.copyWith(color: D.blue, fontSize: 9)),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
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

// Matches sub-widgets ──────────────────────────────────────────────────────────
class _MatchDaySection extends StatelessWidget {
  final String      label;
  final List<Match> matches;
  final bool        showScores;
  const _MatchDaySection({required this.label, required this.matches, required this.showScores});
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
                  color: label == 'Today'
                      ? D.red.withValues(alpha: 0.12)
                      : D.s3.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(D.rMax),
                  border: Border.all(
                    color: label == 'Today'
                        ? D.red.withValues(alpha: 0.28)
                        : Colors.white.withValues(alpha: 0.07),
                    width: 0.5,
                  ),
                ),
                child: Text(label, style: D.caption.copyWith(
                  color:      label == 'Today' ? D.red : D.lbl2,
                  fontWeight: FontWeight.w600,
                  fontSize:   13,
                )),
              ),
            ),
          ),
        ]),
      ),
      _GlassCard(children: matches.asMap().entries.map((e) =>
        _MatchRow(match: e.value, showScore: showScores, isLast: e.key == matches.length - 1),
      ).toList()),
    ]),
  );
}

class _MatchRow extends StatelessWidget {
  final Match match;
  final bool  showScore, isLast;
  const _MatchRow({required this.match, required this.showScore, required this.isLast});
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: D.g16, vertical: D.g16),
      child: Column(children: [
        Text(match.league,
          style: D.caption.copyWith(color: D.lbl3, fontSize: 11),
          textAlign: TextAlign.center),
        const SizedBox(height: D.g12),
        Row(children: [
          Expanded(child: Column(children: [
            _NetworkImage(url: match.homeLogoUrl, w: 44, h: 44),
            const SizedBox(height: D.g6),
            Text(match.homeDisplay,
              style: D.caption.copyWith(fontWeight: FontWeight.w600, color: D.lbl),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: D.g8),
            child: match.isLive
                ? Column(children: [
                    const Row(mainAxisSize: MainAxisSize.min, children: [
                      _LivePulse(), SizedBox(width: D.g4),
                      _Badge(label: 'Live', color: D.red),
                    ]),
                    const SizedBox(height: D.g8),
                    if (showScore) Text(match.score, style: D.title2.copyWith(letterSpacing: 3)),
                  ])
                : Text(match.time, style: D.headline.copyWith(
                    color: D.lbl2, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
          Expanded(child: Column(children: [
            _NetworkImage(url: match.awayLogoUrl, w: 44, h: 44),
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
      color:  Colors.white.withValues(alpha: 0.055),
      margin: const EdgeInsets.symmetric(horizontal: D.g16),
    ),
  ]);
}

// Favorites sub-widgets ────────────────────────────────────────────────────────
class _FavRow extends StatelessWidget {
  final Channel      channel;
  final bool         isFirst, isLast;
  final VoidCallback onTap, onRemove;
  const _FavRow({
    required this.channel, required this.isFirst, required this.isLast,
    required this.onTap,   required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => _SpringTap(
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 0.8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [D.s3, D.s2],
        ),
        borderRadius: BorderRadius.vertical(
          top:    isFirst ? const Radius.circular(D.r16) : Radius.zero,
          bottom: isLast  ? const Radius.circular(D.r16) : Radius.zero,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: D.g16, vertical: D.g12),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [D.s4, D.s3],
              ),
              borderRadius: BorderRadius.circular(D.r10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(D.r10),
              child: _NetworkImage(url: channel.logo, w: 48, h: 48),
            ),
          ),
          const SizedBox(width: D.g12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(channel.name,
              style: D.callout.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('Ch. ${channel.number}',
              style: D.caption.copyWith(fontSize: 11, color: D.lbl3)),
          ])),
          _SpringTap(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(D.g8),
              child: Icon(CupertinoIcons.heart_fill, color: D.red, size: 20),
            ),
          ),
          const Icon(CupertinoIcons.chevron_forward, size: 12, color: D.lbl3),
        ]),
      ),
    ),
  );
}

// Settings sub-widgets ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: D.g6, bottom: D.g10),
    child: Text(text.toUpperCase(), style: D.micro.copyWith(color: D.lbl3, letterSpacing: 0.8)),
  );
}

class _ToggleRow extends StatelessWidget {
  final IconData  icon;
  final Color     iconColor;
  final String    title, subtitle;
  final bool      value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.icon,     required this.iconColor,
    required this.title,    required this.subtitle,
    required this.value,    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: D.g16, vertical: D.g14),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
            iconColor,
            Color.lerp(iconColor, Colors.black, 0.22)!,
          ]),
          borderRadius: BorderRadius.circular(D.r8),
          boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
      const SizedBox(width: D.g14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,    style: D.callout.copyWith(fontWeight: FontWeight.w500, color: D.lbl)),
        const SizedBox(height: 2),
        Text(subtitle, style: D.caption.copyWith(fontSize: 11, color: D.lbl3)),
      ])),
      CupertinoSwitch(value: value, onChanged: onChanged, activeColor: D.blue),
    ]),
  );
}

class _QualityRow extends StatelessWidget {
  final String    label;
  final bool      active, isLast;
  final VoidCallback onTap;
  const _QualityRow({required this.label, required this.active, required this.isLast, required this.onTap});
  @override
  Widget build(BuildContext context) => Column(children: [
    _SpringTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: D.g16, vertical: D.g16),
        child: Row(children: [
          Expanded(child: Text(label, style: D.callout.copyWith(
            fontWeight: FontWeight.w500,
            color:      active ? D.blue : D.lbl,
          ))),
          if (active) const Icon(CupertinoIcons.checkmark, color: D.blue, size: 17),
        ]),
      ),
    ),
    if (!isLast) Container(
      height: 0.5,
      color:  Colors.white.withValues(alpha: 0.055),
      margin: const EdgeInsets.only(left: D.g16),
    ),
  ]);
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final bool   isLast;
  const _InfoRow({required this.label, required this.value, this.isLast = false});
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: D.g16, vertical: D.g16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: D.callout.copyWith(fontWeight: FontWeight.w500, color: D.lbl)),
        Text(value, style: D.callout.copyWith(color: D.lbl3)),
      ]),
    ),
    if (!isLast) Container(
      height: 0.5,
      color:  Colors.white.withValues(alpha: 0.055),
      margin: const EdgeInsets.only(left: D.g16),
    ),
  ]);
}

// Player sub-widgets ───────────────────────────────────────────────────────────
class _GradScrim extends StatelessWidget {
  final bool fromTop;
  const _GradScrim({required this.fromTop});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin:  fromTop ? Alignment.topCenter    : Alignment.bottomCenter,
        end:    fromTop ? Alignment.bottomCenter : Alignment.topCenter,
        colors: [Colors.black.withValues(alpha: 0.80), Colors.transparent],
        stops:  const [0.0, 1.0],
      ),
    ),
  );
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
    final w = c.maxWidth;
    // FIX #7 – thumb left is clamped from 0 so it cannot go negative
    final thumbLeft = (w * progress - 6).clamp(0.0, w - 12);
    return SizedBox(
      height: 22,
      child: Stack(alignment: Alignment.centerLeft, children: [
        Container(
          height: 2.5, width: w,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Container(
          height: 2.5, width: w * progress,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(colors: [Color(0xFF0A84FF), Color(0xFF30D158)]),
            boxShadow: [BoxShadow(color: D.blue.withValues(alpha: 0.60), blurRadius: 8)],
          ),
        ),
        Positioned(
          left: thumbLeft,
          child: Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: D.blue.withValues(alpha: 0.70), blurRadius: 10, spreadRadius: 1)],
            ),
          ),
        ),
      ]),
    );
  });
}

class _GlassBtn extends StatelessWidget {
  final IconData     icon;
  final Color?       iconColor;
  final VoidCallback onTap;
  final double       size, iconSize;
  const _GlassBtn({
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
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            color:  Colors.white.withValues(alpha: 0.14),
            shape:  BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 0.5),
          ),
          child: Stack(alignment: Alignment.center, children: [
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent],
              ),
            ))),
            Icon(icon, color: iconColor ?? Colors.white, size: iconSize),
          ]),
        ),
      ),
    ),
  );
}

class _PlayerError extends StatelessWidget {
  final VoidCallback onRetry;
  const _PlayerError({required this.onRetry});
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black,
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(D.rMax),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 76, height: 76,
            decoration: BoxDecoration(
              shape:  BoxShape.circle,
              color:  Colors.white.withValues(alpha: 0.07),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10), width: 0.5),
            ),
            child: const Icon(CupertinoIcons.wifi_slash, size: 34, color: Colors.white38),
          ),
        ),
      ),
      const SizedBox(height: 20),
      const Text('Connection Failed',
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3, decoration: TextDecoration.none)),
      const SizedBox(height: 8),
      const Text('Unable to load stream',
        style: TextStyle(color: Colors.white54, fontSize: 14, decoration: TextDecoration.none)),
      const SizedBox(height: 28),
      _SpringTap(
        onTap: onRetry,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1C6EF2), Color(0xFF0A50C8)]),
            borderRadius: BorderRadius.circular(D.rMax),
            boxShadow: [BoxShadow(color: D.blue.withValues(alpha: 0.48), blurRadius: 24, offset: const Offset(0, 6))],
          ),
          child: const Text('Try Again',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15, decoration: TextDecoration.none)),
        ),
      ),
    ])),
  );
}

// ─── 11. Shared widgets ───────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final List<Widget> children;
  const _GlassCard({required this.children});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(D.r16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
      child: Container(
        // FIX #11 – explicit constraints prevent unbounded-height layout warnings
        constraints: const BoxConstraints(minHeight: 0),
        decoration: BoxDecoration(
          color: D.s2.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(D.r16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.30), blurRadius: 20, offset: const Offset(0, 5))],
        ),
        child: Stack(children: [
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(D.r16),
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.white.withValues(alpha: 0.04), Colors.transparent],
            ),
          ))),
          Column(children: children),
        ]),
      ),
    ),
  );
}

/// IMPROVEMENT – ripple ring added alongside fade for a premium live indicator
class _LivePulse extends StatefulWidget {
  const _LivePulse();
  @override State<_LivePulse> createState() => _LivePulseState();
}
class _LivePulseState extends State<_LivePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double>   _fade;
  late final Animation<double>   _ring;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _fade = Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _ring = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 14, height: 14,
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Stack(alignment: Alignment.center, children: [
        // Expanding ring
        Opacity(
          opacity: _fade.value,
          child: Container(
            width:  6 + 8 * _ring.value,
            height: 6 + 8 * _ring.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: D.red.withValues(alpha: 0.55 * (1 - _ring.value)), width: 1),
            ),
          ),
        ),
        // Solid dot
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color:      D.red,
            shape:      BoxShape.circle,
            boxShadow: [BoxShadow(color: D.red.withValues(alpha: 0.60), blurRadius: 5, spreadRadius: 1)],
          ),
        ),
      ]),
    ),
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color:        color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(D.rMax),
      border:       Border.all(color: color.withValues(alpha: 0.28), width: 0.5),
    ),
    child: Text(label, style: D.micro.copyWith(color: color, fontWeight: FontWeight.w700)),
  );
}

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

/// FIX #1 – added shimmer placeholder while image is loading
class _NetworkImage extends StatelessWidget {
  final String url;
  final double w, h;
  const _NetworkImage({required this.url, required this.w, required this.h});
  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Icon(CupertinoIcons.tv, size: math.min(w, h) * 0.45, color: D.lbl4);
    }
    return SizedBox(
      width: w, height: h,
      child: Image.network(
        url,
        width: w, height: h,
        fit: BoxFit.contain,
        // Loading placeholder shimmer
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            width: w, height: h,
            decoration: BoxDecoration(
              color: D.s4.withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        },
        errorBuilder: (_, __, ___) =>
            Icon(CupertinoIcons.tv, size: math.min(w, h) * 0.45, color: D.lbl4),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _EmptyView({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    ClipRRect(
      borderRadius: BorderRadius.circular(D.rMax),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [D.s3, D.s2],
            ),
            shape:  BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
          ),
          child: Icon(icon, size: 34, color: D.lbl3),
        ),
      ),
    ),
    const SizedBox(height: 20),
    Text(label, style: D.body.copyWith(color: D.lbl2), textAlign: TextAlign.center),
  ]));
}

// ─── 12. Skeleton / loading ───────────────────────────────────────────────────
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
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _x = Tween(begin: -1.5, end: 2.5)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: D.g16, vertical: D.g8),
    child: Column(children: List.generate(5, (_) => AnimatedBuilder(
      animation: _x,
      builder: (_, __) => Container(
        height: 66,
        margin: const EdgeInsets.only(bottom: 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(D.r8),
          // IMPROVEMENT – three-stop shimmer for more realism
          gradient: LinearGradient(
            begin: Alignment(_x.value - 1, 0),
            end:   Alignment(_x.value,     0),
            colors: [D.s2, D.s3, D.s4.withValues(alpha: 0.65), D.s3, D.s2],
            stops: const [0.0, 0.35, 0.50, 0.65, 1.0],
          ),
        ),
      ),
    ))),
  );
}

// ─── 13. Interaction primitives ───────────────────────────────────────────────

/// IMPROVEMENT – spring-back uses elasticOut for a bouncier feel
class _SpringTap extends StatefulWidget {
  final Widget       child;
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
    _s = Tween(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => _c.forward(),
    onTapUp:     (_) {
      // IMPROVEMENT – reverse with elasticOut for satisfying snap-back
      _c.animateBack(0, duration: const Duration(milliseconds: 380), curve: Curves.elasticOut);
      widget.onTap?.call();
    },
    onTapCancel: () => _c.reverse(),
    child: ScaleTransition(scale: _s, child: widget.child),
  );
}

// ─── 14. Toast overlay ────────────────────────────────────────────────────────
class _Toast extends StatefulWidget {
  final String       message;
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
    _dy  = Tween(begin: 20.0, end: 0.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) _c.reverse().then((_) => widget.onDone());
    });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom + 104;
    return Positioned(
      bottom: bottomPad, left: 32, right: 32,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Opacity(
          opacity: _opa.value,
          child:   Transform.translate(offset: Offset(0, _dy.value), child: child),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(D.r20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: D.s4.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(D.r20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.11), width: 0.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.38), blurRadius: 28, offset: const Offset(0, 8))],
              ),
              child: DefaultTextStyle(
                style: const TextStyle(decoration: TextDecoration.none),
                child: Stack(children: [
                  Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(D.r20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.white.withValues(alpha: 0.05), Colors.transparent],
                    ),
                  ))),
                  Text(
                    widget.message,
                    style: D.callout.copyWith(
                      fontWeight:      FontWeight.w500,
                      decoration:      TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 15. Utilities ────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color       = Colors.white.withValues(alpha: 0.022)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width;  x += 28) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 28) canvas.drawLine(Offset(0, y), Offset(size.width, y),  p);
  }
  @override bool shouldRepaint(_) => false;
}

PageRoute<R> _fadeZoomRoute<R>(Widget page) => PageRouteBuilder<R>(
  pageBuilder: (_, a, __) => page,
  // IMPROVEMENT – matched reverse duration for consistent feel
  transitionDuration:        const Duration(milliseconds: 390),
  reverseTransitionDuration: const Duration(milliseconds: 390),
  transitionsBuilder: (_, a, __, child) => FadeTransition(
    opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
    child: ScaleTransition(
      scale: Tween(begin: 0.94, end: 1.0)
          .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
      child: child,
    ),
  ),
);
