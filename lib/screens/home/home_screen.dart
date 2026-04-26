import 'package:flutter/material.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../models/channel_category.dart';
import '../../models/match.dart';
import '../../services/api_service.dart';
import '../../services/favorites_service.dart';
import '../../widgets/app_backdrop.dart';
import '../../widgets/premium_surface.dart';
import '../../widgets/slide_fade_transition.dart';
import 'channel_group_row.dart';
import 'featured_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin<HomeScreen> {
  List<ChannelCategory> _categories = [];
  List<Match> _matches = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = dark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final textPrimary = dark ? AppColors.textPrimary : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('StreamGo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // Implementation of a simple search toggle or focus
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppBackdrop(
        child: AnimatedSwitcher(
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
                            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.textSecondary),
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
                              style: TextStyle(
                                color: textSecondary,
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
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView(
                        key: const ValueKey('content'),
                        padding: const EdgeInsets.only(bottom: 26),
                        children: [
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: PremiumSurface(
                              borderRadius: BorderRadius.circular(20),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) => setState(() => _searchQuery = v),
                                decoration: InputDecoration(
                                  hintText: 'Search channels...',
                                  hintStyle: TextStyle(color: textSecondary.withOpacity(0.5)),
                                  prefixIcon: Icon(Icons.search_rounded, color: textSecondary.withOpacity(0.5), size: 20),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                style: TextStyle(color: textPrimary, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_searchQuery.isEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Today’s Spotlight',
                                        style: TextStyle(
                                          color: textSecondary.withOpacity(0.72),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.9,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Live sports & premium TV',
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                              color: textPrimary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const _LivePill(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SlideFade(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: FeaturedCard(match: featured),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Text(
                                  'Channels by category',
                                  style: TextStyle(
                                    color: textSecondary.withOpacity(0.72),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.9,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_categories.length} groups',
                                  style: TextStyle(
                                    color: textSecondary.withOpacity(0.58),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._categories.asMap().entries.map(
                            (entry) => SlideFade(
                              delay: Duration(milliseconds: 40 + (entry.key * 45)),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: ChannelGroupRow(
                                  title: entry.value.name,
                                  channels: entry.value.channels,
                                ),
                              ),
                            ),
                          ),
                          ] else ...[
                            ..._categories.map((cat) {
                              final filtered = cat.channels.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                              if (filtered.isEmpty) return const SizedBox.shrink();
                              return SlideFade(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: ChannelGroupRow(
                                    title: cat.name,
                                    channels: filtered,
                                  ),
                                ),
                              );
                            }),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      borderRadius: BorderRadius.circular(999),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      glass: true,
      blur: 14,
      overlayColor: AppColors.live.withOpacity(0.12),
      borderColor: AppColors.live.withOpacity(0.24),
      shadows: [
        BoxShadow(
          color: AppColors.live.withOpacity(0.10),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: AppColors.live),
          SizedBox(width: 8),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}
