import { execFile } from "node:child_process";
import { promisify } from "node:util";
import sharp from "sharp";
import type { StaffTextFact } from "@/lib/structure-discovery";
import { normalizePrintedLabel } from "@/lib/part-labels";

const execFileAsync = promisify(execFile);

export interface StaffBand {
  top: number;
  bottom: number;
}

/**
 * Read part names from the left side of a page when Audiveris did not put
 * them in MusicXML. Staff bands come from the horizontal staff lines, and a
 * word is kept only when it normalizes to a part label.
 */
export async function recognizeStaffLabels(imagePath: string, _pageNumber: number): Promise<StaffTextFact[]> {
  const available = await tesseractAvailable();
  if (!available) {
    return [];
  }
  const image = sharp(imagePath).grayscale();
  const meta = await image.metadata();
  const width = meta.width ?? 0;
  const height = meta.height ?? 0;
  if (!width || !height) {
    return [];
  }
  const { data } = await image.raw().toBuffer({ resolveWithObject: true });
  const bands = detectStaffBands(width, height, data);
  const marginRight = Math.max(40, staffLineLeft(width, height, data) - 8);
  const marginPath = `${imagePath}.labels.png`;
  await sharp(imagePath).extract({ left: 0, top: 0, width: Math.min(width, marginRight), height }).png().toFile(marginPath);
  let tsv = "";
  try {
    const result = await execFileAsync("tesseract", [marginPath, "stdout", "--psm", "6", "tsv"], {
      maxBuffer: 8 * 1024 * 1024,
    });
    tsv = result.stdout;
  } catch {
    return [];
  }
  const tokens = parseTsvWords(tsv).filter((token) => token.confidence >= 45);
  const facts: StaffTextFact[] = [];
  for (const token of tokens) {
    const label = normalizePrintedLabel(token.text, { allowSingleLetter: false });
    if (!label.accepted) {
      continue;
    }
    const centerX = token.left + token.width / 2;
    const centerY = token.top + token.height / 2;
    if (centerX > width * 0.32) {
      continue;
    }
    const bandIndex = bands.findIndex((band) => centerY >= band.top - 24 && centerY <= band.bottom + 24);
    facts.push({
      partId: "",
      measureNumber: 1,
      measureIndex: 0,
      staff: bandIndex >= 0 ? bandIndex + 1 : null,
      text: token.text,
      defaultX: centerX,
      defaultY: -centerY,
      pageWidth: width,
      systemStart: true,
      source: "ocr",
    });
  }
  return facts;
}

export function staffLineLeft(width: number, height: number, gray: Uint8Array | Buffer): number {
  let left = width;
  for (let y = 0; y < height; y += 1) {
    const row = y * width;
    let run = 0;
    for (let x = 0; x < width; x += 1) {
      if (gray[row + x] < 90) {
        run += 1;
        if (run >= 70) {
          left = Math.min(left, x - 69);
          break;
        }
      } else {
        run = 0;
      }
    }
  }
  return left === width ? Math.floor(width * 0.28) : left;
}

export function detectStaffBands(width: number, height: number, gray: Uint8Array | Buffer): StaffBand[] {
  const darkness: number[] = [];
  for (let y = 0; y < height; y += 1) {
    let dark = 0;
    const row = y * width;
    for (let x = Math.floor(width * 0.2); x < width; x += 1) {
      if (gray[row + x] < 90) {
        dark += 1;
      }
    }
    darkness.push(dark / Math.max(1, width - Math.floor(width * 0.2)));
  }
  const lineRows: number[] = [];
  for (let y = 1; y < height - 1; y += 1) {
    if (darkness[y] >= 0.25 && darkness[y] >= darkness[y - 1] && darkness[y] >= darkness[y + 1]) {
      if (lineRows.length === 0 || y - lineRows[lineRows.length - 1] > 2) {
        lineRows.push(y);
      }
    }
  }
  const bands: StaffBand[] = [];
  let cluster: number[] = [];
  const flush = () => {
    if (cluster.length >= 4) {
      bands.push({ top: cluster[0], bottom: cluster[cluster.length - 1] });
    }
    cluster = [];
  };
  for (const row of lineRows) {
    const previous = cluster[cluster.length - 1];
    if (previous != null && row - previous > 28) {
      flush();
    }
    cluster.push(row);
  }
  flush();
  return bands;
}

export async function tesseractAvailable(): Promise<boolean> {
  try {
    await execFileAsync("tesseract", ["--version"]);
    return true;
  } catch {
    return false;
  }
}

function parseTsvWords(tsv: string) {
  const lines = tsv.split(/\r?\n/);
  const header = lines[0]?.split("\t") ?? [];
  const column = (name: string) => header.indexOf(name);
  const level = column("level");
  const left = column("left");
  const top = column("top");
  const width = column("width");
  const height = column("height");
  const conf = column("conf");
  const text = column("text");
  const words: { text: string; left: number; top: number; width: number; height: number; confidence: number }[] = [];
  for (const line of lines.slice(1)) {
    if (!line.trim()) {
      continue;
    }
    const cells = line.split("\t");
    if (Number(cells[level]) !== 5) {
      continue;
    }
    const value = cells[text]?.trim() ?? "";
    if (!value) {
      continue;
    }
    words.push({
      text: value,
      left: Number(cells[left]),
      top: Number(cells[top]),
      width: Number(cells[width]),
      height: Number(cells[height]),
      confidence: Number(cells[conf]),
    });
  }
  return words;
}
