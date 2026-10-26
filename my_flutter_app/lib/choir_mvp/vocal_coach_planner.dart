import 'warmups_library.dart';
import 'warmups_models.dart';
import 'vocal_coach_models.dart';

class VocalCoachPlanBundle {
  const VocalCoachPlanBundle({
    required this.profile,
    required this.plan,
    required this.suggestedExerciseWarmupIds,
    required this.suggestedDrill,
  });

  final VocalSkillProfile profile;
  final VocalTrainingPlan plan;
  final List<String> suggestedExerciseWarmupIds;
  final String suggestedDrill;
}

class VocalCoachPlanner {
  VocalCoachPlanner({
    List<Warmup>? warmupLibrary,
  }) : _warmupLibrary = warmupLibrary ?? WarmupsLibrary.buildAll();

  final List<Warmup> _warmupLibrary;

  VocalCoachPlanBundle buildPlanBundle({
    required String studentId,
    required String studentName,
    required VocalCoachMode mode,
    required Map<VocalCoachTaskType, VocalTaskMetrics> taskMetrics,
    String? sessionId,
    String? stationId,
    String? partId,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final profileScores = _computeProfileScores(taskMetrics);
    final lowConfidence = _hasLowConfidence(taskMetrics);
    final focusAreas = _pickFocusAreas(mode: mode, profileScores: profileScores);
    final profile = VocalSkillProfile(
      studentId: studentId,
      studentName: studentName,
      mode: mode,
      profileScores: profileScores,
      focusAreas: focusAreas,
      taskMetrics: taskMetrics,
      timestamp: timestamp,
      sessionId: sessionId,
      stationId: stationId,
      partId: partId,
      lowConfidence: lowConfidence,
    );

    final plan = _buildTrainingPlan(
      studentId: studentId,
      profile: profile,
      sessionId: sessionId,
      stationId: stationId,
      createdAt: timestamp,
    );

    final suggestedExerciseWarmupIds = _suggestTwoExercises(profile);
    final suggestedDrill = plan.items.isEmpty
        ? 'Sustained 6-second hum with steady onset.'
        : plan.items.first.drill;

    return VocalCoachPlanBundle(
      profile: profile,
      plan: plan,
      suggestedExerciseWarmupIds: suggestedExerciseWarmupIds,
      suggestedDrill: suggestedDrill,
    );
  }

  List<Warmup> warmupsForIds(List<String> warmupIds) {
    final byId = <String, Warmup>{};
    for (final warmup in _warmupLibrary) {
      byId[warmup.id] = warmup;
    }
    return warmupIds
        .map((id) => byId[id])
        .whereType<Warmup>()
        .toList(growable: false);
  }

  Map<String, int> _computeProfileScores(
    Map<VocalCoachTaskType, VocalTaskMetrics> taskMetrics,
  ) {
    final pitchMatch = taskMetrics[VocalCoachTaskType.pitchMatch];
    final fiveTone = taskMetrics[VocalCoachTaskType.fiveToneScale];
    final arpeggio = taskMetrics[VocalCoachTaskType.arpeggio1358531];
    final sustain = taskMetrics[VocalCoachTaskType.sustainSixSeconds];
    final rhythm = taskMetrics[VocalCoachTaskType.rhythmAlignmentToClick];

    final scores = <String, int>{
      VocalFocusArea.pitchStability.id: _avgInt([
        pitchMatch?.stabilityScore,
        fiveTone?.stabilityScore,
        arpeggio?.stabilityScore,
      ]),
      VocalFocusArea.sustainControl.id: _avgInt([
        sustain?.stabilityScore,
        sustain?.pitchAccuracy,
        sustain?.onsetTimingScore,
      ]),
      VocalFocusArea.headVoiceCoordination.id: _avgInt([
        arpeggio?.pitchAccuracy,
        arpeggio?.stabilityScore,
      ]),
      VocalFocusArea.leapAccuracy.id: _avgInt([
        arpeggio?.pitchAccuracy,
        arpeggio?.onsetTimingScore,
      ]),
      VocalFocusArea.rhythmAlignment.id: _avgInt([
        rhythm?.onsetTimingScore,
        rhythm?.stabilityScore,
      ]),
      VocalFocusArea.onsetClarity.id: _avgInt([
        pitchMatch?.onsetTimingScore,
        fiveTone?.onsetTimingScore,
        arpeggio?.onsetTimingScore,
        sustain?.onsetTimingScore,
      ]),
    };

    for (final entry in scores.entries.toList()) {
      scores[entry.key] = (entry.value.clamp(0, 100) as num).toInt();
    }
    return scores;
  }

  List<VocalFocusArea> _pickFocusAreas({
    required VocalCoachMode mode,
    required Map<String, int> profileScores,
  }) {
    final ranked = <MapEntry<VocalFocusArea, int>>[];
    for (final area in VocalFocusArea.values) {
      ranked.add(
        MapEntry(
          area,
          profileScores[area.id] ?? 0,
        ),
      );
    }
    ranked.sort((a, b) => a.value.compareTo(b.value));

    final maxAreas = mode == VocalCoachMode.quickSkillCheck ? 2 : 3;
    final threshold = mode == VocalCoachMode.quickSkillCheck ? 82 : 86;
    final picked = <VocalFocusArea>[];
    for (final entry in ranked) {
      if (entry.value <= threshold) {
        picked.add(entry.key);
      }
      if (picked.length >= maxAreas) {
        break;
      }
    }
    if (picked.isEmpty && ranked.isNotEmpty) {
      picked.add(ranked.first.key);
    }
    if (picked.length < maxAreas && ranked.length > picked.length) {
      for (final entry in ranked) {
        if (!picked.contains(entry.key)) {
          picked.add(entry.key);
        }
        if (picked.length >= maxAreas) {
          break;
        }
      }
    }
    return picked;
  }

  VocalTrainingPlan _buildTrainingPlan({
    required String studentId,
    required VocalSkillProfile profile,
    String? sessionId,
    String? stationId,
    required DateTime createdAt,
  }) {
    final levelHint = _recommendedLevel(profile.baselineComposite);
    final items = <VocalTrainingPlanItem>[];
    for (final area in profile.focusAreas) {
      final rule = _ruleFor(area);
      final warmups = _pickWarmups(
        categories: rule.categories,
        levelHint: levelHint,
        limit: 3,
      );
      items.add(
        VocalTrainingPlanItem(
          focusArea: area,
          warmupIds: warmups.map((entry) => entry.id).toList(growable: false),
          drill: rule.drill,
          recommendedFrequencyPerWeek: rule.frequencyPerWeek,
          sessionDurationMinutes: rule.sessionDurationMinutes,
        ),
      );
    }

    return VocalTrainingPlan(
      studentId: studentId,
      createdAt: createdAt,
      startDate: DateTime(createdAt.year, createdAt.month, createdAt.day),
      endDate: DateTime(
        createdAt.year,
        createdAt.month,
        createdAt.day,
      ).add(const Duration(days: 14)),
      items: items,
      sessionId: sessionId,
      stationId: stationId,
    );
  }

  List<String> _suggestTwoExercises(VocalSkillProfile profile) {
    final warmupIds = <String>{};
    for (final item in _buildTrainingPlan(
      studentId: profile.studentId,
      profile: profile,
      sessionId: profile.sessionId,
      stationId: profile.stationId,
      createdAt: profile.timestamp,
    ).items) {
      for (final id in item.warmupIds) {
        warmupIds.add(id);
        if (warmupIds.length >= 2) {
          return warmupIds.toList(growable: false);
        }
      }
    }
    if (warmupIds.length < 2 && _warmupLibrary.isNotEmpty) {
      for (final warmup in _warmupLibrary) {
        warmupIds.add(warmup.id);
        if (warmupIds.length >= 2) {
          break;
        }
      }
    }
    return warmupIds.toList(growable: false);
  }

  List<Warmup> _pickWarmups({
    required List<WarmupCategory> categories,
    required WarmupLevel levelHint,
    required int limit,
  }) {
    final selected = <Warmup>[];
    final seen = <String>{};
    for (final warmup in _warmupLibrary) {
      if (warmup.level != levelHint || !categories.contains(warmup.category)) {
        continue;
      }
      selected.add(warmup);
      seen.add(warmup.id);
      if (selected.length >= limit) {
        return selected;
      }
    }
    for (final warmup in _warmupLibrary) {
      if (!categories.contains(warmup.category) || seen.contains(warmup.id)) {
        continue;
      }
      selected.add(warmup);
      if (selected.length >= limit) {
        break;
      }
    }
    return selected;
  }

  WarmupLevel _recommendedLevel(int composite) {
    if (composite <= 66) {
      return WarmupLevel.ms;
    }
    if (composite <= 82) {
      return WarmupLevel.lhs;
    }
    return WarmupLevel.uhs;
  }

  bool _hasLowConfidence(Map<VocalCoachTaskType, VocalTaskMetrics> taskMetrics) {
    if (taskMetrics.isEmpty) {
      return true;
    }
    for (final entry in taskMetrics.values) {
      if (entry.lowConfidence || entry.confidenceScore < 45) {
        return true;
      }
    }
    return false;
  }
}

class _FocusRule {
  const _FocusRule({
    required this.categories,
    required this.drill,
    required this.frequencyPerWeek,
    required this.sessionDurationMinutes,
  });

  final List<WarmupCategory> categories;
  final String drill;
  final int frequencyPerWeek;
  final int sessionDurationMinutes;
}

_FocusRule _ruleFor(VocalFocusArea area) {
  switch (area) {
    case VocalFocusArea.pitchStability:
      return const _FocusRule(
        categories: [
          WarmupCategory.intonationTuningDrone,
          WarmupCategory.blendUnison,
          WarmupCategory.vowelsResonance,
        ],
        drill: 'Hold scale degree 3 against a drone for 8 seconds, 4 reps.',
        frequencyPerWeek: 4,
        sessionDurationMinutes: 7,
      );
    case VocalFocusArea.sustainControl:
      return const _FocusRule(
        categories: [
          WarmupCategory.breathSupport,
          WarmupCategory.legatoLine,
          WarmupCategory.dynamicControl,
        ],
        drill: '6-second hiss + 6-second sung sustain, 5 cycles.',
        frequencyPerWeek: 4,
        sessionDurationMinutes: 8,
      );
    case VocalFocusArea.headVoiceCoordination:
      return const _FocusRule(
        categories: [
          WarmupCategory.headVoiceRegistration,
          WarmupCategory.placementForwardTone,
          WarmupCategory.rangeBuilder,
        ],
        drill: 'Light siren glide 1-5-8-5-1 with no chest push, 6 reps.',
        frequencyPerWeek: 3,
        sessionDurationMinutes: 6,
      );
    case VocalFocusArea.leapAccuracy:
      return const _FocusRule(
        categories: [
          WarmupCategory.agilityFlexibility,
          WarmupCategory.rangeBuilder,
          WarmupCategory.headVoiceRegistration,
        ],
        drill: 'Triad leap target drill (1-5-8-5-1) at two tempos.',
        frequencyPerWeek: 4,
        sessionDurationMinutes: 7,
      );
    case VocalFocusArea.rhythmAlignment:
      return const _FocusRule(
        categories: [
          WarmupCategory.staccatoPrecision,
          WarmupCategory.dictionArticulation,
          WarmupCategory.agilityFlexibility,
        ],
        drill: 'Speak-clap-sing on click (quarter + eighth pattern), 4 rounds.',
        frequencyPerWeek: 3,
        sessionDurationMinutes: 6,
      );
    case VocalFocusArea.onsetClarity:
      return const _FocusRule(
        categories: [
          WarmupCategory.dictionArticulation,
          WarmupCategory.staccatoPrecision,
          WarmupCategory.placementForwardTone,
        ],
        drill: 'Gee/Geh clean onset ladder, medium volume, 5 reps.',
        frequencyPerWeek: 3,
        sessionDurationMinutes: 5,
      );
  }
}

int _avgInt(List<int?> values) {
  var total = 0;
  var count = 0;
  for (final value in values) {
    if (value == null) {
      continue;
    }
    total += value;
    count += 1;
  }
  if (count == 0) {
    return 0;
  }
  return (total / count).round();
}

