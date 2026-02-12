import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

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
  String? _errorMessage;

  bool get initialized => _initialized;
  PlaybackEngine get playback => _playback;
  PlaybackController get playbackController => _playbackController;
  String? get loadedFileName => _loadedFileName;
  String? get errorMessage => _errorMessage;
  int get serverPort => _server.commandPort;
  int get announcePort => _server.announcePort;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _playback.addListener(_handlePlaybackUpdate);
    await _playback.initializeAudio();
    await _server.start(
      onCommand: (command) {
        unawaited(applyCommand(command));
      },
      stateBuilder: _playbackController.snapshotState,
    );
    _server.broadcastState();
    _initialized = true;
    notifyListeners();
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
      case 'SET_MIX_PRESET':
        final presetRaw = (command['preset'] as String?) ?? '';
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
}

