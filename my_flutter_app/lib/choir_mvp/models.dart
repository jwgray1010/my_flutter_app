import 'dart:math' as math;

enum ChoirPart { soprano, alto, tenor, bass, piano }

extension ChoirPartX on ChoirPart {
  String get id {
    switch (this) {
      case ChoirPart.soprano:
        return 'soprano';
      case ChoirPart.alto:
        return 'alto';
      case ChoirPart.tenor:
        return 'tenor';
      case ChoirPart.bass:
        return 'bass';
      case ChoirPart.piano:
        return 'piano';
    }
  }

  String get shortLabel {
    switch (this) {
      case ChoirPart.soprano:
        return 'Sop';
      case ChoirPart.alto:
        return 'Alto';
      case ChoirPart.tenor:
        return 'Tenor';
      case ChoirPart.bass:
        return 'Bass';
      case ChoirPart.piano:
        return 'Piano';
    }
  }

  int get midiChannel {
    switch (this) {
      case ChoirPart.soprano:
        return 0;
      case ChoirPart.alto:
        return 1;
      case ChoirPart.tenor:
        return 2;
      case ChoirPart.bass:
        return 3;
      case ChoirPart.piano:
        return 4;
    }
  }
}

ChoirPart? choirPartFromId(String raw) {
  final value = raw.trim().toLowerCase();
  for (final part in ChoirPart.values) {
    if (part.id == value) {
      return part;
    }
  }
  return null;
}

class MeasureMapEntry {
  MeasureMapEntry({
    required this.measureNumber,
    required this.startBeat,
    required this.startTime,
  });

  final int measureNumber;
  final double startBeat;
  final double startTime;

  Map<String, dynamic> toJson() => {
    'measureNumber': measureNumber,
    'startTime': startTime,
  };
}

class ScoreNote {
  ScoreNote({
    required this.part,
    required this.midi,
    required this.startBeat,
    required this.durationBeats,
    required this.measureNumber,
  });

  final ChoirPart part;
  final int midi;
  final double startBeat;
  final double durationBeats;
  final int measureNumber;
}

class PlaybackEvent {
  PlaybackEvent({
    required this.beat,
    required this.note,
    required this.isNoteOn,
  });

  final double beat;
  final ScoreNote note;
  final bool isNoteOn;
}

class ParsedScore {
  ParsedScore({
    required this.measureMap,
    required this.notes,
    required this.baseBpm,
    required this.totalBeats,
    required this.availableParts,
    required this.rehearsalMarks,
  }) : measureNumbers = measureMap.map((entry) => entry.measureNumber).toList();

  final List<MeasureMapEntry> measureMap;
  final List<ScoreNote> notes;
  final List<int> measureNumbers;
  final double baseBpm;
  final double totalBeats;
  final Set<ChoirPart> availableParts;
  final Map<String, int> rehearsalMarks;

  double? beatForMeasure(int measureNumber) {
    for (final entry in measureMap) {
      if (entry.measureNumber == measureNumber) {
        return entry.startBeat;
      }
    }
    return null;
  }

  double endBeatForMeasure(int measureNumber) {
    if (measureMap.isEmpty) {
      return totalBeats;
    }
    for (var index = 0; index < measureMap.length; index++) {
      final entry = measureMap[index];
      if (entry.measureNumber == measureNumber) {
        if (index + 1 < measureMap.length) {
          return measureMap[index + 1].startBeat;
        }
        return totalBeats;
      }
    }
    return totalBeats;
  }

  int measureAtBeat(double beat) {
    if (measureMap.isEmpty) {
      return 1;
    }
    var result = measureMap.first.measureNumber;
    for (final entry in measureMap) {
      if (entry.startBeat <= beat + 1e-7) {
        result = entry.measureNumber;
      } else {
        break;
      }
    }
    return result;
  }

  int clampToKnownMeasure(int measure) {
    if (measureNumbers.isEmpty) {
      return measure;
    }
    if (measureNumbers.contains(measure)) {
      return measure;
    }
    final sorted = measureNumbers;
    var closest = sorted.first;
    var distance = (closest - measure).abs();
    for (final value in sorted) {
      final candidateDistance = (value - measure).abs();
      if (candidateDistance < distance) {
        closest = value;
        distance = candidateDistance;
      }
    }
    return closest;
  }
}

int lowerBoundEventBeat(List<PlaybackEvent> events, double beat) {
  var low = 0;
  var high = events.length;
  while (low < high) {
    final mid = (low + high) >> 1;
    if (events[mid].beat < beat) {
      low = mid + 1;
    } else {
      high = mid;
    }
  }
  return low;
}

int clampInt(int value, int minValue, int maxValue) {
  return math.max(minValue, math.min(maxValue, value));
}

