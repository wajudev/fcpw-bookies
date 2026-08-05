class Player {
  final String id;
  final String externalId;
  final String seasonId;
  final String name;
  final String team;
  final int goals;
  final String gender; // 'M' or 'F'
  final int? matchesPlayed;
  final int yellowCards;
  final int redCards;
  final int doubleYellow;

  Player({
    required this.id,
    required this.externalId,
    required this.seasonId,
    required this.name,
    required this.team,
    required this.goals,
    required this.gender,
    this.matchesPlayed,
    this.yellowCards = 0,
    this.redCards = 0,
    this.doubleYellow = 0,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      externalId: json['external_id'] as String,
      seasonId: json['season_id'] as String,
      name: json['name'] as String,
      team: json['team'] as String,
      goals: json['goals'] as int? ?? 0,
      gender: json['gender'] as String? ?? 'M', // Default to M for backwards compatibility
      matchesPlayed: json['matches_played'] as int?,
      yellowCards: json['yellow_cards'] as int? ?? 0,
      redCards: json['red_cards'] as int? ?? 0,
      doubleYellow: json['double_yellow'] as int? ?? 0,
    );
  }
}
