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

        return Container(
          height: 3,
          width: width,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            // FIX: was a static Container — now AnimatedContainer so it smoothly fills
            child: AnimatedContainer(
              duration: Motion.fast,
              curve: Motion.curve,
              width: width * value,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}
