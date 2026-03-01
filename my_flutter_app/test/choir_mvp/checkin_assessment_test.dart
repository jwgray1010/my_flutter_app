import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:unsaid/choir_mvp/checkin_assessment.dart';
import 'package:unsaid/choir_mvp/class_session_models.dart';

void main() {
  group('CheckInAssessmentEngine', () {
    test('returns PASS for stable in-tune audio', () {
      final sampleRate = 16000;
      final seconds = 8;
      final samples = _sineWaveSamples(
        midi: 60,
        seconds: seconds,
        sampleRate: sampleRate,
      );
      final expected = <int, ExpectedMeasureProfile>{
        for (var measure = 24; measure <= 31; measure++)
          measure: ExpectedMeasureProfile(
            measure: measure,
            expectedMidi: 60,
            noteCount: 4,
          ),
      };

      final result = CheckInAssessmentEngine.assess(
        audio: CheckInRecordedAudio(
          samples: samples,
          sampleRate: sampleRate,
          durationSeconds: seconds.toDouble(),
        ),
        expectedByMeasure: expected,
        minMeasure: 24,
        maxMeasure: 31,
      );

      expect(result.result, CheckInResult.pass);
      expect(result.overallConfidence, greaterThanOrEqualTo(45));
    });

    test('returns NEEDS_WORK for strongly off-pitch audio', () {
      final sampleRate = 16000;
      final seconds = 8;
      final samples = _sineWaveSamples(
        midi: 66,
        seconds: seconds,
        sampleRate: sampleRate,
      );
      final expected = <int, ExpectedMeasureProfile>{
        for (var measure = 10; measure <= 17; measure++)
          measure: ExpectedMeasureProfile(
            measure: measure,
            expectedMidi: 60,
            noteCount: 4,
          ),
      };

      final result = CheckInAssessmentEngine.assess(
        audio: CheckInRecordedAudio(
          samples: samples,
          sampleRate: sampleRate,
          durationSeconds: seconds.toDouble(),
        ),
        expectedByMeasure: expected,
        minMeasure: 10,
        maxMeasure: 17,
      );

      expect(result.result, CheckInResult.needsWork);
      expect(result.troubleMeasures, isNotEmpty);
    });

    test('returns LOW_CONFIDENCE for empty audio', () {
      final result = CheckInAssessmentEngine.assess(
        audio: const CheckInRecordedAudio(
          samples: <int>[],
          sampleRate: 16000,
          durationSeconds: 0,
        ),
        expectedByMeasure: const <int, ExpectedMeasureProfile>{},
        minMeasure: 1,
        maxMeasure: 4,
      );

      expect(result.result, CheckInResult.lowConfidence);
    });
  });
}

List<int> _sineWaveSamples({
  required int midi,
  required int seconds,
  required int sampleRate,
}) {
  final hz = 440.0 * math.pow(2, (midi - 69) / 12).toDouble();
  final count = seconds * sampleRate;
  final data = <int>[];
  for (var i = 0; i < count; i++) {
    final value = (math.sin(2 * math.pi * hz * i / sampleRate) * 12000).round();
    data.add((value.clamp(-32768, 32767) as num).toInt());
  }
  return data;
}

