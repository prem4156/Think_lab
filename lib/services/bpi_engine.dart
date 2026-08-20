import 'dart:math';
import '../models/game_result.dart';
import '../models/user_profile.dart';

class BpiEngine {
  /// Computes BPI point yield from raw score, accuracy %, and level reached
  static int calculateBpiGain({
    required int rawScore,
    required double accuracyPercent,
    required int levelReached,
    required int currentDomainBpi,
  }) {
    // Expected target score for benchmark
    double benchmarkScore = 3000.0 + (levelReached * 400.0);
    double scoreRatio = (rawScore / max(1, benchmarkScore)).clamp(0.2, 2.5);
    double accuracyMultiplier = (accuracyPercent / 100.0).clamp(0.5, 1.0);

    // Calculated performance score for this game run
    double targetBpiRun = 500 + (scoreRatio * 400 * accuracyMultiplier);

    // Dynamic adjustment shift relative to user's current domain BPI
    double delta = (targetBpiRun - currentDomainBpi) * 0.12;

    // Minimum gain for completing a game, scaled up for high performances
    if (delta > 0) {
      return max(8, delta.round());
    } else {
      return max(2, (delta * 0.3).round());
    }
  }

  /// Updates UserProfile with new game result
  static void processGameResult(UserProfile profile, GameResult result) {
    // 1. Update High Score
    int existingHigh = profile.highScores[result.gameId] ?? 0;
    if (result.score > existingHigh) {
      profile.highScores[result.gameId] = result.score;
    }

    // 2. Update Domain BPI
    int oldDomainBpi = profile.domainBpi[result.domain] ?? 600;
    int newDomainBpi = (oldDomainBpi + result.bpiGain).clamp(300, 2000);
    profile.domainBpi[result.domain] = newDomainBpi;

    // 3. Recalculate Overall BPI (Average of all 6 domains)
    int sum = 0;
    for (var d in CognitiveDomain.values) {
      sum += profile.domainBpi[d] ?? 600;
    }
    profile.overallBpi = (sum / CognitiveDomain.values.length).round();

    // 4. Update Games Played
    profile.totalGamesPlayed += 1;
  }

  /// Estimates percentile compared to average age/population norms
  static int getPercentile(int bpi) {
    if (bpi < 400) return 15;
    if (bpi < 600) return 40 + ((bpi - 400) ~/ 10);
    if (bpi < 800) return 60 + ((bpi - 600) ~/ 10);
    if (bpi < 1000) return 80 + ((bpi - 800) ~/ 15);
    if (bpi < 1200) return 93 + ((bpi - 1000) ~/ 40);
    return min(99, 98 + ((bpi - 1200) ~/ 100));
  }
}
