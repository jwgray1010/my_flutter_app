import 'package:flutter_test/flutter_test.dart';
import 'package:unsaid/choir_mvp/vocal_coach_models.dart';
import 'package:unsaid/choir_mvp/vocal_coach_planner.dart';

void main() {
  group('VocalCoachPlanner', () {
    test('quick mode returns up to 2 focus areas and exercises', () {
      final planner = VocalCoachPlanner();
      final bundle = planner.buildPlanBundle(
        studentId: 'alto_maya',
        studentName: 'Maya L',
        mode: VocalCoachMode.quickSkillCheck,
        taskMetrics: <VocalCoachTaskType, VocalTaskMetrics>{
          VocalCoachTaskType.pitchMatch: const VocalTaskMetrics(
            pitchAccuracy: 58,
            stabilityScore: 52,
            onsetTimingScore: 64,
            confidenceScore: 78,
          ),
          VocalCoachTaskType.arpeggio1358531: const VocalTaskMetrics(
            pitchAccuracy: 49,
            stabilityScore: 56,
            onsetTimingScore: 60,
            confidenceScore: 74,
          ),
          VocalCoachTaskType.rhythmAlignmentToClick: const VocalTaskMetrics(
            pitchAccuracy: 72,
            stabilityScore: 68,
            onsetTimingScore: 55,
            confidenceScore: 70,
          ),
        },
      );

      expect(bundle.profile.focusAreas.isNotEmpty, true);
      expect(bundle.profile.focusAreas.length <= 2, true);
      expect(bundle.suggestedExerciseWarmupIds.length, 2);
      expect(bundle.suggestedDrill.isNotEmpty, true);
    });

    test('full mode builds a 2-week plan with profile focus areas', () {
      final planner = VocalCoachPlanner();
      final bundle = planner.buildPlanBundle(
        studentId: 'tenor_joel',
        studentName: 'Joel T',
        mode: VocalCoachMode.fullPreAssessment,
        taskMetrics: <VocalCoachTaskType, VocalTaskMetrics>{
          VocalCoachTaskType.pitchMatch: const VocalTaskMetrics(
            pitchAccuracy: 62,
            stabilityScore: 66,
            onsetTimingScore: 61,
            confidenceScore: 82,
          ),
          VocalCoachTaskType.fiveToneScale: const VocalTaskMetrics(
            pitchAccuracy: 64,
            stabilityScore: 67,
            onsetTimingScore: 63,
            confidenceScore: 79,
          ),
          VocalCoachTaskType.arpeggio1358531: const VocalTaskMetrics(
            pitchAccuracy: 58,
            stabilityScore: 59,
            onsetTimingScore: 57,
            confidenceScore: 75,
          ),
          VocalCoachTaskType.sustainSixSeconds: const VocalTaskMetrics(
            pitchAccuracy: 54,
            stabilityScore: 52,
            onsetTimingScore: 60,
            confidenceScore: 77,
          ),
          VocalCoachTaskType.rhythmAlignmentToClick: const VocalTaskMetrics(
            pitchAccuracy: 70,
            stabilityScore: 68,
            onsetTimingScore: 53,
            confidenceScore: 74,
          ),
        },
      );

      expect(bundle.plan.items.isNotEmpty, true);
      expect(bundle.plan.endDate.isAfter(bundle.plan.startDate), true);
      expect(bundle.profile.focusAreas.length <= 3, true);
      expect(bundle.profile.focusAreas.length, bundle.plan.items.length);
      for (final item in bundle.plan.items) {
        expect(item.warmupIds.isNotEmpty, true);
      }
    });

    test('low confidence flags profile as not final', () {
      final planner = VocalCoachPlanner();
      final bundle = planner.buildPlanBundle(
        studentId: 'bass_ryan',
        studentName: 'Ryan B',
        mode: VocalCoachMode.fullPreAssessment,
        taskMetrics: <VocalCoachTaskType, VocalTaskMetrics>{
          VocalCoachTaskType.pitchMatch: const VocalTaskMetrics(
            pitchAccuracy: 40,
            stabilityScore: 42,
            onsetTimingScore: 39,
            confidenceScore: 22,
            lowConfidence: true,
          ),
        },
      );

      expect(bundle.profile.lowConfidence, true);
    });
  });

  group('VocalTrainingPlanItem parsing', () {
    test('clamps frequency and duration values', () {
      final item = VocalTrainingPlanItem.fromMap(const <String, dynamic>{
        'focusArea': 'pitch_stability',
        'warmupIds': ['a', 'b'],
        'drill': 'Drill',
        'recommendedFrequencyPerWeek': 99,
        'sessionDurationMinutes': -4,
      });
      expect(item.recommendedFrequencyPerWeek, 7);
      expect(item.sessionDurationMinutes, 1);
    });
  });
}

