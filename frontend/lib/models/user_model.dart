class UserModel {
  final String id;
  final String username;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UserSeasonStats {
  final String userId;
  final String seasonId;
  final int totalPoints;
  final int exactHits;
  final String? goldenBootPickMen;
  final String? goldenBootPickWomen;
  final String? yellowCardPick;
  final String? redCardPick;
  final bool? goldenBootHit;
  final bool? yellowCardHit;
  final bool? redCardHit;
  final int? finalRank;

  UserSeasonStats({
    required this.userId,
    required this.seasonId,
    required this.totalPoints,
    required this.exactHits,
    this.goldenBootPickMen,
    this.goldenBootPickWomen,
    this.yellowCardPick,
    this.redCardPick,
    this.goldenBootHit,
    this.yellowCardHit,
    this.redCardHit,
    this.finalRank,
  });

  factory UserSeasonStats.fromJson(Map<String, dynamic> json) {
    return UserSeasonStats(
      userId: json['user_id'] as String,
      seasonId: json['season_id'] as String,
      totalPoints: json['total_points'] as int? ?? 0,
      exactHits: json['exact_hits'] as int? ?? 0,
      goldenBootPickMen: json['golden_boot_pick_men'] as String?,
      goldenBootPickWomen: json['golden_boot_pick_women'] as String?,
      yellowCardPick: json['yellow_card_pick'] as String?,
      redCardPick: json['red_card_pick'] as String?,
      goldenBootHit: json['golden_boot_hit'] as bool?,
      yellowCardHit: json['yellow_card_hit'] as bool?,
      redCardHit: json['red_card_hit'] as bool?,
      finalRank: json['final_rank'] as int?,
    );
  }
}
