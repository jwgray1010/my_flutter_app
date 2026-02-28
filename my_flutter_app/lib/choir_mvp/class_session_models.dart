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
    required this.practiceSessions,
    required this.rosterByDeviceId,
    required this.loopRangeCounts,
    required this.measureVisitCounts,
    required this.eventLogs,
  });

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
    };
  }

  factory ClassSessionState.fromMap(Map<String, dynamic> map) {
    final practiceRaw = map['practiceSessions'];
    final rosterRaw = map['rosterByDeviceId'];
    final loopRaw = map['loopRangeCounts'];
    final measureRaw = map['measureVisitCounts'];
    final logsRaw = map['eventLogs'];

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

