import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'class_session_models.dart';
import 'models.dart';
import 'rehearsal_controller.dart';

class TeacherViewScreen extends StatefulWidget {
  const TeacherViewScreen({
    super.key,
    required this.controller,
  });

  final RehearsalController controller;

  @override
  State<TeacherViewScreen> createState() => _TeacherViewScreenState();
}

class _TeacherViewScreenState extends State<TeacherViewScreen> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final session = widget.controller.classSession;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Teacher View'),
            actions: [
              IconButton(
                tooltip: 'Start Class Session',
                onPressed: _showStartClassDialog,
                icon: const Icon(Icons.play_circle_fill),
              ),
              IconButton(
                tooltip: 'Export CSV',
                onPressed: session == null ? null : _exportCsv,
                icon: const Icon(Icons.file_download),
              ),
            ],
          ),
          body: session == null
              ? Center(
                  child: ElevatedButton(
                    onPressed: _showStartClassDialog,
                    child: const Text('Start Class Session'),
                  ),
                )
              : _StationTeacherDashboard(
                  session: session,
                  controller: widget.controller,
                  onEditStation: _showEditStationDialog,
                  onShowStationQr: _showStationQr,
                ),
        );
      },
    );
  }

  Future<void> _showStartClassDialog() async {
    final textController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Start Class Session'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(labelText: 'Class name (optional)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await widget.controller.startClassSession(
                  className: textController.text.trim(),
                );
                if (!mounted) {
                  return;
                }
                Navigator.of(context).pop();
              },
              child: const Text('Start'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditStationDialog(StationConfig station) async {
    final nameController = TextEditingController(text: station.stationName);
    final startController = TextEditingController(
      text: '${station.practiceSession.minMeasure}',
    );
    final endController = TextEditingController(
      text: '${station.practiceSession.maxMeasure}',
    );
    final tempoController = TextEditingController(
      text: '${station.practiceSession.defaultTempoPercent}',
    );
    var loopDefaultOn = station.practiceSession.loopDefaultOn;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Edit ${station.stationName}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Station name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: startController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Start measure'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: endController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'End measure'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: tempoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Default tempo %'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Loop default ON'),
                      value: loopDefaultOn,
                      onChanged: (value) => setStateDialog(() => loopDefaultOn = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final start = int.tryParse(startController.text.trim()) ?? 1;
                    final end = int.tryParse(endController.text.trim()) ?? start;
                    final tempo = int.tryParse(tempoController.text.trim()) ?? 70;
                    await widget.controller.updateStationConfig(
                      stationId: station.stationId,
                      stationName: nameController.text.trim(),
                      startMeasure: start,
                      endMeasure: end,
                      defaultTempoPercent: tempo,
                      loopDefaultOn: loopDefaultOn,
                    );
                    if (!mounted) {
                      return;
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showStationQr(StationConfig station) async {
    final payload = await widget.controller.stationPairingPayload(station.stationId);
    if (!mounted) {
      return;
    }
    final qrData = jsonEncode(payload);
    final pretty = const JsonEncoder.withIndent('  ').convert(payload);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${station.stationName} QR',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 260,
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                ),
                const SizedBox(height: 10),
                Text(
                  pretty,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportCsv() async {
    final csv = widget.controller.buildClassSessionCsv();
    if (csv.isEmpty) {
      return;
    }
    await Share.share(
      csv,
      subject: 'Station Mode Class Session Report',
    );
  }
}

class _StationTeacherDashboard extends StatelessWidget {
  const _StationTeacherDashboard({
    required this.session,
    required this.controller,
    required this.onEditStation,
    required this.onShowStationQr,
  });

  final ClassSessionState session;
  final RehearsalController controller;
  final Future<void> Function(StationConfig station) onEditStation;
  final Future<void> Function(StationConfig station) onShowStationQr;

  @override
  Widget build(BuildContext context) {
    final stations = session.sortedStations();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.className.isEmpty ? 'Class Session' : session.className,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  Text('Session ID: ${session.sessionId}'),
                  Text('Created: ${session.createdAt.toIso8601String()}'),
                  const SizedBox(height: 8),
                  const Text('Stations configured for single locked session each.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Stations',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (stations.isEmpty)
            const Text('No stations configured.')
          else
            ...stations.map(
              (station) {
                final runtime = controller.stationRuntime(station.stationId);
                final attempts = session.stationAttempts
                    .where((entry) => entry.stationId == station.stationId)
                    .toList();
                final completed = attempts.where((entry) => entry.completed).length;
                final totalSeconds = attempts.fold<int>(
                  0,
                  (sum, entry) => sum + entry.timeOnTaskSeconds,
                );
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                station.stationName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(_stationPartCode(station.lockedPart)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Practice mm.${station.practiceSession.minMeasure}-${station.practiceSession.maxMeasure}  '
                          'Tempo ${station.practiceSession.defaultTempoPercent}%  '
                          '${station.practiceSession.loopDefaultOn ? 'Loop ON' : 'Loop OFF'}',
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => onEditStation(station),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => onShowStationQr(station),
                              icon: const Icon(Icons.qr_code),
                              label: const Text('Generate Station QR'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Active student: ${runtime?.activeStudentName ?? '-'}',
                        ),
                        Text(
                          'Current measure: ${runtime?.currentMeasure ?? station.practiceSession.minMeasure}',
                        ),
                        Text('Tempo: ${runtime?.tempoPercent ?? station.practiceSession.defaultTempoPercent}%'),
                        Text(
                          'Loop: ${(runtime?.loopEnabled ?? false) ? 'ON ${runtime?.loopA ?? '-'}-${runtime?.loopB ?? '-'}' : 'OFF'}',
                        ),
                        Text('Connected: ${(runtime?.connected ?? false) ? 'Yes' : 'No'}'),
                        const SizedBox(height: 6),
                        Text('Students completed today: $completed'),
                        Text(
                          'Total minutes practiced: ${(totalSeconds / 60).toStringAsFixed(1)}',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
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

