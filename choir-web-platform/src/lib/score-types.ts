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
  /** Solo or descant line kept distinct from the choir voicing. */
  isSolo?: boolean;
  /** Featured or optional line that is playable and is not a main-choir voice. */
  extraKind?: "SOLO" | "DESCANT" | "CUE" | "OPTIONAL" | "SMALL_GROUP" | "FEATURED" | null;
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
  xmlVoice?: number | null;
  physicalStaff?: number | null;
  tieStart?: boolean;
  tieStop?: boolean;
  chord?: boolean;
  /** Shared unison: one sounding event may be referenced by more than one logical part. */
  unisonGroupId?: string | null;
}

export interface KeyRegion {
  startMeasure: number;
  fifths: number;
  mode: "major" | "minor";
  label: string;
}

export interface MeasureInfo {
  displayNumber: number;
  /** Raw MusicXML measure number, including suffixes such as "4a". */
  displayLabel?: string;
  internalIndex: number;
  startBeat: number;
  endBeat: number;
  beatsInMeasure: number;
  timeSignature: string;
}

export interface ParsedScore {
  title: string;
  sourceType: "musicxml" | "omr";
  parts: RecognizedPart[];
  notes: NoteEvent[];
  measures: MeasureInfo[];
  suggestedTempoBpm: number;
  keySignature: string | null;
  /** Every written key signature, in order. The first matches keySignature. */
  keyRegions?: KeyRegion[];
  /** Structural choir label such as SSA, TTBB, or SA + Solo. */
  inferredVoicing?: string;
  /**
   * Written measure numbers in performance order.
   * Repeats are listed here and are not copied into measures.
   */
  performanceRoute?: number[];
  rehearsalMarks: Record<string, number>;
  rawMusicXml: string;
  /** Authoritative structure for scores processed by the unified pipeline. */
  scoreModel?: import("@/lib/score-model").ScoreModel;
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

