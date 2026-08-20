import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/daily_workout.dart';
import '../models/game_result.dart';
import '../models/user_profile.dart';
import '../services/bpi_engine.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'game_modal_tutorial.dart';

class GameResultScreen extends StatefulWidget {
  final String gameId;
  final String gameTitle;
  final CognitiveDomain domain;
  final int rawScore;
  final double accuracyPercent;
  final int levelReached;
  final VoidCallback? onComplete;

  const GameResultScreen({
    Key? key,
    required this.gameId,
    required this.gameTitle,
    required this.domain,
    required this.rawScore,
    required this.accuracyPercent,
    required this.levelReached,
    this.onComplete,
  }) : super(key: key);

  @override
  _GameResultScreenState createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen> {
  int bpiGain = 0;
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    _processResultAndSave();
  }

  void _processResultAndSave() async {
    final storage = StorageService.instance;
    UserProfile profile = await storage.loadProfile();

    int currentDomainBpi = profile.domainBpi[widget.domain] ?? 600;
    int gain = BpiEngine.calculateBpiGain(
      rawScore: widget.rawScore,
      accuracyPercent: widget.accuracyPercent,
      levelReached: widget.levelReached,
      currentDomainBpi: currentDomainBpi,
    );

    GameResult result = GameResult(
      gameId: widget.gameId,
      gameTitle: widget.gameTitle,
      domain: widget.domain,
      score: widget.rawScore,
      accuracyPercent: widget.accuracyPercent,
      levelReached: widget.levelReached,
      bpiGain: gain,
      timestamp: DateTime.now(),
    );

    // Update Profile & BPI Engine
    BpiEngine.processGameResult(profile, result);

    // Update Daily Workout
    DailyWorkout workout = await storage.loadDailyWorkout();
    if (workout.gameIds.contains(widget.gameId) &&
        !workout.completedGameIds.contains(widget.gameId)) {
      workout.completedGameIds.add(widget.gameId);
      if (workout.isCompleted) {
        profile.totalWorkoutsCompleted += 1;
        profile.currentStreak += 1;
        if (profile.currentStreak > profile.bestStreak) {
          profile.bestStreak = profile.currentStreak;
        }
      }
      await storage.saveDailyWorkout(workout);
    }

    await storage.saveProfile(profile);
    await storage.addGameResult(result);

    SoundService.instance.playFanfare();

    if (mounted) {
      setState(() {
        bpiGain = gain;
        isSaved = true;
      });
    }
  }

  void _replayGame() async {
    final storage = StorageService.instance;
    UserProfile profile = await storage.loadProfile();
    if (!mounted) return;

    // Open game tutorial modal to replay
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GameModalTutorial(
        gameId: widget.gameId,
        profile: profile,
        onWorkoutGameFinished: widget.onComplete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Celebration Icon & Halo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNeon.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.primaryNeon.withValues(alpha: 0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryNeon.withValues(alpha: 0.35),
                      blurRadius: 36,
                      spreadRadius: 4,
                    )
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: AppTheme.primaryNeon, size: 68),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .fadeIn(),

              const SizedBox(height: 20),

              const Text(
                'WORKOUT COMPLETE!',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 4),

              Text(
                widget.gameTitle,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 28),

              // BPI Gain Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: AppTheme.emeraldAttention.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.emeraldAttention.withValues(alpha: 0.12),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.emeraldAttention.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.psychology_rounded,
                          color: AppTheme.emeraldAttention, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BPI GAIN YIELD',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+$bpiGain BPI PTS',
                          style: const TextStyle(
                            color: AppTheme.emeraldAttention,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms).fadeIn(delay: 300.ms),

              const SizedBox(height: 24),

              // Stats Breakdown Grid
              Row(
                children: [
                  Expanded(
                    child: _statCard('SCORE', '${widget.rawScore}',
                        AppTheme.cyanSpeed, Icons.stars_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                        'ACCURACY',
                        '${widget.accuracyPercent.toStringAsFixed(0)}%',
                        AppTheme.amberProblemSolving,
                        Icons.track_changes_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard('LEVEL', 'Lvl ${widget.levelReached}',
                        AppTheme.pinkLanguage, Icons.trending_up_rounded),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

              const Spacer(),

              // Replay Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: AppTheme.surfaceCardBorder, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _replayGame,
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppTheme.textPrimary, size: 20),
                  label: const Text(
                    'PLAY AGAIN',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 12),

              // Dashboard CTA Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryNeon.withValues(alpha: 0.35),
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
                      if (widget.onComplete != null) {
                        widget.onComplete!();
                      }
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DashboardScreen()),
                        (route) => false,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.home_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'CONTINUE TO DASHBOARD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 550.ms),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.surfaceCardBorder),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
