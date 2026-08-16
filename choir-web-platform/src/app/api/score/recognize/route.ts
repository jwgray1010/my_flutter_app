import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";
import { NextResponse } from "next/server";
import { buildOcrProvider } from "@/lib/server/omr";
import { analyzeImageQuality } from "@/lib/server/quality";
import type { OMRDiagnostics } from "@/lib/score-types";

export const runtime = "nodejs";
export const maxDuration = 120;

const IMAGE_MIME_TYPES = new Set(["image/jpeg", "image/png", "image/jpg", "image/webp"]);

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

  try {
    const bytes = Buffer.from(await file.arrayBuffer());
    await fs.writeFile(tempFilePath, bytes);

    if (extension === "xml" || extension === "musicxml") {
      const musicXml = await fs.readFile(tempFilePath, "utf8");
      const diagnostics = blankDiagnostics();
      return NextResponse.json({ musicXml, diagnostics, provider: "direct-musicxml" });
    }

    let diagnostics: OMRDiagnostics = blankDiagnostics();
    if (IMAGE_MIME_TYPES.has(file.type)) {
      diagnostics = await analyzeImageQuality(tempFilePath);
    } else if (extension === "pdf") {
      diagnostics.warnings.push(
        "PDF processing currently reads page 1 first for the prototype."
      );
    }

    const provider = buildOcrProvider();
    const result = await provider.recognize(
      {
        filePath: tempFilePath,
        mimeType: file.type,
        originalFileName: file.name,
      },
      diagnostics
    );

    return NextResponse.json({
      musicXml: result.musicXml,
      diagnostics: result.diagnostics,
      provider: result.provider,
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unknown recognition failure occurred.";
    return NextResponse.json(
      {
        message: `OMR failed: ${message}`,
      },
      { status: 500 }
    );
  } finally {
    await fs.rm(tempFilePath, { force: true });
  }
}

function extensionFor(fileName: string) {
  const ext = path.extname(fileName).toLowerCase().replace(".", "");
  if (!ext) {
    return null;
  }
  if (["jpg", "jpeg", "png", "pdf", "xml", "musicxml", "webp"].includes(ext)) {
    return ext === "jpeg" ? "jpg" : ext;
  }
  return null;
}

function blankDiagnostics(): OMRDiagnostics {
  return {
    lowConfidence: false,
    warnings: [],
    quality: {
      blurScore: 1,
      contrastScore: 1,
      glareScore: 1,
      perspectiveScore: 1,
    },
  };
}

