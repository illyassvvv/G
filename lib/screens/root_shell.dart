import 'package:flutter/material.dart';
import '../core/motion.dart';
import '../screens/favorites_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/matches/matches_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/navigation/pill_tab_bar.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  late final PageController _pageController = PageController(initialPage: 0);

  static const _pageCount = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTap(int i) {
    if (_index == i) return;
    setState(() => _index = i);
    _pageController.animateToPage(
      i,
      duration: Motion.normal,
      curve: Motion.emphasized,
    );
  }

  void _onPageChanged(int i) {
    if (_index == i) return;
    setState(() => _index = i);
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const MatchesScreen();
      case 2:
        return const FavoritesScreen();
      case 3:
      default:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        allowImplicitScrolling: true,
        itemCount: _pageCount,
        itemBuilder: (_, index) => _buildPage(index),
      ),
      bottomNavigationBar: SafeArea(
        child: PillTabBar(
          currentIndex: _index,
          onTap: _onTabTap,
        ),
      ),
    );
  }
}
