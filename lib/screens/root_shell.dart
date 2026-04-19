import 'package:flutter/material.dart';
// FIX: was importing OLD duplicate screens — now using the refactored ones
import '../screens/home/home_screen.dart';
import '../screens/matches/matches_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/navigation/pill_tab_bar.dart'; // FIX: PillTabBar existed but was NEVER used

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _pages = const [
    HomeScreen(),
    MatchesScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  void _onTap(int i) {
    if (_index == i) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FIX: AnimatedSwitcher gives smooth fade between tabs instead of instant jump
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _pages[_index],
        ),
      ),
      // FIX: replaced stock NavigationBar with the custom PillTabBar that existed but was never used
      bottomNavigationBar: SafeArea(
        child: PillTabBar(
          currentIndex: _index,
          onTap: _onTap,
        ),
      ),
    );
  }
}
