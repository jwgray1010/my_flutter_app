import { promises as fs } from "node:fs";
import path from "node:path";
import { NextResponse } from "next/server";
import {
  dataStoragePaths,
  getSavedScoreById,
  persistSavedScore,
} from "@/lib/server/my-music-db";
import { applyManualCorrections, normalizeManualCorrections } from "@/lib/score-corrections";
import {
  extensionFor,
  processFileToParsedScore,
} from "@/lib/server/score-processing";

export const runtime = "nodejs";
export const maxDuration = 120;

export async function POST(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params;
  const existing = getSavedScoreById(id);
  if (!existing) {
    return NextResponse.json({ message: "Score not found." }, { status: 404 });
  }

  const formData = await request.formData();
  const file = formData.get("file");
  if (!(file instanceof File)) {
    return NextResponse.json({ message: "No replacement file provided." }, { status: 400 });
  }

  const extension = extensionFor(file.name);
  if (!extension) {
    return NextResponse.json(
      { message: "Unsupported file type. Use JPG, PNG, PDF, XML, or MusicXML." },
      { status: 400 }
    );
  }

  const pageNumberValue = formData.get("pageNumber");
  const pageNumber = Number(pageNumberValue);
  const selectedPageNumber = Number.isFinite(pageNumber) && pageNumber > 0 ? Math.round(pageNumber) : undefined;

  const { uploadsDir, audiverisDir } = dataStoragePaths();
  const replacementPath = path.join(/* turbopackIgnore: true */ uploadsDir, `${id}.${extension}`);
  const oldSourcePath = existing.sourceFilePath;
  const replacementMimeType = file.type || existing.sourceMimeType;

  try {
    await fs.mkdir(uploadsDir, { recursive: true });
    const bytes = Buffer.from(await file.arrayBuffer());
    await fs.writeFile(replacementPath, bytes);

    const processed = await processFileToParsedScore({
      filePath: replacementPath,
      originalFileName: file.name,
      mimeType: replacementMimeType,
      audiverisOutputDir: path.join(/* turbopackIgnore: true */ audiverisDir, id),
      pageNumbers:
        selectedPageNumber && replacementMimeType.toLowerCase().includes("pdf")
          ? [selectedPageNumber]
          : undefined,
    });

    const preservedCorrections = normalizeManualCorrections(existing.manualCorrections);
    const correctedScore = applyManualCorrections(processed.parsedScore, preservedCorrections);
    const directorAssignments = Object.fromEntries(
      correctedScore.parts.map((part) => [
        part.id,
        existing.directorConfirmedPartAssignments[part.id] ?? part.canonicalPart,
      ])
    );

    const record = persistSavedScore({
      id,
      title: existing.title,
      sourceFileName: file.name,
      sourceMimeType: replacementMimeType,
      sourceFilePath: replacementPath,
      sourceFiles: [
        {
          fileName: file.name,
          mimeType: replacementMimeType,
          filePath: replacementPath,
          pageNumber: selectedPageNumber ?? null,
        },
      ],
      recognizedMusicXml: processed.musicXml,
      parsedScore: {
        ...correctedScore,
        title: existing.title,
      },
      baseParsedScore: {
        ...processed.parsedScore,
        title: existing.title,
      },
      recognitionProvider: processed.provider,
      diagnostics: processed.diagnostics,
      recognitionWarnings: processed.warnings,
      recognitionLog: processed.recognitionLog,
      directorConfirmedPartAssignments: directorAssignments,
      manualCorrections: preservedCorrections,
      audiverisOmrPath: processed.artifacts.audiverisOmrPath,
      audiverisMxlPath: processed.artifacts.audiverisMxlPath,
      audiverisMusicXmlPath: processed.artifacts.audiverisMusicXmlPath,
      lastUsedTempoPercent: existing.lastUsedTempoPercent,
    });

    if (oldSourcePath !== replacementPath) {
      await fs.rm(oldSourcePath, { force: true });
    }

    return NextResponse.json({
      message: selectedPageNumber
        ? `Page ${selectedPageNumber} replaced and reprocessed.`
        : "Pages replaced and reprocessed.",
      item: record,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to replace score pages.";
    return NextResponse.json({ message }, { status: 500 });
  }
}

