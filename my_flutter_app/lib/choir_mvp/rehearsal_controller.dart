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
    final stationsById = _createDefaultStations();
    final stationRuntimeById = <String, StationRuntimeStatus>{};
    for (final entry in stationsById.entries) {
      final station = entry.value;
      stationRuntimeById[entry.key] = StationRuntimeStatus(
        stationId: station.stationId,
        stationName: station.stationName,
        lockedPart: station.lockedPart,
        currentMeasure: station.practiceSession.minMeasure,
        tempoPercent: station.practiceSession.defaultTempoPercent,
      );
    }
    final session = ClassSessionState(
      sessionId: _newId('session'),
      className: (className ?? '').trim(),
      pieceId: _loadedPieceId,
      createdAt: DateTime.now(),
      pairingToken: token,
      stationsById: stationsById,
      stationRuntimeById: stationRuntimeById,
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
      'student_name,station_name,locked_part,attempt_id,completed,time_seconds,time_minutes,measure_min,measure_max,tempo_min,tempo_max,loop_reps,started_at,ended_at',
    ];
    if (active.stationAttempts.isEmpty) {
      for (final runtime in active.stationRuntimeById.values) {
        final minutes = (runtime.totalPracticeSeconds / 60).toStringAsFixed(1);
        lines.add(
          '${runtime.activeStudentName ?? ''},${runtime.stationName},${_stationPartCode(runtime.lockedPart)},,false,${runtime.totalPracticeSeconds},$minutes,,,,,,${runtime.lastActivityAt.toIso8601String()},',
        );
      }
      return lines.join('\n');
    }
    for (final attempt in active.stationAttempts) {
      final safeName = attempt.studentName.replaceAll(',', ' ');
      final safeStation = attempt.stationName.replaceAll(',', ' ');
      final minutes = (attempt.timeOnTaskSeconds / 60).toStringAsFixed(1);
      lines.add(
        '$safeName,$safeStation,${_stationPartCode(attempt.lockedPart)},${attempt.attemptId},${attempt.completed},${attempt.timeOnTaskSeconds},$minutes,${attempt.measuresVisitedMin ?? ''},${attempt.measuresVisitedMax ?? ''},${attempt.tempoMinUsed ?? ''},${attempt.tempoMaxUsed ?? ''},${attempt.loopReps},${attempt.startedAt.toIso8601String()},${attempt.endedAt?.toIso8601String() ?? ''}',
      );
    }
    return lines.join('\n');
  }

  List<StationConfig> get stationConfigs {
    final active = _classSession;
    if (active == null) {
      return const <StationConfig>[];
    }
    return active.sortedStations();
  }

  StationRuntimeStatus? stationRuntime(String stationId) {
    return _classSession?.stationRuntimeById[stationId];
  }

  Future<void> updateStationConfig({
    required String stationId,
    required String stationName,
    required int startMeasure,
    required int endMeasure,
    required int defaultTempoPercent,
    required bool loopDefaultOn,
  }) async {
    final active = _classSession;
    if (active == null) {
      return;
    }
    final station = active.stationsById[stationId];
    if (station == null) {
      return;
    }
    station.stationName = stationName.trim().isEmpty ? station.stationName : stationName.trim();
    station.practiceSession = StationPracticeSessionConfig(
      id: station.practiceSession.id,
      title: '${station.stationName}: mm.$startMeasure-$endMeasure',
      startMeasure: startMeasure,
      endMeasure: endMeasure,
      defaultTempoPercent:
          (defaultTempoPercent.clamp(50, 100) as num).toInt(),
      allowTempoAdjust: true,
      tempoMinPercent: 50,
      tempoMaxPercent: 100,
      loopDefaultOn: loopDefaultOn,
      allowCustomLoopPoints: true,
      navBackForwardAllowed: true,
      navStepMeasures: 2,
      allowJumpToAnyMeasureInRange: true,
      lockRangeStrict: true,
    );
    final runtime = active.stationRuntimeById[stationId];
    if (runtime != null) {
      runtime.stationName = station.stationName;
      runtime.currentMeasure = station.practiceSession.minMeasure;
      runtime.tempoPercent = station.practiceSession.defaultTempoPercent;
      runtime.loopEnabled = station.practiceSession.loopDefaultOn;
      runtime.loopA = station.practiceSession.loopDefaultOn
          ? station.practiceSession.minMeasure
          : null;
      runtime.loopB = station.practiceSession.loopDefaultOn
          ? station.practiceSession.maxMeasure
          : null;
    }
    await _persistCurrentClassSession();
    _broadcastStateAndNotify();
  }

  Future<Map<String, dynamic>> stationPairingPayload(String stationId) async {
    final active = _classSession;
    if (active == null) {
      throw StateError('No active class session');
    }
    final station = active.stationsById[stationId];
    if (station == null) {
      throw StateError('Unknown station');
    }
    return _server.buildPairingPayload(
      overrideToken: active.pairingToken,
      extra: <String, dynamic>{
        'mode': 'station_single',
        'sessionId': active.sessionId,
        'stationId': station.stationId,
        'stationName': station.stationName,
        'lockedPart': _stationPartCode(station.lockedPart),
        if (station.stationPasscode != null) 'stationPasscode': station.stationPasscode,
        'practice': station.practiceSession.toMap(),
      },
    );
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
    final station = _stationForClientCommand(command);
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
        var measure = _readInt(command['measure']);
        if (measure != null) {
          if (station != null && station.practiceSession.lockRangeStrict) {
            final clamped = measure.clamp(
              station.practiceSession.minMeasure,
              station.practiceSession.maxMeasure,
            );
            measure = (clamped as num).toInt();
          }
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
          if (station != null && station.practiceSession.lockRangeStrict) {
            final requested = _playback.currentMeasure + delta;
            final target = requested.clamp(
              station.practiceSession.minMeasure,
              station.practiceSession.maxMeasure,
            );
            final resolved = (target as num).toInt();
            await _playbackController.jumpToMeasure(resolved);
            return CommandExecutionResult(
              applied: true,
              message: delta < 0 ? 'Back ${delta.abs()}' : 'Forward $delta',
            );
          } else {
            _playbackController.jumpRelative(delta);
            return CommandExecutionResult(
              applied: true,
              message: delta < 0 ? 'Back ${delta.abs()}' : 'Forward $delta',
            );
          }
        }
        return const CommandExecutionResult(
          applied: false,
          message: "Didn't catch that.",
          suggestion: "Try: 'back two measures'.",
        );
      case 'SET_TEMPO':
        var percent = _readDouble(command['percent']);
        if (percent != null) {
          if (station != null) {
            if (!station.practiceSession.allowTempoAdjust) {
              percent = station.practiceSession.defaultTempoPercent.toDouble();
            } else {
              percent = percent.clamp(
                station.practiceSession.tempoMinPercent.toDouble(),
                station.practiceSession.tempoMaxPercent.toDouble(),
              );
            }
          }
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
          if (station != null && !station.practiceSession.allowTempoAdjust) {
            _playbackController.setTempoPercent(
              station.practiceSession.defaultTempoPercent,
            );
          } else if (station != null) {
            final next =
                (_playback.tempoPercent + delta).round().clamp(
                      station.practiceSession.tempoMinPercent,
                      station.practiceSession.tempoMaxPercent,
                    );
            _playbackController.setTempoPercent((next as num).toInt());
          } else {
            _playbackController.adjustTempoPercent(delta);
          }
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
          if (station != null) {
            if (part == ChoirPart.piano) {
              _playbackController.setPartsEnabled(
                <ChoirPart>{station.lockedPart},
                pianoOn: enabled,
              );
              return CommandExecutionResult(
                applied: true,
                message: 'Piano ${enabled ? 'on' : 'off'}',
              );
            }
            _playbackController.setPartsEnabled(
              <ChoirPart>{station.lockedPart},
              pianoOn: _playback.enabledParts.contains(ChoirPart.piano),
            );
            return CommandExecutionResult(
              applied: true,
              message: '${station.lockedPart.shortLabel} locked',
            );
          } else {
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
        if (station != null) {
          _playbackController.setPartsEnabled(
            <ChoirPart>{station.lockedPart},
            pianoOn: pianoEnabled ?? _playback.enabledParts.contains(ChoirPart.piano),
          );
        } else {
          _playbackController.setPartsEnabled(enabled, pianoOn: pianoEnabled);
        }
        return const CommandExecutionResult(
          applied: true,
          message: 'Parts updated',
        );
      case 'SET_MIX_PRESET':
        final presetRaw = ((command['preset'] as String?) ?? '').toLowerCase();
        if (station != null) {
          _playbackController.setPartsEnabled(
            <ChoirPart>{station.lockedPart},
            pianoOn: command['pianoOn'] as bool? ?? true,
          );
          return const CommandExecutionResult(
            applied: true,
            message: 'Station mix locked',
          );
        }
        switch (presetRaw) {
          case 'all':
            if (station != null) {
              _playbackController.setPartsEnabled(
                <ChoirPart>{station.lockedPart},
                pianoOn: true,
              );
            } else {
              _playbackController.setPreset(MixPreset.all);
            }
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
        if (station != null) {
          _playbackController.setPartsEnabled(
            <ChoirPart>{station.lockedPart},
            pianoOn: true,
          );
        } else {
          _playbackController.setPreset(MixPreset.all);
        }
        return const CommandExecutionResult(applied: true, message: 'All parts on');
      case 'SET_LOOP_A':
        var measure = _readInt(command['measure']);
        if (measure != null) {
          if (station != null && station.practiceSession.lockRangeStrict) {
            measure = measure
                .clamp(station.practiceSession.minMeasure, station.practiceSession.maxMeasure)
                .toInt();
          }
          _playbackController.setLoopA(measure: measure);
          return CommandExecutionResult(
            applied: true,
            message: 'Set loop A at $measure',
          );
        }
        return const CommandExecutionResult(applied: false, message: "Didn't catch that.");
      case 'SET_LOOP_B':
        var measure = _readInt(command['measure']);
        if (measure != null) {
          if (station != null && station.practiceSession.lockRangeStrict) {
            measure = measure
                .clamp(station.practiceSession.minMeasure, station.practiceSession.maxMeasure)
                .toInt();
          }
          _playbackController.setLoopB(measure: measure);
          return CommandExecutionResult(
            applied: true,
            message: 'Set loop B at $measure',
          );
        }
        return const CommandExecutionResult(applied: false, message: "Didn't catch that.");
      case 'SET_LOOP_RANGE':
        var a = _readInt(command['a']);
        var b = _readInt(command['b']);
        if (a != null && b != null) {
          if (station != null && station.practiceSession.lockRangeStrict) {
            a = a
                .clamp(station.practiceSession.minMeasure, station.practiceSession.maxMeasure)
                .toInt();
            b = b
                .clamp(station.practiceSession.minMeasure, station.practiceSession.maxMeasure)
                .toInt();
          }
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
      case 'REGISTER_STATION':
        return _handleRegisterStation(command);
      case 'JOIN_STATION':
        return _handleJoinStation(command);
      case 'JOIN_CLASS_SESSION':
        return _handleJoinClassSession(command);
      case 'START_PRACTICE_SESSION':
        return _handleStartPracticeSession(command);
      case 'PRACTICE_EVENT':
        return _handlePracticeEvent(command);
      case 'PRACTICE_SUMMARY':
        return _handlePracticeSummary(command);
      case 'PRACTICE_COMPLETED':
        return _handlePracticeCompleted(command);
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

  StationConfig? _stationForClientCommand(Map<String, dynamic> command) {
    final active = _classSession;
    if (active == null) {
      return null;
    }
    final clientId = command['_clientId']?.toString();
    if (clientId == null || clientId.isEmpty) {
      return null;
    }
    final deviceId = _clientIdToDeviceId[clientId];
    if (deviceId == null || deviceId.isEmpty) {
      return null;
    }
    for (final station in active.stationsById.values) {
      if (station.deviceId == deviceId) {
        return station;
      }
    }
    return null;
  }

  CommandExecutionResult _handleRegisterStation(Map<String, dynamic> command) {
    final active = _classSession;
    if (active == null) {
      return const CommandExecutionResult(applied: false, message: 'No active class session');
    }
    final sessionId = command['sessionId']?.toString() ?? '';
    if (sessionId != active.sessionId) {
      return const CommandExecutionResult(applied: false, message: 'Session mismatch');
    }
    final stationId = command['stationId']?.toString() ?? '';
    final deviceId = command['deviceId']?.toString() ?? '';
    final station = active.stationsById[stationId];
    if (station == null) {
      return const CommandExecutionResult(applied: false, message: 'Unknown station');
    }
    if (deviceId.isNotEmpty) {
      station.deviceId = deviceId;
    }
    final runtime = active.stationRuntimeById[stationId];
    if (runtime != null) {
      runtime.connected = true;
      runtime.lastActivityAt = DateTime.now();
    }
    final clientId = command['_clientId']?.toString();
    if (clientId != null && clientId.isNotEmpty && deviceId.isNotEmpty) {
      _clientIdToDeviceId[clientId] = deviceId;
    }
    _logClassEvent(<String, dynamic>{
      'type': 'REGISTER_STATION',
      'stationId': stationId,
      'deviceId': deviceId,
      'at': DateTime.now().toIso8601String(),
    });
    unawaited(_persistCurrentClassSession());
    _broadcastStateAndNotify();
    return const CommandExecutionResult(applied: true, message: 'Station registered');
  }

  CommandExecutionResult _handleJoinStation(Map<String, dynamic> command) {
    final active = _classSession;
    if (active == null) {
      return const CommandExecutionResult(applied: false, message: 'No active class session');
    }
    final sessionId = command['sessionId']?.toString() ?? '';
    if (sessionId != active.sessionId) {
      return const CommandExecutionResult(applied: false, message: 'Session mismatch');
    }
    final stationId = command['stationId']?.toString() ?? '';
    final studentName = command['studentName']?.toString().trim() ?? '';
    final deviceId = command['deviceId']?.toString() ?? '';
    final attemptId = command['attemptId']?.toString() ?? _newId('attempt');
    final station = active.stationsById[stationId];
    if (station == null || studentName.isEmpty) {
      return const CommandExecutionResult(applied: false, message: 'Invalid station join');
    }

    if (deviceId.isNotEmpty) {
      station.deviceId = deviceId;
    }
    final clientId = command['_clientId']?.toString();
    if (clientId != null && clientId.isNotEmpty && deviceId.isNotEmpty) {
      _clientIdToDeviceId[clientId] = deviceId;
    }
    final runtime = active.stationRuntimeById.putIfAbsent(
      stationId,
      () => StationRuntimeStatus(
        stationId: stationId,
        stationName: station.stationName,
        lockedPart: station.lockedPart,
      ),
    );
    runtime.stationName = station.stationName;
    runtime.activeStudentName = studentName;
    runtime.activeAttemptId = attemptId;
    runtime.currentMeasure = station.practiceSession.minMeasure;
    runtime.tempoPercent = station.practiceSession.defaultTempoPercent;
    runtime.loopEnabled = station.practiceSession.loopDefaultOn;
    runtime.loopA = station.practiceSession.loopDefaultOn ? station.practiceSession.minMeasure : null;
    runtime.loopB = station.practiceSession.loopDefaultOn ? station.practiceSession.maxMeasure : null;
    runtime.connected = true;
    runtime.lastActivityAt = DateTime.now();

    final existingAttempt = _findStationAttempt(active, attemptId);
    if (existingAttempt == null) {
      active.stationAttempts.add(
        StationAttemptSummary(
          attemptId: attemptId,
          sessionId: active.sessionId,
          stationId: stationId,
          stationName: station.stationName,
          studentName: studentName,
          lockedPart: station.lockedPart,
          startedAt: DateTime.now(),
          measuresVisitedMin: station.practiceSession.minMeasure,
          measuresVisitedMax: station.practiceSession.minMeasure,
          tempoMinUsed: station.practiceSession.defaultTempoPercent,
          tempoMaxUsed: station.practiceSession.defaultTempoPercent,
        ),
      );
    }

    _playbackController.setPartsEnabled(<ChoirPart>{station.lockedPart}, pianoOn: true);
    _playbackController.setTempoPercent(station.practiceSession.defaultTempoPercent);
    if (station.practiceSession.loopDefaultOn) {
      _playbackController.setLoopRange(
        a: station.practiceSession.minMeasure,
        b: station.practiceSession.maxMeasure,
      );
    } else {
      _playbackController.clearLoop();
    }
    unawaited(_playbackController.jumpToMeasure(station.practiceSession.minMeasure));

    _logClassEvent(<String, dynamic>{
      'type': 'JOIN_STATION',
      'stationId': stationId,
      'studentName': studentName,
      'attemptId': attemptId,
      'deviceId': deviceId,
      'at': DateTime.now().toIso8601String(),
    });
    unawaited(_persistCurrentClassSession());
    _broadcastStateAndNotify();
    return const CommandExecutionResult(applied: true, message: 'Station joined');
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
    final attemptId = command['attemptId']?.toString() ?? '';
    final eventType = command['event']?.toString().toUpperCase() ?? '';
    if (attemptId.isEmpty || eventType.isEmpty) {
      return const CommandExecutionResult(applied: false, message: 'Malformed practice event');
    }
    final attempt = _findStationAttempt(active, attemptId);
    if (attempt == null) {
      return const CommandExecutionResult(applied: false, message: 'Unknown attempt');
    }
    final runtime = active.stationRuntimeById[attempt.stationId];
    final now = DateTime.now();

    final currentMeasure = _readInt(command['currentMeasure']);
    if (currentMeasure != null) {
      attempt.measuresVisitedMin = attempt.measuresVisitedMin == null
          ? currentMeasure
          : (attempt.measuresVisitedMin! < currentMeasure
                ? attempt.measuresVisitedMin
                : currentMeasure);
      attempt.measuresVisitedMax = attempt.measuresVisitedMax == null
          ? currentMeasure
          : (attempt.measuresVisitedMax! > currentMeasure
                ? attempt.measuresVisitedMax
                : currentMeasure);
      active.measureVisitCounts[currentMeasure] =
          (active.measureVisitCounts[currentMeasure] ?? 0) + 1;
      if (runtime != null) {
        runtime.currentMeasure = currentMeasure;
      }
    }
    final tempo = _readInt(command['tempoPercent']);
    if (tempo != null) {
      attempt.tempoMinUsed =
          attempt.tempoMinUsed == null ? tempo : (attempt.tempoMinUsed! < tempo ? attempt.tempoMinUsed : tempo);
      attempt.tempoMaxUsed =
          attempt.tempoMaxUsed == null ? tempo : (attempt.tempoMaxUsed! > tempo ? attempt.tempoMaxUsed : tempo);
      if (runtime != null) {
        runtime.tempoPercent = tempo;
      }
    }
    final deltaSeconds = _readInt(command['deltaSeconds']);
    if (deltaSeconds != null && deltaSeconds > 0) {
      attempt.timeOnTaskSeconds += deltaSeconds;
      if (runtime != null) {
        runtime.totalPracticeSeconds += deltaSeconds;
      }
    }
    final loopStateRaw = command['loopState'];
    if (loopStateRaw is Map) {
      final loopState = loopStateRaw.cast<String, dynamic>();
      final enabled = loopState['enabled'] == true;
      final a = _readInt(loopState['a']);
      final b = _readInt(loopState['b']);
      if (runtime != null) {
        runtime.loopEnabled = enabled;
        runtime.loopA = a;
        runtime.loopB = b;
      }
      if (enabled && a != null && b != null) {
        final start = a <= b ? a : b;
        final end = a <= b ? b : a;
        final key = 'mm.$start-$end';
        if (eventType == 'LOOP') {
          active.loopRangeCounts[key] = (active.loopRangeCounts[key] ?? 0) + 1;
          attempt.loopReps += 1;
        }
      }
    }
    if (runtime != null) {
      runtime.lastActivityAt = now;
      runtime.connected = true;
      if (eventType == 'PAUSE') {
        // Keep active student, just not playing.
      }
    }

    _logClassEvent(<String, dynamic>{
      'type': 'PRACTICE_EVENT',
      'attemptId': attemptId,
      'stationId': attempt.stationId,
      'studentName': attempt.studentName,
      'event': eventType,
      'currentMeasure': currentMeasure,
      'tempoPercent': tempo,
      'at': now.toIso8601String(),
    });
    unawaited(_persistCurrentClassSession());
    _broadcastStateAndNotify();
    return const CommandExecutionResult(applied: true, message: 'Practice event recorded');
  }

  CommandExecutionResult _handlePracticeSummary(Map<String, dynamic> command) {
    final active = _classSession;
    if (active == null) {
      return const CommandExecutionResult(applied: false, message: 'No active class session');
    }
    final attemptId = command['attemptId']?.toString() ?? '';
    if (attemptId.isEmpty) {
      return const CommandExecutionResult(applied: false, message: 'Missing attempt');
    }
    final attempt = _findStationAttempt(active, attemptId);
    if (attempt == null) {
      return const CommandExecutionResult(applied: false, message: 'Unknown attempt');
    }
    final stationId = command['stationId']?.toString() ?? attempt.stationId;
    final runtime = active.stationRuntimeById[stationId];

    final seconds = _readInt(command['timeOnTaskSeconds']);
    if (seconds != null) {
      attempt.timeOnTaskSeconds = seconds > attempt.timeOnTaskSeconds ? seconds : attempt.timeOnTaskSeconds;
    }
    final minMeasure = _readInt(command['measuresVisitedMin']);
    final maxMeasure = _readInt(command['measuresVisitedMax']);
    if (minMeasure != null) {
      attempt.measuresVisitedMin = minMeasure;
      active.measureVisitCounts[minMeasure] = (active.measureVisitCounts[minMeasure] ?? 0) + 1;
    }
    if (maxMeasure != null) {
      attempt.measuresVisitedMax = maxMeasure;
      active.measureVisitCounts[maxMeasure] = (active.measureVisitCounts[maxMeasure] ?? 0) + 1;
    }
    final loopReps = _readInt(command['loopReps']);
    if (loopReps != null && loopReps > attempt.loopReps) {
      attempt.loopReps = loopReps;
    }
    final tempoMin = _readInt(command['tempoMinUsed']);
    final tempoMax = _readInt(command['tempoMaxUsed']);
    if (tempoMin != null) {
      attempt.tempoMinUsed = tempoMin;
    }
    if (tempoMax != null) {
      attempt.tempoMaxUsed = tempoMax;
    }
    final wasCompleted = attempt.completed;
    if (command['completed'] == true) {
      attempt.completed = true;
      attempt.endedAt ??= DateTime.now();
    }
    if (runtime != null) {
      runtime.lastActivityAt = DateTime.now();
      runtime.totalPracticeSeconds = runtime.totalPracticeSeconds < attempt.timeOnTaskSeconds
          ? attempt.timeOnTaskSeconds
          : runtime.totalPracticeSeconds;
      if (attempt.completed && !wasCompleted) {
        runtime.studentsCompleted += 1;
      }
      if (attempt.completed && runtime.activeAttemptId == attemptId) {
        runtime.activeAttemptId = null;
        runtime.activeStudentName = null;
      }
    }
    _logClassEvent(<String, dynamic>{
      'type': 'PRACTICE_SUMMARY',
      'attemptId': attemptId,
      'stationId': stationId,
      'timeOnTaskSeconds': attempt.timeOnTaskSeconds,
      'completed': attempt.completed,
      'at': DateTime.now().toIso8601String(),
    });
    unawaited(_persistCurrentClassSession());
    _broadcastStateAndNotify();
    return const CommandExecutionResult(applied: true, message: 'Summary recorded');
  }

  CommandExecutionResult _handlePracticeCompleted(Map<String, dynamic> command) {
    final active = _classSession;
    if (active == null) {
      return const CommandExecutionResult(applied: false, message: 'No active class session');
    }
    final attemptId = command['attemptId']?.toString() ?? '';
    if (attemptId.isEmpty) {
      return const CommandExecutionResult(applied: false, message: 'Missing attempt');
    }
    final attempt = _findStationAttempt(active, attemptId);
    if (attempt == null) {
      return const CommandExecutionResult(applied: false, message: 'Unknown attempt');
    }
    final wasCompleted = attempt.completed;
    if (!attempt.completed) {
      attempt.completed = true;
    }
    attempt.endedAt ??= DateTime.now();
    final runtime = active.stationRuntimeById[attempt.stationId];
    if (runtime != null) {
      if (!wasCompleted) {
        runtime.studentsCompleted += 1;
      }
      runtime.activeStudentName = null;
      runtime.activeAttemptId = null;
      runtime.lastActivityAt = DateTime.now();
    }
    _logClassEvent(<String, dynamic>{
      'type': 'PRACTICE_COMPLETED',
      'attemptId': attemptId,
      'stationId': attempt.stationId,
      'studentName': attempt.studentName,
      'at': DateTime.now().toIso8601String(),
    });
    unawaited(_persistCurrentClassSession());
    _broadcastStateAndNotify();
    return const CommandExecutionResult(applied: true, message: 'Completion recorded');
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
    var updated = false;
    final student = active.rosterByDeviceId[deviceId];
    if (student != null) {
      student.connected = connected;
      student.status = connected ? student.status : 'idle';
      student.lastActivityAt = DateTime.now();
      updated = true;
    }
    for (final runtime in active.stationRuntimeById.values) {
      final station = active.stationsById[runtime.stationId];
      if (station?.deviceId == deviceId) {
        runtime.connected = connected;
        runtime.lastActivityAt = DateTime.now();
        if (!connected) {
          runtime.activeStudentName = null;
          runtime.activeAttemptId = null;
        }
        updated = true;
      }
    }
    if (updated) {
      _broadcastStateAndNotify();
    }
  }

  StationAttemptSummary? _findStationAttempt(ClassSessionState session, String attemptId) {
    for (final attempt in session.stationAttempts) {
      if (attempt.attemptId == attemptId) {
        return attempt;
      }
    }
    return null;
  }

  Map<String, StationConfig> _createDefaultStations() {
    final measures = _playback.score?.measureNumbers ?? <int>[1];
    final firstMeasure = measures.isEmpty ? 1 : measures.first;
    final lastMeasure = measures.isEmpty ? 8 : measures.last;
    final defaultEnd =
        ((firstMeasure + 8).clamp(firstMeasure, lastMeasure) as num).toInt();
    final map = <String, StationConfig>{};
    for (final part in const [
      ChoirPart.soprano,
      ChoirPart.alto,
      ChoirPart.tenor,
      ChoirPart.bass,
    ]) {
      final stationId = _newId('station_${part.id}');
      final stationName = '${_stationLabel(part)} Station';
      final practice = StationPracticeSessionConfig(
        id: _newId('practice_${part.id}'),
        title: '${_stationLabel(part)}: mm.$firstMeasure-$defaultEnd',
        startMeasure: firstMeasure,
        endMeasure: defaultEnd,
        defaultTempoPercent: 70,
        allowTempoAdjust: true,
        tempoMinPercent: 50,
        tempoMaxPercent: 100,
        loopDefaultOn: true,
        allowCustomLoopPoints: true,
        navBackForwardAllowed: true,
        navStepMeasures: 2,
        allowJumpToAnyMeasureInRange: true,
        lockRangeStrict: true,
      );
      map[stationId] = StationConfig(
        stationId: stationId,
        stationName: stationName,
        lockedPart: part,
        practiceSession: practice,
      );
    }
    return map;
  }

  String _stationLabel(ChoirPart part) {
    switch (part) {
      case ChoirPart.soprano:
        return 'Soprano';
      case ChoirPart.alto:
        return 'Alto';
      case ChoirPart.tenor:
        return 'Tenor';
      case ChoirPart.bass:
        return 'Bass';
      case ChoirPart.piano:
        return 'Piano';
    }
  }

  String _stationPartCode(ChoirPart part) {
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

