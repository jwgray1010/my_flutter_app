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
import 'vocal_coach_models.dart';

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

class VocalCoachStudentRow {
  const VocalCoachStudentRow({
    required this.studentId,
    required this.studentName,
    required this.focusAreas,
    required this.baselineScore,
    required this.latestMicroCheckScore,
    required this.improvementDelta,
    required this.lastUpdatedAt,
    this.stationId,
  });

  final String studentId;
  final String studentName;
  final List<VocalFocusArea> focusAreas;
  final int baselineScore;
  final int? latestMicroCheckScore;
  final int? improvementDelta;
  final DateTime lastUpdatedAt;
  final String? stationId;
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
  Map<String, dynamic>? _checkInReference;
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
    _refreshClearanceExpirations();
    final lines = <String>[
      'studentName,studentId,stationId,tier,result,timeOnTaskSeconds,troubleMeasures,clearanceStatus,timestamp',
    ];
    if (active.checkInRecords.isEmpty) {
      for (final progress in active.checkInProgressByStudentKey.values) {
        final trouble = progress.latestTroubleMeasures.isEmpty
            ? ''
            : progress.latestTroubleMeasures.join('|');
        lines.add(
          '${progress.studentName},${progress.studentId},${progress.stationId},${progress.latestTier.id},${progress.latestResult.id},0,$trouble,${progress.clearanceStatus.id},${progress.lastUpdatedAt.toIso8601String()}',
        );
      }
      return lines.join('\n');
    }
    for (final attempt in active.checkInRecords) {
      final safeName = attempt.studentName.replaceAll(',', ' ');
      final trouble = attempt.troubleMeasures.isEmpty
          ? ''
          : attempt.troubleMeasures.join('|');
      final progressKey = _studentProgressKey(
        attempt.stationId,
        attempt.studentId,
        attempt.studentName,
      );
      final clearance = active.checkInProgressByStudentKey[progressKey]?.clearanceStatus.id ??
          StudentClearanceStatus.notCleared.id;
      lines.add(
        '$safeName,${attempt.studentId},${attempt.stationId},${attempt.tier.id},${attempt.result.id},${attempt.timeOnTaskSeconds},$trouble,$clearance,${attempt.timestamp.toIso8601String()}',
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

  List<StudentCheckInProgress> checkInProgressRows() {
    final active = _classSession;
    if (active == null) {
      return const <StudentCheckInProgress>[];
    }
    _refreshClearanceExpirations();
    final rows = active.checkInProgressByStudentKey.values.toList();
    rows.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
    return rows;
  }

  Map<StudentClearanceStatus, int> clearanceCounts() {
    final active = _classSession;
    if (active == null) {
      return <StudentClearanceStatus, int>{
        StudentClearanceStatus.notCleared: 0,
        StudentClearanceStatus.cleared: 0,
        StudentClearanceStatus.lowConfidence: 0,
      };
    }
    _refreshClearanceExpirations();
    final counts = <StudentClearanceStatus, int>{
      StudentClearanceStatus.notCleared: 0,
      StudentClearanceStatus.cleared: 0,
      StudentClearanceStatus.lowConfidence: 0,
    };
    for (final row in active.checkInProgressByStudentKey.values) {
      counts[row.clearanceStatus] = (counts[row.clearanceStatus] ?? 0) + 1;
    }
    return counts;
  }

  List<MapEntry<int, int>> topTroubleMeasuresForStation(
    String stationId, {
    int limit = 10,
  }) {
    final active = _classSession;
    if (active == null) {
      return const <MapEntry<int, int>>[];
    }
    final totals = <int, int>{};
    for (final entry in active.checkInTroubleByStationMeasure.entries) {
      final key = entry.key;
      if (!key.startsWith('$stationId:')) {
        continue;
      }
      final parts = key.split(':');
      if (parts.length != 2) {
        continue;
      }
      final measure = int.tryParse(parts[1]);
      if (measure == null) {
        continue;
      }
      totals[measure] = (totals[measure] ?? 0) + entry.value;
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  List<VocalCoachStudentRow> vocalCoachRows() {
    final active = _classSession;
    if (active == null) {
      return const <VocalCoachStudentRow>[];
    }
    final rows = <VocalCoachStudentRow>[];
    for (final profile in active.vocalProfilesByStudentId.values) {
      final latestProgress = _latestVocalProgress(
        active,
        studentId: profile.studentId,
      );
      final latestScore = latestProgress?.microCheckScore;
      final improvement = latestScore == null ? null : latestScore - profile.baselineComposite;
      rows.add(
        VocalCoachStudentRow(
          studentId: profile.studentId,
          studentName: profile.studentName,
          focusAreas: profile.focusAreas,
          baselineScore: profile.baselineComposite,
          latestMicroCheckScore: latestScore,
          improvementDelta: improvement,
          lastUpdatedAt: latestProgress?.timestamp ?? profile.timestamp,
          stationId: profile.stationId,
        ),
      );
    }
    rows.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
    return rows;
  }

  Map<VocalFocusArea, int> vocalCoachSectionWeakness() {
    final active = _classSession;
    if (active == null) {
      return <VocalFocusArea, int>{};
    }
    final counts = <VocalFocusArea, int>{};
    for (final profile in active.vocalProfilesByStudentId.values) {
      for (final focus in profile.focusAreas) {
        counts[focus] = (counts[focus] ?? 0) + 1;
      }
    }
    return counts;
  }

  Future<void> saveVocalCoachProfile({
    required VocalSkillProfile profile,
    VocalTrainingPlan? plan,
  }) async {
    final active = _classSession;
    if (active == null) {
      return;
    }
    final key = profile.studentId.trim().isEmpty
        ? profile.studentName.trim().toLowerCase()
        : profile.studentId.trim();
    if (key.isEmpty) {
      return;
    }
    active.vocalProfilesByStudentId[key] = profile;
    if (plan != null) {
      active.vocalPlansByStudentId[key] = plan;
    }
    _logClassEvent(<String, dynamic>{
      'type': 'VOCAL_COACH_PROFILE',
      'studentId': profile.studentId,
      'studentName': profile.studentName,
      'focusAreas': profile.focusAreas.map((entry) => entry.id).toList(),
      'timestamp': profile.timestamp.toIso8601String(),
      'lowConfidence': profile.lowConfidence,
    });
    await _persistCurrentClassSession();
    _broadcastStateAndNotify();
  }

  Future<void> saveVocalCoachProgress(VocalSessionProgress progress) async {
    final active = _classSession;
    if (active == null) {
      return;
    }
    active.vocalProgressLog.add(progress);
    if (active.vocalProgressLog.length > 5000) {
      active.vocalProgressLog.removeRange(0, active.vocalProgressLog.length - 5000);
    }
    _logClassEvent(<String, dynamic>{
      'type': 'VOCAL_COACH_PROGRESS',
      'studentId': progress.studentId,
      'studentName': progress.studentName,
      'microCheckScore': progress.microCheckScore,
      'timestamp': progress.timestamp.toIso8601String(),
    });
    await _persistCurrentClassSession();
    _broadcastStateAndNotify();
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

  Future<void> updateDirectorGateSettings({
    required bool enabled,
    required CheckInTier requiredTier,
    required DirectorGateValidityWindow validityWindow,
    required int customMinutes,
    required DirectorGateLowConfidenceBehavior lowConfidenceBehavior,
    required int retryCooldownSeconds,
  }) async {
    final active = _classSession;
    if (active == null) {
      return;
    }
    final scoredTier = requiredTier.isScored
        ? requiredTier
        : CheckInTier.acapellaClick;
    active.directorGate = active.directorGate.copyWith(
      enabled: enabled,
      requiredTier: scoredTier,
      validityWindow: validityWindow,
      customMinutes: (customMinutes.clamp(1, 24 * 60) as num).toInt(),
      lowConfidenceBehavior: lowConfidenceBehavior,
      retryCooldownSeconds: (retryCooldownSeconds.clamp(0, 60 * 30) as num).toInt(),
    );
    if (enabled) {
      for (final progress in active.checkInProgressByStudentKey.values) {
        if (progress.clearanceStatus != StudentClearanceStatus.cleared) {
          continue;
        }
        final passedTier = progress.clearanceTierPassed ?? 0;
        if (passedTier < scoredTier.order) {
          progress.clearanceStatus = StudentClearanceStatus.notCleared;
          progress.clearanceTierPassed = null;
          progress.clearanceTimestamp = null;
          progress.clearanceExpiresAt = null;
          continue;
        }
        if (progress.clearanceTimestamp != null) {
          progress.clearanceExpiresAt =
              _clearanceExpiresAt(active.directorGate, progress.clearanceTimestamp!);
        }
      }
    }
    _refreshClearanceExpirations();
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
        'directorGate': active.directorGate.toMap(),
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
      _checkInReference = _buildCheckInReference(score);
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
      case 'CHECKIN_ATTEMPT':
      case 'CHECKIN_RESULT':
        return _handleCheckInResult(command);
      case 'VOCAL_COACH_PROFILE':
        return _handleVocalCoachProfile(command);
      case 'VOCAL_COACH_PROGRESS':
        return _handleVocalCoachProgress(command);
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
    _refreshClearanceExpirations();
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
      'checkInReference': _checkInReference,
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
    final studentName = (command['studentName']?.toString() ?? '').trim();
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

    final studentId = _studentIdFor(stationId: stationId, studentName: studentName);
    final progressKey = _studentProgressKey(stationId, studentId, studentName);
    StudentCheckInProgress? existingProgress =
        active.checkInProgressByStudentKey[progressKey];
    if (existingProgress == null) {
      for (final row in active.checkInProgressByStudentKey.values) {
        if (row.stationId == stationId &&
            row.studentName.trim().toLowerCase() ==
                studentName.trim().toLowerCase()) {
          existingProgress = row;
          break;
        }
      }
    }
    _broadcastClearanceStatus(
      session: active,
      stationId: stationId,
      studentId: studentId,
      studentName: studentName,
      status: existingProgress?.clearanceStatus ?? StudentClearanceStatus.notCleared,
      expiresAt: existingProgress?.clearanceExpiresAt,
    );

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
    final studentName = (command['studentName']?.toString() ?? '').trim();
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

  CommandExecutionResult _handleCheckInResult(Map<String, dynamic> command) {
    final active = _classSession;
    if (active == null) {
      return const CommandExecutionResult(applied: false, message: 'No active class session');
    }
    final sessionId = command['sessionId']?.toString() ?? '';
    if (sessionId.isNotEmpty && sessionId != active.sessionId) {
      return const CommandExecutionResult(applied: false, message: 'Session mismatch');
    }

    final stationId = command['stationId']?.toString() ?? '';
    final studentName = (command['studentName']?.toString() ?? '').trim();
    final incomingStudentId = (command['studentId']?.toString() ?? '').trim();
    final tier = checkInTierFromId(command['tier']?.toString() ?? '');
    final result = checkInResultFromId(command['result']?.toString() ?? '');
    if (stationId.isEmpty || studentName.isEmpty || tier == null || result == null) {
      return const CommandExecutionResult(applied: false, message: 'Malformed check-in result');
    }
    final station = active.stationsById[stationId];
    if (station == null) {
      return const CommandExecutionResult(applied: false, message: 'Unknown station');
    }
    final attemptId = command['attemptId']?.toString() ?? _newId('checkin');
    final studentId = incomingStudentId.isNotEmpty
        ? incomingStudentId
        : _studentIdFor(stationId: stationId, studentName: studentName);
    final gate = active.directorGate;
    if (gate.enabled && tier.isScored && gate.retryCooldownSeconds > 0) {
      final recent = _latestScoredCheckIn(
        active,
        stationId: stationId,
        studentId: studentId,
      );
      if (recent != null) {
        final elapsed = DateTime.now().difference(recent.timestamp).inSeconds;
        if (elapsed < gate.retryCooldownSeconds) {
          return CommandExecutionResult(
            applied: false,
            message: 'Practice ${gate.retryCooldownSeconds}s before retrying.',
          );
        }
      }
    }
    final troubleRaw = command['troubleMeasures'];
    final troubleMeasures = <int>[];
    if (troubleRaw is List) {
      for (final value in troubleRaw) {
        final parsed = _readInt(value);
        if (parsed != null) {
          troubleMeasures.add(parsed);
        }
      }
    }
    final trimmedTrouble = troubleMeasures.take(3).toList();
    final timeOnTaskSeconds = _readInt(command['timeOnTaskSeconds']) ?? 0;
    final confidenceScore = _readInt(command['confidenceScore']);
    final timestamp = DateTime.tryParse(command['timestamp']?.toString() ?? '') ??
        DateTime.now();

    active.checkInRecords.add(
      StationCheckInRecord(
        attemptId: attemptId,
        sessionId: active.sessionId,
        stationId: stationId,
        studentId: studentId,
        studentName: studentName,
        lockedPart: station.lockedPart,
        tier: tier,
        result: result,
        timeOnTaskSeconds: timeOnTaskSeconds,
        timestamp: timestamp,
        troubleMeasures: trimmedTrouble,
        confidenceScore: confidenceScore,
      ),
    );

    final progressKey = _studentProgressKey(stationId, studentId, studentName);
    final legacyKey = '$stationId|${studentName.trim().toLowerCase()}';
    final legacyProgress = active.checkInProgressByStudentKey[legacyKey];
    if (legacyProgress != null && !active.checkInProgressByStudentKey.containsKey(progressKey)) {
      active.checkInProgressByStudentKey[progressKey] = legacyProgress;
      active.checkInProgressByStudentKey.remove(legacyKey);
    }
    final progress = active.checkInProgressByStudentKey.putIfAbsent(
      progressKey,
      () => StudentCheckInProgress(
        studentName: studentName,
        stationId: stationId,
        studentId: studentId,
        partId: _stationPartCode(station.lockedPart),
        latestTier: tier,
        latestResult: result,
        highestScoredTierPassed: 0,
        challengeTier4Completed: false,
        challengeTier5Completed: false,
        latestTroubleMeasures: trimmedTrouble,
        lastUpdatedAt: timestamp,
      ),
    );
    progress.latestTier = tier;
    progress.latestResult = result;
    if (tier.isScored && trimmedTrouble.isNotEmpty) {
      progress.latestTroubleMeasures = trimmedTrouble;
    }
    progress.lastUpdatedAt = timestamp;
    progress.clearanceStatus = _effectiveClearanceStatus(
      progress.clearanceStatus,
      progress.clearanceExpiresAt,
      DateTime.now(),
    );
    if (tier.isScored && result == CheckInResult.pass) {
      progress.highestScoredTierPassed = progress.highestScoredTierPassed < tier.order
          ? tier.order
          : progress.highestScoredTierPassed;
    }
    if (tier == CheckInTier.accompOnly && result == CheckInResult.challengeCompleted) {
      progress.challengeTier4Completed = true;
    }
    if (tier == CheckInTier.accompPlusOtherParts &&
        result == CheckInResult.challengeCompleted) {
      progress.challengeTier5Completed = true;
    }
    _applyDirectorGateOnCheckIn(
      session: active,
      progress: progress,
      tier: tier,
      result: result,
      timestamp: timestamp,
    );

    if (tier.isScored && result != CheckInResult.lowConfidence) {
      for (final measure in trimmedTrouble) {
        final key = '$stationId:$measure';
        active.checkInTroubleByStationMeasure[key] =
            (active.checkInTroubleByStationMeasure[key] ?? 0) + 1;
      }
    }

    _logClassEvent(<String, dynamic>{
      'type': 'CHECKIN_RESULT',
      'attemptId': attemptId,
      'studentId': studentId,
      'stationId': stationId,
      'studentName': studentName,
      'tier': tier.id,
      'result': result.id,
      'troubleMeasures': trimmedTrouble,
      'timeOnTaskSeconds': timeOnTaskSeconds,
      'confidenceScore': confidenceScore,
      'timestamp': timestamp.toIso8601String(),
    });
    _broadcastClearanceStatus(
      session: active,
      stationId: stationId,
      studentId: studentId,
      studentName: studentName,
      status: progress.clearanceStatus,
      expiresAt: progress.clearanceExpiresAt,
    );
    unawaited(_persistCurrentClassSession());
    _broadcastStateAndNotify();
    return const CommandExecutionResult(applied: true, message: 'Check-in result recorded');
  }

  CommandExecutionResult _handleVocalCoachProfile(Map<String, dynamic> command) {
    final active = _classSession;
    if (active == null) {
      return const CommandExecutionResult(applied: false, message: 'No active class session');
    }
    final sessionId = command['sessionId']?.toString() ?? '';
    if (sessionId.isNotEmpty && sessionId != active.sessionId) {
      return const CommandExecutionResult(applied: false, message: 'Session mismatch');
    }
    final profileRaw = command['profile'];
    if (profileRaw is! Map) {
      return const CommandExecutionResult(applied: false, message: 'Malformed profile payload');
    }
    final profile = VocalSkillProfile.fromMap(profileRaw.cast<String, dynamic>());
    final key = profile.studentId.trim().isEmpty
        ? profile.studentName.trim().toLowerCase()
        : profile.studentId.trim();
    if (key.isEmpty) {
      return const CommandExecutionResult(applied: false, message: 'Missing student id');
    }
    active.vocalProfilesByStudentId[key] = profile;
    final planRaw = command['plan'];
    if (planRaw is Map) {
      active.vocalPlansByStudentId[key] = VocalTrainingPlan.fromMap(
        planRaw.cast<String, dynamic>(),
      );
    }
    _logClassEvent(<String, dynamic>{
      'type': 'VOCAL_COACH_PROFILE',
      'studentId': profile.studentId,
      'studentName': profile.studentName,
      'focusAreas': profile.focusAreas.map((entry) => entry.id).toList(),
      'timestamp': profile.timestamp.toIso8601String(),
      'lowConfidence': profile.lowConfidence,
    });
    unawaited(_persistCurrentClassSession());
    _broadcastStateAndNotify();
    return const CommandExecutionResult(applied: true, message: 'Vocal coach profile recorded');
  }

  CommandExecutionResult _handleVocalCoachProgress(Map<String, dynamic> command) {
    final active = _classSession;
    if (active == null) {
      return const CommandExecutionResult(applied: false, message: 'No active class session');
    }
    final sessionId = command['sessionId']?.toString() ?? '';
    if (sessionId.isNotEmpty && sessionId != active.sessionId) {
      return const CommandExecutionResult(applied: false, message: 'Session mismatch');
    }
    final progressRaw = command['progress'];
    if (progressRaw is! Map) {
      return const CommandExecutionResult(applied: false, message: 'Malformed progress payload');
    }
    final progress = VocalSessionProgress.fromMap(progressRaw.cast<String, dynamic>());
    active.vocalProgressLog.add(progress);
    if (active.vocalProgressLog.length > 5000) {
      active.vocalProgressLog.removeRange(0, active.vocalProgressLog.length - 5000);
    }
    _logClassEvent(<String, dynamic>{
      'type': 'VOCAL_COACH_PROGRESS',
      'studentId': progress.studentId,
      'studentName': progress.studentName,
      'microCheckScore': progress.microCheckScore,
      'timestamp': progress.timestamp.toIso8601String(),
    });
    unawaited(_persistCurrentClassSession());
    _broadcastStateAndNotify();
    return const CommandExecutionResult(applied: true, message: 'Vocal coach progress recorded');
  }

  VocalSessionProgress? _latestVocalProgress(
    ClassSessionState session, {
    required String studentId,
  }) {
    for (var i = session.vocalProgressLog.length - 1; i >= 0; i--) {
      final entry = session.vocalProgressLog[i];
      if (entry.studentId == studentId) {
        return entry;
      }
    }
    return null;
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

  String _studentProgressKey(
    String stationId,
    String studentId,
    String studentName,
  ) {
    final normalizedStudentId = studentId.trim();
    if (normalizedStudentId.isNotEmpty) {
      return '$stationId|$normalizedStudentId';
    }
    return '$stationId|${studentName.trim().toLowerCase()}';
  }

  String _studentIdFor({
    required String stationId,
    required String studentName,
  }) {
    return '${stationId}_${studentName.trim().toLowerCase()}';
  }

  StationCheckInRecord? _latestScoredCheckIn(
    ClassSessionState session, {
    required String stationId,
    required String studentId,
  }) {
    for (var i = session.checkInRecords.length - 1; i >= 0; i--) {
      final entry = session.checkInRecords[i];
      if (entry.stationId != stationId || entry.studentId != studentId) {
        continue;
      }
      if (entry.tier.isScored) {
        return entry;
      }
    }
    return null;
  }

  void _applyDirectorGateOnCheckIn({
    required ClassSessionState session,
    required StudentCheckInProgress progress,
    required CheckInTier tier,
    required CheckInResult result,
    required DateTime timestamp,
  }) {
    final gate = session.directorGate;
    final currentStatus = _effectiveClearanceStatus(
      progress.clearanceStatus,
      progress.clearanceExpiresAt,
      timestamp,
    );
    progress.clearanceStatus = currentStatus;
    if (currentStatus != StudentClearanceStatus.cleared &&
        progress.clearanceExpiresAt != null &&
        timestamp.isAfter(progress.clearanceExpiresAt!)) {
      progress.clearanceTierPassed = null;
      progress.clearanceTimestamp = null;
      progress.clearanceExpiresAt = null;
    }

    if (!gate.enabled || !tier.isScored) {
      return;
    }
    if (result == CheckInResult.lowConfidence) {
      if (gate.lowConfidenceBehavior ==
          DirectorGateLowConfidenceBehavior.doesNotCount) {
        if (progress.clearanceStatus != StudentClearanceStatus.cleared) {
          progress.clearanceStatus = StudentClearanceStatus.lowConfidence;
        }
      } else if (progress.clearanceStatus != StudentClearanceStatus.cleared) {
        progress.clearanceStatus = StudentClearanceStatus.notCleared;
      }
      return;
    }

    if (result == CheckInResult.pass && tier.order >= gate.requiredTier.order) {
      progress.clearanceStatus = StudentClearanceStatus.cleared;
      progress.clearanceTierPassed = tier.order;
      progress.clearanceTimestamp = timestamp;
      progress.clearanceExpiresAt = _clearanceExpiresAt(gate, timestamp);
      return;
    }

    if (progress.clearanceStatus != StudentClearanceStatus.cleared) {
      progress.clearanceStatus = StudentClearanceStatus.notCleared;
    }
  }

  DateTime? _clearanceExpiresAt(
    DirectorGateSettings gate,
    DateTime timestamp,
  ) {
    switch (gate.validityWindow) {
      case DirectorGateValidityWindow.rehearsalOnly:
        return null;
      case DirectorGateValidityWindow.today:
        return DateTime(
          timestamp.year,
          timestamp.month,
          timestamp.day,
          23,
          59,
          59,
          999,
        );
      case DirectorGateValidityWindow.customMinutes:
        return timestamp.add(Duration(minutes: gate.customMinutes));
    }
  }

  StudentClearanceStatus _effectiveClearanceStatus(
    StudentClearanceStatus status,
    DateTime? expiresAt,
    DateTime now,
  ) {
    if (status != StudentClearanceStatus.cleared) {
      return status;
    }
    if (expiresAt == null) {
      return status;
    }
    return now.isAfter(expiresAt)
        ? StudentClearanceStatus.notCleared
        : StudentClearanceStatus.cleared;
  }

  void _refreshClearanceExpirations() {
    final active = _classSession;
    if (active == null) {
      return;
    }
    final now = DateTime.now();
    for (final progress in active.checkInProgressByStudentKey.values) {
      final before = progress.clearanceStatus;
      final effective = _effectiveClearanceStatus(
        before,
        progress.clearanceExpiresAt,
        now,
      );
      progress.clearanceStatus = effective;
      if (before == StudentClearanceStatus.cleared &&
          effective != StudentClearanceStatus.cleared &&
          progress.clearanceExpiresAt != null &&
          now.isAfter(progress.clearanceExpiresAt!)) {
        progress.clearanceTierPassed = null;
        progress.clearanceTimestamp = null;
        progress.clearanceExpiresAt = null;
      }
    }
  }

  void _broadcastClearanceStatus({
    required ClassSessionState session,
    required String stationId,
    required String studentId,
    required String studentName,
    required StudentClearanceStatus status,
    DateTime? expiresAt,
  }) {
    _server.broadcastEvent(<String, dynamic>{
      'type': 'CLEARANCE_STATUS',
      'studentId': studentId,
      'studentName': studentName,
      'stationId': stationId,
      'status': status.id,
      'requiredTier': session.directorGate.requiredTier.id,
      'expiresAt': expiresAt?.toIso8601String(),
      'gateEnabled': session.directorGate.enabled,
    });
  }

  Map<String, dynamic> _buildCheckInReference(ParsedScore score) {
    final byPartMeasure = <String, Map<int, List<int>>>{};
    for (final note in score.notes) {
      final part = _partToProtocol(note.part);
      final measureMap = byPartMeasure.putIfAbsent(part, () => <int, List<int>>{});
      final list = measureMap.putIfAbsent(note.measureNumber, () => <int>[]);
      list.add(note.midi);
    }
    final response = <String, dynamic>{};
    byPartMeasure.forEach((part, measureMap) {
      final partOut = <String, dynamic>{};
      final entries = measureMap.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in entries) {
        final values = List<int>.from(entry.value)..sort();
        if (values.isEmpty) {
          continue;
        }
        final median = values[values.length ~/ 2];
        final avg = values.fold<int>(0, (sum, value) => sum + value) / values.length;
        partOut[entry.key.toString()] = <String, dynamic>{
          'medianMidi': median,
          'avgMidi': avg.round(),
          'noteCount': values.length,
        };
      }
      response[part] = partOut;
    });
    response['measureNumbers'] = score.measureNumbers;
    return response;
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

