import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';

import 'models.dart';

class PlaybackEngine extends ChangeNotifier {
  final MidiPro _midi = MidiPro();

  ParsedScore? _score;
  bool _isPlaying = false;
  double _tempoPercent = 100;
  double _currentBeat = 0;
  int? _loopA;
  int? _loopB;
  bool _soundfontReady = false;
  int? _soundfontId;
  String? _audioStatus;

  final Map<ChoirPart, double> _partGain = {
    for (final part in ChoirPart.values) part: 1.0,
  };

  Timer? _tickTimer;
  DateTime? _anchorTime;
  double _anchorBeat = 0;
  double _lastProcessedBeat = 0;
  List<PlaybackEvent> _events = const [];
  int _nextEventIndex = 0;
  final Map<_VoiceKey, int> _activeVoices = {};

  ParsedScore? get score => _score;
  bool get hasScore => _score != null;
  bool get isPlaying => _isPlaying;
  double get tempoPercent => _tempoPercent;
  double get currentBeat => _currentBeat;
  int? get loopA => _loopA;
  int? get loopB => _loopB;
  String? get audioStatus => _audioStatus;

  Set<ChoirPart> get enabledParts => _partGain.entries
      .where((entry) => entry.value > 0)
      .map((entry) => entry.key)
      .toSet();

  int get currentMeasure {
    final currentScore = _score;
    if (currentScore == null) {
      return 1;
    }
    return currentScore.measureAtBeat(_currentBeat);
  }

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
          ? 'Piano ready'
          : 'Failed to load bundled piano soundfont.';
    } catch (error) {
      _soundfontReady = false;
      _audioStatus =
          'Audio init failed. Ensure assets/choir/tight_piano.sf2 is bundled.';
    }
    notifyListeners();
  }

  void loadScore(ParsedScore parsedScore) {
    pause();
    _stopAllActiveNotes();
    _score = parsedScore;
    _events = _buildEvents(parsedScore.notes);
    _currentBeat = parsedScore.measureMap.first.startBeat;
    _lastProcessedBeat = _currentBeat;
    _nextEventIndex = lowerBoundEventBeat(_events, _currentBeat);
    _loopA = null;
    _loopB = null;
    for (final part in ChoirPart.values) {
      _partGain[part] = 1.0;
    }
    notifyListeners();
  }

  Future<void> play() async {
    if (_isPlaying || _score == null) {
      return;
    }
    if (!_soundfontReady) {
      await initializeAudio();
    }
    if (!_soundfontReady) {
      _audioStatus = 'Playback unavailable: soundfont not ready.';
      notifyListeners();
      return;
    }

    _anchorBeat = _currentBeat;
    _anchorTime = DateTime.now();
    _lastProcessedBeat = _currentBeat;
    _nextEventIndex = lowerBoundEventBeat(_events, _currentBeat);
    _isPlaying = true;
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(
      const Duration(milliseconds: 20),
      _onTick,
    );
    notifyListeners();
  }

  void pause() {
    if (!_isPlaying) {
      return;
    }
    _syncCurrentBeat();
    _isPlaying = false;
    _tickTimer?.cancel();
    _tickTimer = null;
    _stopAllActiveNotes();
    notifyListeners();
  }

  void togglePlayPause() {
    if (_isPlaying) {
      pause();
      return;
    }
    unawaited(play());
  }

  void jumpToMeasure(int requestedMeasure) {
    final currentScore = _score;
    if (currentScore == null) {
      return;
    }
    final measure = currentScore.clampToKnownMeasure(requestedMeasure);
    final beat = currentScore.beatForMeasure(measure);
    if (beat == null) {
      return;
    }
    _seekToBeat(beat);
  }

  void jumpByMeasures(int delta) {
    final currentScore = _score;
    if (currentScore == null || currentScore.measureNumbers.isEmpty) {
      return;
    }
    final measures = currentScore.measureNumbers;
    final current = currentMeasure;
    var currentIndex = measures.indexWhere((measure) => measure >= current);
    if (currentIndex == -1) {
      currentIndex = measures.length - 1;
    }
    final targetIndex = clampInt(
      currentIndex + delta,
      0,
      measures.length - 1,
    );
    jumpToMeasure(measures[targetIndex]);
  }

  void setTempoPercent(double percent) {
    final next = percent.clamp(50, 100).toDouble();
    if ((_tempoPercent - next).abs() < 1e-6) {
      return;
    }
    if (_isPlaying) {
      _syncCurrentBeat();
      _anchorBeat = _currentBeat;
      _anchorTime = DateTime.now();
    }
    _tempoPercent = next;
    notifyListeners();
  }

  void increaseTempo() => setTempoPercent(_tempoPercent + 5);

  void decreaseTempo() => setTempoPercent(_tempoPercent - 5);

  void setPartEnabled(ChoirPart part, bool enabled) {
    _partGain[part] = enabled ? 1.0 : 0.0;
    if (!enabled) {
      _stopNotesForPart(part);
    }
    notifyListeners();
  }

  void setAllPartsEnabled() {
    for (final part in ChoirPart.values) {
      _partGain[part] = 1.0;
    }
    notifyListeners();
  }

  void setEnabledParts(Set<ChoirPart> enabled) {
    for (final part in ChoirPart.values) {
      final shouldEnable = enabled.contains(part);
      _partGain[part] = shouldEnable ? 1.0 : 0.0;
      if (!shouldEnable) {
        _stopNotesForPart(part);
      }
    }
    notifyListeners();
  }

  void setLoopA(int requestedMeasure) {
    final currentScore = _score;
    if (currentScore == null) {
      return;
    }
    _loopA = currentScore.clampToKnownMeasure(requestedMeasure);
    if (_loopB != null && _loopA != null && _loopB! < _loopA!) {
      final previousA = _loopA;
      _loopA = _loopB;
      _loopB = previousA;
    }
    notifyListeners();
  }

  void setLoopB(int requestedMeasure) {
    final currentScore = _score;
    if (currentScore == null) {
      return;
    }
    _loopB = currentScore.clampToKnownMeasure(requestedMeasure);
    if (_loopA != null && _loopB != null && _loopB! < _loopA!) {
      final previousA = _loopA;
      _loopA = _loopB;
      _loopB = previousA;
    }
    notifyListeners();
  }

  void clearLoop() {
    _loopA = null;
    _loopB = null;
    notifyListeners();
  }

  Future<void> playStartingPitches({
    Set<ChoirPart>? preferredParts,
  }) async {
    final currentScore = _score;
    if (currentScore == null) {
      return;
    }
    if (!_soundfontReady) {
      await initializeAudio();
    }
    if (!_soundfontReady || _soundfontId == null) {
      return;
    }

    final parts = (preferredParts == null || preferredParts.isEmpty)
        ? enabledParts
        : preferredParts;
    if (parts.isEmpty) {
      return;
    }

    final firstNoteByPart = <ChoirPart, ScoreNote>{};
    for (final note in currentScore.notes) {
      if (!parts.contains(note.part)) {
        continue;
      }
      firstNoteByPart.putIfAbsent(note.part, () => note);
      if (firstNoteByPart.length == parts.length) {
        break;
      }
    }
    if (firstNoteByPart.isEmpty) {
      return;
    }

    final notes = firstNoteByPart.values.toList()
      ..sort((a, b) => a.part.index.compareTo(b.part.index));
    for (final note in notes) {
      unawaited(
        _midi.playNote(
          sfId: _soundfontId!,
          channel: note.part.midiChannel,
          key: note.midi,
          velocity: 100,
        ),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 950));
    for (final note in notes) {
      unawaited(
        _midi.stopNote(
          sfId: _soundfontId!,
          channel: note.part.midiChannel,
          key: note.midi,
        ),
      );
    }
  }

  Map<String, dynamic> snapshotState() {
    final currentScore = _score;
    return {
      'type': 'STATE',
      'loaded': currentScore != null,
      'isPlaying': _isPlaying,
      'tempoPercent': _tempoPercent,
      'currentMeasure': currentMeasure,
      'loopA': _loopA,
      'loopB': _loopB,
      'enabledParts': enabledParts.map((part) => part.id).toList(),
      'measures': currentScore?.measureNumbers ?? <int>[],
      'rehearsalMarks': currentScore?.rehearsalMarks ?? <String, int>{},
      'measureMap': currentScore?.measureMap.map((entry) => entry.toJson()).toList() ?? <Map<String, dynamic>>[],
      'audioStatus': _audioStatus,
    };
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _stopAllActiveNotes();
    unawaited(_midi.dispose());
    super.dispose();
  }

  void _seekToBeat(double beat) {
    final currentScore = _score;
    if (currentScore == null) {
      return;
    }
    final clamped = beat.clamp(0, currentScore.totalBeats).toDouble();
    _currentBeat = clamped;
    _lastProcessedBeat = clamped;
    _nextEventIndex = lowerBoundEventBeat(_events, clamped);
    _stopAllActiveNotes();
    if (_isPlaying) {
      _anchorBeat = clamped;
      _anchorTime = DateTime.now();
    }
    notifyListeners();
  }

  void _onTick(Timer _) {
    final currentScore = _score;
    final anchor = _anchorTime;
    if (!_isPlaying || currentScore == null || anchor == null) {
      return;
    }

    final now = DateTime.now();
    final elapsedSeconds = now.difference(anchor).inMicroseconds / 1000000.0;
    final projectedBeat = _anchorBeat + elapsedSeconds * (_effectiveBpm / 60.0);
    final loopRange = _currentLoopRange(currentScore);

    if (loopRange != null && projectedBeat >= loopRange.endBeat) {
      _processEventsUntil(loopRange.endBeat);
      _stopAllActiveNotes();
      _currentBeat = loopRange.startBeat;
      _lastProcessedBeat = _currentBeat;
      _nextEventIndex = lowerBoundEventBeat(_events, _currentBeat);
      _anchorBeat = _currentBeat;
      _anchorTime = now;
      notifyListeners();
      return;
    }

    final nextBeat = math.min(projectedBeat, currentScore.totalBeats);
    _processEventsUntil(nextBeat);
    _currentBeat = nextBeat;

    if ((_currentBeat - currentScore.totalBeats).abs() < 1e-6 ||
        _currentBeat >= currentScore.totalBeats) {
      _isPlaying = false;
      _tickTimer?.cancel();
      _tickTimer = null;
      _stopAllActiveNotes();
    }

    notifyListeners();
  }

  void _syncCurrentBeat() {
    final currentScore = _score;
    final anchor = _anchorTime;
    if (!_isPlaying || currentScore == null || anchor == null) {
      return;
    }
    final elapsedSeconds = DateTime.now().difference(anchor).inMicroseconds / 1000000.0;
    _currentBeat = math.min(
      currentScore.totalBeats,
      _anchorBeat + elapsedSeconds * (_effectiveBpm / 60.0),
    );
    _lastProcessedBeat = _currentBeat;
    _nextEventIndex = lowerBoundEventBeat(_events, _currentBeat);
  }

  double get _effectiveBpm {
    final currentScore = _score;
    final base = currentScore?.baseBpm ?? 96.0;
    return base * (_tempoPercent / 100.0);
  }

  void _processEventsUntil(double beat) {
    while (_nextEventIndex < _events.length && _events[_nextEventIndex].beat <= beat + 1e-7) {
      final event = _events[_nextEventIndex];
      _nextEventIndex += 1;
      if (event.beat + 1e-7 < _lastProcessedBeat) {
        continue;
      }
      if (event.isNoteOn) {
        _handleNoteOn(event.note);
      } else {
        _handleNoteOff(event.note);
      }
    }
    _lastProcessedBeat = beat;
  }

  void _handleNoteOn(ScoreNote note) {
    if (!_soundfontReady || _soundfontId == null) {
      return;
    }
    final gain = _partGain[note.part] ?? 0;
    if (gain <= 0) {
      return;
    }
    final velocity = clampInt((100 * gain).round(), 1, 127);
    final key = _VoiceKey(part: note.part, midi: note.midi);
    _activeVoices[key] = (_activeVoices[key] ?? 0) + 1;
    unawaited(
      _midi.playNote(
        sfId: _soundfontId!,
        channel: note.part.midiChannel,
        key: note.midi,
        velocity: velocity,
      ),
    );
  }

  void _handleNoteOff(ScoreNote note) {
    if (!_soundfontReady || _soundfontId == null) {
      return;
    }
    final key = _VoiceKey(part: note.part, midi: note.midi);
    final activeCount = _activeVoices[key] ?? 0;
    if (activeCount <= 1) {
      _activeVoices.remove(key);
    } else {
      _activeVoices[key] = activeCount - 1;
    }
    unawaited(
      _midi.stopNote(
        sfId: _soundfontId!,
        channel: note.part.midiChannel,
        key: note.midi,
      ),
    );
  }

  void _stopAllActiveNotes() {
    if (!_soundfontReady || _soundfontId == null || _activeVoices.isEmpty) {
      _activeVoices.clear();
      return;
    }
    final keys = _activeVoices.keys.toList();
    _activeVoices.clear();
    for (final key in keys) {
      unawaited(
        _midi.stopNote(
          sfId: _soundfontId!,
          channel: key.part.midiChannel,
          key: key.midi,
        ),
      );
    }
  }

  void _stopNotesForPart(ChoirPart part) {
    if (!_soundfontReady || _soundfontId == null || _activeVoices.isEmpty) {
      return;
    }
    final keys = _activeVoices.keys.where((key) => key.part == part).toList();
    for (final key in keys) {
      _activeVoices.remove(key);
      unawaited(
        _midi.stopNote(
          sfId: _soundfontId!,
          channel: key.part.midiChannel,
          key: key.midi,
        ),
      );
    }
  }

  List<PlaybackEvent> _buildEvents(List<ScoreNote> notes) {
    final events = <PlaybackEvent>[];
    for (final note in notes) {
      events.add(
        PlaybackEvent(
          beat: note.startBeat,
          note: note,
          isNoteOn: true,
        ),
      );
      events.add(
        PlaybackEvent(
          beat: note.startBeat + math.max(0.05, note.durationBeats),
          note: note,
          isNoteOn: false,
        ),
      );
    }
    events.sort((a, b) {
      final beatCompare = a.beat.compareTo(b.beat);
      if (beatCompare != 0) {
        return beatCompare;
      }
      if (a.isNoteOn == b.isNoteOn) {
        return 0;
      }
      return a.isNoteOn ? 1 : -1;
    });
    return events;
  }

  _LoopRange? _currentLoopRange(ParsedScore currentScore) {
    if (_loopA == null || _loopB == null) {
      return null;
    }
    final start = currentScore.beatForMeasure(_loopA!);
    final end = currentScore.endBeatForMeasure(_loopB!);
    if (start == null || end <= start + 1e-6) {
      return null;
    }
    return _LoopRange(startBeat: start, endBeat: end);
  }
}

class _LoopRange {
  _LoopRange({required this.startBeat, required this.endBeat});

  final double startBeat;
  final double endBeat;
}

class _VoiceKey {
  _VoiceKey({required this.part, required this.midi});

  final ChoirPart part;
  final int midi;

  @override
  bool operator ==(Object other) {
    return other is _VoiceKey && other.part == part && other.midi == midi;
  }

  @override
  int get hashCode => Object.hash(part, midi);
}

