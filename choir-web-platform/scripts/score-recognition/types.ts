export type FixtureSet = "development" | "regression" | "heldout";

export type KeyMode = "major" | "minor";

export interface KeySpec {
  fifths: number;
  mode: KeyMode;
  label: string;
}

export interface TimeSpec {
  beats: number;
  beatType: number;
}

export interface NoteSpec {
  measure: number;
  beat: number;
  duration: number;
  /** Written MIDI pitch, before clef octave transposition. */
  midi: number;
  tie?: "start" | "stop" | "continue";
  cue?: boolean;
}

export interface VoiceSpec {
  voice: number;
  staff?: number;
  notes: NoteSpec[];
}

export interface ClefSpec {
  staff?: number;
  sign: "G" | "F" | "C";
  line: number;
  octaveChange?: number;
}

export interface PartSpec {
  id: string;
  name: string;
  /** When true, every staff and voice stays one accompaniment part. */
  piano?: boolean;
  staves?: number;
  clefs: ClefSpec[];
  voices: VoiceSpec[];
  /**
   * Emit later voices after the first with no backup/forward.
   * This mimics OMR that concatenates shared-staff voices.
   */
  omitBackup?: boolean;
}

export type RepeatSpec =
  | { kind: "simple" }
  | { kind: "volta"; firstEnding: number; secondEnding: number };

export interface FixtureSpec {
  id: string;
  title: string;
  set: FixtureSet;
  origin: "synthetic";
  measures: number;
  time: TimeSpec;
  timeChanges?: { measure: number; time: TimeSpec }[];
  key: KeySpec;
  keyChanges?: { measure: number; key: KeySpec }[];
  /** When set, only the first part receives later key elements. */
  keyChangeScope?: "all" | "first-part";
  credit?: string;
  navigation?: { measure: number; marks: Array<"segno" | "coda" | "to-coda" | "ds-al-coda" | "fine" | "dc-al-fine"> }[];
  routeOverride?: number[];
  setup?: {
    choirVoicing: "AUTO" | "UNISON" | "TWO_PART" | "SA" | "SS" | "SSA" | "SSAA" | "SAT" | "SAB" | "SATB" | "TTB" | "TTBB" | "SSAATTBB" | "CUSTOM";
    accompaniment: "AUTO" | "NONE" | "PIANO" | "OTHER";
    staffLayout: "AUTO" | "CUSTOM" | "SATB_SHARED_2" | "SATB_SEPARATE_4" | "SSA_SHARED_2" | "SSA_SEPARATE_3" | "SSAA_SHARED_2" | "SSAA_SEPARATE_4" | "SSAATTBB_SHARED_4" | "SSAATTBB_SEPARATE_8";
  };
  /** Quarter-lengths of measure 1 when it is a written pickup. */
  pickupQuarters?: number;
  repeat?: RepeatSpec;
  parts: PartSpec[];
  expectedVoicing: string;
  accompaniment: boolean;
  soloCount: number;
  omrProbe?: boolean;
}

export interface ExpectedEvent {
  partId: string;
  startBeat: number;
  midi: number;
  duration: number;
}

export interface ExpectedKeyRegion {
  startMeasure: number;
  fifths: number;
  mode: KeyMode;
  label: string;
}

export interface ExpectedScore {
  voicing: string;
  logicalPartCount: number;
  accompaniment: boolean;
  pianoEntranceMeasure: number | null;
  soloCount: number;
  writtenMeasureCount: number;
  timeSignatures: string[];
  measureBeats: number[];
  keyRegions: ExpectedKeyRegion[];
  performanceRoute: number[];
  entrances: { partId: string; measure: number }[];
  events: ExpectedEvent[];
}

export interface FixtureProvenance {
  sourceUrl: string | null;
  originalAuthor: string;
  license: string;
  sourceFormat: string;
  referenceFormat: string;
  downloadDate: string | null;
  conversionMethod: string;
  origin: "synthetic" | "encoded-public-domain";
}

export interface RealizedFixture {
  spec: FixtureSpec;
  xml: string;
  expected: ExpectedScore;
  provenance: FixtureProvenance;
}
