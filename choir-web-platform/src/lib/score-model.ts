import type { CanonicalPartId, KeyRegion } from "@/lib/score-types";

export const PIPELINE_VERSION = "UNIFIED_SCORE_PIPELINE_V1";

export const OLD_PIPELINE_MESSAGE =
  "This score was processed with an older recognition system. Please reprocess it using the current score engine.";

export type SourceUploadType = "PDF" | "SINGLE_IMAGE" | "MULTI_IMAGE" | "MUSICXML";

export type ChoirVoicingId =
  | "AUTO"
  | "UNISON"
  | "TWO_PART"
  | "SA"
  | "SS"
  | "SSA"
  | "SSAA"
  | "SAT"
  | "SAB"
  | "SATB"
  | "TTB"
  | "TTBB"
  | "SSAATTBB"
  | "CUSTOM";

export type AccompanimentChoice = "AUTO" | "NONE" | "PIANO" | "OTHER";

export type StaffLayoutId =
  | "AUTO"
  | "CUSTOM"
  | "SATB_SHARED_2"
  | "SATB_SEPARATE_4"
  | "SSA_SHARED_2"
  | "SSA_SEPARATE_3"
  | "SSAA_SHARED_2"
  | "SSAA_SEPARATE_4"
  | "SSAATTBB_SHARED_4"
  | "SSAATTBB_SEPARATE_8";

export interface ScoreSetup {
  choirVoicing: ChoirVoicingId;
  accompaniment: AccompanimentChoice;
  staffLayout: StaffLayoutId;
}

export const DEFAULT_SCORE_SETUP: ScoreSetup = {
  choirVoicing: "AUTO",
  accompaniment: "AUTO",
  staffLayout: "AUTO",
};

export const CHOIR_VOICING_OPTIONS: { id: ChoirVoicingId; label: string }[] = [
  { id: "AUTO", label: "Auto Detect" },
  { id: "UNISON", label: "Unison" },
  { id: "TWO_PART", label: "2-Part" },
  { id: "SA", label: "Soprano / Alto" },
  { id: "SS", label: "Soprano 1 / Soprano 2" },
  { id: "SSA", label: "SSA" },
  { id: "SSAA", label: "SSAA" },
  { id: "SAT", label: "SAT" },
  { id: "SAB", label: "SAB" },
  { id: "SATB", label: "SATB" },
  { id: "TTB", label: "TTB" },
  { id: "TTBB", label: "TTBB" },
  { id: "SSAATTBB", label: "SSAATTBB" },
  { id: "CUSTOM", label: "Custom" },
];

export const ACCOMPANIMENT_OPTIONS: { id: AccompanimentChoice; label: string }[] = [
  { id: "AUTO", label: "Auto Detect" },
  { id: "NONE", label: "A Cappella / None" },
  { id: "PIANO", label: "Piano" },
  { id: "OTHER", label: "Other" },
];

export const STAFF_LAYOUT_OPTIONS: { id: StaffLayoutId; label: string }[] = [
  { id: "AUTO", label: "Auto Detect" },
  { id: "SATB_SHARED_2", label: "SATB: 2 staves (S/A and T/B)" },
  { id: "SATB_SEPARATE_4", label: "SATB: 4 staves" },
  { id: "SSA_SHARED_2", label: "SSA: 2 staves (S1/S2 and Alto)" },
  { id: "SSA_SEPARATE_3", label: "SSA: 3 staves" },
  { id: "SSAA_SHARED_2", label: "SSAA: 2 staves (S1/S2 and A1/A2)" },
  { id: "SSAA_SEPARATE_4", label: "SSAA: 4 staves" },
  { id: "SSAATTBB_SHARED_4", label: "SSAATTBB: 4 shared staves" },
  { id: "SSAATTBB_SEPARATE_8", label: "SSAATTBB: 8 staves" },
  { id: "CUSTOM", label: "Custom" },
];

const ROLE_TEMPLATES: Partial<Record<ChoirVoicingId, CanonicalPartId[]>> = {
  UNISON: ["SOPRANO"],
  TWO_PART: ["SOPRANO", "ALTO"],
  SA: ["SOPRANO", "ALTO"],
  SS: ["SOPRANO", "SOPRANO"],
  SSA: ["SOPRANO", "SOPRANO", "ALTO"],
  SSAA: ["SOPRANO", "SOPRANO", "ALTO", "ALTO"],
  SAT: ["SOPRANO", "ALTO", "TENOR"],
  SAB: ["SOPRANO", "ALTO", "BASS"],
  SATB: ["SOPRANO", "ALTO", "TENOR", "BASS"],
  TTB: ["TENOR", "TENOR", "BASS"],
  TTBB: ["TENOR", "TENOR", "BASS", "BASS"],
  SSAATTBB: ["SOPRANO", "SOPRANO", "ALTO", "ALTO", "TENOR", "TENOR", "BASS", "BASS"],
};

const LAYOUT_STAVES: Partial<Record<StaffLayoutId, CanonicalPartId[][]>> = {
  SATB_SHARED_2: [
    ["SOPRANO", "ALTO"],
    ["TENOR", "BASS"],
  ],
  SATB_SEPARATE_4: [["SOPRANO"], ["ALTO"], ["TENOR"], ["BASS"]],
  SSA_SHARED_2: [
    ["SOPRANO", "SOPRANO"],
    ["ALTO"],
  ],
  SSA_SEPARATE_3: [["SOPRANO"], ["SOPRANO"], ["ALTO"]],
  SSAA_SHARED_2: [
    ["SOPRANO", "SOPRANO"],
    ["ALTO", "ALTO"],
  ],
  SSAA_SEPARATE_4: [["SOPRANO"], ["SOPRANO"], ["ALTO"], ["ALTO"]],
  SSAATTBB_SHARED_4: [
    ["SOPRANO", "SOPRANO"],
    ["ALTO", "ALTO"],
    ["TENOR", "TENOR"],
    ["BASS", "BASS"],
  ],
  SSAATTBB_SEPARATE_8: [
    ["SOPRANO"],
    ["SOPRANO"],
    ["ALTO"],
    ["ALTO"],
    ["TENOR"],
    ["TENOR"],
    ["BASS"],
    ["BASS"],
  ],
};

const LAYOUT_VOICING: Partial<Record<StaffLayoutId, ChoirVoicingId>> = {
  SATB_SHARED_2: "SATB",
  SATB_SEPARATE_4: "SATB",
  SSA_SHARED_2: "SSA",
  SSA_SEPARATE_3: "SSA",
  SSAA_SHARED_2: "SSAA",
  SSAA_SEPARATE_4: "SSAA",
  SSAATTBB_SHARED_4: "SSAATTBB",
  SSAATTBB_SEPARATE_8: "SSAATTBB",
};

export function rolesForVoicing(voicing: ChoirVoicingId): CanonicalPartId[] | null {
  return ROLE_TEMPLATES[voicing] ? [...ROLE_TEMPLATES[voicing]] : null;
}

export function stavesForLayout(layout: StaffLayoutId): CanonicalPartId[][] | null {
  const staves = LAYOUT_STAVES[layout];
  return staves ? staves.map((staff) => [...staff]) : null;
}

export function voicingForLayout(layout: StaffLayoutId): ChoirVoicingId | null {
  return LAYOUT_VOICING[layout] ?? null;
}

export function voicingDisplayLabel(voicing: ChoirVoicingId | string): string {
  switch (voicing) {
    case "AUTO":
      return "Unknown";
    case "UNISON":
      return "Unison";
    case "TWO_PART":
      return "2-Part";
    case "CUSTOM":
      return "Custom";
    default:
      return voicing;
  }
}

export function parseScoreSetup(input: Partial<ScoreSetup> | null | undefined): ScoreSetup {
  const voicing = CHOIR_VOICING_OPTIONS.some((option) => option.id === input?.choirVoicing)
    ? (input?.choirVoicing as ChoirVoicingId)
    : "AUTO";
  const accompaniment = ACCOMPANIMENT_OPTIONS.some((option) => option.id === input?.accompaniment)
    ? (input?.accompaniment as AccompanimentChoice)
    : "AUTO";
  const staffLayout = STAFF_LAYOUT_OPTIONS.some((option) => option.id === input?.staffLayout)
    ? (input?.staffLayout as StaffLayoutId)
    : "AUTO";
  return { choirVoicing: voicing, accompaniment, staffLayout };
}

export interface VoicingTraceEntry {
  oldValue: string;
  newValue: string;
  stage: string;
  functionName: string;
  reason: string;
  directorAction: boolean;
}

export interface KeyTraceEntry {
  oldKey: string | null;
  newKey: string;
  measure: number;
  source: string;
  confidence: number;
}

export interface ScoreSystem {
  pageNumber: number;
  systemNumber: number;
  topY: number | null;
  bottomY: number | null;
  physicalStaves: string[];
  staffGroups: string[];
  measureRange: [number, number];
}

export interface StaffGroup {
  id: string;
  kind: "MAIN_CHOIR" | "ACCOMPANIMENT" | "EXTRA";
  label: string;
  staves: string[];
}

export interface LogicalPartModel {
  id: string;
  label: string;
  canonicalPart: CanonicalPartId;
  sourcePartId: string;
  physicalStaff: number | null;
  xmlVoice: number | null;
  extraKind: ExtraPartKind | null;
  needsConfirmation: boolean;
}

export type ExtraPartKind = "SOLO" | "DESCANT" | "CUE" | "OPTIONAL" | "SMALL_GROUP" | "FEATURED";

export interface ActivityRegion {
  partId: string;
  startMeasure: number;
  endMeasure: number;
  active: boolean;
}

export interface LayoutRegion {
  id: string;
  startMeasure: number;
  endMeasure: number;
  staffToParts: { staffId: string; partIds: string[] }[];
  directorVoicing: string | null;
}

export interface DivisiRegion {
  partId: string;
  startMeasure: number;
  endMeasure: number;
  label: string;
}

export interface TimeSignatureRegion {
  startMeasure: number;
  endMeasure: number;
  timeSignature: string;
}

export interface ClefRegion {
  staffId: string;
  startMeasure: number;
  endMeasure: number;
  sign: string;
  octaveChange: number;
}

export interface TempoRegion {
  startMeasure: number;
  endMeasure: number;
  bpm: number | null;
  text: string | null;
}

export type NavigationKind =
  | "REPEAT_START"
  | "REPEAT_END"
  | "ENDING"
  | "SEGNO"
  | "CODA"
  | "DS"
  | "DC"
  | "TO_CODA"
  | "FINE";

export interface NavigationEvent {
  kind: NavigationKind;
  measureIndex: number;
  measureNumber: number;
  times?: number;
  ending?: number;
  alCoda?: boolean;
  alFine?: boolean;
  text?: string;
}

export interface NormalizedNoteEvent {
  logicalPart: string;
  physicalStaff: number | null;
  xmlVoice: number | null;
  writtenMeasureId: number;
  printedMeasureNumber: string;
  beat: number;
  offsetWithinMeasure: number;
  duration: number;
  pitch: number | null;
  rest: boolean;
  tieStart: boolean;
  tieStop: boolean;
  chord: boolean;
  sourcePage: number | null;
  sourceSystem: number | null;
}

export interface DirectorCorrection {
  id: string;
  scope: "SYSTEM" | "LAYOUT_REGION" | "REST_OF_SCORE";
  targetId: string | null;
  voicing: string | null;
  partId: string | null;
  canonicalPart: CanonicalPartId | null;
  createdAt: string;
}

export interface StructuredWarning {
  code: string;
  message: string;
  measure: number | null;
  page: number | null;
  system: number | null;
}

export interface PlaybackChannel {
  id: string;
  label: string;
  group: "CHOIR" | "FEATURED" | "ACCOMPANIMENT";
  partIds: string[];
  canonicalPart: CanonicalPartId;
  entersAtMeasure: number | null;
}

export interface PlaybackVisit {
  displayNumber: number;
  internalIndex: number;
  startBeat: number;
  endBeat: number;
  writtenStart: number;
}

export interface PlaybackEvent {
  partId: string;
  partCanonical: CanonicalPartId;
  midi: number;
  scheduleBeat: number;
  durationBeats: number;
  measureNumber: number;
  velocity: number;
  unisonGroupId: string | null;
}

export interface PlaybackModel {
  channels: PlaybackChannel[];
  route: number[];
  visits: PlaybackVisit[];
  events: PlaybackEvent[];
  eventCountByChannel: Record<string, number>;
}

export interface WrittenMeasureModel {
  id: number;
  printedNumber: string;
  displayNumber: number;
  beats: number;
  timeSignature: string;
  pickup: boolean;
}

export interface ScoreModel {
  pipelineVersion: typeof PIPELINE_VERSION;
  sourceUploadType: SourceUploadType;
  pageCount: number;
  pages: { pageNumber: number }[];
  systems: ScoreSystem[];
  scoreSetup: ScoreSetup;
  mainChoirVoicing: string;
  lockedVoicing: string | null;
  voicingLocked: boolean;
  logicalParts: LogicalPartModel[];
  extraPlayableParts: LogicalPartModel[];
  accompaniment: {
    kind: "NONE" | "PIANO" | "OTHER";
    partIds: string[];
    rightHandStaff: string | null;
    leftHandStaff: string | null;
  };
  mainChoirGroup: StaffGroup | null;
  firstMainChoirSystem: number | null;
  writtenMeasures: WrittenMeasureModel[];
  partActivityRegions: ActivityRegion[];
  layoutRegions: LayoutRegion[];
  divisiRegions: DivisiRegion[];
  keySignatureRegions: KeyRegion[];
  timeSignatureRegions: TimeSignatureRegion[];
  clefRegions: ClefRegion[];
  tempoRegions: TempoRegion[];
  navigationEvents: NavigationEvent[];
  normalizedNoteEvents: NormalizedNoteEvent[];
  directorCorrections: DirectorCorrection[];
  recognitionWarnings: StructuredWarning[];
  voicingTrace: VoicingTraceEntry[];
  keyTrace: KeyTraceEntry[];
  playback: PlaybackModel;
}

export function isCurrentPipeline(score: { scoreModel?: { pipelineVersion?: string } | null } | null | undefined) {
  return score?.scoreModel?.pipelineVersion === PIPELINE_VERSION;
}
