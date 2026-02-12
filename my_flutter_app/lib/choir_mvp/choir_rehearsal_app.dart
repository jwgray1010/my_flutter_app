import 'dart:async';

import 'package:flutter/material.dart';

import 'models.dart';
import 'networking.dart';
import 'rehearsal_controller.dart';

class ChoirRehearsalApp extends StatelessWidget {
  const ChoirRehearsalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Choir Rehearsal MVP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C4DFF),
          secondary: Color(0xFF00C853),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            minimumSize: const Size(140, 56),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final suggestPlayer = MediaQuery.of(context).size.shortestSide >= 600;

    return Scaffold(
      appBar: AppBar(title: const Text('Choir Rehearsal MVP')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Choose this device role',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Text(
                  suggestPlayer
                      ? 'Suggested: Main Player (tablet-sized screen).'
                      : 'Suggested: Phone Remote (phone-sized screen).',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    _RoleCard(
                      title: 'Main Player',
                      subtitle: 'Load score, play audio, host remote commands',
                      icon: Icons.tablet_mac,
                      highlighted: suggestPlayer,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const MainPlayerScreen(),
                          ),
                        );
                      },
                    ),
                    _RoleCard(
                      title: 'Phone Remote',
                      subtitle: 'Measure jumps, parts, tempo, playback control',
                      icon: Icons.phone_iphone,
                      highlighted: !suggestPlayer,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PhoneRemoteScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.highlighted,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Card(
        color: highlighted ? const Color(0xFF2A1F54) : const Color(0xFF1B1B1B),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 52),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainPlayerScreen extends StatefulWidget {
  const MainPlayerScreen({super.key});

  @override
  State<MainPlayerScreen> createState() => _MainPlayerScreenState();
}

class _MainPlayerScreenState extends State<MainPlayerScreen> {
  final RehearsalController _controller = RehearsalController();
  final TextEditingController _jumpMeasureController = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _jumpMeasureController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final playback = _controller.playback;
        final score = playback.score;
        final hasScore = score != null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Main Player'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    'Remote port ${_controller.serverPort}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _controller.loadMusicXmlFromPicker,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Load MusicXML'),
                    ),
                    Text(
                      _controller.loadedFileName ?? 'No score loaded',
                      style: const TextStyle(fontSize: 18),
                    ),
                    if (playback.audioStatus != null)
                      Text(
                        playback.audioStatus!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
                if (_controller.errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _controller.errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                  ),
                ],
                const SizedBox(height: 16),
                _CurrentStatusCard(
                  currentMeasure: playback.currentMeasure,
                  tempoPercent: playback.tempoPercent,
                  loopA: playback.loopA,
                  loopB: playback.loopB,
                  isPlaying: playback.isPlaying,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton(
                      onPressed: hasScore ? () => _controller.jumpByMeasures(-2) : null,
                      child: const Text('Back 2'),
                    ),
                    ElevatedButton(
                      onPressed: hasScore ? _controller.togglePlayPause : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: playback.isPlaying
                            ? Colors.orange
                            : Colors.green,
                      ),
                      child: Text(playback.isPlaying ? 'Pause' : 'Play'),
                    ),
                    ElevatedButton(
                      onPressed: hasScore ? () => _controller.jumpByMeasures(2) : null,
                      child: const Text('Forward 2'),
                    ),
                    ElevatedButton(
                      onPressed: hasScore ? _controller.decreaseTempo : null,
                      child: const Text('Tempo -'),
                    ),
                    ElevatedButton(
                      onPressed: hasScore ? _controller.increaseTempo : null,
                      child: const Text('Tempo +'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _jumpMeasureController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jump to measure',
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: hasScore ? _jumpToTypedMeasure : null,
                      child: const Text('Jump'),
                    ),
                    ElevatedButton(
                      onPressed: hasScore ? _controller.setLoopAAtCurrentMeasure : null,
                      child: const Text('Set Loop A'),
                    ),
                    ElevatedButton(
                      onPressed: hasScore ? _controller.setLoopBAtCurrentMeasure : null,
                      child: const Text('Set Loop B'),
                    ),
                    ElevatedButton(
                      onPressed: hasScore ? _controller.clearLoop : null,
                      child: const Text('Clear Loop'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Part Mixing',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton(
                      onPressed: hasScore ? _controller.enableAllParts : null,
                      child: const Text('All'),
                    ),
                    ...ChoirPart.values.map((part) {
                      final selected = playback.enabledParts.contains(part);
                      return FilterChip(
                        label: Text(part.shortLabel, style: const TextStyle(fontSize: 18)),
                        selected: selected,
                        selectedColor: const Color(0xFF00C853),
                        onSelected: hasScore
                            ? (value) => _controller.setPartEnabled(part, value)
                            : null,
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Measures',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 360,
                  child: hasScore
                      ? MeasureGrid(
                          measures: score.measureNumbers,
                          activeMeasure: playback.currentMeasure,
                          onMeasureTap: _controller.jumpToMeasure,
                        )
                      : const Center(
                          child: Text(
                            'Load a MusicXML file to view measures.',
                            style: TextStyle(fontSize: 18, color: Colors.white70),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _jumpToTypedMeasure() {
    final measure = int.tryParse(_jumpMeasureController.text.trim());
    if (measure == null) {
      return;
    }
    _controller.jumpToMeasure(measure);
  }
}

class _CurrentStatusCard extends StatelessWidget {
  const _CurrentStatusCard({
    required this.currentMeasure,
    required this.tempoPercent,
    required this.loopA,
    required this.loopB,
    required this.isPlaying,
  });

  final int currentMeasure;
  final double tempoPercent;
  final int? loopA;
  final int? loopB;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1F1F1F),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 20,
          runSpacing: 10,
          children: [
            Text(
              'Measure $currentMeasure',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(
              'Tempo ${tempoPercent.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 22),
            ),
            Text(
              isPlaying ? 'Playing' : 'Paused',
              style: TextStyle(
                fontSize: 22,
                color: isPlaying ? Colors.greenAccent : Colors.orangeAccent,
              ),
            ),
            Text(
              'Loop ${loopA?.toString() ?? '-'} → ${loopB?.toString() ?? '-'}',
              style: const TextStyle(fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class MeasureGrid extends StatelessWidget {
  const MeasureGrid({
    super.key,
    required this.measures,
    required this.activeMeasure,
    required this.onMeasureTap,
  });

  final List<int> measures;
  final int activeMeasure;
  final ValueChanged<int> onMeasureTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: measures.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (context, index) {
        final measure = measures[index];
        final active = measure == activeMeasure;
        return ElevatedButton(
          onPressed: () => onMeasureTap(measure),
          style: ElevatedButton.styleFrom(
            backgroundColor: active ? Colors.teal : null,
            padding: EdgeInsets.zero,
          ),
          child: Text(
            '$measure',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        );
      },
    );
  }
}

class PhoneRemoteScreen extends StatefulWidget {
  const PhoneRemoteScreen({super.key});

  @override
  State<PhoneRemoteScreen> createState() => _PhoneRemoteScreenState();
}

class _PhoneRemoteScreenState extends State<PhoneRemoteScreen> {
  final RemoteClient _client = RemoteClient();
  final TextEditingController _manualHostController = TextEditingController();
  final TextEditingController _searchMeasureController = TextEditingController();
  final List<int> _recentMeasures = [];

  @override
  void initState() {
    super.initState();
    unawaited(_client.startDiscovery());
    _client.addListener(_attemptAutoConnect);
  }

  @override
  void dispose() {
    _client.removeListener(_attemptAutoConnect);
    _client.dispose();
    _manualHostController.dispose();
    _searchMeasureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _client,
      builder: (context, _) {
        final state = RemoteState.fromMap(_client.latestState);
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Phone Remote'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Measures'),
                  Tab(text: 'Parts'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _MeasuresTab(
                  state: state,
                  client: _client,
                  searchController: _searchMeasureController,
                  manualHostController: _manualHostController,
                  recentMeasures: _recentMeasures,
                  onJumpMeasure: _jumpToMeasure,
                ),
                _PartsTab(
                  state: state,
                  onSetPartEnabled: (part, enabled) {
                    _client.sendCommand({
                      'type': 'SET_PART_ENABLED',
                      'part': part.id,
                      'enabled': enabled,
                    });
                  },
                  onSetAllParts: () {
                    _client.sendCommand({'type': 'SET_ALL_PARTS'});
                  },
                ),
              ],
            ),
            bottomNavigationBar: _RemoteBottomBar(
              state: state,
              onPlayPause: () {
                _client.sendCommand({'type': state.isPlaying ? 'PAUSE' : 'PLAY'});
              },
              onTempoDown: () {
                _client.sendCommand({
                  'type': 'SET_TEMPO',
                  'percent': (state.tempoPercent - 5).clamp(50, 100),
                });
              },
              onTempoUp: () {
                _client.sendCommand({
                  'type': 'SET_TEMPO',
                  'percent': (state.tempoPercent + 5).clamp(50, 100),
                });
              },
              onLoopToggle: () {
                if (state.loopA == null) {
                  _client.sendCommand({
                    'type': 'SET_LOOP_A',
                    'measure': state.currentMeasure,
                  });
                } else if (state.loopB == null) {
                  _client.sendCommand({
                    'type': 'SET_LOOP_B',
                    'measure': state.currentMeasure,
                  });
                } else {
                  _client.sendCommand({'type': 'CLEAR_LOOP'});
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _attemptAutoConnect() {
    if (_client.isConnected || _client.isConnecting) {
      return;
    }
    if (_client.discoveredPlayers.isEmpty) {
      return;
    }
    final player = _client.discoveredPlayers.first;
    unawaited(_client.connect(host: player.host, port: player.port));
  }

  void _jumpToMeasure(int measure) {
    _client.sendCommand({
      'type': 'JUMP_TO_MEASURE',
      'measure': measure,
    });
    _recentMeasures.remove(measure);
    _recentMeasures.insert(0, measure);
    if (_recentMeasures.length > 8) {
      _recentMeasures.removeLast();
    }
    setState(() {});
  }
}

class _MeasuresTab extends StatelessWidget {
  const _MeasuresTab({
    required this.state,
    required this.client,
    required this.searchController,
    required this.manualHostController,
    required this.recentMeasures,
    required this.onJumpMeasure,
  });

  final RemoteState state;
  final RemoteClient client;
  final TextEditingController searchController;
  final TextEditingController manualHostController;
  final List<int> recentMeasures;
  final ValueChanged<int> onJumpMeasure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            client.connectionStatus ?? 'Searching for player...',
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 180,
                child: TextField(
                  controller: manualHostController,
                  decoration: const InputDecoration(
                    labelText: 'Manual IP',
                    hintText: '192.168.1.25',
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final host = manualHostController.text.trim();
                  if (host.isEmpty) {
                    return;
                  }
                  unawaited(client.connect(host: host, port: 45454));
                },
                child: const Text('Connect'),
              ),
              if (client.discoveredPlayers.isNotEmpty)
                ElevatedButton(
                  onPressed: () {
                    final host = client.discoveredPlayers.first;
                    unawaited(client.connect(host: host.host, port: host.port));
                  },
                  child: const Text('Connect Discovered'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => client.sendCommand(
                  const {'type': 'JUMP_RELATIVE', 'deltaMeasures': -2},
                ),
                child: const Text('Back 2'),
              ),
              ElevatedButton(
                onPressed: () => client.sendCommand(
                  const {'type': 'JUMP_RELATIVE', 'deltaMeasures': 2},
                ),
                child: const Text('Forward 2'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 180,
                child: TextField(
                  controller: searchController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jump measure'),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final measure = int.tryParse(searchController.text.trim());
                  if (measure == null) {
                    return;
                  }
                  onJumpMeasure(measure);
                },
                child: const Text('Go'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Recent',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (recentMeasures.isEmpty)
            const Text('No recent jumps yet.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentMeasures
                  .map(
                    (measure) => ActionChip(
                      label: Text('$measure'),
                      onPressed: () => onJumpMeasure(measure),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: state.measures.isEmpty
                ? const Center(child: Text('Waiting for measure list...'))
                : MeasureGrid(
                    measures: state.measures,
                    activeMeasure: state.currentMeasure,
                    onMeasureTap: onJumpMeasure,
                  ),
          ),
        ],
      ),
    );
  }
}

class _PartsTab extends StatelessWidget {
  const _PartsTab({
    required this.state,
    required this.onSetPartEnabled,
    required this.onSetAllParts,
  });

  final RemoteState state;
  final void Function(ChoirPart part, bool enabled) onSetPartEnabled;
  final VoidCallback onSetAllParts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: onSetAllParts,
            child: const Text('All'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ChoirPart.values.map((part) {
              final enabled = state.enabledPartIds.contains(part.id);
              return FilterChip(
                label: Text(part.shortLabel, style: const TextStyle(fontSize: 17)),
                selected: enabled,
                selectedColor: const Color(0xFF00C853),
                onSelected: (value) => onSetPartEnabled(part, value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RemoteBottomBar extends StatelessWidget {
  const _RemoteBottomBar({
    required this.state,
    required this.onPlayPause,
    required this.onTempoDown,
    required this.onTempoUp,
    required this.onLoopToggle,
  });

  final RemoteState state;
  final VoidCallback onPlayPause;
  final VoidCallback onTempoDown;
  final VoidCallback onTempoUp;
  final VoidCallback onLoopToggle;

  @override
  Widget build(BuildContext context) {
    final loopLabel = state.loopA == null
        ? 'Loop A'
        : state.loopB == null
        ? 'Loop B'
        : 'Clear Loop';

    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: SafeArea(
        top: false,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton(
              onPressed: onPlayPause,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 52),
                backgroundColor: state.isPlaying ? Colors.orange : Colors.green,
              ),
              child: Text(state.isPlaying ? 'Pause' : 'Play'),
            ),
            ElevatedButton(
              onPressed: onTempoDown,
              style: ElevatedButton.styleFrom(minimumSize: const Size(110, 52)),
              child: const Text('Tempo -'),
            ),
            ElevatedButton(
              onPressed: onTempoUp,
              style: ElevatedButton.styleFrom(minimumSize: const Size(110, 52)),
              child: const Text('Tempo +'),
            ),
            ElevatedButton(
              onPressed: onLoopToggle,
              style: ElevatedButton.styleFrom(minimumSize: const Size(150, 52)),
              child: Text(loopLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class RemoteState {
  RemoteState({
    required this.loaded,
    required this.isPlaying,
    required this.tempoPercent,
    required this.currentMeasure,
    required this.loopA,
    required this.loopB,
    required this.enabledPartIds,
    required this.measures,
  });

  final bool loaded;
  final bool isPlaying;
  final double tempoPercent;
  final int currentMeasure;
  final int? loopA;
  final int? loopB;
  final Set<String> enabledPartIds;
  final List<int> measures;

  factory RemoteState.fromMap(Map<String, dynamic>? raw) {
    if (raw == null) {
      return RemoteState.empty();
    }
    final enabledPartsRaw = raw['enabledParts'];
    final measuresRaw = raw['measures'];
    return RemoteState(
      loaded: raw['loaded'] == true,
      isPlaying: raw['isPlaying'] == true,
      tempoPercent: _parseDouble(raw['tempoPercent']) ?? 100,
      currentMeasure: _parseInt(raw['currentMeasure']) ?? 1,
      loopA: _parseInt(raw['loopA']),
      loopB: _parseInt(raw['loopB']),
      enabledPartIds: enabledPartsRaw is List
          ? enabledPartsRaw.map((entry) => entry.toString()).toSet()
          : <String>{},
      measures: measuresRaw is List
          ? measuresRaw
                .map((entry) => _parseInt(entry))
                .whereType<int>()
                .toList()
          : <int>[],
    );
  }

  factory RemoteState.empty() => RemoteState(
    loaded: false,
    isPlaying: false,
    tempoPercent: 100,
    currentMeasure: 1,
    loopA: null,
    loopB: null,
    enabledPartIds: <String>{},
    measures: <int>[],
  );
}

int? _parseInt(Object? value) {
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

double? _parseDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

