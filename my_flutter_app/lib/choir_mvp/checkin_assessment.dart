import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';

import 'class_session_models.dart';

class NoiseProbeResult {
  const NoiseProbeResult({
    required this.available,
    required this.rmsDbFs,
    required this.tooLoud,
  });

  final bool available;
  final double rmsDbFs;
  final bool tooLoud;
}

class ExpectedMeasureProfile {
  const ExpectedMeasureProfile({
    required this.measure,
    required this.expectedMidi,
    required this.noteCount,
  });

  final int measure;
  final double expectedMidi;
  final int noteCount;
}

class CheckInMeasureScore {
  const CheckInMeasureScore({
    required this.measure,
    required this.pitchScore,
    required this.timingScore,
    required this.confidenceScore,
    required this.feedbackTag,
  });

  final int measure;
  final int pitchScore;
  final int timingScore;
  final int confidenceScore;
  final String feedbackTag;
}

class CheckInAssessmentOutput {
  const CheckInAssessmentOutput({
    required this.result,
    required this.troubleMeasures,
    required this.feedbackMessages,
    required this.overallConfidence,
    required this.measureScores,
  });

  final CheckInResult result;
  final List<int> troubleMeasures;
  final List<String> feedbackMessages;
  final int overallConfidence;
  final List<CheckInMeasureScore> measureScores;
}

class CheckInRecordedAudio {
  const CheckInRecordedAudio({
    required this.samples,
    required this.sampleRate,
    required this.durationSeconds,
  });

  final List<int> samples;
  final int sampleRate;
  final double durationSeconds;
}

class CheckInAudioCapture {
  CheckInAudioCapture({
    this.sampleRate = 16000,
  });

  final int sampleRate;
  final AudioRecorder _recorder = AudioRecorder();
  final List<int> _samples = <int>[];
  StreamSubscription<Uint8List>? _sub;

  Future<bool> measurePermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (_) {
      return false;
    }
  }

  Future<NoiseProbeResult> measureAmbientNoise({
    Duration duration = const Duration(seconds: 2),
    double loudThresholdDbFs = -23.0,
  }) async {
    if (!await measurePermission()) {
      return const NoiseProbeResult(
        available: false,
        rmsDbFs: -120,
        tooLoud: false,
      );
    }
    var sampleCount = 0;
    var sumSquares = 0.0;
    StreamSubscription<Uint8List>? subscription;
    try {
      final stream = await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
        ),
      );
      subscription = stream.listen((chunk) {
        final values = _decodePcm16(chunk);
        for (final value in values) {
          final normalized = value / 32768.0;
          sumSquares += normalized * normalized;
          sampleCount += 1;
        }
      });
      await Future<void>.delayed(duration);
    } catch (_) {
      return const NoiseProbeResult(
        available: false,
        rmsDbFs: -120,
        tooLoud: false,
      );
    } finally {
      await subscription?.cancel();
      try {
        await _recorder.stop();
      } catch (_) {}
    }
    if (sampleCount <= 0) {
      return const NoiseProbeResult(
        available: true,
        rmsDbFs: -120,
        tooLoud: false,
      );
    }
    final rms = math.sqrt(sumSquares / sampleCount);
    final db = 20.0 * math.log(rms <= 1e-8 ? 1e-8 : rms) / math.ln10;
    return NoiseProbeResult(
      available: true,
      rmsDbFs: db,
      tooLoud: db > loudThresholdDbFs,
    );
  }

  Future<bool> start() async {
    if (!await measurePermission()) {
      return false;
    }
    _samples.clear();
    try {
      final stream = await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
        ),
      );
      _sub = stream.listen((chunk) {
        _samples.addAll(_decodePcm16(chunk));
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<CheckInRecordedAudio> stop() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    final samples = List<int>.from(_samples);
    final duration = sampleRate <= 0 ? 0 : samples.length / sampleRate;
    _samples.clear();
    return CheckInRecordedAudio(
      samples: samples,
      sampleRate: sampleRate,
      durationSeconds: duration,
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _recorder.dispose();
    } catch (_) {}
  }
}

class CheckInAssessmentEngine {
  static CheckInAssessmentOutput assess({
    required CheckInRecordedAudio audio,
    required Map<int, ExpectedMeasureProfile> expectedByMeasure,
    required int minMeasure,
    required int maxMeasure,
    int minConfidence = 45,
    int pitchThreshold = 68,
    int timingThreshold = 62,
  }) {
    final measureCount = ((maxMeasure - minMeasure + 1).clamp(1, 1000) as num).toInt();
    if (audio.samples.isEmpty || audio.durationSeconds <= 0.1) {
      return const CheckInAssessmentOutput(
        result: CheckInResult.lowConfidence,
        troubleMeasures: <int>[],
        feedbackMessages: <String>['Low confidence', 'Move closer or quieter'],
        overallConfidence: 0,
        measureScores: <CheckInMeasureScore>[],
      );
    }

    final frames = _extractFrames(audio.samples, audio.sampleRate);
    if (frames.isEmpty) {
      return const CheckInAssessmentOutput(
        result: CheckInResult.lowConfidence,
        troubleMeasures: <int>[],
        feedbackMessages: <String>['Low confidence', 'Move closer or quieter'],
        overallConfidence: 0,
        measureScores: <CheckInMeasureScore>[],
      );
    }

    final overallConfidence = _average(
      frames.map((frame) => frame.confidence).toList(),
    );
    final overallConfidenceScore =
        ((overallConfidence * 100).round().clamp(0, 100) as num).toInt();
    if (overallConfidenceScore < minConfidence) {
      return CheckInAssessmentOutput(
        result: CheckInResult.lowConfidence,
        troubleMeasures: const <int>[],
        feedbackMessages: const <String>[
          'Low confidence',
          'Move closer / quieter area',
        ],
        overallConfidence: overallConfidenceScore,
        measureScores: const <CheckInMeasureScore>[],
      );
    }

    final segmentSeconds = audio.durationSeconds / measureCount;
    final measureScores = <CheckInMeasureScore>[];
    final troubleMeasures = <int>[];
    final feedback = <String>{};
    var passingMeasures = 0;
    var confidentMeasures = 0;

    for (var i = 0; i < measureCount; i++) {
      final measure = minMeasure + i;
      final startSec = i * segmentSeconds;
      final endSec = (i + 1) * segmentSeconds;
      final segment = frames
          .where((frame) => frame.timeSec >= startSec && frame.timeSec < endSec)
          .toList();
      final profile = expectedByMeasure[measure];
      final expectedMidi = profile?.expectedMidi ?? 60.0;

      final voiced = segment.where((frame) => frame.midi != null).toList();
      final confidence = _average(segment.map((frame) => frame.confidence).toList());
      final confidenceScore =
          ((confidence * 100).round().clamp(0, 100) as num).toInt();
      if (confidenceScore >= minConfidence) {
        confidentMeasures += 1;
      }

      final pitchMedian = voiced.isEmpty
          ? expectedMidi
          : _median(voiced.map((frame) => frame.midi!).toList());
      final pitchDiff = (pitchMedian - expectedMidi).abs();
      final pitchScore = ((100 - (pitchDiff * 17)).round().clamp(0, 100) as num).toInt();

      int timingScore;
      if (voiced.isEmpty) {
        timingScore = 0;
      } else {
        final firstVoicedSec = voiced.first.timeSec - startSec;
        final onsetRatio = segmentSeconds <= 1e-5 ? 0 : firstVoicedSec / segmentSeconds;
        timingScore = ((100 - (math.max(0, onsetRatio - 0.18) * 180))
                    .round()
                    .clamp(0, 100)
                as num)
            .toInt();
      }

      String feedbackTag = 'OK';
      final unstable = _stddev(voiced.map((frame) => frame.midi ?? 0.0).toList()) > 1.5;
      if (confidenceScore >= minConfidence &&
          (pitchScore < pitchThreshold || timingScore < timingThreshold)) {
        troubleMeasures.add(measure);
        if (pitchScore < pitchThreshold) {
          feedbackTag = 'Pitch drift';
          feedback.add('Pitch drift');
        } else if (timingScore < timingThreshold) {
          feedbackTag = 'Entrance timing';
          feedback.add('Entrance timing');
        } else if (unstable) {
          feedbackTag = 'Unstable sustain';
          feedback.add('Unstable sustain');
        }
      } else if (unstable) {
        feedbackTag = 'Unstable sustain';
        feedback.add('Unstable sustain');
      }

      if (confidenceScore >= minConfidence &&
          pitchScore >= pitchThreshold &&
          timingScore >= timingThreshold) {
        passingMeasures += 1;
      }

      measureScores.add(
        CheckInMeasureScore(
          measure: measure,
          pitchScore: pitchScore,
          timingScore: timingScore,
          confidenceScore: confidenceScore,
          feedbackTag: feedbackTag,
        ),
      );
    }

    final passRatio = measureCount <= 0 ? 0.0 : passingMeasures / measureCount;
    final result = passRatio >= 0.8 && confidentMeasures >= (measureCount * 0.8).round()
        ? CheckInResult.pass
        : CheckInResult.needsWork;
    final feedbackList = feedback.take(3).toList();
    if (feedbackList.isEmpty && result == CheckInResult.needsWork) {
      feedbackList.add('Entrance timing');
    }
    return CheckInAssessmentOutput(
      result: result,
      troubleMeasures: troubleMeasures.take(3).toList(),
      feedbackMessages: feedbackList,
      overallConfidence: overallConfidenceScore,
      measureScores: measureScores,
    );
  }
}

class _AnalyzedFrame {
  const _AnalyzedFrame({
    required this.timeSec,
    required this.confidence,
    required this.midi,
  });

  final double timeSec;
  final double confidence;
  final double? midi;
}

List<_AnalyzedFrame> _extractFrames(List<int> samples, int sampleRate) {
  const frameSize = 1024;
  const hopSize = 256;
  if (samples.length < frameSize || sampleRate <= 0) {
    return const <_AnalyzedFrame>[];
  }
  final frames = <_AnalyzedFrame>[];
  final minLag = (sampleRate / 1000).round();
  final maxLag = (sampleRate / 80).round();
  var index = 0;
  while (index + frameSize < samples.length) {
    final frame = samples.sublist(index, index + frameSize);
    final rms = _rms(frame);
    if (rms < 0.008) {
      frames.add(
        _AnalyzedFrame(
          timeSec: index / sampleRate,
          confidence: 0.0,
          midi: null,
        ),
      );
      index += hopSize;
      continue;
    }

    var bestLag = minLag;
    var bestCorr = 0.0;
    for (var lag = minLag; lag <= maxLag; lag++) {
      final corr = _normalizedAutocorr(frame, lag);
      if (corr > bestCorr) {
        bestCorr = corr;
        bestLag = lag;
      }
    }

    if (bestCorr < 0.16) {
      frames.add(
        _AnalyzedFrame(
          timeSec: index / sampleRate,
          confidence: 0.1,
          midi: null,
        ),
      );
      index += hopSize;
      continue;
    }
    final hz = sampleRate / bestLag;
    final midi = 69 + 12 * (math.log(hz / 440.0) / math.ln2);
    final confidence = (((bestCorr - 0.16) / 0.74).clamp(0.0, 1.0) as num).toDouble();
    frames.add(
      _AnalyzedFrame(
        timeSec: index / sampleRate,
        confidence: confidence,
        midi: midi,
      ),
    );
    index += hopSize;
  }
  return frames;
}

double _rms(List<int> frame) {
  var sum = 0.0;
  for (final value in frame) {
    final normalized = value / 32768.0;
    sum += normalized * normalized;
  }
  return math.sqrt(sum / frame.length);
}

double _normalizedAutocorr(List<int> frame, int lag) {
  var num = 0.0;
  var den1 = 0.0;
  var den2 = 0.0;
  for (var i = 0; i < frame.length - lag; i++) {
    final a = frame[i].toDouble();
    final b = frame[i + lag].toDouble();
    num += a * b;
    den1 += a * a;
    den2 += b * b;
  }
  final den = math.sqrt(den1 * den2);
  if (den <= 1e-8) {
    return 0.0;
  }
  return ((num / den).clamp(-1.0, 1.0) as num).toDouble();
}

double _average(List<double> values) {
  if (values.isEmpty) {
    return 0.0;
  }
  final sum = values.fold<double>(0.0, (a, b) => a + b);
  return sum / values.length;
}

double _median(List<double> values) {
  if (values.isEmpty) {
    return 0.0;
  }
  final sorted = List<double>.from(values)..sort();
  return sorted[sorted.length ~/ 2];
}

double _stddev(List<double> values) {
  if (values.length < 2) {
    return 0.0;
  }
  final avg = _average(values);
  var sum = 0.0;
  for (final value in values) {
    final d = value - avg;
    sum += d * d;
  }
  return math.sqrt(sum / values.length);
}

List<int> _decodePcm16(Uint8List bytes) {
  final result = <int>[];
  for (var i = 0; i + 1 < bytes.length; i += 2) {
    final value = ByteData.sublistView(bytes, i, i + 2).getInt16(0, Endian.little);
    result.add(value);
  }
  return result;
}

