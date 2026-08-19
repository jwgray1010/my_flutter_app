import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'class_session_models.dart';
import 'models.dart';
import 'networking.dart';
import 'rehearsal_controller.dart';
import 'remote_roku_ui.dart';
import 'teacher_view_screen.dart';
import 'voice_commands.dart';
import 'voice_help_screen.dart';
import 'voice_ptt_service.dart';
import 'vocal_coach_flow.dart';
import 'warmup_session_controller.dart';
import 'warmups_flow.dart';
import 'warmups_library.dart';
import 'warmups_models.dart';

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
                            builder: (_) => const PlayerHomeScreen(),
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
                            builder: (_) => const RokuRemoteScreen(),
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

class PlayerHomeScreen extends StatelessWidget {
  const PlayerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15181D),
      appBar: AppBar(
        title: const Text('Player Home'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose Mode',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 112,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6E5BFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MainPlayerScreen(),
                        ),
                      );
                    },
                    child: const Text('Rehearsal'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 112,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E232B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const WarmupCategoryScreen(),
                        ),
                      );
                    },
                    child: const Text('Warmups'),
                  ),
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
  final VoicePttService _voiceService = VoicePttService();
  final VoiceCommandParser _voiceParser = VoiceCommandParser();

  bool _voicePermissionGranted = false;
  bool _isPttListening = false;
  bool _isPttProcessing = false;
  bool _choirRoomMode = false;
  bool _requireWakePhraseInChoirMode = true;
  String _wakePhrase = 'Podium';

  @override
  void initState() {
    super.initState();
    unawaited(_controller.initialize());
    unawaited(_initializeVoice());
  }

  @override
  void dispose() {
    _jumpMeasureController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeVoice() async {
    final granted = await _voiceService.requestPermissions();
    if (!mounted) {
      return;
    }
    setState(() {
      _voicePermissionGranted = granted;
    });
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
              IconButton(
                tooltip: 'Voice commands help',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const VoiceCommandsHelpScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.help_outline),
              ),
              IconButton(
                tooltip: 'Pair remote (QR)',
                onPressed: _showPairingQrSheet,
                icon: const Icon(Icons.qr_code),
              ),
              IconButton(
                tooltip: 'Teacher View',
                onPressed: _openTeacherView,
                icon: const Icon(Icons.monitor),
              ),
              if (_isPttListening || _isPttProcessing)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: _VoiceStatusPill(
                      isListening: _isPttListening,
                      isProcessing: _isPttProcessing,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Center(
                  child: Text(
                    'Remote port ${_controller.serverPort}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Center(
                  child: _PttHoldButton(
                    size: 56,
                    isListening: _isPttListening,
                    onPressStart: _handleVoicePressStart,
                    onPressEnd: _handleVoicePressEnd,
                    semanticsLabel: 'Hold to talk',
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
                    ElevatedButton.icon(
                      onPressed: _showPairingQrSheet,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Pair Remote'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showStartClassSessionDialog,
                      icon: const Icon(Icons.class_),
                      label: Text(
                        _controller.hasActiveClassSession
                            ? 'Restart Class Session'
                            : 'Start Class Session',
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openTeacherView,
                      icon: const Icon(Icons.assessment),
                      label: const Text('Teacher View'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openVocalCoach,
                      icon: const Icon(Icons.graphic_eq),
                      label: const Text('Vocal Coach'),
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
                if (_controller.classSession != null) ...[
                  const SizedBox(height: 10),
                  _ClassSessionStatusCard(session: _controller.classSession!),
                ],
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
                  loopArmed: _controller.playbackController.loopArmed,
                  isPlaying: playback.isPlaying,
                ),
                const SizedBox(height: 12),
                _VoiceSafetyCard(
                  choirRoomMode: _choirRoomMode,
                  requireWakePhrase: _requireWakePhraseInChoirMode,
                  wakePhrase: _wakePhrase,
                  confidenceThreshold: _minimumConfidence,
                  permissionGranted: _voicePermissionGranted,
                  onChoirRoomModeChanged: (value) {
                    setState(() {
                      _choirRoomMode = value;
                    });
                  },
                  onRequireWakePhraseChanged: (value) {
                    setState(() {
                      _requireWakePhraseInChoirMode = value;
                    });
                  },
                  onWakePhraseChanged: (value) {
                    setState(() {
                      _wakePhrase = value;
                    });
                  },
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

  Future<void> _showPairingQrSheet() async {
    final payload = await _controller.pairingPayload();
    await _showQrPayloadSheet(
      title: 'Pair Remote',
      payload: payload,
    );
  }

  Future<void> _showQrPayloadSheet({
    required String title,
    required Map<String, dynamic> payload,
  }) async {
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
                  title,
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

  Future<void> _showStartClassSessionDialog() async {
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
                await _controller.startClassSession(
                  className: textController.text.trim(),
                );
                if (!mounted) {
                  return;
                }
                Navigator.of(context).pop();
                _openTeacherView();
              },
              child: const Text('Start'),
            ),
          ],
        );
      },
    );
  }

  void _openTeacherView() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeacherViewScreen(controller: _controller),
      ),
    );
  }

  Future<void> _openVocalCoach() async {
    final studentName = await _promptStudentNameForCoach();
    if (!mounted || studentName == null || studentName.trim().isEmpty) {
      return;
    }
    final trimmedName = studentName.trim();
    final studentId = _normalizedStudentId(trimmedName);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VocalCoachScreen(
          studentId: studentId,
          studentName: trimmedName,
          sessionId: _controller.classSession?.sessionId,
          onSaveProfile: (profile, plan) {
            return _controller.saveVocalCoachProfile(
              profile: profile,
              plan: plan,
            );
          },
          onSaveProgress: _controller.saveVocalCoachProgress,
          onRunWarmup: _openWarmupById,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<String?> _promptStudentNameForCoach() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Vocal Coach Student'),
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

  String _normalizedStudentId(String studentName) {
    final normalized = studentName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'student_unknown' : normalized;
  }

  Future<void> _openWarmupById(String warmupId) async {
    final library = WarmupsLibrary.buildAll();
    Warmup? selected;
    for (final warmup in library) {
      if (warmup.id == warmupId) {
        selected = warmup;
        break;
      }
    }
    if (selected == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Warmup not found: $warmupId')),
        );
      }
      return;
    }
    final controller = WarmupSessionController(library: library);
    await controller.initializeAudio();
    controller.selectWarmup(selected);
    if (!mounted) {
      controller.dispose();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WarmupPlayerScreen(controller: controller),
      ),
    );
    controller.dispose();
  }

  double get _minimumConfidence => _choirRoomMode ? 0.62 : 0.35;

  Future<void> _handleVoicePressStart() async {
    if (_isPttListening || _isPttProcessing) {
      return;
    }
    HapticFeedback.mediumImpact();
    if (!_voicePermissionGranted) {
      final granted = await _voiceService.requestPermissions();
      if (!mounted) {
        return;
      }
      setState(() {
        _voicePermissionGranted = granted;
      });
      if (!granted) {
        _showVoiceToast(
          success: false,
          message: 'Speech permission denied.',
          suggestion: 'Enable microphone + speech permissions in Settings.',
        );
        return;
      }
    }

    final started = await _voiceService.startListening(
      preferOffline: true,
      allowStandardFallback: true,
    );
    if (!mounted) {
      return;
    }
    if (!started.started) {
      _showVoiceToast(
        success: false,
        message: "Didn't catch that.",
        suggestion: started.message,
      );
      return;
    }
    setState(() {
      _isPttListening = true;
    });
  }

  Future<void> _handleVoicePressEnd() async {
    if (!_isPttListening) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _isPttListening = false;
      _isPttProcessing = true;
    });

    final stopResult = await _voiceService.stopListening();
    if (!mounted) {
      return;
    }
    setState(() {
      _isPttProcessing = false;
    });

    final normalized = normalizeTranscript(stopResult.transcript);
    if (normalized.isEmpty) {
      _showVoiceToast(
        success: false,
        message: "Didn't catch that.",
        suggestion: "Try: 'measure 32'.",
      );
      return;
    }
    if (stopResult.confidence < _minimumConfidence) {
      _showVoiceToast(
        success: false,
        message: "Didn't catch that.",
        suggestion: "Try again clearly: 'go to measure 32'.",
      );
      return;
    }

    var parserText = normalized;
    if (_choirRoomMode && _requireWakePhraseInChoirMode) {
      final wake = _wakePhrase.toLowerCase();
      final hasWakePhrase = parserText.contains(wake);
      if (!hasWakePhrase) {
        _showVoiceToast(
          success: false,
          message: "Didn't catch that.",
          suggestion: "Use wake phrase '$wake' first.",
        );
        return;
      }
      parserText = parserText.replaceAll(RegExp('\\b$wake\\b'), '').trim();
    }

    final rehearsalMarks = _controller.playback.score?.rehearsalMarks ?? const <String, int>{};
    final parsed = _voiceParser.parse(
      parserText,
      rehearsalMarks: rehearsalMarks,
    );
    if (!parsed.isSuccess || parsed.intent == null) {
      _showVoiceToast(
        success: false,
        message: parsed.message,
        suggestion: parsed.suggestion,
      );
      return;
    }

    final commandResult = await _applyMainVoiceIntent(parsed.intent!);
    if (!commandResult.applied) {
      _showVoiceToast(
        success: false,
        message: commandResult.message,
        suggestion: commandResult.suggestion,
      );
      return;
    }
    _showVoiceToast(
      success: true,
      message: commandResult.message.isNotEmpty ? commandResult.message : parsed.message,
      suggestion: null,
    );
  }

  Future<CommandExecutionResult> _applyMainVoiceIntent(VoiceIntent intent) async {
    final command = intentToCommand(
      intent,
      currentMeasure: _controller.playback.currentMeasure,
    );
    if (command == null) {
      return const CommandExecutionResult(
        applied: false,
        message: "Didn't catch that.",
      );
    }
    return _controller.applyCommand(command);
  }

  void _showVoiceToast({
    required bool success,
    required String message,
    String? suggestion,
  }) {
    final icon = success ? '✅' : '❌';
    final text = suggestion == null ? '$icon $message' : '$icon $message  $suggestion';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          content: Text(text),
        ),
      );
  }
}

class _PttHoldButton extends StatelessWidget {
  const _PttHoldButton({
    required this.size,
    required this.isListening,
    required this.onPressStart,
    required this.onPressEnd,
    required this.semanticsLabel,
  });

  final double size;
  final bool isListening;
  final Future<void> Function() onPressStart;
  final Future<void> Function() onPressEnd;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Listener(
        onPointerDown: (_) {
          unawaited(onPressStart());
        },
        onPointerUp: (_) {
          unawaited(onPressEnd());
        },
        onPointerCancel: (_) {
          unawaited(onPressEnd());
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isListening ? Colors.redAccent : const Color(0xFF7C4DFF),
            shape: BoxShape.circle,
            border: Border.all(
              color: isListening ? Colors.white : Colors.white38,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.mic,
            size: size * 0.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _VoiceStatusPill extends StatelessWidget {
  const _VoiceStatusPill({
    required this.isListening,
    required this.isProcessing,
  });

  final bool isListening;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final label = isListening
        ? 'Listening...'
        : isProcessing
        ? 'Processing...'
        : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isListening ? Colors.redAccent : Colors.blueGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _VoiceSafetyCard extends StatelessWidget {
  const _VoiceSafetyCard({
    required this.choirRoomMode,
    required this.requireWakePhrase,
    required this.wakePhrase,
    required this.confidenceThreshold,
    required this.permissionGranted,
    required this.onChoirRoomModeChanged,
    required this.onRequireWakePhraseChanged,
    required this.onWakePhraseChanged,
  });

  final bool choirRoomMode;
  final bool requireWakePhrase;
  final String wakePhrase;
  final double confidenceThreshold;
  final bool permissionGranted;
  final ValueChanged<bool> onChoirRoomModeChanged;
  final ValueChanged<bool> onRequireWakePhraseChanged;
  final ValueChanged<String> onWakePhraseChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1A1A),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voice Command Safety',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Choir Room Mode'),
                    subtitle: Text(
                      'Confidence >= ${(confidenceThreshold * 100).toStringAsFixed(0)}%',
                    ),
                    value: choirRoomMode,
                    onChanged: onChoirRoomModeChanged,
                  ),
                ),
                Text(
                  permissionGranted ? 'Voice ready' : 'No permission',
                  style: TextStyle(
                    color: permissionGranted ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            if (choirRoomMode) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Require wake phrase'),
                value: requireWakePhrase,
                onChanged: onRequireWakePhraseChanged,
              ),
              if (requireWakePhrase)
                Row(
                  children: [
                    const Text('Wake phrase:'),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: wakePhrase,
                      items: const [
                        DropdownMenuItem(value: 'Podium', child: Text('Podium')),
                        DropdownMenuItem(value: 'Maestro', child: Text('Maestro')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          onWakePhraseChanged(value);
                        }
                      },
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CurrentStatusCard extends StatelessWidget {
  const _CurrentStatusCard({
    required this.currentMeasure,
    required this.tempoPercent,
    required this.loopA,
    required this.loopB,
    required this.loopArmed,
    required this.isPlaying,
  });

  final int currentMeasure;
  final double tempoPercent;
  final int? loopA;
  final int? loopB;
  final bool loopArmed;
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
              'Loop ${loopA?.toString() ?? '-'} -> ${loopB?.toString() ?? '-'}',
              style: const TextStyle(fontSize: 22),
            ),
            Text(
              loopArmed ? 'Loop Armed' : 'Loop Disarmed',
              style: TextStyle(
                fontSize: 20,
                color: loopArmed ? Colors.greenAccent : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassSessionStatusCard extends StatelessWidget {
  const _ClassSessionStatusCard({
    required this.session,
  });

  final ClassSessionState session;

  @override
  Widget build(BuildContext context) {
    final connectedStations = session.stationRuntimeById.values
        .where((runtime) => runtime.connected)
        .length;
    final activeStudents = session.stationRuntimeById.values
        .where((runtime) => runtime.activeStudentName != null)
        .length;
    return Card(
      color: const Color(0xFF1A2530),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              session.className.isEmpty ? 'Class Session Active' : session.className,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(
              'Session ${session.sessionId.length > 8 ? session.sessionId.substring(0, 8) : session.sessionId}...',
            ),
            Text('Stations: ${session.stationsById.length}'),
            Text('Active students: $activeStudents'),
            Text('Connected stations: $connectedStations'),
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
  final VoicePttService _voiceService = VoicePttService();
  final VoiceCommandParser _voiceParser = VoiceCommandParser();

  bool _voicePermissionGranted = false;
  bool _isPttListening = false;
  bool _isPttProcessing = false;
  bool _choirRoomMode = false;
  bool _requireWakePhraseInChoirMode = true;
  String _wakePhrase = 'Podium';

  @override
  void initState() {
    super.initState();
    unawaited(_client.startDiscovery());
    _client.addListener(_attemptAutoConnect);
    unawaited(_initializeVoice());
  }

  @override
  void dispose() {
    _client.removeListener(_attemptAutoConnect);
    _client.dispose();
    _manualHostController.dispose();
    _searchMeasureController.dispose();
    super.dispose();
  }

  Future<void> _initializeVoice() async {
    final granted = await _voiceService.requestPermissions();
    if (!mounted) {
      return;
    }
    setState(() {
      _voicePermissionGranted = granted;
    });
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
              actions: [
                IconButton(
                  tooltip: 'Voice commands help',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const VoiceCommandsHelpScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.help_outline),
                ),
                if (_isPttListening || _isPttProcessing)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: _VoiceStatusPill(
                        isListening: _isPttListening,
                        isProcessing: _isPttProcessing,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: _PttHoldButton(
                      size: 50,
                      isListening: _isPttListening,
                      onPressStart: _handleVoicePressStart,
                      onPressEnd: _handleVoicePressEnd,
                      semanticsLabel: 'Hold to talk on remote',
                    ),
                  ),
                ),
              ],
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
                  choirRoomMode: _choirRoomMode,
                  requireWakePhrase: _requireWakePhraseInChoirMode,
                  wakePhrase: _wakePhrase,
                  confidenceThreshold: _minimumConfidence,
                  permissionGranted: _voicePermissionGranted,
                  onChoirRoomModeChanged: (value) {
                    setState(() {
                      _choirRoomMode = value;
                    });
                  },
                  onRequireWakePhraseChanged: (value) {
                    setState(() {
                      _requireWakePhraseInChoirMode = value;
                    });
                  },
                  onWakePhraseChanged: (value) {
                    setState(() {
                      _wakePhrase = value;
                    });
                  },
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

  double get _minimumConfidence => _choirRoomMode ? 0.62 : 0.35;

  Future<void> _handleVoicePressStart() async {
    if (_isPttListening || _isPttProcessing) {
      return;
    }
    HapticFeedback.mediumImpact();
    if (!_voicePermissionGranted) {
      final granted = await _voiceService.requestPermissions();
      if (!mounted) {
        return;
      }
      setState(() {
        _voicePermissionGranted = granted;
      });
      if (!granted) {
        _showVoiceToast(
          success: false,
          message: 'Speech permission denied.',
          suggestion: 'Enable microphone + speech permissions in Settings.',
        );
        return;
      }
    }

    final started = await _voiceService.startListening(
      preferOffline: true,
      allowStandardFallback: true,
    );
    if (!mounted) {
      return;
    }
    if (!started.started) {
      _showVoiceToast(
        success: false,
        message: "Didn't catch that.",
        suggestion: started.message,
      );
      return;
    }
    setState(() {
      _isPttListening = true;
    });
  }

  Future<void> _handleVoicePressEnd() async {
    if (!_isPttListening) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _isPttListening = false;
      _isPttProcessing = true;
    });

    final stopResult = await _voiceService.stopListening();
    if (!mounted) {
      return;
    }
    setState(() {
      _isPttProcessing = false;
    });

    if (!_client.isConnected) {
      _showVoiceToast(
        success: false,
        message: 'Remote not connected.',
        suggestion: 'Connect to the main player first.',
      );
      return;
    }

    final normalized = normalizeTranscript(stopResult.transcript);
    if (normalized.isEmpty) {
      _showVoiceToast(
        success: false,
        message: "Didn't catch that.",
        suggestion: "Try: 'measure 32'.",
      );
      return;
    }
    if (stopResult.confidence < _minimumConfidence) {
      _showVoiceToast(
        success: false,
        message: "Didn't catch that.",
        suggestion: "Try again clearly: 'go to measure 32'.",
      );
      return;
    }

    var parserText = normalized;
    if (_choirRoomMode && _requireWakePhraseInChoirMode) {
      final wake = _wakePhrase.toLowerCase();
      final hasWakePhrase = parserText.contains(wake);
      if (!hasWakePhrase) {
        _showVoiceToast(
          success: false,
          message: "Didn't catch that.",
          suggestion: "Use wake phrase '$wake' first.",
        );
        return;
      }
      parserText = parserText.replaceAll(RegExp('\\b$wake\\b'), '').trim();
    }

    final state = RemoteState.fromMap(_client.latestState);
    final parsed = _voiceParser.parse(
      parserText,
      rehearsalMarks: state.rehearsalMarks,
    );
    if (!parsed.isSuccess || parsed.intent == null) {
      _showVoiceToast(
        success: false,
        message: parsed.message,
        suggestion: parsed.suggestion,
      );
      return;
    }

    final appliedMessage = _applyRemoteVoiceIntent(parsed.intent!, state);
    if (appliedMessage == null) {
      _showVoiceToast(
        success: false,
        message: "Didn't catch that.",
        suggestion: "Try: 'play' or 'measure 32'.",
      );
      return;
    }
    _showVoiceToast(
      success: true,
      message: appliedMessage,
      suggestion: null,
    );
  }

  String? _applyRemoteVoiceIntent(VoiceIntent intent, RemoteState state) {
    final command = intentToCommand(intent, currentMeasure: state.currentMeasure);
    if (command == null) {
      return null;
    }

    if (command['type'] == 'JUMP_TO_MEASURE') {
      final rawMeasure = _parseInt(command['measure']);
      if (rawMeasure != null && state.measures.isNotEmpty) {
        final clamped = _clampToKnownMeasure(rawMeasure, state.measures);
        command['measure'] = clamped;
        _client.sendCommand(command);
        if (rawMeasure != clamped) {
          return 'Clamped to m.$clamped';
        }
        return 'Jump to measure $clamped';
      }
    }

    _client.sendCommand(command);
    return _describeRemoteCommand(command, state);
  }

  int _clampToKnownMeasure(int requested, List<int> measures) {
    if (measures.isEmpty) {
      return requested;
    }
    if (measures.contains(requested)) {
      return requested;
    }
    var closest = measures.first;
    var distance = (closest - requested).abs();
    for (final measure in measures) {
      final candidate = (measure - requested).abs();
      if (candidate < distance) {
        closest = measure;
        distance = candidate;
      }
    }
    return closest;
  }

  String _describeRemoteCommand(Map<String, dynamic> command, RemoteState state) {
    switch (command['type']) {
      case 'PLAY':
        return 'Play';
      case 'PAUSE':
        return 'Pause';
      case 'JUMP_TO_MEASURE':
        return 'Jump to measure ${command['measure']}';
      case 'JUMP_RELATIVE':
        final delta = _parseInt(command['deltaMeasures']) ?? 0;
        return delta < 0 ? 'Back ${delta.abs()}' : 'Forward $delta';
      case 'SET_TEMPO':
        return 'Tempo ${(_parseDouble(command['percent']) ?? state.tempoPercent).round()}%';
      case 'SET_TEMPO_ADJUST':
        final delta = _parseInt(command['delta']) ?? 0;
        return delta < 0 ? 'Tempo slower' : 'Tempo faster';
      case 'SET_LOOP_A':
        return 'Set loop A';
      case 'SET_LOOP_B':
        return 'Set loop B';
      case 'SET_LOOP_RANGE':
        return 'Loop measures ${command['a']} to ${command['b']}';
      case 'LOOP_ARM_TOGGLE':
        return state.loopArmed ? 'Loop disarmed' : 'Loop armed';
      case 'CLEAR_LOOP':
        return 'Clear loop';
      case 'SET_MIX_PRESET':
        if (command['preset'] == 'all') {
          return 'All parts on';
        }
        return 'Parts updated';
      case 'SET_PART_ENABLED':
        final part = command['part']?.toString() ?? '';
        final enabled = command['enabled'] == true;
        return '$part ${enabled ? 'on' : 'off'}';
      case 'PLAY_STARTING_PITCHES':
        return 'Play starting pitches';
      default:
        return 'Command sent';
    }
  }

  void _showVoiceToast({
    required bool success,
    required String message,
    String? suggestion,
  }) {
    final icon = success ? '✅' : '❌';
    final text = suggestion == null ? '$icon $message' : '$icon $message  $suggestion';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          content: Text(text),
        ),
      );
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
    required this.choirRoomMode,
    required this.requireWakePhrase,
    required this.wakePhrase,
    required this.confidenceThreshold,
    required this.permissionGranted,
    required this.onChoirRoomModeChanged,
    required this.onRequireWakePhraseChanged,
    required this.onWakePhraseChanged,
  });

  final RemoteState state;
  final RemoteClient client;
  final TextEditingController searchController;
  final TextEditingController manualHostController;
  final List<int> recentMeasures;
  final ValueChanged<int> onJumpMeasure;
  final bool choirRoomMode;
  final bool requireWakePhrase;
  final String wakePhrase;
  final double confidenceThreshold;
  final bool permissionGranted;
  final ValueChanged<bool> onChoirRoomModeChanged;
  final ValueChanged<bool> onRequireWakePhraseChanged;
  final ValueChanged<String> onWakePhraseChanged;

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
          _VoiceSafetyCard(
            choirRoomMode: choirRoomMode,
            requireWakePhrase: requireWakePhrase,
            wakePhrase: wakePhrase,
            confidenceThreshold: confidenceThreshold,
            permissionGranted: permissionGranted,
            onChoirRoomModeChanged: onChoirRoomModeChanged,
            onRequireWakePhraseChanged: onRequireWakePhraseChanged,
            onWakePhraseChanged: onWakePhraseChanged,
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
    required this.loopArmed,
    required this.enabledPartIds,
    required this.measures,
    required this.rehearsalMarks,
  });

  final bool loaded;
  final bool isPlaying;
  final double tempoPercent;
  final int currentMeasure;
  final int? loopA;
  final int? loopB;
  final bool loopArmed;
  final Set<String> enabledPartIds;
  final List<int> measures;
  final Map<String, int> rehearsalMarks;

  factory RemoteState.fromMap(Map<String, dynamic>? raw) {
    if (raw == null) {
      return RemoteState.empty();
    }
    final enabledPartsRaw = raw['enabledParts'];
    final measuresRaw = raw['measures'];
    final rehearsalMarksRaw = raw['rehearsalMarks'];
    return RemoteState(
      loaded: raw['loaded'] == true,
      isPlaying: raw['isPlaying'] == true,
      tempoPercent: _parseDouble(raw['tempoPercent']) ?? 100,
      currentMeasure: _parseInt(raw['currentMeasure']) ?? 1,
      loopA: _parseInt(raw['loopA']),
      loopB: _parseInt(raw['loopB']),
      loopArmed: raw['loopArmed'] == true,
      enabledPartIds: enabledPartsRaw is List
          ? enabledPartsRaw.map((entry) => entry.toString()).toSet()
          : <String>{},
      measures: measuresRaw is List
          ? measuresRaw
                .map((entry) => _parseInt(entry))
                .whereType<int>()
                .toList()
          : <int>[],
      rehearsalMarks: rehearsalMarksRaw is Map
          ? Map<String, int>.fromEntries(
              rehearsalMarksRaw.entries
                  .map(
                    (entry) => MapEntry(
                      entry.key.toString().toUpperCase(),
                      _parseInt(entry.value) ?? 0,
                    ),
                  )
                  .where((entry) => entry.value > 0),
            )
          : <String, int>{},
    );
  }

  factory RemoteState.empty() => RemoteState(
    loaded: false,
    isPlaying: false,
    tempoPercent: 100,
    currentMeasure: 1,
    loopA: null,
    loopB: null,
    loopArmed: false,
    enabledPartIds: <String>{},
    measures: <int>[],
    rehearsalMarks: <String, int>{},
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

