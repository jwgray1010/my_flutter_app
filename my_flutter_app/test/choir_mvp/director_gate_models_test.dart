import 'package:flutter_test/flutter_test.dart';
import 'package:unsaid/choir_mvp/class_session_models.dart';

void main() {
  group('DirectorGateSettings', () {
    test('parses defaults when fields are missing', () {
      final settings = DirectorGateSettings.fromMap(const <String, dynamic>{});
      expect(settings.enabled, false);
      expect(settings.requiredTier, CheckInTier.acapellaClick);
      expect(settings.validityWindow, DirectorGateValidityWindow.rehearsalOnly);
      expect(settings.lowConfidenceBehavior, DirectorGateLowConfidenceBehavior.doesNotCount);
    });

    test('parses explicit values and clamps numeric fields', () {
      final settings = DirectorGateSettings.fromMap(const <String, dynamic>{
        'enabled': true,
        'requiredTier': 'PART_PLUS_ACCOMP',
        'validityWindow': 'CUSTOM_MINUTES',
        'customMinutes': 9999,
        'lowConfidenceBehavior': 'COUNTS_AS_ATTEMPT_ONLY',
        'retryCooldownSeconds': -12,
      });
      expect(settings.enabled, true);
      expect(settings.requiredTier, CheckInTier.partPlusAccomp);
      expect(settings.validityWindow, DirectorGateValidityWindow.customMinutes);
      expect(settings.customMinutes, 24 * 60);
      expect(
        settings.lowConfidenceBehavior,
        DirectorGateLowConfidenceBehavior.countsAsAttemptOnly,
      );
      expect(settings.retryCooldownSeconds, 0);
    });
  });

  group('StudentCheckInProgress clearance fields', () {
    test('serializes and restores clearance metadata', () {
      final original = StudentCheckInProgress(
        studentName: 'Alex P',
        stationId: 'station_a',
        studentId: 'station_a_alex p',
        partId: 'ALTO',
        latestTier: CheckInTier.acapellaClick,
        latestResult: CheckInResult.pass,
        highestScoredTierPassed: 2,
        challengeTier4Completed: false,
        challengeTier5Completed: false,
        latestTroubleMeasures: const <int>[12, 14],
        lastUpdatedAt: DateTime.parse('2026-02-12T10:30:00Z'),
        clearanceStatus: StudentClearanceStatus.cleared,
        clearanceTierPassed: 2,
        clearanceTimestamp: DateTime.parse('2026-02-12T10:30:00Z'),
        clearanceExpiresAt: DateTime.parse('2026-02-12T11:30:00Z'),
      );
      final restored = StudentCheckInProgress.fromMap(original.toMap());
      expect(restored.studentName, original.studentName);
      expect(restored.studentId, original.studentId);
      expect(restored.clearanceStatus, StudentClearanceStatus.cleared);
      expect(restored.clearanceTierPassed, 2);
      expect(
        restored.clearanceExpiresAt?.toIso8601String(),
        '2026-02-12T11:30:00.000Z',
      );
    });
  });
}

