import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/motion.dart';
import '../../models/match.dart';
import '../../models/channel_category.dart';
import '../../services/api_service.dart';
import '../../widgets/slide_fade_transition.dart';
import 'featured_card.dart';
import 'channel_group_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChannelCategory> _categories = [];
  List<Match> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await ApiService.fetchCategories();
    final matches = await ApiService.fetchMatches();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _matches = matches;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final featured = _matches.isNotEmpty ? _matches.first : null;

    return Scaffold(
      backgroundColor: AppColors.background,
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
            : ListView(
                key: const ValueKey('content'),
                children: [
                  const SizedBox(height: 8),

                  // Featured match hero card
                  SlideFade(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FeaturedCard(match: featured, onTap: () {}),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Each API category becomes its own labelled row ──
                  // e.g. "Bein Sports", "Al Kass", "MBC", ...
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
