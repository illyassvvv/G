import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/channel.dart';

class ChannelService {
  // ── Obfuscated URL (base64-encoded, split into segments) ───────
  // Prevents the raw GitHub URL from being trivially visible in
  // decompiled output or static analysis.
  static const List<String> _urlParts = [
    'aHR0cHM6Ly9yYXcuZ2l0aHVi',   // segment 1
    'dXNlcmNvbnRlbnQuY29tL2ls',     // segment 2
    'bHlhc3N2dnYvRy9tYWluL2No',     // segment 3
    'YW5uZWxzLmpzb24=',             // segment 4
  ];

  static String get _url {
    final encoded = _urlParts.join();
    return utf8.decode(base64.decode(encoded));
  }

  static List<ChannelCategory>? _cache;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 10);

  // ── Fetch with cache ──────────────────────────────────────────
  static Future<List<ChannelCategory>> fetchCategories() async {
    // Return cache if fresh
    if (_cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cache!;
    }

    try {
      final response = await http
          .get(
            Uri.parse('${_url}?t=${DateTime.now().millisecondsSinceEpoch}'),
            headers: {'Cache-Control': 'no-cache'},
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final list = (data['categories'] as List<dynamic>)
            .map((c) => ChannelCategory.fromJson(c as Map<String, dynamic>))
            .toList();
        _cache = list;
        _cacheTime = DateTime.now();
        return list;
      } else {
        debugPrint(
          'ChannelService: HTTP ${response.statusCode} — falling back',
        );
      }
    } catch (e) {
      debugPrint('ChannelService: fetch error: $e');
    }

    // Fallback to stale cache before hardcoded data
    if (_cache != null) return _cache!;
    return _fallback();
  }

  // ── Force refresh ─────────────────────────────────────────────
  static Future<List<ChannelCategory>> refreshCategories() async {
    _cache = null;
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

  // ── Hardcoded fallback (matches channels.json) ──────────────
  static List<ChannelCategory> _fallback() {
    return [
      ChannelCategory(
        name: 'beIN Sports',
        icon: 'sports_soccer',
        channels: const [
          Channel(
            id: 1, name: 'beIN Sports 1', number: '01', category: 'beIN Sports',
            logoUrl: 'https://docdog.top/logo/countries/turkey/beinsports1.png',
            streamUrl: 'http://sportook.online/BEIN-S1/video.m3u8',
          ),
          Channel(
            id: 2, name: 'beIN Sports 2', number: '02', category: 'beIN Sports',
            logoUrl: 'https://docdog.top/logo/countries/turkey/beinsports2.png',
            streamUrl: 'http://sportook.online/BEIN-S22/video.m3u8',
          ),
          Channel(
            id: 3, name: 'beIN Sports 3', number: '03', category: 'beIN Sports',
            logoUrl: 'https://docdog.top/logo/countries/turkey/beinsports3.png',
            streamUrl: 'http://sportook.online/BEIN-S3/video.m3u8',
          ),
          Channel(
            id: 4, name: 'beIN Sports 4', number: '04', category: 'beIN Sports',
            logoUrl: 'https://docdog.top/logo/countries/turkey/beinsports4.png',
            streamUrl: 'https://man1ted.com/be4/index.m3u8',
          ),
          Channel(
            id: 5, name: 'beIN Sports 5', number: '05', category: 'beIN Sports',
            logoUrl: 'https://assets.bein.com/mena/sites/4/2015/06/beIN_SPORTS5_DIGITAL_Mono.png',
            streamUrl: 'https://man1ted.com/be5/index.m3u8',
          ),
          Channel(
            id: 6, name: 'beIN Sports 6', number: '06', category: 'beIN Sports',
            logoUrl: 'https://assets.bein.com/mena/sites/4/2021/02/beIN_SPORTS6_DIGITAL_Mono.png',
            streamUrl: 'https://man1ted.com/be6/index.m3u8',
          ),
        ],
      ),
      ChannelCategory(
        name: 'Al Kass',
        icon: 'sports',
        channels: const [
          Channel(
            id: 101, name: 'Al Kass 1', number: '01', category: 'Al Kass',
            logoUrl: 'https://www.elahmad.com/tv/mobiletv/images/alkass_1.jpg?v=7',
            streamUrl: 'https://liveeu-gcp.alkassdigital.net/alkass1-p/main.m3u8',
          ),
          Channel(
            id: 102, name: 'Al Kass 2', number: '02', category: 'Al Kass',
            logoUrl: 'https://www.elahmad.com/tv/mobiletv/images/alkass_2.jpg?v=7',
            streamUrl: 'https://liveeu-gcp.alkassdigital.net/alkass2-p/main.m3u8',
          ),
          Channel(
            id: 103, name: 'Al Kass 3', number: '03', category: 'Al Kass',
            logoUrl: 'https://www.elahmad.com/tv/mobiletv/images/alkass_3.jpg?v=7',
            streamUrl: 'https://liveeu-gcp.alkassdigital.net/alkass3-p/main.m3u8',
          ),
          Channel(
            id: 104, name: 'Al Kass 4', number: '04', category: 'Al Kass',
            logoUrl: 'https://www.elahmad.com/tv/mobiletv/images/alkass_4.jpg?v=7',
            streamUrl: 'https://liveeu-gcp.alkassdigital.net/alkass4-p/main.m3u8',
          ),
          Channel(
            id: 105, name: 'Al Kass 5', number: '5', category: 'Al Kass',
            logoUrl: 'https://www.elahmad.com/tv/mobiletv/images/alkass_5.jpg?v=7',
            streamUrl: 'https://liveeu-gcp.alkassdigital.net/alkass5-p/main.m3u8',
          ),
          Channel(
            id: 106, name: 'Al Kass 6', number: '6', category: 'Al Kass',
            logoUrl: 'https://www.elahmad.com/tv/mobiletv/images/alkass_6.jpg?v=7',
            streamUrl: 'https://liveeu-gcp.alkassdigital.net/alkass6-p/main.m3u8',
          ),
          Channel(
            id: 107, name: 'Al Kass 7', number: '7', category: 'Al Kass',
            logoUrl: 'https://www.elahmad.com/tv/mobiletv/images/alkass_7.jpg?v=7',
            streamUrl: 'https://liveeu-gcp.alkassdigital.net/alkass7-p/main.m3u8',
          ),
        ],
      ),
      ChannelCategory(
        name: 'Morocco',
        icon: 'tv',
        channels: const [
          Channel(
            id: 108, name: '2m Tv', number: '1', category: 'Morocco',
            logoUrl: 'https://elahmad-tv.com/images/2m_ma_tv.jpg',
            streamUrl: 'https://d2qh3gh0k5vp3v.cloudfront.net/v1/master/3722c60a815c199d9c0ef36c5b73da68a62b09d1/cc-n6pess5lwbghr/2M_ES.m3u8',
          ),
          Channel(
            id: 109, name: 'Al Aoula', number: '2', category: 'Morocco',
            logoUrl: 'https://www.lyngsat.com/logo/tv/aa/al-aoula-ma.png',
            streamUrl: 'https://dhd.koora-live.top/token/https://token.easybroadcast.io/all?url=https%3A%2F%2Fcdn.live.easybroadcast.io%2Fabr_corp%2F73_aloula_w1dqfwm%2Fplaylist_dvr.m3u8',
          ),
          Channel(
            id: 110, name: 'Al Maghribia', number: '3', category: 'Morocco',
            logoUrl: 'https://www.lyngsat.com/logo/tv/aa/al-maghribia-ma.png',
            streamUrl: 'https://dhd.koora-live.top/token/https://token.easybroadcast.io/all?url=https%3A%2F%2Fcdn.live.easybroadcast.io%2Fabr_corp%2F73_almaghribia_83tz85q%2Fplaylist_dvr.m3u8',
          ),
          Channel(
            id: 111, name: 'Arryadia', number: '4', category: 'Morocco',
            logoUrl: 'https://www.lyngsat.com/logo/tv/aa/arryadia-ma.png',
            streamUrl: 'https://dhd.koora-live.top/token/https://token.easybroadcast.io/all?url=https%3A%2F%2Fcdn.live.easybroadcast.io%2Fabr_corp%2F73_arryadia_k2tgcj0%2Fplaylist_dvr.m3u8',
          ),
          Channel(
            id: 112, name: 'Assadissa', number: '5', category: 'Morocco',
            logoUrl: 'https://www.lyngsat.com/logo/tv/aa/assadissa-ma.png',
            streamUrl: 'https://dhd.koora-live.top/token/https://token.easybroadcast.io/all?url=https%3A%2F%2Fcdn.live.easybroadcast.io%2Fabr_corp%2F73_assadissa_7b7u5n1%2Fplaylist_dvr.m3u8',
          ),
          Channel(
            id: 113, name: 'Athaqafia', number: '6', category: 'Morocco',
            logoUrl: 'https://www.lyngsat.com/logo/tv/aa/athaqafia-ma.png',
            streamUrl: 'https://dhd.koora-live.top/token/https://token.easybroadcast.io/all?url=https%3A%2F%2Fcdn.live.easybroadcast.io%2Fabr_corp%2F73_arrabia_hthcj4p%2Fplaylist_dvr.m3u8',
          ),
          Channel(
            id: 114, name: 'Tamazight', number: '7', category: 'Morocco',
            logoUrl: 'https://www.lyngsat.com/logo/tv/tt/tamazight-ma.png',
            streamUrl: 'https://dhd.koora-live.top/token/https://token.easybroadcast.io/all?url=https%3A%2F%2Fcdn.live.easybroadcast.io%2Fabr_corp%2F73_tamazight_tccybxt%2Fplaylist_dvr.m3u8',
          ),
          Channel(
            id: 115, name: 'Medi1TV Maghreb', number: '8', category: 'Morocco',
            logoUrl: 'https://www.lyngsat.com/logo/tv/mm/medi-1-tv-ma.png',
            streamUrl: 'https://cdn.live.easybroadcast.io/abr_corp/83_medi1tv-maghreb_jnbspmg/corp/83_medi1tv-maghreb_jnbspmg_720p/chunks_dvr.m3u8',
          ),
        ],
      ),
    ];
  }
}
