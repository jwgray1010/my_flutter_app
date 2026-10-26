import { execFile } from "node:child_process";
import { promises as fs } from "node:fs";
import path from "node:path";
import { promisify } from "node:util";
import { XMLBuilder, XMLParser } from "fast-xml-parser";
import JSZip from "jszip";
import { PDFDocument } from "pdf-lib";
import type { OMRResult, OMRService, OMRProcessOptions } from "@/lib/server/omr/provider";

const execFileAsync = promisify(execFile);

type AudiverisExecOutput = {
  stdout: string;
  stderr: string;
};

type AudiverisExtractedOutput = {
  musicXml: string;
  artifacts: OMRResult["artifacts"];
};

type RecoveredSheetResult = {
  sheetNumber: number;
  musicXml: string;
  runLog: string;
};

/**
 * Resolves the Audiveris executable path.
 *
 * AUDIVERIS_PATH is the preferred/documented environment variable for
 * production (e.g. Railway) so the deployment configuration and the
 * application code agree on a single source of truth instead of a path
 * being hard-coded in one place and installed somewhere else.
 * AUDIVERIS_BIN is kept as a backward-compatible alias. When neither is
 * set, /opt/audiveris/bin/Audiveris is used, matching both local
 * development (see README) and the production Dockerfile.
 */
export function resolveAudiverisBinPath(): string {
  return (
    process.env.AUDIVERIS_PATH ??
    process.env.AUDIVERIS_BIN ??
    "/opt/audiveris/bin/Audiveris"
  );
}

const AUDIVERIS_BIN = resolveAudiverisBinPath();

function parsePositiveInt(value: string | undefined): number | null {
  if (!value) {
    return null;
  }
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return null;
  }
  return Math.floor(parsed);
}

function isPdfInput(options: OMRProcessOptions, inputFiles: string[]): boolean {
  if (options.sourceExtension?.toLowerCase() === "pdf") {
    return true;
  }
  return inputFiles.some((file) => file.toLowerCase().endsWith(".pdf"));
}

/**
 * Optional execution timeout for Audiveris.
 *
 * By default, we keep Node's execFile timeout UNSET (no artificial kill)
 * and rely on explicit env vars when operators need a cap:
 * - AUDIVERIS_TIMEOUT_MS: applies to all inputs
 * - AUDIVERIS_PDF_TIMEOUT_MS: overrides for PDFs
 * - AUDIVERIS_LARGE_PDF_TIMEOUT_MS: minimum cap for large PDFs
 * - AUDIVERIS_LARGE_PDF_BYTES: threshold for "large" PDFs (default 8MB)
 */
export function resolveAudiverisTimeoutMs(
  options: OMRProcessOptions,
  inputFiles: string[]
): number | undefined {
  const generalTimeoutMs = parsePositiveInt(process.env.AUDIVERIS_TIMEOUT_MS);
  const pdfTimeoutMs = parsePositiveInt(process.env.AUDIVERIS_PDF_TIMEOUT_MS);
  const largePdfTimeoutMs = parsePositiveInt(process.env.AUDIVERIS_LARGE_PDF_TIMEOUT_MS);
  const largePdfBytes = parsePositiveInt(process.env.AUDIVERIS_LARGE_PDF_BYTES) ?? 8 * 1024 * 1024;
  const explicitTimeout = options.timeoutMs && options.timeoutMs > 0 ? Math.floor(options.timeoutMs) : null;
  const isPdf = isPdfInput(options, inputFiles);

  let resolved: number | null = explicitTimeout;
  if (resolved == null) {
    resolved = isPdf ? (pdfTimeoutMs ?? generalTimeoutMs) : generalTimeoutMs;
  }
  if (
    isPdf &&
    resolved != null &&
    largePdfTimeoutMs != null &&
    (options.sourceFileSizeBytes ?? 0) >= largePdfBytes
  ) {
    resolved = Math.max(resolved, largePdfTimeoutMs);
  }
  return resolved ?? undefined;
}

function resolveAudiverisPdfRasterDpi(): number {
  const configured = parsePositiveInt(process.env.AUDIVERIS_PDF_RASTER_DPI);
  return configured ?? 300;
}

/**
 * Builds the JAVA_TOOL_OPTIONS value for launching Audiveris, always
 * including an explicit heap cap (-Xmx) rather than letting the JVM pick
 * its own default.
 *
 * Why this matters: without an explicit cap, the JVM's default heap
 * sizing can end up larger than what the actual container is limited to
 * (a known class of issue in containerized environments), and Audiveris
 * running out of memory in that scenario means the OS kills the whole
 * container process - which takes this app's own Node.js server down
 * with it mid-request, producing a bare, contentless connection failure
 * instead of a normal error response. With an explicit cap, the JVM
 * itself throws a catchable OutOfMemoryError and exits with a non-zero
 * code if it genuinely runs out of room, which the try/catch below turns
 * into a normal, user-facing error message instead of taking anything
 * else down with it.
 *
 * If JAVA_TOOL_OPTIONS is explicitly set in the environment, it's used
 * exactly as given (full override, for advanced tuning). Otherwise,
 * AUDIVERIS_MAX_HEAP_MB (a plain number, no Java flag syntax needed - see
 * README "Resource note") controls the cap, defaulting to 1024 (1GB).
 *
 * Caveat found by direct testing: -Xmx only bounds the Java heap.
 * Audiveris also uses Tesseract OCR through native/JNI code, and native
 * memory (Tesseract's own buffers, JVM metaspace, thread stacks) is not
 * limited by -Xmx at all - a real OMR run completed successfully even
 * with this set absurdly low (down to 4MB) in testing. So this cap only
 * helps for the subset of out-of-memory failures that are specifically
 * Java-heap exhaustion; it is not a guaranteed fix for every possible
 * memory-related crash.
 */
export function resolveAudiverisJavaToolOptions(): string {
  if (process.env.JAVA_TOOL_OPTIONS) {
    return process.env.JAVA_TOOL_OPTIONS;
  }
  const configuredHeapMb = Number(process.env.AUDIVERIS_MAX_HEAP_MB);
  const heapMb = Number.isFinite(configuredHeapMb) && configuredHeapMb > 0 ? configuredHeapMb : 1024;
  return `-Djava.awt.headless=true -Xmx${heapMb}m`;
}

export class AudiverisOMRService implements OMRService {
  async processScore(inputFiles: string[], options: OMRProcessOptions): Promise<OMRResult> {
    if (!inputFiles.length) {
      throw new Error("No score files were provided to Audiveris.");
    }

    await fs.mkdir(options.outputDir, { recursive: true });
    const args = buildAudiverisArgs({
      outputDir: options.outputDir,
      inputFiles,
      pageNumbers: options.pageNumbers,
    });
    const timeoutMs = resolveAudiverisTimeoutMs(options, inputFiles);

    let runOutput: AudiverisExecOutput = { stdout: "", stderr: "" };
    let initialRunLogText = "";
    try {
      runOutput = await runAudiverisCommand(args, timeoutMs);
    } catch (error) {
      const nodeError = error as NodeJS.ErrnoException & { stdout?: string; stderr?: string };
      if (nodeError?.code === "ENOENT") {
        throw new Error(
          `Audiveris executable not found at "${AUDIVERIS_BIN}". The OMR engine is not installed ` +
            "in this environment (or AUDIVERIS_PATH/AUDIVERIS_BIN points to the wrong location). " +
            "This is a deployment/infrastructure problem, not a recognition failure - no score was processed."
        );
      }
      const combinedOutput = `${nodeError?.stdout ?? ""}\n${nodeError?.stderr ?? ""}`;
      initialRunLogText = await readPrimaryAudiverisLog(options.outputDir);
      const combinedOutputWithLog = [combinedOutput, initialRunLogText].filter(Boolean).join("\n");
      const sourceIsPdf = isPdfInput(options, inputFiles);

      if (looksLikeTimeoutError(nodeError)) {
        const recovered = await recoverFromGeneralPdfFailure({
          inputFiles,
          options,
          timeoutMs,
          initialCombinedOutput: combinedOutputWithLog,
          reasonLabel: "timeout",
        });
        if (recovered) {
          return recovered;
        }
        const configuredLabel = timeoutMs != null ? `${Math.round(timeoutMs / 1000)}s` : "an unknown duration";
        throw new Error(
          `Audiveris exceeded the configured process timeout (${configuredLabel}). ` +
            `Increase AUDIVERIS_TIMEOUT_MS${sourceIsPdf ? " / AUDIVERIS_PDF_TIMEOUT_MS" : ""}, ` +
            "or reprocess in smaller page batches."
        );
      }

      if (looksLikeDenominatorTupletCrash(combinedOutputWithLog)) {
        const recovered = await recoverFromDenominatorCrash({
          inputFiles,
          options,
          timeoutMs,
          initialCombinedOutput: combinedOutputWithLog,
        });
        if (recovered) {
          return recovered;
        }
        throw new Error(
          "Audiveris crashed while processing tuplets/rhythm links (\"Denominator is zero\") and the score could not be recovered by per-page fallback. " +
            "Please replace the affected page(s) or run Reprocess/Replace Page after adjusting the scan."
        );
      }

      if (/OutOfMemoryError/i.test(combinedOutputWithLog)) {
        throw new Error(
          "Audiveris ran out of memory while processing this file (Java heap space exhausted). " +
            `The current heap cap is ${process.env.AUDIVERIS_MAX_HEAP_MB ?? "1024"}MB - increase the ` +
            "AUDIVERIS_MAX_HEAP_MB environment variable if this deployment has more memory available, " +
            "or try a smaller/simpler file (e.g. fewer pages per upload)."
        );
      }
      const recoveredGeneralPdf = await recoverFromGeneralPdfFailure({
        inputFiles,
        options,
        timeoutMs,
        initialCombinedOutput: combinedOutputWithLog,
        reasonLabel: sourceIsPdf ? "full-score failure" : "failure",
      });
      if (recoveredGeneralPdf) {
        return recoveredGeneralPdf;
      }
      const recoveredImages = await recoverFromSeparatePageImages({
        inputFiles,
        options,
        timeoutMs,
        initialCombinedOutput: combinedOutputWithLog,
      });
      if (recoveredImages) {
        return recoveredImages;
      }
      if (sourceIsPdf && looksLikeResolutionRelatedSheetRemoval(combinedOutputWithLog)) {
        const pdftoppmAvailable = await isCommandAvailable("pdftoppm", ["-v"]);
        const availabilityMessage = pdftoppmAvailable
          ? "Built-in PDF raster fallback is available; this file likely needs lower raster DPI or page replacement."
          : "Built-in PDF raster fallback is currently unavailable because `pdftoppm` is not installed in this runtime.";
        throw new Error(
          "Audiveris rejected this PDF during load/scale analysis (sheet removed/ignored), usually due to extreme page resolution " +
            "or oversized pixel dimensions. " +
            availabilityMessage +
            " Try setting AUDIVERIS_PDF_RASTER_DPI (for example 220-300) and retry, or replace problematic pages."
        );
      }
      const message = error instanceof Error ? error.message : "Audiveris execution failed.";
      const detailSnippet = extractFailureDetailSnippet(combinedOutputWithLog);
      throw new Error(`Audiveris failed: ${message}${detailSnippet ? `\n${detailSnippet}` : ""}`);
    }

    const extracted = await extractMusicXmlAndArtifacts(options.outputDir);
    const recognitionLog = [runOutput.stdout, runOutput.stderr].filter(Boolean).join("\n");
    const warnings = collectAudiverisWarnings(recognitionLog);

    return {
      musicXml: extracted.musicXml,
      diagnostics: {
        lowConfidence: warnings.length > 0,
        warnings,
        quality: {
          blurScore: 1,
          contrastScore: 1,
          glareScore: 1,
          perspectiveScore: 1,
        },
      },
      provider: "audiveris",
      warnings,
      artifacts: extracted.artifacts,
      recognitionLog,
    };
  }
}

function buildAudiverisArgs(params: {
  outputDir: string;
  inputFiles: string[];
  pageNumbers?: number[];
}) {
  const args = ["-batch", "-save", "-export", "-output", params.outputDir];
  if (params.pageNumbers?.length) {
    args.push("-sheets", params.pageNumbers.join(" "));
  }
  args.push("--", ...params.inputFiles);
  return args;
}

async function runAudiverisCommand(
  args: string[],
  timeoutMs?: number
): Promise<AudiverisExecOutput> {
  const result = await execFileAsync(AUDIVERIS_BIN, args, {
    env: {
      ...process.env,
      JAVA_TOOL_OPTIONS: resolveAudiverisJavaToolOptions(),
    },
    maxBuffer: 32 * 1024 * 1024,
    ...(timeoutMs != null ? { timeout: timeoutMs } : {}),
  });
  return {
    stdout: result.stdout ?? "",
    stderr: result.stderr ?? "",
  };
}

function looksLikeDenominatorTupletCrash(text: string) {
  return /denominator is zero/i.test(text) || /TupletsBuilder/i.test(text);
}

async function recoverFromDenominatorCrash(params: {
  inputFiles: string[];
  options: OMRProcessOptions;
  timeoutMs?: number;
  initialCombinedOutput: string;
}): Promise<OMRResult | null> {
  // Only useful for a full multi-page run. If the caller already asked
  // for an explicit page subset, we can't further split meaningfully.
  if (params.options.pageNumbers?.length) {
    return null;
  }

  const logText = await readPrimaryAudiverisLog(params.options.outputDir);
  const sheetCount = await detectSheetCountForRecovery(
    logText,
    params.initialCombinedOutput,
    params.inputFiles
  );
  if (!sheetCount || sheetCount < 2) {
    return null;
  }

  const successfulSheets: RecoveredSheetResult[] = [];
  const failedSheets: Array<{ sheetNumber: number; reason: string }> = [];
  const fallbackLogs: string[] = [];

  for (let sheetNumber = 1; sheetNumber <= sheetCount; sheetNumber += 1) {
    const sheetOutputDir = path.join(params.options.outputDir, `sheet-recovery-${sheetNumber}`);
    await fs.mkdir(sheetOutputDir, { recursive: true });
    const args = buildAudiverisArgs({
      outputDir: sheetOutputDir,
      inputFiles: params.inputFiles,
      pageNumbers: [sheetNumber],
    });
    try {
      const run = await runAudiverisCommand(
        args,
        resolveAudiverisTimeoutMs({ ...params.options, pageNumbers: [sheetNumber] }, params.inputFiles) ??
          params.timeoutMs
      );
      const extracted = await extractMusicXmlAndArtifacts(sheetOutputDir);
      const runLog = [run.stdout, run.stderr].filter(Boolean).join("\n");
      successfulSheets.push({
        sheetNumber,
        musicXml: extracted.musicXml,
        runLog,
      });
      fallbackLogs.push(`--- RECOVERY SHEET ${sheetNumber} SUCCESS ---\n${runLog}`);
    } catch (error) {
      const nodeError = error as NodeJS.ErrnoException & { stdout?: string; stderr?: string };
      const logOutput = [nodeError?.stdout ?? "", nodeError?.stderr ?? ""].filter(Boolean).join("\n");
      fallbackLogs.push(`--- RECOVERY SHEET ${sheetNumber} FAILED ---\n${logOutput}`);
      failedSheets.push({
        sheetNumber,
        reason:
          looksLikeDenominatorTupletCrash(logOutput) || looksLikeDenominatorTupletCrash(logText)
            ? "Audiveris tuplet/rhythm crash (denominator zero)"
            : "Audiveris failed while processing this page",
      });
    }
  }

  if (!successfulSheets.length) {
    return null;
  }

  const combinedMusicXml =
    successfulSheets.length === 1
      ? successfulSheets[0].musicXml
      : mergeMusicXmlPages(
          successfulSheets
            .sort((a, b) => a.sheetNumber - b.sheetNumber)
            .map((sheet) => ({ sheetNumber: sheet.sheetNumber, musicXml: sheet.musicXml }))
        );

  const mergedMusicXmlPath = path.join(params.options.outputDir, "audiveris-recovered.musicxml");
  await fs.writeFile(mergedMusicXmlPath, combinedMusicXml, "utf8");

  const recoveryWarnings = [
    `Audiveris crashed in full-score mode during tuplet/rhythm linking (\"Denominator is zero\"). Recovered by processing pages individually.`,
    failedSheets.length
      ? `Skipped page(s): ${failedSheets
          .map((f) => `${f.sheetNumber} (${f.reason})`)
          .join(", ")}.`
      : "All pages recovered successfully in per-page mode.",
  ];

  const recognitionLog = [
    "--- INITIAL FULL-RUN FAILURE ---",
    params.initialCombinedOutput,
    ...fallbackLogs,
  ]
    .filter(Boolean)
    .join("\n");
  const warnings = [...new Set([...recoveryWarnings, ...collectAudiverisWarnings(recognitionLog)])];

  return {
    musicXml: combinedMusicXml,
    diagnostics: {
      lowConfidence: true,
      warnings,
      quality: {
        blurScore: 1,
        contrastScore: 1,
        glareScore: 1,
        perspectiveScore: 1,
      },
    },
    provider: "audiveris",
    warnings,
    artifacts: {
      audiverisOmrPath: null,
      audiverisMxlPath: null,
      audiverisMusicXmlPath: mergedMusicXmlPath,
    },
    recognitionLog,
  };
}

function looksLikeTimeoutError(error: NodeJS.ErrnoException | null | undefined): boolean {
  if (!error) {
    return false;
  }
  if (error.code === "ETIMEDOUT") {
    return true;
  }
  if (typeof error.message === "string" && /timed out/i.test(error.message)) {
    return true;
  }
  return false;
}

async function recoverFromGeneralPdfFailure(params: {
  inputFiles: string[];
  options: OMRProcessOptions;
  timeoutMs?: number;
  initialCombinedOutput: string;
  reasonLabel: string;
}): Promise<OMRResult | null> {
  if (params.options.pageNumbers?.length) {
    return null;
  }
  if (!isPdfInput(params.options, params.inputFiles)) {
    return null;
  }
  const logText = await readPrimaryAudiverisLog(params.options.outputDir);
  const sheetCount = await detectSheetCountForRecovery(logText, params.initialCombinedOutput, params.inputFiles);
  const singlePdfPath =
    params.inputFiles.length === 1 && params.inputFiles[0].toLowerCase().endsWith(".pdf")
      ? params.inputFiles[0]
      : null;
  if ((!sheetCount || sheetCount < 1) && !singlePdfPath) {
    return null;
  }

  const successfulSheets: RecoveredSheetResult[] = [];
  const failedSheets: Array<{ sheetNumber: number; reason: string }> = [];
  const fallbackLogs: string[] = [];
  let usedSplitPdfMode = false;
  let usedRasterizedPdfMode = false;

  if (sheetCount && sheetCount >= 1) {
    for (let sheetNumber = 1; sheetNumber <= sheetCount; sheetNumber += 1) {
      const result = await runRecoveryAttempt({
        outputDir: path.join(params.options.outputDir, `sheet-recovery-general-${sheetNumber}`),
        inputFiles: params.inputFiles,
        pageNumbers: [sheetNumber],
        timeoutMs:
          resolveAudiverisTimeoutMs({ ...params.options, pageNumbers: [sheetNumber] }, params.inputFiles) ??
          params.timeoutMs,
      });
      fallbackLogs.push(
        `--- RECOVERY SHEET ${sheetNumber} ${result.successfulSheet ? "SUCCESS" : "FAILED"} ---\n${result.logOutput}`
      );
      if (result.successfulSheet) {
        successfulSheets.push({
          sheetNumber,
          musicXml: result.successfulSheet.musicXml,
          runLog: result.logOutput,
        });
      } else {
        failedSheets.push({ sheetNumber, reason: result.failureReason ?? "Audiveris failed while processing this page" });
      }
    }
  }

  if (!successfulSheets.length && singlePdfPath) {
    const splitTempDir = path.join(params.options.outputDir, "split-pdf-recovery");
    const splitPages = await splitPdfIntoSinglePageFiles(singlePdfPath, splitTempDir);
    if (splitPages.length > 1) {
      usedSplitPdfMode = true;
      failedSheets.length = 0;
      fallbackLogs.push("--- FALLBACK: SPLIT PDF INTO SINGLE-PAGE FILES ---");
      for (let idx = 0; idx < splitPages.length; idx += 1) {
        const pagePath = splitPages[idx];
        const sheetNumber = idx + 1;
        const result = await runRecoveryAttempt({
          outputDir: path.join(params.options.outputDir, `sheet-recovery-split-${sheetNumber}`),
          inputFiles: [pagePath],
          timeoutMs: resolveAudiverisTimeoutMs(
            { ...params.options, pageNumbers: undefined, sourceExtension: "pdf" },
            [pagePath]
          ),
        });
        fallbackLogs.push(
          `--- SPLIT-PDF SHEET ${sheetNumber} ${result.successfulSheet ? "SUCCESS" : "FAILED"} ---\n${result.logOutput}`
        );
        if (result.successfulSheet) {
          successfulSheets.push({
            sheetNumber,
            musicXml: result.successfulSheet.musicXml,
            runLog: result.logOutput,
          });
        } else {
          failedSheets.push({
            sheetNumber,
            reason: result.failureReason ?? "Audiveris failed while processing this split page",
          });
        }
      }
    }
    await fs.rm(splitTempDir, { recursive: true, force: true }).catch(() => {});
  }

  if (!successfulSheets.length && singlePdfPath) {
    const rasterTempDir = path.join(params.options.outputDir, "rasterized-pdf-recovery");
    const rasterPages = await rasterizePdfToPngPages(singlePdfPath, rasterTempDir);
    if (rasterPages.length) {
      usedRasterizedPdfMode = true;
      failedSheets.length = 0;
      fallbackLogs.push(
        `--- FALLBACK: RASTERIZED PDF PAGES (${resolveAudiverisPdfRasterDpi()} DPI via pdftoppm) ---`
      );
      for (let idx = 0; idx < rasterPages.length; idx += 1) {
        const pagePath = rasterPages[idx];
        const sheetNumber = idx + 1;
        const result = await runRecoveryAttempt({
          outputDir: path.join(params.options.outputDir, `sheet-recovery-raster-${sheetNumber}`),
          inputFiles: [pagePath],
          timeoutMs: resolveAudiverisTimeoutMs(
            { ...params.options, pageNumbers: undefined, sourceExtension: "png" },
            [pagePath]
          ),
        });
        fallbackLogs.push(
          `--- RASTER-PDF SHEET ${sheetNumber} ${result.successfulSheet ? "SUCCESS" : "FAILED"} ---\n${result.logOutput}`
        );
        if (result.successfulSheet) {
          successfulSheets.push({
            sheetNumber,
            musicXml: result.successfulSheet.musicXml,
            runLog: result.logOutput,
          });
        } else {
          failedSheets.push({
            sheetNumber,
            reason: result.failureReason ?? "Audiveris failed while processing this rasterized page",
          });
        }
      }
    } else {
      fallbackLogs.push(
        "--- FALLBACK: RASTERIZED PDF PAGES SKIPPED (pdftoppm unavailable or PDF rasterization failed) ---"
      );
    }
    await fs.rm(rasterTempDir, { recursive: true, force: true }).catch(() => {});
  }

  if (!successfulSheets.length) {
    return null;
  }

  const combinedMusicXml =
    successfulSheets.length === 1
      ? successfulSheets[0].musicXml
      : mergeMusicXmlPages(
          successfulSheets
            .sort((a, b) => a.sheetNumber - b.sheetNumber)
            .map((sheet) => ({ sheetNumber: sheet.sheetNumber, musicXml: sheet.musicXml }))
        );
  const mergedMusicXmlPath = path.join(params.options.outputDir, "audiveris-recovered-general.musicxml");
  await fs.writeFile(mergedMusicXmlPath, combinedMusicXml, "utf8");
  const recoveryWarnings = [
    usedRasterizedPdfMode
      ? `Audiveris ${params.reasonLabel} in full-score PDF mode. Recovered by rasterizing PDF pages (pdftoppm) and processing each page image.`
      : usedSplitPdfMode
        ? `Audiveris ${params.reasonLabel} in full-score PDF mode. Recovered by splitting the PDF and processing pages individually.`
        : `Audiveris ${params.reasonLabel} in full-score PDF mode. Recovered by processing pages individually.`,
    failedSheets.length
      ? `Skipped page(s): ${failedSheets.map((f) => `${f.sheetNumber} (${f.reason})`).join(", ")}.`
      : "All pages recovered successfully in per-page mode.",
  ];

  const recognitionLog = [
    "--- INITIAL FULL-RUN FAILURE ---",
    params.initialCombinedOutput,
    ...fallbackLogs,
  ]
    .filter(Boolean)
    .join("\n");
  const warnings = [...new Set([...recoveryWarnings, ...collectAudiverisWarnings(recognitionLog)])];

  return {
    musicXml: combinedMusicXml,
    diagnostics: {
      lowConfidence: true,
      warnings,
      quality: {
        blurScore: 1,
        contrastScore: 1,
        glareScore: 1,
        perspectiveScore: 1,
      },
    },
    provider: "audiveris",
    warnings,
    artifacts: {
      audiverisOmrPath: null,
      audiverisMxlPath: null,
      audiverisMusicXmlPath: mergedMusicXmlPath,
    },
    recognitionLog,
  };
}

function isSeparateRasterPage(filePath: string): boolean {
  return /\.(png|jpe?g|webp)$/i.test(filePath);
}

/**
 * A multi-page photocopy is sent as separate images. Audiveris aborts the
 * whole export when one sheet fails. Read each page on its own, keep every
 * page that exports, and report the pages that could not be transcribed.
 */
async function recoverFromSeparatePageImages(params: {
  inputFiles: string[];
  options: OMRProcessOptions;
  timeoutMs?: number;
  initialCombinedOutput: string;
}): Promise<OMRResult | null> {
  if (params.options.pageNumbers?.length) {
    return null;
  }
  if (params.inputFiles.length < 2 || !params.inputFiles.every(isSeparateRasterPage)) {
    return null;
  }

  const successfulSheets: RecoveredSheetResult[] = [];
  const failedSheets: Array<{ sheetNumber: number; label: string; reason: string }> = [];
  const fallbackLogs: string[] = [];
  const alreadyExported = await salvagePageExports(params.options.outputDir, params.inputFiles);

  for (let index = 0; index < params.inputFiles.length; index += 1) {
    const sheetNumber = index + 1;
    const label = pageLabel(params.inputFiles[index], sheetNumber);
    const salvaged = alreadyExported.get(index);
    if (salvaged) {
      successfulSheets.push({ sheetNumber, musicXml: salvaged, runLog: "Kept the export from the first run." });
      fallbackLogs.push(`--- PAGE ${label} KEPT FROM FIRST RUN ---`);
      continue;
    }
    const result = await runRecoveryAttempt({
      outputDir: path.join(params.options.outputDir, `page-recovery-${sheetNumber}`),
      inputFiles: [params.inputFiles[index]],
      timeoutMs:
        resolveAudiverisTimeoutMs(
          { ...params.options, pageNumbers: undefined, sourceExtension: "png" },
          [params.inputFiles[index]]
        ) ?? params.timeoutMs,
    });
    fallbackLogs.push(
      `--- PAGE ${label} ${result.successfulSheet ? "SUCCESS" : "FAILED"} ---\n${result.logOutput}`
    );
    if (result.successfulSheet) {
      successfulSheets.push({
        sheetNumber,
        musicXml: result.successfulSheet.musicXml,
        runLog: result.logOutput,
      });
    } else {
      failedSheets.push({
        sheetNumber,
        label,
        reason: result.failureReason ?? "Audiveris could not transcribe this page",
      });
    }
  }

  if (!successfulSheets.length) {
    return null;
  }

  const combinedMusicXml =
    successfulSheets.length === 1
      ? successfulSheets[0].musicXml
      : mergeMusicXmlPages(
          successfulSheets
            .sort((a, b) => a.sheetNumber - b.sheetNumber)
            .map((sheet) => ({ sheetNumber: sheet.sheetNumber, musicXml: sheet.musicXml }))
        );
  const mergedMusicXmlPath = path.join(params.options.outputDir, "audiveris-recovered-pages.musicxml");
  await fs.writeFile(mergedMusicXmlPath, combinedMusicXml, "utf8");
  const recoveryWarnings = [
    failedSheets.length
      ? `Kept ${successfulSheets.length} of ${params.inputFiles.length} pages. Left out ${failedSheets
          .map((sheet) => sheet.label)
          .join(", ")} because those pages could not be transcribed.`
      : "The combined page run could not export, so each page was read on its own.",
  ];
  const recognitionLog = ["--- INITIAL FULL-RUN FAILURE ---", params.initialCombinedOutput, ...fallbackLogs]
    .filter(Boolean)
    .join("\n");
  const warnings = [...new Set([...recoveryWarnings, ...collectAudiverisWarnings(recognitionLog)])];

  return {
    musicXml: combinedMusicXml,
    diagnostics: {
      lowConfidence: failedSheets.length > 0,
      warnings,
      quality: {
        blurScore: 1,
        contrastScore: 1,
        glareScore: 1,
        perspectiveScore: 1,
      },
    },
    provider: "audiveris",
    warnings,
    artifacts: {
      audiverisOmrPath: null,
      audiverisMxlPath: null,
      audiverisMusicXmlPath: mergedMusicXmlPath,
    },
    recognitionLog,
  };
}

function pageLabel(filePath: string, sheetNumber: number): string {
  const match = path.basename(filePath).match(/page-(\d+)/i);
  return match ? `page ${Number(match[1])}` : `page ${sheetNumber}`;
}

async function salvagePageExports(outputDir: string, inputFiles: string[]): Promise<Map<number, string>> {
  const exported = new Map<number, string>();
  let files: string[] = [];
  try {
    files = await listFilesRecursive(outputDir);
  } catch {
    return exported;
  }
  for (let index = 0; index < inputFiles.length; index += 1) {
    const stem = path.basename(inputFiles[index]).replace(/\.[^.]+$/, "");
    const match = files.find((file) => {
      const base = path.basename(file);
      if (!base.startsWith(`${stem}.`) && !base.startsWith(`${stem}-`)) {
        return false;
      }
      return base.endsWith(".mxl") || base.endsWith(".musicxml");
    });
    if (!match) {
      continue;
    }
    try {
      const musicXml = match.endsWith(".mxl")
        ? await extractMusicXmlFromMxl(match)
        : await fs.readFile(match, "utf8");
      if (musicXml.trim()) {
        exported.set(index, musicXml);
      }
    } catch {
      continue;
    }
  }
  return exported;
}

async function runRecoveryAttempt(params: {
  outputDir: string;
  inputFiles: string[];
  pageNumbers?: number[];
  timeoutMs?: number;
}): Promise<{
  successfulSheet: { musicXml: string } | null;
  logOutput: string;
  failureReason?: string;
}> {
  await fs.mkdir(params.outputDir, { recursive: true });
  const args = buildAudiverisArgs({
    outputDir: params.outputDir,
    inputFiles: params.inputFiles,
    pageNumbers: params.pageNumbers,
  });
  try {
    const run = await runAudiverisCommand(args, params.timeoutMs);
    const extracted = await extractMusicXmlAndArtifacts(params.outputDir);
    const logOutput = [run.stdout, run.stderr].filter(Boolean).join("\n");
    return {
      successfulSheet: { musicXml: extracted.musicXml },
      logOutput,
    };
  } catch (error) {
    const nodeError = error as NodeJS.ErrnoException & { stdout?: string; stderr?: string };
    const logOutput = [nodeError?.stdout ?? "", nodeError?.stderr ?? ""].filter(Boolean).join("\n");
    // Some Audiveris runs exit non-zero despite writing a usable export;
    // salvage that output instead of discarding the page outright.
    const extractedAfterFailure = await tryExtractMusicXmlFromOutputDir(params.outputDir);
    if (extractedAfterFailure) {
      return {
        successfulSheet: { musicXml: extractedAfterFailure },
        logOutput: [logOutput, "Recovered MusicXML despite non-zero Audiveris exit code."].filter(Boolean).join("\n"),
      };
    }
    return {
      successfulSheet: null,
      logOutput,
      failureReason: inferRecoveryFailureReason(logOutput, error as NodeJS.ErrnoException),
    };
  }
}

function inferRecoveryFailureReason(logOutput: string, error: NodeJS.ErrnoException): string {
  if (looksLikeTimeoutError(error)) {
    return "page timeout";
  }
  if (/too large image/i.test(logOutput)) {
    return "page image too large for default Audiveris limits";
  }
  if (/too high interline value/i.test(logOutput)) {
    return "page resolution too high for Audiveris staff scaling";
  }
  if (/sheet removed|sheet ignored/i.test(logOutput)) {
    return "Audiveris removed this page during load/scale analysis";
  }
  return "Audiveris failed while processing this page";
}

function looksLikeResolutionRelatedSheetRemoval(text: string): boolean {
  return /sheet removed|sheet ignored|too large image|too high interline/i.test(text);
}

async function isCommandAvailable(command: string, args: string[] = []): Promise<boolean> {
  try {
    await execFileAsync(command, args, { maxBuffer: 1024 * 1024 });
    return true;
  } catch (error) {
    const nodeError = error as NodeJS.ErrnoException;
    if (nodeError?.code === "ENOENT") {
      return false;
    }
    // Command exists but returned non-zero (common for --version flags).
    return true;
  }
}

async function tryExtractMusicXmlFromOutputDir(outputDir: string): Promise<string | null> {
  try {
    const extracted = await extractMusicXmlAndArtifacts(outputDir);
    return extracted.musicXml.trim() ? extracted.musicXml : null;
  } catch {
    return null;
  }
}

function extractFailureDetailSnippet(text: string): string {
  if (!text.trim()) {
    return "";
  }
  const lines = text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
  const signalLines = lines.filter((line) =>
    /(ERROR|Exception|failed|OutOfMemory|No target duration|Sheet ignored|Sheet removed|could not|timeout)/i.test(line)
  );
  const selected = signalLines.length ? signalLines.slice(-8) : lines.slice(-8);
  if (!selected.length) {
    return "";
  }
  return `Audiveris details:\n${selected.join("\n")}`;
}

function detectSheetCountFromTexts(...texts: string[]): number | null {
  const numbers = new Set<number>();
  const addMatches = (regex: RegExp) => {
    for (const text of texts) {
      for (const match of text.matchAll(regex)) {
        const value = Number(match[1]);
        if (Number.isFinite(value) && value > 0 && value < 1_000) {
          numbers.add(value);
        }
      }
    }
  };
  addMatches(/Loaded image #(\d+)/g);
  addMatches(/\b(?:stub|sheet)\s*#\s*(\d+)\b/gi);
  addMatches(/\[[^\]]*#(\d+)\]/g);
  if (!numbers.size) {
    return null;
  }
  return Math.max(...numbers);
}

async function detectSheetCountForRecovery(
  logText: string,
  initialCombinedOutput: string,
  inputFiles: string[]
): Promise<number | null> {
  const fromLogs = detectSheetCountFromTexts(logText, initialCombinedOutput);
  if (fromLogs && fromLogs >= 1) {
    return fromLogs;
  }
  const fromPdf = await detectPdfPageCountHint(inputFiles);
  if (fromPdf && fromPdf >= 1) {
    return fromPdf;
  }
  return null;
}

async function detectPdfPageCountHint(inputFiles: string[]): Promise<number | null> {
  if (inputFiles.length !== 1 || !inputFiles[0].toLowerCase().endsWith(".pdf")) {
    return null;
  }
  try {
    const content = await fs.readFile(inputFiles[0], "latin1");
    // Heuristic: look for the Pages tree /Count value first.
    const pageTreeMatches = [...content.matchAll(/\/Type\s*\/Pages[\s\S]{0,300}?\/Count\s+(\d+)/g)];
    const pageTreeCounts = pageTreeMatches
      .map((match) => Number(match[1]))
      .filter((value) => Number.isFinite(value) && value > 0 && value < 1_000);
    if (pageTreeCounts.length) {
      return Math.max(...pageTreeCounts);
    }
  } catch {
    return null;
  }
  return null;
}

async function splitPdfIntoSinglePageFiles(pdfPath: string, outputDir: string): Promise<string[]> {
  try {
    const bytes = await fs.readFile(pdfPath);
    const source = await PDFDocument.load(bytes);
    const total = source.getPageCount();
    if (total < 2) {
      return [];
    }
    await fs.mkdir(outputDir, { recursive: true });
    const paths: string[] = [];
    for (let idx = 0; idx < total; idx += 1) {
      const doc = await PDFDocument.create();
      const [copied] = await doc.copyPages(source, [idx]);
      doc.addPage(copied);
      const pageBytes = await doc.save();
      const pagePath = path.join(outputDir, `page-${String(idx + 1).padStart(3, "0")}.pdf`);
      await fs.writeFile(pagePath, pageBytes);
      paths.push(pagePath);
    }
    return paths;
  } catch {
    return [];
  }
}

async function rasterizePdfToPngPages(pdfPath: string, outputDir: string): Promise<string[]> {
  const dpi = resolveAudiverisPdfRasterDpi();
  const prefixPath = path.join(outputDir, "page");
  await fs.mkdir(outputDir, { recursive: true });
  try {
    await execFileAsync("pdftoppm", ["-r", String(dpi), "-png", pdfPath, prefixPath], {
      maxBuffer: 32 * 1024 * 1024,
    });
  } catch (error) {
    const nodeError = error as NodeJS.ErrnoException;
    if (nodeError?.code === "ENOENT") {
      return [];
    }
    return [];
  }
  const files = await listFilesRecursive(outputDir);
  return files
    .filter((candidate) => /page-\d+\.png$/i.test(path.basename(candidate)))
    .sort((a, b) => {
      const numberA = extractPageNumberFromRasterFileName(path.basename(a));
      const numberB = extractPageNumberFromRasterFileName(path.basename(b));
      return numberA - numberB;
    });
}

function extractPageNumberFromRasterFileName(fileName: string): number {
  const match = fileName.match(/page-(\d+)\.png$/i);
  const parsed = match ? Number(match[1]) : Number.NaN;
  return Number.isFinite(parsed) ? parsed : Number.MAX_SAFE_INTEGER;
}

async function readPrimaryAudiverisLog(outputDir: string): Promise<string> {
  try {
    const files = await listFilesRecursive(outputDir);
    const logCandidates = files
      .filter((candidate) => candidate.endsWith(".log"))
      .sort((a, b) => a.localeCompare(b));
    const latest = logCandidates.at(-1);
    if (!latest) {
      return "";
    }
    return fs.readFile(/* turbopackIgnore: true */ latest, "utf8");
  } catch {
    return "";
  }
}

async function extractMusicXmlAndArtifacts(outputDir: string): Promise<AudiverisExtractedOutput> {
  const files = await listFilesRecursive(outputDir);
  const omrPath = files.find((candidate) => candidate.endsWith(".omr")) ?? null;
  const mxlPath = files.find((candidate) => candidate.endsWith(".mxl")) ?? null;
  const musicXmlPathCandidate = files.find((candidate) => candidate.endsWith(".musicxml")) ?? null;
  const fallbackXmlPath =
    musicXmlPathCandidate == null
      ? files.find(
          (candidate) =>
            candidate.endsWith(".xml") &&
            !candidate.endsWith("book.xml") &&
            !/sheet#\d+\.xml$/i.test(candidate)
        ) ?? null
      : null;
  const xmlPath = musicXmlPathCandidate ?? fallbackXmlPath;

  let musicXml = "";
  let persistedMusicXmlPath: string | null = null;
  if (xmlPath) {
    musicXml = await fs.readFile(/* turbopackIgnore: true */ xmlPath, "utf8");
    persistedMusicXmlPath = xmlPath;
  } else if (mxlPath) {
    musicXml = await extractMusicXmlFromMxl(mxlPath);
    persistedMusicXmlPath = await persistExtractedMusicXml(outputDir, mxlPath, musicXml);
  }

  if (!musicXml.trim().length) {
    throw new Error("Audiveris did not produce MusicXML output. Please replace the page with a clearer scan.");
  }

  return {
    musicXml,
    artifacts: {
      audiverisOmrPath: omrPath,
      audiverisMxlPath: mxlPath,
      audiverisMusicXmlPath: persistedMusicXmlPath,
    },
  };
}

function mergeMusicXmlPages(pages: Array<{ sheetNumber: number; musicXml: string }>): string {
  if (!pages.length) {
    throw new Error("Cannot merge MusicXML pages: no pages were provided.");
  }
  if (pages.length === 1) {
    return pages[0].musicXml;
  }

  const parser = new XMLParser({
    ignoreAttributes: false,
    parseTagValue: false,
    trimValues: false,
  });
  const builder = new XMLBuilder({
    ignoreAttributes: false,
    format: true,
  });

  const parsedDocs = pages.map((page) => ({
    sheetNumber: page.sheetNumber,
    root: parser.parse(page.musicXml)?.["score-partwise"] as Record<string, unknown> | undefined,
  }));
  if (!parsedDocs.every((doc) => doc.root)) {
    throw new Error("Cannot merge MusicXML pages: at least one page is not valid score-partwise MusicXML.");
  }

  const baseRoot = parsedDocs[0].root as Record<string, unknown>;
  const basePartList = ensureObject(baseRoot["part-list"]);
  const baseScoreParts = asArray<Record<string, unknown>>(basePartList["score-part"]);
  basePartList["score-part"] = baseScoreParts;
  baseRoot["part-list"] = basePartList;
  const baseParts = asArray<Record<string, unknown>>(baseRoot.part);
  baseRoot.part = baseParts;

  const scorePartById = new Map<string, Record<string, unknown>>();
  for (const scorePart of baseScoreParts) {
    const id = readAttribute(scorePart, "id");
    if (id) {
      scorePartById.set(id, scorePart);
    }
  }
  const partById = new Map<string, Record<string, unknown>>();
  for (const part of baseParts) {
    const id = readAttribute(part, "id");
    if (id) {
      partById.set(id, part);
      part.measure = asArray<Record<string, unknown>>(part.measure);
    }
  }

  for (const doc of parsedDocs.slice(1)) {
    const root = doc.root as Record<string, unknown>;
    const partList = ensureObject(root["part-list"]);
    const scoreParts = asArray<Record<string, unknown>>(partList["score-part"]);
    for (const scorePart of scoreParts) {
      const id = readAttribute(scorePart, "id");
      if (!id || scorePartById.has(id)) {
        continue;
      }
      scorePartById.set(id, scorePart);
      baseScoreParts.push(scorePart);
    }

    const parts = asArray<Record<string, unknown>>(root.part);
    for (const incomingPart of parts) {
      const id = readAttribute(incomingPart, "id");
      if (!id) {
        continue;
      }
      const incomingMeasures = asArray<Record<string, unknown>>(incomingPart.measure);
      const existing = partById.get(id);
      if (!existing) {
        incomingPart.measure = incomingMeasures;
        partById.set(id, incomingPart);
        baseParts.push(incomingPart);
        continue;
      }
      const existingMeasures = asArray<Record<string, unknown>>(existing.measure);
      existingMeasures.push(...incomingMeasures);
      existing.measure = existingMeasures;
    }
  }

  return `<?xml version="1.0" encoding="UTF-8"?>\n${builder.build({ "score-partwise": baseRoot })}`;
}

function asArray<T>(value: unknown): T[] {
  if (value == null) {
    return [];
  }
  return Array.isArray(value) ? (value as T[]) : [value as T];
}

function ensureObject(value: unknown): Record<string, unknown> {
  return typeof value === "object" && value !== null ? (value as Record<string, unknown>) : {};
}

function readAttribute(node: Record<string, unknown>, name: string): string | null {
  const value = node[`@_${name}`];
  return typeof value === "string" ? value : null;
}

async function listFilesRecursive(rootDir: string): Promise<string[]> {
  const entries = await fs.readdir(rootDir, { withFileTypes: true });
  const files: string[] = [];
  for (const entry of entries) {
    const fullPath = path.join(rootDir, entry.name);
    if (entry.isDirectory()) {
      files.push(...(await listFilesRecursive(fullPath)));
    } else if (entry.isFile()) {
      files.push(fullPath);
    }
  }
  return files;
}

async function extractMusicXmlFromMxl(mxlPath: string) {
  const archiveBuffer = await fs.readFile(mxlPath);
  const zip = await JSZip.loadAsync(archiveBuffer);
  const container = zip.file("META-INF/container.xml");
  if (container) {
    const containerText = await container.async("text");
    const rootPath = parseContainerRootPath(containerText);
    if (rootPath) {
      const mainEntry = zip.file(rootPath);
      if (mainEntry) {
        return mainEntry.async("text");
      }
    }
  }
  const fallback = Object.keys(zip.files).find(
    (entryName) =>
      (entryName.endsWith(".xml") || entryName.endsWith(".musicxml")) &&
      !entryName.startsWith("META-INF/")
  );
  if (!fallback) {
    throw new Error("Could not locate score XML in Audiveris MXL archive.");
  }
  return zip.file(fallback)?.async("text") ?? "";
}

function parseContainerRootPath(containerXml: string) {
  const match = containerXml.match(/full-path="([^"]+)"/i);
  return match?.[1] ?? null;
}

async function persistExtractedMusicXml(outputDir: string, mxlPath: string, xmlText: string) {
  const fileName = `${path.basename(mxlPath, ".mxl")}.musicxml`;
  const filePath = path.join(outputDir, fileName);
  await fs.writeFile(filePath, xmlText, "utf8");
  return filePath;
}

function collectAudiverisWarnings(logOutput: string) {
  const warnings: string[] = [];
  const lines = logOutput.split(/\r?\n/);
  for (const line of lines) {
    if (line.includes("WARN") || line.toLowerCase().includes("missing support")) {
      warnings.push(line.replace(/\s+/g, " ").trim());
    }
  }
  return [...new Set(warnings)].slice(0, 12);
}

