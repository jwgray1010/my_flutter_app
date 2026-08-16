import { promises as fs } from "node:fs";
import path from "node:path";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import type { OMRDiagnostics } from "@/lib/score-types";
import type { OMRInput, OMRProvider, OMRResult } from "@/lib/server/omr/provider";

const execFileAsync = promisify(execFile);

export class HomrOcrProvider implements OMRProvider {
  async recognize(input: OMRInput, diagnostics: OMRDiagnostics): Promise<OMRResult> {
    const scriptPath = path.join(process.cwd(), "scripts", "run_homr.py");
    const { stdout, stderr } = await execFileAsync("python3", [scriptPath, input.filePath], {
      env: {
        ...process.env,
        PYTHONUNBUFFERED: "1",
      },
      maxBuffer: 8 * 1024 * 1024,
    });

    if (stderr && stderr.trim().length) {
      // homr prints status to stderr in some environments; keep only hard errors.
      const lowered = stderr.toLowerCase();
      if (lowered.includes("traceback") || lowered.includes("error")) {
        throw new Error(stderr.trim());
      }
    }

    let payload: { musicXmlPath?: string; message?: string };
    try {
      payload = JSON.parse(stdout);
    } catch {
      throw new Error(`Could not parse OMR output: ${stdout || stderr}`);
    }
    if (!payload.musicXmlPath) {
      throw new Error(payload.message ?? "OMR provider did not return a MusicXML file.");
    }
    const xmlText = await fs.readFile(payload.musicXmlPath, "utf8");
    await fs.rm(payload.musicXmlPath, { force: true });
    return {
      musicXml: xmlText,
      diagnostics,
      provider: "homr",
    };
  }
}

