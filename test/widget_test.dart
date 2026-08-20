import 'package:flutter_test/flutter_test.dart';
import 'package:think_lab/models/game_result.dart';
import 'package:think_lab/models/user_profile.dart';
import 'package:think_lab/services/bpi_engine.dart';

void main() {
  group('BPI Engine & UserProfile Tests', () {
    test('Initial profile has default domain scores and overall BPI', () {
      final profile = UserProfile.defaultProfile();
      expect(profile.overallBpi, 620);
      expect(profile.domainBpi[CognitiveDomain.memory], 640);
      expect(profile.domainBpi[CognitiveDomain.speed], 600);
      expect(profile.currentStreak, 3);
    });

    test('BpiEngine computes positive BPI gain for good performance', () {
      int gain = BpiEngine.calculateBpiGain(
        rawScore: 5000,
        accuracyPercent: 95.0,
        levelReached: 5,
        currentDomainBpi: 600,
      );
      expect(gain, greaterThan(0));
    });

    test('Processing game result updates high score and domain BPI', () {
      final profile = UserProfile.defaultProfile();
      int initialOverall = profile.overallBpi;

      final result = GameResult(
        gameId: 'spatial_memory',
        gameTitle: 'Spatial Memory',
        domain: CognitiveDomain.memory,
        score: 9999,
        accuracyPercent: 100.0,
        levelReached: 8,
        bpiGain: 25,
        timestamp: DateTime.now(),
      );

      BpiEngine.processGameResult(profile, result);

      expect(profile.highScores['spatial_memory'], 9999);
      expect(profile.domainBpi[CognitiveDomain.memory], 665); // 640 + 25
      expect(profile.overallBpi, greaterThan(initialOverall));
    });

    test('Percentile calculator returns valid percentile values', () {
      expect(BpiEngine.getPercentile(500), greaterThanOrEqualTo(40));
      expect(BpiEngine.getPercentile(1200), greaterThanOrEqualTo(93));
    });
  });
}
