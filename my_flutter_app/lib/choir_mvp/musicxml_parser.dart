import 'dart:math' as math;

import 'package:xml/xml.dart';

import 'models.dart';

class MusicXmlParser {
  ParsedScore parse(String xmlContent) {
    final document = XmlDocument.parse(xmlContent);

    final baseBpm = _readBaseTempo(document);
    final partAssignments = _buildPartAssignments(document);

    final measureStartByNumber = <int, double>{};
    final rehearsalMarks = <String, int>{};
    final notes = <ScoreNote>[];
    var totalBeats = 0.0;
    var fallbackMeasureNumber = 1;

    for (final partElement in document.findAllElements('part')) {
      final partId = partElement.getAttribute('id') ?? '';
      final part = partAssignments[partId] ?? _inferPart(partId);
      if (part == null) {
        continue;
      }

      var currentDivisions = 1.0;
      var beatCursor = 0.0;

      for (final measure in partElement.findElements('measure')) {
        final measureNumber = _parseMeasureNumber(
          measure.getAttribute('number'),
          fallbackMeasureNumber,
        );
        fallbackMeasureNumber = math.max(fallbackMeasureNumber, measureNumber + 1);

        final measureStart = beatCursor;
        final previousStart = measureStartByNumber[measureNumber];
        if (previousStart == null || measureStart < previousStart) {
          measureStartByNumber[measureNumber] = measureStart;
        }

        for (final rehearsal in measure.findAllElements('rehearsal')) {
          final raw = rehearsal.innerText.trim();
          if (raw.isEmpty) {
            continue;
          }
          // Keep the first occurrence per mark label.
          rehearsalMarks.putIfAbsent(raw.toUpperCase(), () => measureNumber);
        }

        var lastNonChordStart = beatCursor;

        for (final child in measure.children.whereType<XmlElement>()) {
          final name = child.name.local;
          if (name == 'attributes') {
            final divisionsText = child.getElement('divisions')?.innerText.trim();
            final parsedDivisions = double.tryParse(divisionsText ?? '');
            if (parsedDivisions != null && parsedDivisions > 0) {
              currentDivisions = parsedDivisions;
            }
            continue;
          }

          if (name == 'note') {
            final isChord = child.getElement('chord') != null;
            final durationBeats = _readDurationBeats(child, currentDivisions);
            final noteStart = isChord ? lastNonChordStart : beatCursor;

            final isRest = child.getElement('rest') != null;
            final midi = isRest ? null : _readMidi(child.getElement('pitch'));
            if (midi != null) {
              notes.add(
                ScoreNote(
                  part: part,
                  midi: midi,
                  startBeat: noteStart,
                  durationBeats: durationBeats,
                  measureNumber: measureNumber,
                ),
              );
              totalBeats = math.max(totalBeats, noteStart + durationBeats);
            }

            if (!isChord) {
              lastNonChordStart = noteStart;
              beatCursor += durationBeats;
            }
            continue;
          }

          if (name == 'backup') {
            final beats = _readDurationBeats(child, currentDivisions);
            beatCursor = math.max(0, beatCursor - beats);
            lastNonChordStart = beatCursor;
            continue;
          }

          if (name == 'forward') {
            final beats = _readDurationBeats(child, currentDivisions);
            beatCursor += beats;
            lastNonChordStart = beatCursor;
            totalBeats = math.max(totalBeats, beatCursor);
            continue;
          }
        }

        totalBeats = math.max(totalBeats, beatCursor);
      }
    }

    if (measureStartByNumber.isEmpty) {
      throw const FormatException('No measures found in MusicXML.');
    }

    notes.sort((a, b) => a.startBeat.compareTo(b.startBeat));
    final sortedMeasureNumbers = measureStartByNumber.keys.toList()..sort();
    final measureMap = sortedMeasureNumbers
        .map(
          (number) => MeasureMapEntry(
            measureNumber: number,
            startBeat: measureStartByNumber[number]!,
            startTime: measureStartByNumber[number]! * 60.0 / baseBpm,
          ),
        )
        .toList();

    if (notes.isEmpty) {
      throw const FormatException(
        'No playable notes found in SATB/Piano parts.',
      );
    }

    final availableParts = notes.map((note) => note.part).toSet();
    final finalTotalBeats = math.max(
      totalBeats,
      measureMap.last.startBeat + 1,
    );

    return ParsedScore(
      measureMap: measureMap,
      notes: notes,
      baseBpm: baseBpm,
      totalBeats: finalTotalBeats,
      availableParts: availableParts,
      rehearsalMarks: rehearsalMarks,
    );
  }

  double _readBaseTempo(XmlDocument document) {
    for (final sound in document.findAllElements('sound')) {
      final tempo = double.tryParse(sound.getAttribute('tempo') ?? '');
      if (tempo != null && tempo > 0) {
        return tempo;
      }
    }
    for (final perMinute in document.findAllElements('per-minute')) {
      final tempo = double.tryParse(perMinute.innerText.trim());
      if (tempo != null && tempo > 0) {
        return tempo;
      }
    }
    return 96.0;
  }

  Map<String, ChoirPart> _buildPartAssignments(XmlDocument document) {
    final scorePartElements = document.findAllElements('score-part').toList();
    final assignments = <String, ChoirPart>{};
    final used = <ChoirPart>{};

    for (final scorePart in scorePartElements) {
      final id = scorePart.getAttribute('id');
      if (id == null || id.isEmpty) {
        continue;
      }
      final names = [
        scorePart.getElement('part-name')?.innerText ?? '',
        scorePart.getElement('part-abbreviation')?.innerText ?? '',
      ].join(' ');
      final inferred = _inferPart(names);
      if (inferred != null) {
        assignments[id] = inferred;
        used.add(inferred);
      }
    }

    final fallbackOrder = <ChoirPart>[
      ChoirPart.soprano,
      ChoirPart.alto,
      ChoirPart.tenor,
      ChoirPart.bass,
      ChoirPart.piano,
    ];
    for (final scorePart in scorePartElements) {
      final id = scorePart.getAttribute('id');
      if (id == null || id.isEmpty || assignments.containsKey(id)) {
        continue;
      }
      final fallback = fallbackOrder.firstWhere(
        (part) => !used.contains(part),
        orElse: () => ChoirPart.piano,
      );
      assignments[id] = fallback;
      used.add(fallback);
    }

    return assignments;
  }

  ChoirPart? _inferPart(String raw) {
    final text = raw.toLowerCase();
    if (text.contains('soprano') || text.contains('sop')) {
      return ChoirPart.soprano;
    }
    if (text.contains('alto')) {
      return ChoirPart.alto;
    }
    if (text.contains('tenor')) {
      return ChoirPart.tenor;
    }
    if (text.contains('bass') || text.contains('baritone') || text == 'b') {
      return ChoirPart.bass;
    }
    if (text.contains('piano') ||
        text.contains('accomp') ||
        text.contains('keyboard') ||
        text.contains('reduction')) {
      return ChoirPart.piano;
    }
    return null;
  }

  int _parseMeasureNumber(String? raw, int fallback) {
    if (raw == null || raw.isEmpty) {
      return fallback;
    }
    final match = RegExp(r'\d+').firstMatch(raw);
    if (match == null) {
      return fallback;
    }
    return int.tryParse(match.group(0) ?? '') ?? fallback;
  }

  double _readDurationBeats(XmlElement element, double divisions) {
    final durationText = element.getElement('duration')?.innerText.trim() ?? '';
    final durationValue = double.tryParse(durationText) ?? 0;
    if (durationValue <= 0 || divisions <= 0) {
      return 0.25;
    }
    return durationValue / divisions;
  }

  int? _readMidi(XmlElement? pitch) {
    if (pitch == null) {
      return null;
    }
    final step = pitch.getElement('step')?.innerText.trim().toUpperCase();
    final octaveText = pitch.getElement('octave')?.innerText.trim();
    if (step == null || octaveText == null) {
      return null;
    }
    final semitone = _stepToSemitone[step];
    final octave = int.tryParse(octaveText);
    if (semitone == null || octave == null) {
      return null;
    }
    final alter = int.tryParse(pitch.getElement('alter')?.innerText.trim() ?? '0') ?? 0;
    final midi = (octave + 1) * 12 + semitone + alter;
    if (midi < 0 || midi > 127) {
      return null;
    }
    return midi;
  }
}

const Map<String, int> _stepToSemitone = {
  'C': 0,
  'D': 2,
  'E': 4,
  'F': 5,
  'G': 7,
  'A': 9,
  'B': 11,
};

