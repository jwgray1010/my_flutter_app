import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'networking.dart';

class RokuRemoteScreen extends StatelessWidget {
  const RokuRemoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _RokuTokens.bg,
      appBar: AppBar(
        backgroundColor: _RokuTokens.bg,
        title: const Text('PHONE APP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 18),
            const Text(
              'Choose Mode',
              textAlign: TextAlign.center,
              style: _RokuTokens.title,
            ),
            const SizedBox(height: 22),
            _RokuButton(
              label: 'REMOTE CONTROL',
              height: 92,
              accent: true,
              onPressed: () {
                _tapHaptic();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RemoteControlPadScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _RokuButton(
              label: 'STATION MODE',
              height: 92,
              onPressed: () {
                _tapHaptic();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const StationModeScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            const Text(
              'Station Mode is locked to one in-school station session.',
              textAlign: TextAlign.center,
              style: _RokuTokens.smallLabel,
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
        final connected = _client.isConnected;
        final hasPairing = _client.pairedProfile != null;
        return Scaffold(
          backgroundColor: _RokuTokens.bg,
          appBar: AppBar(
            backgroundColor: _RokuTokens.bg,
            title: const Text('REMOTE'),
            actions: [
              TextButton(
                onPressed: _openPairScreen,
                child: const Text(
                  'PAIR',
                  style: TextStyle(color: _RokuTokens.textPrimary),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusStrip(
                    connected: connected,
                    currentMeasure: state.currentMeasure,
                    tempoPercent: state.tempoPercent,
                    showLoop: state.loopEnabled || state.loopArmed,
                    disconnectedText: 'Disconnected',
                  ),
                  const SizedBox(height: 16),
                  if (!hasPairing) ...[
                    _RokuButton(
                      label: 'PAIR REMOTE',
                      height: 86,
                      accent: true,
                      onPressed: _openPairScreen,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (hasPairing && !connected) ...[
                    _RokuButton(
                      label: _client.isConnecting ? 'RECONNECTING...' : 'RECONNECT',
                      height: 86,
                      accent: true,
                      onPressed: _client.isConnecting
                          ? null
                          : () async {
                              _tapHaptic();
                              await _client.connectPaired();
                            },
                    ),
                    const SizedBox(height: 16),
                  ],
                  _RokuButton(
                    label: state.isPlaying ? 'PAUSE' : 'PLAY',
                    height: 108,
                    accent: true,
                    onPressed: connected ? () => _send('TOGGLE_PLAY') : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _RokuButton(
                          label: 'BACK 2',
                          height: 82,
                          onPressed: connected
                              ? () => _send(
                                  'JUMP_RELATIVE',
                                  args: const <String, dynamic>{'deltaMeasures': -2},
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _RokuButton(
                          label: 'FWD 2',
                          height: 82,
                          onPressed: connected
                              ? () => _send(
                                  'JUMP_RELATIVE',
                                  args: const <String, dynamic>{'deltaMeasures': 2},
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _RokuButton(
                          label: 'TEMPO -',
                          height: 82,
                          onPressed: connected
                              ? () => _send(
                                  'ADJUST_TEMPO_PERCENT',
                                  args: const <String, dynamic>{'deltaPercent': -5},
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _RokuButton(
                          label: 'TEMPO +',
                          height: 82,
                          onPressed: connected
                              ? () => _send(
                                  'ADJUST_TEMPO_PERCENT',
                                  args: const <String, dynamic>{'deltaPercent': 5},
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.tempoPercent}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: _RokuTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _RokuButton(
                    label: 'LOOP',
                    height: 82,
                    selected: state.loopEnabled || state.loopArmed,
                    onPressed: connected
                        ? () {
                            if (state.loopEnabled) {
                              _send('CLEAR_LOOP');
                              return;
                            }
                            _send('LOOP_ARM_TOGGLE');
                          }
                        : null,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _RokuButton(
                          label: 'MEASURES',
                          height: 68,
                          outlined: true,
                          onPressed: () {
                            _tapHaptic();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => MeasuresRemoteScreen(client: _client),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _RokuButton(
                          label: 'PARTS',
                          height: 68,
                          outlined: true,
                          onPressed: () {
                            _tapHaptic();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PartsRemoteScreen(client: _client),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

  void _send(
    String command, {
    Map<String, dynamic> args = const <String, dynamic>{},
  }) {
    _tapHaptic();
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
  int? _lastLoopMeasure;

  @override
  void initState() {
    super.initState();
    _client.addListener(_syncFromPlayerState);
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
    _client.removeListener(_syncFromPlayerState);
    _tick?.cancel();
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _client.pairedProfile;
    final configured = profile?.mode == 'station_single';
    final station = StationModeConfig.fromProfile(profile);
    final remoteState = RokuRemoteState.fromMap(_client.latestState);
    final displayMeasure = _isPracticing && _client.isConnected
        ? _clampMeasure(remoteState.currentMeasure, station)
        : _currentMeasure;
    final displayTempo = _isPracticing && _client.isConnected
        ? remoteState.tempoPercent
        : _tempoPercent;
    final displayLoop = _isPracticing && _client.isConnected
        ? remoteState.loopEnabled
        : _loopEnabled;

    return WillPopScope(
      onWillPop: () => _canReconfigure(station),
      child: AnimatedBuilder(
        animation: _client,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: _RokuTokens.bg,
            appBar: AppBar(
              backgroundColor: _RokuTokens.bg,
              title: const Text('STATION MODE'),
              actions: [
                TextButton(
                  onPressed: () => _reconfigureStation(station),
                  child: const Text(
                    'SCAN QR',
                    style: TextStyle(color: _RokuTokens.textPrimary),
                  ),
                ),
              ],
            ),
            body: !configured
                ? _NotConfiguredStationCard(
                    onScan: () => _reconfigureStation(station),
                  )
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            station.stationName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: _RokuTokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Practice mm.${station.minMeasure}-${station.maxMeasure}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: _RokuTokens.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _StatusStrip(
                            connected: _client.isConnected,
                            currentMeasure: displayMeasure,
                            tempoPercent: displayTempo,
                            showLoop: displayLoop,
                            disconnectedText: 'Disconnected',
                          ),
                          const SizedBox(height: 16),
                          if (!_isPracticing)
                            _StationHomePanel(
                              recentNames: _recentNames,
                              onStart: (name) => _startStudentAttempt(station, name),
                            ),
                          if (_isPracticing) ...[
                            _RokuButton(
                              label: _isPlaying ? 'PAUSE' : 'PLAY',
                              height: 108,
                              accent: true,
                              onPressed: _togglePlayPause,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _RokuButton(
                                    label: 'BACK ${station.navStepMeasures}',
                                    height: 82,
                                    onPressed: () =>
                                        _jumpBy(-station.navStepMeasures, station),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _RokuButton(
                                    label: 'FWD ${station.navStepMeasures}',
                                    height: 82,
                                    onPressed: () => _jumpBy(station.navStepMeasures, station),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _RokuButton(
                                    label: 'TEMPO -',
                                    height: 82,
                                    onPressed: station.allowTempoAdjust
                                        ? () => _adjustTempo(-5, station)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _RokuButton(
                                    label: 'TEMPO +',
                                    height: 82,
                                    onPressed: station.allowTempoAdjust
                                        ? () => _adjustTempo(5, station)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$displayTempo%',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: _RokuTokens.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _RokuButton(
                              label: 'LOOP',
                              height: 82,
                              selected: displayLoop,
                              onPressed: () => _toggleLoop(station),
                            ),
                            if (station.allowCustomLoopPoints) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _RokuButton(
                                      label: 'SET A',
                                      height: 60,
                                      onPressed: () => _setLoopA(station),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _RokuButton(
                                      label: 'SET B',
                                      height: 60,
                                      onPressed: () => _setLoopB(station),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _RokuButton(
                                      label: 'CLEAR',
                                      height: 60,
                                      onPressed: _clearLoop,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const Spacer(),
                            _RokuButton(
                              label: 'DONE / NEXT STUDENT',
                              height: 84,
                              outlined: true,
                              onPressed: () => _finishAttempt(station, completed: true),
                            ),
                          ],
                        ],
                      ),
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
        setState(_resetPracticeState);
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
          backgroundColor: _RokuTokens.card,
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
              onPressed: () => Navigator.of(context).pop(input.text.trim() == passcode),
              child: const Text('Unlock'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      return true;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect passcode')),
      );
    }
    return false;
  }

  void _syncFromPlayerState() {
    if (!_isPracticing) {
      return;
    }
    final station = StationModeConfig.fromProfile(_client.pairedProfile);
    if (!station.isValid || !_client.isConnected) {
      return;
    }
    final remote = RokuRemoteState.fromMap(_client.latestState);
    final resolvedMeasure = _clampMeasure(remote.currentMeasure, station);
    if (remote.loopEnabled && _lastLoopMeasure != null && resolvedMeasure < _lastLoopMeasure!) {
      _loopReps += 1;
    }
    _currentMeasure = resolvedMeasure;
    _tempoPercent = remote.tempoPercent;
    _isPlaying = remote.isPlaying;
    _loopEnabled = remote.loopEnabled;
    _loopA = remote.loopA;
    _loopB = remote.loopB;
    _lastLoopMeasure = resolvedMeasure;

    _measureMinVisited = min(_measureMinVisited, resolvedMeasure);
    _measureMaxVisited = max(_measureMaxVisited, resolvedMeasure);
    _tempoMinUsed = min(_tempoMinUsed, _tempoPercent);
    _tempoMaxUsed = max(_tempoMaxUsed, _tempoPercent);
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
    final trimmed = name.trim();
    if (!station.isValid || trimmed.isEmpty) {
      return;
    }
    _tapHaptic();
    _registerStationIfConfigured();
    final attemptId = _newAttemptId();
    _studentName = trimmed;
    _attemptId = attemptId;
    _isPracticing = true;
    _isPlaying = false;
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
    _lastLoopMeasure = _currentMeasure;
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
      args: <String, dynamic>{'measure': _currentMeasure, 'autoPlay': false},
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
    _tapHaptic();
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
    _tapHaptic();
    final target = _currentMeasure + delta;
    final clamped = _clampMeasure(target, station);
    _currentMeasure = clamped;
    _measureMinVisited = min(_measureMinVisited, _currentMeasure);
    _measureMaxVisited = max(_measureMaxVisited, _currentMeasure);
    _client.sendCommandEnvelope(
      'JUMP_TO_MEASURE',
      args: <String, dynamic>{'measure': clamped, 'autoPlay': _isPlaying},
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
    _tapHaptic();
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
    _tapHaptic();
    _loopEnabled = !_loopEnabled;
    if (_loopEnabled) {
      final a = _loopA ?? station.minMeasure;
      final b = _loopB ?? station.maxMeasure;
      _setLoopRange(a, b, station);
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
    _tapHaptic();
    _loopA = _clampMeasure(_currentMeasure, station);
    if (_loopB != null && _loopB! <= _loopA!) {
      final tmp = _loopA;
      _loopA = _loopB;
      _loopB = tmp;
    }
    if (_loopEnabled && _loopA != null && _loopB != null) {
      _setLoopRange(_loopA!, _loopB!, station);
    }
    _sendPracticeEvent('LOOP', station: station);
    setState(() {});
  }

  void _setLoopB(StationModeConfig station) {
    if (!_isPracticing || !station.allowCustomLoopPoints) {
      return;
    }
    _tapHaptic();
    _loopB = _clampMeasure(_currentMeasure, station);
    if (_loopA != null && _loopB! <= _loopA!) {
      final tmp = _loopA;
      _loopA = _loopB;
      _loopB = tmp;
    }
    if (_loopEnabled && _loopA != null && _loopB != null) {
      _setLoopRange(_loopA!, _loopB!, station);
    }
    _sendPracticeEvent('LOOP', station: station);
    setState(() {});
  }

  void _setLoopRange(int a, int b, StationModeConfig station) {
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
  }

  void _clearLoop() {
    if (!_isPracticing) {
      return;
    }
    _tapHaptic();
    _loopEnabled = false;
    _loopA = null;
    _loopB = null;
    _client.sendCommandEnvelope('CLEAR_LOOP');
    _sendPracticeEvent('LOOP');
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
    _syncFromPlayerState();
    _timeOnTaskSeconds += 1;
    _sendPracticeEvent('PLAY', station: station, deltaSeconds: 1);

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
    _tapHaptic();
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 1),
        content: Text('Saved. Next student.'),
      ),
    );
  }

  void _sendLockedMix(StationModeConfig station) {
    _client.sendCommandEnvelope(
      'SET_PARTS_ENABLED',
      args: <String, dynamic>{
        'partsEnabledSet': <String>[station.lockedPart],
        'pianoEnabled': true,
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
    _lastLoopMeasure = null;
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
          backgroundColor: _RokuTokens.bg,
          appBar: AppBar(
            backgroundColor: _RokuTokens.bg,
            leadingWidth: 108,
            leading: TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text(
                '< Remote',
                style: TextStyle(color: _RokuTokens.textPrimary),
              ),
            ),
            title: const Text('MEASURES'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 56,
                  child: TextField(
                    controller: _searchController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _RokuTokens.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Go to measure...',
                      hintStyle: const TextStyle(color: _RokuTokens.textSecondary),
                      filled: true,
                      fillColor: _RokuTokens.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: _RokuTokens.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: _RokuTokens.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: _RokuTokens.accent),
                      ),
                      suffixIcon: TextButton(
                        onPressed: () {
                          final value = int.tryParse(_searchController.text.trim());
                          if (value == null) {
                            return;
                          }
                          _jumpTo(value);
                        },
                        child: const Text('GO'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _RokuPillToggle(
                      label: 'BY 4s',
                      value: _byFours,
                      onChanged: (value) {
                        _tapHaptic();
                        setState(() => _byFours = value);
                      },
                    ),
                    const SizedBox(width: 12),
                    _RokuPillToggle(
                      label: 'AUTO PLAY',
                      value: _autoPlayOnJump,
                      onChanged: (value) {
                        _tapHaptic();
                        setState(() => _autoPlayOnJump = value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _quickJump(state.currentMeasure, -50),
                    _quickJump(state.currentMeasure, -10),
                    _quickJump(state.currentMeasure, 10),
                    _quickJump(state.currentMeasure, 50),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Recent', style: _RokuTokens.status),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentMeasures.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final measure = _recentMeasures[index];
                      return _RokuChipButton(
                        label: '$measure',
                        onPressed: () => _jumpTo(measure),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: shownMeasures.isEmpty
                      ? const Center(
                          child: Text(
                            'No measure list yet.',
                            style: _RokuTokens.statusSecondary,
                          ),
                        )
                      : GridView.builder(
                          itemCount: shownMeasures.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                          itemBuilder: (context, index) {
                            final measure = shownMeasures[index];
                            final active = measure == state.currentMeasure;
                            return _RokuMeasureCell(
                              measure: measure,
                              active: active,
                              onPressed: () => _jumpTo(measure),
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

  Widget _quickJump(int current, int delta) {
    final label = delta > 0 ? '+$delta' : '$delta';
    return _RokuChipButton(
      label: label,
      onPressed: () => _jumpTo(current + delta),
    );
  }

  void _jumpTo(int measure) {
    _tapHaptic();
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
          backgroundColor: _RokuTokens.bg,
          appBar: AppBar(
            backgroundColor: _RokuTokens.bg,
            leadingWidth: 108,
            leading: TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text(
                '< Remote',
                style: TextStyle(color: _RokuTokens.textPrimary),
              ),
            ),
            title: const Text('PARTS'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RokuButton(
                  label: 'ALL',
                  height: 78,
                  selected: enabled.containsAll(_voiceParts) && enabled.contains('PIANO'),
                  onPressed: () {
                    _tapHaptic();
                    widget.client.sendCommandEnvelope(
                      'SET_MIX_PRESET',
                      args: const <String, dynamic>{'preset': 'ALL'},
                    );
                    _voiceSelectionOrder.clear();
                  },
                ),
                const SizedBox(height: 12),
                _RokuButton(
                  label: 'PIANO',
                  height: 78,
                  selected: enabled.contains('PIANO'),
                  onPressed: () => _onPartTapped('PIANO'),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.1,
                    children: [
                      _RokuButton(
                        label: 'SOPRANO',
                        height: 78,
                        selected: enabled.contains('SOP'),
                        onPressed: () => _onPartTapped('SOP'),
                      ),
                      _RokuButton(
                        label: 'ALTO',
                        height: 78,
                        selected: enabled.contains('ALTO'),
                        onPressed: () => _onPartTapped('ALTO'),
                      ),
                      _RokuButton(
                        label: 'TENOR',
                        height: 78,
                        selected: enabled.contains('TENOR'),
                        onPressed: () => _onPartTapped('TENOR'),
                      ),
                      _RokuButton(
                        label: 'BASS',
                        height: 78,
                        selected: enabled.contains('BASS'),
                        onPressed: () => _onPartTapped('BASS'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select up to two parts.',
                  textAlign: TextAlign.center,
                  style: _RokuTokens.smallLabel,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onPartTapped(String part) {
    _tapHaptic();
    final state = RokuRemoteState.fromMap(widget.client.latestState);
    final currentlyEnabled = state.partsEnabled.toSet();
    final voices = currentlyEnabled.where(_voiceParts.contains).toSet();
    var pianoEnabled = currentlyEnabled.contains('PIANO');

    if (part == 'PIANO') {
      pianoEnabled = !pianoEnabled;
    } else if (voices.contains(part)) {
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
  bool _showScanner = false;
  bool _processing = false;
  String? _message;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final title = widget.requiredMode == 'station_single' ? 'PAIR STATION' : 'PAIR REMOTE';
    return Scaffold(
      backgroundColor: _RokuTokens.bg,
      appBar: AppBar(
        backgroundColor: _RokuTokens.bg,
        title: Text(title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _showScanner ? _buildScannerView() : _buildPairStartView(),
        ),
      ),
    );
  }

  Widget _buildPairStartView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Text(
          widget.requiredMode == 'station_single' ? 'PAIR STATION' : 'PAIR REMOTE',
          textAlign: TextAlign.center,
          style: _RokuTokens.title,
        ),
        const SizedBox(height: 16),
        const Text(
          'Scan the QR shown on the iPad Player.',
          textAlign: TextAlign.center,
          style: _RokuTokens.statusSecondary,
        ),
        const SizedBox(height: 22),
        _RokuButton(
          label: 'SCAN QR',
          height: 102,
          accent: true,
          onPressed: () {
            _tapHaptic();
            setState(() {
              _showScanner = true;
              _processing = false;
              _error = null;
              _message = 'Point camera at QR code.';
            });
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _RokuTokens.danger,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _RokuButton(
            label: 'TRY AGAIN',
            height: 72,
            onPressed: () {
              _tapHaptic();
              setState(() {
                _error = null;
                _showScanner = true;
                _message = 'Point camera at QR code.';
              });
            },
          ),
        ],
        const Spacer(),
      ],
    );
  }

  Widget _buildScannerView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 380,
            child: MobileScanner(
              onDetect: (capture) {
                if (_processing || capture.barcodes.isEmpty) {
                  return;
                }
                final raw = capture.barcodes.first.rawValue;
                if (raw == null || raw.isEmpty) {
                  return;
                }
                unawaited(_handleQrPayload(raw));
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _message ?? 'Point camera at QR code.',
          textAlign: TextAlign.center,
          style: _RokuTokens.statusSecondary,
        ),
        const SizedBox(height: 12),
        _RokuButton(
          label: _processing ? 'CONNECTING...' : 'CANCEL',
          height: 70,
          outlined: true,
          onPressed: _processing
              ? null
              : () {
                  _tapHaptic();
                  setState(() {
                    _showScanner = false;
                    _message = null;
                  });
                },
        ),
      ],
    );
  }

  Future<void> _handleQrPayload(String raw) async {
    setState(() {
      _processing = true;
      _message = 'Connecting...';
      _error = null;
    });
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('Invalid QR payload');
      }
      final map = decoded.cast<String, dynamic>();
      final requiredMode = widget.requiredMode;
      if (requiredMode != null && map['mode']?.toString() != requiredMode) {
        throw FormatException('Expected $requiredMode QR.');
      }
      await widget.client.pairFromPayload(map);
      final connected = await _waitForConnection();
      if (!connected) {
        throw const FormatException(
          'Player not found. Make sure both devices are on the same Wi-Fi.',
        );
      }
      _successHaptic();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _processing = false;
        _showScanner = false;
        _message = null;
        _error = 'Player not found. Make sure both devices are on the same Wi-Fi.';
      });
    }
  }

  Future<bool> _waitForConnection() async {
    final deadline = DateTime.now().add(const Duration(seconds: 4));
    while (DateTime.now().isBefore(deadline)) {
      if (widget.client.isConnected) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return widget.client.isConnected;
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
      child: Container(
        decoration: BoxDecoration(
          color: _RokuTokens.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _RokuTokens.border),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Station not configured',
              style: _RokuTokens.title,
            ),
            const SizedBox(height: 10),
            const Text(
              'Scan a Station QR from the iPad Teacher setup.',
              textAlign: TextAlign.center,
              style: _RokuTokens.statusSecondary,
            ),
            const SizedBox(height: 16),
            _RokuButton(
              label: 'SCAN STATION QR',
              height: 92,
              accent: true,
              onPressed: onScan,
            ),
          ],
        ),
      ),
    );
  }
}

class _StationHomePanel extends StatelessWidget {
  const _StationHomePanel({
    required this.recentNames,
    required this.onStart,
  });

  final List<String> recentNames;
  final void Function(String name) onStart;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RokuButton(
            label: "I'M STARTING",
            height: 110,
            accent: true,
            onPressed: () async {
              final name = await _promptStudentName(context);
              if (name != null && name.trim().isNotEmpty) {
                onStart(name.trim());
              }
            },
          ),
          if (recentNames.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Recent names', style: _RokuTokens.status),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentNames
                  .map(
                    (name) => _RokuChipButton(
                      label: name,
                      onPressed: () => onStart(name),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Future<String?> _promptStudentName(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _RokuTokens.card,
          title: const Text("I'm Starting"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Student name',
              hintText: 'First + last initial',
            ),
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
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({
    required this.connected,
    required this.currentMeasure,
    required this.tempoPercent,
    required this.showLoop,
    required this.disconnectedText,
  });

  final bool connected;
  final int currentMeasure;
  final int tempoPercent;
  final bool showLoop;
  final String disconnectedText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _RokuTokens.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: connected ? _RokuTokens.success : _RokuTokens.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          if (connected) ...[
            Text('m. $currentMeasure', style: _RokuTokens.status),
            const SizedBox(width: 16),
            Text('$tempoPercent%', style: _RokuTokens.status),
            const SizedBox(width: 12),
            if (showLoop)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _RokuTokens.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Loop',
                  style: TextStyle(
                    color: _RokuTokens.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ] else ...[
            Text(disconnectedText, style: _RokuTokens.statusSecondary),
          ],
        ],
      ),
    );
  }
}

class _RokuButton extends StatelessWidget {
  const _RokuButton({
    required this.label,
    required this.height,
    required this.onPressed,
    this.accent = false,
    this.selected = false,
    this.outlined = false,
  });

  final String label;
  final double height;
  final VoidCallback? onPressed;
  final bool accent;
  final bool selected;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final background = !enabled
        ? _RokuTokens.card.withOpacity(0.45)
        : (accent || selected)
            ? _RokuTokens.accent
            : _RokuTokens.card;
    final border = outlined || (!accent && !selected)
        ? const BorderSide(color: _RokuTokens.border)
        : BorderSide.none;
    return SizedBox(
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: _RokuTokens.textPrimary,
          disabledBackgroundColor: _RokuTokens.card.withOpacity(0.45),
          disabledForegroundColor: _RokuTokens.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_RokuTokens.radius),
            side: border,
          ),
          textStyle: _RokuTokens.buttonLabel,
          minimumSize: const Size(80, 60),
          elevation: 0,
        ).copyWith(
          overlayColor: MaterialStatePropertyAll(
            _RokuTokens.textPrimary.withOpacity(0.08),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _RokuChipButton extends StatelessWidget {
  const _RokuChipButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _RokuTokens.card,
          foregroundColor: _RokuTokens.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _RokuTokens.border),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () {
          _tapHaptic();
          onPressed();
        },
        child: Text(label),
      ),
    );
  }
}

class _RokuMeasureCell extends StatelessWidget {
  const _RokuMeasureCell({
    required this.measure,
    required this.active,
    required this.onPressed,
  });

  final int measure;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? _RokuTokens.accent : _RokuTokens.card,
        foregroundColor: _RokuTokens.textPrimary,
        elevation: 0,
        minimumSize: const Size(70, 70),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _RokuTokens.border),
        ),
      ),
      onPressed: () {
        _tapHaptic();
        onPressed();
      },
      child: Text(
        '$measure',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RokuPillToggle extends StatelessWidget {
  const _RokuPillToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: value ? _RokuTokens.accent : _RokuTokens.card,
          foregroundColor: _RokuTokens.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: const BorderSide(color: _RokuTokens.border),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () => onChanged(!value),
        child: Text(label),
      ),
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

class _RokuTokens {
  static const Color bg = Color(0xFF15181D);
  static const Color card = Color(0xFF1E232B);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color.fromRGBO(255, 255, 255, 0.70);
  static const Color border = Color.fromRGBO(255, 255, 255, 0.12);
  static const Color accent = Color(0xFF6E5BFF);
  static const Color danger = Color(0xFFFF4D4D);
  static const Color success = Color(0xFF3DDC84);

  static const double radius = 20;

  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle status = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle statusSecondary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle smallLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );
}

void _tapHaptic() {
  unawaited(HapticFeedback.selectionClick());
}

void _successHaptic() {
  unawaited(HapticFeedback.lightImpact());
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

