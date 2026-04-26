import 'package:flutter/material.dart';
import '../core/url_utils.dart';

/// Fixed-size network image widget with:
/// - reserved layout space
/// - centered loading indicator
/// - subtle fade-in
/// - fallback icon on error
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
    final uri = UrlUtils.tryParseNetworkUrl(url, allowHttp: true, allowHttps: true);
    if (uri == null) {
      return SizedBox(width: size, height: size, child: _fallback());
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheSide = (size * dpr).round().clamp(1, 1024);

    return SizedBox(
      width: size,
      height: size,
      child: Image.network(
        uri.toString(),
        width: size,
        height: size,
        fit: BoxFit.contain,
        headers: _headers,
        gaplessPlayback: true,
        cacheWidth: cacheSide,
        cacheHeight: cacheSide,
        filterQuality: FilterQuality.low,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return _FadeIn(child: child);
          }
          return Center(
            child: SizedBox(
              width: size * 0.35,
              height: size * 0.35,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.white.withOpacity(0.18),
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Center(
      child: Icon(
        fallbackIcon,
        size: size * 0.5,
        color: Colors.white.withOpacity(0.18),
      ),
    );
  }
}

class _FadeIn extends StatelessWidget {
  final Widget child;
  const _FadeIn({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (_, value, __) => Opacity(opacity: value, child: child),
      child: child,
    );
  }
}
