class Match {
  final String id;
  final String league;
  final String home;
  final String away;
  final String score;
  final String time;
  final bool isLive;

  const Match({
    required this.id,
    required this.league,
    required this.home,
    required this.away,
    required this.score,
    required this.time,
    required this.isLive,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'].toString(),
      league: json['league'] ?? '',
      home: json['home'] ?? '',
      away: json['away'] ?? '',
      score: json['score'] ?? '',
      time: json['time'] ?? '',
      isLive: (json['status']?.toString() ?? '0') == '1',
    );
  }
}