import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/channel.dart';

class ChannelService {
  // Public raw URL — no token needed for public repo
  static const String _url =
      'https://raw.githubusercontent.com/illyassvvv/G/main/channels.json';

  static List<ChannelCategory>? _cache;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 10);

  // ── Fetch with cache ──────────────────────────────────────────
  static Future<List<ChannelCategory>> fetchCategories() async {
    // Return cache if fresh
    if (_cache != null && _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cache!;
    }

    try {
      final response = await http
          .get(Uri.parse('$_url?t=${DateTime.now().millisecondsSinceEpoch}'),
              headers: {'Cache-Control': 'no-cache'})
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final list = (data['categories'] as List<dynamic>)
            .map((c) => ChannelCategory.fromJson(c as Map<String, dynamic>))
            .toList();
        _cache     = list;
        _cacheTime = DateTime.now();
        return list;
      }
    } catch (e) {
      debugPrint('ChannelService: fetch error: $e');
    }

    // Fallback to hardcoded
    return _fallback();
  }

  // ── Force refresh ─────────────────────────────────────────────
  static Future<List<ChannelCategory>> refreshCategories() async {
    _cache     = null;
    _cacheTime = null;
    return fetchCategories();
  }

  // ── Search across all channels ────────────────────────────────
  static List<Channel> search(List<ChannelCategory> cats, String query) {
    if (query.trim().isEmpty) return [];
    final q = query.trim().toLowerCase();
    final results = <Channel>[];
    for (final cat in cats) {
      for (final ch in cat.channels) {
        if (ch.name.toLowerCase().contains(q) ||
            ch.category.toLowerCase().contains(q) ||
            ch.number.contains(q)) {
          results.add(ch);
        }
      }
    }
    return results;
  }

  // ── Hardcoded fallback ────────────────────────────────────────
  static const String _logoBase =
      'https://raw.githubusercontent.com/illyassvvv/G/main/logos';

  static List<ChannelCategory> _fallback() {
    return [
      ChannelCategory(
        name: 'beIN Sports',
        icon: 'sports_soccer',
        channels: const [
          Channel(
            id: 1, name: 'beIN Sports 1', number: '01', category: 'beIN Sports',
            logoUrl: '$_logoBase/bein1.png',
            streamUrl: 'http://xmrcars.org:8080/bn1hd/mono.m3u8',
          ),
          Channel(
            id: 2, name: 'beIN Sports 2', number: '02', category: 'beIN Sports',
            logoUrl: '$_logoBase/bein2.png',
            streamUrl: 'http://xmrcars.org:8080/bn2hd/mono.m3u8',
          ),
          Channel(
            id: 3, name: 'beIN Sports 3', number: '03', category: 'beIN Sports',
            logoUrl: '$_logoBase/bein3.png',
            streamUrl: 'http://xmrcars.org:8080/bn3hd/mono.m3u8',
          ),
          Channel(
            id: 4, name: 'beIN Sports 4', number: '04', category: 'beIN Sports',
            logoUrl: '$_logoBase/bein4.png',
            streamUrl: 'https://man1ted.com/be4/index.m3u8',
          ),
          Channel(
            id: 5, name: 'beIN Sports 5', number: '05', category: 'beIN Sports',
            logoUrl: '$_logoBase/bein5.png',
            streamUrl: 'https://man1ted.com/be5/index.m3u8',
          ),
          Channel(
            id: 6, name: 'beIN Sports 6', number: '06', category: 'beIN Sports',
            logoUrl: '$_logoBase/bein6.png',
            streamUrl: 'https://man1ted.com/be6/index.m3u8',
          ),
        ],
      ),
    ];
  }
}
