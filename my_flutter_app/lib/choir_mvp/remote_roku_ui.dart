import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'networking.dart';

class RokuRemoteScreen extends StatefulWidget {
  const RokuRemoteScreen({super.key});

  @override
  State<RokuRemoteScreen> createState() => _RokuRemoteScreenState();
}

class _RokuRemoteScreenState extends State<RokuRemoteScreen> {
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
            title: const Text('Remote'),
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
                        Text(
                          'Device: $connectedName',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          _client.connectionStatus ?? 'Disconnected',
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                        if (state.pieceName.isNotEmpty)
                          Text(
                            state.pieceName,
                            style: const TextStyle(fontSize: 14, color: Colors.white70),
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
                          args: <String, dynamic>{'deltaMeasures': -2},
                        ),
                      ),
                      _BigRemoteButton(
                        label: 'Forward 2',
                        icon: Icons.skip_next,
                        onTap: () => _send(
                          'JUMP_RELATIVE',
                          args: <String, dynamic>{'deltaMeasures': 2},
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
                const SizedBox(height: 6),
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
    final paired = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PairDeviceScreen(client: _client),
      ),
    );
    if (!mounted) {
      return;
    }
    if (paired == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paired and connected')),
      );
    }
  }

  void _send(String command, {Map<String, dynamic> args = const <String, dynamic>{}}) {
    _client.sendCommandEnvelope(command, args: args);
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
                        decoration: const InputDecoration(
                          labelText: 'Measure number',
                        ),
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
                  onChanged: (value) {
                    setState(() {
                      _byFours = value;
                    });
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-Play on Jump'),
                  value: _autoPlayOnJump,
                  onChanged: (value) {
                    setState(() {
                      _autoPlayOnJump = value;
                    });
                  },
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
  });

  final RemoteClient client;

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
                if (_processing) {
                  return;
                }
                if (capture.barcodes.isEmpty) {
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
              _message ?? 'Scan the QR code shown on iPad Player.',
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
      await widget.client.pairFromPayload(decoded.cast<String, dynamic>());
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
          ? partsRaw.map((e) => e.toString().toUpperCase()).toSet()
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

