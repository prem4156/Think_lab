import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/game_result.dart';
import '../models/user_profile.dart';
import '../services/bpi_engine.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'game_modal_tutorial.dart';

class BpiAnalyticsScreen extends StatefulWidget {
  const BpiAnalyticsScreen({Key? key}) : super(key: key);

  @override
  _BpiAnalyticsScreenState createState() => _BpiAnalyticsScreenState();
}

class _BpiAnalyticsScreenState extends State<BpiAnalyticsScreen> {
  UserProfile? profile;
  List<GameResult> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final prof = await StorageService.instance.loadProfile();
    final hist = await StorageService.instance.loadGameHistory();
    if (mounted) {
      setState(() {
        profile = prof;
        history = hist;
        isLoading = false;
      });
    }
  }

  void _launchDomainGame(CognitiveDomain domain) {
    String gameId = 'spatial_memory';
    switch (domain) {
      case CognitiveDomain.speed:
        gameId = 'stroop_match';
        break;
      case CognitiveDomain.memory:
        gameId = 'spatial_memory';
        break;
      case CognitiveDomain.attention:
        gameId = 'flock_focus';
        break;
      case CognitiveDomain.flexibility:
        gameId = 'rule_switcher';
        break;
      case CognitiveDomain.problemSolving:
        gameId = 'rapid_math';
        break;
      case CognitiveDomain.language:
        gameId = 'anagram_surge';
        break;
    }

    SoundService.instance.playTap();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GameModalTutorial(
        gameId: gameId,
        profile: profile!,
        onWorkoutGameFinished: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || profile == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryNeon),
        ),
      );
    }

    int overallBpi = profile!.overallBpi;
    int percentile = BpiEngine.getPercentile(overallBpi);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('Brain Performance Index'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero BPI Card with Gradient & Glow
              _buildHeroBpiCard(overallBpi, percentile)
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .scale(duration: 500.ms, curve: Curves.easeOutQuad),

              const SizedBox(height: 16),

              // Stats Row (Workouts, Streak, Best)
              _buildQuickStatsRow()
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 150.ms),

              const SizedBox(height: 28),

              // 6-Axis Cognitive Radar Chart Title
              const Text(
                'COGNITIVE DOMAIN RADAR',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 14),

              // Radar Chart Card
              _buildRadarChartCard()
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 250.ms)
                  .slideY(begin: 0.05, end: 0),

              const SizedBox(height: 28),

              // Individual Domain Breakdown Header
              const Text(
                'DOMAINS DEEP DIVE',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 14),

              // Domain Deep Dive Cards List
              ...CognitiveDomain.values.asMap().entries.map((entry) {
                int idx = entry.key;
                CognitiveDomain domain = entry.value;
                int bpiVal = profile!.domainBpi[domain] ?? 600;
                Color color = _getDomainColor(domain);
                IconData icon = _getDomainIcon(domain);

                return _buildDomainCard(domain, bpiVal, color, icon)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: Duration(milliseconds: 300 + (idx * 60)))
                    .slideX(begin: 0.05, end: 0);
              }),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBpiCard(int overallBpi, int percentile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNeon.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.stars_rounded, color: Colors.white70, size: 18),
              SizedBox(width: 6),
              Text(
                'OVERALL BPI SCORE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$overallBpi',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 68,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '🏆 TOP $percentile% OF MIND TRAINERS WORLDWIDE',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        _quickStatTile(
          '${profile!.totalWorkoutsCompleted}',
          'Workouts Done',
          Icons.fitness_center,
          AppTheme.primaryNeon,
        ),
        const SizedBox(width: 10),
        _quickStatTile(
          '${profile!.currentStreak} Days',
          'Current Streak',
          Icons.local_fire_department,
          AppTheme.amberProblemSolving,
        ),
        const SizedBox(width: 10),
        _quickStatTile(
          '${profile!.bestStreak} Days',
          'Best Streak',
          Icons.emoji_events,
          AppTheme.coralFlexibility,
        ),
      ],
    );
  }

  Widget _quickStatTile(String val, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceCardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              val,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarChartCard() {
    return Container(
      height: 330,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.surfaceCardBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNeon.withValues(alpha: 0.05),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.circle,
          radarBorderData: const BorderSide(color: AppTheme.surfaceCardBorder),
          gridBorderData: BorderSide(
              color: AppTheme.surfaceCardBorder.withValues(alpha: 0.6)),
          tickBorderData: const BorderSide(color: Colors.transparent),
          titlePositionPercentageOffset: 0.18,
          titleTextStyle: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
          getTitle: (index, angle) {
            switch (index) {
              case 0:
                return const RadarChartTitle(text: 'SPEED');
              case 1:
                return const RadarChartTitle(text: 'MEMORY');
              case 2:
                return const RadarChartTitle(text: 'ATTENTION');
              case 3:
                return const RadarChartTitle(text: 'FLEXIBILITY');
              case 4:
                return const RadarChartTitle(text: 'PROBLEM');
              case 5:
                return const RadarChartTitle(text: 'LANGUAGE');
              default:
                return const RadarChartTitle(text: '');
            }
          },
          dataSets: [
            RadarDataSet(
              fillColor: AppTheme.primaryNeon.withValues(alpha: 0.20),
              borderColor: AppTheme.primaryNeon,
              borderWidth: 2.5,
              entryRadius: 4.5,
              dataEntries: CognitiveDomain.values.map((d) {
                int val = profile!.domainBpi[d] ?? 600;
                return RadarEntry(value: val.toDouble());
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainCard(
      CognitiveDomain domain, int bpiVal, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.surfaceCardBorder),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      domain.displayName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$bpiVal BPI',
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (bpiVal / 1500.0).clamp(0.1, 1.0),
                    backgroundColor: AppTheme.bgDark,
                    color: color,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => _launchDomainGame(domain),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.play_arrow_rounded, color: color, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDomainColor(CognitiveDomain domain) {
    switch (domain) {
      case CognitiveDomain.speed:
        return AppTheme.cyanSpeed;
      case CognitiveDomain.memory:
        return AppTheme.purpleMemory;
      case CognitiveDomain.attention:
        return AppTheme.emeraldAttention;
      case CognitiveDomain.flexibility:
        return AppTheme.coralFlexibility;
      case CognitiveDomain.problemSolving:
        return AppTheme.amberProblemSolving;
      case CognitiveDomain.language:
        return AppTheme.pinkLanguage;
    }
  }

  IconData _getDomainIcon(CognitiveDomain domain) {
    switch (domain) {
      case CognitiveDomain.speed:
        return Icons.bolt;
      case CognitiveDomain.memory:
        return Icons.psychology;
      case CognitiveDomain.attention:
        return Icons.remove_red_eye;
      case CognitiveDomain.flexibility:
        return Icons.swap_calls;
      case CognitiveDomain.problemSolving:
        return Icons.calculate;
      case CognitiveDomain.language:
        return Icons.font_download;
    }
  }
}
