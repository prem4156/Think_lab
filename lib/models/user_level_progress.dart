class UserLevelProgress {
  final Map<String, int> levelStars; // levelId -> stars (1..3)
  final Set<String> openedChests; // chest levelIds
  final int gems;
  final int hearts;

  UserLevelProgress({
    required this.levelStars,
    required this.openedChests,
    required this.gems,
    this.hearts = 5,
  });

  factory UserLevelProgress.initial() {
    return UserLevelProgress(
      levelStars: {
        'level_1': 0, // Level 1 is available initially
      },
      openedChests: {},
      gems: 150,
      hearts: 5,
    );
  }

  int get totalStars {
    return levelStars.values.fold(0, (sum, val) => sum + val);
  }

  bool isLevelUnlocked(int levelNumber) {
    if (levelNumber <= 1) return true;
    String prevLevelId = 'level_${levelNumber - 1}';
    // Chest levels unlock automatically once reached
    if (prevLevelId.contains('chest') || levelStars.containsKey(prevLevelId)) {
      return true;
    }
    return false;
  }

  int get highestUnlockedLevelIndex {
    int maxLvl = 1;
    for (int i = 1; i <= 20; i++) {
      if (isLevelUnlocked(i)) {
        maxLvl = i;
      }
    }
    return maxLvl;
  }

  Map<String, dynamic> toJson() => {
        'levelStars': levelStars,
        'openedChests': openedChests.toList(),
        'gems': gems,
        'hearts': hearts,
      };

  factory UserLevelProgress.fromJson(Map<String, dynamic> json) {
    Map<String, int> starsMap = {};
    if (json['levelStars'] != null) {
      final raw = json['levelStars'] as Map<String, dynamic>;
      raw.forEach((k, v) {
        starsMap[k] = (v as num).toInt();
      });
    }

    Set<String> chests = {};
    if (json['openedChests'] != null) {
      chests = (json['openedChests'] as List).map((e) => e.toString()).toSet();
    }

    return UserLevelProgress(
      levelStars: starsMap.isEmpty ? {'level_1': 0} : starsMap,
      openedChests: chests,
      gems: json['gems'] ?? 150,
      hearts: json['hearts'] ?? 5,
    );
  }
}
