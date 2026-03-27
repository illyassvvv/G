import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Resolves tokenized/redirect IPTV stream URLs to their final direct URLs.
///
/// Many IPTV providers use intermediate URLs that redirect through token
/// servers before reaching the actual .m3u8 stream. Android's ExoPlayer
/// (used by video_player) does not always follow these complex redirects.
/// This service manually follows all redirects to extract the final URL.
class StreamResolverService {
  static const _maxRedirects = 10;
  static const _timeout = Duration(seconds: 15);

  /// Browser-like headers to ensure redirects work like they do in a browser.
  static const _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 10; Android TV) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.9',
    'Connection': 'keep-alive',
  };

  /// Resolves the given [url] by following all HTTP redirects manually.
  /// Returns the final resolved URL and any cookies/headers needed for playback.
  ///
  /// If resolution fails, returns the original URL as a fallback so that
  /// the player can still attempt to play it directly.
  static Future<ResolvedStream> resolveStreamUrl(String url) async {
    debugPrint('[StreamResolver] Resolving: $url');

    // If it's already a direct m3u8 link with no token/redirect patterns,
    // skip resolution to avoid unnecessary network calls.
    if (_isLikelyDirectUrl(url)) {
      debugPrint('[StreamResolver] URL appears direct, skipping resolution');
      return ResolvedStream(url: url);
    }

    String currentUrl = url;
    final collectedHeaders = <String, String>{};
    final cookies = <String>[];

    try {
      for (int i = 0; i < _maxRedirects; i++) {
        debugPrint('[StreamResolver] Redirect #$i: $currentUrl');

        final request = http.Request('GET', Uri.parse(currentUrl));
        request.headers.addAll(_defaultHeaders);

        // Forward any collected cookies
        if (cookies.isNotEmpty) {
          request.headers['Cookie'] = cookies.join('; ');
        }

        // Use a client that does NOT follow redirects automatically
        final client = http.Client();
        try {
          final streamedResponse = await client.send(request).timeout(_timeout);
          final statusCode = streamedResponse.statusCode;

          // Collect any Set-Cookie headers
          final setCookie = streamedResponse.headers['set-cookie'];
          if (setCookie != null && setCookie.isNotEmpty) {
            cookies.add(setCookie.split(';').first);
          }

          // Check for redirect (3xx status codes)
          if (statusCode >= 300 && statusCode < 400) {
            final location = streamedResponse.headers['location'];
            if (location != null && location.isNotEmpty) {
              // Handle relative redirects
              if (location.startsWith('/')) {
                final uri = Uri.parse(currentUrl);
                currentUrl = '${uri.scheme}://${uri.host}$location';
              } else if (!location.startsWith('http')) {
                final uri = Uri.parse(currentUrl);
                final basePath = uri.path.substring(
                    0, uri.path.lastIndexOf('/') + 1);
                currentUrl = '${uri.scheme}://${uri.host}$basePath$location';
              } else {
                currentUrl = location;
              }
              continue;
            }
          }

          // If we get a 200, this is the final URL
          if (statusCode == 200) {
            // Check Content-Type or URL to see if we need to read body
            // for embedded redirect (some token servers return HTML/JS redirects)
            final contentType =
                streamedResponse.headers['content-type'] ?? '';

            if (contentType.contains('text/html') ||
                contentType.contains('text/plain')) {
              // Read the body to check for meta refresh or JS redirect
              final body = await streamedResponse.stream
                  .bytesToString()
                  .timeout(_timeout);
              final extractedUrl = _extractUrlFromBody(body);
              if (extractedUrl != null) {
                debugPrint(
                    '[StreamResolver] Found embedded redirect: $extractedUrl');
                currentUrl = extractedUrl;
                continue;
              }
            }

            debugPrint('[StreamResolver] Resolved to: $currentUrl');

            // Build final headers for the player
            if (cookies.isNotEmpty) {
              collectedHeaders['Cookie'] = cookies.join('; ');
            }

            return ResolvedStream(
              url: currentUrl,
              headers: collectedHeaders.isNotEmpty ? collectedHeaders : null,
            );
          }

          // For other status codes, break and return current URL
          debugPrint(
              '[StreamResolver] Got status $statusCode, using current URL');
          break;
        } finally {
          client.close();
        }
      }
    } catch (e) {
      debugPrint('[StreamResolver] Error resolving URL: $e');
    }

    // Fallback: return whatever URL we have
    debugPrint('[StreamResolver] Falling back to: $currentUrl');
    if (cookies.isNotEmpty) {
      collectedHeaders['Cookie'] = cookies.join('; ');
    }
    return ResolvedStream(
      url: currentUrl,
      headers: collectedHeaders.isNotEmpty ? collectedHeaders : null,
    );
  }

  /// Checks if a URL is likely a direct stream (no token/redirect patterns).
  static bool _isLikelyDirectUrl(String url) {
    final lower = url.toLowerCase();
    // URLs containing token, redirect, or proxy patterns need resolution
    if (lower.contains('/token/') ||
        lower.contains('token=') ||
        lower.contains('/redirect') ||
        lower.contains('/proxy/') ||
        lower.contains('url=')) {
      return false;
    }
    // Direct .m3u8 or .ts URLs are usually fine
    if (lower.endsWith('.m3u8') || lower.endsWith('.ts')) {
      return true;
    }
    // URLs ending with m3u8 query params
    if (lower.contains('.m3u8?') || lower.contains('.m3u8&')) {
      return true;
    }
    // Default: assume it might need resolution
    return false;
  }

  /// Tries to extract a URL from HTML/JS body content (meta refresh, JS redirect).
  static String? _extractUrlFromBody(String body) {
    // Check for meta refresh tag
    // e.g. <meta http-equiv="refresh" content="0;url=http://...">
    final metaRefreshPattern = RegExp(
      r'<meta[^>]*http-equiv\s*=\s*"refresh"[^>]*content\s*=\s*"[^"]*url=([^"\s>]+)',
      caseSensitive: false,
    );
    final metaMatch = metaRefreshPattern.firstMatch(body);
    if (metaMatch != null) {
      return metaMatch.group(1);
    }

    // Check for window.location or location.href redirect
    // e.g. window.location = "http://..." or location.href = "http://..."
    final jsRedirectPattern = RegExp(
      r'(?:window\.location|location\.href)\s*=\s*"([^"]+)"',
      caseSensitive: false,
    );
    final jsMatch = jsRedirectPattern.firstMatch(body);
    if (jsMatch != null) {
      return jsMatch.group(1);
    }

    // Check for direct m3u8 URL in body
    final m3u8Pattern = RegExp(
      r'(https?://[^\s"<>]+\.m3u8[^\s"<>]*)',
      caseSensitive: false,
    );
    final m3u8Match = m3u8Pattern.firstMatch(body);
    if (m3u8Match != null) {
      return m3u8Match.group(1);
    }

    return null;
  }
}

/// Result of stream URL resolution.
class ResolvedStream {
  final String url;
  final Map<String, String>? headers;

  const ResolvedStream({required this.url, this.headers});
}
