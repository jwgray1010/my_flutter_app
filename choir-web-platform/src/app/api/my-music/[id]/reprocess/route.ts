import path from "node:path";
import { NextResponse } from "next/server";
import {
  getSavedScoreById,
  persistSavedScore,
} from "@/lib/server/my-music-db";
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
    const processed = await processFileToParsedScore({
      filePath: existing.sourceFilePath,
      originalFileName: existing.sourceFileName,
      mimeType: existing.sourceMimeType,
    });
    const directorAssignments = Object.fromEntries(
      processed.parsedScore.parts.map((part) => [part.id, part.canonicalPart])
    );
    const titleFromSource = path.basename(existing.sourceFileName, path.extname(existing.sourceFileName));
    const resolvedTitle =
      existing.title && existing.title !== "Untitled score"
        ? existing.title
        : processed.parsedScore.title || titleFromSource;

    const record = persistSavedScore({
      id,
      title: resolvedTitle,
      sourceFileName: existing.sourceFileName,
      sourceMimeType: existing.sourceMimeType,
      sourceFilePath: existing.sourceFilePath,
      recognizedMusicXml: processed.musicXml,
      parsedScore: {
        ...processed.parsedScore,
        title: resolvedTitle,
      },
      recognitionProvider: processed.provider,
      diagnostics: processed.diagnostics,
      directorConfirmedPartAssignments: directorAssignments,
    });

    return NextResponse.json({
      message: "Score reprocessed successfully.",
      item: record,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to reprocess score.";
    return NextResponse.json({ message }, { status: 500 });
  }
}

