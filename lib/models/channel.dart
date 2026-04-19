class Channel {
  final int id;
  final String name;
  final String logo;
  final String streamUrl;

  // Logo URL comes directly from the GitHub JSON
  // https://raw.githubusercontent.com/illyassvvv/G/refs/heads/main/channels.json
  String get logoUrl => logo;

  const Channel({
    required this.id,
    required this.name,
    required this.logo,
    required this.streamUrl,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      logo: json['logo'] ?? json['image'] ?? '',
      streamUrl: json['stream'] ?? json['url'] ?? '',
    );
  }
}
