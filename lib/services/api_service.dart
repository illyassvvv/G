import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../models/channel_category.dart';
import '../models/match.dart';

class ApiService {
  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) '
        'Version/15.0 Mobile/15E148 Safari/604.1',
    'Accept': 'application/json, */*',
    'Accept-Language': 'en-US,en;q=0.9,ar;q=0.8',
  };

  /// Returns channels grouped by category (Bein Sports, Al Kass, etc.)
  static Future<List<ChannelCategory>> fetchCategories() async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/illyassvvv/G/refs/heads/main/channels.json',
        ),
        headers: _headers,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // Format: { "categories": [ { "name": "Bein Sports", "channels": [...] } ] }
        if (data['categories'] != null) {
          return (data['categories'] as List).map<ChannelCategory>((cat) {
            final channels = (cat['channels'] as List? ?? [])
                .map<Channel>((e) => Channel.fromJson(e))
                .toList();
            return ChannelCategory(
              name: cat['name']?.toString() ?? 'Channels',
              channels: channels,
            );
          }).toList();
        }

        // Flat list fallback — group everything under one category
        if (data is List) {
          final channels = (data as List)
              .map<Channel>((e) => Channel.fromJson(e))
              .toList();
          return [ChannelCategory(name: 'All Channels', channels: channels)];
        }
      }
    } catch (_) {}
    return [];
  }

  /// Flat list helper — kept for compatibility
  static Future<List<Channel>> fetchChannels() async {
    final cats = await fetchCategories();
    return cats.expand((c) => c.channels).toList();
  }

  static Future<List<Match>> fetchMatches() async {
    try {
      final now = DateTime.now();
      final date =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final res = await http.get(
        Uri.parse('https://ws.kora-api.space/api/matches/$date/1'),
        headers: _headers,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data['matches'] as List)
            .map<Match>((e) => Match.fromJson(e))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
