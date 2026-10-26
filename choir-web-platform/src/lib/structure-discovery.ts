import type { KeyRegion, MeasureInfo, ParsedScore, RecognizedPart } from "@/lib/score-types";
import type { RouteMeasure } from "@/lib/playback-model";
import type {
  ChoirVoicingId,
  ClefRegion,
  DivisiRegion,
  KeyTraceEntry,
  NavigationEvent,
  ScoreSystem,
  StaffGroup,
  StructuredWarning,
  TempoRegion,
  TimeSignatureRegion,
} from "@/lib/score-model";
import { voicingDisplayLabel } from "@/lib/score-model";

export interface DirectionFact {
  measureIndex: number;
  measureNumber: number;
  text: string;
  symbols: string[];
}

export interface StaffKeyFact {
  partId: string;
  measureNumber: number;
  fifths: number;
  mode: "major" | "minor";
}

export interface PrintFact {
  measureIndex: number;
  measureNumber: number;
  newSystem: boolean;
  newPage: boolean;
}

export interface ClefFact {
  partId: string;
  staff: number;
  measureNumber: number;
  sign: string;
  octaveChange: number;
}

export interface TempoFact {
  measureNumber: number;
  bpm: number | null;
  text: string | null;
}

export interface VoiceDurationFact {
  partId: string;
  measureNumber: number;
  voice: number;
  beats: number;
  nominal: number;
}

export interface StructuralFacts {
  credits: string[];
  partNames: { id: string; name: string }[];
  directions: DirectionFact[];
  staffKeys: StaffKeyFact[];
  prints: PrintFact[];
  clefs: ClefFact[];
  tempos: TempoFact[];
  voiceDurations: VoiceDurationFact[];
  repeats: RouteMeasure[];
}

const ENSEMBLE_PATTERNS: { pattern: RegExp; voicing: ChoirVoicingId }[] = [
  { pattern: /\bssaattbb\b/i, voicing: "SSAATTBB" },
  { pattern: /\bssaa\b/i, voicing: "SSAA" },
  { pattern: /\bsatb\b/i, voicing: "SATB" },
  { pattern: /\bttbb\b/i, voicing: "TTBB" },
  { pattern: /\bssa\b/i, voicing: "SSA" },
  { pattern: /\bttb\b/i, voicing: "TTB" },
  { pattern: /\bsab\b/i, voicing: "SAB" },
  { pattern: /\bsat\b/i, voicing: "SAT" },
  { pattern: /\b(2[\s-]*part|two[\s-]*part)\b/i, voicing: "TWO_PART" },
  { pattern: /\b(3[\s-]*part|three[\s-]*part)\b/i, voicing: "CUSTOM" },
  { pattern: /\bunison\b/i, voicing: "UNISON" },
];

const MAJOR_KEYS = ["Cb", "Gb", "Db", "Ab", "Eb", "Bb", "F", "C", "G", "D", "A", "E", "B", "F#", "C#"];
const MINOR_KEYS = ["Ab", "Eb", "Bb", "F", "C", "G", "D", "A", "E", "B", "F#", "C#", "G#", "D#", "A#"];

export function describeKeySignature(fifths: number, mode: "major" | "minor") {
  const table = mode === "minor" ? MINOR_KEYS : MAJOR_KEYS;
  const index = fifths + 7;
  if (index >= 0 && index < table.length) {
    return `${table[index]} ${mode}`;
  }
  return `${fifths} fifths`;
}

export function discoverEnsembleText(facts: StructuralFacts): {
  voicing: ChoirVoicingId | null;
  phrase: string | null;
  aCappella: boolean;
  mentionsPiano: boolean;
} {
  const texts = [
    ...facts.credits,
    ...facts.partNames.map((part) => part.name),
    ...facts.directions.map((direction) => direction.text),
  ];
  let voicing: ChoirVoicingId | null = null;
  let phrase: string | null = null;
  let aCappella = false;
  let mentionsPiano = false;
  for (const text of texts) {
    if (/\ba\s*cappella\b/i.test(text)) {
      aCappella = true;
    }
    if (/\b(piano|pno|keyboard|organ|accompaniment)\b/i.test(text)) {
      mentionsPiano = true;
    }
    if (voicing) {
      continue;
    }
    for (const candidate of ENSEMBLE_PATTERNS) {
      if (candidate.pattern.test(text)) {
        voicing = candidate.voicing;
        phrase = text.trim();
        break;
      }
    }
  }
  return { voicing, phrase, aCappella, mentionsPiano };
}

export function genericPartPair(parts: RecognizedPart[]): boolean {
  const choir = parts.filter((part) => part.canonicalPart !== "PIANO" && !part.isSolo && !part.extraKind);
  if (choir.length !== 2) {
    return false;
  }
  return choir.every((part) => isGenericVoiceLabel(part.sourceName));
}

export function isGenericVoiceLabel(name: string): boolean {
  const normalized = name.toLowerCase().replace(/\./g, "").trim();
  return /^(part|voice)\s*(i|ii|1|2)$/.test(normalized) || /^(upper|lower)\s+voice$/.test(normalized);
}

export function reconcileKeyRegions(
  facts: StructuralFacts,
  measures: MeasureInfo[]
): { regions: KeyRegion[]; trace: KeyTraceEntry[]; warnings: StructuredWarning[] } {
  const byMeasure = new Map<number, StaffKeyFact[]>();
  for (const key of facts.staffKeys) {
    const list = byMeasure.get(key.measureNumber) ?? [];
    list.push(key);
    byMeasure.set(key.measureNumber, list);
  }
  const partIds = [...new Set(facts.staffKeys.map((key) => key.partId))];
  const warnings: StructuredWarning[] = [];
  const accepted: KeyRegion[] = [];
  const trace: KeyTraceEntry[] = [];
  let current: { fifths: number; mode: "major" | "minor" } | null = null;
  const orderedMeasures = [...byMeasure.keys()].sort((a, b) => a - b);
  const rejected = new Set<number>();

  const flicker = flickeringMeasures(orderedMeasures, byMeasure);
  for (const measure of flicker) {
    rejected.add(measure);
    warnings.push({
      code: "KEY_FLICKER",
      message: `m.${measure} — possible key-signature conflict`,
      measure,
      page: null,
      system: null,
    });
  }

  for (const measure of orderedMeasures) {
    if (rejected.has(measure)) {
      continue;
    }
    const reports = byMeasure.get(measure) ?? [];
    const signature = agreedSignature(reports);
    if (!signature) {
      warnings.push({
        code: "KEY_DISAGREEMENT",
        message: `m.${measure} — staves do not agree on a key signature`,
        measure,
        page: null,
        system: null,
      });
      continue;
    }
    if (signature.modeConflict) {
      warnings.push({
        code: "KEY_MODE",
        message: `m.${measure} — staves agree on the signature but not the mode word`,
        measure,
        page: null,
        system: null,
      });
    }
    if (partIds.length > 1 && reports.length < partIds.length && current) {
      warnings.push({
        code: "KEY_SINGLE_STAFF",
        message: `m.${measure} — one staff reports a new key while the others do not`,
        measure,
        page: null,
        system: null,
      });
      continue;
    }
    if (current && current.fifths === signature.fifths && current.mode === signature.mode) {
      continue;
    }
    const label = describeKeySignature(signature.fifths, signature.mode);
    trace.push({
      oldKey: current ? describeKeySignature(current.fifths, current.mode) : null,
      newKey: label,
      measure,
      source: reports.length > 1 ? "cross-staff MusicXML key" : "MusicXML key",
      confidence: reports.length > 1 ? 0.95 : 0.8,
    });
    accepted.push({ startMeasure: measure, fifths: signature.fifths, mode: signature.mode, label });
    current = signature;
  }

  if (!accepted.length && measures.length) {
    return { regions: [], trace, warnings };
  }
  return { regions: accepted, trace, warnings };
}

export function buildSystems(measures: MeasureInfo[], prints: PrintFact[], staffIds: string[]): ScoreSystem[] {
  if (!measures.length) {
    return [];
  }
  const breaks = new Map<number, PrintFact>();
  for (const print of prints) {
    if (print.newSystem || print.newPage) {
      breaks.set(print.measureIndex, print);
    }
  }
  const systems: ScoreSystem[] = [];
  let page = 1;
  let systemNumber = 1;
  let start = 0;
  for (let index = 0; index < measures.length; index += 1) {
    const print = breaks.get(index);
    if (index > 0 && print) {
      systems.push(systemFrom(measures, start, index - 1, page, systemNumber, staffIds));
      if (print.newPage) {
        page += 1;
        systemNumber = 1;
      } else {
        systemNumber += 1;
      }
      start = index;
    }
  }
  systems.push(systemFrom(measures, start, measures.length - 1, page, systemNumber, staffIds));
  return systems;
}

export function buildNavigation(measures: MeasureInfo[], facts: StructuralFacts): NavigationEvent[] {
  const events: NavigationEvent[] = [];
  facts.repeats.forEach((repeat, index) => {
    const measureNumber = measures[index]?.displayNumber ?? repeat.number;
    if (repeat.repeatForward) {
      events.push({ kind: "REPEAT_START", measureIndex: index, measureNumber });
    }
    if (repeat.repeatBackward) {
      events.push({
        kind: "REPEAT_END",
        measureIndex: index,
        measureNumber,
        times: repeat.repeatTimes,
      });
    }
    if (repeat.ending != null) {
      events.push({
        kind: "ENDING",
        measureIndex: index,
        measureNumber,
        ending: repeat.ending,
      });
    }
  });
  for (const direction of facts.directions) {
    const text = direction.text;
    const symbols = new Set(direction.symbols);
    if (symbols.has("segno") || /\bsegno\b/i.test(text)) {
      events.push(nav("SEGNO", direction));
    }
    if (symbols.has("coda") || /^\s*coda\b/i.test(text)) {
      events.push(nav("CODA", direction));
    }
    if (/\bto coda\b/i.test(text) || symbols.has("to-coda")) {
      events.push(nav("TO_CODA", direction, text));
    }
    if (/\bd\.\s*s\.|\bdal segno\b/i.test(text)) {
      events.push({
        ...nav("DS", direction, text),
        alCoda: /coda/i.test(text),
        alFine: /fine/i.test(text),
      });
    }
    if (/\bd\.\s*c\.|\bda capo\b/i.test(text)) {
      events.push({
        ...nav("DC", direction, text),
        alCoda: /coda/i.test(text),
        alFine: /fine/i.test(text),
      });
    }
    if (/\bfine\b/i.test(text) && !/\bd\.\s*[sc]\./i.test(text) && !/da capo|dal segno/i.test(text)) {
      events.push(nav("FINE", direction, text));
    }
  }
  return events;
}

export function buildTimeRegions(measures: MeasureInfo[]): TimeSignatureRegion[] {
  const regions: TimeSignatureRegion[] = [];
  for (const measure of measures) {
    const previous = regions[regions.length - 1];
    if (previous && previous.timeSignature === measure.timeSignature) {
      previous.endMeasure = measure.displayNumber;
      continue;
    }
    regions.push({
      startMeasure: measure.displayNumber,
      endMeasure: measure.displayNumber,
      timeSignature: measure.timeSignature,
    });
  }
  return regions;
}

export function buildClefRegions(facts: StructuralFacts, measures: MeasureInfo[]): ClefRegion[] {
  const last = measures[measures.length - 1]?.displayNumber ?? 1;
  const grouped = new Map<string, ClefFact[]>();
  for (const clef of facts.clefs) {
    const id = `${clef.partId}:${clef.staff}`;
    const list = grouped.get(id) ?? [];
    list.push(clef);
    grouped.set(id, list);
  }
  const regions: ClefRegion[] = [];
  for (const [staffId, clefs] of grouped) {
    clefs.sort((a, b) => a.measureNumber - b.measureNumber);
    clefs.forEach((clef, index) => {
      const next = clefs[index + 1];
      regions.push({
        staffId,
        startMeasure: clef.measureNumber,
        endMeasure: next ? next.measureNumber - 1 : last,
        sign: clef.sign,
        octaveChange: clef.octaveChange,
      });
    });
  }
  return regions;
}

export function buildTempoRegions(facts: StructuralFacts, measures: MeasureInfo[]): TempoRegion[] {
  if (!facts.tempos.length || !measures.length) {
    return [];
  }
  const last = measures[measures.length - 1].displayNumber;
  const sorted = [...facts.tempos].sort((a, b) => a.measureNumber - b.measureNumber);
  return sorted.map((tempo, index) => ({
    startMeasure: tempo.measureNumber,
    endMeasure: sorted[index + 1] ? sorted[index + 1].measureNumber - 1 : last,
    bpm: tempo.bpm,
    text: tempo.text,
  }));
}

export function rhythmWarnings(facts: StructuralFacts, measures: MeasureInfo[]): StructuredWarning[] {
  const pickup = new Set(
    measures
      .filter((measure, index) => index === 0 && measure.beatsInMeasure + 0.05 < nominalOf(measure.timeSignature))
      .map((measure) => measure.displayNumber)
  );
  const warnings: StructuredWarning[] = [];
  const seen = new Set<string>();
  for (const voice of facts.voiceDurations) {
    if (pickup.has(voice.measureNumber)) {
      continue;
    }
    if (Math.abs(voice.beats - voice.nominal) <= 0.05) {
      continue;
    }
    const key = `${voice.measureNumber}:${voice.partId}:${voice.voice}`;
    if (seen.has(key)) {
      continue;
    }
    seen.add(key);
    warnings.push({
      code: "RHYTHM_DURATION",
      message: `m.${voice.measureNumber} — voice ${voice.voice} lasts ${round(voice.beats)} beats in ${round(voice.nominal)}`,
      measure: voice.measureNumber,
      page: null,
      system: null,
    });
  }
  return warnings;
}

export function divisiRegions(facts: StructuralFacts, parts: RecognizedPart[], measures: MeasureInfo[]): DivisiRegion[] {
  const last = measures[measures.length - 1]?.displayNumber ?? 1;
  const regions: DivisiRegion[] = [];
  for (const direction of facts.directions) {
    if (!/\bdiv\.?\b|divisi/i.test(direction.text)) {
      continue;
    }
    const part = parts.find((candidate) => !candidate.isSolo && candidate.canonicalPart !== "PIANO");
    if (!part) {
      continue;
    }
    regions.push({
      partId: part.id,
      startMeasure: direction.measureNumber,
      endMeasure: last,
      label: direction.text.trim(),
    });
  }
  return regions;
}

export function endSoloMeasure(facts: StructuralFacts): number | null {
  let end: number | null = null;
  for (const direction of facts.directions) {
    if (/\bend\s+solo\b/i.test(direction.text)) {
      end = direction.measureNumber;
    }
  }
  return end;
}

export function firstChoirSystem(systems: ScoreSystem[], score: ParsedScore): number | null {
  const choirIds = new Set(
    score.parts.filter((part) => part.canonicalPart !== "PIANO" && !part.isSolo && !part.extraKind).map((part) => part.id)
  );
  for (const system of systems) {
    const [start, end] = system.measureRange;
    const active = score.notes.some(
      (note) => choirIds.has(note.partId) && note.measureNumber >= start && note.measureNumber <= end
    );
    if (active) {
      return system.systemNumber;
    }
  }
  return systems[0]?.systemNumber ?? null;
}

export function mainChoirStaffGroup(score: ParsedScore): StaffGroup | null {
  const staves = score.parts
    .filter((part) => part.canonicalPart !== "PIANO" && !part.isSolo && !part.extraKind)
    .map((part) => staffIdOf(part));
  if (!staves.length) {
    return null;
  }
  return {
    id: "main-choir",
    kind: "MAIN_CHOIR",
    label: "Main choir",
    staves,
  };
}

export function staffIdOf(part: RecognizedPart): string {
  const staff = part.voiceNumber != null && part.id.includes(":s") ? part.id.split(":s")[1]?.split(":")[0] : "1";
  return `${part.sourcePartId}:s${staff ?? "1"}`;
}

export function validationWarnings(score: ParsedScore, mainVoicing: string, locked: boolean): StructuredWarning[] {
  const warnings: StructuredWarning[] = [];
  const choir = score.parts.filter((part) => part.canonicalPart !== "PIANO" && !part.isSolo && !part.extraKind);
  if (!choir.length && score.notes.some((note) => note.partCanonical !== "PIANO")) {
    warnings.push(warn("MISSING_PARTS", "Expected choir parts were not identified."));
  }
  const pianoNotes = score.notes.filter((note) => note.partCanonical === "PIANO");
  const pianoOnChoir = pianoNotes.some((note) =>
    choir.some((part) => part.id === note.partId)
  );
  if (pianoOnChoir) {
    warnings.push(warn("PIANO_IN_CHOIR", "Piano notes were stored on a choir part."));
  }
  if (locked && score.inferredVoicing && !score.inferredVoicing.startsWith(mainVoicing)) {
    warnings.push(warn("VOICING_DRIFT", "The displayed voicing does not start with the locked choir voicing."));
  }
  const labels = score.measures.map((measure) => measure.displayLabel ?? String(measure.displayNumber));
  if (new Set(labels).size !== labels.length) {
    warnings.push(warn("DUPLICATE_MEASURE", "DUPLICATE WRITTEN MEASURE"));
  }
  return warnings;
}

function warn(code: string, message: string): StructuredWarning {
  return { code, message, measure: null, page: null, system: null };
}

function systemFrom(
  measures: MeasureInfo[],
  start: number,
  end: number,
  pageNumber: number,
  systemNumber: number,
  staffIds: string[]
): ScoreSystem {
  const first = measures[start];
  const last = measures[end];
  return {
    pageNumber,
    systemNumber,
    topY: null,
    bottomY: null,
    physicalStaves: staffIds,
    staffGroups: [],
    measureRange: [first.displayNumber, last.displayNumber],
  };
}

function nav(kind: NavigationEvent["kind"], direction: DirectionFact, text?: string): NavigationEvent {
  return {
    kind,
    measureIndex: direction.measureIndex,
    measureNumber: direction.measureNumber,
    text,
  };
}

function agreedSignature(
  reports: StaffKeyFact[]
): { fifths: number; mode: "major" | "minor"; modeConflict: boolean } | null {
  if (!reports.length) {
    return null;
  }
  const fifths = reports[0].fifths;
  if (reports.some((report) => report.fifths !== fifths)) {
    return null;
  }
  const modes = new Set(reports.map((report) => report.mode));
  return {
    fifths,
    mode: reports[0].mode,
    modeConflict: modes.size > 1,
  };
}

function uniqueSignatures(reports: StaffKeyFact[]): { fifths: number; mode: "major" | "minor" }[] {
  const seen = new Map<string, { fifths: number; mode: "major" | "minor" }>();
  for (const report of reports) {
    seen.set(`${report.fifths}:${report.mode}`, { fifths: report.fifths, mode: report.mode });
  }
  return [...seen.values()];
}

function flickeringMeasures(measures: number[], byMeasure: Map<number, StaffKeyFact[]>): number[] {
  const changes: { measure: number; label: string }[] = [];
  let lastLabel = "";
  for (const measure of measures) {
    const signature = uniqueSignatures(byMeasure.get(measure) ?? [])[0];
    if (!signature) {
      continue;
    }
    const label = `${signature.fifths}:${signature.mode}`;
    if (label === lastLabel) {
      continue;
    }
    changes.push({ measure, label });
    lastLabel = label;
  }
  const rejected: number[] = [];
  let run: { measure: number; label: string }[] = [];
  const flush = () => {
    if (run.length >= 3) {
      rejected.push(...run.slice(1).map((change) => change.measure));
    }
    run = [];
  };
  for (const change of changes) {
    const previous = run[run.length - 1];
    if (previous && change.measure === previous.measure + 1) {
      run.push(change);
      continue;
    }
    flush();
    run = [change];
  }
  flush();
  return rejected;
}

function nominalOf(timeSignature: string): number {
  const [beats, beatType] = timeSignature.split("/").map((part) => Number(part));
  if (!beats || !beatType) {
    return 4;
  }
  return beats * (4 / beatType);
}

function round(value: number): number {
  return Math.round(value * 100) / 100;
}

export function ensembleLabel(voicing: ChoirVoicingId): string {
  return voicingDisplayLabel(voicing);
}
