import path from "node:path";
import { promises as fs } from "node:fs";
import type { OMRArtifacts } from "@/lib/server/omr/provider";
import type { OMRDiagnostics, ParsedScore } from "@/lib/score-types";
import { buildOcrService } from "@/lib/server/omr";
import { analyzeImageQuality } from "@/lib/server/quality";
import { preparePageForOmr, rasterizePdfPages } from "@/lib/normalize-pages";
import { DEFAULT_SCORE_SETUP, parseScoreSetup, type ScoreSetup, type SourceUploadType } from "@/lib/score-model";
import { interpretUnifiedScore } from "@/lib/unified-pipeline";

const IMAGE_MIME_TYPES = new Set(["image/jpeg", "image/png", "image/jpg", "image/webp"]);

export interface ProcessFileRef {
  filePath: string;
  originalFileName: string;
  mimeType: string;
}

type ProcessFileInput = ProcessFileRef & {
  audiverisOutputDir: string;
  pageNumbers?: number[];
  additionalFiles?: ProcessFileRef[];
  setup?: Partial<ScoreSetup> | null;
  sourceUploadType?: SourceUploadType;
};

type ProcessFileOutput = {
  musicXml: string;
  diagnostics: OMRDiagnostics;
  provider: string;
  parsedScore: ParsedScore;
  artifacts: OMRArtifacts;
  warnings: string[];
  recognitionLog: string;
  sourceUploadType: SourceUploadType;
  pageCount: number;
};

export async function processFileToParsedScore(input: ProcessFileInput): Promise<ProcessFileOutput> {
  const files = [input, ...(input.additionalFiles ?? [])];
  for (const file of files) {
    if (!extensionFor(file.originalFileName)) {
      throw new Error("Unsupported file type. Use JPG, PNG, PDF, XML, or MusicXML.");
    }
  }

  const sourceUploadType = input.sourceUploadType ?? inferSourceUploadType(files);
  const setup = parseScoreSetup(input.setup ?? DEFAULT_SCORE_SETUP);
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
  let pageCount = 1;

  const notationFile = files.find((file) => {
    const extension = extensionFor(file.originalFileName);
    return extension === "xml" || extension === "musicxml";
  });

  if (notationFile && files.length === 1) {
    musicXml = await fs.readFile(notationFile.filePath, "utf8");
    pageCount = 1;
  } else if (notationFile) {
    throw new Error("MusicXML is its own score. Add pages only for images or PDFs.");
  } else {
    const pagePaths: string[] = [];
    for (const [index, file] of files.entries()) {
      const extension = extensionFor(file.originalFileName);
      if (extension === "pdf") {
        const rasterDir = path.join(input.audiverisOutputDir, `pages-${index}`);
        let pages = await rasterizePdfPages(file.filePath, rasterDir);
        if (files.length === 1 && input.pageNumbers?.length) {
          pages = pages.filter((_, pageIndex) => input.pageNumbers?.includes(pageIndex + 1));
          if (!pages.length) {
            throw new Error("None of the requested PDF pages could be read.");
          }
        }
        pagePaths.push(...pages);
      } else if (IMAGE_MIME_TYPES.has(file.mimeType) || extension === "jpg" || extension === "png" || extension === "webp") {
        pagePaths.push(file.filePath);
      } else {
        throw new Error("Unsupported file type. Use JPG, PNG, PDF, XML, or MusicXML.");
      }
    }
    pageCount = pagePaths.length;
    const preparedDir = path.join(input.audiverisOutputDir, "prepared-pages");
    const preparedPaths: string[] = [];
    for (let pageIndex = 0; pageIndex < pagePaths.length; pageIndex += 1) {
      preparedPaths.push(
        await preparePageForOmr(
          pagePaths[pageIndex],
          path.join(preparedDir, `page-${pageIndex + 1}.png`)
        )
      );
    }
    pagePaths.splice(0, pagePaths.length, ...preparedPaths);
    if (IMAGE_MIME_TYPES.has(files[0].mimeType) || extensionFor(files[0].originalFileName) !== "pdf") {
      try {
        diagnostics = await analyzeImageQuality(pagePaths[0]);
      } catch {
        diagnostics = blankDiagnostics();
      }
    }
    const omrService = buildOcrService();
    const result = await omrService.processScore(pagePaths, {
      outputDir: input.audiverisOutputDir,
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

  const parsedScore = interpretUnifiedScore({
    xml: musicXml,
    sourceType,
    sourceUploadType,
    pageCount,
    setup,
  });
  const modelWarnings = parsedScore.scoreModel?.recognitionWarnings.map((warning) => warning.message) ?? [];
  return {
    musicXml,
    diagnostics,
    provider,
    parsedScore,
    artifacts,
    warnings: [...warnings, ...modelWarnings],
    recognitionLog,
    sourceUploadType,
    pageCount,
  };
}

export function inferSourceUploadType(files: { originalFileName: string }[]): SourceUploadType {
  if (files.length === 1) {
    const extension = extensionFor(files[0].originalFileName);
    if (extension === "pdf") {
      return "PDF";
    }
    if (extension === "xml" || extension === "musicxml") {
      return "MUSICXML";
    }
    return "SINGLE_IMAGE";
  }
  return "MULTI_IMAGE";
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
