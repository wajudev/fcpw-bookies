enum MatchStatus { upcoming, live, finished }

class Match {
  final String id;
  final String externalId;
  final String seasonId;
  final String squad;
  final String homeTeam;
  final String awayTeam;
  final DateTime kickoffTime;
  final int? homeScoreActual;
  final int? awayScoreActual;
  final MatchStatus status;
  final int? matchweek;
  final String? matchweekName;

  Match({
    required this.id,
    required this.externalId,
    required this.seasonId,
    required this.squad,
    required this.homeTeam,
    required this.awayTeam,
    required this.kickoffTime,
    this.homeScoreActual,
    this.awayScoreActual,
    required this.status,
    this.matchweek,
    this.matchweekName,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] as String,
      externalId: json['external_id'] as String,
      seasonId: json['season_id'] as String,
      squad: json['squad'] as String,
      homeTeam: json['home_team'] as String,
      awayTeam: json['away_team'] as String,
      kickoffTime: DateTime.parse(json['kickoff_time'] as String),
      homeScoreActual: json['home_score_actual'] as int?,
      awayScoreActual: json['away_score_actual'] as int?,
      status: _parseStatus(json['status'] as String),
      matchweek: json['matchweek'] as int?,
      matchweekName: json['matchweek_name'] as String?,
    );
  }

  static MatchStatus _parseStatus(String status) {
    switch (status) {
      case 'upcoming':
        return MatchStatus.upcoming;
      case 'live':
        return MatchStatus.live;
      case 'finished':
        return MatchStatus.finished;
      default:
        return MatchStatus.upcoming;
    }
  }

  bool get isLocked {
    final twoHoursBefore = kickoffTime.subtract(const Duration(hours: 2));
    return DateTime.now().isAfter(twoHoursBefore);
  }

  bool get canPredict => !isLocked && status == MatchStatus.upcoming;
}

class Prediction {
  final String? id;
  final String userId;
  final String matchId;
  final int homeScoreGuess;
  final int awayScoreGuess;
  final int? pointsAwarded;

  Prediction({
    this.id,
    required this.userId,
    required this.matchId,
    required this.homeScoreGuess,
    required this.awayScoreGuess,
    this.pointsAwarded,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      matchId: json['match_id'] as String,
      homeScoreGuess: json['home_score_guess'] as int,
      awayScoreGuess: json['away_score_guess'] as int,
      pointsAwarded: json['points_awarded'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'match_id': matchId,
      'home_score_guess': homeScoreGuess,
      'away_score_guess': awayScoreGuess,
    };
  }
}
