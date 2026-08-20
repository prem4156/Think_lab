import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/game_result.dart';
import '../models/user_profile.dart';
import '../services/sound_service.dart';
import '../theme/app_theme.dart';
import 'games/spatial_memory_game.dart';
import 'games/sequence_recall_game.dart';
import 'games/stroop_match_game.dart';
import 'games/rapid_math_game.dart';
import 'games/flock_focus_game.dart';
import 'games/eagle_eye_game.dart';
import 'games/rule_switcher_game.dart';
import 'games/anagram_surge_game.dart';

class GameModalTutorial extends StatelessWidget {
  final String gameId;
  final UserProfile profile;
  final VoidCallback? onWorkoutGameFinished;

  const GameModalTutorial({
    Key? key,
    required this.gameId,
    required this.profile,
    this.onWorkoutGameFinished,
  }) : super(key: key);

  static final Map<String, Map<String, dynamic>> gameMeta = {
    'spatial_memory': {
      'title': 'Spatial Memory Matrix',
      'domain': CognitiveDomain.memory,
      'color': AppTheme.purpleMemory,
      'icon': Icons.grid_on,
      'skills': ['Spatial Recall', 'Working Memory', 'Visual Patterning'],
      'instructions':
          'Memorize the position of highlighted glowing tiles on the matrix grid before they vanish, then tap to recall them accurately.',
    },
    'sequence_recall': {
      'title': 'Sequence Recall',
      'domain': CognitiveDomain.memory,
      'color': AppTheme.purpleMemory,
      'icon': Icons.audiotrack,
      'skills': ['Pattern Memory', 'Sequential Recall', 'Auditory Focus'],
      'instructions':
          'Watch and listen to the escalating audio-visual sequence, then repeat the exact order step by step.',
    },
    'stroop_match': {
      'title': 'Stroop Color Match',
      'domain': CognitiveDomain.speed,
      'color': AppTheme.cyanSpeed,
      'icon': Icons.bolt,
      'skills': ['Processing Speed', 'Interference Control', 'Response Inhibition'],
      'instructions':
          'Rapidly determine if the printed color word matches the font ink color. Ignore conflicting information!',
    },
    'rapid_math': {
      'title': 'Rapid Math Inequalities',
      'domain': CognitiveDomain.problemSolving,
      'color': AppTheme.amberProblemSolving,
      'icon': Icons.calculate,
      'skills': ['Quantitative Logic', 'Mental Math Speed', 'Numerical Comparison'],
      'instructions':
          'Evaluate mathematical expressions and inequality symbols (> < =) at top speed. Decide TRUE or FALSE.',
    },
    'flock_focus': {
      'title': 'Flock Focus',
      'domain': CognitiveDomain.attention,
      'color': AppTheme.emeraldAttention,
      'icon': Icons.navigation,
      'skills': ['Selective Attention', 'Divided Focus', 'Distraction Dodge'],
      'instructions':
          'Identify the flight direction of the CENTER bird, ignoring surrounding flanker birds flying in opposing directions.',
    },
    'eagle_eye': {
      'title': 'Eagle Eye Dual Focus',
      'domain': CognitiveDomain.attention,
      'color': AppTheme.emeraldAttention,
      'icon': Icons.remove_red_eye,
      'skills': ['Peripheral Awareness', 'Dual Focus', 'Visual Scanning'],
      'instructions':
          'A central symbol and a peripheral radar target flash simultaneously. Recall BOTH central icon & peripheral position!',
    },
    'rule_switcher': {
      'title': 'Rule Switcher Agility',
      'domain': CognitiveDomain.flexibility,
      'color': AppTheme.coralFlexibility,
      'icon': Icons.swap_calls,
      'skills': ['Task Switching', 'Mental Agility', 'Cognitive Adaptability'],
      'instructions':
          'Cards change dynamically between Number rules and Color rules. Adapt your response logic instantly!',
    },
    'anagram_surge': {
      'title': 'Anagram Surge',
      'domain': CognitiveDomain.language,
      'color': AppTheme.pinkLanguage,
      'icon': Icons.font_download,
      'skills': ['Word Fluency', 'Anagram Solving', 'Lexical Speed'],
      'instructions':
          'Unscramble scrambled letter tiles to form target words before time runs out. Use category hints when needed.',
    },
  };

  @override
  Widget build(BuildContext context) {
    final meta = gameMeta[gameId] ?? gameMeta['spatial_memory']!;
    final title = meta['title'] as String;
    final domain = meta['domain'] as CognitiveDomain;
    final color = meta['color'] as Color;
    final icon = meta['icon'] as IconData;
    final skills = meta['skills'] as List<String>;
    final instructions = meta['instructions'] as String;

    int highScore = profile.highScores[gameId] ?? 0;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCardBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header Icon & Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: color, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          domain.displayName.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn().slideY(begin: 0.05, end: 0),
            const SizedBox(height: 24),

            // High Score Banner Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.surfaceCardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.emoji_events,
                          color: AppTheme.amberProblemSolving, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'PERSONAL HIGH SCORE',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$highScore PTS',
                    style: const TextStyle(
                      color: AppTheme.amberProblemSolving,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 20),

            // Cognitive Skills Trained
            const Text(
              'COGNITIVE SKILLS TRAINED',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 14, color: color),
                          const SizedBox(width: 6),
                          Text(
                            s,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 20),

            // How to Play Card
            const Text(
              'HOW TO PLAY',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.surfaceCardBorder),
              ),
              child: Text(
                instructions,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 28),

            // Play Button CTA with Glow
            SizedBox(
              width: double.infinity,
              height: 54,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  onPressed: () {
                    SoundService.instance.playTap();
                    Navigator.pop(context); // Close sheet
                    _launchGameScreen(context, gameId, onWorkoutGameFinished);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 26),
                      SizedBox(width: 8),
                      Text(
                        'START MINIGAME',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 350.ms).scale(delay: 350.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }

  void _launchGameScreen(
      BuildContext context, String gameId, VoidCallback? onComplete) {
    Widget gameWidget;
    switch (gameId) {
      case 'spatial_memory':
        gameWidget = SpatialMemoryGame(onGameComplete: onComplete);
        break;
      case 'sequence_recall':
        gameWidget = SequenceRecallGame(onGameComplete: onComplete);
        break;
      case 'stroop_match':
        gameWidget = StroopMatchGame(onGameComplete: onComplete);
        break;
      case 'rapid_math':
        gameWidget = RapidMathGame(onGameComplete: onComplete);
        break;
      case 'flock_focus':
        gameWidget = FlockFocusGame(onGameComplete: onComplete);
        break;
      case 'eagle_eye':
        gameWidget = EagleEyeGame(onGameComplete: onComplete);
        break;
      case 'rule_switcher':
        gameWidget = RuleSwitcherGame(onGameComplete: onComplete);
        break;
      case 'anagram_surge':
        gameWidget = AnagramSurgeGame(onGameComplete: onComplete);
        break;
      default:
        gameWidget = SpatialMemoryGame(onGameComplete: onComplete);
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => gameWidget),
    );
  }
}
