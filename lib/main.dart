import 'dart:convert';
import 'dart:ui';
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
  runApp(const StreamGoApp());
}

// ─────────────────────────────────────────
//  Favorites Manager (SharedPreferences)
// ─────────────────────────────────────────
class FavoritesManager {
  static const _key = 'favorite_channel_ids';

  static Future<Set<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((e) => int.tryParse(e) ?? -1).toSet();
  }

  static Future<void> save(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.map((e) => e.toString()).toList());
  }

  static Future<bool> toggle(int id) async {
    final favs = await load();
    if (favs.contains(id)) {
      favs.remove(id);
    } else {
      favs.add(id);
    }
    await save(favs);
    return favs.contains(id);
  }
}

// ─────────────────────────────────────────
//  Settings Manager
// ─────────────────────────────────────────
class AppSettings {
  bool arabicInterface;
  bool autoPlay;
  bool showMatchScores;
  String videoQuality; // 'auto', 'hd', 'sd'

  AppSettings({
    this.arabicInterface = true,
    this.autoPlay = true,
    this.showMatchScores = true,
    this.videoQuality = 'auto',
  });

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      arabicInterface: prefs.getBool('arabic_interface') ?? true,
      autoPlay: prefs.getBool('auto_play') ?? true,
      showMatchScores: prefs.getBool('show_match_scores') ?? true,
      videoQuality: prefs.getString('video_quality') ?? 'auto',
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('arabic_interface', arabicInterface);
    await prefs.setBool('auto_play', autoPlay);
    await prefs.setBool('show_match_scores', showMatchScores);
    await prefs.setString('video_quality', videoQuality);
  }
}

// ─────────────────────────────────────────
//  Models
// ─────────────────────────────────────────
class Channel {
  final int id;
  final String name;
  final String number;
  final String logo;
  final String streamUrl;

  const Channel({
    required this.id,
    required this.name,
    required this.number,
    required this.logo,
    required this.streamUrl,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        id: json['id'] as int,
        name: json['name'] as String,
        number: json['number']?.toString() ?? '',
        logo: json['logo'] as String? ?? '',
        streamUrl: json['stream'] as String? ?? '',
      );
}

class Category {
  final String name;
  final IconData icon;
  final List<Channel> channels;

  const Category({
    required this.name,
    required this.icon,
    required this.channels,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        name: json['name'] as String,
        icon: _iconFromString(json['icon'] as String? ?? 'tv'),
        channels: (json['channels'] as List<dynamic>)
            .map((c) => Channel.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  static IconData _iconFromString(String name) {
    const map = <String, IconData>{
      'sports_soccer': Icons.sports_soccer,
      'sports': Icons.sports,
      'tv': Icons.tv,
      'movie': Icons.movie,
      'star': Icons.star,
      'flash_on': Icons.flash_on,
    };
    return map[name] ?? Icons.tv;
  }
}

class Match {
  final String id;
  final String league;
  final String leagueEn;
  final String leagueLogo;
  final String home;
  final String homeEn;
  final String homeLogo;
  final String away;
  final String awayEn;
  final String awayLogo;
  final String score;
  final String date;
  final String time;
  final int status; // 1 = live, 0 = scheduled, etc.
  final bool hasChannels;

  const Match({
    required this.id,
    required this.league,
    required this.leagueEn,
    required this.leagueLogo,
    required this.home,
    required this.homeEn,
    required this.homeLogo,
    required this.away,
    required this.awayEn,
    required this.awayLogo,
    required this.score,
    required this.date,
    required this.time,
    required this.status,
    required this.hasChannels,
  });

  factory Match.fromJson(Map<String, dynamic> json) => Match(
        id: json['id']?.toString() ?? '',
        league: json['league'] as String? ?? '',
        leagueEn: json['league_en'] as String? ?? '',
        leagueLogo: json['league_logo'] as String? ?? '',
        home: json['home'] as String? ?? '',
        homeEn: json['home_en'] as String? ?? '',
        homeLogo: json['home_logo'] as String? ?? '',
        away: json['away'] as String? ?? '',
        awayEn: json['away_en'] as String? ?? '',
        awayLogo: json['away_logo'] as String? ?? '',
        score: json['score'] as String? ?? '0 - 0',
        date: json['date'] as String? ?? '',
        time: json['time'] as String? ?? '',
        status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
        hasChannels: (json['has_channels']?.toString() ?? '0') == '1',
      );

  bool get isLive => status == 1;

  String get homeLogoUrl =>
      'https://img.kora-api.space/uploads/team/$homeLogo';
  String get awayLogoUrl =>
      'https://img.kora-api.space/uploads/team/$awayLogo';
}

// ─────────────────────────────────────────
//  Data Services
// ─────────────────────────────────────────
class ChannelService {
  static const String _url =
      'https://raw.githubusercontent.com/illyassvvv/G/refs/heads/main/channels.json';

  static Future<List<Category>> fetchCategories() async {
    final response = await http.get(Uri.parse(_url));
    if (response.statusCode != 200) {
      throw Exception('فشل تحميل القنوات (${response.statusCode})');
    }
    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> cats = body['categories'] as List<dynamic>;
    return cats
        .map((c) => Category.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}

class MatchService {
  static Future<List<Match>> fetchMatches(String date) async {
    final url = 'https://ws.kora-api.space/api/matches/$date/1';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('فشل تحميل المباريات (${response.statusCode})');
    }
    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> matches = body['matches'] as List<dynamic>? ?? [];
    return matches
        .map((m) => Match.fromJson(m as Map<String, dynamic>))
        .toList();
  }
}

// ─────────────────────────────────────────
//  App Root
// ─────────────────────────────────────────
class StreamGoApp extends StatelessWidget {
  const StreamGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreamGo TV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
        fontFamily: 'Tahoma',
        primaryColor: Colors.blueAccent,
      ),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: const HomeScreen(),
    );
  }
}

// ─────────────────────────────────────────
//  Home Screen (Shell with bottom nav)
// ─────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late Future<List<Category>> _categoriesFuture;
  late Future<List<Match>> _matchesFuture;
  Set<int> _favoriteIds = {};
  AppSettings _settings = AppSettings();
  List<Channel> _allChannels = [];

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ChannelService.fetchCategories();
    _matchesFuture = MatchService.fetchMatches(_todayDate());
    _loadFavorites();
    _loadSettings();
  }

  String _todayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadFavorites() async {
    final favs = await FavoritesManager.load();
    if (mounted) setState(() => _favoriteIds = favs);
  }

  Future<void> _loadSettings() async {
    final s = await AppSettings.load();
    if (mounted) setState(() => _settings = s);
  }

  void _reload() {
    setState(() {
      _categoriesFuture = ChannelService.fetchCategories();
      _matchesFuture = MatchService.fetchMatches(_todayDate());
    });
  }

  Future<void> _toggleFavorite(int channelId) async {
    final isFav = await FavoritesManager.toggle(channelId);
    if (mounted) {
      setState(() {
        if (isFav) {
          _favoriteIds.add(channelId);
        } else {
          _favoriteIds.remove(channelId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Main Content ──
          IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeTab(),
              _buildChannelsTab(),
              _buildFavoritesTab(),
              _buildMatchesTab(),
              _buildSettingsTab(),
            ],
          ),

          // ── Bottom navigation ──
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: _buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  // ── TAB 0: Home ──
  Widget _buildHomeTab() {
    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        final categories = snapshot.data!;
        _allChannels = categories.expand((c) => c.channels).toList();
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          color: Colors.blueAccent,
          backgroundColor: const Color(0xFF121212),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildHeroSection(categories),
                const SizedBox(height: 12),
                ...categories.map((cat) => _buildCategoryRow(cat)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── TAB 1: Channels (all channels flat list) ──
  Widget _buildChannelsTab() {
    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        final categories = snapshot.data!;
        _allChannels = categories.expand((c) => c.channels).toList();
        return Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 100, top: 8),
                itemCount: _allChannels.length,
                itemBuilder: (context, index) {
                  final ch = _allChannels[index];
                  return _buildChannelListTile(ch);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChannelListTile(Channel ch) {
    final isFav = _favoriteIds.contains(ch.id);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ch.logo.isNotEmpty
              ? Image.network(ch.logo, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.tv, color: Colors.white24))
              : const Icon(Icons.tv, color: Colors.white24),
        ),
      ),
      title: Text(ch.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text('قناة ${ch.number}',
          style: const TextStyle(color: Colors.white38, fontSize: 11)),
      trailing: IconButton(
        icon: Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          color: isFav ? Colors.redAccent : Colors.white38,
          size: 22,
        ),
        onPressed: () => _toggleFavorite(ch.id),
      ),
      onTap: () => _openPlayer(ch),
    );
  }

  // ── TAB 2: Favorites ──
  Widget _buildFavoritesTab() {
    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        final allChannels = snapshot.data?.expand((c) => c.channels).toList() ?? [];
        final favChannels =
            allChannels.where((ch) => _favoriteIds.contains(ch.id)).toList();

        return Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'المفضلة (${favChannels.length})',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: favChannels.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          const Text('لا توجد قنوات مفضلة',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 16)),
                          const SizedBox(height: 8),
                          const Text('اضغط على ❤ في أي قناة لإضافتها',
                              style: TextStyle(
                                  color: Colors.white24, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: favChannels.length,
                      itemBuilder: (context, index) =>
                          _buildChannelListTile(favChannels[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  // ── TAB 3: Matches ──
  Widget _buildMatchesTab() {
    return Column(
      children: [
        _buildHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              const Icon(Icons.sports_soccer,
                  color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              const Text('مباريات اليوم',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              GestureDetector(
                onTap: _reload,
                child: const Icon(Icons.refresh, color: Colors.white54, size: 20),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Match>>(
            future: _matchesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 48, color: Colors.white24),
                      const SizedBox(height: 12),
                      const Text('تعذّر تحميل المباريات',
                          style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _reload,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }
              final matches = snapshot.data!;
              if (matches.isEmpty) {
                return const Center(
                  child: Text('لا توجد مباريات اليوم',
                      style: TextStyle(color: Colors.white38)),
                );
              }
              // Group by league
              final Map<String, List<Match>> grouped = {};
              for (final m in matches) {
                grouped.putIfAbsent(m.league, () => []).add(m);
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: grouped.keys.length,
                itemBuilder: (context, i) {
                  final league = grouped.keys.elementAt(i);
                  final leagueMatches = grouped[league]!;
                  return _buildLeagueSection(league, leagueMatches);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeagueSection(String league, List<Match> matches) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 4, height: 16,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(league,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          ...matches.map((m) => _buildMatchCard(m)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: match.isLive
              ? Colors.redAccent.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          // Home team
          Expanded(
            child: Column(
              children: [
                _teamLogo(match.homeLogoUrl),
                const SizedBox(height: 6),
                Text(match.home,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // Score / Time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                if (match.isLive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('LIVE',
                        style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(height: 4),
                Text(
                  match.isLive ? match.score : match.time,
                  style: TextStyle(
                    fontSize: match.isLive ? 20 : 14,
                    fontWeight: FontWeight.w900,
                    color: match.isLive ? Colors.white : Colors.white70,
                  ),
                ),
                if (!match.isLive)
                  Text(match.date,
                      style: const TextStyle(
                          fontSize: 9, color: Colors.white38)),
                if (match.hasChannels) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _showMatchChannels(match),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('شاهد',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Away team
          Expanded(
            child: Column(
              children: [
                _teamLogo(match.awayLogoUrl),
                const SizedBox(height: 6),
                Text(match.away,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamLogo(String url) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.sports_soccer, color: Colors.white24, size: 24),
        ),
      ),
    );
  }

  void _showMatchChannels(Match match) {
    // Navigate to channels tab and optionally filter
    setState(() => _selectedIndex = 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('اختر قناة لمشاهدة ${match.home} vs ${match.away}'),
        backgroundColor: Colors.blueAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── TAB 4: Settings ──
  Widget _buildSettingsTab() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('الإعدادات',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              _settingsTile(
                icon: Icons.play_circle_outline,
                title: 'تشغيل تلقائي',
                subtitle: 'تشغيل القناة عند الاختيار مباشرة',
                value: _settings.autoPlay,
                onChanged: (v) async {
                  setState(() => _settings.autoPlay = v);
                  await _settings.save();
                },
              ),
              _settingsTile(
                icon: Icons.scoreboard_outlined,
                title: 'عرض نتائج المباريات',
                subtitle: 'إظهار نتيجة المباراة في الواجهة',
                value: _settings.showMatchScores,
                onChanged: (v) async {
                  setState(() => _settings.showMatchScores = v);
                  await _settings.save();
                },
              ),
              const SizedBox(height: 16),
              _settingsSectionTitle('جودة الفيديو'),
              _qualityOption('auto', 'تلقائي'),
              _qualityOption('hd', 'عالية الجودة HD'),
              _qualityOption('sd', 'جودة عادية SD'),
              const SizedBox(height: 16),
              _settingsSectionTitle('حول التطبيق'),
              _infoTile('الإصدار', '2.0.0'),
              _infoTile('المطور', 'StreamGo Team'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.blueAccent, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blueAccent,
      ),
    );
  }

  Widget _settingsSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              fontSize: 13)),
    );
  }

  Widget _qualityOption(String value, String label) {
    final isSelected = _settings.videoQuality == value;
    return GestureDetector(
      onTap: () async {
        setState(() => _settings.videoQuality = value);
        await _settings.save();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent.withValues(alpha: 0.15)
              : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.blueAccent : Colors.white38,
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Open Player ──
  void _openPlayer(Channel channel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          channel: channel,
          isFavorite: _favoriteIds.contains(channel.id),
          onToggleFavorite: () => _toggleFavorite(channel.id),
          autoPlay: _settings.autoPlay,
        ),
      ),
    );
  }

  // ── Loading ──
  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('تعذّر تحميل البيانات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF050505).withValues(alpha: 0.95),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child:
                    const Icon(Icons.flash_on, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text('STREAM',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2)),
              const Text('GO',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.blueAccent)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _reload,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Hero Section (shows first live match or default) ──
  Widget _buildHeroSection(List<Category> categories) {
    return FutureBuilder<List<Match>>(
      future: _matchesFuture,
      builder: (context, snapshot) {
        Match? featuredMatch;
        if (snapshot.hasData) {
          final live =
              snapshot.data!.where((m) => m.isLive).toList();
          if (live.isNotEmpty) featuredMatch = live.first;
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&q=80&w=1200',
                    fit: BoxFit.cover,
                    color: Colors.black.withValues(alpha: 0.5),
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: featuredMatch != null
                    ? _heroMatchContent(featuredMatch)
                    : _heroDefaultContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _heroMatchContent(Match match) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('LIVE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Text(match.league,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _teamLogo(match.homeLogoUrl),
            const SizedBox(width: 12),
            Column(
              children: [
                Text(match.score,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900)),
                Text('${match.home} vs ${match.away}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11)),
              ],
            ),
            const SizedBox(width: 12),
            _teamLogo(match.awayLogoUrl),
          ],
        ),
        const Spacer(),
        if (match.hasChannels)
          ElevatedButton(
            onPressed: () => _showMatchChannels(match),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('شاهد الآن',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 6),
                Icon(Icons.play_arrow, size: 18),
              ],
            ),
          ),
      ],
    );
  }

  Widget _heroDefaultContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('LIVE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            const Text('البث المباشر',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const Spacer(),
        const Text('مشاهدة المباريات\nمباشرة الآن',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.3)),
        const Spacer(),
        ElevatedButton(
          onPressed: () => setState(() => _selectedIndex = 3),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('المباريات', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 6),
              Icon(Icons.sports_soccer, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  // ── Category Row ──
  Widget _buildCategoryRow(Category category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(category.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Icon(category.icon, size: 16, color: Colors.blueAccent),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 155,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: category.channels.length,
              itemBuilder: (context, index) {
                return _buildChannelCard(category.channels[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelCard(Channel ch) {
    final isFav = _favoriteIds.contains(ch.id);
    return GestureDetector(
      onTap: () => _openPlayer(ch),
      child: Container(
        width: 105,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Center(
                        child: ch.logo.isNotEmpty
                            ? Image.network(ch.logo,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.tv,
                                    color: Colors.white24,
                                    size: 36))
                            : const Icon(Icons.tv,
                                color: Colors.white24, size: 36),
                      ),
                    ),
                    // Fav button
                    Positioned(
                      top: 4, left: 4,
                      child: GestureDetector(
                        onTap: () => _toggleFavorite(ch.id),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.redAccent : Colors.white38,
                          size: 16,
                        ),
                      ),
                    ),
                    // Number badge
                    Positioned(
                      top: 4, right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(ch.number,
                            style: const TextStyle(
                                fontSize: 9,
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(ch.name,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ── Bottom Nav ──
  Widget _buildBottomNavigation() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFF121212).withValues(alpha: 0.9),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(Icons.home_filled, 'الرئيسية', 0),
              _navItem(Icons.tv, 'القنوات', 1),
              _navItem(Icons.favorite, 'المفضلة', 2),
              _navItem(Icons.sports_soccer, 'المباريات', 3),
              _navItem(Icons.settings, 'الإعدادات', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: isActive ? Colors.blueAccent : Colors.grey, size: 24),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: isActive ? Colors.blueAccent : Colors.grey,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Video Player Screen (Real HLS Player)
// ─────────────────────────────────────────
class VideoPlayerScreen extends StatefulWidget {
  final Channel channel;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final bool autoPlay;

  const VideoPlayerScreen({
    super.key,
    required this.channel,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.autoPlay = true,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isFavorite = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    if (widget.channel.streamUrl.isNotEmpty) {
      _initPlayer();
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'لا يوجد رابط بث لهذه القناة';
      });
    }
  }

  Future<void> _initPlayer() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final uri = Uri.parse(widget.channel.streamUrl);
      _videoController = VideoPlayerController.networkUrl(uri);

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: widget.autoPlay,
        looping: true,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                Text(errorMessage,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _retryPlayer,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        },
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _retryPlayer() {
    _disposePlayer();
    _initPlayer();
  }

  void _disposePlayer() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Player area ──
            AspectRatio(
              aspectRatio: isLandscape ? 16 / 9 : 16 / 9,
              child: Stack(
                children: [
                  // Video or placeholder
                  Container(
                    color: Colors.black,
                    child: _isLoading
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                    color: Colors.blueAccent),
                                SizedBox(height: 12),
                                Text('جاري تحميل البث...',
                                    style:
                                        TextStyle(color: Colors.blueAccent)),
                              ],
                            ),
                          )
                        : _hasError
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: Colors.redAccent, size: 48),
                                    const SizedBox(height: 12),
                                    const Text('تعذّر تحميل البث',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text(_errorMessage,
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 11),
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _retryPlayer,
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueAccent),
                                      child: const Text('إعادة المحاولة'),
                                    ),
                                  ],
                                ),
                              )
                            : _chewieController != null
                                ? Chewie(controller: _chewieController!)
                                : const SizedBox(),
                  ),
                  // Back button overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Channel Info ──
            if (!isLandscape) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    // Logo
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: widget.channel.logo.isNotEmpty
                            ? Image.network(widget.channel.logo,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.tv,
                                    color: Colors.white24))
                            : const Icon(Icons.tv, color: Colors.white24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.channel.name,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            widget.channel.streamUrl.isNotEmpty
                                ? 'بث مباشر 🔴'
                                : 'غير متاح',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Favorite toggle button
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.redAccent : Colors.white54,
                        size: 28,
                      ),
                      onPressed: () {
                        widget.onToggleFavorite();
                        setState(() => _isFavorite = !_isFavorite);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isFavorite
                                ? 'تمت إضافة القناة للمفضلة ❤'
                                : 'تم حذف القناة من المفضلة'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: _isFavorite
                                ? Colors.redAccent
                                : Colors.grey[800],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Divider(color: Colors.white12),
              ),
              // Stream URL info
              if (widget.channel.streamUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link,
                            color: Colors.blueAccent, size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.channel.streamUrl,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 10),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
