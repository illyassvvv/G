import 'package:flutter/material.dart';
import '../core/motion.dart';

class NetworkImageWidget extends StatelessWidget {
  final String url;
  final double size;

  const NetworkImageWidget({
    super.key,
    required this.url,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Icon(Icons.tv, size: size * 0.6, color: Colors.grey);
    }

    // FIX: add fade-in animation on load for smooth appearance
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return AnimatedOpacity(
            opacity: 1,
            duration: Motion.normal,
            curve: Motion.fade,
            child: child,
          );
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: Motion.normal,
          curve: Motion.fade,
          child: child,
        );
      },
      errorBuilder: (_, __, ___) {
        return Icon(Icons.tv, size: size * 0.6, color: Colors.grey);
      },
    );
  }
}
