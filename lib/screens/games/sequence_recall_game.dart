import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/game_result.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../game_result_screen.dart';

class SequenceRecallGame extends StatefulWidget {
  final VoidCallback? onGameComplete;

  const SequenceRecallGame({Key? key, this.onGameComplete}) : super(key: key);

  @override
  _SequenceRecallGameState createState() => _SequenceRecallGameState();
}

class _SequenceRecallGameState extends State<SequenceRecallGame> {
  final List<Color> nodeColors = [
    AppTheme.cyanSpeed,
    AppTheme.purpleMemory,
    AppTheme.emeraldAttention,
    AppTheme.amberProblemSolving,
  ];

  List<int> sequence = [];
  int currentStep = 0;
  int level = 1;
  int score = 0;
  int lives = 3;
  int totalAttempts = 0;
  int successfulSequences = 0;

  bool isPlaybackPhase = false;
  int? activeHighlightedNode;

  @override
  void initState() {
    super.initState();
    startNewGameSequence();
  }

  void startNewGameSequence() {
    setState(() {
      sequence.clear();
      level = 1;
      currentStep = 0;
    });
    advanceSequence();
  }

  void advanceSequence() {
    Random r = Random();
    setState(() {
      sequence.add(r.nextInt(4));
      currentStep = 0;
      isPlaybackPhase = true;
    });
    playSequenceAnimation();
  }

  void playSequenceAnimation() async {
    await Future.delayed(const Duration(milliseconds: 600));
    for (int i = 0; i < sequence.length; i++) {
      if (!mounted) return;
      int nodeIndex = sequence[i];
      setState(() {
        activeHighlightedNode = nodeIndex;
      });
      SoundService.instance.playTap();
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        activeHighlightedNode = null;
      });
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (mounted) {
      setState(() {
        isPlaybackPhase = false;
      });
    }
  }

  void handleNodeTap(int nodeIndex) {
    if (isPlaybackPhase || lives <= 0) return;

    SoundService.instance.playTap();

    // Check match against current step in sequence
    if (nodeIndex == sequence[currentStep]) {
      currentStep++;
      // Sequence completed!
      if (currentStep == sequence.length) {
        totalAttempts++;
        successfulSequences++;
        SoundService.instance.playCorrect();
        setState(() {
          score += 400 + (sequence.length * 150);
          level = sequence.length;
        });

        if (level % 3 == 0) {
          SoundService.instance.playLevelUp();
        }

        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) advanceSequence();
        });
      }
    } else {
      // Wrong node tapped!
      SoundService.instance.playWrong();
      totalAttempts++;
      setState(() {
        lives--;
      });

      if (lives <= 0) {
        endGame();
      } else {
        // Replay pattern
        setState(() {
          currentStep = 0;
          isPlaybackPhase = true;
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) playSequenceAnimation();
        });
      }
    }
  }

  void endGame() {
    double accuracy = totalAttempts == 0
        ? 0.0
        : (successfulSequences / totalAttempts) * 100.0;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          gameId: 'sequence_recall',
          gameTitle: 'Sequence Recall',
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
        title: const Text('Sequence Recall'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // HUD (Lives, Score, Sequence Length)
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
                    Row(
                      children: List.generate(
                        3,
                        (index) => Icon(
                          index < lives ? Icons.favorite : Icons.favorite_border,
                          color: AppTheme.coralFlexibility,
                        ),
                      ),
                    ),
                    Text(
                      'SCORE: $score',
                      style: const TextStyle(
                        color: AppTheme.purpleMemory,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'STEPS: ${sequence.length}',
                      style: const TextStyle(
                        color: AppTheme.primaryNeon,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(
                isPlaybackPhase
                    ? 'WATCH THE SEQUENCE...'
                    : 'REPEAT THE PATTERN!',
                style: TextStyle(
                  color: isPlaybackPhase
                      ? AppTheme.amberProblemSolving
                      : AppTheme.emeraldAttention,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 40),

              // 4 Simon Nodes (2x2 Grid Layout)
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        bool isActive = activeHighlightedNode == index;
                        Color baseColor = nodeColors[index];

                        return GestureDetector(
                          onTap: () => handleNodeTap(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? baseColor
                                  : baseColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: baseColor,
                                width: isActive ? 4 : 2,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: baseColor.withOpacity(0.8),
                                        blurRadius: 24,
                                        spreadRadius: 4,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Icon(
                                _getNodeIcon(index),
                                color: isActive
                                    ? Colors.white
                                    : baseColor,
                                size: 44,
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

  IconData _getNodeIcon(int index) {
    switch (index) {
      case 0:
        return Icons.auto_awesome;
      case 1:
        return Icons.psychology;
      case 2:
        return Icons.bolt;
      default:
        return Icons.diamond;
    }
  }
}
