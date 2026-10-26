enum VocalCoachMode {
  quickSkillCheck,
  fullPreAssessment,
}

extension VocalCoachModeX on VocalCoachMode {
  String get id {
    switch (this) {
      case VocalCoachMode.quickSkillCheck:
        return 'QUICK_SKILL_CHECK';
      case VocalCoachMode.fullPreAssessment:
        return 'FULL_PRE_ASSESSMENT';
    }
  }

  String get title {
    switch (this) {
      case VocalCoachMode.quickSkillCheck:
        return 'Quick Skill Check';
      case VocalCoachMode.fullPreAssessment:
        return 'Full Pre-Assessment';
    }
  }
}

VocalCoachMode? vocalCoachModeFromId(String raw) {
  final normalized = raw.trim().toUpperCase();
  for (final value in VocalCoachMode.values) {
    if (value.id == normalized) {
      return value;
    }
  }
  return null;
}

enum VocalCoachTaskType {
  pitchMatch,
  fiveToneScale,
  arpeggio1358531,
  sustainSixSeconds,
  rhythmAlignmentToClick,
}

extension VocalCoachTaskTypeX on VocalCoachTaskType {
  String get id {
    switch (this) {
      case VocalCoachTaskType.pitchMatch:
        return 'PITCH_MATCH';
      case VocalCoachTaskType.fiveToneScale:
        return 'FIVE_TONE_SCALE';
      case VocalCoachTaskType.arpeggio1358531:
        return 'ARPEGGIO_1358531';
      case VocalCoachTaskType.sustainSixSeconds:
        return 'SUSTAIN_6_SECONDS';
      case VocalCoachTaskType.rhythmAlignmentToClick:
        return 'RHYTHM_ALIGNMENT_TO_CLICK';
    }
  }

  String get title {
    switch (this) {
      case VocalCoachTaskType.pitchMatch:
        return 'Pitch match (5 notes)';
      case VocalCoachTaskType.fiveToneScale:
        return '5-tone scale';
      case VocalCoachTaskType.arpeggio1358531:
        return 'Arpeggio 1-3-5-8-5-3-1';
      case VocalCoachTaskType.sustainSixSeconds:
        return 'Sustain 6 seconds';
      case VocalCoachTaskType.rhythmAlignmentToClick:
        return 'Rhythm alignment to click';
    }
  }
}

VocalCoachTaskType? vocalCoachTaskTypeFromId(String raw) {
  final normalized = raw.trim().toUpperCase();
  for (final value in VocalCoachTaskType.values) {
    if (value.id == normalized) {
      return value;
    }
  }
  return null;
}

class VocalTaskMetrics {
  const VocalTaskMetrics({
    required this.pitchAccuracy,
    required this.stabilityScore,
    required this.onsetTimingScore,
    required this.confidenceScore,
    this.lowConfidence = false,
  });

  final int pitchAccuracy;
  final int stabilityScore;
  final int onsetTimingScore;
  final int confidenceScore;
  final bool lowConfidence;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pitchAccuracy': pitchAccuracy,
      'stabilityScore': stabilityScore,
      'onsetTimingScore': onsetTimingScore,
      'confidenceScore': confidenceScore,
      'lowConfidence': lowConfidence,
    };
  }

  factory VocalTaskMetrics.fromMap(Map<String, dynamic> map) {
    return VocalTaskMetrics(
      pitchAccuracy: _toInt(map['pitchAccuracy']) ?? 0,
      stabilityScore: _toInt(map['stabilityScore']) ?? 0,
      onsetTimingScore: _toInt(map['onsetTimingScore']) ?? 0,
      confidenceScore: _toInt(map['confidenceScore']) ?? 0,
      lowConfidence: map['lowConfidence'] == true,
    );
  }
}

enum VocalFocusArea {
  pitchStability,
  sustainControl,
  headVoiceCoordination,
  leapAccuracy,
  rhythmAlignment,
  onsetClarity,
}

extension VocalFocusAreaX on VocalFocusArea {
  String get id {
    switch (this) {
      case VocalFocusArea.pitchStability:
        return 'pitch_stability';
      case VocalFocusArea.sustainControl:
        return 'sustain_control';
      case VocalFocusArea.headVoiceCoordination:
        return 'head_voice_coordination';
      case VocalFocusArea.leapAccuracy:
        return 'leap_accuracy';
      case VocalFocusArea.rhythmAlignment:
        return 'rhythm_alignment';
      case VocalFocusArea.onsetClarity:
        return 'onset_clarity';
    }
  }

  String get title {
    switch (this) {
      case VocalFocusArea.pitchStability:
        return 'Pitch Stability';
      case VocalFocusArea.sustainControl:
        return 'Sustain Control';
      case VocalFocusArea.headVoiceCoordination:
        return 'Head Voice Coordination';
      case VocalFocusArea.leapAccuracy:
        return 'Leap Accuracy';
      case VocalFocusArea.rhythmAlignment:
        return 'Rhythm Alignment';
      case VocalFocusArea.onsetClarity:
        return 'Onset Clarity';
    }
  }
}

VocalFocusArea? vocalFocusAreaFromId(String raw) {
  final normalized = raw.trim().toLowerCase();
  for (final value in VocalFocusArea.values) {
    if (value.id == normalized) {
      return value;
    }
  }
  return null;
}

class VocalSkillProfile {
  const VocalSkillProfile({
    required this.studentId,
    required this.studentName,
    required this.mode,
    required this.profileScores,
    required this.focusAreas,
    required this.taskMetrics,
    required this.timestamp,
    this.sessionId,
    this.stationId,
    this.partId,
    this.lowConfidence = false,
  });

  final String studentId;
  final String studentName;
  final VocalCoachMode mode;
  final Map<String, int> profileScores;
  final List<VocalFocusArea> focusAreas;
  final Map<VocalCoachTaskType, VocalTaskMetrics> taskMetrics;
  final DateTime timestamp;
  final String? sessionId;
  final String? stationId;
  final String? partId;
  final bool lowConfidence;

  int get baselineComposite {
    if (profileScores.isEmpty) {
      return 0;
    }
    final total = profileScores.values.fold<int>(0, (sum, value) => sum + value);
    return (total / profileScores.length).round();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'studentId': studentId,
      'studentName': studentName,
      'mode': mode.id,
      'profileScores': profileScores,
      'focusAreas': focusAreas.map((entry) => entry.id).toList(),
      'taskMetrics': taskMetrics.map(
        (key, value) => MapEntry<String, dynamic>(key.id, value.toMap()),
      ),
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'stationId': stationId,
      'partId': partId,
      'lowConfidence': lowConfidence,
    };
  }

  factory VocalSkillProfile.fromMap(Map<String, dynamic> map) {
    final scoresRaw = map['profileScores'];
    final scores = <String, int>{};
    if (scoresRaw is Map) {
      for (final entry in scoresRaw.entries) {
        final score = _toInt(entry.value);
        if (score != null) {
          scores[entry.key.toString()] = score;
        }
      }
    }

    final focusRaw = map['focusAreas'];
    final focusAreas = <VocalFocusArea>[];
    if (focusRaw is List) {
      for (final value in focusRaw) {
        final parsed = vocalFocusAreaFromId(value.toString());
        if (parsed != null) {
          focusAreas.add(parsed);
        }
      }
    }

    final taskRaw = map['taskMetrics'];
    final taskMetrics = <VocalCoachTaskType, VocalTaskMetrics>{};
    if (taskRaw is Map) {
      for (final entry in taskRaw.entries) {
        final task = vocalCoachTaskTypeFromId(entry.key.toString());
        final value = entry.value;
        if (task == null || value is! Map) {
          continue;
        }
        taskMetrics[task] = VocalTaskMetrics.fromMap(
          value.cast<String, dynamic>(),
        );
      }
    }

    return VocalSkillProfile(
      studentId: map['studentId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      mode: vocalCoachModeFromId(map['mode']?.toString() ?? '') ??
          VocalCoachMode.quickSkillCheck,
      profileScores: scores,
      focusAreas: focusAreas,
      taskMetrics: taskMetrics,
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      sessionId: map['sessionId']?.toString(),
      stationId: map['stationId']?.toString(),
      partId: map['partId']?.toString(),
      lowConfidence: map['lowConfidence'] == true,
    );
  }
}

class VocalTrainingPlanItem {
  const VocalTrainingPlanItem({
    required this.focusArea,
    required this.warmupIds,
    required this.drill,
    required this.recommendedFrequencyPerWeek,
    required this.sessionDurationMinutes,
  });

  final VocalFocusArea focusArea;
  final List<String> warmupIds;
  final String drill;
  final int recommendedFrequencyPerWeek;
  final int sessionDurationMinutes;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'focusArea': focusArea.id,
      'warmupIds': warmupIds,
      'drill': drill,
      'recommendedFrequencyPerWeek': recommendedFrequencyPerWeek,
      'sessionDurationMinutes': sessionDurationMinutes,
    };
  }

  factory VocalTrainingPlanItem.fromMap(Map<String, dynamic> map) {
    final warmupsRaw = map['warmupIds'];
    return VocalTrainingPlanItem(
      focusArea: vocalFocusAreaFromId(map['focusArea']?.toString() ?? '') ??
          VocalFocusArea.pitchStability,
      warmupIds: warmupsRaw is List
          ? warmupsRaw.map((entry) => entry.toString()).toList()
          : const <String>[],
      drill: map['drill']?.toString() ?? '',
      recommendedFrequencyPerWeek:
          (((_toInt(map['recommendedFrequencyPerWeek']) ?? 3).clamp(1, 7)) as num)
              .toInt(),
      sessionDurationMinutes:
          (((_toInt(map['sessionDurationMinutes']) ?? 6).clamp(1, 20)) as num)
              .toInt(),
    );
  }
}

class VocalTrainingPlan {
  const VocalTrainingPlan({
    required this.studentId,
    required this.createdAt,
    required this.startDate,
    required this.endDate,
    required this.items,
    this.sessionId,
    this.stationId,
  });

  final String studentId;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime endDate;
  final List<VocalTrainingPlanItem> items;
  final String? sessionId;
  final String? stationId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'studentId': studentId,
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'items': items.map((entry) => entry.toMap()).toList(),
      'sessionId': sessionId,
      'stationId': stationId,
    };
  }

  factory VocalTrainingPlan.fromMap(Map<String, dynamic> map) {
    final itemsRaw = map['items'];
    final items = <VocalTrainingPlanItem>[];
    if (itemsRaw is List) {
      for (final entry in itemsRaw) {
        if (entry is Map) {
          items.add(VocalTrainingPlanItem.fromMap(entry.cast<String, dynamic>()));
        }
      }
    }
    return VocalTrainingPlan(
      studentId: map['studentId']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      startDate: DateTime.tryParse(map['startDate']?.toString() ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse(map['endDate']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 14)),
      items: items,
      sessionId: map['sessionId']?.toString(),
      stationId: map['stationId']?.toString(),
    );
  }
}

class VocalSessionProgress {
  const VocalSessionProgress({
    required this.studentId,
    required this.studentName,
    required this.timestamp,
    required this.completedWarmupIds,
    required this.drillCompleted,
    required this.microCheckScore,
    required this.focusAreasWorked,
    this.sessionId,
    this.stationId,
  });

  final String studentId;
  final String studentName;
  final DateTime timestamp;
  final List<String> completedWarmupIds;
  final bool drillCompleted;
  final int microCheckScore;
  final List<VocalFocusArea> focusAreasWorked;
  final String? sessionId;
  final String? stationId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'studentId': studentId,
      'studentName': studentName,
      'timestamp': timestamp.toIso8601String(),
      'completedWarmupIds': completedWarmupIds,
      'drillCompleted': drillCompleted,
      'microCheckScore': microCheckScore,
      'focusAreasWorked': focusAreasWorked.map((entry) => entry.id).toList(),
      'sessionId': sessionId,
      'stationId': stationId,
    };
  }

  factory VocalSessionProgress.fromMap(Map<String, dynamic> map) {
    final warmupsRaw = map['completedWarmupIds'];
    final focusRaw = map['focusAreasWorked'];
    final focus = <VocalFocusArea>[];
    if (focusRaw is List) {
      for (final value in focusRaw) {
        final parsed = vocalFocusAreaFromId(value.toString());
        if (parsed != null) {
          focus.add(parsed);
        }
      }
    }
    return VocalSessionProgress(
      studentId: map['studentId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      completedWarmupIds: warmupsRaw is List
          ? warmupsRaw.map((entry) => entry.toString()).toList()
          : const <String>[],
      drillCompleted: map['drillCompleted'] == true,
      microCheckScore: _toInt(map['microCheckScore']) ?? 0,
      focusAreasWorked: focus,
      sessionId: map['sessionId']?.toString(),
      stationId: map['stationId']?.toString(),
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

