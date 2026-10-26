import 'dart:math' as math;

import 'models.dart';

enum VoiceIntentType {
  play,
  pause,
  jumpToMeasure,
  jumpRelative,
  setTempo,
  adjustTempo,
  setLoopA,
  setLoopB,
  setLoopRange,
  clearLoop,
  setMixPreset,
  setPartState,
  playStartingPitches,
}

class VoiceIntent {
  const VoiceIntent({
    required this.type,
    required this.payload,
  });

  final VoiceIntentType type;
  final Map<String, dynamic> payload;
}

class VoiceParseResult {
  const VoiceParseResult._({
    required this.intent,
    required this.message,
    this.suggestion,
  });

  final VoiceIntent? intent;
  final String message;
  final String? suggestion;

  bool get isSuccess => intent != null;

  factory VoiceParseResult.success({
    required VoiceIntent intent,
    required String message,
  }) {
    return VoiceParseResult._(intent: intent, message: message);
  }

  factory VoiceParseResult.failure({
    required String message,
    String? suggestion,
  }) {
    return VoiceParseResult._(
      intent: null,
      message: message,
      suggestion: suggestion,
    );
  }
}

class VoiceCommandParser {
  VoiceParseResult parse(
    String transcript, {
    Map<String, int> rehearsalMarks = const <String, int>{},
  }) {
    final normalized = normalizeTranscript(transcript);
    if (normalized.isEmpty) {
      return VoiceParseResult.failure(
        message: "Didn't catch that.",
        suggestion: "Try: 'measure 32' or 'play'.",
      );
    }

    if (_isStartingPitchCommand(normalized)) {
      return VoiceParseResult.success(
        intent: const VoiceIntent(
          type: VoiceIntentType.playStartingPitches,
          payload: <String, dynamic>{},
        ),
        message: 'Play starting pitches',
      );
    }

    if (RegExp(r'\bclear loop\b').hasMatch(normalized)) {
      return VoiceParseResult.success(
        intent: const VoiceIntent(
          type: VoiceIntentType.clearLoop,
          payload: <String, dynamic>{},
        ),
        message: 'Clear loop',
      );
    }

    final loopRange = _parseLoopRange(normalized);
    if (loopRange != null) {
      return VoiceParseResult.success(
        intent: VoiceIntent(
          type: VoiceIntentType.setLoopRange,
          payload: <String, dynamic>{
            'a': loopRange.$1,
            'b': loopRange.$2,
          },
        ),
        message: 'Loop measures ${loopRange.$1} to ${loopRange.$2}',
      );
    }

    if (RegExp(r'\bset loop a\b').hasMatch(normalized)) {
      return VoiceParseResult.success(
        intent: const VoiceIntent(
          type: VoiceIntentType.setLoopA,
          payload: <String, dynamic>{},
        ),
        message: 'Set loop A',
      );
    }
    if (RegExp(r'\bset loop b\b').hasMatch(normalized)) {
      return VoiceParseResult.success(
        intent: const VoiceIntent(
          type: VoiceIntentType.setLoopB,
          payload: <String, dynamic>{},
        ),
        message: 'Set loop B',
      );
    }
    if (RegExp(r'\bloop this\b').hasMatch(normalized) ||
        RegExp(r'^\s*loop\s*$').hasMatch(normalized)) {
      return VoiceParseResult.success(
        intent: const VoiceIntent(
          type: VoiceIntentType.setLoopA,
          payload: <String, dynamic>{'armToggle': true},
        ),
        message: 'Toggle loop armed',
      );
    }

    final tempoPercent = _parseTempoPercent(normalized);
    if (tempoPercent != null) {
      return VoiceParseResult.success(
        intent: VoiceIntent(
          type: VoiceIntentType.setTempo,
          payload: <String, dynamic>{'percent': tempoPercent},
        ),
        message: 'Set tempo to ${tempoPercent.toStringAsFixed(0)}%',
      );
    }
    if (RegExp(r'\bslower\b').hasMatch(normalized)) {
      return VoiceParseResult.success(
        intent: const VoiceIntent(
          type: VoiceIntentType.adjustTempo,
          payload: <String, dynamic>{'delta': -5},
        ),
        message: 'Tempo slower',
      );
    }
    if (RegExp(r'\bfaster\b').hasMatch(normalized)) {
      return VoiceParseResult.success(
        intent: const VoiceIntent(
          type: VoiceIntentType.adjustTempo,
          payload: <String, dynamic>{'delta': 5},
        ),
        message: 'Tempo faster',
      );
    }

    final relativeDelta = _parseRelativeMeasureDelta(normalized);
    if (relativeDelta != null) {
      return VoiceParseResult.success(
        intent: VoiceIntent(
          type: VoiceIntentType.jumpRelative,
          payload: <String, dynamic>{'delta': relativeDelta},
        ),
        message: relativeDelta < 0
            ? 'Back ${relativeDelta.abs()} measure${relativeDelta.abs() == 1 ? '' : 's'}'
            : 'Forward $relativeDelta measure${relativeDelta == 1 ? '' : 's'}',
      );
    }

    final letterMatch = RegExp(r'\bletter\s+([a-z])\b').firstMatch(normalized);
    if (letterMatch != null) {
      if (rehearsalMarks.isEmpty) {
        return VoiceParseResult.failure(
          message: 'No rehearsal marks in this score',
          suggestion: "Try: 'measure 32'.",
        );
      }
      final letter = (letterMatch.group(1) ?? '').toUpperCase();
      final targetMeasure = rehearsalMarks[letter];
      if (targetMeasure == null) {
        return VoiceParseResult.failure(
          message: 'Rehearsal letter $letter not found.',
          suggestion: "Try: 'measure 32'.",
        );
      }
      return VoiceParseResult.success(
        intent: VoiceIntent(
          type: VoiceIntentType.jumpToMeasure,
          payload: <String, dynamic>{
            'measure': targetMeasure,
            'source': 'letter:$letter',
          },
        ),
        message: 'Jump to letter $letter (measure $targetMeasure)',
      );
    }

    final measureNumber = _parseMeasureNumber(normalized);
    if (measureNumber != null) {
      return VoiceParseResult.success(
        intent: VoiceIntent(
          type: VoiceIntentType.jumpToMeasure,
          payload: <String, dynamic>{'measure': measureNumber},
        ),
        message: 'Jump to measure $measureNumber',
      );
    }

    final partsResult = _parseParts(normalized);
    if (partsResult != null) {
      return partsResult;
    }

    if (RegExp(r'\bresume\b').hasMatch(normalized) ||
        RegExp(r'\bplay\b').hasMatch(normalized) ||
        RegExp(r'\bstart\b').hasMatch(normalized)) {
      return VoiceParseResult.success(
        intent: const VoiceIntent(
          type: VoiceIntentType.play,
          payload: <String, dynamic>{},
        ),
        message: 'Play',
      );
    }
    if (RegExp(r'\bpause\b').hasMatch(normalized) ||
        RegExp(r'\bstop\b').hasMatch(normalized)) {
      return VoiceParseResult.success(
        intent: const VoiceIntent(
          type: VoiceIntentType.pause,
          payload: <String, dynamic>{},
        ),
        message: 'Pause',
      );
    }

    return VoiceParseResult.failure(
      message: "Didn't catch that.",
      suggestion: "Try: 'play', 'measure 32', or 'tempo 70'.",
    );
  }
}

Map<String, dynamic>? intentToCommand(
  VoiceIntent intent, {
  required int currentMeasure,
}) {
  switch (intent.type) {
    case VoiceIntentType.play:
      return <String, dynamic>{'type': 'PLAY'};
    case VoiceIntentType.pause:
      return <String, dynamic>{'type': 'PAUSE'};
    case VoiceIntentType.jumpToMeasure:
      return <String, dynamic>{
        'type': 'JUMP_TO_MEASURE',
        'measure': intent.payload['measure'],
      };
    case VoiceIntentType.jumpRelative:
      return <String, dynamic>{
        'type': 'JUMP_RELATIVE',
        'deltaMeasures': intent.payload['delta'],
      };
    case VoiceIntentType.setTempo:
      return <String, dynamic>{
        'type': 'SET_TEMPO',
        'percent': intent.payload['percent'],
      };
    case VoiceIntentType.adjustTempo:
      return <String, dynamic>{
        'type': 'SET_TEMPO_ADJUST',
        'delta': intent.payload['delta'],
      };
    case VoiceIntentType.setLoopA:
      if (intent.payload['armToggle'] == true) {
        return <String, dynamic>{'type': 'LOOP_ARM_TOGGLE'};
      }
      return <String, dynamic>{
        'type': 'SET_LOOP_A',
        'measure': intent.payload['measure'] ?? currentMeasure,
      };
    case VoiceIntentType.setLoopB:
      return <String, dynamic>{
        'type': 'SET_LOOP_B',
        'measure': intent.payload['measure'] ?? currentMeasure,
      };
    case VoiceIntentType.setLoopRange:
      return <String, dynamic>{
        'type': 'SET_LOOP_RANGE',
        'a': intent.payload['a'],
        'b': intent.payload['b'],
      };
    case VoiceIntentType.clearLoop:
      return <String, dynamic>{'type': 'CLEAR_LOOP'};
    case VoiceIntentType.setMixPreset:
      return <String, dynamic>{
        'type': 'SET_MIX_PRESET',
        ...intent.payload,
      };
    case VoiceIntentType.setPartState:
      return <String, dynamic>{
        'type': 'SET_PART_ENABLED',
        'part': intent.payload['part'],
        'enabled': intent.payload['enabled'],
      };
    case VoiceIntentType.playStartingPitches:
      return <String, dynamic>{'type': 'PLAY_STARTING_PITCHES'};
  }
}

String normalizeTranscript(String input) {
  final lower = input.toLowerCase();
  final stripped = lower.replaceAll(RegExp(r"[^a-z0-9\s]"), " ");
  final tokens = stripped
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .where((token) => !_fillerWords.contains(token))
      .toList();
  return tokens.join(' ');
}

bool _isStartingPitchCommand(String text) {
  return text.contains('starting pitch') ||
      text.contains('starting pitches') ||
      text.contains('give pitches') ||
      text.contains('give me starting pitches') ||
      text.contains('play starting pitches');
}

int? _parseMeasureNumber(String text) {
  if (!RegExp(r'\b(measure|bar)\b').hasMatch(text)) {
    return null;
  }
  final digitMatch = RegExp(r'\b(?:measure|bar)\s+(\d{1,4})\b').firstMatch(text);
  if (digitMatch != null) {
    return int.tryParse(digitMatch.group(1)!);
  }

  final tokens = text.split(' ');
  for (var i = 0; i < tokens.length; i++) {
    final token = tokens[i];
    if (token != 'measure' && token != 'bar') {
      continue;
    }
    final parsed = _parseNumberWords(tokens.skip(i + 1).take(5).toList());
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

int? _parseRelativeMeasureDelta(String text) {
  if (text.contains('back')) {
    final value = _extractSmallMeasureCount(text, directionWord: 'back') ?? 2;
    return -value;
  }
  if (text.contains('forward')) {
    final value = _extractSmallMeasureCount(text, directionWord: 'forward') ?? 2;
    return value;
  }
  return null;
}

int? _extractSmallMeasureCount(String text, {required String directionWord}) {
  final digitMatch = RegExp('\\b$directionWord\\s+(\\d)\\b').firstMatch(text);
  if (digitMatch != null) {
    final parsed = int.tryParse(digitMatch.group(1)!);
    if (parsed != null) {
      return math.max(1, math.min(2, parsed));
    }
  }

  final tokens = text.split(' ');
  final index = tokens.indexOf(directionWord);
  if (index == -1) {
    return null;
  }
  final parsed = _parseNumberWords(tokens.skip(index + 1).take(3).toList());
  if (parsed == null) {
    return null;
  }
  return math.max(1, math.min(2, parsed));
}

double? _parseTempoPercent(String text) {
  final explicitTempo = RegExp(r'\b(?:tempo|set tempo to|set tempo)\s+(\d{2,3})\b')
      .firstMatch(text);
  if (explicitTempo != null) {
    final parsed = int.tryParse(explicitTempo.group(1)!);
    if (parsed != null) {
      return parsed.clamp(50, 100).toDouble();
    }
  }
  final percentDigits = RegExp(r'\b(\d{2,3})\s*percent\b').firstMatch(text);
  if (percentDigits != null) {
    final parsed = int.tryParse(percentDigits.group(1)!);
    if (parsed != null) {
      return parsed.clamp(50, 100).toDouble();
    }
  }

  final tokens = text.split(' ');
  final percentIndex = tokens.indexOf('percent');
  if (percentIndex > 0) {
    final windowStart = math.max(0, percentIndex - 5);
    for (var start = windowStart; start < percentIndex; start++) {
      final parsed = _parseNumberWords(tokens.sublist(start, percentIndex));
      if (parsed != null) {
        return parsed.clamp(50, 100).toDouble();
      }
    }
  }

  final tempoIndex = tokens.indexOf('tempo');
  if (tempoIndex != -1 && tempoIndex + 1 < tokens.length) {
    final parsed = _parseNumberWords(tokens.skip(tempoIndex + 1).take(4).toList());
    if (parsed != null) {
      return parsed.clamp(50, 100).toDouble();
    }
  }
  return null;
}

(int, int)? _parseLoopRange(String text) {
  final digitMatch = RegExp(
    r'\bloop measures?\s+(\d{1,4})\s*(?:to|through|thru|-)\s*(\d{1,4})\b',
  ).firstMatch(text);
  if (digitMatch != null) {
    final first = int.tryParse(digitMatch.group(1)!);
    final second = int.tryParse(digitMatch.group(2)!);
    if (first != null && second != null) {
      return first <= second ? (first, second) : (second, first);
    }
  }

  if (!text.contains('loop measures')) {
    return null;
  }
  final tokens = text.split(' ');
  final startIndex = tokens.indexOf('measures');
  if (startIndex == -1 || startIndex + 1 >= tokens.length) {
    return null;
  }
  final toIndex = tokens.indexWhere((token) => token == 'to' || token == 'through' || token == 'thru');
  if (toIndex == -1 || toIndex <= startIndex + 1 || toIndex + 1 >= tokens.length) {
    return null;
  }
  final first = _parseNumberWords(tokens.sublist(startIndex + 1, toIndex));
  final second = _parseNumberWords(tokens.sublist(toIndex + 1));
  if (first == null || second == null) {
    return null;
  }
  return first <= second ? (first, second) : (second, first);
}

VoiceParseResult? _parseParts(String text) {
  if (RegExp(r'^\s*all\s*$').hasMatch(text)) {
    return VoiceParseResult.success(
      intent: const VoiceIntent(
        type: VoiceIntentType.setMixPreset,
        payload: <String, dynamic>{'preset': 'all'},
      ),
      message: 'All parts on',
    );
  }

  if (RegExp(r'\bpiano off\b').hasMatch(text)) {
    return VoiceParseResult.success(
      intent: const VoiceIntent(
        type: VoiceIntentType.setPartState,
        payload: <String, dynamic>{'part': 'piano', 'enabled': false},
      ),
      message: 'Piano off',
    );
  }
  if (RegExp(r'\bpiano on\b').hasMatch(text)) {
    return VoiceParseResult.success(
      intent: const VoiceIntent(
        type: VoiceIntentType.setPartState,
        payload: <String, dynamic>{'part': 'piano', 'enabled': true},
      ),
      message: 'Piano on',
    );
  }

  final mentionedParts = <ChoirPart>{};
  if (RegExp(r'\bsopranos?\b|\bsop\b').hasMatch(text)) {
    mentionedParts.add(ChoirPart.soprano);
  }
  if (RegExp(r'\baltos?\b').hasMatch(text)) {
    mentionedParts.add(ChoirPart.alto);
  }
  if (RegExp(r'\btenors?\b').hasMatch(text)) {
    mentionedParts.add(ChoirPart.tenor);
  }
  if (RegExp(r'\bbasses?\b|\bbass\b').hasMatch(text)) {
    mentionedParts.add(ChoirPart.bass);
  }
  final mentionsPianoWord = RegExp(r'\bpiano\b').hasMatch(text);
  if (mentionsPianoWord) {
    mentionedParts.add(ChoirPart.piano);
  }

  if (mentionedParts.isEmpty) {
    return null;
  }

  final onlyMode = text.startsWith('only ') ||
      text.endsWith(' only') ||
      text.contains(' only ');

  final enabled = <ChoirPart>{};
  if (onlyMode) {
    enabled.addAll(mentionedParts);
    // "altos only" should still include piano by default.
    if (!enabled.contains(ChoirPart.piano)) {
      enabled.add(ChoirPart.piano);
    }
  } else if (mentionedParts.length == 1 && mentionedParts.contains(ChoirPart.piano)) {
    enabled.add(ChoirPart.piano);
  } else {
    enabled.addAll(mentionedParts);
    if (!enabled.contains(ChoirPart.piano)) {
      enabled.add(ChoirPart.piano);
    }
  }

  return VoiceParseResult.success(
    intent: VoiceIntent(
      type: VoiceIntentType.setMixPreset,
      payload: <String, dynamic>{
        'preset': 'exact',
        'parts': enabled.map((part) => part.id).toList(),
        'pianoOn': enabled.contains(ChoirPart.piano),
      },
    ),
    message: 'Parts: ${_formatParts(enabled)}',
  );
}

String _formatParts(Set<ChoirPart> parts) {
  final ordered = parts.toList()..sort((a, b) => a.index.compareTo(b.index));
  return ordered.map((part) => part.shortLabel).join(' + ');
}

int? _parseNumberWords(List<String> words) {
  if (words.isEmpty) {
    return null;
  }
  var total = 0;
  var current = 0;
  var consumed = false;
  for (final rawWord in words) {
    final word = rawWord.trim();
    if (word.isEmpty) {
      continue;
    }
    if (_units.containsKey(word)) {
      current += _units[word]!;
      consumed = true;
      continue;
    }
    if (_tens.containsKey(word)) {
      current += _tens[word]!;
      consumed = true;
      continue;
    }
    if (word == 'hundred') {
      current = (current == 0 ? 1 : current) * 100;
      consumed = true;
      continue;
    }
    if (word == 'and') {
      continue;
    }
    break;
  }
  if (!consumed) {
    return null;
  }
  total += current;
  return total;
}

const Set<String> _fillerWords = {
  'okay',
  'ok',
  'please',
  'lets',
  'let',
  's',
  'us',
  'um',
  'uh',
};

const Map<String, int> _units = {
  'zero': 0,
  'one': 1,
  'two': 2,
  'three': 3,
  'four': 4,
  'five': 5,
  'six': 6,
  'seven': 7,
  'eight': 8,
  'nine': 9,
  'ten': 10,
  'eleven': 11,
  'twelve': 12,
  'thirteen': 13,
  'fourteen': 14,
  'fifteen': 15,
  'sixteen': 16,
  'seventeen': 17,
  'eighteen': 18,
  'nineteen': 19,
};

const Map<String, int> _tens = {
  'twenty': 20,
  'thirty': 30,
  'forty': 40,
  'fifty': 50,
  'sixty': 60,
  'seventy': 70,
  'eighty': 80,
  'ninety': 90,
};

