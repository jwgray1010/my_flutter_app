import { randomUUID } from "node:crypto";
import { promises as fs } from "node:fs";
import path from "node:path";
import { NextResponse } from "next/server";
import {
  dataStoragePaths,
  persistSavedScore,
} from "@/lib/server/my-music-db";
import {
  extensionFor,
  processFileToParsedScore,
} from "@/lib/server/score-processing";
import type { SavedScoreSummary } from "@/lib/score-types";

export const runtime = "nodejs";
export const maxDuration = 120;

export async function POST(request: Request) {
  const formData = await request.formData();
  const file = formData.get("file");
  if (!(file instanceof File)) {
    return NextResponse.json({ message: "No file uploaded." }, { status: 400 });
  }

  const extension = extensionFor(file.name);
  if (!extension) {
    return NextResponse.json(
      { message: "Unsupported file type. Use JPG, PNG, PDF, XML, or MusicXML." },
      { status: 400 }
    );
  }

  const scoreId = randomUUID();
  const { uploadsDir } = dataStoragePaths();
  const sourceFilePath = path.join(uploadsDir, `${scoreId}.${extension}`);
  const sourceMimeType = file.type || mimeFromExtension(extension);

  try {
    const bytes = Buffer.from(await file.arrayBuffer());
    await fs.mkdir(uploadsDir, { recursive: true });
    await fs.writeFile(sourceFilePath, bytes);

    const processed = await processFileToParsedScore({
      filePath: sourceFilePath,
      originalFileName: file.name,
      mimeType: sourceMimeType,
    });

    const resolvedTitle =
      processed.parsedScore.title && processed.parsedScore.title !== "Untitled score"
        ? processed.parsedScore.title
        : path.basename(file.name, path.extname(file.name));

    const directorAssignments = Object.fromEntries(
      processed.parsedScore.parts.map((part) => [part.id, part.canonicalPart])
    );

    const record = persistSavedScore({
      id: scoreId,
      title: resolvedTitle || "Untitled score",
      sourceFileName: file.name,
      sourceMimeType,
      sourceFilePath,
      recognizedMusicXml: processed.musicXml,
      parsedScore: {
        ...processed.parsedScore,
        title: resolvedTitle || processed.parsedScore.title,
      },
      recognitionProvider: processed.provider,
      diagnostics: processed.diagnostics,
      directorConfirmedPartAssignments: directorAssignments,
    });

    const summary: SavedScoreSummary = {
      id: record.id,
      title: record.title,
      importedAt: record.importedAt,
      sourceFileName: record.sourceFileName,
      partTextureLabel: record.partTextureLabel,
      measureCount: record.measureCount,
      detectedParts: record.detectedParts,
      lastUsedTempoPercent: record.lastUsedTempoPercent,
    };

    return NextResponse.json({
      message: "✓ Saved to My Music",
      savedScore: summary,
      parsedScore: record.parsedScore,
      diagnostics: processed.diagnostics,
      provider: processed.provider,
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Failed to process and save score.";
    return NextResponse.json({ message }, { status: 500 });
  }
}

function mimeFromExtension(extension: string) {
  if (extension === "pdf") {
    return "application/pdf";
  }
  if (extension === "xml" || extension === "musicxml") {
    return "application/xml";
  }
  if (extension === "png") {
    return "image/png";
  }
  return "image/jpeg";
}

