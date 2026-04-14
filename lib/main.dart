import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const StreamGoApp());
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

  // Map JSON icon string → Flutter IconData
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

// ─────────────────────────────────────────
//  Remote Data Service
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

// ─────────────────────────────────────────
//  Home Screen
// ─────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Async state
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ChannelService.fetchCategories();
  }

  // Pull-to-refresh
  void _reload() {
    setState(() {
      _categoriesFuture = ChannelService.fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Scrollable content ──
          RefreshIndicator(
            onRefresh: () async => _reload(),
            color: Colors.blueAccent,
            backgroundColor: const Color(0xFF121212),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroSection(),
                  const SizedBox(height: 20),
                  // ── FutureBuilder for dynamic channel list ──
                  FutureBuilder<List<Category>>(
                    future: _categoriesFuture,
                    builder: (context, snapshot) {
                      // Loading state
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingState();
                      }
                      // Error state
                      if (snapshot.hasError) {
                        return _buildErrorState(snapshot.error.toString());
                      }
                      // Success state
                      final categories = snapshot.data!;
                      return Column(
                        children: categories
                            .map((cat) => _buildCategoryRow(cat))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Header overlay ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildHeader(),
          ),

          // ── Bottom navigation ──
          Positioned(
            bottom: 24, left: 16, right: 16,
            child: _buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  // ── Loading shimmer-style placeholder ──
  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(2, (_) => _shimmerRow()),
      ),
    );
  }

  Widget _shimmerRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category title placeholder
          Container(
            width: 120,
            height: 16,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (_, __) => Container(
                width: 110,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ──
  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'تعذّر تحميل القنوات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF050505).withValues(alpha: 0.9),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
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
                child: const Icon(Icons.flash_on, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                "STREAM",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
              const Text(
                "GO",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.blueAccent),
              ),
            ],
          ),
          // Actions
          Row(
            children: [
              // Reload button
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _reload,
                tooltip: 'تحديث القنوات',
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {},
              ),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  image: const DecorationImage(
                    image: NetworkImage("https://api.dicebear.com/7.x/avataaars/png?seed=Mia"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Hero Banner ──
  Widget _buildHeroSection() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            "https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&q=80&w=2000",
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.3),
            colorBlendMode: BlendMode.darken,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF050505),
                  const Color(0xFF050505).withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24, left: 24, right: 24,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text("LIVE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    const Text("الدوري الإنجليزي الممتاز", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "مانشستر سيتي\nضد ليفربول",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.2),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("شاهد الآن", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.play_arrow, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Category Row ──
  Widget _buildCategoryRow(Category category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  category.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Icon(category.icon, size: 16, color: Colors.blueAccent),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: category.channels.length,
              itemBuilder: (context, index) {
                return ChannelCardWidget(channel: category.channels[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation ──
  Widget _buildBottomNavigation() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: const Color(0xFF121212).withValues(alpha: 0.8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(Icons.home_filled, "الرئيسية", 0),
              _navItem(Icons.tv, "القنوات", 1),
              _navItem(Icons.star_border, "المفضلة", 2),
              _navItem(Icons.person_outline, "حسابي", 3),
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
          Icon(icon, color: isActive ? Colors.blueAccent : Colors.grey, size: 26),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.blueAccent : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Channel Card Widget
// ─────────────────────────────────────────
class ChannelCardWidget extends StatefulWidget {
  final Channel channel;
  const ChannelCardWidget({super.key, required this.channel});

  @override
  State<ChannelCardWidget> createState() => _ChannelCardWidgetState();
}

class _ChannelCardWidgetState extends State<ChannelCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(channel: widget.channel),
          ),
        );
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Container(
          width: 110,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Channel number badge
                      Positioned(
                        top: 6, right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.channel.number,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Channel logo
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Image.network(
                            widget.channel.logo,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.tv,
                              color: Colors.white24,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.channel.name,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Video Player Screen
// ─────────────────────────────────────────
class VideoPlayerScreen extends StatelessWidget {
  final Channel channel;
  const VideoPlayerScreen({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(channel.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_outline, size: 80, color: Colors.white54),
            const SizedBox(height: 16),
            const Text(
              "جاري تحميل البث...",
              style: TextStyle(color: Colors.blueAccent),
            ),
            const SizedBox(height: 8),
            // Show stream URL for debugging
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                channel.streamUrl,
                style: const TextStyle(color: Colors.white24, fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // TODO: Replace with real player, e.g.:
            // Chewie(controller: chewieController)
          ],
        ),
      ),
    );
  }
}
