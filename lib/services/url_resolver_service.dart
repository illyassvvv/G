import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Resolves redirect/tokenized stream URLs to their final direct URLs.
///
/// Many IPTV streams use tokenized or redirect URLs (e.g., koora-live, easybroadcast)
/// that require following multiple HTTP redirects to reach the actual .m3u8 stream.
/// Standard Android players (ExoPlayer/video_player) don't always handle these
/// complex redirect chains. This service manually follows all redirects to extract
/// the final playable URL.
class UrlResolverService {
  static const int _maxRedirects = 10;
  static const Duration _timeout = Duration(seconds: 15);

  /// Resolves a stream URL by following all redirects manually.
  /// Returns the final resolved URL, or the original URL if resolution fails.
  static Future<String> resolveStreamUrl(String url) async {
    if (url.isEmpty) return url;

    // If it's already a direct m3u8 link without token/redirect patterns, return as-is
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    // Check if URL contains patterns that suggest it needs resolution
    final needsResolution = _needsResolution(url);
    if (!needsResolution) {
      debugPrint('[UrlResolver] Direct URL, no resolution needed: $url');
      return url;
    }

    debugPrint('[UrlResolver] Resolving URL: $url');

    try {
      String currentUrl = url;
      final Set<String> visitedUrls = {};

      for (int i = 0; i < _maxRedirects; i++) {
        if (visitedUrls.contains(currentUrl)) {
          debugPrint('[UrlResolver] Redirect loop detected at: $currentUrl');
          break;
        }
        visitedUrls.add(currentUrl);

        final request = http.Request('GET', Uri.parse(currentUrl));
        request.headers.addAll({
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Android TV) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Safari/537.36',
          'Accept': '*/*',
          'Connection': 'keep-alive',
        });
        request.followRedirects = false;

        final client = http.Client();
        try {
          final response = await client.send(request).timeout(_timeout);

          final statusCode = response.statusCode;
          debugPrint('[UrlResolver] Step $i: $statusCode for $currentUrl');

          if (statusCode >= 300 && statusCode < 400) {
            // Follow redirect
            final location = response.headers['location'];
            if (location == null || location.isEmpty) {
              debugPrint('[UrlResolver] Redirect without Location header');
              break;
            }

            // Handle relative redirects
            final redirectUri = Uri.parse(currentUrl).resolve(location);
            currentUrl = redirectUri.toString();
            debugPrint('[UrlResolver] Redirected to: $currentUrl');

            // Drain the response body to free resources
            await response.stream.drain<void>();
          } else if (statusCode == 200) {
            // Check content type for m3u8 or read a small portion to detect playlist
            final contentType = response.headers['content-type'] ?? '';
            debugPrint('[UrlResolver] Final URL content-type: $contentType');

            // If we got a 200 response, check if the body contains a redirect URL
            if (contentType.contains('text/html') || contentType.contains('text/plain')) {
              final body = await response.stream.bytesToString().timeout(_timeout);
              final extractedUrl = _extractUrlFromBody(body);
              if (extractedUrl != null && extractedUrl != currentUrl) {
                debugPrint('[UrlResolver] Extracted URL from body: $extractedUrl');
                currentUrl = extractedUrl;
                continue;
              }
            } else {
              await response.stream.drain<void>();
            }

            // We've reached the final URL
            debugPrint('[UrlResolver] Resolved to: $currentUrl');
            return currentUrl;
          } else {
            debugPrint('[UrlResolver] Unexpected status: $statusCode');
            await response.stream.drain<void>();
            break;
          }
        } finally {
          client.close();
        }
      }

      debugPrint('[UrlResolver] Returning resolved URL: $currentUrl');
      return currentUrl;
    } catch (e) {
      debugPrint('[UrlResolver] Error resolving URL: $e');
      // Return original URL as fallback
      return url;
    }
  }

  /// Checks if a URL likely needs resolution (contains token/redirect patterns).
  static bool _needsResolution(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('/token/') ||
        lowerUrl.contains('/redirect') ||
        lowerUrl.contains('token=') ||
        lowerUrl.contains('easybroadcast') ||
        lowerUrl.contains('koora-live') ||
        lowerUrl.contains('dhd.') ||
        // Also resolve any URL that is NOT a direct media stream
        (!lowerUrl.endsWith('.m3u8') &&
         !lowerUrl.endsWith('.ts') &&
         !lowerUrl.endsWith('.mp4') &&
         !lowerUrl.contains('.m3u8?') &&
         !lowerUrl.contains('.ts?') &&
         !lowerUrl.contains('.mp4?') &&
         // But only if it looks like it could be a redirect
         (lowerUrl.contains('http', 8) || lowerUrl.contains('/all?')));
  }

  /// Tries to extract a stream URL from an HTML or text body.
  static String? _extractUrlFromBody(String body) {
    // Look for m3u8 URLs in the body
    final m3u8Pattern = RegExp(r'(https?://[^\s"<>]+\.m3u8[^\s"<>]*)');
    final match = m3u8Pattern.firstMatch(body);
    if (match != null) {
      return match.group(1);
    }

    // Look for any http URL that could be a stream
    final urlPattern = RegExp(r'(https?://[^\s"<>]+\.(ts|mp4|mpd)[^\s"<>]*)');
    final urlMatch = urlPattern.firstMatch(body);
    if (urlMatch != null) {
      return urlMatch.group(1);
    }

    // Look for meta refresh or JavaScript redirect
    final metaPattern = RegExp(r'url=([^\s"<>]+)', caseSensitive: false);
    final metaMatch = metaPattern.firstMatch(body);
    if (metaMatch != null) {
      final url = metaMatch.group(1);
      if (url != null && url.startsWith('http')) {
        return url;
      }
    }

    return null;
  }
}
