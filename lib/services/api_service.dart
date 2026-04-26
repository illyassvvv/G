import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../models/channel_category.dart';
import '../models/match.dart';

class ApiService {
  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/139.0.0.0 Safari/537.36',
    'Accept': 'application/json, */*',
    'Accept-Language': 'en-US,en;q=0.9,ar;q=0.8',
  };

  static const _timeout = Duration(seconds: 8);
  static const _categoriesUrl =
      'https://raw.githubusercontent.com/illyassvvv/G/refs/heads/main/channels.json';
  static const _matchesUrlBase = 'https://ws.kora-api.space/api/matches';

  static Future<dynamic> _getJson(String url) async {
    final res = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(_timeout);

    if (res.statusCode != 200) {
      throw HttpException('Request failed: ${res.statusCode}', uri: Uri.parse(url));
    }

    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  static List<Channel> _parseChannels(dynamic raw) {
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((e) => Channel.fromJson(Map<String, dynamic>.from(e)))
        .where((c) => c.id != 0 && c.name.isNotEmpty)
        .toList(growable: false);
  }

  static Future<List<ChannelCategory>> fetchCategories() async {
    final data = await _getJson(_categoriesUrl);

    if (data is Map<String, dynamic>) {
      final categories = data['categories'];
      if (categories is List) {
        return categories.whereType<Map>().map((cat) {
          final catMap = Map<String, dynamic>.from(cat);
          final channels = _parseChannels(catMap['channels']);
          return ChannelCategory(
            name: catMap['name']?.toString().trim().isNotEmpty == true
                ? catMap['name'].toString().trim()
                : 'Channels',
            channels: channels,
          );
        }).where((category) => category.channels.isNotEmpty).toList(growable: false);
      } else {
        // Handle the case where the JSON is a single object with channels directly
        final channels = _parseChannels(data['channels'] ?? data['data']);
        if (channels.isNotEmpty) {
          return [ChannelCategory(name: 'All Channels', channels: channels)];
        }
      }
    }

    if (data is List) {
      final channels = _parseChannels(data);
      if (channels.isNotEmpty) {
        return [ChannelCategory(name: 'All Channels', channels: channels)];
      }
    }

    throw const FormatException('Unexpected categories payload');
  }

  static Future<List<Channel>> fetchChannels() async {
    final cats = await fetchCategories();
    return cats.expand((c) => c.channels).toList(growable: false);
  }

  static Future<List<Match>> fetchMatches() async {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final data = await _getJson('$_matchesUrlBase/$date/1');

    if (data is Map<String, dynamic>) {
      final matches = data['matches'] ?? data['data'];
      if (matches is List) {
        return matches
            .whereType<Map>()
            .map((e) => Match.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false);
      }
    } else if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Match.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    }

    throw const FormatException('Unexpected matches payload');
  }
}
