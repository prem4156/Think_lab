import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_result.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../game_result_screen.dart';

class RuleSwitcherGame extends StatefulWidget {
  final VoidCallback? onGameComplete;

  const RuleSwitcherGame({Key? key, this.onGameComplete}) : super(key: key);

  @override
  _RuleSwitcherGameState createState() => _RuleSwitcherGameState();
}

class _RuleSwitcherGameState extends State<RuleSwitcherGame> {
  // 0 = NUMBER RULE ("Is Number EVEN?"), 1 = COLOR RULE ("Is Color RED/WARM?")
  int currentRule = 0;

  int numberValue = 4;
  Color cardColor = AppTheme.coralFlexibility;
  bool isColorWarm = true;
  bool currentAnswer = true;

  int score = 0;
  int level = 1;
  int streak = 0;
  int totalRounds = 0;
  int correctRounds = 0;
  int timeLeft = 45;
  Timer? timer;

  final List<Color> warmColors = [
    Colors.redAccent,
    Colors.deepOrangeAccent,
    Colors.amber,
  ];

  final List<Color> coolColors = [
    Colors.cyanAccent,
    Colors.blueAccent,
    Colors.indigoAccent,
  ];

  @override
  void initState() {
    super.initState();
    startTimer();
    nextCard();
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

  void nextCard() {
    Random r = Random();
    int rule = r.nextInt(2); // 0 or 1
    int numVal = r.nextInt(9) + 1; // 1..9

    bool pickWarm = r.nextBool();
    Color chosenColor;
    if (pickWarm) {
      chosenColor = warmColors[r.nextInt(warmColors.length)];
    } else {
      chosenColor = coolColors[r.nextInt(coolColors.length)];
    }

    bool ans;
    if (rule == 0) {
      // EVEN NUMBER RULE
      ans = (numVal % 2 == 0);
    } else {
      // WARM COLOR RULE
      ans = pickWarm;
    }

    setState(() {
      currentRule = rule;
      numberValue = numVal;
      cardColor = chosenColor;
      isColorWarm = pickWarm;
      currentAnswer = ans;
    });
  }

  void handleUserAnswer(bool userSaidYes) {
    SoundService.instance.playTap();
    totalRounds++;

    if (userSaidYes == currentAnswer) {
      SoundService.instance.playCorrect();
      correctRounds++;
      streak++;

      int points = 300 + (streak * 45) + (level * 60);
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

    nextCard();
  }

  void endGame() {
    timer?.cancel();
    double accuracy =
        totalRounds == 0 ? 0.0 : (correctRounds / totalRounds) * 100.0;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameId: 'rule_switcher',
          gameTitle: 'Rule Switcher Agility',
          domain: CognitiveDomain.flexibility,
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
        title: const Text('Rule Switcher'),
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
                    _statItem('SCORE', '$score', AppTheme.purpleMemory),
                    _statItem('STREAK', '🔥 $streak', AppTheme.amberProblemSolving),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ACTIVE RULE PROMPT BANNER
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: currentRule == 0
                      ? AppTheme.secondaryNeon.withOpacity(0.2)
                      : AppTheme.coralFlexibility.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: currentRule == 0
                        ? AppTheme.secondaryNeon
                        : AppTheme.coralFlexibility,
                    width: 2,
                  ),
                ),
                child: Text(
                  currentRule == 0
                      ? 'RULE: IS NUMBER EVEN?'
                      : 'RULE: IS COLOR RED / WARM?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: currentRule == 0
                        ? AppTheme.secondaryNeon
                        : AppTheme.coralFlexibility,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Stimulus Card Display
              Expanded(
                child: Center(
                  child: Container(
                    width: 220,
                    height: 280,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: cardColor, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: cardColor.withOpacity(0.3),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$numberValue',
                        style: TextStyle(
                          color: cardColor,
                          fontSize: 88,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // YES / NO Response Buttons
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
                        'NO',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => handleUserAnswer(false),
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
                        'YES',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => handleUserAnswer(true),
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
