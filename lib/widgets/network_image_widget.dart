import 'package:flutter/material.dart';

/// A fixed-size network image widget with:
/// - Reserved layout space (no jumps)
/// - Centered loading indicator during download
/// - 200ms fade-in on appearance (once only)
/// - Fallback icon on error
class NetworkImageWidget extends StatelessWidget {
  final String url;
  final double size;
  final IconData fallbackIcon;

  const NetworkImageWidget({
    super.key,
    required this.url,
    required this.size,
    this.fallbackIcon = Icons.tv,
  });

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1',
  };

  @override
  Widget build(BuildContext context) {
    // Always reserve the exact space — prevents layout jumps
    return SizedBox(
      width: size,
      height: size,
      child: url.isEmpty ? _fallback() : _image(),
    );
  }

  Widget _image() {
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      headers: _headers,
      // loadingBuilder: streams download progress — shows spinner while loading
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          // Download complete — fade in the image (once, no repeat)
          return _FadeIn(child: child);
        }
        // Still downloading — show centered spinner
        return Center(
          child: SizedBox(
            width: size * 0.35,
            height: size * 0.35,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.white.withOpacity(0.2),
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Center(
      child: Icon(
        fallbackIcon,
        size: size * 0.5,
        color: Colors.white.withOpacity(0.2),
      ),
    );
  }
}

/// One-shot 200ms fade-in. Uses TweenAnimationBuilder so it
/// only fires once per build — no repeated animations.
class _FadeIn extends StatelessWidget {
  final Widget child;
  const _FadeIn({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (_, value, __) => Opacity(opacity: value, child: child),
      child: child,
    );
  }
}
