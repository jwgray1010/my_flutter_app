import { JSDOM } from "jsdom";
import path from "node:path";
import { promises as fs } from "node:fs";
import { parseMusicXmlToScore } from "@/lib/musicxml";
import type { OMRArtifacts } from "@/lib/server/omr/provider";
import type { OMRDiagnostics, ParsedScore } from "@/lib/score-types";
import { buildOcrService } from "@/lib/server/omr";
import { analyzeImageQuality } from "@/lib/server/quality";

const IMAGE_MIME_TYPES = new Set(["image/jpeg", "image/png", "image/jpg", "image/webp"]);

type ProcessFileInput = {
  filePath: string;
  originalFileName: string;
  mimeType: string;
  audiverisOutputDir: string;
  pageNumbers?: number[];
};

type ProcessFileOutput = {
  musicXml: string;
  diagnostics: OMRDiagnostics;
  provider: string;
  parsedScore: ParsedScore;
  artifacts: OMRArtifacts;
  warnings: string[];
  recognitionLog: string;
};

export async function processFileToParsedScore(
  input: ProcessFileInput
): Promise<ProcessFileOutput> {
  const extension = extensionFor(input.originalFileName);
  if (!extension) {
    throw new Error("Unsupported file type. Use JPG, PNG, PDF, XML, or MusicXML.");
  }

  let diagnostics = blankDiagnostics();
  let musicXml = "";
  let provider = "direct-musicxml";
  let sourceType: ParsedScore["sourceType"] = "musicxml";
  let artifacts: OMRArtifacts = {
    audiverisOmrPath: null,
    audiverisMxlPath: null,
    audiverisMusicXmlPath: null,
  };
  let warnings: string[] = [];
  let recognitionLog = "";

  if (extension === "xml" || extension === "musicxml") {
    musicXml = await fs.readFile(input.filePath, "utf8");
  } else {
    if (IMAGE_MIME_TYPES.has(input.mimeType)) {
      diagnostics = await analyzeImageQuality(input.filePath);
    } else if (extension === "pdf") {
      diagnostics.warnings.push("PDF processing currently reads page 1 first for the prototype.");
    }
    const omrService = buildOcrService();
    const result = await omrService.processScore([input.filePath], {
      outputDir: input.audiverisOutputDir,
      pageNumbers: input.pageNumbers,
    });
    musicXml = result.musicXml;
    warnings = result.warnings;
    diagnostics = {
      ...diagnostics,
      lowConfidence: diagnostics.lowConfidence || result.diagnostics.lowConfidence || warnings.length > 0,
      warnings: [...new Set([...diagnostics.warnings, ...result.diagnostics.warnings])],
      quality: diagnostics.quality,
    };
    provider = result.provider;
    artifacts = result.artifacts;
    recognitionLog = result.recognitionLog;
    sourceType = "omr";
  }

  const previousDomParser = globalThis.DOMParser;
  (globalThis as { DOMParser: typeof window.DOMParser }).DOMParser = new JSDOM().window.DOMParser;
  try {
    const parsedScore = parseMusicXmlToScore(musicXml, sourceType);
    return {
      musicXml,
      diagnostics,
      provider,
      parsedScore,
      artifacts,
      warnings,
      recognitionLog,
    };
  } finally {
    if (previousDomParser) {
      (globalThis as { DOMParser: typeof window.DOMParser }).DOMParser = previousDomParser;
    } else {
      delete (globalThis as { DOMParser?: typeof window.DOMParser }).DOMParser;
    }
  }
}

export function extensionFor(fileName: string) {
  const ext = path.extname(fileName).toLowerCase().replace(".", "");
  if (!ext) {
    return null;
  }
  if (["jpg", "jpeg", "png", "pdf", "xml", "musicxml", "webp"].includes(ext)) {
    return ext === "jpeg" ? "jpg" : ext;
  }
  return null;
}

export function blankDiagnostics(): OMRDiagnostics {
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

