import 'dart:convert';
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
    // Required by some token servers that check the referer
    'Referer': 'https://www.google.com/',
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

            // ── Handle m3u8 master playlists from token/proxy servers ──
            // Some IPTV token servers (e.g. dhd.koora-live.top/token/...)
            // act as proxies: they fetch a tokenized m3u8 playlist from the
            // upstream CDN and return it directly with content-type
            // application/vnd.apple.mpegurl. The original proxy URL has an
            // embedded URL in its path (e.g. /token/https://...) which can
            // cause issues with Uri.parse() and ExoPlayer's URL handling.
            //
            // Fix: read the m3u8 body, extract the best-quality variant URL
            // (which is a clean, direct CDN URL with token query params),
            // and return that instead. This gives ExoPlayer a standard URL
            // it can handle without issues.
            if (_isTokenOrProxyUrl(currentUrl) &&
                (contentType.contains('mpegurl') ||
                 contentType.contains('x-mpegurl') ||
                 contentType.contains('apple.mpegurl') ||
                 contentType.contains('octet-stream'))) {
              final body = await streamedResponse.stream
                  .bytesToString()
                  .timeout(_timeout);

              // Check if body is actually an m3u8 playlist
              if (body.trimLeft().startsWith('#EXTM3U')) {
                final variantUrl = _extractBestVariantFromM3u8(body);
                if (variantUrl != null) {
                  debugPrint(
                      '[StreamResolver] Extracted variant from m3u8: $variantUrl');
                  if (cookies.isNotEmpty) {
                    collectedHeaders['Cookie'] = cookies.join('; ');
                  }
                  return ResolvedStream(
                    url: variantUrl,
                    headers: collectedHeaders.isNotEmpty
                        ? collectedHeaders
                        : null,
                  );
                }
                // If it's a media playlist (no variants), check for a bare
                // m3u8 URL inside the body (some proxies embed one).
                final m3u8Url = _extractUrlFromBody(body);
                if (m3u8Url != null) {
                  debugPrint(
                      '[StreamResolver] Found m3u8 URL in body: $m3u8Url');
                  currentUrl = m3u8Url;
                  continue;
                }
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

  /// Tries to extract a URL from HTML/JS/JSON body content.
  static String? _extractUrlFromBody(String body) {
    final trimmed = body.trim();

    // ── 1. JSON response (most modern token servers return JSON) ──────────
    // e.g. {"url":"https://...m3u8"} or {"stream":"..."} or {"link":"..."}
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final dynamic json = jsonDecode(trimmed);
        final Map<String, dynamic>? obj = json is Map<String, dynamic>
            ? json
            : (json is List && json.isNotEmpty && json.first is Map)
                ? json.first as Map<String, dynamic>
                : null;
        if (obj != null) {
          for (final key in [
            'url', 'stream_url', 'link', 'src', 'source',
            'hls', 'stream', 'file', 'path', 'manifest',
          ]) {
            final val = obj[key];
            if (val is String && val.startsWith('http')) return val;
          }
        }
      } catch (_) {
        // not valid JSON – fall through to HTML patterns
      }
    }

    // ── 2. HTML meta refresh ───────────────────────────────────────────────
    final metaRefreshPattern = RegExp(
      r'<meta[^>]*http-equiv\s*=\s*"refresh"[^>]*content\s*=\s*"[^"]*url=([^"\s>]+)',
      caseSensitive: false,
    );
    final metaMatch = metaRefreshPattern.firstMatch(trimmed);
    if (metaMatch != null) return metaMatch.group(1);

    // ── 3. JS window.location / location.href redirect ────────────────────
    final jsRedirectPattern = RegExp(
      r'(?:window\.location|location\.href)\s*=\s*"([^"]+)"',
      caseSensitive: false,
    );
    final jsMatch = jsRedirectPattern.firstMatch(trimmed);
    if (jsMatch != null) return jsMatch.group(1);

    // ── 4. Bare m3u8 URL anywhere in the body ─────────────────────────────
    final m3u8Pattern = RegExp(
      r'(https?://[^\s"<>]+\.m3u8[^\s"<>]*)',
      caseSensitive: false,
    );
    final m3u8Match = m3u8Pattern.firstMatch(trimmed);
    if (m3u8Match != null) return m3u8Match.group(1);

    return null;
  }

  /// Checks if a URL looks like a token/proxy URL that wraps another URL.
  /// These URLs have embedded URLs in their path (e.g. /token/https://...).
  static bool _isTokenOrProxyUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('/token/') ||
        lower.contains('/proxy/') ||
        lower.contains('/redirect/');
  }

  /// Parses an HLS master playlist and returns the highest-bandwidth variant URL.
  ///
  /// A master playlist looks like:
  /// ```
  /// #EXTM3U
  /// #EXT-X-STREAM-INF:BANDWIDTH=1636196,RESOLUTION=854x480,...
  /// https://cdn.example.com/480p/chunks.m3u8?token=abc
  /// #EXT-X-STREAM-INF:BANDWIDTH=778760,RESOLUTION=640x360,...
  /// https://cdn.example.com/360p/chunks.m3u8?token=abc
  /// ```
  ///
  /// Returns the URL of the highest bandwidth variant, or null if the body
  /// is not a master playlist (e.g. it's a media playlist with segments).
  static String? _extractBestVariantFromM3u8(String body) {
    final lines = body.split('\n');
    String? bestUrl;
    int bestBandwidth = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('#EXT-X-STREAM-INF:')) {
        // Extract BANDWIDTH value
        final bwMatch = RegExp(r'BANDWIDTH=(\d+)').firstMatch(line);
        final bandwidth =
            bwMatch != null ? int.tryParse(bwMatch.group(1)!) ?? 0 : 0;

        // The next non-empty, non-comment line is the variant URL
        for (int j = i + 1; j < lines.length; j++) {
          final candidate = lines[j].trim();
          if (candidate.isEmpty || candidate.startsWith('#')) continue;
          if (candidate.startsWith('http')) {
            if (bandwidth > bestBandwidth) {
              bestBandwidth = bandwidth;
              bestUrl = candidate;
            }
          }
          break; // only check the first non-comment line after STREAM-INF
        }
      }
    }

    return bestUrl;
  }
}

/// Result of stream URL resolution.
class ResolvedStream {
  final String url;
  final Map<String, String>? headers;

  const ResolvedStream({required this.url, this.headers});
}
