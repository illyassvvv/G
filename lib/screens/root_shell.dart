import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/matches/matches_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/navigation/pill_tab_bar.dart';
import '../core/motion.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  late final PageController _pageController = PageController(
    initialPage: 0,
    // keepPage ensures the page controller doesn't re-create pages on tab switch
    keepPage: true,
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Called by the pill tab bar
  void _onTabTap(int i) {
    if (_index == i) return;
    setState(() => _index = i);
    _pageController.animateToPage(
      i,
      // Smooth, snappy swipe — same curve as UI motion system
      duration: Motion.normal,
      curve: Motion.emphasized,
    );
  }

  // Called when user physically swipes the PageView
  void _onPageChanged(int i) {
    if (_index == i) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // PageView enables swipe-between-sections gesture
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        // physics: feel like native iOS — momentum + snapping
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: const [
          HomeScreen(),
          MatchesScreen(),
          FavoritesScreen(),
          SettingsScreen(),
        ],
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
