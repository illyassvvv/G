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
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: Motion.fast,
                    curve: Motion.curve,
                    width: width * value,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFDCE5FF)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
