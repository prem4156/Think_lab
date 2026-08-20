import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_result.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../game_result_screen.dart';

class SpatialMemoryGame extends StatefulWidget {
  final VoidCallback? onGameComplete;

  const SpatialMemoryGame({Key? key, this.onGameComplete}) : super(key: key);

  @override
  _SpatialMemoryGameState createState() => _SpatialMemoryGameState();
}

class _SpatialMemoryGameState extends State<SpatialMemoryGame> {
  int level = 1;
  int score = 0;
  int consecutiveWins = 0;
  int totalRounds = 0;
  int correctRounds = 0;
  int timeLeft = 45;
  Timer? gameTimer;
  Timer? flashTimer;

  int gridSize = 3; // 3x3 at start
  int targetTileCount = 3;
  Set<int> targetIndices = {};
  Set<int> selectedIndices = {};
  bool isShowingPattern = false;
  bool isInputAllowed = false;

  @override
  void initState() {
    super.initState();
    startOverallTimer();
    startNewRound();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    flashTimer?.cancel();
    super.dispose();
  }

  void startOverallTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft <= 1) {
        timer.cancel();
        endGame();
      } else {
        setState(() {
          timeLeft--;
        });
      }
    });
  }

  void startNewRound() {
    setState(() {
      isShowingPattern = true;
      isInputAllowed = false;
      selectedIndices.clear();
      targetIndices.clear();

      // Dynamic difficulty scaling
      if (level <= 2) {
        gridSize = 3;
        targetTileCount = 3 + level;
      } else if (level <= 5) {
        gridSize = 4;
        targetTileCount = 4 + (level - 2);
      } else {
        gridSize = 5;
        targetTileCount = 6 + (level - 5);
      }

      int totalCells = gridSize * gridSize;
      Random r = Random();
      while (targetIndices.length < targetTileCount) {
        targetIndices.add(r.nextInt(totalCells));
      }
    });

    // Show pattern brief flash
    int flashDurationMs = max(900, 1800 - (level * 80));
    flashTimer = Timer(Duration(milliseconds: flashDurationMs), () {
      if (mounted) {
        setState(() {
          isShowingPattern = false;
          isInputAllowed = true;
        });
      }
    });
  }

  void handleTileTap(int index) {
    if (!isInputAllowed || selectedIndices.contains(index)) return;

    SoundService.instance.playTap();

    setState(() {
      selectedIndices.add(index);
    });

    // Wrong tile hit!
    if (!targetIndices.contains(index)) {
      SoundService.instance.playWrong();
      setState(() {
        isInputAllowed = false;
        consecutiveWins = 0;
        totalRounds++;
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) startNewRound();
      });
      return;
    }

    // All correct target tiles found!
    if (selectedIndices.length == targetIndices.length) {
      SoundService.instance.playCorrect();
      totalRounds++;
      correctRounds++;
      consecutiveWins++;

      int roundPoints = 300 + (level * 150) + (consecutiveWins * 50);
      setState(() {
        score += roundPoints;
        isInputAllowed = false;
        if (consecutiveWins >= 2) {
          level++;
          consecutiveWins = 0;
          SoundService.instance.playLevelUp();
        }
      });

      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) startNewRound();
      });
    }
  }

  void endGame() {
    gameTimer?.cancel();
    flashTimer?.cancel();

    double accuracy =
        totalRounds == 0 ? 0.0 : (correctRounds / totalRounds) * 100.0;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameId: 'spatial_memory',
          gameTitle: 'Spatial Memory',
          domain: CognitiveDomain.memory,
          rawScore: score,
          accuracyPercent: accuracy,
          levelReached: level,
          onComplete: widget.onGameComplete,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Spatial Memory Matrix'),
        actions: [
          IconButton(
            icon: Icon(
              SoundService.instance.isMuted
                  ? Icons.volume_off
                  : Icons.volume_up,
              color: AppTheme.purpleMemory,
            ),
            onPressed: () {
              setState(() {
                SoundService.instance.toggleMute();
              });
            },
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Top HUD (Timer, Score, Level)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceCardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _hudStat('TIME', '$timeLeft s', AppTheme.coralFlexibility),
                    _hudStat('SCORE', '$score', AppTheme.purpleMemory),
                    _hudStat('LEVEL', 'Lvl $level', AppTheme.primaryNeon),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Status indicator banner
              Text(
                isShowingPattern
                  ? 'MEMORIZE THE HIGHLIGHTED TILES!'
                  : 'TAP THE RECALLED TILES',
                style: TextStyle(
                  color: isShowingPattern
                      ? AppTheme.amberProblemSolving
                      : AppTheme.purpleMemory,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 24),

              // Interactive Grid
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridSize,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: gridSize * gridSize,
                      itemBuilder: (context, index) {
                        bool isTarget = targetIndices.contains(index);
                        bool isSelected = selectedIndices.contains(index);

                        Color tileColor = AppTheme.surfaceCard;
                        BorderSide borderSide = const BorderSide(
                            color: AppTheme.surfaceCardBorder, width: 1.5);

                        if (isShowingPattern && isTarget) {
                          tileColor = AppTheme.purpleMemory;
                        } else if (isSelected) {
                          if (isTarget) {
                            tileColor = AppTheme.emeraldAttention;
                          } else {
                            tileColor = AppTheme.coralFlexibility;
                          }
                        }

                        return GestureDetector(
                          onTap: () => handleTileTap(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: tileColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.fromBorderSide(borderSide),
                              boxShadow: (isShowingPattern && isTarget) ||
                                      (isSelected && isTarget)
                                  ? [
                                      BoxShadow(
                                        color: tileColor.withOpacity(0.6),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : [],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hudStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
