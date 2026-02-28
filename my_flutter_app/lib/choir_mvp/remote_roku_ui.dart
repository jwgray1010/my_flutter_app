import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'class_session_models.dart';
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
                    builder: (_) => const StudentPracticeScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.school),
              label: const Text('Student Practice'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Student Practice is for in-school class sessions.',
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

class StudentPracticeScreen extends StatefulWidget {
  const StudentPracticeScreen({super.key});

  @override
  State<StudentPracticeScreen> createState() => _StudentPracticeScreenState();
}

class _StudentPracticeScreenState extends State<StudentPracticeScreen> {
  final RemoteClient _client = RemoteClient();
  final TextEditingController _nameController = TextEditingController();
  String _part = 'ALTO';
  bool _joined = false;
  String? _activePracticeId;
  bool _playing = false;
  bool _loopEnabled = false;
  int _currentMeasure = 1;
  int _currentTempo = 100;
  int _secondsOnTask = 0;
  int _baseTempoForSession = 100;
  bool _reachedEnd = false;
  final Set<int> _visitedMeasures = <int>{};
  int _loopReps = 0;
  Timer? _practiceTimer;
  final Set<String> _autoCompletedPracticeIds = <String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _client.restoreAndReconnect();
    final profile = _client.pairedProfile;
    if (profile?.mode == 'class_session') {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _practiceTimer?.cancel();
    unawaited(_sendSummary());
    _client.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _client,
      builder: (context, _) {
        final state = RokuRemoteState.fromMap(_client.latestState);
        final classSession = state.classSession;
        final activePractice = classSession?.practiceById(_activePracticeId);
        final requiresPair = _client.pairedProfile?.mode != 'class_session';
        return Scaffold(
          appBar: AppBar(
            title: const Text('Student Practice'),
            actions: [
              IconButton(
                onPressed: _openClassPairQr,
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Scan Class QR',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _client.connectionStatus ?? 'Not connected',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                if (requiresPair)
                  ElevatedButton.icon(
                    onPressed: _openClassPairQr,
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Join Class via QR'),
                  ),
                if (!requiresPair) ...[
                  if (!_joined) _studentIdentityForm(classSession),
                  if (_joined) ...[
                    _studentRosterHeader(classSession),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _practiceSessionList(classSession),
                    ),
                    if (activePractice != null) _practiceControlPad(activePractice),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _studentIdentityForm(ClassSessionRemoteState? classSession) {
    final sessionId = _client.pairedProfile?.sessionId ?? classSession?.sessionId ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class Session: ${classSession?.className.isNotEmpty == true ? classSession!.className : sessionId}'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _part,
              items: const [
                DropdownMenuItem(value: 'SOP', child: Text('Soprano')),
                DropdownMenuItem(value: 'ALTO', child: Text('Alto')),
                DropdownMenuItem(value: 'TENOR', child: Text('Tenor')),
                DropdownMenuItem(value: 'BASS', child: Text('Bass')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _part = value;
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Part'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _joinClassSession(sessionId),
              child: const Text('Join Class Session'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentRosterHeader(ClassSessionRemoteState? classSession) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              classSession?.className.isNotEmpty == true
                  ? classSession!.className
                  : 'Class Session',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text('Student: ${_nameController.text.trim()} ($_part)'),
            Text('Device ID: ${_client.deviceId.substring(0, 12)}...'),
          ],
        ),
      ),
    );
  }

  Widget _practiceSessionList(ClassSessionRemoteState? classSession) {
    final sessions = classSession?.practiceSessions ?? const <PracticeSessionPreset>[];
    if (sessions.isEmpty) {
      return const Center(
        child: Text('Waiting for teacher to add practice sessions...'),
      );
    }
    return ListView.separated(
      itemCount: sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final session = sessions[index];
        final isActive = session.id == _activePracticeId;
        return Card(
          color: isActive ? const Color(0xFF1E3A4F) : null,
          child: ListTile(
            title: Text(session.title),
            subtitle: Text(
              'mm.${session.minMeasure}-${session.maxMeasure}  Tempo ${session.tempoPercent}%'
              '${session.loopEnabled ? '  Loop ON' : ''}',
            ),
            trailing: ElevatedButton(
              onPressed: () => _startPracticeSession(session, classSession?.sessionId ?? ''),
              child: Text(isActive ? 'Active' : 'Start'),
            ),
          ),
        );
      },
    );
  }

  Widget _practiceControlPad(PracticeSessionPreset activePractice) {
    final allowLoopToggle = activePractice.loopEnabled;
    final tempoLower = (activePractice.tempoPercent - 10).clamp(50, 100);
    final tempoUpper = (activePractice.tempoPercent + 10).clamp(50, 100);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Now Practicing: ${activePractice.title}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text('Measure $_currentMeasure  Tempo $_currentTempo%'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _togglePlayPause,
                  child: Text(_playing ? 'Pause' : 'Play'),
                ),
                ElevatedButton(
                  onPressed: () => _stepBack(activePractice, 1),
                  child: const Text('Back 1'),
                ),
                ElevatedButton(
                  onPressed: () => _stepBack(activePractice, 2),
                  child: const Text('Back 2'),
                ),
                ElevatedButton(
                  onPressed: allowLoopToggle ? _toggleLoop : null,
                  child: Text(_loopEnabled ? 'Loop On' : 'Loop Off'),
                ),
                ElevatedButton(
                  onPressed: () => _adjustTempo(activePractice, -5, tempoLower, tempoUpper),
                  child: const Text('Tempo -'),
                ),
                ElevatedButton(
                  onPressed: () => _adjustTempo(activePractice, 5, tempoLower, tempoUpper),
                  child: const Text('Tempo +'),
                ),
                ElevatedButton(
                  onPressed: _markComplete,
                  child: const Text('Mark Complete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openClassPairQr() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PairDeviceScreen(
          client: _client,
          requiredMode: 'class_session',
        ),
      ),
    );
    setState(() {
      _joined = false;
      _activePracticeId = null;
    });
  }

  void _joinClassSession(String sessionId) {
    final name = _nameController.text.trim();
    if (name.isEmpty || sessionId.isEmpty) {
      return;
    }
    _client.sendStudentMessage(
      'JOIN_CLASS_SESSION',
      payload: <String, dynamic>{
        'sessionId': sessionId,
        'studentName': name,
        'part': _part,
        'deviceId': _client.deviceId,
      },
    );
    setState(() {
      _joined = true;
    });
  }

  void _startPracticeSession(PracticeSessionPreset session, String sessionId) {
    if (sessionId.isEmpty) {
      return;
    }
    _activePracticeId = session.id;
    _playing = session.autoPlayOnStart;
    _loopEnabled = session.loopEnabled;
    _currentMeasure = session.minMeasure;
    _currentTempo = session.tempoPercent;
    _baseTempoForSession = session.tempoPercent;
    _secondsOnTask = 0;
    _reachedEnd = false;
    _visitedMeasures
      ..clear()
      ..add(_currentMeasure);
    _loopReps = 0;
    _practiceTimer?.cancel();
    if (_playing) {
      _practiceTimer = Timer.periodic(const Duration(seconds: 1), (_) => _practiceTick());
    }
    _client.sendStudentMessage(
      'START_PRACTICE_SESSION',
      payload: <String, dynamic>{
        'sessionId': sessionId,
        'practiceSessionId': session.id,
        'studentName': _nameController.text.trim(),
        'part': _part,
        'deviceId': _client.deviceId,
      },
    );
    _sendPracticeEvent('START');
    setState(() {});
  }

  void _togglePlayPause() {
    _playing = !_playing;
    _practiceTimer?.cancel();
    if (_playing) {
      _practiceTimer = Timer.periodic(const Duration(seconds: 1), (_) => _practiceTick());
    }
    _sendPracticeEvent(_playing ? 'PLAY' : 'PAUSE');
    setState(() {});
  }

  void _stepBack(PracticeSessionPreset session, int steps) {
    _currentMeasure = (_currentMeasure - steps).clamp(session.minMeasure, session.maxMeasure);
    _visitedMeasures.add(_currentMeasure);
    _sendPracticeEvent('JUMP');
    setState(() {});
  }

  void _toggleLoop() {
    _loopEnabled = !_loopEnabled;
    _sendPracticeEvent('LOOP');
    setState(() {});
  }

  void _adjustTempo(PracticeSessionPreset session, int delta, int lower, int upper) {
    _currentTempo = (_currentTempo + delta).clamp(lower, upper);
    _sendPracticeEvent('TEMPO');
    setState(() {});
  }

  void _markComplete() {
    _sendPracticeEvent('COMPLETE', completed: true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked complete')),
    );
  }

  void _practiceTick() {
    final state = RokuRemoteState.fromMap(_client.latestState);
    final classSession = state.classSession;
    final practice = classSession?.practiceById(_activePracticeId);
    if (practice == null) {
      return;
    }
    if (!_playing) {
      return;
    }
    _secondsOnTask += 1;
    var didLoopReset = false;
    if (_secondsOnTask % 2 == 0) {
      _currentMeasure += 1;
      if (_currentMeasure > practice.maxMeasure) {
        _reachedEnd = true;
        if (_loopEnabled && practice.loopEnabled) {
          _currentMeasure = practice.minMeasure;
          didLoopReset = true;
          _loopReps += 1;
        } else {
          _currentMeasure = practice.maxMeasure;
          _playing = false;
          _practiceTimer?.cancel();
        }
      }
    }
    _visitedMeasures.add(_currentMeasure);
    _sendPracticeEvent(
      'PLAY',
      deltaSeconds: 1,
      loopRange: didLoopReset ? '${practice.minMeasure}-${practice.maxMeasure}' : null,
    );
    if (_secondsOnTask >= 20 && _reachedEnd && !_autoCompletedPracticeIds.contains(practice.id)) {
      _autoCompletedPracticeIds.add(practice.id);
      _sendPracticeEvent('COMPLETE', completed: true);
    }
    setState(() {});
  }

  void _sendPracticeEvent(
    String eventType, {
    bool completed = false,
    int deltaSeconds = 0,
    String? loopRange,
  }) {
    final profile = _client.pairedProfile;
    final sessionId = profile?.sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return;
    }
    _client.sendStudentMessage(
      'PRACTICE_EVENT',
      payload: <String, dynamic>{
        'sessionId': sessionId,
        'deviceId': _client.deviceId,
        'studentName': _nameController.text.trim(),
        'part': _part,
        'practiceSessionId': _activePracticeId,
        'event': eventType,
        'currentMeasure': _currentMeasure,
        'tempoPercent': _currentTempo,
        'deltaSeconds': deltaSeconds,
        if (loopRange != null) 'loopRange': loopRange,
        'completed': completed,
      },
    );
  }

  Future<void> _sendSummary() async {
    final profile = _client.pairedProfile;
    final sessionId = profile?.sessionId;
    if (sessionId == null || sessionId.isEmpty || !_joined) {
      return;
    }
    _client.sendStudentMessage(
      'PRACTICE_SUMMARY',
      payload: <String, dynamic>{
        'sessionId': sessionId,
        'deviceId': _client.deviceId,
        'practiceSessionId': _activePracticeId,
        'timeOnTaskSeconds': _secondsOnTask,
        'completedSessions': _autoCompletedPracticeIds.toList(),
        'measuresVisited': _visitedMeasures.toList(),
        'loopReps': _loopReps,
        'tempoRange': <String, dynamic>{
          'min': (_baseTempoForSession - 10).clamp(50, 100),
          'max': (_baseTempoForSession + 10).clamp(50, 100),
        },
      },
    );
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

class ClassSessionRemoteState {
  ClassSessionRemoteState({
    required this.sessionId,
    required this.className,
    required this.practiceSessions,
  });

  final String sessionId;
  final String className;
  final List<PracticeSessionPreset> practiceSessions;

  PracticeSessionPreset? practiceById(String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final session in practiceSessions) {
      if (session.id == id) {
        return session;
      }
    }
    return null;
  }

  factory ClassSessionRemoteState.fromMap(Map<String, dynamic> map) {
    final practiceRaw = map['practiceSessions'];
    final sessions = <PracticeSessionPreset>[];
    if (practiceRaw is List) {
      for (final entry in practiceRaw) {
        if (entry is Map) {
          sessions.add(PracticeSessionPreset.fromMap(entry.cast<String, dynamic>()));
        }
      }
    }
    return ClassSessionRemoteState(
      sessionId: map['sessionId']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      practiceSessions: sessions,
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
    required this.classSession,
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
  final ClassSessionRemoteState? classSession;

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
    final classRaw = raw['activeClassSession'];
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
          ? partsRaw.map((e) => e.toString().toUpperCase()).toSet()
          : <String>{},
      measures: measuresRaw is List ? measuresRaw.map(_toInt).whereType<int>().toList() : <int>[],
      classSession: classRaw is Map
          ? ClassSessionRemoteState.fromMap(classRaw.cast<String, dynamic>())
          : null,
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
    classSession: null,
  );
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
        minimumSize: const Size(double.infinity, 82),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 26),
      label: Text(label, style: const TextStyle(fontSize: 20)),
    );
  }
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

