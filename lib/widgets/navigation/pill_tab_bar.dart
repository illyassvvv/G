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
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_items.length, (index) {
          final active = index == currentIndex;

          return Expanded(
            child: Pressable(
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: Motion.normal,
                curve: Motion.emphasized,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: Motion.fast,
                      child: Icon(
                        active ? _activeItems[index] : _items[index],
                        key: ValueKey(active),
                        size: 20,
                        color: active ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
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
