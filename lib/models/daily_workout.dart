class DailyWorkout {
  final String dateKey; // YYYY-MM-DD
  final List<String> gameIds;
  final List<String> completedGameIds;

  DailyWorkout({
    required this.dateKey,
    required this.gameIds,
    required this.completedGameIds,
  });

  bool get isCompleted => completedGameIds.length >= gameIds.length;

  double get progressFraction =>
      gameIds.isEmpty ? 0.0 : completedGameIds.length / gameIds.length;

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'gameIds': gameIds,
        'completedGameIds': completedGameIds,
      };

  factory DailyWorkout.fromJson(Map<String, dynamic> json) => DailyWorkout(
        dateKey: json['dateKey'] ?? '',
        gameIds: List<String>.from(json['gameIds'] ?? []),
        completedGameIds: List<String>.from(json['completedGameIds'] ?? []),
      );

  factory DailyWorkout.generateForToday() {
    final now = DateTime.now();
    final dateKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Recommend 3 varied games daily
    final List<String> catalog = [
      'stroop_match',
      'spatial_memory',
      'flock_focus',
      'rapid_math',
      'rule_switcher',
      'sequence_recall',
      'eagle_eye',
      'anagram_surge',
    ];

    // Pick 3 based on day of year hash
    int dayHash = now.year * 365 + now.month * 31 + now.day;
    List<String> todayGames = [];
    for (int i = 0; i < 3; i++) {
      int idx = (dayHash + i * 3) % catalog.length;
      if (!todayGames.contains(catalog[idx])) {
        todayGames.add(catalog[idx]);
      }
    }
    // Ensure 3 games
    for (var g in catalog) {
      if (todayGames.length >= 3) break;
      if (!todayGames.contains(g)) todayGames.add(g);
    }

    return DailyWorkout(
      dateKey: dateKey,
      gameIds: todayGames,
      completedGameIds: [],
    );
  }
}
