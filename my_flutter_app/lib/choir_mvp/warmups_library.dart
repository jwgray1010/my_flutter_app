import 'warmups_models.dart';

class WarmupsLibrary {
  WarmupsLibrary._();

  static List<Warmup> buildAll() {
    final warmups = <Warmup>[];
    for (final category in WarmupCategory.values) {
      final families = _familyNames[category] ?? const <String>[];
      for (var familyIndex = 0; familyIndex < families.length; familyIndex++) {
        final familyTitle = families[familyIndex];
        final archetype = _archetypes[(familyIndex + category.index) % _archetypes.length];
        for (final level in WarmupLevel.values) {
          final profile = _profileFor(level);
          final pattern = _patternFor(archetype, level);
          final warmup = Warmup(
            id: '${category.id}_f${familyIndex + 1}_${level.id.toLowerCase()}',
            title: familyTitle,
            category: category,
            level: level,
            description: _descriptionFor(category, familyTitle),
            focusTags: <String>[
              category.title,
              ...archetype.tags,
              level.title,
            ],
            melodyPattern: pattern,
            defaultTempoBpm: profile.defaultTempoBpm + (familyIndex % 3) * 2,
            defaultStepMode: profile.defaultStepMode,
            repeatsPerKey: profile.repeatsPerKey,
            pauseBetweenKeysMs: profile.pauseBetweenKeysMs,
            rangePresets: profile.rangePresets,
            demoConfig: WarmupDemoConfig(
              supportsDemo: true,
              allowedVoices: const [WarmupDemoVoice.treble, WarmupDemoVoice.boy],
              defaultVoice: WarmupDemoVoice.treble,
              defaultDemoOn: level == WarmupLevel.ms,
            ),
          );
          warmups.add(warmup);
        }
      }
    }
    return warmups;
  }

  static List<Warmup> filter({
    required List<Warmup> warmups,
    required WarmupCategory category,
    required WarmupLevel level,
  }) {
    return warmups
        .where((item) => item.category == category && item.level == level)
        .toList();
  }
}

class _LevelProfile {
  const _LevelProfile({
    required this.defaultTempoBpm,
    required this.defaultStepMode,
    required this.repeatsPerKey,
    required this.pauseBetweenKeysMs,
    required this.rangePresets,
  });

  final int defaultTempoBpm;
  final WarmupStepMode defaultStepMode;
  final int repeatsPerKey;
  final int pauseBetweenKeysMs;
  final List<WarmupRangePreset> rangePresets;
}

class _Archetype {
  const _Archetype({
    required this.msDegrees,
    required this.lhsDegrees,
    required this.uhsDegrees,
    required this.msRhythm,
    required this.lhsRhythm,
    required this.uhsRhythm,
    required this.articulation,
    required this.tags,
  });

  final List<int> msDegrees;
  final List<int> lhsDegrees;
  final List<int> uhsDegrees;
  final List<double> msRhythm;
  final List<double> lhsRhythm;
  final List<double> uhsRhythm;
  final WarmupArticulation articulation;
  final List<String> tags;
}

_LevelProfile _profileFor(WarmupLevel level) {
  switch (level) {
    case WarmupLevel.ms:
      return const _LevelProfile(
        defaultTempoBpm: 68,
        defaultStepMode: WarmupStepMode.halfStep,
        repeatsPerKey: 1,
        pauseBetweenKeysMs: 900,
        rangePresets: [
          WarmupRangePreset(
            name: 'Narrow',
            lowestMidiNote: 55,
            highestMidiNote: 72,
            tessituraLow: 58,
            tessituraHigh: 69,
          ),
          WarmupRangePreset(
            name: 'Core',
            lowestMidiNote: 53,
            highestMidiNote: 74,
            tessituraLow: 57,
            tessituraHigh: 71,
          ),
          WarmupRangePreset(
            name: 'Extended',
            lowestMidiNote: 52,
            highestMidiNote: 76,
            tessituraLow: 56,
            tessituraHigh: 73,
          ),
        ],
      );
    case WarmupLevel.lhs:
      return const _LevelProfile(
        defaultTempoBpm: 82,
        defaultStepMode: WarmupStepMode.halfStep,
        repeatsPerKey: 2,
        pauseBetweenKeysMs: 700,
        rangePresets: [
          WarmupRangePreset(
            name: 'Narrow',
            lowestMidiNote: 50,
            highestMidiNote: 76,
            tessituraLow: 54,
            tessituraHigh: 72,
          ),
          WarmupRangePreset(
            name: 'Core',
            lowestMidiNote: 48,
            highestMidiNote: 79,
            tessituraLow: 52,
            tessituraHigh: 75,
          ),
          WarmupRangePreset(
            name: 'Extended',
            lowestMidiNote: 47,
            highestMidiNote: 81,
            tessituraLow: 50,
            tessituraHigh: 77,
          ),
        ],
      );
    case WarmupLevel.uhs:
      return const _LevelProfile(
        defaultTempoBpm: 96,
        defaultStepMode: WarmupStepMode.wholeStep,
        repeatsPerKey: 2,
        pauseBetweenKeysMs: 550,
        rangePresets: [
          WarmupRangePreset(
            name: 'Narrow',
            lowestMidiNote: 47,
            highestMidiNote: 79,
            tessituraLow: 50,
            tessituraHigh: 75,
          ),
          WarmupRangePreset(
            name: 'Core',
            lowestMidiNote: 45,
            highestMidiNote: 83,
            tessituraLow: 49,
            tessituraHigh: 79,
          ),
          WarmupRangePreset(
            name: 'Extended',
            lowestMidiNote: 43,
            highestMidiNote: 86,
            tessituraLow: 47,
            tessituraHigh: 82,
          ),
        ],
      );
  }
}

WarmupMelodyPattern _patternFor(_Archetype archetype, WarmupLevel level) {
  switch (level) {
    case WarmupLevel.ms:
      return WarmupMelodyPattern(
        scaleDegrees: archetype.msDegrees,
        rhythmPattern: archetype.msRhythm,
        articulation: archetype.articulation,
      );
    case WarmupLevel.lhs:
      return WarmupMelodyPattern(
        scaleDegrees: archetype.lhsDegrees,
        rhythmPattern: archetype.lhsRhythm,
        articulation: archetype.articulation,
      );
    case WarmupLevel.uhs:
      return WarmupMelodyPattern(
        scaleDegrees: archetype.uhsDegrees,
        rhythmPattern: archetype.uhsRhythm,
        articulation: archetype.articulation,
      );
  }
}

String _descriptionFor(WarmupCategory category, String familyTitle) {
  return '${category.title}: $familyTitle';
}

const List<_Archetype> _archetypes = [
  _Archetype(
    msDegrees: [1, 2, 3, 4, 5, 4, 3, 2, 1],
    lhsDegrees: [1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1],
    uhsDegrees: [1, 2, 3, 5, 6, 8, 6, 5, 3, 2, 1],
    msRhythm: [1, 1, 1, 1, 1, 1, 1, 1, 2],
    lhsRhythm: [0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 1.6],
    uhsRhythm: [0.6, 0.6, 0.6, 0.8, 0.6, 0.8, 0.6, 0.8, 0.6, 0.6, 1.4],
    articulation: WarmupArticulation.legato,
    tags: ['line', 'vowel'],
  ),
  _Archetype(
    msDegrees: [1, 3, 5, 3, 1],
    lhsDegrees: [1, 3, 5, 8, 5, 3, 1],
    uhsDegrees: [1, 3, 5, 8, 10, 8, 5, 3, 1],
    msRhythm: [1, 1, 1, 1, 2],
    lhsRhythm: [0.8, 0.8, 0.8, 1, 0.8, 0.8, 1.2],
    uhsRhythm: [0.7, 0.7, 0.7, 0.8, 0.9, 0.8, 0.7, 0.7, 1.2],
    articulation: WarmupArticulation.legato,
    tags: ['triad', 'support'],
  ),
  _Archetype(
    msDegrees: [1, 2, 1, 2, 3, 2, 1],
    lhsDegrees: [1, 2, 3, 2, 4, 3, 2, 1],
    uhsDegrees: [1, 2, 3, 5, 4, 6, 5, 3, 2, 1],
    msRhythm: [0.8, 0.8, 0.8, 0.8, 1, 0.8, 1.2],
    lhsRhythm: [0.6, 0.6, 0.6, 0.6, 0.8, 0.6, 0.6, 1.4],
    uhsRhythm: [0.5, 0.5, 0.5, 0.6, 0.5, 0.6, 0.5, 0.6, 0.5, 1.2],
    articulation: WarmupArticulation.staccato,
    tags: ['agility', 'onset'],
  ),
  _Archetype(
    msDegrees: [1, 5, 1, 5, 1],
    lhsDegrees: [1, 5, 8, 5, 3, 1],
    uhsDegrees: [1, 5, 8, 10, 8, 5, 3, 1],
    msRhythm: [1, 1, 1, 1, 2],
    lhsRhythm: [0.8, 0.8, 1, 0.8, 0.8, 1.4],
    uhsRhythm: [0.7, 0.7, 0.8, 0.9, 0.8, 0.7, 0.7, 1.2],
    articulation: WarmupArticulation.legato,
    tags: ['registration', 'resonance'],
  ),
  _Archetype(
    msDegrees: [1, 2, 3, 2, 1, 2, 3, 4, 3, 2, 1],
    lhsDegrees: [1, 2, 3, 4, 3, 2, 1, 2, 3, 4, 5, 4, 3, 2, 1],
    uhsDegrees: [1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1, 3, 5, 3, 1],
    msRhythm: [0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7, 1.2],
    lhsRhythm: [0.55, 0.55, 0.55, 0.55, 0.55, 0.55, 0.55, 0.55, 0.55, 0.55, 0.55, 0.55, 0.55, 0.55, 1.2],
    uhsRhythm: [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.6, 0.6, 0.6, 1.2],
    articulation: WarmupArticulation.staccato,
    tags: ['speed', 'coordination'],
  ),
  _Archetype(
    msDegrees: [1, 4, 2, 5, 3, 2, 1],
    lhsDegrees: [1, 4, 2, 5, 3, 6, 4, 2, 1],
    uhsDegrees: [1, 4, 2, 6, 3, 7, 5, 3, 2, 1],
    msRhythm: [1, 1, 1, 1, 1, 1, 2],
    lhsRhythm: [0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8, 1.4],
    uhsRhythm: [0.7, 0.7, 0.7, 0.8, 0.7, 0.8, 0.7, 0.7, 0.7, 1.2],
    articulation: WarmupArticulation.legato,
    tags: ['intervals', 'focus'],
  ),
];

const Map<WarmupCategory, List<String>> _familyNames = {
  WarmupCategory.vowelsResonance: [
    'Five-Note Vowel Lift',
    'Open Ah Resonance Arc',
    'OO to EE Focus Slide',
    'Tall Space Resonance Steps',
    'Forward Mask Vowel Pulses',
    'Vowel Spin Ladder',
  ],
  WarmupCategory.dictionArticulation: [
    'Gee-Geh Onset Builder',
    'Noh-Nah Consonant Pulse',
    'Diction Triplet Grid',
    'Soft-T/Hard-D Contrast',
    'Legato Diction Carry',
    'Clean Ends Pattern',
  ],
  WarmupCategory.headVoiceRegistration: [
    'Head Lift Siren',
    'Passaggio Float',
    'Mixed Bridge Glide',
    'Top Space Echo',
    'Light Mechanism Reset',
    'Upper Register Connect',
  ],
  WarmupCategory.breathSupport: [
    'Sustained Support Arc',
    'Pulse to Sustain',
    'Breath Timing Ladder',
    'Appoggio Balance Line',
    'Release and Refill',
    'Silent Breath Reset',
  ],
  WarmupCategory.placementForwardTone: [
    'Forward Buzz Scale',
    'Mask Placement Echo',
    'Bright Ping Arpeggio',
    'Nasal Gate Alignment',
    'Spin and Ring Pattern',
    'Front Vowel Carry',
  ],
  WarmupCategory.blendUnison: [
    'Blend Lock Unison',
    'Unison Color Match',
    'Balanced Core Chord',
    'Tuning Stack Unison',
    'Shared Vowel Beam',
    'Section Merge Arc',
  ],
  WarmupCategory.intonationTuningDrone: [
    'Drone Third Tuning',
    'Fifth Lock Tuner',
    'Octave Alignment Drill',
    'Moving Tone Center',
    'Resolution Tuning Path',
    'Triad Tune and Release',
  ],
  WarmupCategory.agilityFlexibility: [
    'Quick-Shift Five',
    'Agility Burst Cells',
    'Turn Figure Builder',
    'Scale Skip Engine',
    'Leap and Recover Run',
    'Flexible Spiral Pattern',
  ],
  WarmupCategory.legatoLine: [
    'Connected Phrase Arc',
    'Smooth Step Line',
    'Legato Breath Thread',
    'Long-Line Crescendo',
    'Phrase Carry Loop',
    'Line Over Barline',
  ],
  WarmupCategory.staccatoPrecision: [
    'Staccato Dot Grid',
    'Clean Release Pops',
    'Pointed Onset Ladder',
    'Ping Precision Pattern',
    'Fast Dotted Drill',
    'Short Tone Control',
  ],
  WarmupCategory.dynamicControl: [
    'Crescendo Ladder',
    'Decrescendo Return',
    'Terrace Dynamics Steps',
    'Messa Di Voce Cell',
    'Accent then Float',
    'Dynamic Shape Loop',
  ],
  WarmupCategory.rangeBuilder: [
    'Range Rise Anchor',
    'Upper Lift Builder',
    'Low Support Builder',
    'Expanding Span Arcs',
    'Edge Note Stability',
    'Range Endurance Cycle',
  ],
};

