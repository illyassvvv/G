import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../models/match.dart';

class ApiService {
  static Future<List<Channel>> fetchChannels() async {
    try {
      final res = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/illyassvvv/G/refs/heads/main/channels.json'));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['categories'] as List)
            .expand((c) => c['channels'])
            .map<Channel>((e) => Channel.fromJson(e))
            .toList();

        return list;
      }
    } catch (_) {}

    return [];
  }

  static Future<List<Match>> fetchMatches() async {
    try {
      final now = DateTime.now();
      final date =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final res = await http.get(
          Uri.parse('https://ws.kora-api.space/api/matches/$date/1'));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['matches'] as List)
            .map<Match>((e) => Match.fromJson(e))
            .toList();

        return list;
      }
    } catch (_) {}

    return [];
  }
}