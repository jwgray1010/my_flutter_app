import 'package:flutter_test/flutter_test.dart';
import 'package:unsaid/choir_mvp/voice_commands.dart';

void main() {
  group('VoiceCommandParser deterministic phrases', () {
    final parser = VoiceCommandParser();
    final rehearsalMarks = <String, int>{
      'A': 12,
      'B': 28,
      'C': 42,
    };

    final phrases = <_IntentCase>[
      _IntentCase('play', VoiceIntentType.play),
      _IntentCase('okay start', VoiceIntentType.play),
      _IntentCase('resume please', VoiceIntentType.play),
      _IntentCase('pause', VoiceIntentType.pause),
      _IntentCase('stop', VoiceIntentType.pause),
      _IntentCase('measure 32', VoiceIntentType.jumpToMeasure, <String, dynamic>{'measure': 32}),
      _IntentCase('from measure 19', VoiceIntentType.jumpToMeasure, <String, dynamic>{'measure': 19}),
      _IntentCase('go to measure 88', VoiceIntentType.jumpToMeasure, <String, dynamic>{'measure': 88}),
      _IntentCase('bar 64', VoiceIntentType.jumpToMeasure, <String, dynamic>{'measure': 64}),
      _IntentCase('letter A', VoiceIntentType.jumpToMeasure, <String, dynamic>{'measure': 12}),
      _IntentCase('back two measures', VoiceIntentType.jumpRelative, <String, dynamic>{'delta': -2}),
      _IntentCase('back 2', VoiceIntentType.jumpRelative, <String, dynamic>{'delta': -2}),
      _IntentCase('back one measure', VoiceIntentType.jumpRelative, <String, dynamic>{'delta': -1}),
      _IntentCase('forward two measures', VoiceIntentType.jumpRelative, <String, dynamic>{'delta': 2}),
      _IntentCase('forward 2', VoiceIntentType.jumpRelative, <String, dynamic>{'delta': 2}),
      _IntentCase('slower', VoiceIntentType.adjustTempo, <String, dynamic>{'delta': -5}),
      _IntentCase('faster', VoiceIntentType.adjustTempo, <String, dynamic>{'delta': 5}),
      _IntentCase('tempo 70', VoiceIntentType.setTempo, <String, dynamic>{'percent': 70.0}),
      _IntentCase('seventy percent', VoiceIntentType.setTempo, <String, dynamic>{'percent': 70.0}),
      _IntentCase('set tempo to 80', VoiceIntentType.setTempo, <String, dynamic>{'percent': 80.0}),
      _IntentCase('seventy five percent', VoiceIntentType.setTempo, <String, dynamic>{'percent': 75.0}),
      _IntentCase('loop', VoiceIntentType.setLoopA, <String, dynamic>{'armToggle': true}),
      _IntentCase('loop this', VoiceIntentType.setLoopA, <String, dynamic>{'armToggle': true}),
      _IntentCase('set loop A', VoiceIntentType.setLoopA),
      _IntentCase('set loop B', VoiceIntentType.setLoopB),
      _IntentCase('clear loop', VoiceIntentType.clearLoop),
      _IntentCase('loop measures 48 to 56', VoiceIntentType.setLoopRange, <String, dynamic>{'a': 48, 'b': 56}),
      _IntentCase('all', VoiceIntentType.setMixPreset, <String, dynamic>{'preset': 'all'}),
      _IntentCase('piano', VoiceIntentType.setMixPreset, <String, dynamic>{'preset': 'exact'}),
      _IntentCase('soprano', VoiceIntentType.setMixPreset, <String, dynamic>{'preset': 'exact'}),
      _IntentCase('sopranos and altos', VoiceIntentType.setMixPreset, <String, dynamic>{'preset': 'exact'}),
      _IntentCase('tenors and basses', VoiceIntentType.setMixPreset, <String, dynamic>{'preset': 'exact'}),
      _IntentCase('only altos', VoiceIntentType.setMixPreset, <String, dynamic>{'preset': 'exact'}),
      _IntentCase('altos only', VoiceIntentType.setMixPreset, <String, dynamic>{'preset': 'exact'}),
      _IntentCase('piano off', VoiceIntentType.setPartState, <String, dynamic>{'part': 'piano', 'enabled': false}),
      _IntentCase('piano on', VoiceIntentType.setPartState, <String, dynamic>{'part': 'piano', 'enabled': true}),
      _IntentCase('starting pitch', VoiceIntentType.playStartingPitches),
      _IntentCase('give me starting pitches', VoiceIntentType.playStartingPitches),
      _IntentCase('give pitches', VoiceIntentType.playStartingPitches),
      _IntentCase('play starting pitches', VoiceIntentType.playStartingPitches),
    ];

    for (final phrase in phrases) {
      test('parses "${phrase.input}"', () {
        final result = parser.parse(phrase.input, rehearsalMarks: rehearsalMarks);
        expect(result.isSuccess, isTrue);
        final intent = result.intent;
        expect(intent, isNotNull);
        expect(intent!.type, phrase.type);
        for (final entry in phrase.contains.entries) {
          expect(intent.payload[entry.key], entry.value);
        }
      });
    }

    test('letter command fails gracefully when rehearsal marks missing', () {
      final result = parser.parse('letter A', rehearsalMarks: const <String, int>{});
      expect(result.isSuccess, isFalse);
      expect(result.message, 'No rehearsal marks in this score');
    });

    test('normalization strips filler words and punctuation', () {
      final normalized = normalizeTranscript("Okay, please let's go to measure 32!");
      expect(normalized, 'go to measure 32');
    });
  });
}

class _IntentCase {
  const _IntentCase(
    this.input,
    this.type, [
    this.contains = const <String, dynamic>{},
  ]);

  final String input;
  final VoiceIntentType type;
  final Map<String, dynamic> contains;
}

