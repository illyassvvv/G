import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/motion.dart';
import '../../models/match.dart';
import '../../services/api_service.dart';
import '../../widgets/slide_fade_transition.dart';
import 'match_row.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<Match> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ApiService.fetchMatches();
    if (!mounted) return;
    setState(() {
      _matches = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Matches'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AnimatedSwitcher(
        duration: Motion.normal,
        child: _loading
            ? const Center(
                key: ValueKey('loading'),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : ListView.separated(
                key: const ValueKey('list'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _matches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  return SlideFade(child: MatchRow(match: _matches[i]));
                },
              ),
      ),
    );
  }
}
