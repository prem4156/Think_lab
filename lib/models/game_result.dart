enum CognitiveDomain {
  speed,
  memory,
  attention,
  flexibility,
  problemSolving,
  language,
}

extension CognitiveDomainExtension on CognitiveDomain {
  String get displayName {
    switch (this) {
      case CognitiveDomain.speed:
        return 'Speed';
      case CognitiveDomain.memory:
        return 'Memory';
      case CognitiveDomain.attention:
        return 'Attention';
      case CognitiveDomain.flexibility:
        return 'Flexibility';
      case CognitiveDomain.problemSolving:
        return 'Problem Solving';
      case CognitiveDomain.language:
        return 'Language';
    }
  }
}

class GameResult {
  final String gameId;
  final String gameTitle;
  final CognitiveDomain domain;
  final int score;
  final double accuracyPercent;
  final int levelReached;
  final int bpiGain;
  final DateTime timestamp;

  GameResult({
    required this.gameId,
    required this.gameTitle,
    required this.domain,
    required this.score,
    required this.accuracyPercent,
    required this.levelReached,
    required this.bpiGain,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'gameTitle': gameTitle,
        'domain': domain.index,
        'score': score,
        'accuracyPercent': accuracyPercent,
        'levelReached': levelReached,
        'bpiGain': bpiGain,
        'timestamp': timestamp.toIso8601String(),
      };

  factory GameResult.fromJson(Map<String, dynamic> json) => GameResult(
        gameId: json['gameId'],
        gameTitle: json['gameTitle'],
        domain: CognitiveDomain.values[json['domain'] ?? 0],
        score: json['score'] ?? 0,
        accuracyPercent: (json['accuracyPercent'] ?? 0.0).toDouble(),
        levelReached: json['levelReached'] ?? 1,
        bpiGain: json['bpiGain'] ?? 0,
        timestamp: DateTime.parse(json['timestamp']),
      );
}
