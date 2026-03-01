import 'models.dart';

enum CheckInTier {
  partWithMe,
  acapellaClick,
  partPlusAccomp,
  accompOnly,
  accompPlusOtherParts,
}

extension CheckInTierX on CheckInTier {
  String get id {
    switch (this) {
      case CheckInTier.partWithMe:
        return 'PART_WITH_ME';
      case CheckInTier.acapellaClick:
        return 'ACAPELLA_CLICK';
      case CheckInTier.partPlusAccomp:
        return 'PART_PLUS_ACCOMP';
      case CheckInTier.accompOnly:
        return 'ACCOMP_ONLY';
      case CheckInTier.accompPlusOtherParts:
        return 'ACCOMP_PLUS_OTHER_PARTS';
    }
  }

  String get shortLabel {
    switch (this) {
      case CheckInTier.partWithMe:
        return 'Step 1';
      case CheckInTier.acapellaClick:
        return 'Step 2';
      case CheckInTier.partPlusAccomp:
        return 'Step 3';
      case CheckInTier.accompOnly:
        return 'Step 4';
      case CheckInTier.accompPlusOtherParts:
        return 'Step 5';
    }
  }

  String get title {
    switch (this) {
      case CheckInTier.partWithMe:
        return 'With Your Part';
      case CheckInTier.acapellaClick:
        return 'A Cappella + Click';
      case CheckInTier.partPlusAccomp:
        return 'With Piano';
      case CheckInTier.accompOnly:
        return 'Piano Only (Challenge)';
      case CheckInTier.accompPlusOtherParts:
        return 'Full Choir Minus You (Challenge)';
    }
  }

  int get order {
    switch (this) {
      case CheckInTier.partWithMe:
        return 1;
      case CheckInTier.acapellaClick:
        return 2;
      case CheckInTier.partPlusAccomp:
        return 3;
      case CheckInTier.accompOnly:
        return 4;
      case CheckInTier.accompPlusOtherParts:
        return 5;
    }
  }

  bool get isScored => order <= 3;
}

enum CheckInResult {
  pass,
  needsWork,
  lowConfidence,
  challengeCompleted,
}

extension CheckInResultX on CheckInResult {
  String get id {
    switch (this) {
      case CheckInResult.pass:
        return 'PASS';
      case CheckInResult.needsWork:
        return 'NEEDS_WORK';
      case CheckInResult.lowConfidence:
        return 'LOW_CONFIDENCE';
      case CheckInResult.challengeCompleted:
        return 'CHALLENGE_COMPLETED';
    }
  }

  String get label {
    switch (this) {
      case CheckInResult.pass:
        return 'PASS';
      case CheckInResult.needsWork:
        return 'NEEDS WORK';
      case CheckInResult.lowConfidence:
        return 'LOW CONFIDENCE';
      case CheckInResult.challengeCompleted:
        return 'CHALLENGE COMPLETED';
    }
  }
}

enum DirectorGateValidityWindow {
  rehearsalOnly,
  today,
  customMinutes,
}

extension DirectorGateValidityWindowX on DirectorGateValidityWindow {
  String get id {
    switch (this) {
      case DirectorGateValidityWindow.rehearsalOnly:
        return 'REHEARSAL_ONLY';
      case DirectorGateValidityWindow.today:
        return 'TODAY';
      case DirectorGateValidityWindow.customMinutes:
        return 'CUSTOM_MINUTES';
    }
  }

  String get label {
    switch (this) {
      case DirectorGateValidityWindow.rehearsalOnly:
        return 'This rehearsal only';
      case DirectorGateValidityWindow.today:
        return 'Today';
      case DirectorGateValidityWindow.customMinutes:
        return 'Custom minutes';
    }
  }
}

enum DirectorGateLowConfidenceBehavior {
  doesNotCount,
  countsAsAttemptOnly,
}

extension DirectorGateLowConfidenceBehaviorX on DirectorGateLowConfidenceBehavior {
  String get id {
    switch (this) {
      case DirectorGateLowConfidenceBehavior.doesNotCount:
        return 'DOES_NOT_COUNT';
      case DirectorGateLowConfidenceBehavior.countsAsAttemptOnly:
        return 'COUNTS_AS_ATTEMPT_ONLY';
    }
  }

  String get label {
    switch (this) {
      case DirectorGateLowConfidenceBehavior.doesNotCount:
        return 'Does not count';
      case DirectorGateLowConfidenceBehavior.countsAsAttemptOnly:
        return 'Counts as attempt only';
    }
  }
}

enum StudentClearanceStatus {
  notCleared,
  cleared,
  lowConfidence,
}

extension StudentClearanceStatusX on StudentClearanceStatus {
  String get id {
    switch (this) {
      case StudentClearanceStatus.notCleared:
        return 'NOT_CLEARED';
      case StudentClearanceStatus.cleared:
        return 'CLEARED';
      case StudentClearanceStatus.lowConfidence:
        return 'LOW_CONFIDENCE';
    }
  }

  String get label {
    switch (this) {
      case StudentClearanceStatus.notCleared:
        return 'NOT CLEARED';
      case StudentClearanceStatus.cleared:
        return 'CLEARED';
      case StudentClearanceStatus.lowConfidence:
        return 'LOW CONFIDENCE';
    }
  }
}

class DirectorGateSettings {
  const DirectorGateSettings({
    this.enabled = false,
    this.requiredTier = CheckInTier.acapellaClick,
    this.validityWindow = DirectorGateValidityWindow.rehearsalOnly,
    this.customMinutes = 60,
    this.lowConfidenceBehavior = DirectorGateLowConfidenceBehavior.doesNotCount,
    this.retryCooldownSeconds = 0,
  });

  final bool enabled;
  final CheckInTier requiredTier;
  final DirectorGateValidityWindow validityWindow;
  final int customMinutes;
  final DirectorGateLowConfidenceBehavior lowConfidenceBehavior;
  final int retryCooldownSeconds;

  bool get hasRetryCooldown => retryCooldownSeconds > 0;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabled': enabled,
      'requiredTier': requiredTier.id,
      'validityWindow': validityWindow.id,
      'customMinutes': customMinutes,
      'lowConfidenceBehavior': lowConfidenceBehavior.id,
      'retryCooldownSeconds': retryCooldownSeconds,
    };
  }

  factory DirectorGateSettings.fromMap(Map<String, dynamic> map) {
    final parsedTier = checkInTierFromId(map['requiredTier']?.toString() ?? '');
    final requiredTier = parsedTier != null && parsedTier.isScored
        ? parsedTier
        : CheckInTier.acapellaClick;
    return DirectorGateSettings(
      enabled: map['enabled'] == true,
      requiredTier: requiredTier,
      validityWindow: directorGateValidityWindowFromId(
              map['validityWindow']?.toString() ?? '') ??
          DirectorGateValidityWindow.rehearsalOnly,
      customMinutes:
          (((_toInt(map['customMinutes']) ?? 60).clamp(1, 24 * 60)) as num)
              .toInt(),
      lowConfidenceBehavior: directorGateLowConfidenceBehaviorFromId(
              map['lowConfidenceBehavior']?.toString() ?? '') ??
          DirectorGateLowConfidenceBehavior.doesNotCount,
      retryCooldownSeconds:
          (((_toInt(map['retryCooldownSeconds']) ?? 0).clamp(0, 60 * 30)) as num)
              .toInt(),
    );
  }

  DirectorGateSettings copyWith({
    bool? enabled,
    CheckInTier? requiredTier,
    DirectorGateValidityWindow? validityWindow,
    int? customMinutes,
    DirectorGateLowConfidenceBehavior? lowConfidenceBehavior,
    int? retryCooldownSeconds,
  }) {
    final tier = requiredTier ?? this.requiredTier;
    return DirectorGateSettings(
      enabled: enabled ?? this.enabled,
      requiredTier: tier.isScored ? tier : this.requiredTier,
      validityWindow: validityWindow ?? this.validityWindow,
      customMinutes: customMinutes ?? this.customMinutes,
      lowConfidenceBehavior: lowConfidenceBehavior ?? this.lowConfidenceBehavior,
      retryCooldownSeconds: retryCooldownSeconds ?? this.retryCooldownSeconds,
    );
  }
}

class PracticeSessionPreset {
  PracticeSessionPreset({
    required this.id,
    required this.title,
    required this.startMeasure,
    required this.endMeasure,
    required this.loopEnabled,
    required this.tempoPercent,
    required this.allowedParts,
    required this.pianoDefaultOn,
    required this.autoPlayOnStart,
  });

  final String id;
  final String title;
  final int startMeasure;
  final int endMeasure;
  final bool loopEnabled;
  final int tempoPercent;
  final Set<ChoirPart> allowedParts;
  final bool pianoDefaultOn;
  final bool autoPlayOnStart;

  int get minMeasure => startMeasure <= endMeasure ? startMeasure : endMeasure;
  int get maxMeasure => startMeasure <= endMeasure ? endMeasure : startMeasure;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'startMeasure': startMeasure,
      'endMeasure': endMeasure,
      'loopEnabled': loopEnabled,
      'tempoPercent': tempoPercent,
      'allowedParts': allowedParts.map((part) => part.id).toList(),
      'pianoDefaultOn': pianoDefaultOn,
      'autoPlayOnStart': autoPlayOnStart,
    };
  }

  factory PracticeSessionPreset.fromMap(Map<String, dynamic> map) {
    final allowedRaw = map['allowedParts'];
    final allowed = <ChoirPart>{};
    if (allowedRaw is List) {
      for (final entry in allowedRaw) {
        final part = choirPartFromId(entry.toString());
        if (part != null) {
          allowed.add(part);
        }
      }
    }
    return PracticeSessionPreset(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      startMeasure: _toInt(map['startMeasure']) ?? 1,
      endMeasure: _toInt(map['endMeasure']) ?? 1,
      loopEnabled: map['loopEnabled'] == true,
      tempoPercent: _toInt(map['tempoPercent']) ?? 100,
      allowedParts: allowed,
      pianoDefaultOn: map['pianoDefaultOn'] != false,
      autoPlayOnStart: map['autoPlayOnStart'] != false,
    );
  }
}

class StationPracticeSessionConfig {
  StationPracticeSessionConfig({
    required this.id,
    required this.title,
    required this.startMeasure,
    required this.endMeasure,
    required this.defaultTempoPercent,
    this.allowTempoAdjust = true,
    this.tempoMinPercent = 50,
    this.tempoMaxPercent = 100,
    this.loopDefaultOn = true,
    this.allowCustomLoopPoints = true,
    this.navBackForwardAllowed = true,
    this.navStepMeasures = 2,
    this.allowJumpToAnyMeasureInRange = true,
    this.lockRangeStrict = true,
  });

  final String id;
  final String title;
  final int startMeasure;
  final int endMeasure;
  final int defaultTempoPercent;
  final bool allowTempoAdjust;
  final int tempoMinPercent;
  final int tempoMaxPercent;
  final bool loopDefaultOn;
  final bool allowCustomLoopPoints;
  final bool navBackForwardAllowed;
  final int navStepMeasures;
  final bool allowJumpToAnyMeasureInRange;
  final bool lockRangeStrict;

  int get minMeasure => startMeasure <= endMeasure ? startMeasure : endMeasure;
  int get maxMeasure => startMeasure <= endMeasure ? endMeasure : startMeasure;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'startMeasure': startMeasure,
      'endMeasure': endMeasure,
      'defaultTempoPercent': defaultTempoPercent,
      'allowTempoAdjust': allowTempoAdjust,
      'tempoMinPercent': tempoMinPercent,
      'tempoMaxPercent': tempoMaxPercent,
      'loopDefaultOn': loopDefaultOn,
      'allowCustomLoopPoints': allowCustomLoopPoints,
      'navBackForwardAllowed': navBackForwardAllowed,
      'navStepMeasures': navStepMeasures,
      'allowJumpToAnyMeasureInRange': allowJumpToAnyMeasureInRange,
      'lockRangeStrict': lockRangeStrict,
    };
  }

  factory StationPracticeSessionConfig.fromMap(Map<String, dynamic> map) {
    return StationPracticeSessionConfig(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      startMeasure: _toInt(map['startMeasure']) ?? 1,
      endMeasure: _toInt(map['endMeasure']) ?? 1,
      defaultTempoPercent: _toInt(map['defaultTempoPercent']) ?? 70,
      allowTempoAdjust: map['allowTempoAdjust'] != false,
      tempoMinPercent: _toInt(map['tempoMinPercent']) ?? 50,
      tempoMaxPercent: _toInt(map['tempoMaxPercent']) ?? 100,
      loopDefaultOn: map['loopDefaultOn'] != false,
      allowCustomLoopPoints: map['allowCustomLoopPoints'] != false,
      navBackForwardAllowed: map['navBackForwardAllowed'] != false,
      navStepMeasures: _toInt(map['navStepMeasures']) ?? 2,
      allowJumpToAnyMeasureInRange: map['allowJumpToAnyMeasureInRange'] != false,
      lockRangeStrict: map['lockRangeStrict'] != false,
    );
  }
}

class StationConfig {
  StationConfig({
    required this.stationId,
    required this.stationName,
    required this.lockedPart,
    required this.practiceSession,
    this.stationPasscode,
    this.deviceId,
  });

  final String stationId;
  String stationName;
  final ChoirPart lockedPart;
  StationPracticeSessionConfig practiceSession;
  final String? stationPasscode;
  String? deviceId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'stationId': stationId,
      'stationName': stationName,
      'lockedPart': _stationPartCode(lockedPart),
      'practiceSession': practiceSession.toMap(),
      'stationPasscode': stationPasscode,
      'deviceId': deviceId,
    };
  }

  factory StationConfig.fromMap(Map<String, dynamic> map) {
    final lockedRaw = map['lockedPart']?.toString() ?? 'ALTO';
    final lockedPart = _partFromStationRaw(lockedRaw) ?? ChoirPart.alto;
    final practiceRaw = map['practiceSession'];
    final practice = practiceRaw is Map
        ? StationPracticeSessionConfig.fromMap(practiceRaw.cast<String, dynamic>())
        : StationPracticeSessionConfig(
            id: '',
            title: '',
            startMeasure: 1,
            endMeasure: 8,
            defaultTempoPercent: 70,
          );
    return StationConfig(
      stationId: map['stationId']?.toString() ?? '',
      stationName: map['stationName']?.toString() ?? '',
      lockedPart: lockedPart,
      practiceSession: practice,
      stationPasscode: map['stationPasscode']?.toString(),
      deviceId: map['deviceId']?.toString(),
    );
  }
}

class StationRuntimeStatus {
  StationRuntimeStatus({
    required this.stationId,
    required this.stationName,
    required this.lockedPart,
    this.activeStudentName,
    this.activeAttemptId,
    this.currentMeasure = 1,
    this.tempoPercent = 100,
    this.loopEnabled = false,
    this.loopA,
    this.loopB,
    this.studentsCompleted = 0,
    this.totalPracticeSeconds = 0,
    this.connected = false,
    DateTime? lastActivityAt,
  }) : lastActivityAt = lastActivityAt ?? DateTime.now();

  final String stationId;
  String stationName;
  final ChoirPart lockedPart;
  String? activeStudentName;
  String? activeAttemptId;
  int currentMeasure;
  int tempoPercent;
  bool loopEnabled;
  int? loopA;
  int? loopB;
  int studentsCompleted;
  int totalPracticeSeconds;
  bool connected;
  DateTime lastActivityAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'stationId': stationId,
      'stationName': stationName,
      'lockedPart': _stationPartCode(lockedPart),
      'activeStudentName': activeStudentName,
      'activeAttemptId': activeAttemptId,
      'currentMeasure': currentMeasure,
      'tempoPercent': tempoPercent,
      'loopEnabled': loopEnabled,
      'loopA': loopA,
      'loopB': loopB,
      'studentsCompleted': studentsCompleted,
      'totalPracticeSeconds': totalPracticeSeconds,
      'connected': connected,
      'lastActivityAt': lastActivityAt.toIso8601String(),
    };
  }

  factory StationRuntimeStatus.fromMap(Map<String, dynamic> map) {
    return StationRuntimeStatus(
      stationId: map['stationId']?.toString() ?? '',
      stationName: map['stationName']?.toString() ?? '',
      lockedPart: _partFromStationRaw(map['lockedPart']?.toString() ?? '') ??
          ChoirPart.alto,
      activeStudentName: map['activeStudentName']?.toString(),
      activeAttemptId: map['activeAttemptId']?.toString(),
      currentMeasure: _toInt(map['currentMeasure']) ?? 1,
      tempoPercent: _toInt(map['tempoPercent']) ?? 100,
      loopEnabled: map['loopEnabled'] == true,
      loopA: _toInt(map['loopA']),
      loopB: _toInt(map['loopB']),
      studentsCompleted: _toInt(map['studentsCompleted']) ?? 0,
      totalPracticeSeconds: _toInt(map['totalPracticeSeconds']) ?? 0,
      connected: map['connected'] == true,
      lastActivityAt: DateTime.tryParse(map['lastActivityAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class StationAttemptSummary {
  StationAttemptSummary({
    required this.attemptId,
    required this.sessionId,
    required this.stationId,
    required this.stationName,
    required this.studentName,
    required this.lockedPart,
    required this.startedAt,
    this.endedAt,
    this.timeOnTaskSeconds = 0,
    this.measuresVisitedMin,
    this.measuresVisitedMax,
    this.loopReps = 0,
    this.tempoMinUsed,
    this.tempoMaxUsed,
    this.completed = false,
  });

  final String attemptId;
  final String sessionId;
  final String stationId;
  final String stationName;
  final String studentName;
  final ChoirPart lockedPart;
  final DateTime startedAt;
  DateTime? endedAt;
  int timeOnTaskSeconds;
  int? measuresVisitedMin;
  int? measuresVisitedMax;
  int loopReps;
  int? tempoMinUsed;
  int? tempoMaxUsed;
  bool completed;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'attemptId': attemptId,
      'sessionId': sessionId,
      'stationId': stationId,
      'stationName': stationName,
      'studentName': studentName,
      'lockedPart': _stationPartCode(lockedPart),
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'timeOnTaskSeconds': timeOnTaskSeconds,
      'measuresVisitedMin': measuresVisitedMin,
      'measuresVisitedMax': measuresVisitedMax,
      'loopReps': loopReps,
      'tempoMinUsed': tempoMinUsed,
      'tempoMaxUsed': tempoMaxUsed,
      'completed': completed,
    };
  }

  factory StationAttemptSummary.fromMap(Map<String, dynamic> map) {
    return StationAttemptSummary(
      attemptId: map['attemptId']?.toString() ?? '',
      sessionId: map['sessionId']?.toString() ?? '',
      stationId: map['stationId']?.toString() ?? '',
      stationName: map['stationName']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      lockedPart: _partFromStationRaw(map['lockedPart']?.toString() ?? '') ??
          ChoirPart.alto,
      startedAt: DateTime.tryParse(map['startedAt']?.toString() ?? '') ??
          DateTime.now(),
      endedAt: DateTime.tryParse(map['endedAt']?.toString() ?? ''),
      timeOnTaskSeconds: _toInt(map['timeOnTaskSeconds']) ?? 0,
      measuresVisitedMin: _toInt(map['measuresVisitedMin']),
      measuresVisitedMax: _toInt(map['measuresVisitedMax']),
      loopReps: _toInt(map['loopReps']) ?? 0,
      tempoMinUsed: _toInt(map['tempoMinUsed']),
      tempoMaxUsed: _toInt(map['tempoMaxUsed']),
      completed: map['completed'] == true,
    );
  }
}

class StationCheckInRecord {
  StationCheckInRecord({
    required this.attemptId,
    required this.sessionId,
    required this.stationId,
    required this.studentId,
    required this.studentName,
    required this.lockedPart,
    required this.tier,
    required this.result,
    required this.timeOnTaskSeconds,
    required this.timestamp,
    List<int>? troubleMeasures,
    this.confidenceScore,
  }) : troubleMeasures = troubleMeasures ?? <int>[];

  final String attemptId;
  final String sessionId;
  final String stationId;
  final String studentId;
  final String studentName;
  final ChoirPart lockedPart;
  final CheckInTier tier;
  final CheckInResult result;
  final int timeOnTaskSeconds;
  final DateTime timestamp;
  final List<int> troubleMeasures;
  final int? confidenceScore;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'attemptId': attemptId,
      'sessionId': sessionId,
      'stationId': stationId,
      'studentId': studentId,
      'studentName': studentName,
      'lockedPart': _stationPartCode(lockedPart),
      'tier': tier.id,
      'result': result.id,
      'timeOnTaskSeconds': timeOnTaskSeconds,
      'timestamp': timestamp.toIso8601String(),
      'troubleMeasures': troubleMeasures,
      'confidenceScore': confidenceScore,
    };
  }

  factory StationCheckInRecord.fromMap(Map<String, dynamic> map) {
    final troubleRaw = map['troubleMeasures'];
    final trouble = <int>[];
    if (troubleRaw is List) {
      for (final value in troubleRaw) {
        final parsed = _toInt(value);
        if (parsed != null) {
          trouble.add(parsed);
        }
      }
    }
    final stationId = map['stationId']?.toString() ?? '';
    final studentName = map['studentName']?.toString() ?? '';
    final rawStudentId = (map['studentId']?.toString() ?? '').trim();
    final fallbackStudentId = '${stationId}_${studentName.trim().toLowerCase()}';
    return StationCheckInRecord(
      attemptId: map['attemptId']?.toString() ?? '',
      sessionId: map['sessionId']?.toString() ?? '',
      stationId: stationId,
      studentId: rawStudentId.isNotEmpty ? rawStudentId : fallbackStudentId,
      studentName: studentName,
      lockedPart: _partFromStationRaw(map['lockedPart']?.toString() ?? '') ??
          ChoirPart.alto,
      tier: checkInTierFromId(map['tier']?.toString() ?? '') ??
          CheckInTier.partWithMe,
      result: checkInResultFromId(map['result']?.toString() ?? '') ??
          CheckInResult.needsWork,
      timeOnTaskSeconds: _toInt(map['timeOnTaskSeconds']) ?? 0,
      timestamp: DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      troubleMeasures: trouble,
      confidenceScore: _toInt(map['confidenceScore']),
    );
  }
}

class StudentCheckInProgress {
  StudentCheckInProgress({
    required this.studentName,
    required this.stationId,
    required this.studentId,
    required this.partId,
    required this.latestTier,
    required this.latestResult,
    required this.highestScoredTierPassed,
    required this.challengeTier4Completed,
    required this.challengeTier5Completed,
    required this.latestTroubleMeasures,
    required this.lastUpdatedAt,
    this.clearanceStatus = StudentClearanceStatus.notCleared,
    this.clearanceTierPassed,
    this.clearanceTimestamp,
    this.clearanceExpiresAt,
  });

  final String studentName;
  final String stationId;
  final String studentId;
  final String partId;
  CheckInTier latestTier;
  CheckInResult latestResult;
  int highestScoredTierPassed;
  bool challengeTier4Completed;
  bool challengeTier5Completed;
  List<int> latestTroubleMeasures;
  DateTime lastUpdatedAt;
  StudentClearanceStatus clearanceStatus;
  int? clearanceTierPassed;
  DateTime? clearanceTimestamp;
  DateTime? clearanceExpiresAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'studentName': studentName,
      'stationId': stationId,
      'studentId': studentId,
      'partId': partId,
      'latestTier': latestTier.id,
      'latestResult': latestResult.id,
      'highestScoredTierPassed': highestScoredTierPassed,
      'challengeTier4Completed': challengeTier4Completed,
      'challengeTier5Completed': challengeTier5Completed,
      'latestTroubleMeasures': latestTroubleMeasures,
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'clearanceStatus': clearanceStatus.id,
      'clearanceTierPassed': clearanceTierPassed,
      'clearanceTimestamp': clearanceTimestamp?.toIso8601String(),
      'clearanceExpiresAt': clearanceExpiresAt?.toIso8601String(),
    };
  }

  factory StudentCheckInProgress.fromMap(Map<String, dynamic> map) {
    final troubleRaw = map['latestTroubleMeasures'];
    final trouble = <int>[];
    if (troubleRaw is List) {
      for (final value in troubleRaw) {
        final parsed = _toInt(value);
        if (parsed != null) {
          trouble.add(parsed);
        }
      }
    }
    final studentName = map['studentName']?.toString() ?? '';
    final stationId = map['stationId']?.toString() ?? '';
    final rawStudentId = (map['studentId']?.toString() ?? '').trim();
    final fallbackStudentId = '${stationId}_${studentName.trim().toLowerCase()}';
    return StudentCheckInProgress(
      studentName: studentName,
      stationId: stationId,
      studentId: rawStudentId.isNotEmpty ? rawStudentId : fallbackStudentId,
      partId: map['partId']?.toString() ?? '',
      latestTier: checkInTierFromId(map['latestTier']?.toString() ?? '') ??
          CheckInTier.partWithMe,
      latestResult: checkInResultFromId(map['latestResult']?.toString() ?? '') ??
          CheckInResult.needsWork,
      highestScoredTierPassed: _toInt(map['highestScoredTierPassed']) ?? 0,
      challengeTier4Completed: map['challengeTier4Completed'] == true,
      challengeTier5Completed: map['challengeTier5Completed'] == true,
      latestTroubleMeasures: trouble,
      lastUpdatedAt: DateTime.tryParse(map['lastUpdatedAt']?.toString() ?? '') ??
          DateTime.now(),
      clearanceStatus:
          studentClearanceStatusFromId(map['clearanceStatus']?.toString() ?? '') ??
              StudentClearanceStatus.notCleared,
      clearanceTierPassed: _toInt(map['clearanceTierPassed']),
      clearanceTimestamp:
          DateTime.tryParse(map['clearanceTimestamp']?.toString() ?? ''),
      clearanceExpiresAt:
          DateTime.tryParse(map['clearanceExpiresAt']?.toString() ?? ''),
    );
  }
}

class StudentPracticeRecord {
  StudentPracticeRecord({
    required this.studentName,
    required this.partId,
    required this.deviceId,
    required this.connected,
    required this.status,
    required this.currentMeasure,
    required this.currentTempo,
    required this.currentSessionTitle,
    required this.sessionsCompleted,
    required this.totalPracticeSeconds,
    required this.lastActivityAt,
    required this.completedSessionIds,
  });

  final String studentName;
  final String partId;
  final String deviceId;
  bool connected;
  String status;
  int currentMeasure;
  int currentTempo;
  String? currentSessionTitle;
  int sessionsCompleted;
  int totalPracticeSeconds;
  DateTime lastActivityAt;
  final Set<String> completedSessionIds;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'studentName': studentName,
      'partId': partId,
      'deviceId': deviceId,
      'connected': connected,
      'status': status,
      'currentMeasure': currentMeasure,
      'currentTempo': currentTempo,
      'currentSessionTitle': currentSessionTitle,
      'sessionsCompleted': sessionsCompleted,
      'totalPracticeSeconds': totalPracticeSeconds,
      'lastActivityAt': lastActivityAt.toIso8601String(),
      'completedSessionIds': completedSessionIds.toList(),
    };
  }

  factory StudentPracticeRecord.fromMap(Map<String, dynamic> map) {
    final completedRaw = map['completedSessionIds'];
    return StudentPracticeRecord(
      studentName: map['studentName']?.toString() ?? '',
      partId: map['partId']?.toString() ?? '',
      deviceId: map['deviceId']?.toString() ?? '',
      connected: map['connected'] == true,
      status: map['status']?.toString() ?? 'idle',
      currentMeasure: _toInt(map['currentMeasure']) ?? 1,
      currentTempo: _toInt(map['currentTempo']) ?? 100,
      currentSessionTitle: map['currentSessionTitle']?.toString(),
      sessionsCompleted: _toInt(map['sessionsCompleted']) ?? 0,
      totalPracticeSeconds: _toInt(map['totalPracticeSeconds']) ?? 0,
      lastActivityAt: DateTime.tryParse(map['lastActivityAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      completedSessionIds: completedRaw is List
          ? completedRaw.map((entry) => entry.toString()).toSet()
          : <String>{},
    );
  }
}

class ClassSessionState {
  ClassSessionState({
    required this.sessionId,
    required this.className,
    required this.pieceId,
    required this.createdAt,
    required this.pairingToken,
    DirectorGateSettings? directorGate,
    List<PracticeSessionPreset>? practiceSessions,
    Map<String, StudentPracticeRecord>? rosterByDeviceId,
    Map<String, int>? loopRangeCounts,
    Map<int, int>? measureVisitCounts,
    List<Map<String, dynamic>>? eventLogs,
    Map<String, StationConfig>? stationsById,
    Map<String, StationRuntimeStatus>? stationRuntimeById,
    List<StationAttemptSummary>? stationAttempts,
    Map<String, StudentCheckInProgress>? checkInProgressByStudentKey,
    List<StationCheckInRecord>? checkInRecords,
    Map<String, int>? checkInTroubleByStationMeasure,
  }) : directorGate = directorGate ?? const DirectorGateSettings(),
       practiceSessions = practiceSessions ?? <PracticeSessionPreset>[],
       rosterByDeviceId = rosterByDeviceId ?? <String, StudentPracticeRecord>{},
       loopRangeCounts = loopRangeCounts ?? <String, int>{},
       measureVisitCounts = measureVisitCounts ?? <int, int>{},
       eventLogs = eventLogs ?? <Map<String, dynamic>>[],
       stationsById = stationsById ?? <String, StationConfig>{},
       stationRuntimeById = stationRuntimeById ?? <String, StationRuntimeStatus>{},
       stationAttempts = stationAttempts ?? <StationAttemptSummary>[],
       checkInProgressByStudentKey =
           checkInProgressByStudentKey ?? <String, StudentCheckInProgress>{},
       checkInRecords = checkInRecords ?? <StationCheckInRecord>[],
       checkInTroubleByStationMeasure =
           checkInTroubleByStationMeasure ?? <String, int>{};

  final String sessionId;
  final String className;
  final String pieceId;
  final DateTime createdAt;
  final String pairingToken;
  DirectorGateSettings directorGate;
  final List<PracticeSessionPreset> practiceSessions;
  final Map<String, StudentPracticeRecord> rosterByDeviceId;
  final Map<String, int> loopRangeCounts;
  final Map<int, int> measureVisitCounts;
  final List<Map<String, dynamic>> eventLogs;
  final Map<String, StationConfig> stationsById;
  final Map<String, StationRuntimeStatus> stationRuntimeById;
  final List<StationAttemptSummary> stationAttempts;
  final Map<String, StudentCheckInProgress> checkInProgressByStudentKey;
  final List<StationCheckInRecord> checkInRecords;
  final Map<String, int> checkInTroubleByStationMeasure;

  List<StationConfig> sortedStations() {
    final list = stationsById.values.toList();
    list.sort((a, b) => a.stationName.compareTo(b.stationName));
    return list;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'className': className,
      'pieceId': pieceId,
      'createdAt': createdAt.toIso8601String(),
      'pairingToken': pairingToken,
      'directorGate': directorGate.toMap(),
      'practiceSessions': practiceSessions.map((session) => session.toMap()).toList(),
      'rosterByDeviceId': rosterByDeviceId.map(
        (key, value) => MapEntry<String, dynamic>(key, value.toMap()),
      ),
      'loopRangeCounts': loopRangeCounts,
      'measureVisitCounts': measureVisitCounts.map(
        (key, value) => MapEntry<String, dynamic>(key.toString(), value),
      ),
      'eventLogs': eventLogs,
      'stationsById': stationsById.map(
        (key, value) => MapEntry<String, dynamic>(key, value.toMap()),
      ),
      'stationRuntimeById': stationRuntimeById.map(
        (key, value) => MapEntry<String, dynamic>(key, value.toMap()),
      ),
      'stationAttempts': stationAttempts.map((entry) => entry.toMap()).toList(),
      'checkInProgressByStudentKey': checkInProgressByStudentKey.map(
        (key, value) => MapEntry<String, dynamic>(key, value.toMap()),
      ),
      'checkInRecords': checkInRecords.map((entry) => entry.toMap()).toList(),
      'checkInTroubleByStationMeasure': checkInTroubleByStationMeasure,
    };
  }

  Map<String, dynamic> toRemoteMap() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'className': className,
      'createdAt': createdAt.toIso8601String(),
      'directorGate': directorGate.toMap(),
      'practiceSessions': practiceSessions.map((session) => session.toMap()).toList(),
      'roster': rosterByDeviceId.values.map((entry) => entry.toMap()).toList(),
      'loopRangeCounts': loopRangeCounts,
      'measureVisitCounts': measureVisitCounts.map(
        (key, value) => MapEntry<String, dynamic>(key.toString(), value),
      ),
      'stations': stationsById.values.map((station) => station.toMap()).toList(),
      'stationRuntime': stationRuntimeById.values.map((entry) => entry.toMap()).toList(),
      'stationSummary': _buildStationSummaryMap(),
      'checkInProgress': checkInProgressByStudentKey.values
          .map((entry) => entry.toMap())
          .toList(),
      'checkInTroubleByStationMeasure': checkInTroubleByStationMeasure,
    };
  }

  Map<String, dynamic> _buildStationSummaryMap() {
    final summary = <String, dynamic>{};
    for (final station in stationsById.values) {
      final attempts = stationAttempts.where((entry) => entry.stationId == station.stationId);
      final completed = attempts.where((entry) => entry.completed).length;
      final totalSeconds = attempts.fold<int>(0, (sum, entry) => sum + entry.timeOnTaskSeconds);
      summary[station.stationId] = <String, dynamic>{
        'studentsCompleted': completed,
        'totalPracticeSeconds': totalSeconds,
      };
    }
    return summary;
  }

  factory ClassSessionState.fromMap(Map<String, dynamic> map) {
    final practiceRaw = map['practiceSessions'];
    final rosterRaw = map['rosterByDeviceId'];
    final loopRaw = map['loopRangeCounts'];
    final measureRaw = map['measureVisitCounts'];
    final logsRaw = map['eventLogs'];
    final stationsRaw = map['stationsById'];
    final runtimeRaw = map['stationRuntimeById'];
    final attemptsRaw = map['stationAttempts'];
    final checkInProgressRaw = map['checkInProgressByStudentKey'];
    final checkInRecordsRaw = map['checkInRecords'];
    final checkInTroubleRaw = map['checkInTroubleByStationMeasure'];
    final directorGateRaw = map['directorGate'];

    final practiceSessions = <PracticeSessionPreset>[];
    if (practiceRaw is List) {
      for (final entry in practiceRaw) {
        if (entry is Map) {
          practiceSessions.add(
            PracticeSessionPreset.fromMap(entry.cast<String, dynamic>()),
          );
        }
      }
    }

    final rosterByDeviceId = <String, StudentPracticeRecord>{};
    if (rosterRaw is Map) {
      for (final entry in rosterRaw.entries) {
        final value = entry.value;
        if (value is Map) {
          rosterByDeviceId[entry.key.toString()] = StudentPracticeRecord.fromMap(
            value.cast<String, dynamic>(),
          );
        }
      }
    }

    final loopRangeCounts = <String, int>{};
    if (loopRaw is Map) {
      for (final entry in loopRaw.entries) {
        final value = _toInt(entry.value);
        if (value != null) {
          loopRangeCounts[entry.key.toString()] = value;
        }
      }
    }

    final measureVisitCounts = <int, int>{};
    if (measureRaw is Map) {
      for (final entry in measureRaw.entries) {
        final key = int.tryParse(entry.key.toString());
        final value = _toInt(entry.value);
        if (key != null && value != null) {
          measureVisitCounts[key] = value;
        }
      }
    }

    final eventLogs = <Map<String, dynamic>>[];
    if (logsRaw is List) {
      for (final entry in logsRaw) {
        if (entry is Map) {
          eventLogs.add(entry.cast<String, dynamic>());
        }
      }
    }

    final stationsById = <String, StationConfig>{};
    if (stationsRaw is Map) {
      for (final entry in stationsRaw.entries) {
        final value = entry.value;
        if (value is Map) {
          stationsById[entry.key.toString()] = StationConfig.fromMap(
            value.cast<String, dynamic>(),
          );
        }
      }
    }

    final stationRuntimeById = <String, StationRuntimeStatus>{};
    if (runtimeRaw is Map) {
      for (final entry in runtimeRaw.entries) {
        final value = entry.value;
        if (value is Map) {
          stationRuntimeById[entry.key.toString()] = StationRuntimeStatus.fromMap(
            value.cast<String, dynamic>(),
          );
        }
      }
    }

    final stationAttempts = <StationAttemptSummary>[];
    if (attemptsRaw is List) {
      for (final entry in attemptsRaw) {
        if (entry is Map) {
          stationAttempts.add(
            StationAttemptSummary.fromMap(entry.cast<String, dynamic>()),
          );
        }
      }
    }

    final checkInProgressByStudentKey = <String, StudentCheckInProgress>{};
    if (checkInProgressRaw is Map) {
      for (final entry in checkInProgressRaw.entries) {
        final value = entry.value;
        if (value is Map) {
          checkInProgressByStudentKey[entry.key.toString()] =
              StudentCheckInProgress.fromMap(value.cast<String, dynamic>());
        }
      }
    }

    final checkInRecords = <StationCheckInRecord>[];
    if (checkInRecordsRaw is List) {
      for (final entry in checkInRecordsRaw) {
        if (entry is Map) {
          checkInRecords.add(
            StationCheckInRecord.fromMap(entry.cast<String, dynamic>()),
          );
        }
      }
    }

    final checkInTroubleByStationMeasure = <String, int>{};
    if (checkInTroubleRaw is Map) {
      for (final entry in checkInTroubleRaw.entries) {
        final value = _toInt(entry.value);
        if (value != null) {
          checkInTroubleByStationMeasure[entry.key.toString()] = value;
        }
      }
    }

    return ClassSessionState(
      sessionId: map['sessionId']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      pieceId: map['pieceId']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      pairingToken: map['pairingToken']?.toString() ?? '',
      directorGate: directorGateRaw is Map
          ? DirectorGateSettings.fromMap(directorGateRaw.cast<String, dynamic>())
          : const DirectorGateSettings(),
      practiceSessions: practiceSessions,
      rosterByDeviceId: rosterByDeviceId,
      loopRangeCounts: loopRangeCounts,
      measureVisitCounts: measureVisitCounts,
      eventLogs: eventLogs,
      stationsById: stationsById,
      stationRuntimeById: stationRuntimeById,
      stationAttempts: stationAttempts,
      checkInProgressByStudentKey: checkInProgressByStudentKey,
      checkInRecords: checkInRecords,
      checkInTroubleByStationMeasure: checkInTroubleByStationMeasure,
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

ChoirPart? _partFromStationRaw(String raw) {
  final value = raw.trim().toUpperCase();
  switch (value) {
    case 'SOP':
    case 'SOPRANO':
      return ChoirPart.soprano;
    case 'ALTO':
      return ChoirPart.alto;
    case 'TENOR':
      return ChoirPart.tenor;
    case 'BASS':
      return ChoirPart.bass;
    default:
      return choirPartFromId(raw);
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

CheckInTier? checkInTierFromId(String raw) {
  final normalized = raw.trim().toUpperCase();
  for (final tier in CheckInTier.values) {
    if (tier.id == normalized) {
      return tier;
    }
  }
  return null;
}

CheckInResult? checkInResultFromId(String raw) {
  final normalized = raw.trim().toUpperCase();
  for (final result in CheckInResult.values) {
    if (result.id == normalized) {
      return result;
    }
  }
  return null;
}

DirectorGateValidityWindow? directorGateValidityWindowFromId(String raw) {
  final normalized = raw.trim().toUpperCase();
  for (final value in DirectorGateValidityWindow.values) {
    if (value.id == normalized) {
      return value;
    }
  }
  return null;
}

DirectorGateLowConfidenceBehavior? directorGateLowConfidenceBehaviorFromId(
  String raw,
) {
  final normalized = raw.trim().toUpperCase();
  for (final value in DirectorGateLowConfidenceBehavior.values) {
    if (value.id == normalized) {
      return value;
    }
  }
  return null;
}

StudentClearanceStatus? studentClearanceStatusFromId(String raw) {
  final normalized = raw.trim().toUpperCase();
  for (final value in StudentClearanceStatus.values) {
    if (value.id == normalized) {
      return value;
    }
  }
  return null;
}

