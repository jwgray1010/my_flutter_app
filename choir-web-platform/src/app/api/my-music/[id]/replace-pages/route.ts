import { promises as fs } from "node:fs";
import path from "node:path";
import { NextResponse } from "next/server";
import {
  dataStoragePaths,
  getSavedScoreById,
  persistSavedScore,
} from "@/lib/server/my-music-db";
import { applyManualCorrections, normalizeManualCorrections } from "@/lib/score-corrections";
import { startRecognitionJob } from "@/lib/server/recognition-jobs";
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

  let formData: FormData;
  try {
    formData = await request.formData();
  } catch {
    return NextResponse.json(
      { message: "The upload could not be read. Try the file again." },
      { status: 400 }
    );
  }
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

  const needsOmr = extension !== "xml" && extension !== "musicxml";
  if (needsOmr) {
    const jobId = startRecognitionJob(() => replacePages(id, formData));
    return NextResponse.json(
      { jobId, status: "running", message: "Recognition started." },
      { status: 202 }
    );
  }

  const result = await replacePages(id, formData);
  return NextResponse.json(result.body, { status: result.status });
}

async function replacePages(id: string, formData: FormData) {
  const existing = getSavedScoreById(id);
  if (!existing) {
    return { status: 404, body: { message: "Score not found." } };
  }

  const file = formData.get("file");
  if (!(file instanceof File)) {
    return { status: 400, body: { message: "No replacement file provided." } };
  }

  const extension = extensionFor(file.name);
  if (!extension) {
    return {
      status: 400,
      body: { message: "Unsupported file type. Use JPG, PNG, PDF, XML, or MusicXML." },
    };
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
      setup: existing.parsedScore.scoreModel?.scoreSetup,
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

    return {
      status: 200,
      body: {
        message: selectedPageNumber
          ? `Page ${selectedPageNumber} replaced and reprocessed.`
          : "Pages replaced and reprocessed.",
        item: record,
      },
    };
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to replace score pages.";
    console.error("[my-music/replace-pages] Recognition failed:", error);
    if (replacementPath !== oldSourcePath) {
      await fs.rm(replacementPath, { force: true }).catch(() => {});
    }
    return { status: 500, body: { message } };
  }
}

