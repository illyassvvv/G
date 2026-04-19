import 'package:flutter/material.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../models/match.dart';
import '../../services/api_service.dart';
import '../../widgets/app_backdrop.dart';
import '../../widgets/slide_fade_transition.dart';
import 'match_row.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with AutomaticKeepAliveClientMixin<MatchesScreen> {
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
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data = await ApiService.fetchMatches();
      if (!mounted) return;
      setState(() {
        _matches = data;
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        dark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Matches'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackdrop(
        child: AnimatedSwitcher(
          duration: Motion.normal,
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
                              'Failed to load matches',
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
                      child: ListView.separated(
                        key: const ValueKey('list'),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _matches.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          return SlideFade(
                            delay: Duration(milliseconds: 35 + (i * 42)),
                            child: MatchRow(match: _matches[i]),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}
