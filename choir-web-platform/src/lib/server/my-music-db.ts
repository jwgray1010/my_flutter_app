import fs from "node:fs";
import path from "node:path";
import Database from "better-sqlite3";
import type {
  CanonicalPartId,
  OMRDiagnostics,
  ParsedScore,
  SavedScoreRecord,
  SavedScoreSummary,
} from "@/lib/score-types";

type ScoreRow = {
  id: string;
  title: string;
  imported_at: string;
  updated_at: string;
  source_filename: string;
  source_mime_type: string;
  source_file_path: string;
  recognized_musicxml: string;
  parsed_score_json: string;
  detected_parts_json: string;
  confirmed_assignments_json: string;
  measure_map_json: string;
  time_signatures_json: string;
  key_signature: string | null;
  tempo_bpm: number;
  recognition_provider: string;
  recognition_warnings_json: string;
  recognition_quality_json: string;
  last_used_tempo_percent: number;
};

type PersistInput = {
  id: string;
  title: string;
  sourceFileName: string;
  sourceMimeType: string;
  sourceFilePath: string;
  recognizedMusicXml: string;
  parsedScore: ParsedScore;
  recognitionProvider: string;
  diagnostics: OMRDiagnostics;
  directorConfirmedPartAssignments: Record<string, CanonicalPartId>;
};

const DATA_DIR = path.join(process.cwd(), "data");
const UPLOADS_DIR = path.join(DATA_DIR, "uploads");
const DB_PATH = path.join(DATA_DIR, "my-music.sqlite");

let db: Database.Database | null = null;

function getDb() {
  if (db) {
    return db;
  }
  fs.mkdirSync(DATA_DIR, { recursive: true });
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
  db = new Database(DB_PATH);
  db.pragma("journal_mode = WAL");
  db.exec(`
    CREATE TABLE IF NOT EXISTS saved_scores (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      imported_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      source_filename TEXT NOT NULL,
      source_mime_type TEXT NOT NULL,
      source_file_path TEXT NOT NULL,
      recognized_musicxml TEXT NOT NULL,
      parsed_score_json TEXT NOT NULL,
      detected_parts_json TEXT NOT NULL,
      confirmed_assignments_json TEXT NOT NULL,
      measure_map_json TEXT NOT NULL,
      time_signatures_json TEXT NOT NULL,
      key_signature TEXT,
      tempo_bpm REAL NOT NULL,
      recognition_provider TEXT NOT NULL,
      recognition_warnings_json TEXT NOT NULL,
      recognition_quality_json TEXT NOT NULL,
      last_used_tempo_percent INTEGER NOT NULL DEFAULT 100
    );
  `);
  return db;
}

export function dataStoragePaths() {
  return {
    dataDir: DATA_DIR,
    uploadsDir: UPLOADS_DIR,
    dbPath: DB_PATH,
  };
}

export function persistSavedScore(input: PersistInput): SavedScoreRecord {
  const database = getDb();
  const now = new Date().toISOString();
  const detectedParts = [...new Set(input.parsedScore.parts.map((part) => part.canonicalPart))];
  const textureLabel = buildPartTextureLabel(detectedParts);
  const timeSignatures = [...new Set(input.parsedScore.measures.map((measure) => measure.timeSignature))];
  const measureMap = input.parsedScore.measures.map((measure) => ({
    displayNumber: measure.displayNumber,
    internalIndex: measure.internalIndex,
    startBeat: measure.startBeat,
    endBeat: measure.endBeat,
    beatsInMeasure: measure.beatsInMeasure,
    timeSignature: measure.timeSignature,
  }));

  database
    .prepare(
      `
      INSERT INTO saved_scores (
        id, title, imported_at, updated_at, source_filename, source_mime_type, source_file_path,
        recognized_musicxml, parsed_score_json, detected_parts_json, confirmed_assignments_json,
        measure_map_json, time_signatures_json, key_signature, tempo_bpm, recognition_provider,
        recognition_warnings_json, recognition_quality_json, last_used_tempo_percent
      ) VALUES (
        @id, @title, @imported_at, @updated_at, @source_filename, @source_mime_type, @source_file_path,
        @recognized_musicxml, @parsed_score_json, @detected_parts_json, @confirmed_assignments_json,
        @measure_map_json, @time_signatures_json, @key_signature, @tempo_bpm, @recognition_provider,
        @recognition_warnings_json, @recognition_quality_json, @last_used_tempo_percent
      )
      ON CONFLICT(id) DO UPDATE SET
        title = excluded.title,
        updated_at = excluded.updated_at,
        source_filename = excluded.source_filename,
        source_mime_type = excluded.source_mime_type,
        source_file_path = excluded.source_file_path,
        recognized_musicxml = excluded.recognized_musicxml,
        parsed_score_json = excluded.parsed_score_json,
        detected_parts_json = excluded.detected_parts_json,
        confirmed_assignments_json = excluded.confirmed_assignments_json,
        measure_map_json = excluded.measure_map_json,
        time_signatures_json = excluded.time_signatures_json,
        key_signature = excluded.key_signature,
        tempo_bpm = excluded.tempo_bpm,
        recognition_provider = excluded.recognition_provider,
        recognition_warnings_json = excluded.recognition_warnings_json,
        recognition_quality_json = excluded.recognition_quality_json
      `
    )
    .run({
      id: input.id,
      title: input.title,
      imported_at: now,
      updated_at: now,
      source_filename: input.sourceFileName,
      source_mime_type: input.sourceMimeType,
      source_file_path: input.sourceFilePath,
      recognized_musicxml: input.recognizedMusicXml,
      parsed_score_json: JSON.stringify(input.parsedScore),
      detected_parts_json: JSON.stringify(detectedParts),
      confirmed_assignments_json: JSON.stringify(input.directorConfirmedPartAssignments),
      measure_map_json: JSON.stringify(measureMap),
      time_signatures_json: JSON.stringify(timeSignatures),
      key_signature: input.parsedScore.keySignature,
      tempo_bpm: input.parsedScore.suggestedTempoBpm,
      recognition_provider: input.recognitionProvider,
      recognition_warnings_json: JSON.stringify(input.diagnostics.warnings),
      recognition_quality_json: JSON.stringify(input.diagnostics.quality),
      last_used_tempo_percent: 100,
    });

  const saved = getSavedScoreById(input.id);
  if (!saved) {
    throw new Error("Failed to persist score.");
  }
  const withTexture = {
    ...saved,
    partTextureLabel: textureLabel,
  };
  return withTexture;
}

export function listSavedScores(): SavedScoreSummary[] {
  const database = getDb();
  const rows = database
    .prepare(
      `
      SELECT
        id, title, imported_at, updated_at, source_filename, source_mime_type, source_file_path,
        recognized_musicxml, parsed_score_json, detected_parts_json, confirmed_assignments_json,
        measure_map_json, time_signatures_json, key_signature, tempo_bpm, recognition_provider,
        recognition_warnings_json, recognition_quality_json, last_used_tempo_percent
      FROM saved_scores
      ORDER BY datetime(imported_at) DESC
      `
    )
    .all() as ScoreRow[];
  return rows.map((row) => toSummary(row));
}

export function getSavedScoreById(id: string): SavedScoreRecord | null {
  const database = getDb();
  const row = database
    .prepare(
      `
      SELECT
        id, title, imported_at, updated_at, source_filename, source_mime_type, source_file_path,
        recognized_musicxml, parsed_score_json, detected_parts_json, confirmed_assignments_json,
        measure_map_json, time_signatures_json, key_signature, tempo_bpm, recognition_provider,
        recognition_warnings_json, recognition_quality_json, last_used_tempo_percent
      FROM saved_scores
      WHERE id = ?
      `
    )
    .get(id) as ScoreRow | undefined;

  if (!row) {
    return null;
  }

  const parsedScore = JSON.parse(row.parsed_score_json) as ParsedScore;
  const detectedParts = JSON.parse(row.detected_parts_json) as CanonicalPartId[];

  return {
    id: row.id,
    title: row.title,
    importedAt: row.imported_at,
    sourceFileName: row.source_filename,
    sourceMimeType: row.source_mime_type,
    sourceFilePath: row.source_file_path,
    partTextureLabel: buildPartTextureLabel(detectedParts),
    measureCount: parsedScore.measures.length,
    detectedParts,
    lastUsedTempoPercent: row.last_used_tempo_percent,
    parsedScore,
    recognizedMusicXml: row.recognized_musicxml,
    directorConfirmedPartAssignments: JSON.parse(
      row.confirmed_assignments_json
    ) as Record<string, CanonicalPartId>,
    recognitionWarnings: JSON.parse(row.recognition_warnings_json) as string[],
    recognitionQuality: JSON.parse(row.recognition_quality_json) as OMRDiagnostics["quality"],
    recognitionProvider: row.recognition_provider,
  };
}

export function renameSavedScore(id: string, title: string) {
  const database = getDb();
  database
    .prepare(
      `
      UPDATE saved_scores
      SET title = ?, updated_at = ?
      WHERE id = ?
      `
    )
    .run(title, new Date().toISOString(), id);
}

export function updateLastTempoPercent(id: string, tempoPercent: number) {
  const database = getDb();
  database
    .prepare(
      `
      UPDATE saved_scores
      SET last_used_tempo_percent = ?, updated_at = ?
      WHERE id = ?
      `
    )
    .run(Math.max(50, Math.min(120, Math.round(tempoPercent))), new Date().toISOString(), id);
}

export function updateDirectorPartAssignments(
  id: string,
  assignments: Record<string, CanonicalPartId>
) {
  const database = getDb();
  database
    .prepare(
      `
      UPDATE saved_scores
      SET confirmed_assignments_json = ?, updated_at = ?
      WHERE id = ?
      `
    )
    .run(JSON.stringify(assignments), new Date().toISOString(), id);
}

export function deleteSavedScore(id: string) {
  const existing = getSavedScoreById(id);
  if (!existing) {
    return;
  }
  const database = getDb();
  database.prepare("DELETE FROM saved_scores WHERE id = ?").run(id);
  try {
    fs.unlinkSync(existing.sourceFilePath);
  } catch {
    // Ignore missing file errors.
  }
}

function toSummary(row: ScoreRow): SavedScoreSummary {
  const parsedScore = JSON.parse(row.parsed_score_json) as ParsedScore;
  const detectedParts = JSON.parse(row.detected_parts_json) as CanonicalPartId[];
  return {
    id: row.id,
    title: row.title,
    importedAt: row.imported_at,
    sourceFileName: row.source_filename,
    partTextureLabel: buildPartTextureLabel(detectedParts),
    measureCount: parsedScore.measures.length,
    detectedParts,
    lastUsedTempoPercent: row.last_used_tempo_percent,
  };
}

function buildPartTextureLabel(parts: CanonicalPartId[]) {
  const set = new Set(parts);
  const hasSATB =
    set.has("SOPRANO") && set.has("ALTO") && set.has("TENOR") && set.has("BASS");
  const hasPiano = set.has("PIANO");
  if (hasSATB && hasPiano) {
    return "SATB + Piano";
  }
  if (hasSATB) {
    return "SATB";
  }
  if (hasPiano) {
    return "Piano";
  }
  const filtered = parts.filter((part) => part !== "UNKNOWN");
  return filtered.length ? filtered.join(" + ") : "Unknown";
}

