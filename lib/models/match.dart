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

  static String _asString(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    return value.toString().trim();
  }

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: _asString(json['id']),
      league: _asString(json['league'] ?? json['competition']),
      home: _asString(json['home'] ?? json['home_name'] ?? json['localteam']),
      away: _asString(json['away'] ?? json['away_name'] ?? json['visitorteam']),
      score: _asString(json['score'] ?? json['result']),
      time: _asString(json['time'] ?? json['minute']),
      isLive: _asString(json['status'], '0') == '1',
      homeLogo: _asString(json['home_logo'] ?? json['localteam_logo'] ??
          json['home_image'] ?? json['local_logo']),
      awayLogo: _asString(json['away_logo'] ?? json['visitorteam_logo'] ??
          json['away_image'] ?? json['visitor_logo']),
      leagueLogo: _asString(json['league_logo'] ?? json['competition_logo']),
    );
  }
}
