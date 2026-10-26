import 'dart:async';
import 'dart:math' as math;

import 'checkin_assessment.dart';
import 'vocal_coach_models.dart';

class VocalCoachAssessmentEngine {
  VocalCoachAssessmentEngine({
    CheckInAudioCapture? capture,
  }) : _capture = capture ?? CheckInAudioCapture();

  final CheckInAudioCapture _capture;

  Future<bool> requestPermission() {
    return _capture.measurePermission();
  }

  Future<NoiseProbeResult> measureNoise({
    Duration duration = const Duration(seconds: 2),
    double loudThresholdDbFs = -23.0,
  }) {
    return _capture.measureAmbientNoise(
      duration: duration,
      loudThresholdDbFs: loudThresholdDbFs,
    );
  }

  Future<VocalTaskMetrics> runTask(
    VocalCoachTaskType task, {
    Duration? duration,
    int minConfidenceScore = 45,
  }) async {
    final started = await _capture.start();
    if (!started) {
      return const VocalTaskMetrics(
        pitchAccuracy: 0,
        stabilityScore: 0,
        onsetTimingScore: 0,
        confidenceScore: 0,
        lowConfidence: true,
      );
    }
    await Future<void>.delayed(duration ?? _defaultDuration(task));
    final audio = await _capture.stop();
    return _assessTask(
      task: task,
      audio: audio,
      minConfidenceScore: minConfidenceScore,
    );
  }

  Future<void> dispose() {
    return _capture.dispose();
  }

  VocalTaskMetrics _assessTask({
    required VocalCoachTaskType task,
    required CheckInRecordedAudio audio,
    required int minConfidenceScore,
  }) {
    if (audio.samples.isEmpty || audio.durationSeconds <= 0.15) {
      return const VocalTaskMetrics(
        pitchAccuracy: 0,
        stabilityScore: 0,
        onsetTimingScore: 0,
        confidenceScore: 0,
        lowConfidence: true,
      );
    }
    final frames = _extractFrames(audio.samples, audio.sampleRate);
    if (frames.isEmpty) {
      return const VocalTaskMetrics(
        pitchAccuracy: 0,
        stabilityScore: 0,
        onsetTimingScore: 0,
        confidenceScore: 0,
        lowConfidence: true,
      );
    }

    final confidenceScore = ((_average(
                  frames.map((entry) => entry.confidence).toList(growable: false),
                ) *
                100)
            .round()
            .clamp(0, 100)
        as num)
        .toInt();

    if (confidenceScore < minConfidenceScore) {
      return VocalTaskMetrics(
        pitchAccuracy: 0,
        stabilityScore: 0,
        onsetTimingScore: 0,
        confidenceScore: confidenceScore,
        lowConfidence: true,
      );
    }

    final pitchAccuracy = _pitchScore(task, frames, audio.durationSeconds);
    final stabilityScore = _stabilityScore(task, frames, audio.durationSeconds);
    final onsetTimingScore = _onsetTimingScore(task, frames, audio.durationSeconds);

    return VocalTaskMetrics(
      pitchAccuracy: pitchAccuracy,
      stabilityScore: stabilityScore,
      onsetTimingScore: onsetTimingScore,
      confidenceScore: confidenceScore,
      lowConfidence: false,
    );
  }

  Duration _defaultDuration(VocalCoachTaskType task) {
    switch (task) {
      case VocalCoachTaskType.pitchMatch:
        return const Duration(seconds: 6);
      case VocalCoachTaskType.fiveToneScale:
        return const Duration(seconds: 7);
      case VocalCoachTaskType.arpeggio1358531:
        return const Duration(seconds: 7);
      case VocalCoachTaskType.sustainSixSeconds:
        return const Duration(seconds: 6);
      case VocalCoachTaskType.rhythmAlignmentToClick:
        return const Duration(seconds: 8);
    }
  }

  int _pitchScore(
    VocalCoachTaskType task,
    List<_AnalyzedFrame> frames,
    double durationSeconds,
  ) {
    final expected = _expectedMidi(task);
    if (expected.isEmpty) {
      return 0;
    }
    final segmentSec = durationSeconds / expected.length;
    if (segmentSec <= 0.0) {
      return 0;
    }
    var scoreTotal = 0.0;
    var hitCount = 0;
    for (var i = 0; i < expected.length; i++) {
      final segStart = segmentSec * i;
      final segEnd = segmentSec * (i + 1);
      final voiced = frames
          .where(
            (entry) =>
                entry.timeSec >= segStart &&
                entry.timeSec < segEnd &&
                entry.midi != null,
          )
          .toList(growable: false);
      if (voiced.isEmpty) {
        continue;
      }
      final median = _median(
        voiced.map((entry) => entry.midi!).toList(growable: false),
      );
      final diff = (median - expected[i]).abs();
      final segmentScore = (100 - (diff * 21)).clamp(0.0, 100.0);
      scoreTotal += segmentScore;
      hitCount += 1;
    }
    if (hitCount == 0) {
      return 0;
    }
    return ((scoreTotal / hitCount).round().clamp(0, 100) as num).toInt();
  }

  int _stabilityScore(
    VocalCoachTaskType task,
    List<_AnalyzedFrame> frames,
    double durationSeconds,
  ) {
    Iterable<_AnalyzedFrame> voiced = frames.where((entry) => entry.midi != null);
    if (task == VocalCoachTaskType.sustainSixSeconds) {
      final middleStart = durationSeconds * 0.2;
      final middleEnd = durationSeconds * 0.8;
      voiced = voiced.where(
        (entry) => entry.timeSec >= middleStart && entry.timeSec <= middleEnd,
      );
    }
    final midiValues = voiced.map((entry) => entry.midi!).toList(growable: false);
    if (midiValues.isEmpty) {
      return 0;
    }
    final spread = _stddev(midiValues);
    final baseScore = (100 - spread * 24).clamp(0.0, 100.0);

    if (task == VocalCoachTaskType.sustainSixSeconds) {
      final voicedCoverage = midiValues.length / math.max(1, frames.length);
      final coverageBoost = voicedCoverage >= 0.6 ? 8.0 : voicedCoverage * 12.0;
      return ((baseScore + coverageBoost).round().clamp(0, 100) as num).toInt();
    }
    return (baseScore.round().clamp(0, 100) as num).toInt();
  }

  int _onsetTimingScore(
    VocalCoachTaskType task,
    List<_AnalyzedFrame> frames,
    double durationSeconds,
  ) {
    if (task == VocalCoachTaskType.rhythmAlignmentToClick) {
      return _rhythmOnsetScore(frames);
    }
    final voiced = frames.where((entry) => entry.midi != null).toList(growable: false);
    if (voiced.isEmpty) {
      return 0;
    }
    final firstOnset = voiced.first.timeSec;
    final targetOnset = durationSeconds * 0.1;
    final diff = (firstOnset - targetOnset).abs();
    return ((100 - (diff * 180)).round().clamp(0, 100) as num).toInt();
  }

  int _rhythmOnsetScore(List<_AnalyzedFrame> frames) {
    final onsets = <double>[];
    double? lastOnset;
    for (final frame in frames) {
      if (frame.midi == null || frame.confidence < 0.35) {
        continue;
      }
      if (lastOnset == null || (frame.timeSec - lastOnset) >= 0.24) {
        onsets.add(frame.timeSec);
        lastOnset = frame.timeSec;
      }
    }
    if (onsets.length < 2) {
      return 0;
    }
    final intervals = <double>[];
    for (var i = 1; i < onsets.length; i++) {
      intervals.add(onsets[i] - onsets[i - 1]);
    }
    final expectedBeatSec = 0.5;
    var sumDiff = 0.0;
    for (final interval in intervals) {
      sumDiff += (interval - expectedBeatSec).abs();
    }
    final avgDiff = sumDiff / intervals.length;
    return ((100 - avgDiff * 220).round().clamp(0, 100) as num).toInt();
  }

  List<double> _expectedMidi(VocalCoachTaskType task) {
    switch (task) {
      case VocalCoachTaskType.pitchMatch:
        return const [60, 62, 64, 65, 67];
      case VocalCoachTaskType.fiveToneScale:
        return const [60, 62, 64, 65, 67, 65, 64, 62, 60];
      case VocalCoachTaskType.arpeggio1358531:
        return const [60, 64, 67, 72, 67, 64, 60];
      case VocalCoachTaskType.sustainSixSeconds:
        return const [64, 64, 64, 64];
      case VocalCoachTaskType.rhythmAlignmentToClick:
        return const [60, 60, 60, 60, 60, 60, 60, 60];
    }
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

