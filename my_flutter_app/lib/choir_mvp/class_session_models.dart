import 'models.dart';

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
    List<PracticeSessionPreset>? practiceSessions,
    Map<String, StudentPracticeRecord>? rosterByDeviceId,
    Map<String, int>? loopRangeCounts,
    Map<int, int>? measureVisitCounts,
    List<Map<String, dynamic>>? eventLogs,
    Map<String, StationConfig>? stationsById,
    Map<String, StationRuntimeStatus>? stationRuntimeById,
    List<StationAttemptSummary>? stationAttempts,
  }) : practiceSessions = practiceSessions ?? <PracticeSessionPreset>[],
       rosterByDeviceId = rosterByDeviceId ?? <String, StudentPracticeRecord>{},
       loopRangeCounts = loopRangeCounts ?? <String, int>{},
       measureVisitCounts = measureVisitCounts ?? <int, int>{},
       eventLogs = eventLogs ?? <Map<String, dynamic>>[],
       stationsById = stationsById ?? <String, StationConfig>{},
       stationRuntimeById = stationRuntimeById ?? <String, StationRuntimeStatus>{},
       stationAttempts = stationAttempts ?? <StationAttemptSummary>[];

  final String sessionId;
  final String className;
  final String pieceId;
  final DateTime createdAt;
  final String pairingToken;
  final List<PracticeSessionPreset> practiceSessions;
  final Map<String, StudentPracticeRecord> rosterByDeviceId;
  final Map<String, int> loopRangeCounts;
  final Map<int, int> measureVisitCounts;
  final List<Map<String, dynamic>> eventLogs;
  final Map<String, StationConfig> stationsById;
  final Map<String, StationRuntimeStatus> stationRuntimeById;
  final List<StationAttemptSummary> stationAttempts;

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
    };
  }

  Map<String, dynamic> toRemoteMap() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'className': className,
      'createdAt': createdAt.toIso8601String(),
      'practiceSessions': practiceSessions.map((session) => session.toMap()).toList(),
      'roster': rosterByDeviceId.values.map((entry) => entry.toMap()).toList(),
      'loopRangeCounts': loopRangeCounts,
      'measureVisitCounts': measureVisitCounts.map(
        (key, value) => MapEntry<String, dynamic>(key.toString(), value),
      ),
      'stations': stationsById.values.map((station) => station.toMap()).toList(),
      'stationRuntime': stationRuntimeById.values.map((entry) => entry.toMap()).toList(),
      'stationSummary': _buildStationSummaryMap(),
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

    return ClassSessionState(
      sessionId: map['sessionId']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      pieceId: map['pieceId']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      pairingToken: map['pairingToken']?.toString() ?? '',
      practiceSessions: practiceSessions,
      rosterByDeviceId: rosterByDeviceId,
      loopRangeCounts: loopRangeCounts,
      measureVisitCounts: measureVisitCounts,
      eventLogs: eventLogs,
      stationsById: stationsById,
      stationRuntimeById: stationRuntimeById,
      stationAttempts: stationAttempts,
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

