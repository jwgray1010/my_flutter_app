import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'class_session_models.dart';
import 'models.dart';
import 'musicxml_parser.dart';
import 'networking.dart';
import 'playback_controller.dart';
import 'playback_engine.dart';

class CommandExecutionResult {
  const CommandExecutionResult({
    required this.applied,
    required this.message,
    this.suggestion,
  });

  final bool applied;
  final String message;
  final String? suggestion;
}

class RehearsalController extends ChangeNotifier {
  RehearsalController({
    MusicXmlParser? parser,
    PlaybackEngine? playback,
    LocalPlayerServer? server,
  }) : _parser = parser ?? MusicXmlParser(),
       _playback = playback ?? PlaybackEngine(),
       _server = server ?? LocalPlayerServer() {
    _playbackController = PlaybackController(
      playback: _playback,
      onChanged: _broadcastStateAndNotify,
    );
  }

  final MusicXmlParser _parser;
  final PlaybackEngine _playback;
  final LocalPlayerServer _server;
  late final PlaybackController _playbackController;

  bool _initialized = false;
  String? _loadedFileName;
  String _loadedPieceId = 'no_piece';
  String? _errorMessage;
  ClassSessionState? _classSession;
  final Map<String, String> _clientIdToDeviceId = <String, String>{};

  bool get initialized => _initialized;
  PlaybackEngine get playback => _playback;
  PlaybackController get playbackController => _playbackController;
  String? get loadedFileName => _loadedFileName;
  String get loadedPieceId => _loadedPieceId;
  String? get errorMessage => _errorMessage;
  ClassSessionState? get classSession => _classSession;
  bool get hasActiveClassSession => _classSession != null;
  int get serverPort => _server.port;
  int get announcePort => _server.announcePort;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _playback.addListener(_handlePlaybackUpdate);
    await _playback.initializeAudio();
    await _server.start(
      onCommand: (command) async {
        await applyCommand(command);
      },
      stateBuilder: _buildRemoteState,
      playerNameBuilder: _playerDisplayName,
      onClientConnectionChanged: _handleClientConnectionChanged,
    );
    _server.broadcastState();
    _initialized = true;
    notifyListeners();
  }

  Future<Map<String, dynamic>> pairingPayload() async {
    if (!_initialized) {
      await initialize();
    }
    return _server.buildPairingPayload();
  }

  Future<Map<String, dynamic>> classSessionPairingPayload() async {
    final active = _classSession;
    if (active == null) {
      throw StateError('No active class session');
    }
    return _server.buildPairingPayload(
      overrideToken: active.pairingToken,
      extra: <String, dynamic>{
        'mode': 'class_session',
        'sessionId': active.sessionId,
      },
    );
  }

  Future<void> startClassSession({
    String? className,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    final token = _newToken();
    final session = ClassSessionState(
      sessionId: _newId('session'),
      className: (className ?? '').trim(),
      pieceId: _loadedPieceId,
      createdAt: DateTime.now(),
      pairingToken: token,
      practiceSessions: <PracticeSessionPreset>[],
      rosterByDeviceId: <String, StudentPracticeRecord>{},
      loopRangeCounts: <String, int>{},
      measureVisitCounts: <int, int>{},
      eventLogs: <Map<String, dynamic>>[],
    );
    _classSession = session;
    _clientIdToDeviceId.clear();
    _server.setClassSessionToken(token);
    await _persistCurrentClassSession();
    _broadcastStateAndNotify();
  }

  Future<void> addPracticeSessionPreset({
    required String title,
    required int startMeasure,
    required int endMeasure,
    required int tempoPercent,
    required bool loopEnabled,
    required Set<ChoirPart> allowedParts,
    required bool pianoDefaultOn,
    required bool autoPlayOnStart,
  }) async {
    final active = _classSession;
    if (active == null) {
      return;
    }
    active.practiceSessions.add(
      PracticeSessionPreset(
        id: _newId('practice'),
        title: title.trim().isEmpty ? 'Practice ${active.practiceSessions.length + 1}' : title.trim(),
        startMeasure: startMeasure,
        endMeasure: endMeasure,
        loopEnabled: loopEnabled,
        tempoPercent: tempoPercent,
        allowedParts: allowedParts,
        pianoDefaultOn: pianoDefaultOn,
        autoPlayOnStart: autoPlayOnStart,
      ),
    );
    await _persistCurrentClassSession();
    _broadcastStateAndNotify();
  }

  Future<void> clearClassSession() async {
    _classSession = null;
    _clientIdToDeviceId.clear();
    _server.setClassSessionToken(null);
    _broadcastStateAndNotify();
  }

  String buildClassSessionCsv() {
    final active = _classSession;
    if (active == null) {
      return '';
    }
    final lines = <String>[
      'student_name,part,minutes_practiced,sessions_completed,last_activity',
    ];
    for (final row in active.rosterByDeviceId.values) {
      final safeName = row.studentName.replaceAll(',', ' ');
      final safePart = row.partId.replaceAll(',', ' ');
      final minutes = (row.totalPracticeSeconds / 60).toStringAsFixed(1);
      lines.add(
        '$safeName,$safePart,$minutes,${row.sessionsCompleted},${row.lastActivityAt.toIso8601String()}',
      );
    }
    return lines.join('\n');
  }

  Future<void> loadMusicXmlFromPicker() async {
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['musicxml', 'xml', 'mxl'],
      );
      if (result == null || result.files.isEmpty) {
        return;
      }
      final file = result.files.single;
      final extension = (file.extension ?? '').toLowerCase();
      if (extension == 'mxl') {
        _errorMessage = '.mxl compressed scores are not supported in this MVP.';
        notifyListeners();
        return;
      }
      final xmlContent = await _readSelectedFileAsText(file);
      final score = _parser.parse(xmlContent);
      _playback.loadScore(score);
      _playbackController.resetLoopArmed();
      _loadedFileName = file.name;
      _loadedPieceId = _buildPieceId(xmlContent);
      _errorMessage = null;
      _broadcastStateAndNotify();
    } catch (error) {
      _errorMessage = 'Failed to load MusicXML: $error';
      notifyListeners();
    }
  }

  Future<void> play() async {
    await _playbackController.play();
  }

  void pause() {
    _playbackController.pause();
  }

  void togglePlayPause() {
    if (_playback.isPlaying) {
      _playbackController.pause();
      return;
    }
    unawaited(_playbackController.play());
  }

  void jumpToMeasure(int measure) {
    unawaited(_playbackController.jumpToMeasure(measure));
  }

  void jumpByMeasures(int delta) {
    _playbackController.jumpRelative(delta);
  }

  void setTempoPercent(double percent) {
    _playbackController.setTempoPercent(percent.round());
  }

  void increaseTempo() {
    _playbackController.adjustTempoPercent(5);
  }

  void decreaseTempo() {
    _playbackController.adjustTempoPercent(-5);
  }

  void setPartEnabled(ChoirPart part, bool enabled) {
    final updated = _playback.enabledParts.toSet();
    if (enabled) {
      updated.add(part);
    } else {
      updated.remove(part);
    }
    _playbackController.setPartsEnabled(updated);
  }

  void enableAllParts() {
    _playbackController.setPreset(MixPreset.all);
  }

  void setEnabledParts(Set<ChoirPart> enabled) {
    _playbackController.setPartsEnabled(enabled);
  }

  void setLoopAAtCurrentMeasure() {
    _playbackController.setLoopA(measure: _playback.currentMeasure);
  }

  void setLoopBAtCurrentMeasure() {
    _playbackController.setLoopB(measure: _playback.currentMeasure);
  }

  void clearLoop() {
    _playbackController.clearLoop();
  }

  Future<void> playStartingPitches({
    Set<ChoirPart>? preferredParts,
  }) async {
    // MVP: preferred parts can still be provided through set parts before call.
    if (preferredParts != null) {
      _playbackController.setPartsEnabled(preferredParts, pianoOn: true);
    }
    await _playbackController.playStartingPitches();
  }

  bool jumpToRehearsalMark(String rawMark) {
    final score = _playback.score;
    if (score == null) {
      return false;
    }
    final normalized = rawMark.trim().toUpperCase();
    final measure = score.rehearsalMarks[normalized];
    if (measure == null) {
      return false;
    }
    unawaited(_playbackController.jumpToMeasure(measure));
    return true;
  }

  @override
  void dispose() {
    _playback.removeListener(_handlePlaybackUpdate);
    unawaited(_server.stop());
    _playback.dispose();
    super.dispose();
  }

  Future<String> _readSelectedFileAsText(PlatformFile file) async {
    if (file.bytes != null) {
      return utf8.decode(file.bytes!, allowMalformed: true);
    }
    if (file.path != null) {
      return File(file.path!).readAsString();
    }
    throw const FormatException('Selected file has no readable content.');
  }

  void _handlePlaybackUpdate() {
    _broadcastStateAndNotify();
  }

  Future<CommandExecutionResult> applyCommand(Map<String, dynamic> command) async {
    final type = (command['type'] as String?) ?? '';
    switch (type) {
      case 'PLAY':
        await _playbackController.play();
        return const CommandExecutionResult(applied: true, message: 'Play');
      case 'PAUSE':
        _playbackController.pause();
        return const CommandExecutionResult(applied: true, message: 'Pause');
      case 'TOGGLE_PLAY':
        if (_playback.isPlaying) {
          _playbackController.pause();
          return const CommandExecutionResult(applied: true, message: 'Pause');
        }
        await _playbackController.play();
        return const CommandExecutionResult(applied: true, message: 'Play');
      case 'JUMP_TO_MEASURE':
        final measure = _readInt(command['measure']);
        if (measure != null) {
          final jumpResult = await _playbackController.jumpToMeasure(
            measure,
            autoPlay: command['autoPlay'] == true,
          );
          if (jumpResult.wasClamped) {
            return CommandExecutionResult(
              applied: true,
              message: 'Clamped to m.${jumpResult.resolved}',
            );
          }
          return CommandExecutionResult(
            applied: true,
            message: 'Jump to measure ${jumpResult.resolved}',
          );
        }
        return const CommandExecutionResult(
          applied: false,
          message: "Didn't catch that.",
          suggestion: "Try: 'measure 32'.",
        );
      case 'JUMP_RELATIVE':
        final delta = _readInt(command['deltaMeasures']);
        if (delta != null) {
          _playbackController.jumpRelative(delta);
          return CommandExecutionResult(
            applied: true,
            message: delta < 0 ? 'Back ${delta.abs()}' : 'Forward $delta',
          );
        }
        return const CommandExecutionResult(
          applied: false,
          message: "Didn't catch that.",
          suggestion: "Try: 'back two measures'.",
        );
      case 'SET_TEMPO':
        final percent = _readDouble(command['percent']);
        if (percent != null) {
          _playbackController.setTempoPercent(percent.round());
          return CommandExecutionResult(
            applied: true,
            message: 'Tempo ${percent.round()}%',
          );
        }
        return const CommandExecutionResult(
          applied: false,
          message: "Didn't catch that.",
          suggestion: "Try: 'tempo 70'.",
        );
      case 'SET_TEMPO_ADJUST':
        final delta = _readInt(command['delta']);
        if (delta != null) {
          _playbackController.adjustTempoPercent(delta);
          return CommandExecutionResult(
            applied: true,
            message: delta < 0 ? 'Tempo slower' : 'Tempo faster',
          );
        }
        return const CommandExecutionResult(
          applied: false,
          message: "Didn't catch that.",
          suggestion: "Try: 'slower' or 'faster'.",
        );
      case 'SET_PART_ENABLED':
        final partName = command['part'] as String?;
        final enabled = command['enabled'];
        final part = partName == null ? null : choirPartFromId(partName);
        if (part != null && enabled is bool) {
          final current = _playback.enabledParts.toSet();
          if (enabled) {
            current.add(part);
          } else {
            current.remove(part);
          }
          _playbackController.setPartsEnabled(current);
          return CommandExecutionResult(
            applied: true,
            message: '${part.shortLabel} ${enabled ? 'on' : 'off'}',
          );
        }
        return const CommandExecutionResult(
          applied: false,
          message: "Didn't catch that.",
        );
      case 'SET_PARTS_EXACT':
        final rawParts = command['parts'];
        if (rawParts is List) {
          final enabled = <ChoirPart>{};
          for (final raw in rawParts) {
            final parsed = choirPartFromId(raw.toString());
            if (parsed != null) {
              enabled.add(parsed);
            }
          }
          _playbackController.setPartsEnabled(enabled);
          return CommandExecutionResult(
            applied: true,
            message: 'Parts updated',
          );
        }
        return const CommandExecutionResult(
          applied: false,
          message: "Didn't catch that.",
        );
      case 'SET_PARTS_ENABLED':
        final rawParts = command['partsEnabledSet'];
        final pianoEnabled = command['pianoEnabled'] as bool?;
        final enabled = <ChoirPart>{};
        if (rawParts is List) {
          for (final raw in rawParts) {
            final parsed = _partFromProtocol(raw.toString());
            if (parsed != null) {
              enabled.add(parsed);
            }
          }
        }
        if (pianoEnabled == null && _playback.enabledParts.contains(ChoirPart.piano)) {
          enabled.add(ChoirPart.piano);
        }
        _playbackController.setPartsEnabled(enabled, pianoOn: pianoEnabled);
        return const CommandExecutionResult(
          applied: true,
          message: 'Parts updated',
        );
      case 'SET_MIX_PRESET':
        final presetRaw = ((command['preset'] as String?) ?? '').toLowerCase();
        switch (presetRaw) {
          case 'all':
            _playbackController.setPreset(MixPreset.all);
            return const CommandExecutionResult(
              applied: true,
              message: 'All parts on',
            );
          case 'exact':
            final rawParts = command['parts'];
            final pianoOn = command['pianoOn'] as bool?;
            final enabled = <ChoirPart>{};
            if (rawParts is List) {
              for (final raw in rawParts) {
                final parsed = choirPartFromId(raw.toString());
                if (parsed != null) {
                  enabled.add(parsed);
                }
              }
            }
            _playbackController.setPreset(
              MixPreset.exactParts,
              exactParts: enabled,
              pianoOn: pianoOn,
            );
            return const CommandExecutionResult(
              applied: true,
              message: 'Parts updated',
            );
          case 'target':
            final target = choirPartFromId((command['target'] as String?) ?? '');
            if (target != null) {
              _playbackController.setPreset(
                MixPreset.isolateTarget,
                target: target,
                pianoOn: command['pianoOn'] as bool?,
              );
              return CommandExecutionResult(
                applied: true,
                message: 'Isolate ${target.shortLabel}',
              );
            }
            return const CommandExecutionResult(
              applied: false,
              message: "Didn't catch that.",
            );
          default:
            return const CommandExecutionResult(
              applied: false,
              message: "Didn't catch that.",
            );
        }
      case 'SET_ALL_PARTS':
        _playbackController.setPreset(MixPreset.all);
        return const CommandExecutionResult(applied: true, message: 'All parts on');
      case 'SET_LOOP_A':
        final measure = _readInt(command['measure']);
        if (measure != null) {
          _playbackController.setLoopA(measure: measure);
          return CommandExecutionResult(
            applied: true,
            message: 'Set loop A at $measure',
          );
        }
        return const CommandExecutionResult(applied: false, message: "Didn't catch that.");
      case 'SET_LOOP_B':
        final measure = _readInt(command['measure']);
        if (measure != null) {
          _playbackController.setLoopB(measure: measure);
          return CommandExecutionResult(
            applied: true,
            message: 'Set loop B at $measure',
          );
        }
        return const CommandExecutionResult(applied: false, message: "Didn't catch that.");
      case 'SET_LOOP_RANGE':
        final a = _readInt(command['a']);
        final b = _readInt(command['b']);
        if (a != null && b != null) {
          _playbackController.setLoopRange(a: a, b: b);
          return CommandExecutionResult(
            applied: true,
            message: 'Loop measures ${a <= b ? a : b} to ${a <= b ? b : a}',
          );
        }
        return const CommandExecutionResult(applied: false, message: "Didn't catch that.");
      case 'LOOP_ARM_TOGGLE':
        if (_playback.loopA == null && _playback.loopB == null) {
          _playbackController.toggleLoopArmed();
          return CommandExecutionResult(
            applied: true,
            message: _playbackController.loopArmed ? 'Loop armed' : 'Loop disarmed',
          );
        }
        return const CommandExecutionResult(
          applied: true,
          message: 'Loop points already set',
        );
      case 'CLEAR_LOOP':
        _playbackController.clearLoop();
        return const CommandExecutionResult(applied: true, message: 'Clear loop');
      case 'PLAY_STARTING_PITCHES':
        await _playbackController.playStartingPitches();
        return const CommandExecutionResult(
          applied: true,
          message: 'Play starting pitches',
        );
      case 'JOIN_CLASS_SESSION':
        return _handleJoinClassSession(command);
      case 'START_PRACTICE_SESSION':
        return _handleStartPracticeSession(command);
      case 'PRACTICE_EVENT':
        return _handlePracticeEvent(command);
      case 'PRACTICE_SUMMARY':
        return _handlePracticeSummary(command);
      default:
        return const CommandExecutionResult(
          applied: false,
          message: "Didn't catch that.",
        );
    }
  }

  int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  double? _readDouble(Object? value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  void _broadcastStateAndNotify() {
    _server.broadcastState();
    notifyListeners();
  }

  String _playerDisplayName() {
    return 'ChoirPlayer-iPad';
  }

  Map<String, dynamic> _buildRemoteState() {
    final score = _playback.score;
    final loopEnabled = _playback.loopA != null && _playback.loopB != null;
    return <String, dynamic>{
      'pieceName': _loadedFileName ?? 'Untitled',
      'isPlaying': _playback.isPlaying,
      'currentMeasure': _playback.currentMeasure,
      'tempoPercent': _playback.tempoPercent.round(),
      'loop': <String, dynamic>{
        'enabled': loopEnabled,
        'a': _playback.loopA,
        'b': _playback.loopB,
        'armed': _playbackController.loopArmed,
      },
      'loopArmed': _playbackController.loopArmed,
      'partsEnabled': _playback.enabledParts.map(_partToProtocol).toList(),
      'measures': score?.measureNumbers ?? <int>[],
      'rehearsalMarks': score?.rehearsalMarks ?? <String, int>{},
      'activeClassSession': _classSession?.toRemoteMap(),
    };
  }

  String _partToProtocol(ChoirPart part) {
    switch (part) {
      case ChoirPart.soprano:
        return 'SOP';
      case ChoirPart.alto:
        return 'ALTO';
      case ChoirPart.tenor:
        return 'TENOR';
      case ChoirPart.bass:
        return 'BASS';
      case ChoirPart.piano:
        return 'PIANO';
    }
  }

  ChoirPart? _partFromProtocol(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'SOP':
      case 'SOPRANO':
        return ChoirPart.soprano;
      case 'ALTO':
        return ChoirPart.alto;
      case 'TENOR':
        return ChoirPart.tenor;
      case 'BASS':
        return ChoirPart.bass;
      case 'PIANO':
        return ChoirPart.piano;
      default:
        return choirPartFromId(raw);
    }
  }

  CommandExecutionResult _handleJoinClassSession(Map<String, dynamic> command) {
    final active = _classSession;
    if (active == null) {
      return const CommandExecutionResult(
        applied: false,
        message: 'No active class session',
      );
    }
    final sessionId = command['sessionId']?.toString() ?? '';
    if (sessionId != active.sessionId) {
      return const CommandExecutionResult(
        applied: false,
        message: 'Session mismatch',
      );
    }
    final studentName = command['studentName']?.toString().trim() ?? '';
    final part = command['part']?.toString().toUpperCase() ?? '';
    final deviceId = command['deviceId']?.toString() ?? '';
    if (studentName.isEmpty || deviceId.isEmpty) {
      return const CommandExecutionResult(
        applied: false,
        message: 'Missing student identity',
      );
    }
    final clientId = command['_clientId']?.toString();
    if (clientId != null && clientId.isNotEmpty) {
      _clientIdToDeviceId[clientId] = deviceId;
    }
    final existing = active.rosterByDeviceId[deviceId];
    final now = DateTime.now();
    if (existing == null) {
      active.rosterByDeviceId[deviceId] = StudentPracticeRecord(
        studentName: studentName,
        partId: part,
        deviceId: deviceId,
        connected: true,
        status: 'connected',
        currentMeasure: 1,
        currentTempo: 100,
        currentSessionTitle: null,
        sessionsCompleted: 0,
        totalPracticeSeconds: 0,
        lastActivityAt: now,
        completedSessionIds: <String>{},
      );
    } else {
      existing.connected = true;
      existing.status = 'connected';
      existing.lastActivityAt = now;
    }
    _logClassEvent(<String, dynamic>{
      'type': 'JOIN_CLASS_SESSION',
      'studentName': studentName,
      'part': part,
      'deviceId': deviceId,
      'at': now.toIso8601String(),
    });
    unawaited(_persistCurrentClassSession());
    return const CommandExecutionResult(applied: true, message: 'Joined class session');
  }

  CommandExecutionResult _handleStartPracticeSession(Map<String, dynamic> command) {
    final active = _classSession;
    if (active == null) {
      return const CommandExecutionResult(applied: false, message: 'No active class session');
    }
    final sessionId = command['sessionId']?.toString() ?? '';
    if (sessionId != active.sessionId) {
      return const CommandExecutionResult(applied: false, message: 'Session mismatch');
    }
    final practiceSessionId = command['practiceSessionId']?.toString() ?? '';
    final deviceId = command['deviceId']?.toString() ?? '';
    final student = active.rosterByDeviceId[deviceId];
    if (practiceSessionId.isEmpty || student == null) {
      return const CommandExecutionResult(applied: false, message: 'Unknown student/session');
    }
    PracticeSessionPreset? practice;
    for (final entry in active.practiceSessions) {
      if (entry.id == practiceSessionId) {
        practice = entry;
        break;
      }
    }
    if (practice == null) {
      return const CommandExecutionResult(applied: false, message: 'Practice not found');
    }
    student.status = 'practicing';
    student.currentSessionTitle = practice.title;
    student.currentMeasure = practice.minMeasure;
    student.currentTempo = practice.tempoPercent;
    student.lastActivityAt = DateTime.now();

    _logClassEvent(<String, dynamic>{
      'type': 'START_PRACTICE_SESSION',
      'deviceId': deviceId,
      'practiceSessionId': practiceSessionId,
      'title': practice.title,
      'at': DateTime.now().toIso8601String(),
    });
    unawaited(_persistCurrentClassSession());
    return const CommandExecutionResult(applied: true, message: 'Practice started');
  }

  CommandExecutionResult _handlePracticeEvent(Map<String, dynamic> command) {
    final active = _classSession;
    if (active == null) {
      return const CommandExecutionResult(applied: false, message: 'No active class session');
    }
    final deviceId = command['deviceId']?.toString() ?? '';
    final eventType = command['event']?.toString().toUpperCase() ?? '';
    if (deviceId.isEmpty || eventType.isEmpty) {
      return const CommandExecutionResult(applied: false, message: 'Malformed practice event');
    }
    final student = active.rosterByDeviceId[deviceId];
    if (student == null) {
      return const CommandExecutionResult(applied: false, message: 'Unknown student');
    }

    final now = DateTime.now();
    student.lastActivityAt = now;
    if (eventType == 'PLAY') {
      student.status = 'practicing';
    } else if (eventType == 'PAUSE') {
      student.status = 'idle';
    }

    final currentMeasure = _readInt(command['currentMeasure']);
    if (currentMeasure != null) {
      student.currentMeasure = currentMeasure;
      active.measureVisitCounts[currentMeasure] =
          (active.measureVisitCounts[currentMeasure] ?? 0) + 1;
    }
    final currentTempo = _readInt(command['tempoPercent']);
    if (currentTempo != null) {
      student.currentTempo = currentTempo;
    }
    final deltaSeconds = _readInt(command['deltaSeconds']);
    if (deltaSeconds != null && deltaSeconds > 0) {
      student.totalPracticeSeconds += deltaSeconds;
    }
    final loopRange = command['loopRange']?.toString();
    if (loopRange != null && loopRange.isNotEmpty) {
      active.loopRangeCounts[loopRange] = (active.loopRangeCounts[loopRange] ?? 0) + 1;
    }
    final completed = command['completed'] == true;
    final completedSessionId = command['practiceSessionId']?.toString();
    if (completed && completedSessionId != null && completedSessionId.isNotEmpty) {
      if (student.completedSessionIds.add(completedSessionId)) {
        student.sessionsCompleted += 1;
      }
    }

    _logClassEvent(<String, dynamic>{
      'type': 'PRACTICE_EVENT',
      'deviceId': deviceId,
      'event': eventType,
      'currentMeasure': student.currentMeasure,
      'tempoPercent': student.currentTempo,
      'completed': completed,
      'practiceSessionId': completedSessionId,
      'at': now.toIso8601String(),
    });
    unawaited(_persistCurrentClassSession());
    return const CommandExecutionResult(applied: true, message: 'Practice event recorded');
  }

  CommandExecutionResult _handlePracticeSummary(Map<String, dynamic> command) {
    final active = _classSession;
    if (active == null) {
      return const CommandExecutionResult(applied: false, message: 'No active class session');
    }
    final deviceId = command['deviceId']?.toString() ?? '';
    final student = active.rosterByDeviceId[deviceId];
    if (deviceId.isEmpty || student == null) {
      return const CommandExecutionResult(applied: false, message: 'Unknown student');
    }
    final seconds = _readInt(command['timeOnTaskSeconds']);
    if (seconds != null && seconds > student.totalPracticeSeconds) {
      student.totalPracticeSeconds = seconds;
    }
    final completedRaw = command['completedSessions'];
    if (completedRaw is List) {
      for (final id in completedRaw) {
        student.completedSessionIds.add(id.toString());
      }
      student.sessionsCompleted = student.completedSessionIds.length;
    }
    final measuresRaw = command['measuresVisited'];
    if (measuresRaw is List) {
      for (final measure in measuresRaw) {
        final parsed = _readInt(measure);
        if (parsed != null) {
          active.measureVisitCounts[parsed] = (active.measureVisitCounts[parsed] ?? 0) + 1;
        }
      }
    }
    student.lastActivityAt = DateTime.now();
    _logClassEvent(<String, dynamic>{
      'type': 'PRACTICE_SUMMARY',
      'deviceId': deviceId,
      'timeOnTaskSeconds': student.totalPracticeSeconds,
      'sessionsCompleted': student.sessionsCompleted,
      'at': DateTime.now().toIso8601String(),
    });
    unawaited(_persistCurrentClassSession());
    return const CommandExecutionResult(applied: true, message: 'Summary recorded');
  }

  Future<void> _persistCurrentClassSession() async {
    final active = _classSession;
    if (active == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'choir_class_session_${active.sessionId}',
      jsonEncode(active.toMap()),
    );
  }

  void _logClassEvent(Map<String, dynamic> event) {
    final active = _classSession;
    if (active == null) {
      return;
    }
    active.eventLogs.add(event);
    if (active.eventLogs.length > 3000) {
      active.eventLogs.removeRange(0, active.eventLogs.length - 3000);
    }
  }

  void _handleClientConnectionChanged(String clientId, bool connected) {
    final active = _classSession;
    if (active == null) {
      return;
    }
    final deviceId = _clientIdToDeviceId[clientId];
    if (deviceId == null) {
      return;
    }
    final student = active.rosterByDeviceId[deviceId];
    if (student == null) {
      return;
    }
    student.connected = connected;
    student.status = connected ? student.status : 'idle';
    student.lastActivityAt = DateTime.now();
    _broadcastStateAndNotify();
  }

  String _buildPieceId(String xmlContent) {
    final bytes = utf8.encode(xmlContent);
    var hash = 2166136261;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  String _newId(String prefix) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final randomValue = Random.secure().nextInt(1 << 32);
    return '${prefix}_$now$randomValue';
  }

  String _newToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List<String>.generate(24, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}

