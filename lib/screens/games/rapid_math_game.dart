import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_result.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../game_result_screen.dart';

class RapidMathGame extends StatefulWidget {
  final VoidCallback? onGameComplete;

  const RapidMathGame({Key? key, this.onGameComplete}) : super(key: key);

  @override
  _RapidMathGameState createState() => _RapidMathGameState();
}

class _RapidMathGameState extends State<RapidMathGame> {
  int score = 0;
  int level = 1;
  int streak = 0;
  int totalRounds = 0;
  int correctRounds = 0;
  int timeLeft = 45;
  Timer? timer;

  String expressionLeft = '';
  String expressionRight = '';
  String relation = '='; // '>', '<', '='
  bool statementIsTrue = true;

  @override
  void initState() {
    super.initState();
    startTimer();
    nextProblem();
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

  void nextProblem() {
    Random r = Random();
    int valLeft, valRight;

    if (level <= 2) {
      int a = r.nextInt(15) + 1;
      int b = r.nextInt(15) + 1;
      valLeft = a + b;
      expressionLeft = '$a + $b';

      int c = r.nextInt(15) + 1;
      int d = r.nextInt(15) + 1;
      valRight = c + d;
      expressionRight = '$c + $d';
    } else if (level <= 5) {
      int a = r.nextInt(25) + 5;
      int b = r.nextInt(20) + 1;
      valLeft = a - b;
      expressionLeft = '$a - $b';

      int c = r.nextInt(10) + 2;
      int d = r.nextInt(8) + 2;
      valRight = c * d;
      expressionRight = '$c × $d';
    } else {
      int a = r.nextInt(12) + 2;
      int b = r.nextInt(12) + 2;
      valLeft = a * b;
      expressionLeft = '$a × $b';

      int c = r.nextInt(100) + 20;
      int d = r.nextInt(30) + 5;
      valRight = c - d;
      expressionRight = '$c - $d';
    }

    // Determine relation prompt
    List<String> rels = ['>', '<', '='];
    String chosenRel = rels[r.nextInt(rels.length)];

    bool isTrue;
    if (chosenRel == '>') {
      isTrue = valLeft > valRight;
    } else if (chosenRel == '<') {
      isTrue = valLeft < valRight;
    } else {
      isTrue = valLeft == valRight;
    }

    setState(() {
      relation = chosenRel;
      statementIsTrue = isTrue;
    });
  }

  void handleAnswer(bool userSaidTrue) {
    SoundService.instance.playTap();
    totalRounds++;

    if (userSaidTrue == statementIsTrue) {
      SoundService.instance.playCorrect();
      correctRounds++;
      streak++;

      int points = 300 + (streak * 50) + (level * 60);
      setState(() {
        score += points;
        if (streak % 4 == 0) {
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

    nextProblem();
  }

  void endGame() {
    timer?.cancel();
    double accuracy =
        totalRounds == 0 ? 0.0 : (correctRounds / totalRounds) * 100.0;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameId: 'rapid_math',
          gameTitle: 'Rapid Math Inequalities',
          domain: CognitiveDomain.problemSolving,
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
        title: const Text('Rapid Math'),
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
                    _statItem('SCORE', '$score', AppTheme.amberProblemSolving),
                    _statItem('STREAK', '🔥 $streak', AppTheme.primaryNeon),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              const Text(
                'IS THIS MATHEMATICAL STATEMENT TRUE OR FALSE?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 32),

              // Math Inequality Display
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 36),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: AppTheme.amberProblemSolving.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.amberProblemSolving.withOpacity(0.15),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          expressionLeft,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.amberProblemSolving
                                .withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            relation,
                            style: const TextStyle(
                              color: AppTheme.amberProblemSolving,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          expressionRight,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // TRUE vs FALSE Buttons
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
                        'FALSE',
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
                        'TRUE',
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
