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
    reverseDuration: Motion.fast,
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
      behavior: HitTestBehavior.opaque,
      onTapDown: _onDown,
      onTapUp: _onUp,
      onTapCancel: _onCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          final t = _controller.value;
          return Transform.translate(
            offset: Offset(0, 1.5 * t),
            child: Transform.scale(
              scale: 1 - (t * 0.035),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
