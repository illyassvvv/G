class Channel {
  final int id;
  final String name;
  final String logo;
  final String streamUrl;

  const Channel({
    required this.id,
    required this.name,
    required this.logo,
    required this.streamUrl,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'],
      name: json['name'],
      logo: json['logo'] ?? '',
      streamUrl: json['stream'] ?? '',
    );
  }
}