import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/motion.dart';
import '../../models/channel.dart';
import '../../models/match.dart';
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
  List<Channel> _channels = [];
  List<Match> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final channels = await ApiService.fetchChannels();
    final matches = await ApiService.fetchMatches();

    if (!mounted) return;

    setState(() {
      _channels = channels;
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
                  // FIX: wrap content with SlideFade for smooth entrance animation
                  SlideFade(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FeaturedCard(
                        match: featured,
                        onTap: () {},
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SlideFade(
                    child: ChannelGroupRow(
                      title: 'Channels',
                      channels: _channels,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
      ),
    );
  }
}
