import 'package:flutter/material.dart';
import '../core/motion.dart';

class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.fast,
  );

  void _onDown(TapDownDetails _) => _controller.forward();

  void _onUp(TapUpDetails _) {
    widget.onTap();
    _controller.reverse();
  }

  void _onCancel() => _controller.reverse();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onDown,
      onTapUp: _onUp,
      onTapCancel: _onCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          final scale = 1 - (_controller.value * 0.04);
          return Transform.scale(scale: scale, child: child);
        },
        child: widget.child,
      ),
    );
  }
}