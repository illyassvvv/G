import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/motion.dart';
import '../pressable.dart';

class PillTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PillTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tabs = _items;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemWidth = width / tabs.length;

          return ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: (dark ? AppColors.surfaceGlass : Colors.white)
                      .withOpacity(dark ? 0.88 : 0.82),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: dark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(dark ? 0.26 : 0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: Motion.normal,
                      curve: Motion.emphasized,
                      left: currentIndex * itemWidth,
                      top: 6,
                      bottom: 6,
                      width: itemWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary.withOpacity(0.25),
                                AppColors.primary.withOpacity(0.14),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.28),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(tabs.length, (index) {
                        final active = index == currentIndex;
                        final item = tabs[index];
                        return Expanded(
                          child: Pressable(
                            onTap: () => onTap(index),
                            child: Center(
                              child: AnimatedScale(
                                duration: Motion.fast,
                                curve: Motion.spring,
                                scale: active ? 1.05 : 0.98,
                                child: AnimatedOpacity(
                                  opacity: active ? 1 : 0.76,
                                  duration: Motion.fast,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        active ? item.activeIcon : item.icon,
                                        size: 20,
                                        color: active ? Colors.white : AppColors.textSecondary,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.label,
                                        style: TextStyle(
                                          color: active ? Colors.white : AppColors.textSecondary,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _TabItem(this.label, this.icon, this.activeIcon);
}

const _items = [
  _TabItem('Home', Icons.home_outlined, Icons.home_rounded),
  _TabItem('Matches', Icons.sports_soccer_outlined, Icons.sports_soccer_rounded),
  _TabItem('Favorites', Icons.favorite_border_rounded, Icons.favorite_rounded),
  _TabItem('Settings', Icons.settings_outlined, Icons.settings_rounded),
];
