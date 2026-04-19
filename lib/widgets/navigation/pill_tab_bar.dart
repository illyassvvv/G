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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemWidth = width / _items.length;

          return ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: (dark ? AppColors.surfaceGlass : Colors.white)
                      .withOpacity(dark ? 0.88 : 0.82),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: dark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.55),
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
                                AppColors.primary.withOpacity(0.22),
                                AppColors.primary.withOpacity(0.14),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(_items.length, (index) {
                        final active = index == currentIndex;
                        final icon = active ? _activeItems[index] : _items[index];
                        return Expanded(
                          child: Pressable(
                            onTap: () => onTap(index),
                            child: Center(
                              child: AnimatedScale(
                                duration: Motion.fast,
                                curve: Motion.spring,
                                scale: active ? 1.08 : 0.96,
                                child: Icon(
                                  icon,
                                  size: 21,
                                  color: active
                                      ? Colors.white
                                      : AppColors.textSecondary,
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

const _items = [
  Icons.home_outlined,
  Icons.sports_soccer_outlined,
  Icons.favorite_border,
  Icons.settings_outlined,
];

const _activeItems = [
  Icons.home,
  Icons.sports_soccer,
  Icons.favorite,
  Icons.settings,
];
