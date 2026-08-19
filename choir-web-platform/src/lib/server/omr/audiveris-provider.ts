import { execFile } from "node:child_process";
import { promises as fs } from "node:fs";
import path from "node:path";
import { promisify } from "node:util";
import JSZip from "jszip";
import type { OMRResult, OMRService, OMRProcessOptions } from "@/lib/server/omr/provider";

const execFileAsync = promisify(execFile);
const AUDIVERIS_BIN = process.env.AUDIVERIS_BIN ?? "/opt/audiveris/bin/Audiveris";

export class AudiverisOMRService implements OMRService {
  async processScore(inputFiles: string[], options: OMRProcessOptions): Promise<OMRResult> {
    if (!inputFiles.length) {
      throw new Error("No score files were provided to Audiveris.");
    }

    await fs.mkdir(options.outputDir, { recursive: true });
    const args = ["-batch", "-save", "-export", "-output", options.outputDir];

    if (options.pageNumbers?.length) {
      args.push("-sheets", options.pageNumbers.join(" "));
    }

    args.push("--", ...inputFiles);

    let stdout = "";
    let stderr = "";
    try {
      const result = await execFileAsync(AUDIVERIS_BIN, args, {
        env: {
          ...process.env,
          JAVA_TOOL_OPTIONS: process.env.JAVA_TOOL_OPTIONS ?? "-Djava.awt.headless=true",
        },
        maxBuffer: 32 * 1024 * 1024,
      });
      stdout = result.stdout ?? "";
      stderr = result.stderr ?? "";
    } catch (error) {
      const message = error instanceof Error ? error.message : "Audiveris execution failed.";
      throw new Error(`Audiveris failed: ${message}`);
    }

    const files = await listFilesRecursive(options.outputDir);
    const omrPath = files.find((candidate) => candidate.endsWith(".omr")) ?? null;
    const mxlPath = files.find((candidate) => candidate.endsWith(".mxl")) ?? null;
    const xmlPath = files.find(
      (candidate) =>
        candidate.endsWith(".musicxml") ||
        (candidate.endsWith(".xml") && !candidate.endsWith("book.xml"))
    );

    let musicXml = "";
    let musicXmlPath: string | null = null;
    if (xmlPath) {
      musicXml = await fs.readFile(xmlPath, "utf8");
      musicXmlPath = xmlPath;
    } else if (mxlPath) {
      musicXml = await extractMusicXmlFromMxl(mxlPath);
      musicXmlPath = await persistExtractedMusicXml(options.outputDir, mxlPath, musicXml);
    }

    if (!musicXml.trim().length) {
      throw new Error(
        "Audiveris did not produce MusicXML output. Please replace the page with a clearer scan."
      );
    }

    const recognitionLog = [stdout, stderr].filter(Boolean).join("\n");
    const warnings = collectAudiverisWarnings(recognitionLog);

    return {
      musicXml,
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
      artifacts: {
        audiverisOmrPath: omrPath,
        audiverisMxlPath: mxlPath,
        audiverisMusicXmlPath: musicXmlPath,
      },
      recognitionLog,
    };
  }
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

