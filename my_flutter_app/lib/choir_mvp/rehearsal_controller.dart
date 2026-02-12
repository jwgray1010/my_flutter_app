import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'models.dart';
import 'musicxml_parser.dart';
import 'networking.dart';
import 'playback_engine.dart';

class RehearsalController extends ChangeNotifier {
  RehearsalController({
    MusicXmlParser? parser,
    PlaybackEngine? playback,
    LocalPlayerServer? server,
  }) : _parser = parser ?? MusicXmlParser(),
       _playback = playback ?? PlaybackEngine(),
       _server = server ?? LocalPlayerServer();

  final MusicXmlParser _parser;
  final PlaybackEngine _playback;
  final LocalPlayerServer _server;

  bool _initialized = false;
  String? _loadedFileName;
  String? _errorMessage;

  bool get initialized => _initialized;
  PlaybackEngine get playback => _playback;
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
      onCommand: _handleRemoteCommand,
      stateBuilder: _playback.snapshotState,
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
      _loadedFileName = file.name;
      _errorMessage = null;
      _server.broadcastState();
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Failed to load MusicXML: $error';
      notifyListeners();
    }
  }

  Future<void> play() async {
    await _playback.play();
    _server.broadcastState();
  }

  void pause() {
    _playback.pause();
    _server.broadcastState();
  }

  void togglePlayPause() {
    _playback.togglePlayPause();
    _server.broadcastState();
  }

  void jumpToMeasure(int measure) {
    _playback.jumpToMeasure(measure);
    _server.broadcastState();
  }

  void jumpByMeasures(int delta) {
    _playback.jumpByMeasures(delta);
    _server.broadcastState();
  }

  void setTempoPercent(double percent) {
    _playback.setTempoPercent(percent);
    _server.broadcastState();
  }

  void increaseTempo() {
    _playback.increaseTempo();
    _server.broadcastState();
  }

  void decreaseTempo() {
    _playback.decreaseTempo();
    _server.broadcastState();
  }

  void setPartEnabled(ChoirPart part, bool enabled) {
    _playback.setPartEnabled(part, enabled);
    _server.broadcastState();
  }

  void enableAllParts() {
    _playback.setAllPartsEnabled();
    _server.broadcastState();
  }

  void setLoopAAtCurrentMeasure() {
    _playback.setLoopA(_playback.currentMeasure);
    _server.broadcastState();
  }

  void setLoopBAtCurrentMeasure() {
    _playback.setLoopB(_playback.currentMeasure);
    _server.broadcastState();
  }

  void clearLoop() {
    _playback.clearLoop();
    _server.broadcastState();
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
    _server.broadcastState();
    notifyListeners();
  }

  void _handleRemoteCommand(Map<String, dynamic> command) {
    final type = (command['type'] as String?) ?? '';
    switch (type) {
      case 'PLAY':
        unawaited(_playback.play());
        break;
      case 'PAUSE':
        _playback.pause();
        break;
      case 'JUMP_TO_MEASURE':
        final measure = _readInt(command['measure']);
        if (measure != null) {
          _playback.jumpToMeasure(measure);
        }
        break;
      case 'JUMP_RELATIVE':
        final delta = _readInt(command['deltaMeasures']);
        if (delta != null) {
          _playback.jumpByMeasures(delta);
        }
        break;
      case 'SET_TEMPO':
        final percent = _readDouble(command['percent']);
        if (percent != null) {
          _playback.setTempoPercent(percent);
        }
        break;
      case 'SET_PART_ENABLED':
        final partName = command['part'] as String?;
        final enabled = command['enabled'];
        final part = partName == null ? null : choirPartFromId(partName);
        if (part != null && enabled is bool) {
          _playback.setPartEnabled(part, enabled);
        }
        break;
      case 'SET_ALL_PARTS':
        _playback.setAllPartsEnabled();
        break;
      case 'SET_LOOP_A':
        final measure = _readInt(command['measure']);
        if (measure != null) {
          _playback.setLoopA(measure);
        }
        break;
      case 'SET_LOOP_B':
        final measure = _readInt(command['measure']);
        if (measure != null) {
          _playback.setLoopB(measure);
        }
        break;
      case 'CLEAR_LOOP':
        _playback.clearLoop();
        break;
      default:
        return;
    }
    _server.broadcastState();
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
}

