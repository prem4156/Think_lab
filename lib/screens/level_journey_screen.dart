import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/game_result.dart';
import '../models/level_data.dart';
import '../models/user_level_progress.dart';
import '../models/user_profile.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cozy_city_journey_game.dart';
import 'game_modal_tutorial.dart';
import 'games/anagram_surge_game.dart';
import 'games/eagle_eye_game.dart';
import 'games/flock_focus_game.dart';
import 'games/rapid_math_game.dart';
import 'games/rule_switcher_game.dart';
import 'games/sequence_recall_game.dart';
import 'games/spatial_memory_game.dart';
import 'games/stroop_match_game.dart';

class LevelJourneyScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onProgressUpdated;

  const LevelJourneyScreen({
    Key? key,
    required this.profile,
    required this.onProgressUpdated,
  }) : super(key: key);

  @override
  State<LevelJourneyScreen> createState() => _LevelJourneyScreenState();
}

class _LevelJourneyScreenState extends State<LevelJourneyScreen> {
  UserLevelProgress? levelProgress;
  bool isLoading = true;
  late final CozyCityJourneyGame _cozyCityGame;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _cozyCityGame = CozyCityJourneyGame(
      units: LevelCurriculum.units,
      levelProgress: levelProgress,
      onLevelSelected: _openLevelDetailsModal,
    );
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (levelProgress != null) {
        _cozyCityGame.updateData(levelProgress!, _scrollController.offset);
      }
    });
    _loadProgress();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final prog = await StorageService.instance.loadLevelProgress();
    if (mounted) {
      setState(() {
        levelProgress = prog;
        isLoading = false;
      });
      _cozyCityGame.updateData(prog, _scrollController.hasClients ? _scrollController.offset : 0.0);
    }
  }

  void _onPuzzleFinished(PuzzleLevel level, int score) async {
    if (levelProgress == null) return;
    int starsEarned = level.calculateStars(score);

    // Save stars & gems
    Map<String, int> starsMap = Map.from(levelProgress!.levelStars);
    int prevStars = starsMap[level.id] ?? 0;
    int newGems = levelProgress!.gems;

    if (starsEarned > prevStars) {
      starsMap[level.id] = starsEarned;
      newGems += level.gemReward * (starsEarned - prevStars);
    }

    // Unlock next level
    String nextLevelId = 'level_${level.levelNumber + 1}';
    if (!starsMap.containsKey(nextLevelId)) {
      starsMap[nextLevelId] = 0;
    }

    UserLevelProgress updated = UserLevelProgress(
      levelStars: starsMap,
      openedChests: levelProgress!.openedChests,
      gems: newGems,
      hearts: levelProgress!.hearts,
    );

    await StorageService.instance.saveLevelProgress(updated);
    await _loadProgress();
    widget.onProgressUpdated();
  }

  void _claimChest(PuzzleLevel level) async {
    if (levelProgress == null) return;
    if (levelProgress!.openedChests.contains(level.id)) return;

    SoundService.instance.playVictory();

    Set<String> updatedChests = Set.from(levelProgress!.openedChests)..add(level.id);
    int newGems = levelProgress!.gems + level.gemReward;

    // Unlock next level after chest
    Map<String, int> starsMap = Map.from(levelProgress!.levelStars);
    String nextLevelId = 'level_${level.levelNumber + 1}';
    if (!starsMap.containsKey(nextLevelId)) {
      starsMap[nextLevelId] = 0;
    }

    UserLevelProgress updated = UserLevelProgress(
      levelStars: starsMap,
      openedChests: updatedChests,
      gems: newGems,
      hearts: levelProgress!.hearts,
    );

    await StorageService.instance.saveLevelProgress(updated);
    await _loadProgress();
    widget.onProgressUpdated();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.amberProblemSolving,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const Text('🎉 ', style: TextStyle(fontSize: 20)),
              Expanded(
                child: Text(
                  'Claimed ${level.gemReward} Gems from ${level.title}!',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _openLevelDetailsModal(PuzzleLevel level) {
    if (levelProgress == null) return;
    SoundService.instance.playTap();

    bool isUnlocked = levelProgress!.isLevelUnlocked(level.levelNumber);
    int currentStars = levelProgress!.levelStars[level.id] ?? 0;
    bool isChestOpened = levelProgress!.openedChests.contains(level.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final meta = GameModalTutorial.gameMeta[level.gameId] ??
            GameModalTutorial.gameMeta['spatial_memory']!;
        Color domainColor = meta['color'] as Color;
        IconData iconData = level.type == LevelType.chest
            ? Icons.inventory_2_rounded
            : level.type == LevelType.boss
                ? Icons.workspace_premium_rounded
                : (meta['icon'] as IconData);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.bgDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCardBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),

                // Level Header Icon & Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: domainColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: domainColor, width: 2),
                      ),
                      child: Icon(iconData, color: domainColor, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: domainColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'LEVEL ${level.levelNumber}',
                                  style: TextStyle(
                                    color: domainColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                level.domain.displayName.toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            level.title,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Star Targets or Chest Details
                if (level.type != LevelType.chest) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.surfaceCardBorder),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'STAR THRESHOLDS',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Row(
                              children: List.generate(3, (index) {
                                bool filled = index < currentStars;
                                return Icon(
                                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: filled ? AppTheme.amberProblemSolving : AppTheme.textMuted,
                                  size: 20,
                                );
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStarRequirement('⭐ 1 Star', level.targetScore1Star, currentStars >= 1),
                            _buildStarRequirement('⭐⭐ 2 Stars', level.targetScore2Star, currentStars >= 2),
                            _buildStarRequirement('⭐⭐⭐ 3 Stars', level.targetScore3Star, currentStars >= 3),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.amberProblemSolving.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.amberProblemSolving.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Text('🎁 ', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Treasure Chest Reward',
                                style: TextStyle(
                                  color: AppTheme.amberProblemSolving,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Contains +${level.gemReward} Gems & XP boost!',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Description Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.surfaceCardBorder),
                  ),
                  child: Text(
                    level.description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: isUnlocked
                          ? LinearGradient(colors: [domainColor, domainColor.withValues(alpha: 0.8)])
                          : null,
                      color: isUnlocked ? null : AppTheme.surfaceCardBorder,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isUnlocked
                          ? [
                              BoxShadow(
                                color: domainColor.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: !isUnlocked
                          ? null
                          : () {
                              Navigator.pop(context); // Close sheet
                              if (level.type == LevelType.chest) {
                                _claimChest(level);
                              } else {
                                _launchPuzzleGame(level);
                              }
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            !isUnlocked
                                ? Icons.lock_rounded
                                : level.type == LevelType.chest
                                    ? (isChestOpened ? Icons.check_circle : Icons.card_giftcard)
                                    : (currentStars > 0 ? Icons.replay : Icons.play_arrow_rounded),
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            !isUnlocked
                                ? 'LOCKED (Complete previous)'
                                : level.type == LevelType.chest
                                    ? (isChestOpened ? 'ALREADY CLAIMED' : 'CLAIM CHEST REWARD')
                                    : (currentStars > 0 ? 'REPLAY PUZZLE' : 'START PUZZLE'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStarRequirement(String label, int pts, bool achieved) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: achieved ? AppTheme.amberProblemSolving : AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$pts pts',
          style: TextStyle(
            color: achieved ? AppTheme.textPrimary : AppTheme.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  void _launchPuzzleGame(PuzzleLevel level) {
    Widget gameWidget;

    void onCompleteCallback() {
      // Fetch latest game score from Storage service history
      StorageService.instance.loadGameHistory().then((history) {
        if (history.isNotEmpty) {
          int lastScore = history.first.score;
          _onPuzzleFinished(level, lastScore);
        }
      });
    }

    switch (level.gameId) {
      case 'spatial_memory':
        gameWidget = SpatialMemoryGame(onGameComplete: onCompleteCallback);
        break;
      case 'sequence_recall':
        gameWidget = SequenceRecallGame(onGameComplete: onCompleteCallback);
        break;
      case 'stroop_match':
        gameWidget = StroopMatchGame(onGameComplete: onCompleteCallback);
        break;
      case 'rapid_math':
        gameWidget = RapidMathGame(onGameComplete: onCompleteCallback);
        break;
      case 'flock_focus':
        gameWidget = FlockFocusGame(onGameComplete: onCompleteCallback);
        break;
      case 'eagle_eye':
        gameWidget = EagleEyeGame(onGameComplete: onCompleteCallback);
        break;
      case 'rule_switcher':
        gameWidget = RuleSwitcherGame(onGameComplete: onCompleteCallback);
        break;
      case 'anagram_surge':
        gameWidget = AnagramSurgeGame(onGameComplete: onCompleteCallback);
        break;
      default:
        gameWidget = SpatialMemoryGame(onGameComplete: onCompleteCallback);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => gameWidget),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || levelProgress == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF121024),
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryNeon),
        ),
      );
    }

    int activeLevelNum = levelProgress!.highestUnlockedLevelIndex;

    return Scaffold(
      backgroundColor: const Color(0xFF121024),
      body: Stack(
        children: [
          // Animated Cozy City Flame Background Canvas
          Positioned.fill(
            child: GameWidget(game: _cozyCityGame),
          ),

          // Level Journey Scroll Area & Stats Bar
          SafeArea(
            child: Column(
              children: [
                // Top Duolingo Header Stats Bar
                _buildTopHeaderStats(),

                // Serpentine Level Map Scroll Area
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      children: LevelCurriculum.units.map((unit) {
                        return _buildUnitSection(unit, activeLevelNum);
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeaderStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16122B).withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceCardBorder.withValues(alpha: 0.3)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Streak Counter
          _buildStatChip('🔥', '${widget.profile.currentStreak}', AppTheme.amberProblemSolving),

          // Gems Counter
          _buildStatChip('💎', '${levelProgress!.gems}', AppTheme.cyanSpeed),

          // Stars Counter
          _buildStatChip('⭐', '${levelProgress!.totalStars}/60', AppTheme.purpleMemory),

          // Energy / Hearts
          _buildStatChip('❤️', '${levelProgress!.hearts}/5', AppTheme.pinkLanguage),
        ],
      ),
    );
  }

  Widget _buildStatChip(String emoji, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            val,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitSection(UnitData unit, int activeLevelNum) {
    // Count completed levels in unit
    int completedCount = 0;
    for (var l in unit.levels) {
      if ((levelProgress!.levelStars[l.id] ?? 0) > 0 || levelProgress!.openedChests.contains(l.id)) {
        completedCount++;
      }
    }
    double progressFraction = completedCount / unit.levels.length;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          // Unit Header Banner Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  unit.themeColor.withValues(alpha: 0.35),
                  const Color(0xFF1D1736).withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: unit.themeColor.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: unit.themeColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      unit.title,
                      style: TextStyle(
                        color: unit.themeColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      '$completedCount/${unit.levels.length}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  unit.subtitle,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    backgroundColor: AppTheme.bgDark,
                    color: unit.themeColor,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Levels in unit connected by serpentine path
          Stack(
            alignment: Alignment.topCenter,
            children: [
              // Background Curved Connecting Path
              Positioned.fill(
                child: CustomPaint(
                  painter: SerpentinePathPainter(
                    levels: unit.levels,
                    progress: levelProgress!,
                    themeColor: unit.themeColor,
                  ),
                ),
              ),

              // Level Nodes List
              Column(
                children: unit.levels.map((level) {
                  return _buildLevelNode(level, activeLevelNum, unit.themeColor);
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelNode(PuzzleLevel level, int activeLevelNum, Color unitColor) {
    bool isUnlocked = levelProgress!.isLevelUnlocked(level.levelNumber);
    bool isActive = isUnlocked && level.levelNumber == activeLevelNum;
    int stars = levelProgress!.levelStars[level.id] ?? 0;
    bool isChestOpened = levelProgress!.openedChests.contains(level.id);

    final meta = GameModalTutorial.gameMeta[level.gameId] ??
        GameModalTutorial.gameMeta['spatial_memory']!;
    Color domainColor = meta['color'] as Color;

    // Node layout horizontal offset for serpentine trail
    double xOffset = level.xOffset;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: Align(
        alignment: Alignment(xOffset, 0),
        child: GestureDetector(
          onTap: () => _openLevelDetailsModal(level),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Static Active Glow Outer Ring (No looping pulse animation)
              if (isActive)
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26), // Outer Squircle Aura
                    color: AppTheme.amberProblemSolving.withValues(alpha: 0.3),
                    border: Border.all(color: AppTheme.amberProblemSolving, width: 2),
                  ),
                ),

              // Squircle Level Button Container (3D Bevel Box)
              Container(
                width: level.type == LevelType.boss ? 76 : 66,
                height: level.type == LevelType.boss ? 76 : 66,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22), // SQUIRCLE SHAPE
                  gradient: isUnlocked
                      ? LinearGradient(
                          colors: [domainColor, domainColor.withValues(alpha: 0.85)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isUnlocked ? null : const Color(0xFF3F3D4D),
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5), // 3D Bottom Drop Shadow
                          ),
                        ]
                      : [],
                  border: Border.all(
                    color: isUnlocked
                        ? (isActive ? const Color(0xFFFFD700) : Colors.white.withValues(alpha: 0.8))
                        : const Color(0xFF5A5868),
                    width: isActive ? 3.5 : 2.5,
                  ),
                ),
                child: Center(
                  child: _getNodeIcon(level, isUnlocked, stars, isChestOpened, domainColor),
                ),
              ),

              // Crisp Static START Badge Overhead (No animation jitter)
              if (isActive)
                Positioned(
                  top: -46,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Text(
                          'START!',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '🧠',
                        style: TextStyle(fontSize: 22),
                      ),
                    ],
                  ),
                ),

              // Stars Display overhead for completed levels
              if (isUnlocked && stars > 0 && level.type != LevelType.chest)
                Positioned(
                  top: -18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.amberProblemSolving),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (idx) {
                        return Icon(
                          idx < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 13,
                          color: idx < stars ? AppTheme.amberProblemSolving : AppTheme.textMuted,
                        );
                      }),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getNodeIcon(PuzzleLevel level, bool isUnlocked, int stars, bool isChestOpened, Color domainColor) {
    if (!isUnlocked) {
      return const Icon(Icons.lock_rounded, color: AppTheme.textMuted, size: 24);
    }

    if (level.type == LevelType.chest) {
      return Icon(
        isChestOpened ? Icons.inventory_2_outlined : Icons.inventory_2_rounded,
        color: Colors.white,
        size: 30,
      );
    }

    if (level.type == LevelType.boss) {
      return const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 36);
    }

    if (stars > 0) {
      return const Icon(Icons.check_rounded, color: Colors.white, size: 30);
    }

    final meta = GameModalTutorial.gameMeta[level.gameId] ??
        GameModalTutorial.gameMeta['spatial_memory']!;
    IconData icon = meta['icon'] as IconData;

    return Icon(icon, color: Colors.white, size: 28);
  }
}

// Custom Painter for City Road Trail connecting Level Nodes
class SerpentinePathPainter extends CustomPainter {
  final List<PuzzleLevel> levels;
  final UserLevelProgress progress;
  final Color themeColor;

  SerpentinePathPainter({
    required this.levels,
    required this.progress,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.length < 2) return;

    double centerX = size.width / 2;
    double verticalSpacing = (size.height) / levels.length;

    // Draw secondary branching side paths splitting off from each level node
    final branchBorder = Paint()
      ..color = const Color(0xFF4A341E)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final branchDirt = Paint()
      ..color = const Color(0xFF7A5531)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < levels.length; i++) {
      var level = levels[i];
      double nodeX = centerX + level.xOffset * (size.width * 0.32);
      double nodeY = (i * verticalSpacing) + (verticalSpacing / 2);

      double branchDirection = (i % 2 == 0) ? -1.0 : 1.0;
      double endX = nodeX + (branchDirection * (size.width * 0.26));
      double endY = nodeY + ((i % 3 - 1) * 20.0);

      canvas.drawLine(Offset(nodeX, nodeY), Offset(endX, endY), branchBorder);
      canvas.drawLine(Offset(nodeX, nodeY), Offset(endX, endY), branchDirt);
    }

    // Draw main Clash journey road
    for (int i = 0; i < levels.length - 1; i++) {
      var current = levels[i];
      var next = levels[i + 1];

      double startX = centerX + current.xOffset * (size.width * 0.32);
      double startY = (i * verticalSpacing) + (verticalSpacing / 2);

      double endX = centerX + next.xOffset * (size.width * 0.32);
      double endY = ((i + 1) * verticalSpacing) + (verticalSpacing / 2);

      Path path = Path();
      path.moveTo(startX, startY);

      double controlY1 = startY + (endY - startY) * 0.5;
      double controlY2 = startY + (endY - startY) * 0.5;
      path.cubicTo(startX, controlY1, endX, controlY2, endX, endY);

      bool isNextUnlocked = progress.isLevelUnlocked(next.levelNumber);

      // 1. Road Curb Border
      final curbPaint = Paint()
        ..color = isNextUnlocked ? const Color(0xFF4A341E) : const Color(0xFF2D2B38)
        ..strokeWidth = 34
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, curbPaint);

      // 2. Road Dirt Surface
      final surfacePaint = Paint()
        ..color = isNextUnlocked ? const Color(0xFF8C6239) : const Color(0xFF3F3D4D)
        ..strokeWidth = 26
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, surfacePaint);

      // 3. Dashed Center Line
      final dashPaint = Paint()
        ..color = isNextUnlocked ? const Color(0xFFFFB703).withValues(alpha: 0.8) : const Color(0xFF6B6B78)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, dashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SerpentinePathPainter oldDelegate) {
    return true;
  }
}
