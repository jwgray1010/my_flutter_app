import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'checkin_assessment.dart';
import 'vocal_coach_assessment.dart';
import 'vocal_coach_models.dart';
import 'vocal_coach_planner.dart';

typedef SaveVocalCoachProfile =
    Future<void> Function(VocalSkillProfile profile, VocalTrainingPlan plan);
typedef SaveVocalCoachProgress = Future<void> Function(VocalSessionProgress progress);
typedef RunWarmupById = Future<void> Function(String warmupId);

class VocalCoachScreen extends StatefulWidget {
  const VocalCoachScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.onSaveProfile,
    required this.onSaveProgress,
    this.title = 'Vocal Development Coach',
    this.sessionId,
    this.stationId,
    this.partId,
    this.onRunWarmup,
  });

  final String studentId;
  final String studentName;
  final String title;
  final String? sessionId;
  final String? stationId;
  final String? partId;
  final SaveVocalCoachProfile onSaveProfile;
  final SaveVocalCoachProgress onSaveProgress;
  final RunWarmupById? onRunWarmup;

  @override
  State<VocalCoachScreen> createState() => _VocalCoachScreenState();
}

enum _CoachPhase {
  selectMode,
  assessment,
  result,
  session,
}

class _VocalCoachScreenState extends State<VocalCoachScreen> {
  final VocalCoachAssessmentEngine _assessmentEngine = VocalCoachAssessmentEngine();
  final VocalCoachPlanner _planner = VocalCoachPlanner();
  final Map<VocalCoachTaskType, VocalTaskMetrics> _taskMetrics =
      <VocalCoachTaskType, VocalTaskMetrics>{};
  final Set<String> _completedWarmupIds = <String>{};

  _CoachPhase _phase = _CoachPhase.selectMode;
  VocalCoachMode? _mode;
  bool _runningTask = false;
  String? _statusLine;
  int _taskIndex = 0;
  bool _drillCompleted = false;
  int? _microCheckScore;
  VocalCoachPlanBundle? _bundle;
  NoiseProbeResult? _lastNoiseProbe;

  @override
  void dispose() {
    unawaited(_assessmentEngine.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CoachTokens.bg,
      appBar: AppBar(
        backgroundColor: _CoachTokens.bg,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_phase) {
      case _CoachPhase.selectMode:
        return _buildModeSelection();
      case _CoachPhase.assessment:
        return _buildAssessment();
      case _CoachPhase.result:
        return _buildResult();
      case _CoachPhase.session:
        return _buildSession();
    }
  }

  Widget _buildModeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.studentName.toUpperCase(),
          textAlign: TextAlign.center,
          style: _CoachTokens.title,
        ),
        const SizedBox(height: 8),
        const Text(
          'On-device coach. No raw audio is stored.',
          textAlign: TextAlign.center,
          style: _CoachTokens.subtitle,
        ),
        const SizedBox(height: 20),
        _CoachButton(
          label: 'Mode A - Quick Skill Check',
          subtitle: '3-5 min, returns 1-2 focus areas + 2 exercises',
          accent: true,
          onPressed: () => _startMode(VocalCoachMode.quickSkillCheck),
        ),
        const SizedBox(height: 12),
        _CoachButton(
          label: 'Mode B - Full Pre-Assessment',
          subtitle: '5-7 min, generates 2-week training plan',
          onPressed: () => _startMode(VocalCoachMode.fullPreAssessment),
        ),
        if (_statusLine != null) ...[
          const SizedBox(height: 16),
          Text(
            _statusLine!,
            textAlign: TextAlign.center,
            style: _CoachTokens.subtitle,
          ),
        ],
      ],
    );
  }

  Widget _buildAssessment() {
    final mode = _mode!;
    final tasks = _tasksForMode(mode);
    final currentTask = tasks[_taskIndex];
    final metrics = _taskMetrics[currentTask];
    final progressLabel = '${_taskIndex + 1}/${tasks.length}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          mode.title.toUpperCase(),
          textAlign: TextAlign.center,
          style: _CoachTokens.title,
        ),
        const SizedBox(height: 6),
        Text(
          'Task $progressLabel: ${currentTask.title}',
          textAlign: TextAlign.center,
          style: _CoachTokens.sectionTitle,
        ),
        const SizedBox(height: 12),
        if (_lastNoiseProbe != null) _NoiseBadge(noise: _lastNoiseProbe!),
        const SizedBox(height: 10),
        if (metrics != null)
          _MetricsCard(
            metrics: metrics,
            title: currentTask.title,
          )
        else
          const _InstructionCard(
            text:
                'Stand close to device. Use clear onset. If noisy, move closer to mic.',
          ),
        const SizedBox(height: 16),
        _CoachButton(
          label: _runningTask ? 'RUNNING...' : 'RUN TASK',
          accent: true,
          onPressed: _runningTask ? null : () => _runTask(currentTask),
        ),
        const SizedBox(height: 12),
        _CoachButton(
          label: _taskIndex >= tasks.length - 1 ? 'FINISH ASSESSMENT' : 'NEXT TASK',
          onPressed: _canAdvance(currentTask) ? _advanceTask : null,
        ),
        const SizedBox(height: 12),
        _CoachButton(
          label: 'RESTART',
          outlined: true,
          onPressed: _resetAssessment,
        ),
        if (_statusLine != null) ...[
          const SizedBox(height: 12),
          Text(
            _statusLine!,
            textAlign: TextAlign.center,
            style: _CoachTokens.subtitle,
          ),
        ],
      ],
    );
  }

  Widget _buildResult() {
    final bundle = _bundle;
    if (bundle == null) {
      return const SizedBox.shrink();
    }
    final profile = bundle.profile;
    final focusText = profile.focusAreas.map((entry) => entry.title).join(' | ');
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Focus Areas',
            textAlign: TextAlign.center,
            style: _CoachTokens.title,
          ),
          const SizedBox(height: 8),
          Text(
            focusText.isEmpty ? 'No major flags' : focusText,
            textAlign: TextAlign.center,
            style: _CoachTokens.sectionTitle,
          ),
          const SizedBox(height: 12),
          _ProfileScoreCard(scores: profile.profileScores),
          const SizedBox(height: 12),
          if (_mode == VocalCoachMode.quickSkillCheck)
            _QuickSuggestionCard(
              warmupIds: bundle.suggestedExerciseWarmupIds,
              drill: bundle.suggestedDrill,
            )
          else
            _PlanCard(plan: bundle.plan),
          const SizedBox(height: 14),
          _CoachButton(
            label: "START TODAY'S SESSION",
            accent: true,
            onPressed: () {
              setState(() {
                _phase = _CoachPhase.session;
                _statusLine = null;
                _completedWarmupIds.clear();
                _drillCompleted = false;
                _microCheckScore = null;
              });
            },
          ),
          const SizedBox(height: 10),
          _CoachButton(
            label: 'RUN NEW ASSESSMENT',
            outlined: true,
            onPressed: _resetAssessment,
          ),
        ],
      ),
    );
  }

  Widget _buildSession() {
    final bundle = _bundle;
    if (bundle == null) {
      return const SizedBox.shrink();
    }
    final warmupIds = <String>[];
    if (_mode == VocalCoachMode.quickSkillCheck) {
      warmupIds.addAll(bundle.suggestedExerciseWarmupIds.take(2));
    } else {
      for (final item in bundle.plan.items) {
        for (final warmupId in item.warmupIds) {
          warmupIds.add(warmupId);
          if (warmupIds.length >= 2) {
            break;
          }
        }
        if (warmupIds.length >= 2) {
          break;
        }
      }
    }
    final canSave =
        _completedWarmupIds.length >= warmupIds.length &&
        _drillCompleted &&
        _microCheckScore != null;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Today's Session",
            textAlign: TextAlign.center,
            style: _CoachTokens.title,
          ),
          const SizedBox(height: 6),
          Text(
            bundle.profile.focusAreas.map((entry) => entry.title).join(' | '),
            textAlign: TextAlign.center,
            style: _CoachTokens.subtitle,
          ),
          const SizedBox(height: 14),
          for (final warmupId in warmupIds)
            _SessionStepCard(
              title: 'Warmup: $warmupId',
              completed: _completedWarmupIds.contains(warmupId),
              onRun: widget.onRunWarmup == null
                  ? null
                  : () => widget.onRunWarmup!(warmupId),
              onDone: () {
                setState(() {
                  _completedWarmupIds.add(warmupId);
                });
              },
            ),
          _SessionStepCard(
            title: 'Drill: ${bundle.suggestedDrill}',
            completed: _drillCompleted,
            onDone: () {
              setState(() {
                _drillCompleted = true;
              });
            },
          ),
          _SessionStepCard(
            title: _microCheckScore == null
                ? 'Micro-check'
                : 'Micro-check score: $_microCheckScore',
            completed: _microCheckScore != null,
            actionLabel: _runningTask ? 'RUNNING...' : 'RUN MICRO-CHECK',
            onRun: _runningTask ? null : _runMicroCheck,
          ),
          const SizedBox(height: 12),
          _CoachButton(
            label: 'SAVE PROGRESS',
            accent: true,
            onPressed: canSave ? () => _saveProgress(warmupIds) : null,
          ),
          const SizedBox(height: 10),
          _CoachButton(
            label: 'BACK TO RESULTS',
            outlined: true,
            onPressed: () {
              setState(() {
                _phase = _CoachPhase.result;
              });
            },
          ),
          if (_statusLine != null) ...[
            const SizedBox(height: 10),
            Text(
              _statusLine!,
              textAlign: TextAlign.center,
              style: _CoachTokens.subtitle,
            ),
          ],
        ],
      ),
    );
  }

  void _startMode(VocalCoachMode mode) {
    setState(() {
      _mode = mode;
      _phase = _CoachPhase.assessment;
      _taskMetrics.clear();
      _statusLine = null;
      _taskIndex = 0;
      _bundle = null;
      _lastNoiseProbe = null;
    });
  }

  List<VocalCoachTaskType> _tasksForMode(VocalCoachMode mode) {
    if (mode == VocalCoachMode.quickSkillCheck) {
      return const <VocalCoachTaskType>[
        VocalCoachTaskType.pitchMatch,
        VocalCoachTaskType.arpeggio1358531,
        VocalCoachTaskType.rhythmAlignmentToClick,
      ];
    }
    return const <VocalCoachTaskType>[
      VocalCoachTaskType.pitchMatch,
      VocalCoachTaskType.fiveToneScale,
      VocalCoachTaskType.arpeggio1358531,
      VocalCoachTaskType.sustainSixSeconds,
      VocalCoachTaskType.rhythmAlignmentToClick,
    ];
  }

  bool _canAdvance(VocalCoachTaskType task) {
    return _taskMetrics.containsKey(task) && !_runningTask;
  }

  Future<void> _runTask(VocalCoachTaskType task) async {
    setState(() {
      _runningTask = true;
      _statusLine = 'Checking room noise...';
    });
    final noise = await _assessmentEngine.measureNoise();
    if (!mounted) {
      return;
    }
    if (noise.tooLoud) {
      setState(() {
        _runningTask = false;
        _lastNoiseProbe = noise;
        _statusLine = 'Low confidence - move closer (room is too loud).';
      });
      return;
    }
    setState(() {
      _statusLine = 'Recording ${task.title}...';
      _lastNoiseProbe = noise;
    });
    if (task == VocalCoachTaskType.rhythmAlignmentToClick) {
      await _playCountInClicks();
    }
    final metrics = await _assessmentEngine.runTask(task);
    if (!mounted) {
      return;
    }
    setState(() {
      _taskMetrics[task] = metrics;
      _runningTask = false;
      _statusLine = metrics.lowConfidence
          ? 'Low confidence - move closer and retry.'
          : 'Task captured.';
    });
  }

  Future<void> _playCountInClicks() async {
    for (var i = 0; i < 4; i++) {
      SystemSound.play(SystemSoundType.click);
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
  }

  void _advanceTask() {
    final mode = _mode;
    if (mode == null) {
      return;
    }
    final tasks = _tasksForMode(mode);
    if (_taskIndex < tasks.length - 1) {
      setState(() {
        _taskIndex += 1;
        _statusLine = null;
      });
      return;
    }
    final bundle = _planner.buildPlanBundle(
      studentId: widget.studentId,
      studentName: widget.studentName,
      mode: mode,
      taskMetrics: _taskMetrics,
      sessionId: widget.sessionId,
      stationId: widget.stationId,
      partId: widget.partId,
    );
    if (bundle.profile.lowConfidence) {
      setState(() {
        _statusLine = 'Low confidence - move closer and retry assessment.';
      });
      return;
    }
    unawaited(widget.onSaveProfile(bundle.profile, bundle.plan));
    setState(() {
      _bundle = bundle;
      _phase = _CoachPhase.result;
      _statusLine = null;
    });
  }

  void _resetAssessment() {
    setState(() {
      _phase = _CoachPhase.selectMode;
      _mode = null;
      _taskMetrics.clear();
      _taskIndex = 0;
      _statusLine = null;
      _bundle = null;
      _runningTask = false;
      _lastNoiseProbe = null;
      _completedWarmupIds.clear();
      _drillCompleted = false;
      _microCheckScore = null;
    });
  }

  Future<void> _runMicroCheck() async {
    setState(() {
      _runningTask = true;
      _statusLine = 'Running micro-check...';
    });
    final noise = await _assessmentEngine.measureNoise(
      duration: const Duration(seconds: 1),
    );
    if (!mounted) {
      return;
    }
    if (noise.tooLoud) {
      setState(() {
        _runningTask = false;
        _statusLine = 'Low confidence - move closer.';
      });
      return;
    }
    final metrics = await _assessmentEngine.runTask(
      VocalCoachTaskType.pitchMatch,
      duration: const Duration(seconds: 4),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _runningTask = false;
      _microCheckScore = ((((metrics.pitchAccuracy + metrics.stabilityScore) / 2)
                      .round()
                      .clamp(0, 100))
                  as num)
              .toInt();
      _statusLine = metrics.lowConfidence
          ? 'Low confidence - retry micro-check.'
          : 'Micro-check saved.';
    });
  }

  Future<void> _saveProgress(List<String> warmupIds) async {
    final bundle = _bundle;
    final microCheckScore = _microCheckScore;
    if (bundle == null || microCheckScore == null) {
      return;
    }
    final progress = VocalSessionProgress(
      studentId: widget.studentId,
      studentName: widget.studentName,
      timestamp: DateTime.now(),
      completedWarmupIds: _completedWarmupIds.toList(growable: false),
      drillCompleted: _drillCompleted,
      microCheckScore: microCheckScore,
      focusAreasWorked: bundle.profile.focusAreas,
      sessionId: widget.sessionId,
      stationId: widget.stationId,
    );
    await widget.onSaveProgress(progress);
    if (!mounted) {
      return;
    }
    setState(() {
      _statusLine = 'Progress saved.';
      for (final warmupId in warmupIds) {
        _completedWarmupIds.remove(warmupId);
      }
      _drillCompleted = false;
      _microCheckScore = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progress saved.')),
    );
  }
}

class _CoachButton extends StatelessWidget {
  const _CoachButton({
    required this.label,
    this.subtitle,
    this.onPressed,
    this.accent = false,
    this.outlined = false,
  });

  final String label;
  final String? subtitle;
  final VoidCallback? onPressed;
  final bool accent;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final background = accent ? _CoachTokens.accent : _CoachTokens.card;
    final border = outlined
        ? const BorderSide(color: _CoachTokens.border, width: 1.2)
        : BorderSide.none;
    return SizedBox(
      height: subtitle == null ? 82 : 98,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: _CoachTokens.textPrimary,
          disabledBackgroundColor: _CoachTokens.card.withOpacity(0.45),
          disabledForegroundColor: _CoachTokens.textSecondary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: border,
          ),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _CoachTokens.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _CoachTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _CoachTokens.border),
      ),
      child: Text(
        text,
        style: _CoachTokens.subtitle,
      ),
    );
  }
}

class _NoiseBadge extends StatelessWidget {
  const _NoiseBadge({
    required this.noise,
  });

  final NoiseProbeResult noise;

  @override
  Widget build(BuildContext context) {
    final label = noise.tooLoud
        ? 'Noise high (${noise.rmsDbFs.toStringAsFixed(1)} dBFS)'
        : 'Noise OK (${noise.rmsDbFs.toStringAsFixed(1)} dBFS)';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: noise.tooLoud ? const Color(0xFF3A2323) : const Color(0xFF233A2B),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _CoachTokens.border),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _CoachTokens.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({
    required this.metrics,
    required this.title,
  });

  final VocalTaskMetrics metrics;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _CoachTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _CoachTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _CoachTokens.sectionTitle),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _MetricTag(label: 'Pitch ${metrics.pitchAccuracy}'),
              _MetricTag(label: 'Stability ${metrics.stabilityScore}'),
              _MetricTag(label: 'Onset ${metrics.onsetTimingScore}'),
              _MetricTag(label: 'Conf ${metrics.confidenceScore}'),
            ],
          ),
          if (metrics.lowConfidence) ...[
            const SizedBox(height: 8),
            const Text(
              'Low confidence - move closer.',
              style: TextStyle(color: Colors.amber),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricTag extends StatelessWidget {
  const _MetricTag({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _CoachTokens.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _CoachTokens.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProfileScoreCard extends StatelessWidget {
  const _ProfileScoreCard({
    required this.scores,
  });

  final Map<String, int> scores;

  @override
  Widget build(BuildContext context) {
    final entries = scores.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _CoachTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _CoachTokens.border),
      ),
      child: Column(
        children: [
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: _CoachTokens.subtitle,
                    ),
                  ),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(
                      color: _CoachTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickSuggestionCard extends StatelessWidget {
  const _QuickSuggestionCard({
    required this.warmupIds,
    required this.drill,
  });

  final List<String> warmupIds;
  final String drill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _CoachTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _CoachTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Suggested Exercises', style: _CoachTokens.sectionTitle),
          const SizedBox(height: 8),
          for (final id in warmupIds)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('- Warmup: $id', style: _CoachTokens.subtitle),
            ),
          const SizedBox(height: 4),
          Text('- Drill: $drill', style: _CoachTokens.subtitle),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
  });

  final VocalTrainingPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _CoachTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _CoachTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('2-Week Plan', style: _CoachTokens.sectionTitle),
          const SizedBox(height: 6),
          Text(
            '${plan.startDate.month}/${plan.startDate.day} - ${plan.endDate.month}/${plan.endDate.day}',
            style: _CoachTokens.subtitle,
          ),
          const SizedBox(height: 8),
          for (final item in plan.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.focusArea.title,
                    style: const TextStyle(
                      color: _CoachTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Warmups: ${item.warmupIds.take(3).join(', ')}',
                    style: _CoachTokens.subtitle,
                  ),
                  Text(
                    'Drill: ${item.drill}',
                    style: _CoachTokens.subtitle,
                  ),
                  Text(
                    '${item.recommendedFrequencyPerWeek}x/week | ${item.sessionDurationMinutes} min',
                    style: _CoachTokens.subtitle,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionStepCard extends StatelessWidget {
  const _SessionStepCard({
    required this.title,
    required this.completed,
    this.onRun,
    this.onDone,
    this.actionLabel = 'RUN',
  });

  final String title;
  final bool completed;
  final VoidCallback? onRun;
  final VoidCallback? onDone;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _CoachTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _CoachTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            completed ? '$title  [DONE]' : title,
            style: const TextStyle(
              color: _CoachTokens.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (onRun != null)
                Expanded(
                  child: _CoachButton(
                    label: actionLabel,
                    onPressed: onRun,
                  ),
                ),
              if (onRun != null && onDone != null) const SizedBox(width: 8),
              if (onDone != null)
                Expanded(
                  child: _CoachButton(
                    label: completed ? 'DONE' : 'MARK DONE',
                    accent: completed,
                    onPressed: onDone,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoachTokens {
  static const bg = Color(0xFF15181D);
  static const card = Color(0xFF1E232B);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color.fromRGBO(255, 255, 255, 0.70);
  static const border = Color.fromRGBO(255, 255, 255, 0.12);
  static const accent = Color(0xFF6E5BFF);

  static const title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );
}

