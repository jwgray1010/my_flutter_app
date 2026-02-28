import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'networking.dart';

class RokuRemoteScreen extends StatelessWidget {
  const RokuRemoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('iPhone App')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Choose Mode',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RemoteControlPadScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings_remote),
              label: const Text('Remote Control'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const StationModeScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.school),
              label: const Text('Station Mode'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Station Mode is in-school and locked to one station session.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class RemoteControlPadScreen extends StatefulWidget {
  const RemoteControlPadScreen({super.key});

  @override
  State<RemoteControlPadScreen> createState() => _RemoteControlPadScreenState();
}

class _RemoteControlPadScreenState extends State<RemoteControlPadScreen> {
  final RemoteClient _client = RemoteClient();

  @override
  void initState() {
    super.initState();
    unawaited(_client.restoreAndReconnect());
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _client,
      builder: (context, _) {
        final state = RokuRemoteState.fromMap(_client.latestState);
        final connectedName = _client.pairedProfile?.name ?? 'Not paired';
        return Scaffold(
          appBar: AppBar(
            title: const Text('Remote Control'),
            actions: [
              IconButton(
                onPressed: _openPairScreen,
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Pair Device',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Device: $connectedName'),
                        Text(
                          _client.connectionStatus ?? 'Disconnected',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (state.pieceName.isNotEmpty)
                          Text(
                            state.pieceName,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            Text('Measure ${state.currentMeasure}'),
                            Text('Tempo ${state.tempoPercent}%'),
                            Text(
                              state.loopLabel,
                              style: TextStyle(
                                color: state.loopEnabled || state.loopArmed
                                    ? Colors.greenAccent
                                    : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.8,
                    children: [
                      _BigRemoteButton(
                        label: state.isPlaying ? 'Pause' : 'Play',
                        icon: state.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: state.isPlaying ? Colors.orange : Colors.green,
                        onTap: () => _send('TOGGLE_PLAY'),
                      ),
                      _BigRemoteButton(
                        label: 'Loop',
                        icon: Icons.repeat,
                        color: (state.loopEnabled || state.loopArmed)
                            ? Colors.teal
                            : Colors.blueGrey,
                        onTap: () {
                          if (state.loopEnabled) {
                            _send('CLEAR_LOOP');
                          } else {
                            _send('LOOP_ARM_TOGGLE');
                          }
                        },
                      ),
                      _BigRemoteButton(
                        label: 'Back 2',
                        icon: Icons.skip_previous,
                        onTap: () => _send(
                          'JUMP_RELATIVE',
                          args: const <String, dynamic>{'deltaMeasures': -2},
                        ),
                      ),
                      _BigRemoteButton(
                        label: 'Forward 2',
                        icon: Icons.skip_next,
                        onTap: () => _send(
                          'JUMP_RELATIVE',
                          args: const <String, dynamic>{'deltaMeasures': 2},
                        ),
                      ),
                      _BigRemoteButton(
                        label: 'Tempo -',
                        icon: Icons.remove,
                        onTap: () => _send(
                          'ADJUST_TEMPO_PERCENT',
                          args: const <String, dynamic>{'deltaPercent': -5},
                        ),
                      ),
                      _BigRemoteButton(
                        label: 'Tempo +',
                        icon: Icons.add,
                        onTap: () => _send(
                          'ADJUST_TEMPO_PERCENT',
                          args: const <String, dynamic>{'deltaPercent': 5},
                        ),
                      ),
                      _BigRemoteButton(
                        label: 'Back 4',
                        icon: Icons.fast_rewind,
                        onTap: () => _send(
                          'JUMP_RELATIVE',
                          args: const <String, dynamic>{'deltaMeasures': -4},
                        ),
                      ),
                      _BigRemoteButton(
                        label: 'Forward 4',
                        icon: Icons.fast_forward,
                        onTap: () => _send(
                          'JUMP_RELATIVE',
                          args: const <String, dynamic>{'deltaMeasures': 4},
                        ),
                      ),
                      _BigRemoteButton(
                        label: 'Starting Pitches',
                        icon: Icons.music_note,
                        onTap: () => _send('PLAY_STARTING_PITCHES'),
                      ),
                      _BigRemoteButton(
                        label: 'Pair Device',
                        icon: Icons.link,
                        onTap: _openPairScreen,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => MeasuresRemoteScreen(client: _client),
                            ),
                          );
                        },
                        icon: const Icon(Icons.grid_on),
                        label: const Text('Measures'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PartsRemoteScreen(client: _client),
                            ),
                          );
                        },
                        icon: const Icon(Icons.tune),
                        label: const Text('Parts'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openPairScreen() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PairDeviceScreen(client: _client),
      ),
    );
  }

  void _send(String command, {Map<String, dynamic> args = const <String, dynamic>{}}) {
    _client.sendCommandEnvelope(command, args: args);
  }
}

class StationModeScreen extends StatefulWidget {
  const StationModeScreen({super.key});

  @override
  State<StationModeScreen> createState() => _StationModeScreenState();
}

class _StationModeScreenState extends State<StationModeScreen> {
  final RemoteClient _client = RemoteClient();
  final List<String> _recentNames = <String>[];
  Timer? _tick;

  String? _studentName;
  String? _attemptId;
  bool _isPracticing = false;
  bool _isPlaying = false;
  bool _pianoOn = true;
  bool _loopEnabled = false;
  int _currentMeasure = 1;
  int _tempoPercent = 70;
  int? _loopA;
  int? _loopB;
  int _timeOnTaskSeconds = 0;
  int _loopReps = 0;
  int _tempoMinUsed = 70;
  int _tempoMaxUsed = 70;
  int _measureMinVisited = 1;
  int _measureMaxVisited = 1;
  bool _autoCompletedSent = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _client.restoreAndReconnect();
    if (!mounted) {
      return;
    }
    _registerStationIfConfigured();
    setState(() {});
  }

  @override
  void dispose() {
    _tick?.cancel();
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _client.pairedProfile;
    final configured = profile?.mode == 'station_single';
    final station = StationModeConfig.fromProfile(profile);
    return WillPopScope(
      onWillPop: () => _canReconfigure(station),
      child: AnimatedBuilder(
        animation: _client,
        builder: (context, _) {
          return Scaffold(
          appBar: AppBar(
            title: const Text('Station Mode'),
            actions: [
              IconButton(
                tooltip: 'Configure station',
                onPressed: () => _reconfigureStation(station),
                icon: const Icon(Icons.qr_code_scanner),
              ),
            ],
          ),
          body: !configured
              ? _NotConfiguredStationCard(onScan: () => _reconfigureStation(station))
              : Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        color: const Color(0xFF203047),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                station.stationName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Practice mm.${station.minMeasure}-${station.maxMeasure}',
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _client.connectionStatus ?? 'Disconnected',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (!_isPracticing)
                        _StationHomeCard(
                          recentNames: _recentNames,
                          onStart: (name) => _startStudentAttempt(station, name),
                        ),
                      if (_isPracticing) ...[
                        _StationPracticeHeader(
                          studentName: _studentName ?? '',
                          currentMeasure: _currentMeasure,
                          tempoPercent: _tempoPercent,
                          loopEnabled: _loopEnabled,
                          loopA: _loopA,
                          loopB: _loopB,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _StationControlsCard(
                            station: station,
                            isPlaying: _isPlaying,
                            loopEnabled: _loopEnabled,
                            pianoOn: _pianoOn,
                            onPlayPause: _togglePlayPause,
                            onBack: () => _jumpBy(-station.navStepMeasures, station),
                            onForward: () => _jumpBy(station.navStepMeasures, station),
                            onTempoDown: () => _adjustTempo(-5, station),
                            onTempoUp: () => _adjustTempo(5, station),
                            onLoopToggle: () => _toggleLoop(station),
                            onSetLoopA: () => _setLoopA(station),
                            onSetLoopB: () => _setLoopB(station),
                            onClearLoop: _clearLoop,
                            onPianoToggle: () => _togglePiano(station),
                            onMeasures: station.allowJumpToAnyMeasureInRange
                                ? () => _openMeasureGrid(station)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _finishAttempt(station, completed: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                          ),
                          child: const Text('DONE / NEXT STUDENT'),
                        ),
                      ],
                    ],
                  ),
                ),
          );
        },
      ),
    );
  }

  Future<void> _reconfigureStation(StationModeConfig station) async {
    if (!await _canReconfigure(station)) {
      return;
    }
    final paired = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PairDeviceScreen(
          client: _client,
          requiredMode: 'station_single',
        ),
      ),
    );
    if (paired == true) {
      _registerStationIfConfigured();
      if (mounted) {
        setState(() {
          _resetPracticeState();
        });
      }
    }
  }

  Future<bool> _canReconfigure(StationModeConfig station) async {
    final passcode = station.stationPasscode;
    if (passcode == null || passcode.isEmpty) {
      return true;
    }
    final input = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Station Passcode'),
          content: TextField(
            controller: input,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Enter passcode'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(input.text.trim() == passcode);
              },
              child: const Text('Unlock'),
            ),
          ],
        );
      },
    );
    if (result != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect passcode')),
        );
      }
      return false;
    }
    return true;
  }

  void _registerStationIfConfigured() {
    final station = StationModeConfig.fromProfile(_client.pairedProfile);
    if (!station.isValid) {
      return;
    }
    _client.sendStudentMessage(
      'REGISTER_STATION',
      payload: <String, dynamic>{
        'sessionId': station.sessionId,
        'stationId': station.stationId,
        'stationName': station.stationName,
        'lockedPart': station.lockedPart,
        'deviceId': _client.deviceId,
      },
    );
  }

  void _startStudentAttempt(StationModeConfig station, String name) {
    if (!station.isValid || name.trim().isEmpty) {
      return;
    }
    _registerStationIfConfigured();
    final attemptId = _newAttemptId();
    _studentName = name.trim();
    _attemptId = attemptId;
    _isPracticing = true;
    _isPlaying = false;
    _pianoOn = true;
    _loopEnabled = station.loopDefaultOn;
    _loopA = station.loopDefaultOn ? station.minMeasure : null;
    _loopB = station.loopDefaultOn ? station.maxMeasure : null;
    _currentMeasure = station.minMeasure;
    _tempoPercent = station.defaultTempoPercent;
    _timeOnTaskSeconds = 0;
    _loopReps = 0;
    _tempoMinUsed = _tempoPercent;
    _tempoMaxUsed = _tempoPercent;
    _measureMinVisited = _currentMeasure;
    _measureMaxVisited = _currentMeasure;
    _autoCompletedSent = false;
    _tick?.cancel();

    _recentNames.remove(_studentName);
    _recentNames.insert(0, _studentName!);
    if (_recentNames.length > 6) {
      _recentNames.removeLast();
    }

    _client.sendStudentMessage(
      'JOIN_STATION',
      payload: <String, dynamic>{
        'sessionId': station.sessionId,
        'stationId': station.stationId,
        'studentName': _studentName,
        'lockedPart': station.lockedPart,
        'deviceId': _client.deviceId,
        'attemptId': attemptId,
      },
    );

    _sendLockedMix(station);
    _client.sendCommandEnvelope(
      'SET_TEMPO_PERCENT',
      args: <String, dynamic>{'percent': _tempoPercent},
    );
    _client.sendCommandEnvelope(
      'JUMP_TO_MEASURE',
      args: <String, dynamic>{
        'measure': _currentMeasure,
        'autoPlay': false,
      },
    );
    if (_loopEnabled) {
      _client.sendCommandEnvelope(
        'SET_LOOP_RANGE',
        args: <String, dynamic>{'a': station.minMeasure, 'b': station.maxMeasure},
      );
    } else {
      _client.sendCommandEnvelope('CLEAR_LOOP');
    }
    _sendPracticeEvent('JOIN', station: station);
    setState(() {});
  }

  void _togglePlayPause() {
    if (!_isPracticing) {
      return;
    }
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
      _client.sendCommandEnvelope('PLAY');
      _tick?.cancel();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    } else {
      _client.sendCommandEnvelope('PAUSE');
      _tick?.cancel();
    }
    _sendPracticeEvent(_isPlaying ? 'PLAY' : 'PAUSE');
    setState(() {});
  }

  void _jumpBy(int delta, StationModeConfig station) {
    if (!_isPracticing || !station.navBackForwardAllowed) {
      return;
    }
    final target = _currentMeasure + delta;
    final clamped = _clampMeasure(target, station);
    _currentMeasure = clamped;
    _measureMinVisited = min(_measureMinVisited, _currentMeasure);
    _measureMaxVisited = max(_measureMaxVisited, _currentMeasure);
    _client.sendCommandEnvelope(
      'JUMP_TO_MEASURE',
      args: <String, dynamic>{
        'measure': clamped,
        'autoPlay': _isPlaying,
      },
    );
    if (target != clamped) {
      _showClampToast(station);
    }
    _sendPracticeEvent('JUMP', station: station);
    setState(() {});
  }

  void _adjustTempo(int delta, StationModeConfig station) {
    if (!_isPracticing || !station.allowTempoAdjust) {
      return;
    }
    _tempoPercent = (_tempoPercent + delta).clamp(
      station.tempoMinPercent,
      station.tempoMaxPercent,
    ).toInt();
    _tempoMinUsed = min(_tempoMinUsed, _tempoPercent);
    _tempoMaxUsed = max(_tempoMaxUsed, _tempoPercent);
    _client.sendCommandEnvelope(
      'SET_TEMPO_PERCENT',
      args: <String, dynamic>{'percent': _tempoPercent},
    );
    _sendPracticeEvent('TEMPO', station: station);
    setState(() {});
  }

  void _toggleLoop(StationModeConfig station) {
    if (!_isPracticing) {
      return;
    }
    _loopEnabled = !_loopEnabled;
    if (_loopEnabled) {
      final a = _loopA ?? station.minMeasure;
      final b = _loopB ?? station.maxMeasure;
      _setLoopRange(a, b, station, countRep: false);
    } else {
      _loopA = null;
      _loopB = null;
      _client.sendCommandEnvelope('CLEAR_LOOP');
    }
    _sendPracticeEvent('LOOP', station: station);
    setState(() {});
  }

  void _setLoopA(StationModeConfig station) {
    if (!_isPracticing || !station.allowCustomLoopPoints) {
      return;
    }
    _loopA = _clampMeasure(_currentMeasure, station);
    if (_loopB != null && _loopB! <= _loopA!) {
      final tmp = _loopA;
      _loopA = _loopB;
      _loopB = tmp;
    }
    if (_loopEnabled && _loopA != null && _loopB != null) {
      _setLoopRange(_loopA!, _loopB!, station, countRep: false);
    }
    _sendPracticeEvent('LOOP', station: station);
    setState(() {});
  }

  void _setLoopB(StationModeConfig station) {
    if (!_isPracticing || !station.allowCustomLoopPoints) {
      return;
    }
    _loopB = _clampMeasure(_currentMeasure, station);
    if (_loopA != null && _loopB! <= _loopA!) {
      final tmp = _loopA;
      _loopA = _loopB;
      _loopB = tmp;
    }
    if (_loopEnabled && _loopA != null && _loopB != null) {
      _setLoopRange(_loopA!, _loopB!, station, countRep: false);
    }
    _sendPracticeEvent('LOOP', station: station);
    setState(() {});
  }

  void _setLoopRange(int a, int b, StationModeConfig station, {required bool countRep}) {
    final aa = _clampMeasure(a, station);
    final bb = _clampMeasure(b, station);
    final start = aa <= bb ? aa : bb;
    final end = aa <= bb ? bb : aa;
    _loopA = start;
    _loopB = end;
    _client.sendCommandEnvelope(
      'SET_LOOP_RANGE',
      args: <String, dynamic>{'a': start, 'b': end},
    );
    if (countRep) {
      _loopReps += 1;
    }
  }

  void _clearLoop() {
    if (!_isPracticing) {
      return;
    }
    _loopEnabled = false;
    _loopA = null;
    _loopB = null;
    _client.sendCommandEnvelope('CLEAR_LOOP');
    _sendPracticeEvent('LOOP');
    setState(() {});
  }

  void _togglePiano(StationModeConfig station) {
    if (!_isPracticing) {
      return;
    }
    _pianoOn = !_pianoOn;
    _sendLockedMix(station);
    _sendPracticeEvent('MIX');
    setState(() {});
  }

  Future<void> _openMeasureGrid(StationModeConfig station) async {
    if (!_isPracticing) {
      return;
    }
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        final measures = <int>[
          for (var m = station.minMeasure; m <= station.maxMeasure; m++) m,
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: GridView.builder(
              itemCount: measures.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.8,
              ),
              itemBuilder: (context, index) {
                final measure = measures[index];
                return ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(measure),
                  child: Text('$measure'),
                );
              },
            ),
          ),
        );
      },
    );
    if (selected == null) {
      return;
    }
    _currentMeasure = _clampMeasure(selected, station);
    _measureMinVisited = min(_measureMinVisited, _currentMeasure);
    _measureMaxVisited = max(_measureMaxVisited, _currentMeasure);
    _client.sendCommandEnvelope(
      'JUMP_TO_MEASURE',
      args: <String, dynamic>{
        'measure': _currentMeasure,
        'autoPlay': _isPlaying,
      },
    );
    _sendPracticeEvent('JUMP', station: station);
    setState(() {});
  }

  void _onTick() {
    if (!_isPracticing || !_isPlaying) {
      return;
    }
    final station = StationModeConfig.fromProfile(_client.pairedProfile);
    if (!station.isValid) {
      return;
    }
    _timeOnTaskSeconds += 1;
    if (_timeOnTaskSeconds % 2 == 0) {
      var next = _currentMeasure + 1;
      if (next > station.maxMeasure) {
        if (_loopEnabled) {
          next = _loopA ?? station.minMeasure;
          _loopReps += 1;
        } else {
          next = station.maxMeasure;
          _isPlaying = false;
          _tick?.cancel();
        }
      }
      _currentMeasure = _clampMeasure(next, station);
      _measureMinVisited = min(_measureMinVisited, _currentMeasure);
      _measureMaxVisited = max(_measureMaxVisited, _currentMeasure);
    }

    _sendPracticeEvent(
      'PLAY',
      station: station,
      deltaSeconds: 1,
    );

    if (_timeOnTaskSeconds >= 120 && !_autoCompletedSent) {
      _autoCompletedSent = true;
      _client.sendStudentMessage(
        'PRACTICE_COMPLETED',
        payload: <String, dynamic>{
          'attemptId': _attemptId,
          'studentName': _studentName,
          'stationId': station.stationId,
          'completed': true,
        },
      );
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _finishAttempt(StationModeConfig station, {required bool completed}) {
    if (!_isPracticing || _attemptId == null || _studentName == null) {
      return;
    }
    _tick?.cancel();
    _client.sendStudentMessage(
      'PRACTICE_SUMMARY',
      payload: <String, dynamic>{
        'attemptId': _attemptId,
        'studentName': _studentName,
        'stationId': station.stationId,
        'timeOnTaskSeconds': _timeOnTaskSeconds,
        'measuresVisitedMin': _measureMinVisited,
        'measuresVisitedMax': _measureMaxVisited,
        'loopReps': _loopReps,
        'tempoMinUsed': _tempoMinUsed,
        'tempoMaxUsed': _tempoMaxUsed,
        'completed': completed,
      },
    );
    _client.sendStudentMessage(
      'PRACTICE_COMPLETED',
      payload: <String, dynamic>{
        'attemptId': _attemptId,
        'studentName': _studentName,
        'stationId': station.stationId,
        'completed': completed,
      },
    );
    _resetPracticeState();
    setState(() {});
  }

  void _sendLockedMix(StationModeConfig station) {
    _client.sendCommandEnvelope(
      'SET_PARTS_ENABLED',
      args: <String, dynamic>{
        'partsEnabledSet': <String>[station.lockedPart],
        'pianoEnabled': _pianoOn,
      },
    );
  }

  void _sendPracticeEvent(
    String type, {
    StationModeConfig? station,
    int deltaSeconds = 0,
  }) {
    if (!_isPracticing || _attemptId == null) {
      return;
    }
    final activeStation = station ?? StationModeConfig.fromProfile(_client.pairedProfile);
    if (!activeStation.isValid) {
      return;
    }
    _client.sendStudentMessage(
      'PRACTICE_EVENT',
      payload: <String, dynamic>{
        'attemptId': _attemptId,
        'stationId': activeStation.stationId,
        'event': type,
        'currentMeasure': _currentMeasure,
        'tempoPercent': _tempoPercent,
        'deltaSeconds': deltaSeconds,
        'loopState': <String, dynamic>{
          'enabled': _loopEnabled,
          'a': _loopA,
          'b': _loopB,
        },
      },
    );
  }

  int _clampMeasure(int requested, StationModeConfig station) {
    return requested.clamp(station.minMeasure, station.maxMeasure).toInt();
  }

  void _showClampToast(StationModeConfig station) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text('Locked to mm.${station.minMeasure}-${station.maxMeasure}'),
      ),
    );
  }

  String _newAttemptId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = Random.secure().nextInt(1 << 30);
    return 'attempt_$now$rand';
  }

  void _resetPracticeState() {
    _studentName = null;
    _attemptId = null;
    _isPracticing = false;
    _isPlaying = false;
    _loopEnabled = false;
    _loopA = null;
    _loopB = null;
    _timeOnTaskSeconds = 0;
    _loopReps = 0;
    _autoCompletedSent = false;
  }
}

class MeasuresRemoteScreen extends StatefulWidget {
  const MeasuresRemoteScreen({
    super.key,
    required this.client,
  });

  final RemoteClient client;

  @override
  State<MeasuresRemoteScreen> createState() => _MeasuresRemoteScreenState();
}

class _MeasuresRemoteScreenState extends State<MeasuresRemoteScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<int> _recentMeasures = <int>[];
  bool _byFours = false;
  bool _autoPlayOnJump = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.client,
      builder: (context, _) {
        final state = RokuRemoteState.fromMap(widget.client.latestState);
        final shownMeasures = _byFours
            ? state.measures.where((measure) => (measure - 1) % 4 == 0).toList()
            : state.measures;
        return Scaffold(
          appBar: AppBar(title: const Text('Measures')),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Measure number'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final value = int.tryParse(_searchController.text.trim());
                        if (value == null) {
                          return;
                        }
                        _jumpTo(value);
                      },
                      child: const Text('Go'),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('By 4s'),
                  value: _byFours,
                  onChanged: (value) => setState(() => _byFours = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-Play on Jump'),
                  value: _autoPlayOnJump,
                  onChanged: (value) => setState(() => _autoPlayOnJump = value),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _smallJumpButton(state.currentMeasure, -50),
                    _smallJumpButton(state.currentMeasure, -10),
                    _smallJumpButton(state.currentMeasure, 10),
                    _smallJumpButton(state.currentMeasure, 50),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Recent',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _recentMeasures
                      .map(
                        (measure) => ActionChip(
                          label: Text('$measure'),
                          onPressed: () => _jumpTo(measure),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: shownMeasures.isEmpty
                      ? const Center(child: Text('No measure list yet.'))
                      : GridView.builder(
                          itemCount: shownMeasures.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1.8,
                          ),
                          itemBuilder: (context, index) {
                            final measure = shownMeasures[index];
                            final active = measure == state.currentMeasure;
                            return ElevatedButton(
                              onPressed: () => _jumpTo(measure),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: active ? Colors.teal : null,
                              ),
                              child: Text('$measure'),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _smallJumpButton(int current, int delta) {
    final label = delta > 0 ? '+$delta' : '$delta';
    return ElevatedButton(
      onPressed: () => _jumpTo(current + delta),
      child: Text(label),
    );
  }

  void _jumpTo(int measure) {
    widget.client.sendCommandEnvelope(
      'JUMP_TO_MEASURE',
      args: <String, dynamic>{
        'measure': measure,
        'autoPlay': _autoPlayOnJump,
      },
    );
    _recentMeasures.remove(measure);
    _recentMeasures.insert(0, measure);
    if (_recentMeasures.length > 8) {
      _recentMeasures.removeLast();
    }
    setState(() {});
  }
}

class PartsRemoteScreen extends StatefulWidget {
  const PartsRemoteScreen({
    super.key,
    required this.client,
  });

  final RemoteClient client;

  @override
  State<PartsRemoteScreen> createState() => _PartsRemoteScreenState();
}

class _PartsRemoteScreenState extends State<PartsRemoteScreen> {
  final List<String> _voiceSelectionOrder = <String>[];
  static const List<String> _voiceParts = <String>['SOP', 'ALTO', 'TENOR', 'BASS'];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.client,
      builder: (context, _) {
        final state = RokuRemoteState.fromMap(widget.client.latestState);
        final enabled = state.partsEnabled.toSet();
        _syncVoiceOrder(enabled);
        return Scaffold(
          appBar: AppBar(title: const Text('Parts')),
          body: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () {
                    widget.client.sendCommandEnvelope(
                      'SET_MIX_PRESET',
                      args: const <String, dynamic>{'preset': 'ALL'},
                    );
                    _voiceSelectionOrder.clear();
                  },
                  child: const Text('All'),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _partToggleChip('PIANO', enabled.contains('PIANO')),
                    _partToggleChip('SOP', enabled.contains('SOP')),
                    _partToggleChip('ALTO', enabled.contains('ALTO')),
                    _partToggleChip('TENOR', enabled.contains('TENOR')),
                    _partToggleChip('BASS', enabled.contains('BASS')),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Rule: max two voice parts selected at once.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _partToggleChip(String part, bool selected) {
    final label = switch (part) {
      'PIANO' => 'Piano',
      'SOP' => 'Sop',
      'ALTO' => 'Alto',
      'TENOR' => 'Tenor',
      'BASS' => 'Bass',
      _ => part,
    };
    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: Colors.green,
      onSelected: (_) => _onPartTapped(part),
    );
  }

  void _onPartTapped(String part) {
    final state = RokuRemoteState.fromMap(widget.client.latestState);
    final currentlyEnabled = state.partsEnabled.toSet();
    final voices = currentlyEnabled.where(_voiceParts.contains).toSet();
    var pianoEnabled = currentlyEnabled.contains('PIANO');

    if (part == 'PIANO') {
      pianoEnabled = !pianoEnabled;
    } else {
      if (voices.contains(part)) {
        voices.remove(part);
        _voiceSelectionOrder.remove(part);
      } else {
        if (voices.length >= 2) {
          String? oldest;
          for (final value in _voiceSelectionOrder) {
            if (voices.contains(value)) {
              oldest = value;
              break;
            }
          }
          oldest ??= voices.first;
          voices.remove(oldest);
          _voiceSelectionOrder.remove(oldest);
        }
        voices.add(part);
        _voiceSelectionOrder.remove(part);
        _voiceSelectionOrder.add(part);
      }
    }

    widget.client.sendCommandEnvelope(
      'SET_PARTS_ENABLED',
      args: <String, dynamic>{
        'partsEnabledSet': voices.toList(),
        'pianoEnabled': pianoEnabled,
      },
    );
    setState(() {});
  }

  void _syncVoiceOrder(Set<String> currentEnabled) {
    _voiceSelectionOrder.removeWhere((part) => !currentEnabled.contains(part));
    for (final part in _voiceParts) {
      if (currentEnabled.contains(part) && !_voiceSelectionOrder.contains(part)) {
        _voiceSelectionOrder.add(part);
      }
    }
  }
}

class PairDeviceScreen extends StatefulWidget {
  const PairDeviceScreen({
    super.key,
    required this.client,
    this.requiredMode,
  });

  final RemoteClient client;
  final String? requiredMode;

  @override
  State<PairDeviceScreen> createState() => _PairDeviceScreenState();
}

class _PairDeviceScreenState extends State<PairDeviceScreen> {
  bool _processing = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pair Device')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                if (_processing || capture.barcodes.isEmpty) {
                  return;
                }
                final raw = capture.barcodes.first.rawValue;
                if (raw == null || raw.isEmpty) {
                  return;
                }
                _handleQrPayload(raw);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _message ?? 'Scan QR on iPad Player.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleQrPayload(String raw) async {
    setState(() {
      _processing = true;
      _message = 'Pairing...';
    });
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('Invalid QR payload');
      }
      final map = decoded.cast<String, dynamic>();
      final requiredMode = widget.requiredMode;
      if (requiredMode != null && map['mode']?.toString() != requiredMode) {
        throw FormatException('Expected QR mode "$requiredMode"');
      }
      await widget.client.pairFromPayload(map);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      setState(() {
        _processing = false;
        _message = 'Pairing failed: $error';
      });
    }
  }
}

class _NotConfiguredStationCard extends StatelessWidget {
  const _NotConfiguredStationCard({
    required this.onScan,
  });

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Station not configured',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text('Scan a Station QR from the iPad Teacher setup.'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Station QR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StationHomeCard extends StatelessWidget {
  const _StationHomeCard({
    required this.recentNames,
    required this.onStart,
  });

  final List<String> recentNames;
  final void Function(String name) onStart;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () async {
                final name = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("I'm Starting"),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(labelText: 'Student name'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                          child: const Text('Start'),
                        ),
                      ],
                    );
                  },
                );
                if (name != null && name.trim().isNotEmpty) {
                  onStart(name.trim());
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 70)),
              child: const Text("I'M STARTING"),
            ),
            if (recentNames.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Recent names'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recentNames
                    .map(
                      (name) => ActionChip(
                        label: Text(name),
                        onPressed: () => onStart(name),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StationPracticeHeader extends StatelessWidget {
  const _StationPracticeHeader({
    required this.studentName,
    required this.currentMeasure,
    required this.tempoPercent,
    required this.loopEnabled,
    required this.loopA,
    required this.loopB,
  });

  final String studentName;
  final int currentMeasure;
  final int tempoPercent;
  final bool loopEnabled;
  final int? loopA;
  final int? loopB;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            Text(
              studentName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            Text('Measure $currentMeasure'),
            Text('Tempo $tempoPercent%'),
            Text(
              loopEnabled
                  ? 'Loop ${loopA?.toString() ?? '-'}-${loopB?.toString() ?? '-'}'
                  : 'Loop Off',
            ),
          ],
        ),
      ),
    );
  }
}

class _StationControlsCard extends StatelessWidget {
  const _StationControlsCard({
    required this.station,
    required this.isPlaying,
    required this.loopEnabled,
    required this.pianoOn,
    required this.onPlayPause,
    required this.onBack,
    required this.onForward,
    required this.onTempoDown,
    required this.onTempoUp,
    required this.onLoopToggle,
    required this.onSetLoopA,
    required this.onSetLoopB,
    required this.onClearLoop,
    required this.onPianoToggle,
    this.onMeasures,
  });

  final StationModeConfig station;
  final bool isPlaying;
  final bool loopEnabled;
  final bool pianoOn;
  final VoidCallback onPlayPause;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onTempoDown;
  final VoidCallback onTempoUp;
  final VoidCallback onLoopToggle;
  final VoidCallback onSetLoopA;
  final VoidCallback onSetLoopB;
  final VoidCallback onClearLoop;
  final VoidCallback onPianoToggle;
  final VoidCallback? onMeasures;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _BigRemoteButton(
            label: isPlaying ? 'Pause' : 'Play',
            icon: isPlaying ? Icons.pause : Icons.play_arrow,
            color: isPlaying ? Colors.orange : Colors.green,
            onTap: onPlayPause,
          ),
          _BigRemoteButton(
            label: 'Back ${station.navStepMeasures}',
            icon: Icons.skip_previous,
            onTap: onBack,
          ),
          _BigRemoteButton(
            label: 'Forward ${station.navStepMeasures}',
            icon: Icons.skip_next,
            onTap: onForward,
          ),
          _BigRemoteButton(
            label: 'Tempo -',
            icon: Icons.remove,
            onTap: station.allowTempoAdjust ? onTempoDown : () {},
            color: station.allowTempoAdjust ? null : Colors.blueGrey,
          ),
          _BigRemoteButton(
            label: 'Tempo +',
            icon: Icons.add,
            onTap: station.allowTempoAdjust ? onTempoUp : () {},
            color: station.allowTempoAdjust ? null : Colors.blueGrey,
          ),
          _BigRemoteButton(
            label: loopEnabled ? 'Loop On' : 'Loop Off',
            icon: Icons.repeat,
            onTap: onLoopToggle,
          ),
          _BigRemoteButton(
            label: 'Set Loop A',
            icon: Icons.looks_one,
            onTap: station.allowCustomLoopPoints ? onSetLoopA : () {},
            color: station.allowCustomLoopPoints ? null : Colors.blueGrey,
          ),
          _BigRemoteButton(
            label: 'Set Loop B',
            icon: Icons.looks_two,
            onTap: station.allowCustomLoopPoints ? onSetLoopB : () {},
            color: station.allowCustomLoopPoints ? null : Colors.blueGrey,
          ),
          _BigRemoteButton(
            label: 'Clear Loop',
            icon: Icons.clear,
            onTap: onClearLoop,
          ),
          _BigRemoteButton(
            label: pianoOn ? 'Piano On' : 'Piano Off',
            icon: Icons.piano,
            onTap: onPianoToggle,
          ),
          if (onMeasures != null)
            _BigRemoteButton(
              label: 'Measures',
              icon: Icons.grid_view,
              onTap: onMeasures!,
            ),
        ],
      ),
    );
  }
}

class _BigRemoteButton extends StatelessWidget {
  const _BigRemoteButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(240, 70),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      label: Text(label, style: const TextStyle(fontSize: 20)),
    );
  }
}

class StationModeConfig {
  StationModeConfig({
    required this.mode,
    required this.sessionId,
    required this.stationId,
    required this.stationName,
    required this.lockedPart,
    required this.minMeasure,
    required this.maxMeasure,
    required this.defaultTempoPercent,
    required this.loopDefaultOn,
    required this.allowTempoAdjust,
    required this.tempoMinPercent,
    required this.tempoMaxPercent,
    required this.allowCustomLoopPoints,
    required this.navBackForwardAllowed,
    required this.navStepMeasures,
    required this.allowJumpToAnyMeasureInRange,
    required this.lockRangeStrict,
    this.stationPasscode,
  });

  final String mode;
  final String sessionId;
  final String stationId;
  final String stationName;
  final String lockedPart;
  final int minMeasure;
  final int maxMeasure;
  final int defaultTempoPercent;
  final bool loopDefaultOn;
  final bool allowTempoAdjust;
  final int tempoMinPercent;
  final int tempoMaxPercent;
  final bool allowCustomLoopPoints;
  final bool navBackForwardAllowed;
  final int navStepMeasures;
  final bool allowJumpToAnyMeasureInRange;
  final bool lockRangeStrict;
  final String? stationPasscode;

  bool get isValid => mode == 'station_single' && sessionId.isNotEmpty && stationId.isNotEmpty;

  factory StationModeConfig.fromProfile(PlayerPairingProfile? profile) {
    final practice = profile?.practice ?? const <String, dynamic>{};
    final rawStart = _toInt(practice['startMeasure']) ?? 1;
    final rawEnd = _toInt(practice['endMeasure']) ?? 8;
    final minMeasure = rawStart <= rawEnd ? rawStart : rawEnd;
    final maxMeasure = rawStart <= rawEnd ? rawEnd : rawStart;
    return StationModeConfig(
      mode: profile?.mode ?? '',
      sessionId: profile?.sessionId ?? '',
      stationId: profile?.stationId ?? '',
      stationName: profile?.stationName ?? 'Station',
      lockedPart: profile?.lockedPart ?? 'ALTO',
      minMeasure: minMeasure,
      maxMeasure: maxMeasure,
      defaultTempoPercent: _toInt(practice['defaultTempoPercent']) ?? 70,
      loopDefaultOn: practice['loopDefaultOn'] != false,
      allowTempoAdjust: practice['allowTempoAdjust'] != false,
      tempoMinPercent: _toInt(practice['tempoMinPercent']) ?? 50,
      tempoMaxPercent: _toInt(practice['tempoMaxPercent']) ?? 100,
      allowCustomLoopPoints: practice['allowCustomLoopPoints'] != false,
      navBackForwardAllowed: practice['navBackForwardAllowed'] != false,
      navStepMeasures: _toInt(practice['navStepMeasures']) ?? 2,
      allowJumpToAnyMeasureInRange: practice['allowJumpToAnyMeasureInRange'] != false,
      lockRangeStrict: practice['lockRangeStrict'] != false,
      stationPasscode: profile?.stationPasscode,
    );
  }
}

class RokuRemoteState {
  RokuRemoteState({
    required this.pieceName,
    required this.isPlaying,
    required this.currentMeasure,
    required this.tempoPercent,
    required this.loopEnabled,
    required this.loopArmed,
    required this.loopA,
    required this.loopB,
    required this.partsEnabled,
    required this.measures,
  });

  final String pieceName;
  final bool isPlaying;
  final int currentMeasure;
  final int tempoPercent;
  final bool loopEnabled;
  final bool loopArmed;
  final int? loopA;
  final int? loopB;
  final Set<String> partsEnabled;
  final List<int> measures;

  String get loopLabel {
    if (loopEnabled) {
      return 'Loop $loopA-$loopB';
    }
    if (loopArmed) {
      return 'Loop Armed';
    }
    return 'Loop Off';
  }

  factory RokuRemoteState.fromMap(Map<String, dynamic>? raw) {
    if (raw == null) {
      return RokuRemoteState.empty();
    }
    final loopRaw = raw['loop'];
    final loop = loopRaw is Map ? loopRaw.cast<String, dynamic>() : <String, dynamic>{};
    final partsRaw = raw['partsEnabled'];
    final measuresRaw = raw['measures'];
    return RokuRemoteState(
      pieceName: raw['pieceName']?.toString() ?? '',
      isPlaying: raw['isPlaying'] == true,
      currentMeasure: _toInt(raw['currentMeasure']) ?? 1,
      tempoPercent: _toInt(raw['tempoPercent']) ?? 100,
      loopEnabled: loop['enabled'] == true,
      loopArmed: loop['armed'] == true,
      loopA: _toInt(loop['a']),
      loopB: _toInt(loop['b']),
      partsEnabled: partsRaw is List
          ? partsRaw.map((entry) => entry.toString().toUpperCase()).toSet()
          : <String>{},
      measures: measuresRaw is List
          ? measuresRaw.map(_toInt).whereType<int>().toList()
          : <int>[],
    );
  }

  factory RokuRemoteState.empty() => RokuRemoteState(
    pieceName: '',
    isPlaying: false,
    currentMeasure: 1,
    tempoPercent: 100,
    loopEnabled: false,
    loopArmed: false,
    loopA: null,
    loopB: null,
    partsEnabled: const <String>{'SOP', 'ALTO', 'TENOR', 'BASS', 'PIANO'},
    measures: const <int>[],
  );
}

int? _toInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

