import 'package:flutter/material.dart';
import '../models/game_result.dart';
import '../theme/app_theme.dart';

enum LevelType {
  puzzle,
  chest,
  boss,
}

class PuzzleLevel {
  final String id;
  final int levelNumber;
  final String title;
  final String gameId;
  final CognitiveDomain domain;
  final LevelType type;
  final int targetScore1Star;
  final int targetScore2Star;
  final int targetScore3Star;
  final int gemReward;
  final String description;
  final double xOffset; // Serpentine wave alignment (-1.0 to 1.0)
  final int unitNumber;

  const PuzzleLevel({
    required this.id,
    required this.levelNumber,
    required this.title,
    required this.gameId,
    required this.domain,
    this.type = LevelType.puzzle,
    required this.targetScore1Star,
    required this.targetScore2Star,
    required this.targetScore3Star,
    required this.gemReward,
    required this.description,
    required this.xOffset,
    required this.unitNumber,
  });

  int calculateStars(int score) {
    if (score >= targetScore3Star) return 3;
    if (score >= targetScore2Star) return 2;
    if (score >= targetScore1Star) return 1;
    return 0;
  }
}

class UnitData {
  final int unitNumber;
  final String title;
  final String subtitle;
  final Color themeColor;
  final List<PuzzleLevel> levels;

  const UnitData({
    required this.unitNumber,
    required this.title,
    required this.subtitle,
    required this.themeColor,
    required this.levels,
  });
}

class LevelCurriculum {
  static const List<UnitData> units = [
    UnitData(
      unitNumber: 1,
      title: 'UNIT 1: MEMORY & SPEED FOUNDATIONS',
      subtitle: 'Ignite neural pathways with pattern recall and rapid reflexes',
      themeColor: AppTheme.purpleMemory,
      levels: [
        PuzzleLevel(
          id: 'level_1',
          levelNumber: 1,
          title: 'Spatial Awakening I',
          gameId: 'spatial_memory',
          domain: CognitiveDomain.memory,
          targetScore1Star: 1500,
          targetScore2Star: 3000,
          targetScore3Star: 4500,
          gemReward: 25,
          description: 'Memorize glowing matrix tiles and tap to recall.',
          xOffset: 0.0,
          unitNumber: 1,
        ),
        PuzzleLevel(
          id: 'level_2',
          levelNumber: 2,
          title: 'Stroop Reflex I',
          gameId: 'stroop_match',
          domain: CognitiveDomain.speed,
          targetScore1Star: 2000,
          targetScore2Star: 3500,
          targetScore3Star: 5000,
          gemReward: 30,
          description: 'Match font color and word meaning under pressure.',
          xOffset: 0.55,
          unitNumber: 1,
        ),
        PuzzleLevel(
          id: 'level_3',
          levelNumber: 3,
          title: 'Unit 1 Treasure Vault',
          gameId: 'chest',
          domain: CognitiveDomain.memory,
          type: LevelType.chest,
          targetScore1Star: 0,
          targetScore2Star: 0,
          targetScore3Star: 0,
          gemReward: 75,
          description: 'Claim your bonus gems and XP boost!',
          xOffset: 0.85,
          unitNumber: 1,
        ),
        PuzzleLevel(
          id: 'level_4',
          levelNumber: 4,
          title: 'Audio Echo I',
          gameId: 'sequence_recall',
          domain: CognitiveDomain.memory,
          targetScore1Star: 1800,
          targetScore2Star: 3200,
          targetScore3Star: 4800,
          gemReward: 35,
          description: 'Repeat the escalating tone and light sequences.',
          xOffset: 0.40,
          unitNumber: 1,
        ),
        PuzzleLevel(
          id: 'level_5',
          levelNumber: 5,
          title: 'UNIT 1 BOSS: SPEED SHOWDOWN',
          gameId: 'stroop_match',
          domain: CognitiveDomain.speed,
          type: LevelType.boss,
          targetScore1Star: 3000,
          targetScore2Star: 4800,
          targetScore3Star: 6500,
          gemReward: 100,
          description: 'Ultimate speed test! Score 4800+ for 2 stars.',
          xOffset: -0.20,
          unitNumber: 1,
        ),
      ],
    ),
    UnitData(
      unitNumber: 2,
      title: 'UNIT 2: FOCUS & PERCEPTION',
      subtitle: 'Sharpen peripheral awareness and filter out distractions',
      themeColor: AppTheme.emeraldAttention,
      levels: [
        PuzzleLevel(
          id: 'level_6',
          levelNumber: 6,
          title: 'Flock Commander I',
          gameId: 'flock_focus',
          domain: CognitiveDomain.attention,
          targetScore1Star: 1800,
          targetScore2Star: 3400,
          targetScore3Star: 5000,
          gemReward: 35,
          description: 'Track center bird orientation ignoring surrounding noise.',
          xOffset: -0.65,
          unitNumber: 2,
        ),
        PuzzleLevel(
          id: 'level_7',
          levelNumber: 7,
          title: 'Rapid Inequalities I',
          gameId: 'rapid_math',
          domain: CognitiveDomain.problemSolving,
          targetScore1Star: 2200,
          targetScore2Star: 4000,
          targetScore3Star: 5800,
          gemReward: 40,
          description: 'Solve mathematical comparisons at rapid pace.',
          xOffset: -0.80,
          unitNumber: 2,
        ),
        PuzzleLevel(
          id: 'level_8',
          levelNumber: 8,
          title: 'Perception Chest',
          gameId: 'chest',
          domain: CognitiveDomain.attention,
          type: LevelType.chest,
          targetScore1Star: 0,
          targetScore2Star: 0,
          targetScore3Star: 0,
          gemReward: 100,
          description: 'Claim your focus rewards and energy refill!',
          xOffset: -0.35,
          unitNumber: 2,
        ),
        PuzzleLevel(
          id: 'level_9',
          levelNumber: 9,
          title: 'Eagle Eye Scanner I',
          gameId: 'eagle_eye',
          domain: CognitiveDomain.attention,
          targetScore1Star: 1800,
          targetScore2Star: 3300,
          targetScore3Star: 4900,
          gemReward: 40,
          description: 'Dual-focus scanner: track central icon and peripheral target.',
          xOffset: 0.25,
          unitNumber: 2,
        ),
        PuzzleLevel(
          id: 'level_10',
          levelNumber: 10,
          title: 'UNIT 2 BOSS: FOCUS MASTER',
          gameId: 'flock_focus',
          domain: CognitiveDomain.attention,
          type: LevelType.boss,
          targetScore1Star: 3200,
          targetScore2Star: 5000,
          targetScore3Star: 7000,
          gemReward: 120,
          description: 'Master selective focus under intense distraction!',
          xOffset: 0.70,
          unitNumber: 2,
        ),
      ],
    ),
    UnitData(
      unitNumber: 3,
      title: 'UNIT 3: MENTAL AGILITY & LOGIC',
      subtitle: 'Flex your cognitive adaptability and word fluency',
      themeColor: AppTheme.coralFlexibility,
      levels: [
        PuzzleLevel(
          id: 'level_11',
          levelNumber: 11,
          title: 'Rule Switcher I',
          gameId: 'rule_switcher',
          domain: CognitiveDomain.flexibility,
          targetScore1Star: 2000,
          targetScore2Star: 3600,
          targetScore3Star: 5200,
          gemReward: 45,
          description: 'Switch rules dynamically between numbers and colors.',
          xOffset: 0.50,
          unitNumber: 3,
        ),
        PuzzleLevel(
          id: 'level_12',
          levelNumber: 12,
          title: 'Anagram Surge I',
          gameId: 'anagram_surge',
          domain: CognitiveDomain.language,
          targetScore1Star: 2400,
          targetScore2Star: 4200,
          targetScore3Star: 6000,
          gemReward: 45,
          description: 'Unscramble hidden words before time runs out.',
          xOffset: -0.10,
          unitNumber: 3,
        ),
        PuzzleLevel(
          id: 'level_13',
          levelNumber: 13,
          title: 'Agility Supply Chest',
          gameId: 'chest',
          domain: CognitiveDomain.flexibility,
          type: LevelType.chest,
          targetScore1Star: 0,
          targetScore2Star: 0,
          targetScore3Star: 0,
          gemReward: 125,
          description: 'Claim your mental agility chest bonuses!',
          xOffset: -0.65,
          unitNumber: 3,
        ),
        PuzzleLevel(
          id: 'level_14',
          levelNumber: 14,
          title: 'Spatial Matrix II',
          gameId: 'spatial_memory',
          domain: CognitiveDomain.memory,
          targetScore1Star: 2500,
          targetScore2Star: 4200,
          targetScore3Star: 6200,
          gemReward: 50,
          description: 'Advanced 5x5 spatial memory grid recall challenge.',
          xOffset: -0.40,
          unitNumber: 3,
        ),
        PuzzleLevel(
          id: 'level_15',
          levelNumber: 15,
          title: 'UNIT 3 BOSS: MATH MADNESS',
          gameId: 'rapid_math',
          domain: CognitiveDomain.problemSolving,
          type: LevelType.boss,
          targetScore1Star: 3500,
          targetScore2Star: 5500,
          targetScore3Star: 7800,
          gemReward: 150,
          description: 'High-speed inequality logic challenge!',
          xOffset: 0.15,
          unitNumber: 3,
        ),
      ],
    ),
    UnitData(
      unitNumber: 4,
      title: 'UNIT 4: GRAND MASTER GYM',
      subtitle: 'Conquer elite level brain puzzles for ultimate mastery',
      themeColor: AppTheme.amberProblemSolving,
      levels: [
        PuzzleLevel(
          id: 'level_16',
          levelNumber: 16,
          title: 'Anagram Surge II',
          gameId: 'anagram_surge',
          domain: CognitiveDomain.language,
          targetScore1Star: 3000,
          targetScore2Star: 5000,
          targetScore3Star: 7200,
          gemReward: 60,
          description: 'Solve complex anagram puzzles under strict timer.',
          xOffset: 0.65,
          unitNumber: 4,
        ),
        PuzzleLevel(
          id: 'level_17',
          levelNumber: 17,
          title: 'Eagle Eye Scanner II',
          gameId: 'eagle_eye',
          domain: CognitiveDomain.attention,
          targetScore1Star: 2800,
          targetScore2Star: 4600,
          targetScore3Star: 6600,
          gemReward: 60,
          description: 'High-speed peripheral target matching.',
          xOffset: 0.35,
          unitNumber: 4,
        ),
        PuzzleLevel(
          id: 'level_18',
          levelNumber: 18,
          title: 'Grand Master Vault',
          gameId: 'chest',
          domain: CognitiveDomain.problemSolving,
          type: LevelType.chest,
          targetScore1Star: 0,
          targetScore2Star: 0,
          targetScore3Star: 0,
          gemReward: 200,
          description: 'Claim elite master gem reward!',
          xOffset: -0.20,
          unitNumber: 4,
        ),
        PuzzleLevel(
          id: 'level_19',
          levelNumber: 19,
          title: 'Rule Switcher II',
          gameId: 'rule_switcher',
          domain: CognitiveDomain.flexibility,
          targetScore1Star: 3200,
          targetScore2Star: 5200,
          targetScore3Star: 7400,
          gemReward: 65,
          description: 'Lightning-fast task switching flexibility.',
          xOffset: -0.70,
          unitNumber: 4,
        ),
        PuzzleLevel(
          id: 'level_20',
          levelNumber: 20,
          title: 'GRAND CHAMPION PUZZLE',
          gameId: 'sequence_recall',
          domain: CognitiveDomain.memory,
          type: LevelType.boss,
          targetScore1Star: 4000,
          targetScore2Star: 6500,
          targetScore3Star: 9000,
          gemReward: 250,
          description: 'The ultimate memory sequence test for Mind Lab Champions!',
          xOffset: 0.0,
          unitNumber: 4,
        ),
      ],
    ),
  ];

  static List<PuzzleLevel> get allLevels {
    return units.expand((u) => u.levels).toList();
  }

  static PuzzleLevel? getLevelById(String id) {
    for (var u in units) {
      for (var l in u.levels) {
        if (l.id == id) return l;
      }
    }
    return null;
  }
}
