import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/game_result.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../game_result_screen.dart';

class StroopMatchGame extends StatefulWidget {
  final VoidCallback? onGameComplete;

  const StroopMatchGame({Key? key, this.onGameComplete}) : super(key: key);

  @override
  _StroopMatchGameState createState() => _StroopMatchGameState();
}

class _StroopMatchGameState extends State<StroopMatchGame> {
  final List<Map<String, dynamic>> colorData = [
    {'name': 'RED', 'color': Colors.redAccent},
    {'name': 'BLUE', 'color': Colors.blueAccent},
    {'name': 'GREEN', 'color': Colors.greenAccent},
    {'name': 'YELLOW', 'color': Colors.amberAccent},
    {'name': 'PURPLE', 'color': Colors.purpleAccent},
    {'name': 'ORANGE', 'color': Colors.deepOrangeAccent},
  ];

  int score = 0;
  int level = 1;
  int streak = 0;
  int totalRounds = 0;
  int correctRounds = 0;
  int timeLeft = 45;
  Timer? timer;

  String displayedWord = 'RED';
  Color displayedColor = Colors.redAccent;
  bool isMatching = true;

  @override
  void initState() {
    super.initState();
    startTimer();
    nextQuestion();
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

  void nextQuestion() {
    Random r = Random();
    int wordIdx = r.nextInt(colorData.length);
    bool makeMatch = r.nextBool();

    int colorIdx;
    if (makeMatch) {
      colorIdx = wordIdx;
    } else {
      colorIdx = (wordIdx + 1 + r.nextInt(colorData.length - 1)) %
          colorData.length;
    }

    setState(() {
      displayedWord = colorData[wordIdx]['name'];
      displayedColor = colorData[colorIdx]['color'];
      isMatching = (wordIdx == colorIdx);
    });
  }

  void handleAnswer(bool userSaidMatch) {
    SoundService.instance.playTap();
    totalRounds++;

    if (userSaidMatch == isMatching) {
      // Correct!
      SoundService.instance.playCorrect();
      correctRounds++;
      streak++;

      int points = 250 + (streak * 40) + (level * 50);
      setState(() {
        score += points;
        if (streak % 5 == 0) {
          level++;
          SoundService.instance.playLevelUp();
        }
      });
    } else {
      // Wrong!
      SoundService.instance.playWrong();
      setState(() {
        streak = 0;
      });
    }

    nextQuestion();
  }

  void endGame() {
    timer?.cancel();
    double accuracy =
        totalRounds == 0 ? 0.0 : (correctRounds / totalRounds) * 100.0;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameId: 'stroop_match',
          gameTitle: 'Stroop Color Match',
          domain: CognitiveDomain.speed,
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
        title: const Text('Stroop Color Match'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    _statItem('SCORE', '$score', AppTheme.cyanSpeed),
                    _statItem('STREAK', '🔥 $streak', AppTheme.amberProblemSolving),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              const Text(
                'DOES THE WORD MATCH ITS COLOR?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 32),

              // Word Display Card
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: displayedColor.withValues(alpha: 0.6),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: displayedColor.withValues(alpha: 0.25),
                          blurRadius: 36,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        displayedWord,
                        key: ValueKey(displayedWord + displayedColor.toString()),
                        style: TextStyle(
                          color: displayedColor,
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                        ),
                      ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons: NO-MATCH vs MATCH
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.coralFlexibility,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                      ),
                      icon: const Icon(Icons.close, size: 28, color: Colors.white),
                      label: const Text(
                        'NO MATCH',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => handleAnswer(false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldAttention,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                      ),
                      icon: const Icon(Icons.check, size: 28, color: Colors.white),
                      label: const Text(
                        'MATCH',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => handleAnswer(true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
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
