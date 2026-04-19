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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemWidth = width / _items.length;
          return ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.82),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: Motion.normal,
                      curve: Motion.emphasized,
                      left: currentIndex * itemWidth,
                      top: 5,
                      bottom: 5,
                      width: itemWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(23),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.28),
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
                                scale: active ? 1.08 : 0.94,
                                child: Icon(
                                  icon,
                                  size: 20,
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
