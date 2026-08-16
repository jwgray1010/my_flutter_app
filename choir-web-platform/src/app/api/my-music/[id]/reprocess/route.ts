import path from "node:path";
import { NextResponse } from "next/server";
import {
  dataStoragePaths,
  getSavedScoreById,
  persistSavedScore,
} from "@/lib/server/my-music-db";
import { applyManualCorrections, normalizeManualCorrections } from "@/lib/score-corrections";
import { processFileToParsedScore } from "@/lib/server/score-processing";

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

  try {
    const { audiverisDir } = dataStoragePaths();
    const processed = await processFileToParsedScore({
      filePath: existing.sourceFilePath,
      originalFileName: existing.sourceFileName,
      mimeType: existing.sourceMimeType,
      audiverisOutputDir: path.join(/* turbopackIgnore: true */ audiverisDir, id),
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

    return NextResponse.json({
      message:
        "Score reprocessed. Manual corrections were preserved where possible.",
      item: record,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to reprocess score.";
    return NextResponse.json({ message }, { status: 500 });
  }
}

