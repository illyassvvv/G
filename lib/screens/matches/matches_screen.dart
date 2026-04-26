import 'package:flutter/material.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../models/match.dart';
import '../../services/api_service.dart';
import '../../widgets/app_backdrop.dart';
import '../../widgets/premium_surface.dart';
import '../../widgets/slide_fade_transition.dart';
import 'match_row.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> with AutomaticKeepAliveClientMixin<MatchesScreen> {
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
    final textSecondary = dark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final textPrimary = dark ? AppColors.textPrimary : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Matches'),
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
                            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.textSecondary),
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
                              style: TextStyle(color: textSecondary, fontSize: 12),
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
                        key: const ValueKey('list'),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Upcoming & live',
                                      style: TextStyle(
                                        color: textSecondary.withOpacity(0.72),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.9,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Elegant match schedule',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: textPrimary,
                                          ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                PremiumSurface(
                                  borderRadius: BorderRadius.circular(999),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  glass: true,
                                  blur: 14,
                                  overlayColor: AppColors.primary.withOpacity(0.10),
                                  borderColor: AppColors.primary.withOpacity(0.20),
                                  child: Text(
                                    '${_matches.length} events',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ..._matches.asMap().entries.map(
                            (entry) => SlideFade(
                              delay: Duration(milliseconds: 35 + (entry.key * 42)),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: MatchRow(match: entry.value),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
