class Channel {
  final int id;
  final String name;
  final String number;
  final String logoUrl;
  final String streamUrl;
  final String category;

  const Channel({
    required this.id,
    required this.name,
    required this.number,
    required this.logoUrl,
    required this.streamUrl,
    this.category = '',
  });

  factory Channel.fromJson(Map<String, dynamic> json, String categoryName) {
    return Channel(
      id: json['id'] as int,
      name: json['name'] as String,
      number: json['number'] as String,
      logoUrl: json['logo'] as String,
      streamUrl: json['stream'] as String,
      category: categoryName,
    );
  }
}

class ChannelCategory {
  final String name;
  final String icon;
  final List<Channel> channels;

  const ChannelCategory({
    required this.name,
    required this.icon,
    required this.channels,
  });

  factory ChannelCategory.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final channels = (json['channels'] as List<dynamic>)
        .map((ch) => Channel.fromJson(ch as Map<String, dynamic>, name))
        .toList();
    return ChannelCategory(
      name: name,
      icon: json['icon'] as String,
      channels: channels,
    );
  }
}
