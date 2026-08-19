import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";
import { NextResponse } from "next/server";
import { dataStoragePaths } from "@/lib/server/my-music-db";
import { extensionFor, processFileToParsedScore } from "@/lib/server/score-processing";

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
      {
        message: "Unsupported file type. Use JPG, PNG, PDF, XML, or MusicXML.",
      },
      { status: 400 }
    );
  }

  const tempFilePath = path.join(
    os.tmpdir(),
    `choir-upload-${Date.now()}-${Math.random().toString(36).slice(2)}.${extension}`
  );
  const { audiverisDir } = dataStoragePaths();
  const transientOutputDir = path.join(
    /* turbopackIgnore: true */ audiverisDir,
    `transient-${Date.now()}-${Math.random().toString(36).slice(2)}`
  );

  try {
    const bytes = Buffer.from(await file.arrayBuffer());
    await fs.writeFile(tempFilePath, bytes);

    const result = await processFileToParsedScore({
      filePath: tempFilePath,
      mimeType: file.type,
      originalFileName: file.name,
      audiverisOutputDir: transientOutputDir,
    });

    return NextResponse.json({
      musicXml: result.musicXml,
      diagnostics: result.diagnostics,
      provider: result.provider,
      parsedScore: result.parsedScore,
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unknown recognition failure occurred.";
    console.error("[score/recognize] Recognition failed:", error);
    return NextResponse.json(
      {
        message: `OMR failed: ${message}`,
      },
      { status: 500 }
    );
  } finally {
    await fs.rm(tempFilePath, { force: true });
    await fs.rm(transientOutputDir, { recursive: true, force: true });
  }
}

