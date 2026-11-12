import { randomUUID } from "node:crypto";
import { promises as fs } from "node:fs";
import path from "node:path";
import { NextResponse } from "next/server";
import {
  dataStoragePaths,
  persistSavedScore,
} from "@/lib/server/my-music-db";
import { startRecognitionJob } from "@/lib/server/recognition-jobs";
import {
  extensionFor,
  processFileToParsedScore,
} from "@/lib/server/score-processing";
import { emptyManualCorrections } from "@/lib/score-corrections";
import { parseScoreSetup } from "@/lib/score-model";
import type { SavedScoreSummary } from "@/lib/score-types";

export const runtime = "nodejs";
export const maxDuration = 120;

function uploadNeedsOmr(extension: string) {
  return extension !== "xml" && extension !== "musicxml";
}

export async function POST(request: Request) {
  let formData: FormData;
  try {
    formData = await request.formData();
  } catch {
    return NextResponse.json(
      { message: "The upload could not be read. Try the file again." },
      { status: 400 }
    );
  }
  const files = formData
    .getAll("file")
    .filter((entry): entry is File => entry instanceof File);
  const file = files[0];
  if (!file) {
    return NextResponse.json({ message: "No file uploaded." }, { status: 400 });
  }

  const extension = extensionFor(file.name);
  if (!extension || files.some((entry) => !extensionFor(entry.name))) {
    return NextResponse.json(
      { message: "Unsupported file type. Use JPG, PNG, PDF, XML, or MusicXML." },
      { status: 400 }
    );
  }

  if (files.some((entry) => uploadNeedsOmr(extensionFor(entry.name) ?? ""))) {
    const jobId = startRecognitionJob(() => runProcess(formData));
    return NextResponse.json(
      { jobId, status: "running", message: "Recognition started." },
      { status: 202 }
    );
  }

  const result = await runProcess(formData);
  return NextResponse.json(result.body, { status: result.status });
}

async function runProcess(formData: FormData) {
  const files = formData
    .getAll("file")
    .filter((entry): entry is File => entry instanceof File);
  const file = files[0];
  if (!file) {
    return { status: 400, body: { message: "No file uploaded." } };
  }

  const extension = extensionFor(file.name);
  if (!extension || files.some((entry) => !extensionFor(entry.name))) {
    return {
      status: 400,
      body: { message: "Unsupported file type. Use JPG, PNG, PDF, XML, or MusicXML." },
    };
  }
  const setup = parseScoreSetup({
    choirVoicing: formValue(formData.get("choirVoicing")) as never,
    accompaniment: formValue(formData.get("accompaniment")) as never,
    staffLayout: formValue(formData.get("staffLayout")) as never,
  });

  const scoreId = randomUUID();
  const { uploadsDir, audiverisDir } = dataStoragePaths();
  const sourceFilePath = path.join(/* turbopackIgnore: true */ uploadsDir, `${scoreId}.${extension}`);
  const audiverisOutputDir = path.join(
    /* turbopackIgnore: true */ audiverisDir,
    scoreId
  );
  const sourceMimeType = file.type || mimeFromExtension(extension);

  try {
    const bytes = Buffer.from(await file.arrayBuffer());
    await fs.mkdir(uploadsDir, { recursive: true });
    await fs.writeFile(sourceFilePath, bytes);
    const additionalFiles = [];
    for (const [index, extra] of files.slice(1).entries()) {
      const extraExtension = extensionFor(extra.name);
      if (!extraExtension) {
        continue;
      }
      const extraPath = path.join(uploadsDir, `${scoreId}-page-${index + 2}.${extraExtension}`);
      await fs.writeFile(extraPath, Buffer.from(await extra.arrayBuffer()));
      additionalFiles.push({
        filePath: extraPath,
        originalFileName: extra.name,
        mimeType: extra.type || mimeFromExtension(extraExtension),
      });
    }

    const processed = await processFileToParsedScore({
      filePath: sourceFilePath,
      originalFileName: file.name,
      mimeType: sourceMimeType,
      audiverisOutputDir,
      additionalFiles,
      setup,
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
      sourceFiles: [
        {
          fileName: file.name,
          mimeType: sourceMimeType,
          filePath: sourceFilePath,
          pageNumber: 1,
        },
        ...additionalFiles.map((extra, index) => ({
          fileName: extra.originalFileName,
          mimeType: extra.mimeType,
          filePath: extra.filePath,
          pageNumber: index + 2,
        })),
      ],
      recognizedMusicXml: processed.musicXml,
      parsedScore: {
        ...processed.parsedScore,
        title: resolvedTitle || processed.parsedScore.title,
      },
      baseParsedScore: {
        ...processed.parsedScore,
        title: resolvedTitle || processed.parsedScore.title,
      },
      recognitionProvider: processed.provider,
      diagnostics: processed.diagnostics,
      recognitionWarnings: processed.warnings,
      recognitionLog: processed.recognitionLog,
      directorConfirmedPartAssignments: directorAssignments,
      manualCorrections: emptyManualCorrections(),
      audiverisOmrPath: processed.artifacts.audiverisOmrPath,
      audiverisMxlPath: processed.artifacts.audiverisMxlPath,
      audiverisMusicXmlPath: processed.artifacts.audiverisMusicXmlPath,
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
      recognitionWarnings: record.recognitionWarnings,
    };

    return {
      status: 200,
      body: {
        message: "✓ Saved to My Music",
        savedScore: summary,
        parsedScore: record.parsedScore,
        diagnostics: processed.diagnostics,
        provider: processed.provider,
        warnings: processed.warnings,
      },
    };
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Failed to process and save score.";
    console.error("[my-music/process] Recognition failed:", error);
    await fs.rm(sourceFilePath, { force: true }).catch(() => {});
    await fs.rm(audiverisOutputDir, { recursive: true, force: true }).catch(() => {});
    return { status: 500, body: { message } };
  }
}

function formValue(value: FormDataEntryValue | null) {
  return typeof value === "string" ? value : "AUTO";
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

