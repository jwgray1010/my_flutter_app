import path from "node:path";
import { NextResponse } from "next/server";
import {
  dataStoragePaths,
  getSavedScoreById,
  persistSavedScore,
} from "@/lib/server/my-music-db";
import { startRecognitionJob } from "@/lib/server/recognition-jobs";
import { applyManualCorrections, normalizeManualCorrections } from "@/lib/score-corrections";
import { extensionFor, processFileToParsedScore } from "@/lib/server/score-processing";

export const runtime = "nodejs";
export const maxDuration = 120;

export async function POST(
  _request: Request,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params;
  const existing = getSavedScoreById(id);
  if (!existing) {
    return NextResponse.json({ message: "Score not found." }, { status: 404 });
  }

  const extension = extensionFor(existing.sourceFileName);
  const needsOmr = extension != null && extension !== "xml" && extension !== "musicxml";
  if (needsOmr) {
    const jobId = startRecognitionJob(() => reprocessScore(id));
    return NextResponse.json(
      { jobId, status: "running", message: "Recognition started." },
      { status: 202 }
    );
  }

  const result = await reprocessScore(id);
  return NextResponse.json(result.body, { status: result.status });
}

async function reprocessScore(id: string) {
  const existing = getSavedScoreById(id);
  if (!existing) {
    return { status: 404, body: { message: "Score not found." } };
  }

  try {
    const { audiverisDir } = dataStoragePaths();
    const processed = await processFileToParsedScore({
      filePath: existing.sourceFilePath,
      originalFileName: existing.sourceFileName,
      mimeType: existing.sourceMimeType,
      audiverisOutputDir: path.join(/* turbopackIgnore: true */ audiverisDir, id),
      additionalFiles: existing.sourceFiles.slice(1).map((file) => ({
        filePath: file.filePath,
        originalFileName: file.fileName,
        mimeType: file.mimeType,
      })),
      setup: existing.parsedScore.scoreModel?.scoreSetup,
      sourceUploadType: existing.parsedScore.scoreModel?.sourceUploadType,
    });
    const preservedCorrections = normalizeManualCorrections(existing.manualCorrections);
    const correctedScore = applyManualCorrections(processed.parsedScore, preservedCorrections);
    const directorAssignments = Object.fromEntries(
      correctedScore.parts.map((part) => [
        part.id,
        existing.directorConfirmedPartAssignments[part.id] ?? part.canonicalPart,
      ])
    );
    const titleFromSource = path.basename(existing.sourceFileName, path.extname(existing.sourceFileName));
    const resolvedTitle =
      existing.title && existing.title !== "Untitled score"
        ? existing.title
        : correctedScore.title || titleFromSource;

    const record = persistSavedScore({
      id,
      title: resolvedTitle,
      sourceFileName: existing.sourceFileName,
      sourceMimeType: existing.sourceMimeType,
      sourceFilePath: existing.sourceFilePath,
      sourceFiles: existing.sourceFiles,
      recognizedMusicXml: processed.musicXml,
      parsedScore: {
        ...correctedScore,
        title: resolvedTitle,
      },
      baseParsedScore: {
        ...processed.parsedScore,
        title: resolvedTitle,
      },
      recognitionProvider: processed.provider,
      diagnostics: processed.diagnostics,
      recognitionWarnings: [
        ...processed.warnings,
        "Reprocessing may replace recognition results. Manual corrections were preserved where possible.",
      ],
      recognitionLog: processed.recognitionLog,
      directorConfirmedPartAssignments: directorAssignments,
      manualCorrections: preservedCorrections,
      audiverisOmrPath: processed.artifacts.audiverisOmrPath,
      audiverisMxlPath: processed.artifacts.audiverisMxlPath,
      audiverisMusicXmlPath: processed.artifacts.audiverisMusicXmlPath,
      lastUsedTempoPercent: existing.lastUsedTempoPercent,
    });

    return {
      status: 200,
      body: {
        message: "Score reprocessed. Manual corrections were preserved where possible.",
        item: record,
      },
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to reprocess score.";
    console.error("[my-music/reprocess] Recognition failed:", error);
    return { status: 500, body: { message } };
  }
}

