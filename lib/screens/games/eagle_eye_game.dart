import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_result.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../game_result_screen.dart';

class EagleEyeGame extends StatefulWidget {
  final VoidCallback? onGameComplete;

  const EagleEyeGame({Key? key, this.onGameComplete}) : super(key: key);

  @override
  _EagleEyeGameState createState() => _EagleEyeGameState();
}

class _EagleEyeGameState extends State<EagleEyeGame> {
  final List<IconData> centerIcons = [
    Icons.star,
    Icons.favorite,
    Icons.square,
    Icons.lightbulb,
  ];

  int score = 0;
  int level = 1;
  int streak = 0;
  int totalRounds = 0;
  int correctRounds = 0;
  int roundsLeft = 10;

  int targetCentralIconIdx = 0;
  int targetPeripheralPos = 0; // 0 to 7 positions on radar circle

  bool isFlashingPhase = false;
  bool isAnsweringPhase = false;

  int? userSelectedCentralIcon;
  int? userSelectedPeripheralPos;

  @override
  void initState() {
    super.initState();
    startNewTrial();
  }

  void startNewTrial() {
    if (roundsLeft <= 0) {
      endGame();
      return;
    }

    Random r = Random();
    setState(() {
      roundsLeft--;
      targetCentralIconIdx = r.nextInt(centerIcons.length);
      targetPeripheralPos = r.nextInt(8);

      userSelectedCentralIcon = null;
      userSelectedPeripheralPos = null;
      isFlashingPhase = true;
      isAnsweringPhase = false;
    });

    int flashMs = max(180, 450 - (level * 25));
    Future.delayed(Duration(milliseconds: flashMs), () {
      if (mounted) {
        setState(() {
          isFlashingPhase = false;
          isAnsweringPhase = true;
        });
      }
    });
  }

  void handleCentralSelect(int idx) {
    SoundService.instance.playTap();
    setState(() {
      userSelectedCentralIcon = idx;
    });
    checkAnswersIfBothSelected();
  }

  void handlePeripheralSelect(int pos) {
    SoundService.instance.playTap();
    setState(() {
      userSelectedPeripheralPos = pos;
    });
    checkAnswersIfBothSelected();
  }

  void checkAnswersIfBothSelected() {
    if (userSelectedCentralIcon == null || userSelectedPeripheralPos == null) {
      return;
    }

    totalRounds++;
    bool centralCorrect = (userSelectedCentralIcon == targetCentralIconIdx);
    bool peripheralCorrect = (userSelectedPeripheralPos == targetPeripheralPos);

    if (centralCorrect && peripheralCorrect) {
      SoundService.instance.playCorrect();
      correctRounds++;
      streak++;

      int points = 500 + (streak * 60) + (level * 80);
      setState(() {
        score += points;
        if (streak % 3 == 0) {
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

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) startNewTrial();
    });
  }

  void endGame() {
    double accuracy =
        totalRounds == 0 ? 0.0 : (correctRounds / totalRounds) * 100.0;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameId: 'eagle_eye',
          gameTitle: 'Eagle Eye Dual Focus',
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
        title: const Text('Eagle Eye'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Top HUD
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.surfaceCardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statItem('TRIALS LEFT', '$roundsLeft', AppTheme.coralFlexibility),
                    _statItem('SCORE', '$score', AppTheme.emeraldAttention),
                    _statItem('STREAK', '🔥 $streak', AppTheme.amberProblemSolving),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Target Visual Flash Canvas area
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.emeraldAttention.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Central Icon
                          if (isFlashingPhase)
                            Center(
                              child: Icon(
                                centerIcons[targetCentralIconIdx],
                                size: 54,
                                color: AppTheme.primaryNeon,
                              ),
                            ),

                          // Peripheral Target Flash
                          if (isFlashingPhase)
                            _buildPeripheralFlash(targetPeripheralPos),

                          // Answering Prompt Overlay
                          if (isAnsweringPhase)
                            const Center(
                              child: Text(
                                'RECALL CENTRAL ICON &\nPERIPHERAL TARGET',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Answer Selection Area
              if (isAnsweringPhase) ...[
                const Text(
                  '1. CENTRAL SYMBOL:',
                  style: TextStyle(
                      color: AppTheme.primaryNeon,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    centerIcons.length,
                    (idx) => InkWell(
                      onTap: () => handleCentralSelect(idx),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: userSelectedCentralIcon == idx
                              ? AppTheme.primaryNeon
                              : AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.surfaceCardBorder),
                        ),
                        child: Icon(
                          centerIcons[idx],
                          color: userSelectedCentralIcon == idx
                              ? Colors.white
                              : AppTheme.textPrimary,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '2. PERIPHERAL RADAR POSITION (0 to 7):',
                  style: TextStyle(
                      color: AppTheme.emeraldAttention,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: List.generate(
                    8,
                    (pos) => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: userSelectedPeripheralPos == pos
                            ? AppTheme.emeraldAttention
                            : AppTheme.surfaceCard,
                        foregroundColor: userSelectedPeripheralPos == pos
                            ? Colors.white
                            : AppTheme.textPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onPressed: () => handlePeripheralSelect(pos),
                      child: Text('Pos $pos',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeripheralFlash(int pos) {
    // Calculate angle around circle (0..7 => 0, 45, 90, 135, 180, 225, 270, 315 deg)
    double angle = (pos * 45) * (pi / 180);
    double radius = 100; // Offset from center

    double x = radius * cos(angle);
    double y = radius * sin(angle);

    return Center(
      child: Transform.translate(
        offset: Offset(x, y),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppTheme.emeraldAttention,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: AppTheme.emeraldAttention,
                  blurRadius: 16,
                  spreadRadius: 4),
            ],
          ),
          child: const Icon(Icons.location_searching,
              color: Colors.black, size: 24),
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
