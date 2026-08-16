export type CanonicalPartId =
  | "SOPRANO"
  | "ALTO"
  | "TENOR"
  | "BASS"
  | "PIANO"
  | "UNKNOWN";

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

