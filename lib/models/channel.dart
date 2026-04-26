import '../core/url_utils.dart';

class Channel {
  final int id;
  final String name;
  final String logo;
  final String streamUrl;

  String get logoUrl => logo;

  const Channel({
    required this.id,
    required this.name,
    required this.logo,
    required this.streamUrl,
  });

  static String _asString(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    return value.toString().trim();
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    return int.tryParse(_asString(value)) ?? fallback;
  }

  static String _safeUrl(dynamic value, {bool imageOnly = false}) {
    final raw = _asString(value);
    if (raw.isEmpty) return '';
    final uri = UrlUtils.tryParseNetworkUrl(
      raw,
      allowHttp: true,
      allowHttps: true,
    );
    if (uri == null) return '';

    // Prefer HTTPS when the source already provides it; keep HTTP fallback
    // for legacy stream endpoints.
    if (imageOnly && uri.scheme != 'https' && uri.scheme != 'http') {
      return '';
    }
    return uri.toString();
  }

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      logo: _safeUrl(json['logo'] ?? json['image'], imageOnly: true),
      streamUrl: _safeUrl(json['stream'] ?? json['url']),
    );
  }
}
