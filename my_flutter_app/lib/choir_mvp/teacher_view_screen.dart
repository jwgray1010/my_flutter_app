import 'package:flutter/material.dart';
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
              : _TeacherDashboard(
                  session: session,
                  onAddPracticeSession: _showAddPracticeDialog,
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

  Future<void> _showAddPracticeDialog() async {
    final titleController = TextEditingController();
    final startController = TextEditingController(text: '1');
    final endController = TextEditingController(text: '8');
    final tempoController = TextEditingController(text: '80');
    var loopEnabled = true;
    var selectedPart = ChoirPart.alto;
    var autoPlay = true;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add Practice Session'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: startController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Start measure'),
                    ),
                    TextField(
                      controller: endController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'End measure'),
                    ),
                    TextField(
                      controller: tempoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tempo %'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ChoirPart>(
                      value: selectedPart,
                      decoration: const InputDecoration(labelText: 'Student part'),
                      items: const [
                        DropdownMenuItem(value: ChoirPart.soprano, child: Text('Soprano')),
                        DropdownMenuItem(value: ChoirPart.alto, child: Text('Alto')),
                        DropdownMenuItem(value: ChoirPart.tenor, child: Text('Tenor')),
                        DropdownMenuItem(value: ChoirPart.bass, child: Text('Bass')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setStateDialog(() {
                            selectedPart = value;
                          });
                        }
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Loop enabled'),
                      contentPadding: EdgeInsets.zero,
                      value: loopEnabled,
                      onChanged: (value) => setStateDialog(() => loopEnabled = value),
                    ),
                    SwitchListTile(
                      title: const Text('Auto-play on start'),
                      contentPadding: EdgeInsets.zero,
                      value: autoPlay,
                      onChanged: (value) => setStateDialog(() => autoPlay = value),
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
                    final tempo = (int.tryParse(tempoController.text.trim()) ?? 80).clamp(50, 100);
                    await widget.controller.addPracticeSessionPreset(
                      title: titleController.text.trim(),
                      startMeasure: start,
                      endMeasure: end,
                      tempoPercent: tempo,
                      loopEnabled: loopEnabled,
                      allowedParts: <ChoirPart>{selectedPart},
                      pianoDefaultOn: true,
                      autoPlayOnStart: autoPlay,
                    );
                    if (!mounted) {
                      return;
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
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
      subject: 'Choir Class Session Report',
    );
  }
}

class _TeacherDashboard extends StatelessWidget {
  const _TeacherDashboard({
    required this.session,
    required this.onAddPracticeSession,
  });

  final ClassSessionState session;
  final VoidCallback onAddPracticeSession;

  @override
  Widget build(BuildContext context) {
    final roster = session.rosterByDeviceId.values.toList()
      ..sort((a, b) => a.studentName.compareTo(b.studentName));
    final topLooped = session.loopRangeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topMeasures = session.measureVisitCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
                  ElevatedButton.icon(
                    onPressed: onAddPracticeSession,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Practice Session'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Practice Sessions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (session.practiceSessions.isEmpty)
            const Text('No practice sessions yet.')
          else
            ...session.practiceSessions.map(
              (practice) => ListTile(
                dense: true,
                title: Text(practice.title),
                subtitle: Text(
                  'mm.${practice.minMeasure}-${practice.maxMeasure}  Tempo ${practice.tempoPercent}%'
                  '${practice.loopEnabled ? '  Loop' : ''}',
                ),
              ),
            ),
          const SizedBox(height: 10),
          const Text(
            'Live Roster',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (roster.isEmpty)
            const Text('No students joined yet.')
          else
            DataTable(
              columns: const [
                DataColumn(label: Text('Student')),
                DataColumn(label: Text('Part')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Measure')),
                DataColumn(label: Text('Tempo')),
                DataColumn(label: Text('Session')),
              ],
              rows: roster
                  .map(
                    (row) => DataRow(
                      cells: [
                        DataCell(Text(row.studentName)),
                        DataCell(Text(row.partId)),
                        DataCell(Text(row.connected ? row.status : 'disconnected')),
                        DataCell(Text('${row.currentMeasure}')),
                        DataCell(Text('${row.currentTempo}%')),
                        DataCell(Text(row.currentSessionTitle ?? '-')),
                      ],
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 10),
          const Text(
            'Completion Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ...roster.map(
            (row) => ListTile(
              dense: true,
              title: Text(row.studentName),
              subtitle: Text(
                'Completed: ${row.sessionsCompleted}  '
                'Minutes: ${(row.totalPracticeSeconds / 60).toStringAsFixed(1)}  '
                'Last: ${row.lastActivityAt.toIso8601String()}',
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Trouble Spots',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text('Top looped ranges'),
          ...topLooped.take(10).map(
            (entry) => Text('${entry.key}: ${entry.value}'),
          ),
          const SizedBox(height: 8),
          const Text('Top visited measures'),
          ...topMeasures.take(10).map(
            (entry) => Text('m.${entry.key}: ${entry.value}'),
          ),
        ],
      ),
    );
  }
}

