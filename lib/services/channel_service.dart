import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/channel.dart';

class ChannelService {
  // GitHub raw URL - user just edits channels.json in repo root
  static const String _channelsUrl =
      'https://raw.githubusercontent.com/illyassvvv/G/main/channels.json';

  static List<ChannelCategory>? _cachedCategories;

  static Future<List<ChannelCategory>> fetchCategories() async {
    // Return cache if available
    if (_cachedCategories != null) return _cachedCategories!;

    try {
      final response = await http.get(
        Uri.parse('$_channelsUrl?t=${DateTime.now().millisecondsSinceEpoch}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final categoriesJson = data['categories'] as List<dynamic>;
        _cachedCategories = categoriesJson
            .map((c) => ChannelCategory.fromJson(c as Map<String, dynamic>))
            .toList();
        return _cachedCategories!;
      }
    } catch (e) {
      debugPrint('Error fetching channels: $e');
    }

    // Fallback to hardcoded channels if fetch fails
    return _fallbackCategories();
  }

  static Future<List<ChannelCategory>> refreshCategories() async {
    _cachedCategories = null;
    return fetchCategories();
  }

  static List<ChannelCategory> _fallbackCategories() {
    return [
      ChannelCategory(
        name: 'beIN Sports',
        icon: 'sports_soccer',
        channels: [
          const Channel(
            id: 1,
            name: 'beIN Sports 1',
            number: '01',
            logoUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/9/96/BeIN_Sports_1.svg/200px-BeIN_Sports_1.svg.png',
            streamUrl: 'http://xmrcars.org:8080/bn1hd/mono.m3u8',
            category: 'beIN Sports',
          ),
          const Channel(
            id: 2,
            name: 'beIN Sports 2',
            number: '02',
            logoUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/d/db/BeIN_Sports_2.svg/200px-BeIN_Sports_2.svg.png',
            streamUrl: 'http://xmrcars.org:8080/bn2hd/mono.m3u8',
            category: 'beIN Sports',
          ),
          const Channel(
            id: 3,
            name: 'beIN Sports 3',
            number: '03',
            logoUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/3/32/BeIN_Sports_3.svg/200px-BeIN_Sports_3.svg.png',
            streamUrl: 'http://xmrcars.org:8080/bn3hd/mono.m3u8',
            category: 'beIN Sports',
          ),
          const Channel(
            id: 4,
            name: 'beIN Sports 4',
            number: '04',
            logoUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/0/07/BeIN_Sports_4.svg/200px-BeIN_Sports_4.svg.png',
            streamUrl: 'https://man1ted.com/be4/index.m3u8',
            category: 'beIN Sports',
          ),
          const Channel(
            id: 5,
            name: 'beIN Sports 5',
            number: '05',
            logoUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/8/8d/BeIN_Sports_5.svg/200px-BeIN_Sports_5.svg.png',
            streamUrl: 'https://man1ted.com/be5/index.m3u8',
            category: 'beIN Sports',
          ),
          const Channel(
            id: 6,
            name: 'beIN Sports 6',
            number: '06',
            logoUrl: 'https://upload.wikimedia.org/wikipedia/en/thumb/8/8d/BeIN_Sports_5.svg/200px-BeIN_Sports_5.svg.png',
            streamUrl: 'https://man1ted.com/be6/index.m3u8',
            category: 'beIN Sports',
          ),
        ],
      ),
    ];
  }
}
