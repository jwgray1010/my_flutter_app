enum WarmupCategory {
  vowelsResonance,
  dictionArticulation,
  headVoiceRegistration,
  breathSupport,
  placementForwardTone,
  blendUnison,
  intonationTuningDrone,
  agilityFlexibility,
  legatoLine,
  staccatoPrecision,
  dynamicControl,
  rangeBuilder,
}

extension WarmupCategoryX on WarmupCategory {
  String get title {
    switch (this) {
      case WarmupCategory.vowelsResonance:
        return 'Vowels & Resonance';
      case WarmupCategory.dictionArticulation:
        return 'Diction & Articulation';
      case WarmupCategory.headVoiceRegistration:
        return 'Head Voice & Registration';
      case WarmupCategory.breathSupport:
        return 'Breath & Support';
      case WarmupCategory.placementForwardTone:
        return 'Placement & Forward Tone';
      case WarmupCategory.blendUnison:
        return 'Blend & Unison';
      case WarmupCategory.intonationTuningDrone:
        return 'Intonation & Tuning (Drone)';
      case WarmupCategory.agilityFlexibility:
        return 'Agility & Flexibility';
      case WarmupCategory.legatoLine:
        return 'Legato Line';
      case WarmupCategory.staccatoPrecision:
        return 'Staccato Precision';
      case WarmupCategory.dynamicControl:
        return 'Dynamic Control';
      case WarmupCategory.rangeBuilder:
        return 'Range Builder';
    }
  }

  String get id {
    switch (this) {
      case WarmupCategory.vowelsResonance:
        return 'vowels_resonance';
      case WarmupCategory.dictionArticulation:
        return 'diction_articulation';
      case WarmupCategory.headVoiceRegistration:
        return 'head_voice_registration';
      case WarmupCategory.breathSupport:
        return 'breath_support';
      case WarmupCategory.placementForwardTone:
        return 'placement_forward_tone';
      case WarmupCategory.blendUnison:
        return 'blend_unison';
      case WarmupCategory.intonationTuningDrone:
        return 'intonation_tuning_drone';
      case WarmupCategory.agilityFlexibility:
        return 'agility_flexibility';
      case WarmupCategory.legatoLine:
        return 'legato_line';
      case WarmupCategory.staccatoPrecision:
        return 'staccato_precision';
      case WarmupCategory.dynamicControl:
        return 'dynamic_control';
      case WarmupCategory.rangeBuilder:
        return 'range_builder';
    }
  }
}

enum WarmupLevel { ms, lhs, uhs }

extension WarmupLevelX on WarmupLevel {
  String get id {
    switch (this) {
      case WarmupLevel.ms:
        return 'MS';
      case WarmupLevel.lhs:
        return 'LHS';
      case WarmupLevel.uhs:
        return 'UHS';
    }
  }

  String get title {
    switch (this) {
      case WarmupLevel.ms:
        return 'Middle';
      case WarmupLevel.lhs:
        return 'Lower HS';
      case WarmupLevel.uhs:
        return 'Upper HS';
    }
  }
}

enum WarmupArticulation { legato, staccato }

enum WarmupStepMode { halfStep, wholeStep }

extension WarmupStepModeX on WarmupStepMode {
  String get shortLabel {
    switch (this) {
      case WarmupStepMode.halfStep:
        return '1/2';
      case WarmupStepMode.wholeStep:
        return 'Whole';
    }
  }

  int get semitoneStep {
    switch (this) {
      case WarmupStepMode.halfStep:
        return 1;
      case WarmupStepMode.wholeStep:
        return 2;
    }
  }
}

enum WarmupTexture { unison, twoPart, sab, satb }

extension WarmupTextureX on WarmupTexture {
  String get label {
    switch (this) {
      case WarmupTexture.unison:
        return 'UNISON';
      case WarmupTexture.twoPart:
        return '2-PART';
      case WarmupTexture.sab:
        return 'SAB';
      case WarmupTexture.satb:
        return 'SATB';
    }
  }
}

enum WarmupDemoVoice { treble, boy }

extension WarmupDemoVoiceX on WarmupDemoVoice {
  String get label {
    switch (this) {
      case WarmupDemoVoice.treble:
        return 'TREBLE';
      case WarmupDemoVoice.boy:
        return 'BOY';
    }
  }
}

class WarmupMelodyPattern {
  const WarmupMelodyPattern({
    required this.scaleDegrees,
    required this.rhythmPattern,
    required this.articulation,
  });

  final List<int> scaleDegrees;
  final List<double> rhythmPattern;
  final WarmupArticulation articulation;
}

class WarmupRangePreset {
  const WarmupRangePreset({
    required this.name,
    required this.lowestMidiNote,
    required this.highestMidiNote,
    required this.tessituraLow,
    required this.tessituraHigh,
  });

  final String name;
  final int lowestMidiNote;
  final int highestMidiNote;
  final int tessituraLow;
  final int tessituraHigh;
}

class WarmupDemoConfig {
  const WarmupDemoConfig({
    required this.supportsDemo,
    required this.allowedVoices,
    required this.defaultVoice,
    required this.defaultDemoOn,
  });

  final bool supportsDemo;
  final List<WarmupDemoVoice> allowedVoices;
  final WarmupDemoVoice defaultVoice;
  final bool defaultDemoOn;
}

class Warmup {
  const Warmup({
    required this.id,
    required this.title,
    required this.category,
    required this.level,
    required this.description,
    required this.focusTags,
    required this.melodyPattern,
    required this.defaultTempoBpm,
    required this.defaultStepMode,
    required this.repeatsPerKey,
    required this.pauseBetweenKeysMs,
    required this.rangePresets,
    required this.demoConfig,
  });

  final String id;
  final String title;
  final WarmupCategory category;
  final WarmupLevel level;
  final String description;
  final List<String> focusTags;
  final WarmupMelodyPattern melodyPattern;
  final int defaultTempoBpm;
  final WarmupStepMode defaultStepMode;
  final int repeatsPerKey;
  final int pauseBetweenKeysMs;
  final List<WarmupRangePreset> rangePresets;
  final WarmupDemoConfig demoConfig;
}

