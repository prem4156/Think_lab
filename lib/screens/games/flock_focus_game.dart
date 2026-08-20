import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_result.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../game_result_screen.dart';

class FlockFocusGame extends StatefulWidget {
  final VoidCallback? onGameComplete;

  const FlockFocusGame({Key? key, this.onGameComplete}) : super(key: key);

  @override
  _FlockFocusGameState createState() => _FlockFocusGameState();
}

class _FlockFocusGameState extends State<FlockFocusGame> {
  // Directions: 0 = LEFT, 1 = RIGHT, 2 = UP, 3 = DOWN
  int centerDirection = 0;
  int flankerDirection = 1;

  int score = 0;
  int level = 1;
  int streak = 0;
  int totalRounds = 0;
  int correctRounds = 0;
  int timeLeft = 45;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
    nextWave();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft <= 1) {
        t.cancel();
        endGame();
      } else {
        setState(() {
          timeLeft--;
        });
      }
    });
  }

  void nextWave() {
    Random r = Random();
    int centerDir = r.nextInt(4);

    // Flanker directions (sometimes matching, often distractor opposing)
    bool distractor = r.nextBool();
    int flankerDir;
    if (distractor) {
      flankerDir = (centerDir + 1 + r.nextInt(3)) % 4;
    } else {
      flankerDir = centerDir;
    }

    setState(() {
      centerDirection = centerDir;
      flankerDirection = flankerDir;
    });
  }

  void handleDirectionAnswer(int chosenDir) {
    SoundService.instance.playTap();
    totalRounds++;

    if (chosenDir == centerDirection) {
      SoundService.instance.playCorrect();
      correctRounds++;
      streak++;

      int points = 300 + (streak * 45) + (level * 50);
      setState(() {
        score += points;
        if (streak % 5 == 0) {
          level++;
          SoundService.instance.playLevelUp();
        }
      });
    } else {
      SoundService.instance.playWrong();
      setState(() {
        streak = 0;
      });
    }

    nextWave();
  }

  void endGame() {
    timer?.cancel();
    double accuracy =
        totalRounds == 0 ? 0.0 : (correctRounds / totalRounds) * 100.0;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameId: 'flock_focus',
          gameTitle: 'Flock Focus',
          domain: CognitiveDomain.attention,
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
        title: const Text('Flock Focus'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Top HUD
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
                    _statItem('TIME', '$timeLeft s', AppTheme.coralFlexibility),
                    _statItem('SCORE', '$score', AppTheme.emeraldAttention),
                    _statItem('STREAK', '🔥 $streak', AppTheme.amberProblemSolving),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'WHICH WAY IS THE CENTER BIRD FLYING?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 30),

              // Flock Birds Visual Area
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: AppTheme.emeraldAttention.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Top Flanker Bird
                        _birdWidget(flankerDirection, isCenter: false),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Left Flanker Bird
                            _birdWidget(flankerDirection, isCenter: false),
                            const SizedBox(width: 28),
                            // CENTER BIRD (TARGET)
                            _birdWidget(centerDirection, isCenter: true),
                            const SizedBox(width: 28),
                            // Right Flanker Bird
                            _birdWidget(flankerDirection, isCenter: false),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Bottom Flanker Bird
                        _birdWidget(flankerDirection, isCenter: false),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 4 Direction Controls (Cross D-Pad Layout)
              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceCard,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => handleDirectionAnswer(2), // UP
                    child: const Icon(Icons.arrow_upward,
                        size: 32, color: AppTheme.emeraldAttention),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceCard,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 36, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => handleDirectionAnswer(0), // LEFT
                        child: const Icon(Icons.arrow_back,
                            size: 32, color: AppTheme.emeraldAttention),
                      ),
                      const SizedBox(width: 48),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surfaceCard,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 36, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => handleDirectionAnswer(1), // RIGHT
                        child: const Icon(Icons.arrow_forward,
                            size: 32, color: AppTheme.emeraldAttention),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceCard,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => handleDirectionAnswer(3), // DOWN
                    child: const Icon(Icons.arrow_downward,
                        size: 32, color: AppTheme.emeraldAttention),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _birdWidget(int directionIndex, {required bool isCenter}) {
    double angle = 0;
    if (directionIndex == 0) angle = -pi / 2; // LEFT
    if (directionIndex == 1) angle = pi / 2; // RIGHT
    if (directionIndex == 2) angle = 0; // UP
    if (directionIndex == 3) angle = pi; // DOWN

    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: EdgeInsets.all(isCenter ? 14 : 10),
        decoration: BoxDecoration(
          color: isCenter
              ? AppTheme.emeraldAttention.withOpacity(0.25)
              : AppTheme.surfaceCard,
          shape: BoxShape.circle,
          border: Border.all(
            color: isCenter ? AppTheme.emeraldAttention : AppTheme.surfaceCardBorder,
            width: isCenter ? 2.5 : 1,
          ),
        ),
        child: Icon(
          Icons.navigation,
          size: isCenter ? 44 : 32,
          color: isCenter ? AppTheme.emeraldAttention : AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _statItem(String title, String val, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          val,
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
