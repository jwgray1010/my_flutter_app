import type { ClefSpec, FixtureSpec, NoteSpec, PartSpec, TimeSpec } from "./types";

const C_MAJOR = { fifths: 0, mode: "major" as const, label: "C major" };
const A_MINOR = { fifths: 0, mode: "minor" as const, label: "A minor" };
const G_MAJOR = { fifths: 1, mode: "major" as const, label: "G major" };
const F_MAJOR = { fifths: -1, mode: "major" as const, label: "F major" };
const FOUR: TimeSpec = { beats: 4, beatType: 4 };
const THREE: TimeSpec = { beats: 3, beatType: 4 };
const TREBLE: ClefSpec = { sign: "G", line: 2 };
const BASS: ClefSpec = { sign: "F", line: 4 };
const TENOR_8VB: ClefSpec = { sign: "G", line: 2, octaveChange: -1 };

function line(midi: number, lastMeasure: number, lengthOf: (measure: number) => number, start = 1): NoteSpec[] {
  const notes: NoteSpec[] = [];
  for (let measure = start; measure <= lastMeasure; measure += 1) {
    const beats = lengthOf(measure);
    for (let beat = 0; beat < beats; beat += 1) {
      notes.push({ measure, beat, duration: 1, midi });
    }
  }
  return notes;
}

function voicePart(
  id: string,
  name: string,
  midi: number,
  lastMeasure: number,
  options?: {
    clef?: ClefSpec;
    startMeasure?: number;
    lengthOf?: (measure: number) => number;
    piano?: boolean;
  }
): PartSpec {
  const lengthOf = options?.lengthOf ?? (() => 4);
  const clef = options?.clef ?? TREBLE;
  return {
    id,
    name,
    piano: options?.piano,
    clefs: [clef],
    voices: [
      {
        voice: 1,
        notes: line(midi, lastMeasure, lengthOf, options?.startMeasure ?? 1),
      },
    ],
  };
}

function satb(
  lastMeasure: number,
  lengthOf: (measure: number) => number = () => 4,
  start = 1
): PartSpec[] {
  return [
    voicePart("P1", "Soprano", 72, lastMeasure, { lengthOf, startMeasure: start }),
    voicePart("P2", "Alto", 67, lastMeasure, { lengthOf, startMeasure: start }),
    voicePart("P3", "Tenor", 55, lastMeasure, { clef: BASS, lengthOf, startMeasure: start }),
    voicePart("P4", "Bass", 48, lastMeasure, { clef: BASS, lengthOf, startMeasure: start }),
  ];
}

function pianoPart(
  id: string,
  name: string,
  lastMeasure: number,
  lengthOf: (measure: number) => number = () => 4
): PartSpec {
  return {
    id,
    name,
    piano: true,
    staves: 2,
    clefs: [
      { staff: 1, sign: "G", line: 2 },
      { staff: 2, sign: "F", line: 4 },
    ],
    voices: [
      { voice: 1, staff: 1, notes: line(60, lastMeasure, lengthOf) },
      { voice: 2, staff: 2, notes: line(48, lastMeasure, lengthOf) },
    ],
  };
}

function fourQuarters(): (measure: number) => number {
  return () => 4;
}

export const SYNTHETIC_FIXTURES: FixtureSpec[] = [
  {
    id: "dev-satb-named",
    title: "Named SATB quarters",
    set: "development",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    key: C_MAJOR,
    parts: satb(8),
    expectedVoicing: "SATB",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "dev-ssa-unnamed",
    title: "Three unlabeled treble voices",
    set: "development",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    key: C_MAJOR,
    parts: [
      voicePart("P1", "Voice 1", 76, 8),
      voicePart("P2", "Voice 2", 72, 8),
      voicePart("P3", "Voice 3", 67, 8),
    ],
    expectedVoicing: "Unknown",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "dev-ssaa-unnamed",
    title: "Four unlabeled treble voices",
    set: "development",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    key: C_MAJOR,
    parts: [
      voicePart("P1", "Voice 1", 76, 8),
      voicePart("P2", "Voice 2", 72, 8),
      voicePart("P3", "Voice 3", 69, 8),
      voicePart("P4", "Voice 4", 65, 8),
    ],
    expectedVoicing: "Unknown",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "dev-ttbb-unnamed",
    title: "Four unlabeled bass-clef voices",
    set: "development",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    key: C_MAJOR,
    parts: [
      voicePart("P1", "Voice 1", 57, 8, { clef: BASS }),
      voicePart("P2", "Voice 2", 53, 8, { clef: BASS }),
      voicePart("P3", "Voice 3", 50, 8, { clef: BASS }),
      voicePart("P4", "Voice 4", 45, 8, { clef: BASS }),
    ],
    expectedVoicing: "Unknown",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "dev-sab-unnamed",
    title: "Three unlabeled mixed voices",
    set: "development",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    key: C_MAJOR,
    parts: [
      voicePart("P1", "Voice 1", 72, 8),
      voicePart("P2", "Voice 2", 67, 8),
      voicePart("P3", "Voice 3", 48, 8, { clef: BASS }),
    ],
    expectedVoicing: "Unknown",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "dev-tenor-octave",
    title: "Tenor octave-transposing clef",
    set: "development",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    key: C_MAJOR,
    parts: [voicePart("P1", "Tenor", 67, 8, { clef: TENOR_8VB })],
    expectedVoicing: "Unison",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "dev-a-minor",
    title: "A minor signature",
    set: "development",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    key: A_MINOR,
    parts: satb(8),
    expectedVoicing: "SATB",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "dev-key-change",
    title: "C major to G major",
    set: "development",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    key: C_MAJOR,
    keyChanges: [{ measure: 5, key: G_MAJOR }],
    parts: satb(8),
    expectedVoicing: "SATB",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "dev-missing-backup",
    title: "Shared staff without backup",
    set: "development",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    key: C_MAJOR,
    parts: [
      {
        id: "P1",
        name: "Soprano/Alto",
        omitBackup: true,
        clefs: [TREBLE],
        voices: [
          { voice: 1, notes: line(74, 8, fourQuarters()) },
          { voice: 2, notes: line(67, 8, fourQuarters()) },
        ],
      },
    ],
    expectedVoicing: "SA",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "dev-ties",
    title: "Tied quarters sound as halves",
    set: "development",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    key: C_MAJOR,
    parts: [
      {
        id: "P1",
        name: "Soprano",
        clefs: [TREBLE],
        voices: [{ voice: 1, notes: tiedHalves(72, 8) }],
      },
    ],
    expectedVoicing: "Unison",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "dev-cue-entrance",
    title: "Cue notes before a real entrance",
    set: "development",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    key: C_MAJOR,
    parts: [
      {
        id: "P1",
        name: "Soprano",
        clefs: [TREBLE],
        voices: [{ voice: 1, notes: cuesThenLine(72, 4, 8) }],
      },
      voicePart("P2", "Alto", 67, 8),
    ],
    expectedVoicing: "SA",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "dev-choir-two-staves",
    title: "Two treble staves named Choir",
    set: "development",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    key: C_MAJOR,
    parts: [
      {
        id: "P1",
        name: "Choir",
        staves: 2,
        clefs: [
          { staff: 1, sign: "G", line: 2 },
          { staff: 2, sign: "G", line: 2 },
        ],
        voices: [
          { voice: 1, staff: 1, notes: line(74, 8, fourQuarters()) },
          { voice: 1, staff: 2, notes: line(67, 8, fourQuarters()) },
        ],
      },
    ],
    expectedVoicing: "Unknown",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "dev-ssa-shared",
    title: "Soprano divisi plus Alto",
    set: "development",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    key: C_MAJOR,
    parts: [
      {
        id: "P1",
        name: "Soprano",
        clefs: [TREBLE],
        voices: [
          { voice: 1, notes: line(76, 8, fourQuarters()) },
          { voice: 2, notes: line(72, 8, fourQuarters()) },
        ],
      },
      voicePart("P2", "Alto", 67, 8),
    ],
    expectedVoicing: "SSA",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "dev-repeat",
    title: "Simple repeat",
    set: "development",
    origin: "synthetic",
    measures: 4,
    time: FOUR,
    key: C_MAJOR,
    repeat: { kind: "simple" },
    parts: satb(4),
    expectedVoicing: "SATB",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "dev-volta",
    title: "First and second endings",
    set: "development",
    origin: "synthetic",
    measures: 4,
    time: FOUR,
    key: C_MAJOR,
    repeat: { kind: "volta", firstEnding: 3, secondEnding: 4 },
    parts: satb(4),
    expectedVoicing: "SATB",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "dev-time-change",
    title: "4/4 then 3/4",
    set: "development",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    timeChanges: [{ measure: 5, time: THREE }],
    key: C_MAJOR,
    parts: satb(8, (measure) => (measure >= 5 ? 3 : 4)),
    expectedVoicing: "SATB",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "dev-solo",
    title: "Solo enters before the choir",
    set: "development",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    key: C_MAJOR,
    parts: [
      voicePart("P1", "Solo", 76, 8),
      voicePart("P2", "Soprano", 72, 8, { startMeasure: 5 }),
      voicePart("P3", "Alto", 67, 8, { startMeasure: 5 }),
    ],
    expectedVoicing: "SA + Solo",
    accompaniment: false,
    soloCount: 1,
  },
  {
    id: "dev-unison",
    title: "Unison line",
    set: "development",
    origin: "synthetic",
    measures: 4,
    time: FOUR,
    key: C_MAJOR,
    parts: [voicePart("P1", "Voice", 72, 4)],
    expectedVoicing: "Unison",
    accompaniment: false,
    soloCount: 0,
    omrProbe: true,
  },
  {
    id: "reg-shared-sa",
    title: "Named Soprano/Alto on one staff",
    set: "regression",
    origin: "synthetic",
    measures: 4,
    time: FOUR,
    key: C_MAJOR,
    parts: [
      {
        id: "P1",
        name: "Soprano/Alto",
        clefs: [TREBLE],
        voices: [
          { voice: 1, notes: line(74, 4, fourQuarters()) },
          { voice: 2, notes: line(67, 4, fourQuarters()) },
        ],
      },
    ],
    expectedVoicing: "SA",
    accompaniment: false,
    soloCount: 0,
    omrProbe: true,
  },
  {
    id: "reg-piano-grand",
    title: "SATB with grand-staff piano",
    set: "regression",
    origin: "synthetic",
    measures: 4,
    time: FOUR,
    key: C_MAJOR,
    parts: [...satb(4), pianoPart("P5", "Piano", 4)],
    expectedVoicing: "SATB",
    accompaniment: true,
    soloCount: 0,
  },
  {
    id: "reg-generic-grand",
    title: "Generic grand staff",
    set: "regression",
    origin: "synthetic",
    measures: 4,
    time: FOUR,
    key: C_MAJOR,
    parts: [pianoPart("P1", "Part 1", 4)],
    expectedVoicing: "Piano",
    accompaniment: true,
    soloCount: 0,
  },
  {
    id: "reg-piano-intro",
    title: "Piano introduction before SATB",
    set: "regression",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    key: C_MAJOR,
    parts: [pianoPart("P5", "Piano", 8), ...satb(8, fourQuarters(), 5)],
    expectedVoicing: "SATB",
    accompaniment: true,
    soloCount: 0,
  },
  {
    id: "reg-pickup",
    title: "One-beat pickup",
    set: "regression",
    origin: "synthetic",
    measures: 5,
    time: FOUR,
    pickupQuarters: 1,
    key: C_MAJOR,
    parts: satb(5, (measure) => (measure === 1 ? 1 : 4)),
    expectedVoicing: "SATB",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "reg-sa-named",
    title: "Named SA",
    set: "regression",
    origin: "synthetic",
    measures: 4,
    time: FOUR,
    key: C_MAJOR,
    parts: [voicePart("P1", "Soprano", 74, 4), voicePart("P2", "Alto", 67, 4)],
    expectedVoicing: "SA",
    accompaniment: false,
    soloCount: 0,
    omrProbe: true,
  },
  {
    id: "reg-tb-named",
    title: "Named TB",
    set: "regression",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    key: C_MAJOR,
    parts: [
      voicePart("P1", "Tenor", 57, 8, { clef: BASS }),
      voicePart("P2", "Bass", 48, 8, { clef: BASS }),
    ],
    expectedVoicing: "TB",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "reg-chords",
    title: "Chord tones on the beat",
    set: "regression",
    origin: "synthetic",
    measures: 4,
    time: FOUR,
    key: C_MAJOR,
    parts: [
      {
        id: "P1",
        name: "Soprano",
        clefs: [TREBLE],
        voices: [{ voice: 1, notes: chordOnDownbeats(line(72, 4, fourQuarters()), 67) }],
      },
      voicePart("P2", "Alto", 64, 4),
      voicePart("P3", "Tenor", 55, 4, { clef: BASS }),
      voicePart("P4", "Bass", 48, 4, { clef: BASS }),
    ],
    expectedVoicing: "SATB",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "hold-ssaa-piano-key",
    title: "Four treble voices with piano and a key change",
    set: "heldout",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    key: C_MAJOR,
    keyChanges: [{ measure: 5, key: F_MAJOR }],
    parts: [
      voicePart("P1", "Voice 1", 76, 8),
      voicePart("P2", "Voice 2", 72, 8),
      voicePart("P3", "Voice 3", 69, 8),
      voicePart("P4", "Voice 4", 65, 8),
      pianoPart("P5", "Piano", 8),
    ],
    expectedVoicing: "Unknown",
    accompaniment: true,
    soloCount: 0,
  },
  {
    id: "hold-ttbb-repeat",
    title: "Four bass-clef voices with a repeat",
    set: "heldout",
    origin: "synthetic",
    measures: 4,
    time: FOUR,
    key: C_MAJOR,
    repeat: { kind: "simple" },
    parts: [
      voicePart("P1", "Voice 1", 57, 4, { clef: BASS }),
      voicePart("P2", "Voice 2", 53, 4, { clef: BASS }),
      voicePart("P3", "Voice 3", 50, 4, { clef: BASS }),
      voicePart("P4", "Voice 4", 45, 4, { clef: BASS }),
    ],
    expectedVoicing: "Unknown",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "hold-sab-minor-pickup",
    title: "Three mixed voices in A minor with a pickup",
    set: "heldout",
    origin: "synthetic",
    measures: 5,
    time: FOUR,
    pickupQuarters: 1,
    key: A_MINOR,
    parts: [
      voicePart("P1", "Voice 1", 72, 5, { lengthOf: (measure) => (measure === 1 ? 1 : 4) }),
      voicePart("P2", "Voice 2", 67, 5, { lengthOf: (measure) => (measure === 1 ? 1 : 4) }),
      voicePart("P3", "Voice 3", 48, 5, {
        clef: BASS,
        lengthOf: (measure) => (measure === 1 ? 1 : 4),
      }),
    ],
    expectedVoicing: "Unknown",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "reg-printed-ssa",
    title: "Printed ensemble line and piano",
    set: "regression",
    origin: "synthetic",
    measures: 4,
    time: FOUR,
    key: C_MAJOR,
    credit: "for SSA and Piano",
    parts: [
      voicePart("P1", "Voice 1", 76, 4),
      voicePart("P2", "Voice 2", 72, 4),
      voicePart("P3", "Voice 3", 67, 4),
      pianoPart("P5", "Piano", 4),
    ],
    expectedVoicing: "SSA",
    accompaniment: true,
    soloCount: 0,
  },
  {
    id: "reg-lock-ttbb",
    title: "Director lock on four high voices",
    set: "regression",
    origin: "synthetic",
    measures: 4,
    time: FOUR,
    key: C_MAJOR,
    setup: { choirVoicing: "TTBB", accompaniment: "AUTO", staffLayout: "AUTO" },
    parts: [
      voicePart("P1", "Voice 1", 76, 4),
      voicePart("P2", "Voice 2", 72, 4),
      voicePart("P3", "Voice 3", 69, 4),
      voicePart("P4", "Voice 4", 65, 4),
    ],
    expectedVoicing: "TTBB",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "reg-choir-entrance",
    title: "Piano alone then choir",
    set: "regression",
    origin: "synthetic",
    measures: 8,
    time: FOUR,
    key: C_MAJOR,
    parts: [pianoPart("P5", "Piano", 8), ...satb(8, fourQuarters(), 6)],
    expectedVoicing: "SATB",
    accompaniment: true,
    soloCount: 0,
  },
  {
    id: "reg-satb-shared",
    title: "Shared staff labels",
    set: "regression",
    origin: "synthetic",
    measures: 4,
    time: FOUR,
    key: C_MAJOR,
    parts: [
      {
        id: "P1",
        name: "Soprano/Alto",
        clefs: [TREBLE],
        voices: [
          { voice: 1, notes: line(74, 4, fourQuarters()) },
          { voice: 2, notes: line(67, 4, fourQuarters()) },
        ],
      },
      {
        id: "P2",
        name: "Tenor/Bass",
        clefs: [BASS],
        voices: [
          { voice: 1, notes: line(55, 4, fourQuarters()) },
          { voice: 2, notes: line(48, 4, fourQuarters()) },
        ],
      },
    ],
    expectedVoicing: "SATB",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "reg-chromatic",
    title: "Chromatic notes without a new signature",
    set: "regression",
    origin: "synthetic",
    measures: 4,
    time: FOUR,
    key: C_MAJOR,
    parts: [voicePart("P1", "Soprano", 66, 4), voicePart("P2", "Alto", 62, 4), voicePart("P3", "Tenor", 57, 4, { clef: BASS }), voicePart("P4", "Bass", 48, 4, { clef: BASS })],
    expectedVoicing: "SATB",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "reg-descant",
    title: "Descant above the choir",
    set: "regression",
    origin: "synthetic",
    measures: 4,
    time: FOUR,
    key: C_MAJOR,
    parts: [voicePart("P0", "Descant", 79, 4), ...satb(4)],
    expectedVoicing: "SATB + Descant",
    accompaniment: false,
    soloCount: 1,
  },
  {
    id: "reg-two-part-labels",
    title: "Generic upper and lower parts",
    set: "regression",
    origin: "synthetic",
    measures: 4,
    time: FOUR,
    key: C_MAJOR,
    parts: [voicePart("P1", "Part 1", 72, 4), voicePart("P2", "Part 2", 67, 4)],
    expectedVoicing: "2-Part",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "reg-ds-coda",
    title: "Dal segno and coda",
    set: "regression",
    origin: "synthetic",
    measures: 6,
    time: FOUR,
    key: C_MAJOR,
    navigation: [
      { measure: 1, marks: ["segno"] },
      { measure: 3, marks: ["to-coda"] },
      { measure: 4, marks: ["ds-al-coda"] },
      { measure: 5, marks: ["coda"] },
    ],
    routeOverride: [1, 2, 3, 4, 1, 2, 3, 5, 6],
    parts: [voicePart("P1", "Soprano", 72, 6)],
    expectedVoicing: "Unison",
    accompaniment: false,
    soloCount: 0,
  },
  {
    id: "reg-key-one-staff",
    title: "One staff reports a later signature",
    set: "regression",
    origin: "synthetic",
    measures: 4,
    time: FOUR,
    key: C_MAJOR,
    keyChanges: [{ measure: 3, key: G_MAJOR }],
    keyChangeScope: "first-part",
    parts: satb(4),
    expectedVoicing: "SATB",
    accompaniment: false,
    soloCount: 0,
  },
];

function tiedHalves(midi: number, measures: number): NoteSpec[] {
  const notes: NoteSpec[] = [];
  for (let measure = 1; measure <= measures; measure += 1) {
    notes.push({ measure, beat: 0, duration: 1, midi, tie: "start" });
    notes.push({ measure, beat: 1, duration: 1, midi, tie: "stop" });
    notes.push({ measure, beat: 2, duration: 1, midi: midi - 2, tie: "start" });
    notes.push({ measure, beat: 3, duration: 1, midi: midi - 2, tie: "stop" });
  }
  return notes;
}

function cuesThenLine(midi: number, cueThrough: number, last: number): NoteSpec[] {
  const notes: NoteSpec[] = [];
  for (let measure = 1; measure <= cueThrough; measure += 1) {
    for (let beat = 0; beat < 4; beat += 1) {
      notes.push({ measure, beat, duration: 1, midi: midi - 12, cue: true });
    }
  }
  notes.push(...line(midi, last, () => 4, cueThrough + 1));
  return notes;
}

function chordOnDownbeats(notes: NoteSpec[], chordMidi: number): NoteSpec[] {
  const extra = notes
    .filter((note) => note.beat === 0)
    .map((note) => ({ ...note, midi: chordMidi }));
  return [...notes, ...extra];
}
