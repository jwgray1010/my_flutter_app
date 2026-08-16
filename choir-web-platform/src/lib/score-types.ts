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

