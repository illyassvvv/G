class Match {
  final String id;
  final String league;
  final String home;
  final String away;
  final String score;
  final String time;
  final bool isLive;
  final String homeLogo;
  final String awayLogo;
  final String leagueLogo;

  static const _teamLogoBase = 'https://img.kora-api.space/uploads/team/';
  static const _leagueLogoBase = 'https://img.kora-api.space/uploads/leagues/';

  String get homeLogoUrl =>
      homeLogo.isNotEmpty ? '$_teamLogoBase$homeLogo' : '';
  String get awayLogoUrl =>
      awayLogo.isNotEmpty ? '$_teamLogoBase$awayLogo' : '';
  String get leagueLogoUrl =>
      leagueLogo.isNotEmpty ? '$_leagueLogoBase$leagueLogo' : '';

  const Match({
    required this.id,
    required this.league,
    required this.home,
    required this.away,
    required this.score,
    required this.time,
    required this.isLive,
    required this.homeLogo,
    required this.awayLogo,
    required this.leagueLogo,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'].toString(),
      league: json['league'] ?? json['competition'] ?? '',
      home: json['home'] ?? json['home_name'] ?? json['localteam'] ?? '',
      away: json['away'] ?? json['away_name'] ?? json['visitorteam'] ?? '',
      score: json['score'] ?? json['result'] ?? '',
      time: json['time'] ?? json['minute'] ?? '',
      isLive: (json['status']?.toString() ?? '0') == '1',
      // Try multiple common field names used by football APIs
      homeLogo: json['home_logo'] ?? json['localteam_logo'] ??
          json['home_image'] ?? json['local_logo'] ?? '',
      awayLogo: json['away_logo'] ?? json['visitorteam_logo'] ??
          json['away_image'] ?? json['visitor_logo'] ?? '',
      leagueLogo: json['league_logo'] ?? json['competition_logo'] ?? '',
    );
  }
}
