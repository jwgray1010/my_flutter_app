import { execFile } from "node:child_process";
import { promises as fs } from "node:fs";
import path from "node:path";
import { promisify } from "node:util";
import sharp from "sharp";

const execFileAsync = promisify(execFile);

/** Audiveris asks for about 300 DPI. Copier PDFs are often 150 DPI, which it ignores. */
export function omrRasterDpi(): number {
  const configured = Number(process.env.AUDIVERIS_PDF_RASTER_DPI);
  if (Number.isFinite(configured) && configured >= 72 && configured <= 600) {
    return Math.round(configured);
  }
  return 300;
}

/**
 * Expands one PDF into ordered page images. Failure stays an ingestion error.
 * The musical interpreter never sees the original PDF as one staff collection.
 */
export async function rasterizePdfPages(pdfPath: string, outputDir: string): Promise<string[]> {
  await fs.mkdir(outputDir, { recursive: true });
  const prefix = path.join(outputDir, "page");
  try {
    await execFileAsync("pdftoppm", ["-r", String(omrRasterDpi()), "-png", pdfPath, prefix], {
      maxBuffer: 32 * 1024 * 1024,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "pdftoppm failed";
    throw new Error(`Could not split the PDF into pages. ${message}`);
  }
  const names = await fs.readdir(outputDir);
  const pages = names
    .filter((name) => /^page-\d+\.png$/i.test(name))
    .sort((left, right) => pageIndex(left) - pageIndex(right))
    .map((name) => path.join(outputDir, name));
  if (!pages.length) {
    throw new Error("Could not split the PDF into pages.");
  }
  return pages;
}

function pageIndex(fileName: string): number {
  const match = /(\d+)\.png$/i.exec(fileName);
  return match ? Number(match[1]) : 0;
}

/**
 * Photocopies are gray, so staff lines are too faint for Audiveris and a
 * later linking step can abort the export. Stretching contrast keeps the
 * printed music and lets that page export.
 */
export async function preparePageForOmr(sourcePath: string, outputPath: string): Promise<string> {
  await fs.mkdir(path.dirname(outputPath), { recursive: true });
  await sharp(sourcePath).rotate().grayscale().normalise().png().toFile(outputPath);
  return outputPath;
}
