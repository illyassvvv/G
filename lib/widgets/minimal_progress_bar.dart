import 'package:flutter/material.dart';
import '../core/motion.dart';

class MinimalProgressBar extends StatelessWidget {
  final double progress;

  const MinimalProgressBar({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (_, constraints) {
        final width = constraints.maxWidth;
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 4,
            width: width,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: Motion.fast,
                curve: Motion.curve,
                width: width * value,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFE6ECFF)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
