import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

import 'warmups_models.dart';

class WarmupEngine extends ChangeNotifier {
  final MidiPro _midi = MidiPro();

  Warmup? _warmup;
  WarmupTexture _texture = WarmupTexture.unison;
  WarmupStepMode _stepMode = WarmupStepMode.halfStep;
  WarmupDemoVoice _demoVoice = WarmupDemoVoice.treble;
  bool _demoOn = true;
  int _tempoBpm = 72;
  int _repeatsPerKey = 1;
  int _selectedRangePresetIndex = 0;

  bool _isPlaying = false;
  bool _loopRunning = false;
  bool _soundfontReady = false;
  int _runToken = 0;
  int? _soundfontId;
  String? _audioStatus;

  int _currentTonicMidi = 60;
  bool _transposeAscending = true;
  int _currentRepeat = 0;
  int _currentStep = 0;
  int _completedKeys = 0;
  String _statusLine = '';

  final Set<_ActiveNote> _activeNotes = <_ActiveNote>{};

  Warmup? get warmup => _warmup;
  WarmupTexture get texture => _texture;
  WarmupStepMode get stepMode => _stepMode;
  WarmupDemoVoice get demoVoice => _demoVoice;
  bool get demoOn => _demoOn;
  int get tempoBpm => _tempoBpm;
  int get repeatsPerKey => _repeatsPerKey;
  int get selectedRangePresetIndex => _selectedRangePresetIndex;
  bool get isPlaying => _isPlaying;
  int get currentRepeat => _currentRepeat;
  int get currentStep => _currentStep;
  int get completedKeys => _completedKeys;
  String get statusLine => _statusLine;
  String? get audioStatus => _audioStatus;

  WarmupRangePreset? get selectedRangePreset {
    final current = _warmup;
    if (current == null || current.rangePresets.isEmpty) {
      return null;
    }
    final index = _selectedRangePresetIndex.clamp(0, current.rangePresets.length - 1);
    return current.rangePresets[index];
  }

  String get currentKeyLabel => _noteName(_currentTonicMidi);

  Future<void> initializeAudio() async {
    if (_soundfontReady) {
      return;
    }
    try {
      _soundfontId = await _midi.loadSoundfontAsset(
        assetPath: 'assets/choir/tight_piano.sf2',
        bank: 0,
        program: 0,
      );
      _soundfontReady = _soundfontId != null;
      _audioStatus = _soundfontReady
          ? 'Warmup piano ready'
          : 'Failed to load warmup piano soundfont.';
    } catch (_) {
      _soundfontReady = false;
      _audioStatus = 'Warmup audio init failed.';
    }
    notifyListeners();
  }

  void loadWarmup(Warmup warmup) {
    _warmup = warmup;
    _texture = WarmupTexture.unison;
    _stepMode = warmup.defaultStepMode;
    _demoVoice = warmup.demoConfig.defaultVoice;
    _demoOn = warmup.demoConfig.defaultDemoOn && warmup.demoConfig.supportsDemo;
    _tempoBpm = warmup.defaultTempoBpm;
    _repeatsPerKey = warmup.repeatsPerKey.clamp(1, 3);
    _selectedRangePresetIndex = 0;
    _statusLine = 'Ready';
    _resetProgression(resetRepeat: true);
    _stopAllActiveNotes();
    notifyListeners();
  }

  void setTexture(WarmupTexture texture) {
    if (_texture == texture) {
      return;
    }
    _texture = texture;
    notifyListeners();
  }

  void setDemoOn(bool value) {
    if (_demoOn == value) {
      return;
    }
    _demoOn = value;
    if (!_demoOn) {
      _stopDemoNotes();
    }
    notifyListeners();
  }

  void setDemoVoice(WarmupDemoVoice voice) {
    if (_demoVoice == voice) {
      return;
    }
    _demoVoice = voice;
    notifyListeners();
  }

  void setStepMode(WarmupStepMode mode) {
    if (_stepMode == mode) {
      return;
    }
    _stepMode = mode;
    notifyListeners();
  }

  void setRangePresetIndex(int index) {
    final current = _warmup;
    if (current == null || current.rangePresets.isEmpty) {
      return;
    }
    final next = index.clamp(0, current.rangePresets.length - 1);
    if (next == _selectedRangePresetIndex) {
      return;
    }
    _selectedRangePresetIndex = next;
    _resetProgression(resetRepeat: false);
    notifyListeners();
  }

  void setRepeatsPerKey(int repeats) {
    final next = repeats.clamp(1, 3);
    if (next == _repeatsPerKey) {
      return;
    }
    _repeatsPerKey = next;
    notifyListeners();
  }

  void setTempoBpm(int bpm) {
    final next = bpm.clamp(50, 140);
    if (next == _tempoBpm) {
      return;
    }
    _tempoBpm = next;
    notifyListeners();
  }

  void adjustTempo(int delta) {
    setTempoBpm(_tempoBpm + delta);
  }

  Future<void> play() async {
    final current = _warmup;
    if (current == null) {
      return;
    }
    if (!_soundfontReady) {
      await initializeAudio();
    }
    if (!_soundfontReady || _soundfontId == null) {
      _audioStatus = 'Warmup playback unavailable.';
      notifyListeners();
      return;
    }
    _isPlaying = true;
    _statusLine = 'Playing';
    notifyListeners();
    if (!_loopRunning) {
      _loopRunning = true;
      final token = ++_runToken;
      unawaited(_runPlaybackLoop(token, current));
    }
  }

  void pause() {
    if (!_isPlaying) {
      return;
    }
    _isPlaying = false;
    _statusLine = 'Paused';
    _stopAllActiveNotes();
    notifyListeners();
  }

  void stop() {
    _isPlaying = false;
    _statusLine = 'Stopped';
    _runToken += 1;
    _loopRunning = false;
    _currentRepeat = 0;
    _currentStep = 0;
    _completedKeys = 0;
    _stopAllActiveNotes();
    _resetProgression(resetRepeat: true);
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    unawaited(_midi.dispose());
    super.dispose();
  }

  Future<void> _runPlaybackLoop(int token, Warmup initialWarmup) async {
    var warmup = initialWarmup;
    while (token == _runToken) {
      final latestWarmup = _warmup;
      if (latestWarmup == null) {
        break;
      }
      warmup = latestWarmup;
      if (!_isPlaying) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        continue;
      }
      final range = selectedRangePreset;
      if (range == null) {
        _isPlaying = false;
        _statusLine = 'No range preset';
        notifyListeners();
        break;
      }
      if (!_canRenderAtTonic(
        tonicMidi: _currentTonicMidi,
        pattern: warmup.melodyPattern,
        range: range,
      )) {
        final advanced = _advanceKey(
          range: range,
          pattern: warmup.melodyPattern,
        );
        if (!advanced) {
          _isPlaying = false;
          _statusLine = 'Range complete';
          notifyListeners();
          break;
        }
        continue;
      }

      final steps = _renderStepsForCurrentKey(
        warmup: warmup,
        range: range,
      );
      if (steps.isEmpty) {
        _isPlaying = false;
        _statusLine = 'No playable pattern';
        notifyListeners();
        break;
      }

      for (var index = _currentStep; index < steps.length;) {
        if (token != _runToken) {
          break;
        }
        if (!_isPlaying) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          continue;
        }
        _currentStep = index;
        _statusLine = 'Key $currentKeyLabel  Rep ${_currentRepeat + 1}/$_repeatsPerKey';
        notifyListeners();

        final step = steps[index];
        _playStep(step);
        final noteDone = await _waitBeats(step.noteOnBeats, token);
        _stopStep(step);
        if (!noteDone) {
          continue;
        }

        final remaining = step.totalBeats - step.noteOnBeats;
        if (remaining > 0) {
          final restDone = await _waitBeats(remaining, token);
          if (!restDone) {
            continue;
          }
        }
        index += 1;
      }

      if (token != _runToken) {
        break;
      }
      if (!_isPlaying) {
        continue;
      }

      _currentStep = 0;
      _currentRepeat += 1;
      notifyListeners();

      if (_currentRepeat < _repeatsPerKey) {
        continue;
      }
      _currentRepeat = 0;
      _completedKeys += 1;
      notifyListeners();

      final pauseDone = await _waitMilliseconds(warmup.pauseBetweenKeysMs, token);
      if (!pauseDone) {
        continue;
      }

      final advanced = _advanceKey(
        range: range,
        pattern: warmup.melodyPattern,
      );
      if (!advanced) {
        _isPlaying = false;
        _statusLine = 'Warmup complete';
        notifyListeners();
        break;
      }
    }

    _stopAllActiveNotes();
    _loopRunning = false;
    notifyListeners();
  }

  Future<bool> _waitBeats(double beats, int token) async {
    var remaining = beats;
    var anchor = DateTime.now();
    while (remaining > 0) {
      if (token != _runToken) {
        return false;
      }
      if (!_isPlaying) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        anchor = DateTime.now();
        continue;
      }
      await Future<void>.delayed(const Duration(milliseconds: 35));
      final now = DateTime.now();
      final elapsedSeconds = now.difference(anchor).inMicroseconds / 1000000.0;
      anchor = now;
      remaining -= elapsedSeconds * (_tempoBpm / 60.0);
    }
    return token == _runToken;
  }

  Future<bool> _waitMilliseconds(int milliseconds, int token) async {
    var remaining = milliseconds;
    while (remaining > 0) {
      if (token != _runToken) {
        return false;
      }
      if (!_isPlaying) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        continue;
      }
      const tick = 40;
      await Future<void>.delayed(const Duration(milliseconds: tick));
      remaining -= tick;
    }
    return token == _runToken;
  }

  List<_RenderedStep> _renderStepsForCurrentKey({
    required Warmup warmup,
    required WarmupRangePreset range,
  }) {
    final pattern = warmup.melodyPattern;
    final rendered = <_RenderedStep>[];
    final previous = <_TextureRole, int>{};
    final majorOffsets = pattern.scaleDegrees.map(_degreeToSemitone).toList();

    for (var index = 0; index < pattern.scaleDegrees.length; index++) {
      final degree = pattern.scaleDegrees[index];
      final rhythm = pattern.rhythmPattern[index % pattern.rhythmPattern.length];
      final melody = _pickVoiceNote(
        tonicMidi: _currentTonicMidi,
        candidateDegrees: [degree],
        window: _windowForRole(_TextureRole.soprano, range),
        previousMidi: previous[_TextureRole.soprano],
        melodyMidi: null,
        previousMelodyMidi: null,
        avoidParallelFifths: false,
      );
      final notes = <_TextureRole, int>{_TextureRole.soprano: melody};
      final prevMelody = previous[_TextureRole.soprano];
      previous[_TextureRole.soprano] = melody;

      switch (_texture) {
        case WarmupTexture.unison:
          break;
        case WarmupTexture.twoPart:
          notes[_TextureRole.part2] = _pickVoiceNote(
            tonicMidi: _currentTonicMidi,
            candidateDegrees: [degree - 2, degree - 5],
            window: _windowForRole(_TextureRole.part2, range),
            previousMidi: previous[_TextureRole.part2],
            melodyMidi: melody,
            previousMelodyMidi: prevMelody,
            avoidParallelFifths: false,
          );
          previous[_TextureRole.part2] = notes[_TextureRole.part2]!;
          break;
        case WarmupTexture.sab:
          notes[_TextureRole.alto] = _pickVoiceNote(
            tonicMidi: _currentTonicMidi,
            candidateDegrees: [degree - 2, degree - 3],
            window: _windowForRole(_TextureRole.alto, range),
            previousMidi: previous[_TextureRole.alto],
            melodyMidi: melody,
            previousMelodyMidi: prevMelody,
            avoidParallelFifths: false,
          );
          notes[_TextureRole.bass] = _pickVoiceNote(
            tonicMidi: _currentTonicMidi,
            candidateDegrees: [1 - 7, 5 - 7, 1 - 14, 5 - 14],
            window: _windowForRole(_TextureRole.bass, range),
            previousMidi: previous[_TextureRole.bass],
            melodyMidi: melody,
            previousMelodyMidi: prevMelody,
            avoidParallelFifths: true,
          );
          previous[_TextureRole.alto] = notes[_TextureRole.alto]!;
          previous[_TextureRole.bass] = notes[_TextureRole.bass]!;
          break;
        case WarmupTexture.satb:
          notes[_TextureRole.alto] = _pickVoiceNote(
            tonicMidi: _currentTonicMidi,
            candidateDegrees: [degree - 2, degree - 3],
            window: _windowForRole(_TextureRole.alto, range),
            previousMidi: previous[_TextureRole.alto],
            melodyMidi: melody,
            previousMelodyMidi: prevMelody,
            avoidParallelFifths: false,
          );
          notes[_TextureRole.tenor] = _pickVoiceNote(
            tonicMidi: _currentTonicMidi,
            candidateDegrees: [degree - 4, degree - 5, degree - 2],
            window: _windowForRole(_TextureRole.tenor, range),
            previousMidi: previous[_TextureRole.tenor],
            melodyMidi: notes[_TextureRole.alto],
            previousMelodyMidi: previous[_TextureRole.alto],
            avoidParallelFifths: true,
          );
          notes[_TextureRole.bass] = _pickVoiceNote(
            tonicMidi: _currentTonicMidi,
            candidateDegrees: [1 - 7, 5 - 7, 1 - 14, 5 - 14],
            window: _windowForRole(_TextureRole.bass, range),
            previousMidi: previous[_TextureRole.bass],
            melodyMidi: melody,
            previousMelodyMidi: prevMelody,
            avoidParallelFifths: true,
          );
          previous[_TextureRole.alto] = notes[_TextureRole.alto]!;
          previous[_TextureRole.tenor] = notes[_TextureRole.tenor]!;
          previous[_TextureRole.bass] = notes[_TextureRole.bass]!;
          break;
      }

      if (_demoOn && warmup.demoConfig.supportsDemo) {
        notes[_TextureRole.demo] = _demoPitchFor(
          melody: melody,
          range: range,
          voice: _demoVoice,
        );
      }

      final totalBeats = rhythm <= 0 ? 0.5 : rhythm;
      final noteOnBeats = pattern.articulation == WarmupArticulation.staccato
          ? math.max(0.25, totalBeats * 0.55)
          : math.max(0.35, totalBeats * 0.9);

      rendered.add(
        _RenderedStep(
          index: index,
          notes: notes,
          totalBeats: totalBeats,
          noteOnBeats: noteOnBeats,
          melodyOffset: majorOffsets[index],
        ),
      );
    }
    return rendered;
  }

  void _playStep(_RenderedStep step) {
    if (!_soundfontReady || _soundfontId == null) {
      return;
    }
    for (final entry in step.notes.entries) {
      final role = entry.key;
      final midi = entry.value;
      final channel = _channelForRole(role);
      final velocity = _velocityForRole(role);
      final active = _ActiveNote(channel: channel, midi: midi);
      _activeNotes.add(active);
      unawaited(
        _midi.playNote(
          sfId: _soundfontId!,
          channel: channel,
          key: midi,
          velocity: velocity,
        ),
      );
    }
  }

  void _stopStep(_RenderedStep step) {
    if (!_soundfontReady || _soundfontId == null) {
      return;
    }
    for (final entry in step.notes.entries) {
      final role = entry.key;
      final midi = entry.value;
      final channel = _channelForRole(role);
      final active = _ActiveNote(channel: channel, midi: midi);
      _activeNotes.remove(active);
      unawaited(
        _midi.stopNote(
          sfId: _soundfontId!,
          channel: channel,
          key: midi,
        ),
      );
    }
  }

  bool _advanceKey({
    required WarmupRangePreset range,
    required WarmupMelodyPattern pattern,
  }) {
    final step = _stepMode.semitoneStep;
    final candidate = _transposeAscending
        ? _currentTonicMidi + step
        : _currentTonicMidi - step;
    if (_canRenderAtTonic(
      tonicMidi: candidate,
      pattern: pattern,
      range: range,
    )) {
      _currentTonicMidi = candidate;
      return true;
    }
    if (_transposeAscending) {
      _transposeAscending = false;
      final downward = _currentTonicMidi - step;
      if (_canRenderAtTonic(
        tonicMidi: downward,
        pattern: pattern,
        range: range,
      )) {
        _currentTonicMidi = downward;
        return true;
      }
    }
    return false;
  }

  bool _canRenderAtTonic({
    required int tonicMidi,
    required WarmupMelodyPattern pattern,
    required WarmupRangePreset range,
  }) {
    if (pattern.scaleDegrees.isEmpty) {
      return false;
    }
    var minMidi = 999;
    var maxMidi = -999;
    for (final degree in pattern.scaleDegrees) {
      final midi = tonicMidi + _degreeToSemitone(degree);
      if (midi < minMidi) {
        minMidi = midi;
      }
      if (midi > maxMidi) {
        maxMidi = midi;
      }
    }
    return minMidi >= range.lowestMidiNote && maxMidi <= range.highestMidiNote;
  }

  void _resetProgression({required bool resetRepeat}) {
    final warmup = _warmup;
    final range = selectedRangePreset;
    if (warmup == null || range == null) {
      _currentTonicMidi = 60;
      _transposeAscending = true;
      if (resetRepeat) {
        _currentRepeat = 0;
        _currentStep = 0;
        _completedKeys = 0;
      }
      return;
    }
    _currentTonicMidi = _startingTonic(
      pattern: warmup.melodyPattern,
      range: range,
    );
    _transposeAscending = true;
    if (resetRepeat) {
      _currentRepeat = 0;
      _currentStep = 0;
      _completedKeys = 0;
    }
  }

  int _startingTonic({
    required WarmupMelodyPattern pattern,
    required WarmupRangePreset range,
  }) {
    if (pattern.scaleDegrees.isEmpty) {
      return 60;
    }
    final offsets = pattern.scaleDegrees.map(_degreeToSemitone).toList();
    final minOffset = offsets.reduce(math.min);
    final maxOffset = offsets.reduce(math.max);
    var tonic = range.tessituraLow - minOffset;
    var melodyMin = tonic + minOffset;
    var melodyMax = tonic + maxOffset;

    while (melodyMax > range.tessituraHigh && tonic > range.lowestMidiNote - 24) {
      tonic -= 1;
      melodyMin = tonic + minOffset;
      melodyMax = tonic + maxOffset;
    }
    while (melodyMin < range.lowestMidiNote && tonic < range.highestMidiNote + 24) {
      tonic += 1;
      melodyMin = tonic + minOffset;
      melodyMax = tonic + maxOffset;
    }
    return tonic;
  }

  _RangeWindow _windowForRole(_TextureRole role, WarmupRangePreset range) {
    var low = range.tessituraLow;
    var high = range.tessituraHigh;
    switch (role) {
      case _TextureRole.soprano:
        low = range.tessituraLow;
        high = range.tessituraHigh;
        break;
      case _TextureRole.part2:
        low = range.lowestMidiNote + 4;
        high = range.tessituraHigh - 2;
        break;
      case _TextureRole.alto:
        low = range.tessituraLow - 5;
        high = range.tessituraHigh - 5;
        break;
      case _TextureRole.tenor:
        low = range.tessituraLow - 12;
        high = range.tessituraHigh - 10;
        break;
      case _TextureRole.bass:
        low = range.lowestMidiNote;
        high = range.tessituraLow - 8;
        break;
      case _TextureRole.demo:
        low = range.tessituraLow;
        high = range.tessituraHigh + 4;
        break;
    }

    if (low < range.lowestMidiNote) {
      low = range.lowestMidiNote;
    }
    if (high > range.highestMidiNote) {
      high = range.highestMidiNote;
    }
    if (low > high) {
      low = range.lowestMidiNote;
      high = range.highestMidiNote;
    }
    return _RangeWindow(low: low, high: high);
  }

  int _pickVoiceNote({
    required int tonicMidi,
    required List<int> candidateDegrees,
    required _RangeWindow window,
    required int? previousMidi,
    required int? melodyMidi,
    required int? previousMelodyMidi,
    required bool avoidParallelFifths,
  }) {
    final options = <int>[];
    for (final degree in candidateDegrees) {
      final base = tonicMidi + _degreeToSemitone(degree);
      for (var shift = -3; shift <= 3; shift++) {
        final note = base + shift * 12;
        if (note >= window.low && note <= window.high) {
          options.add(note);
        }
      }
    }
    if (options.isEmpty) {
      final fallback = tonicMidi + _degreeToSemitone(candidateDegrees.first);
      return _clampMidi(fallback, window.low, window.high);
    }

    final unique = options.toSet().toList()..sort();
    var best = unique.first;
    var bestScore = 1 << 30;
    final center = (window.low + window.high) / 2.0;

    for (final option in unique) {
      var score = 0;
      if (previousMidi != null) {
        final leap = (option - previousMidi).abs();
        score += leap * 3;
        if (leap > 9) {
          score += 35;
        }
      } else {
        score += ((option - center).abs() * 2).round();
      }
      if (melodyMidi != null && option >= melodyMidi) {
        score += 20;
      }
      if (avoidParallelFifths &&
          previousMidi != null &&
          melodyMidi != null &&
          previousMelodyMidi != null) {
        final nowInterval = (melodyMidi - option).abs() % 12;
        final prevInterval = (previousMelodyMidi - previousMidi).abs() % 12;
        final melodyMotion = melodyMidi - previousMelodyMidi;
        final voiceMotion = option - previousMidi;
        if (nowInterval == 7 &&
            prevInterval == 7 &&
            melodyMotion.sign == voiceMotion.sign &&
            melodyMotion != 0 &&
            voiceMotion != 0) {
          score += 50;
        }
      }
      if (score < bestScore) {
        bestScore = score;
        best = option;
      }
    }
    return best;
  }

  int _demoPitchFor({
    required int melody,
    required WarmupRangePreset range,
    required WarmupDemoVoice voice,
  }) {
    final window = _windowForRole(_TextureRole.demo, range);
    final raw = voice == WarmupDemoVoice.treble ? melody : melody - 12;
    return _clampMidi(raw, window.low, window.high);
  }

  int _channelForRole(_TextureRole role) {
    switch (role) {
      case _TextureRole.soprano:
        return 0;
      case _TextureRole.alto:
        return 1;
      case _TextureRole.part2:
        return 1;
      case _TextureRole.tenor:
        return 2;
      case _TextureRole.bass:
        return 3;
      case _TextureRole.demo:
        return _demoVoice == WarmupDemoVoice.treble ? 5 : 6;
    }
  }

  int _velocityForRole(_TextureRole role) {
    switch (role) {
      case _TextureRole.soprano:
        return 96;
      case _TextureRole.alto:
      case _TextureRole.part2:
        return 88;
      case _TextureRole.tenor:
        return 84;
      case _TextureRole.bass:
        return 82;
      case _TextureRole.demo:
        return 72;
    }
  }

  void _stopDemoNotes() {
    if (!_soundfontReady || _soundfontId == null) {
      return;
    }
    final demoChannels = {5, 6};
    final notes = _activeNotes.where((entry) => demoChannels.contains(entry.channel)).toList();
    for (final note in notes) {
      _activeNotes.remove(note);
      unawaited(
        _midi.stopNote(
          sfId: _soundfontId!,
          channel: note.channel,
          key: note.midi,
        ),
      );
    }
  }

  void _stopAllActiveNotes() {
    if (!_soundfontReady || _soundfontId == null) {
      _activeNotes.clear();
      return;
    }
    final notes = _activeNotes.toList();
    _activeNotes.clear();
    for (final note in notes) {
      unawaited(
        _midi.stopNote(
          sfId: _soundfontId!,
          channel: note.channel,
          key: note.midi,
        ),
      );
    }
  }
}

class _RenderedStep {
  const _RenderedStep({
    required this.index,
    required this.notes,
    required this.totalBeats,
    required this.noteOnBeats,
    required this.melodyOffset,
  });

  final int index;
  final Map<_TextureRole, int> notes;
  final double totalBeats;
  final double noteOnBeats;
  final int melodyOffset;
}

class _RangeWindow {
  const _RangeWindow({
    required this.low,
    required this.high,
  });

  final int low;
  final int high;
}

class _ActiveNote {
  const _ActiveNote({
    required this.channel,
    required this.midi,
  });

  final int channel;
  final int midi;

  @override
  bool operator ==(Object other) {
    return other is _ActiveNote && other.channel == channel && other.midi == midi;
  }

  @override
  int get hashCode => Object.hash(channel, midi);
}

enum _TextureRole {
  soprano,
  part2,
  alto,
  tenor,
  bass,
  demo,
}

int _clampMidi(int value, int low, int high) {
  return value.clamp(low, high).toInt();
}

int _degreeToSemitone(int degree) {
  const major = [0, 2, 4, 5, 7, 9, 11];
  final zeroBased = degree - 1;
  final octave = zeroBased >= 0
      ? zeroBased ~/ 7
      : -(((-zeroBased - 1) ~/ 7) + 1);
  final degreeIndex = ((zeroBased % 7) + 7) % 7;
  return major[degreeIndex] + octave * 12;
}

String _noteName(int midi) {
  const names = ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
  final note = names[midi % 12];
  final octave = (midi ~/ 12) - 1;
  return '$note$octave';
}

