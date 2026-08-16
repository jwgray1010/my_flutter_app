import fs from "node:fs";
import path from "node:path";
import Database from "better-sqlite3";
import { emptyManualCorrections, normalizeManualCorrections } from "@/lib/score-corrections";
import type {
  AssignablePartId,
  CanonicalPartId,
  ManualScoreCorrections,
  OMRDiagnostics,
  ParsedScore,
  SavedScoreRecord,
  SavedScoreSummary,
  SourceFileReference,
} from "@/lib/score-types";

type ScoreRow = {
  id: string;
  title: string;
  imported_at: string;
  updated_at: string;
  source_filename: string;
  source_mime_type: string;
  source_file_path: string;
  source_files_json: string;
  recognized_musicxml: string;
  parsed_score_json: string;
  base_parsed_score_json: string;
  detected_parts_json: string;
  confirmed_assignments_json: string;
  manual_corrections_json: string;
  measure_map_json: string;
  time_signatures_json: string;
  key_signature: string | null;
  tempo_bpm: number;
  recognition_provider: string;
  recognition_warnings_json: string;
  recognition_quality_json: string;
  recognition_log: string;
  audiveris_omr_path: string | null;
  audiveris_mxl_path: string | null;
  audiveris_musicxml_path: string | null;
  last_used_tempo_percent: number;
};

type PersistInput = {
  id: string;
  title: string;
  sourceFileName: string;
  sourceMimeType: string;
  sourceFilePath: string;
  sourceFiles?: SourceFileReference[];
  recognizedMusicXml: string;
  parsedScore: ParsedScore;
  baseParsedScore?: ParsedScore;
  recognitionProvider: string;
  diagnostics: OMRDiagnostics;
  recognitionWarnings?: string[];
  recognitionLog?: string;
  directorConfirmedPartAssignments: Record<string, AssignablePartId>;
  manualCorrections?: ManualScoreCorrections;
  audiverisOmrPath?: string | null;
  audiverisMxlPath?: string | null;
  audiverisMusicXmlPath?: string | null;
  lastUsedTempoPercent?: number;
};

type UpdateScorePayload = {
  parsedScore: ParsedScore;
  directorConfirmedPartAssignments: Record<string, AssignablePartId>;
  manualCorrections: ManualScoreCorrections;
};

const DATA_DIR = path.join(process.cwd(), "data");
const UPLOADS_DIR = path.join(DATA_DIR, "uploads");
const AUDIVERIS_DIR = path.join(DATA_DIR, "audiveris");
const DB_PATH = path.join(DATA_DIR, "my-music.sqlite");

let db: Database.Database | null = null;

function getDb() {
  if (db) {
    return db;
  }
  fs.mkdirSync(DATA_DIR, { recursive: true });
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
  fs.mkdirSync(AUDIVERIS_DIR, { recursive: true });

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
      source_files_json TEXT NOT NULL DEFAULT '[]',
      recognized_musicxml TEXT NOT NULL,
      parsed_score_json TEXT NOT NULL,
      base_parsed_score_json TEXT NOT NULL,
      detected_parts_json TEXT NOT NULL,
      confirmed_assignments_json TEXT NOT NULL,
      manual_corrections_json TEXT NOT NULL DEFAULT '{}',
      measure_map_json TEXT NOT NULL,
      time_signatures_json TEXT NOT NULL,
      key_signature TEXT,
      tempo_bpm REAL NOT NULL,
      recognition_provider TEXT NOT NULL,
      recognition_warnings_json TEXT NOT NULL,
      recognition_quality_json TEXT NOT NULL,
      recognition_log TEXT NOT NULL DEFAULT '',
      audiveris_omr_path TEXT,
      audiveris_mxl_path TEXT,
      audiveris_musicxml_path TEXT,
      last_used_tempo_percent INTEGER NOT NULL DEFAULT 100
    );
  `);

  ensureColumn(db, "saved_scores", "source_files_json", "TEXT NOT NULL DEFAULT '[]'");
  ensureColumn(db, "saved_scores", "base_parsed_score_json", "TEXT NOT NULL DEFAULT '{}'");
  ensureColumn(db, "saved_scores", "manual_corrections_json", "TEXT NOT NULL DEFAULT '{}'");
  ensureColumn(db, "saved_scores", "recognition_log", "TEXT NOT NULL DEFAULT ''");
  ensureColumn(db, "saved_scores", "audiveris_omr_path", "TEXT");
  ensureColumn(db, "saved_scores", "audiveris_mxl_path", "TEXT");
  ensureColumn(db, "saved_scores", "audiveris_musicxml_path", "TEXT");

  return db;
}

function ensureColumn(
  database: Database.Database,
  tableName: string,
  columnName: string,
  definition: string
) {
  const columns = database.prepare(`PRAGMA table_info(${tableName})`).all() as Array<{
    name: string;
  }>;
  if (!columns.some((column) => column.name === columnName)) {
    database.exec(`ALTER TABLE ${tableName} ADD COLUMN ${columnName} ${definition}`);
  }
}

export function dataStoragePaths() {
  return {
    dataDir: DATA_DIR,
    uploadsDir: UPLOADS_DIR,
    audiverisDir: AUDIVERIS_DIR,
    dbPath: DB_PATH,
  };
}

export function persistSavedScore(input: PersistInput): SavedScoreRecord {
  const database = getDb();
  const now = new Date().toISOString();
  const detectedParts = [...new Set(input.parsedScore.parts.map((part) => part.canonicalPart))];
  const timeSignatures = [...new Set(input.parsedScore.measures.map((measure) => measure.timeSignature))];
  const measureMap = input.parsedScore.measures.map((measure) => ({
    displayNumber: measure.displayNumber,
    internalIndex: measure.internalIndex,
    startBeat: measure.startBeat,
    endBeat: measure.endBeat,
    beatsInMeasure: measure.beatsInMeasure,
    timeSignature: measure.timeSignature,
  }));
  const sourceFiles =
    input.sourceFiles && input.sourceFiles.length
      ? input.sourceFiles
      : [
          {
            fileName: input.sourceFileName,
            mimeType: input.sourceMimeType,
            filePath: input.sourceFilePath,
            pageNumber: null,
          },
        ];
  const manualCorrections = normalizeManualCorrections(input.manualCorrections);
  const recognitionWarnings = input.recognitionWarnings ?? input.diagnostics.warnings;

  database
    .prepare(
      `
      INSERT INTO saved_scores (
        id, title, imported_at, updated_at, source_filename, source_mime_type, source_file_path,
        source_files_json, recognized_musicxml, parsed_score_json, base_parsed_score_json,
        detected_parts_json, confirmed_assignments_json, manual_corrections_json, measure_map_json,
        time_signatures_json, key_signature, tempo_bpm, recognition_provider,
        recognition_warnings_json, recognition_quality_json, recognition_log, audiveris_omr_path,
        audiveris_mxl_path, audiveris_musicxml_path, last_used_tempo_percent
      ) VALUES (
        @id, @title, @imported_at, @updated_at, @source_filename, @source_mime_type, @source_file_path,
        @source_files_json, @recognized_musicxml, @parsed_score_json, @base_parsed_score_json,
        @detected_parts_json, @confirmed_assignments_json, @manual_corrections_json, @measure_map_json,
        @time_signatures_json, @key_signature, @tempo_bpm, @recognition_provider,
        @recognition_warnings_json, @recognition_quality_json, @recognition_log, @audiveris_omr_path,
        @audiveris_mxl_path, @audiveris_musicxml_path, @last_used_tempo_percent
      )
      ON CONFLICT(id) DO UPDATE SET
        title = excluded.title,
        updated_at = excluded.updated_at,
        source_filename = excluded.source_filename,
        source_mime_type = excluded.source_mime_type,
        source_file_path = excluded.source_file_path,
        source_files_json = excluded.source_files_json,
        recognized_musicxml = excluded.recognized_musicxml,
        parsed_score_json = excluded.parsed_score_json,
        base_parsed_score_json = excluded.base_parsed_score_json,
        detected_parts_json = excluded.detected_parts_json,
        confirmed_assignments_json = excluded.confirmed_assignments_json,
        manual_corrections_json = excluded.manual_corrections_json,
        measure_map_json = excluded.measure_map_json,
        time_signatures_json = excluded.time_signatures_json,
        key_signature = excluded.key_signature,
        tempo_bpm = excluded.tempo_bpm,
        recognition_provider = excluded.recognition_provider,
        recognition_warnings_json = excluded.recognition_warnings_json,
        recognition_quality_json = excluded.recognition_quality_json,
        recognition_log = excluded.recognition_log,
        audiveris_omr_path = excluded.audiveris_omr_path,
        audiveris_mxl_path = excluded.audiveris_mxl_path,
        audiveris_musicxml_path = excluded.audiveris_musicxml_path,
        last_used_tempo_percent = excluded.last_used_tempo_percent
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
      source_files_json: JSON.stringify(sourceFiles),
      recognized_musicxml: input.recognizedMusicXml,
      parsed_score_json: JSON.stringify(input.parsedScore),
      base_parsed_score_json: JSON.stringify(input.baseParsedScore ?? input.parsedScore),
      detected_parts_json: JSON.stringify(detectedParts),
      confirmed_assignments_json: JSON.stringify(input.directorConfirmedPartAssignments),
      manual_corrections_json: JSON.stringify(manualCorrections),
      measure_map_json: JSON.stringify(measureMap),
      time_signatures_json: JSON.stringify(timeSignatures),
      key_signature: input.parsedScore.keySignature,
      tempo_bpm: input.parsedScore.suggestedTempoBpm,
      recognition_provider: input.recognitionProvider,
      recognition_warnings_json: JSON.stringify(recognitionWarnings),
      recognition_quality_json: JSON.stringify(input.diagnostics.quality),
      recognition_log: input.recognitionLog ?? "",
      audiveris_omr_path: input.audiverisOmrPath ?? null,
      audiveris_mxl_path: input.audiverisMxlPath ?? null,
      audiveris_musicxml_path: input.audiverisMusicXmlPath ?? null,
      last_used_tempo_percent: Math.max(
        50,
        Math.min(120, Math.round(input.lastUsedTempoPercent ?? 100))
      ),
    });

  const saved = getSavedScoreById(input.id);
  if (!saved) {
    throw new Error("Failed to persist score.");
  }
  return saved;
}

export function updateSavedScoreContent(id: string, payload: UpdateScorePayload) {
  const database = getDb();
  const detectedParts = [...new Set(payload.parsedScore.parts.map((part) => part.canonicalPart))];
  const measureMap = payload.parsedScore.measures.map((measure) => ({
    displayNumber: measure.displayNumber,
    internalIndex: measure.internalIndex,
    startBeat: measure.startBeat,
    endBeat: measure.endBeat,
    beatsInMeasure: measure.beatsInMeasure,
    timeSignature: measure.timeSignature,
  }));
  const timeSignatures = [...new Set(payload.parsedScore.measures.map((measure) => measure.timeSignature))];

  database
    .prepare(
      `
      UPDATE saved_scores
      SET parsed_score_json = ?,
          detected_parts_json = ?,
          confirmed_assignments_json = ?,
          manual_corrections_json = ?,
          measure_map_json = ?,
          time_signatures_json = ?,
          key_signature = ?,
          tempo_bpm = ?,
          updated_at = ?
      WHERE id = ?
      `
    )
    .run(
      JSON.stringify(payload.parsedScore),
      JSON.stringify(detectedParts),
      JSON.stringify(payload.directorConfirmedPartAssignments),
      JSON.stringify(payload.manualCorrections),
      JSON.stringify(measureMap),
      JSON.stringify(timeSignatures),
      payload.parsedScore.keySignature,
      payload.parsedScore.suggestedTempoBpm,
      new Date().toISOString(),
      id
    );
}

export function listSavedScores(): SavedScoreSummary[] {
  const database = getDb();
  const rows = database
    .prepare(
      `
      SELECT
        id, title, imported_at, updated_at, source_filename, source_mime_type, source_file_path,
        source_files_json, recognized_musicxml, parsed_score_json, base_parsed_score_json,
        detected_parts_json, confirmed_assignments_json, manual_corrections_json, measure_map_json,
        time_signatures_json, key_signature, tempo_bpm, recognition_provider, recognition_warnings_json,
        recognition_quality_json, recognition_log, audiveris_omr_path, audiveris_mxl_path,
        audiveris_musicxml_path, last_used_tempo_percent
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
        source_files_json, recognized_musicxml, parsed_score_json, base_parsed_score_json,
        detected_parts_json, confirmed_assignments_json, manual_corrections_json, measure_map_json,
        time_signatures_json, key_signature, tempo_bpm, recognition_provider, recognition_warnings_json,
        recognition_quality_json, recognition_log, audiveris_omr_path, audiveris_mxl_path,
        audiveris_musicxml_path, last_used_tempo_percent
      FROM saved_scores
      WHERE id = ?
      `
    )
    .get(id) as ScoreRow | undefined;

  if (!row) {
    return null;
  }

  const parsedScore = JSON.parse(row.parsed_score_json) as ParsedScore;
  const parsedBaseCandidate = safeParseJson<ParsedScore | null>(
    row.base_parsed_score_json,
    null
  );
  const baseParsedScore = looksLikeParsedScore(parsedBaseCandidate)
    ? parsedBaseCandidate
    : parsedScore;
  const detectedParts = JSON.parse(row.detected_parts_json) as CanonicalPartId[];

  return {
    id: row.id,
    title: row.title,
    importedAt: row.imported_at,
    sourceFileName: row.source_filename,
    sourceMimeType: row.source_mime_type,
    sourceFilePath: row.source_file_path,
    sourceFiles: safeParseJson<SourceFileReference[]>(
      row.source_files_json,
      [
        {
          fileName: row.source_filename,
          mimeType: row.source_mime_type,
          filePath: row.source_file_path,
          pageNumber: null,
        },
      ]
    ),
    audiverisOmrPath: row.audiveris_omr_path,
    audiverisMxlPath: row.audiveris_mxl_path,
    audiverisMusicXmlPath: row.audiveris_musicxml_path,
    partTextureLabel: buildPartTextureLabel(detectedParts),
    measureCount: parsedScore.measures.length,
    detectedParts,
    lastUsedTempoPercent: row.last_used_tempo_percent,
    parsedScore,
    baseParsedScore,
    recognizedMusicXml: row.recognized_musicxml,
    directorConfirmedPartAssignments: safeParseJson<Record<string, AssignablePartId>>(
      row.confirmed_assignments_json,
      {}
    ),
    manualCorrections: normalizeManualCorrections(
      safeParseJson<ManualScoreCorrections>(row.manual_corrections_json, emptyManualCorrections())
    ),
    recognitionWarnings: safeParseJson<string[]>(row.recognition_warnings_json, []),
    recognitionQuality: safeParseJson<OMRDiagnostics["quality"]>(row.recognition_quality_json, {
      blurScore: 1,
      contrastScore: 1,
      glareScore: 1,
      perspectiveScore: 1,
    }),
    recognitionProvider: row.recognition_provider,
    recognitionLog: row.recognition_log ?? "",
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
  assignments: Record<string, AssignablePartId>
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
  for (const source of existing.sourceFiles) {
    try {
      fs.unlinkSync(source.filePath);
    } catch {
      // Ignore missing source file.
    }
  }
  for (const artifactPath of [
    existing.audiverisOmrPath,
    existing.audiverisMxlPath,
    existing.audiverisMusicXmlPath,
  ]) {
    if (!artifactPath) {
      continue;
    }
    try {
      fs.unlinkSync(artifactPath);
    } catch {
      // Ignore missing artifact file.
    }
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
    recognitionWarnings: safeParseJson<string[]>(row.recognition_warnings_json, []),
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

function safeParseJson<T>(raw: string | null | undefined, fallback: T): T {
  if (!raw) {
    return fallback;
  }
  try {
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

function looksLikeParsedScore(value: ParsedScore | null): value is ParsedScore {
  if (!value || typeof value !== "object") {
    return false;
  }
  return Array.isArray(value.parts) && Array.isArray(value.notes) && Array.isArray(value.measures);
}

