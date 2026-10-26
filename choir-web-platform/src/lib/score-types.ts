export type CanonicalPartId =
  | "SOPRANO"
  | "ALTO"
  | "TENOR"
  | "BASS"
  | "PIANO"
  | "UNKNOWN";

export type AssignablePartId = CanonicalPartId | "IGNORE";

export interface RecognizedPart {
  id: string;
  sourceName: string;
  canonicalPart: CanonicalPartId;
  staves: number;
  /** The underlying MusicXML <part> id this voice was extracted from. */
  sourcePartId: string;
  /** The MusicXML <voice> number this entry represents, when the source
   * part was split because it contains multiple independent voices
   * sharing one staff (e.g. Soprano+Alto on one staff). Null when the
   * whole part is a single voice (the common case). */
  voiceNumber: number | null;
  /** True when the canonical assignment came from a pitch-based guess
   * rather than an explicit name/label, so the director should confirm it. */
  needsConfirmation: boolean;
  /** Lowest/highest MIDI pitch actually sung/played by this voice, and the
   * display measure range it appears in - shown to help a director
   * identify which detected voice is which choir part. */
  pitchRangeLow: number | null;
  pitchRangeHigh: number | null;
  firstMeasureNumber: number | null;
  lastMeasureNumber: number | null;
}

export interface NoteEvent {
  partId: string;
  partCanonical: CanonicalPartId;
  midi: number;
  startBeat: number;
  durationBeats: number;
  measureNumber: number;
  velocity: number;
}

export interface MeasureInfo {
  displayNumber: number;
  internalIndex: number;
  startBeat: number;
  endBeat: number;
  beatsInMeasure: number;
  timeSignature: string;
}

export const UNIFIED_SCORE_PIPELINE_VERSION = "UNIFIED_SCORE_PIPELINE_V1";

export type SourceUploadType = "PDF" | "IMAGE" | "MULTI_IMAGE" | "MUSICXML" | "UNKNOWN";

export interface WrittenMeasure {
  id: string;
  displayNumber: number;
  internalIndex: number;
  timeSignature: string;
  beatsInMeasure: number;
  isPickup: boolean;
  keySignature: string | null;
}

export interface KeySignatureRegion {
  startMeasure: number;
  endMeasure: number;
  keySignature: string;
  fifths: number;
  source: "musicxml-key";
}

export interface KeyChangeTrace {
  measureNumber: number;
  oldKey: string | null;
  newKey: string;
  source: "musicxml-key";
  confidence: "confirmed" | "rejected";
  reason: string;
}

export interface TimeSignatureRegion {
  startMeasure: number;
  endMeasure: number;
  timeSignature: string;
}

export interface ClefRegion {
  partId: string;
  staff: number;
  startMeasure: number;
  endMeasure: number;
  sign: string;
  line: number | null;
}

export type NavigationKind =
  | "REPEAT_START"
  | "REPEAT_END"
  | "ENDING"
  | "SEGNO"
  | "CODA"
  | "TO_CODA"
  | "DA_CAPO"
  | "DAL_SEGNO"
  | "FINE";

export interface NavigationEvent {
  kind: NavigationKind;
  measureNumber: number;
  internalIndex: number;
  endingNumbers: number[] | null;
  text: string | null;
}

export interface PlaybackRouteStep {
  writtenMeasureId: string;
  displayNumber: number;
  internalIndex: number;
  visit: number;
  performanceStartBeat: number;
  performanceEndBeat: number;
}

export interface PartActivityRegion {
  partId: string;
  label: string;
  canonicalPart: CanonicalPartId;
  firstActiveMeasure: number | null;
  lastActiveMeasure: number | null;
}

export interface ScoreStructure {
  pipelineVersion: typeof UNIFIED_SCORE_PIPELINE_VERSION;
  sourceUploadType: SourceUploadType;
  writtenMeasures: WrittenMeasure[];
  keySignatureRegions: KeySignatureRegion[];
  keyChangeTrace: KeyChangeTrace[];
  timeSignatureRegions: TimeSignatureRegion[];
  clefRegions: ClefRegion[];
  navigationEvents: NavigationEvent[];
  playbackRoute: PlaybackRouteStep[];
  partActivityRegions: PartActivityRegion[];
  recognitionWarnings: string[];
}

export interface ParsedScore {
  title: string;
  sourceType: "musicxml" | "omr";
  parts: RecognizedPart[];
  notes: NoteEvent[];
  measures: MeasureInfo[];
  suggestedTempoBpm: number;
  keySignature: string | null;
  rehearsalMarks: Record<string, number>;
  rawMusicXml: string;
  /** Structural reading of the printed score. Playback must follow this route
   * instead of inventing repeat copies. Absent on scores saved before the
   * unified pipeline. */
  structure?: ScoreStructure;
}

export interface OMRDiagnostics {
  lowConfidence: boolean;
  warnings: string[];
  quality: {
    blurScore: number;
    contrastScore: number;
    glareScore: number;
    perspectiveScore: number;
  };
}

export interface SourceFileReference {
  fileName: string;
  mimeType: string;
  filePath: string;
  pageNumber?: number | null;
}

export interface MeasurePartEditEvent {
  id: string;
  kind: "NOTE" | "REST";
  midi: number | null;
  durationBeats: number;
}

export interface MeasureBoundaryFlag {
  measureInternalIndex: number;
  measureDisplayNumber: number;
  note: string;
  createdAt: string;
}

export interface MeasureNumberAnchorCorrection {
  internalIndex: number;
  displayNumber: number;
}

export interface MeasurePartEditCorrection {
  partId: string;
  measureInternalIndex: number;
  events: MeasurePartEditEvent[];
  updatedAt: string;
}

export interface ManualScoreCorrections {
  partAssignments: Record<string, AssignablePartId>;
  measureNumberAnchor: MeasureNumberAnchorCorrection | null;
  boundaryFlags: MeasureBoundaryFlag[];
  measurePartEdits: MeasurePartEditCorrection[];
}

export interface SavedScoreSummary {
  id: string;
  title: string;
  importedAt: string;
  sourceFileName: string;
  partTextureLabel: string;
  measureCount: number;
  detectedParts: CanonicalPartId[];
  lastUsedTempoPercent: number;
  recognitionWarnings: string[];
}

export interface SavedScoreRecord extends SavedScoreSummary {
  sourceFilePath: string;
  sourceMimeType: string;
  sourceFiles: SourceFileReference[];
  audiverisOmrPath: string | null;
  audiverisMxlPath: string | null;
  audiverisMusicXmlPath: string | null;
  parsedScore: ParsedScore;
  baseParsedScore: ParsedScore;
  recognizedMusicXml: string;
  directorConfirmedPartAssignments: Record<string, AssignablePartId>;
  manualCorrections: ManualScoreCorrections;
  recognitionWarnings: string[];
  recognitionQuality: OMRDiagnostics["quality"];
  recognitionProvider: string;
  recognitionLog: string;
}

