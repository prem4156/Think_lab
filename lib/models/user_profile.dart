import 'game_result.dart';

class UserProfile {
  String name;
  String email;
  int overallBpi;
  Map<CognitiveDomain, int> domainBpi;
  int currentStreak;
  int bestStreak;
  DateTime? lastWorkoutDate;
  int totalGamesPlayed;
  int totalWorkoutsCompleted;
  Map<String, int> highScores;

  UserProfile({
    this.name = 'Mind Trainer',
    this.email = 'trainer@thinkcity.app',
    required this.overallBpi,
    required this.domainBpi,
    required this.currentStreak,
    required this.bestStreak,
    this.lastWorkoutDate,
    required this.totalGamesPlayed,
    required this.totalWorkoutsCompleted,
    required this.highScores,
  });

  factory UserProfile.defaultProfile() {
    return UserProfile(
      name: 'Mind Trainer',
      email: 'trainer@thinkcity.app',
      overallBpi: 620,
      domainBpi: {
        CognitiveDomain.speed: 600,
        CognitiveDomain.memory: 640,
        CognitiveDomain.attention: 610,
        CognitiveDomain.flexibility: 630,
        CognitiveDomain.problemSolving: 650,
        CognitiveDomain.language: 600,
      },
      currentStreak: 3,
      bestStreak: 7,
      lastWorkoutDate: null,
      totalGamesPlayed: 12,
      totalWorkoutsCompleted: 4,
      highScores: {
        'spatial_memory': 4800,
        'sequence_recall': 3600,
        'stroop_match': 5200,
        'rapid_math': 6100,
        'flock_focus': 4200,
        'eagle_eye': 3900,
        'rule_switcher': 4500,
        'anagram_surge': 5000,
      },
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'overallBpi': overallBpi,
        'domainBpi': domainBpi.map((k, v) => MapEntry(k.index.toString(), v)),
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'lastWorkoutDate': lastWorkoutDate?.toIso8601String(),
        'totalGamesPlayed': totalGamesPlayed,
        'totalWorkoutsCompleted': totalWorkoutsCompleted,
        'highScores': highScores,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    Map<CognitiveDomain, int> domainMap = {};
    if (json['domainBpi'] != null) {
      final map = json['domainBpi'] as Map<String, dynamic>;
      map.forEach((key, val) {
        int idx = int.tryParse(key) ?? 0;
        if (idx >= 0 && idx < CognitiveDomain.values.length) {
          domainMap[CognitiveDomain.values[idx]] = (val as num).toInt();
        }
      });
    }

    // Fill defaults if any domain missing
    for (var domain in CognitiveDomain.values) {
      domainMap.putIfAbsent(domain, () => 600);
    }

    return UserProfile(
      name: json['name'] ?? 'Alex Rivera',
      email: json['email'] ?? 'trainer@thinkcity.app',
      overallBpi: json['overallBpi'] ?? 620,
      domainBpi: domainMap,
      currentStreak: json['currentStreak'] ?? 0,
      bestStreak: json['bestStreak'] ?? 0,
      lastWorkoutDate: json['lastWorkoutDate'] != null
          ? DateTime.parse(json['lastWorkoutDate'])
          : null,
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
      totalWorkoutsCompleted: json['totalWorkoutsCompleted'] ?? 0,
      highScores: Map<String, int>.from(json['highScores'] ?? {}),
    );
  }
}
