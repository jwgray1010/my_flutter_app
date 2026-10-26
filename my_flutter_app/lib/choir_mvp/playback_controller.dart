import 'models.dart';
import 'playback_engine.dart';

typedef Part = ChoirPart;

enum MixPreset {
  all,
  isolateTarget,
  exactParts,
}

class JumpToMeasureResult {
  const JumpToMeasureResult({
    required this.requested,
    required this.resolved,
  });

  final int requested;
  final int resolved;

  bool get wasClamped => requested != resolved;
}

class PlaybackController {
  PlaybackController({
    required PlaybackEngine playback,
    required void Function() onChanged,
  }) : _playback = playback,
       _onChanged = onChanged;

  final PlaybackEngine _playback;
  final void Function() _onChanged;
  bool _loopArmed = false;

  bool get loopArmed => _loopArmed;

  Future<void> play() async {
    await _playback.play();
    _onChanged();
  }

  void pause() {
    _playback.pause();
    _onChanged();
  }

  Future<JumpToMeasureResult> jumpToMeasure(int m, {bool autoPlay = false}) async {
    final resolved = _resolveMeasure(m);
    _playback.jumpToMeasure(resolved);
    if (autoPlay) {
      await _playback.play();
    }
    _onChanged();
    return JumpToMeasureResult(requested: m, resolved: resolved);
  }

  void jumpRelative(int delta) {
    _playback.jumpByMeasures(delta);
    _onChanged();
  }

  void setTempoPercent(int p) {
    _playback.setTempoPercent(p.toDouble());
    _onChanged();
  }

  void adjustTempoPercent(int delta) {
    final next = (_playback.tempoPercent + delta).round();
    _playback.setTempoPercent(next.toDouble());
    _onChanged();
  }

  void setLoopA({required int measure}) {
    _playback.setLoopA(measure);
    _loopArmed = false;
    _onChanged();
  }

  void setLoopB({required int measure}) {
    _playback.setLoopB(measure);
    _loopArmed = false;
    _onChanged();
  }

  void setLoopRange({required int a, required int b}) {
    final start = a <= b ? a : b;
    final end = a <= b ? b : a;
    _playback.setLoopA(start);
    _playback.setLoopB(end);
    _loopArmed = false;
    _onChanged();
  }

  void clearLoop() {
    _playback.clearLoop();
    _loopArmed = false;
    _onChanged();
  }

  void resetLoopArmed() {
    _loopArmed = false;
    _onChanged();
  }

  void toggleLoopArmed() {
    _loopArmed = !_loopArmed;
    _onChanged();
  }

  void setPartsEnabled(Set<Part> parts, {bool? pianoOn}) {
    final enabled = Set<Part>.from(parts);
    if (pianoOn != null) {
      if (pianoOn) {
        enabled.add(Part.piano);
      } else {
        enabled.remove(Part.piano);
      }
    }
    _playback.setEnabledParts(enabled);
    _onChanged();
  }

  void setPreset(MixPreset preset, {Part? target, Set<Part>? exactParts, bool? pianoOn}) {
    switch (preset) {
      case MixPreset.all:
        _playback.setAllPartsEnabled();
        _onChanged();
        return;
      case MixPreset.isolateTarget:
        if (target == null) {
          return;
        }
        setPartsEnabled(<Part>{target}, pianoOn: pianoOn ?? true);
        return;
      case MixPreset.exactParts:
        setPartsEnabled(exactParts ?? <Part>{}, pianoOn: pianoOn);
        return;
    }
  }

  Future<void> playStartingPitches() async {
    await _playback.playStartingPitches();
    _onChanged();
  }

  Map<String, dynamic> snapshotState() {
    return <String, dynamic>{
      ..._playback.snapshotState(),
      'loopArmed': _loopArmed,
    };
  }

  int _resolveMeasure(int requested) {
    final score = _playback.score;
    if (score == null) {
      return requested;
    }
    return score.clampToKnownMeasure(requested);
  }
}

