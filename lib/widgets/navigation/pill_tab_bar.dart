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
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (dark ? AppColors.surfaceGlass : Colors.white).withOpacity(dark ? 0.90 : 0.88),
                      (dark ? AppColors.surfaceElevated : Colors.white).withOpacity(dark ? 0.94 : 0.96),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: dark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.70),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(dark ? 0.30 : 0.10),
                      blurRadius: 34,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(dark ? 0.04 : 0.30),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary.withOpacity(dark ? 0.24 : 0.20),
                                AppColors.primarySoft.withOpacity(dark ? 0.18 : 0.12),
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(dark ? 0.28 : 0.20),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(dark ? 0.12 : 0.08),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
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
                                scale: active ? 1.1 : 0.95,
                                child: Icon(
                                  icon,
                                  size: 22,
                                  color: active
                                      ? Colors.white
                                      : AppColors.textSecondary.withOpacity(dark ? 0.92 : 0.78),
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
