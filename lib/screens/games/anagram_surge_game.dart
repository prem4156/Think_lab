import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_result.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../game_result_screen.dart';

class AnagramSurgeGame extends StatefulWidget {
  final VoidCallback? onGameComplete;

  const AnagramSurgeGame({Key? key, this.onGameComplete}) : super(key: key);

  @override
  _AnagramSurgeGameState createState() => _AnagramSurgeGameState();
}

class _AnagramSurgeGameState extends State<AnagramSurgeGame> {
  final List<Map<String, String>> wordBank = [
    {'word': 'BRAIN', 'hint': 'Organ of mind & thought'},
    {'word': 'THINK', 'hint': 'Process of cognitive reasoning'},
    {'word': 'FOCUS', 'hint': 'Concentrated mental attention'},
    {'word': 'SMART', 'hint': 'Clever, intelligent, agile'},
    {'word': 'LIGHT', 'hint': 'Opposite of dark'},
    {'word': 'SOLVE', 'hint': 'Find a solution to a problem'},
    {'word': 'LOGIC', 'hint': 'Reasoning conducted according to strict principles'},
    {'word': 'SPEED', 'hint': 'Velocity or rapid performance'},
    {'word': 'SHARP', 'hint': 'Keen intellect or acute edge'},
    {'word': 'FLASH', 'hint': 'Sudden burst of brightness or speed'},
    {'word': 'NEURON', 'hint': 'Nerve cell transmitting brain signals'},
    {'word': 'MEMORY', 'hint': 'Mental capacity to retain past experiences'},
  ];

  String targetWord = 'BRAIN';
  String hintText = '';
  List<String> scrambledLetters = [];
  List<String> userFormedLetters = [];

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
    nextAnagram();
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

  void nextAnagram() {
    Random r = Random();
    Map<String, String> choice = wordBank[r.nextInt(wordBank.length)];
    targetWord = choice['word']!;
    hintText = choice['hint']!;

    // Scramble letters
    List<String> chars = targetWord.split('');
    while (chars.join() == targetWord) {
      chars.shuffle(r);
    }

    setState(() {
      scrambledLetters = chars;
      userFormedLetters.clear();
    });
  }

  void handleLetterTap(int scrambledIndex) {
    if (scrambledLetters[scrambledIndex].isEmpty) return;

    SoundService.instance.playTap();
    String tappedChar = scrambledLetters[scrambledIndex];

    setState(() {
      userFormedLetters.add(tappedChar);
      scrambledLetters[scrambledIndex] = '';
    });

    // Check completed word length
    if (userFormedLetters.length == targetWord.length) {
      String formedStr = userFormedLetters.join();
      totalRounds++;

      if (formedStr == targetWord) {
        SoundService.instance.playCorrect();
        correctRounds++;
        streak++;

        int points = 400 + (streak * 50) + (level * 60);
        setState(() {
          score += points;
          if (streak % 3 == 0) {
            level++;
            SoundService.instance.playLevelUp();
          }
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) nextAnagram();
        });
      } else {
        SoundService.instance.playWrong();
        setState(() {
          streak = 0;
        });

        // Reset current word attempt
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              scrambledLetters = targetWord.split('');
              scrambledLetters.shuffle();
              userFormedLetters.clear();
            });
          }
        });
      }
    }
  }

  void handleRemoveUserLetter(int userIndex) {
    SoundService.instance.playTap();
    String removedChar = userFormedLetters.removeAt(userIndex);

    // Put letter back in first empty slot of scrambledLetters
    for (int i = 0; i < scrambledLetters.length; i++) {
      if (scrambledLetters[i].isEmpty) {
        scrambledLetters[i] = removedChar;
        break;
      }
    }

    setState(() {});
  }

  void endGame() {
    timer?.cancel();
    double accuracy =
        totalRounds == 0 ? 0.0 : (correctRounds / totalRounds) * 100.0;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameId: 'anagram_surge',
          gameTitle: 'Anagram Surge',
          domain: CognitiveDomain.language,
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
        title: const Text('Anagram Surge'),
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
                    _statItem('SCORE', '$score', AppTheme.pinkLanguage),
                    _statItem('STREAK', '🔥 $streak', AppTheme.amberProblemSolving),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Hint Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.pinkLanguage.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.pinkLanguage, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: AppTheme.pinkLanguage, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'HINT: $hintText',
                        style: const TextStyle(
                          color: AppTheme.pinkLanguage,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Formed Word Answer Slot
              Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.pinkLanguage.withOpacity(0.5), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    targetWord.length,
                    (i) {
                      bool hasChar = i < userFormedLetters.length;
                      String char = hasChar ? userFormedLetters[i] : '';

                      return GestureDetector(
                        onTap: hasChar ? () => handleRemoveUserLetter(i) : null,
                        child: Container(
                          width: 44,
                          height: 52,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: hasChar
                                ? AppTheme.pinkLanguage
                                : AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.pinkLanguage, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              char,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Available Scrambled Letter Tiles
              Expanded(
                child: Center(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: List.generate(
                      scrambledLetters.length,
                      (idx) {
                        String char = scrambledLetters[idx];
                        bool isEmpty = char.isEmpty;

                        return GestureDetector(
                          onTap: isEmpty ? null : () => handleLetterTap(idx),
                          child: Opacity(
                            opacity: isEmpty ? 0.3 : 1.0,
                            child: Container(
                              width: 58,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.primaryNeon,
                                  width: 2,
                                ),
                                boxShadow: isEmpty
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: AppTheme.primaryNeon
                                              .withOpacity(0.3),
                                          blurRadius: 10,
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: Text(
                                  char,
                                  style: const TextStyle(
                                    color: AppTheme.primaryNeon,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
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
