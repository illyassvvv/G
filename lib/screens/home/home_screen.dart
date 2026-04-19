import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/motion.dart';
import '../../models/match.dart';
import '../../models/channel_category.dart';
import '../../services/api_service.dart';
import '../../services/favorites_service.dart';
import '../../widgets/slide_fade_transition.dart';
import 'featured_card.dart';
import 'channel_group_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin<HomeScreen> {
  List<ChannelCategory> _categories = [];
  List<Match> _matches = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.fetchCategories(),
        ApiService.fetchMatches(),
      ]);

      final cats = results[0] as List<ChannelCategory>;
      final matches = results[1] as List<Match>;
      FavoritesService.registerChannels(cats.expand((c) => c.channels));

      if (!mounted) return;
      setState(() {
        _categories = cats;
        _matches = matches;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final featured = _matches.isNotEmpty ? _matches.first : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('StreamGo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AnimatedSwitcher(
        duration: Motion.normal,
        switchInCurve: Motion.emphasized,
        child: _loading
            ? const Center(
                key: ValueKey('loading'),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : _error != null
                ? Center(
                    key: const ValueKey('error'),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_rounded,
                              size: 56, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load home feed',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    key: const ValueKey('content'),
                    children: [
                      const SizedBox(height: 8),
                      SlideFade(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: FeaturedCard(match: featured, onTap: () {}),
                        ),
                      ),
                      const SizedBox(height: 28),
                      ..._categories.map(
                        (cat) => SlideFade(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ChannelGroupRow(
                              title: cat.name,
                              channels: cat.channels,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
      ),
    );
  }
}
