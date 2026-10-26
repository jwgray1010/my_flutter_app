import sharp from "sharp";
import type { OMRDiagnostics } from "@/lib/score-types";

export async function analyzeImageQuality(imagePath: string): Promise<OMRDiagnostics> {
  const image = sharp(imagePath).greyscale();
  const metadata = await image.metadata();
  const { data, info } = await image
    .resize({ width: 900, withoutEnlargement: true })
    .raw()
    .toBuffer({ resolveWithObject: true });

  const width = info.width;
  const height = info.height;
  const pixels = data;
  const pixelCount = Math.max(1, width * height);

  let mean = 0;
  for (let i = 0; i < pixels.length; i += 1) {
    mean += pixels[i];
  }
  mean /= pixelCount;

  let variance = 0;
  let brightCount = 0;
  let edgeEnergy = 0;
  for (let y = 1; y < height - 1; y += 1) {
    for (let x = 1; x < width - 1; x += 1) {
      const idx = y * width + x;
      const px = pixels[idx];
      const diff = px - mean;
      variance += diff * diff;
      if (px > 245) {
        brightCount += 1;
      }
      const lap =
        4 * px -
        pixels[idx - 1] -
        pixels[idx + 1] -
        pixels[idx - width] -
        pixels[idx + width];
      edgeEnergy += Math.abs(lap);
    }
  }

  variance /= pixelCount;
  edgeEnergy /= pixelCount;
  const blurScore = clamp01(edgeEnergy / 42);
  const contrastScore = clamp01(Math.sqrt(variance) / 64);
  const glareScore = 1 - clamp01(brightCount / (pixelCount * 0.12));

  const aspect = width / Math.max(1, height);
  const expectedMin = 0.55;
  const expectedMax = 1.9;
  const perspectiveScore =
    aspect >= expectedMin && aspect <= expectedMax
      ? 0.9
      : clamp01(1 - Math.min(Math.abs(aspect - 1), 1));

  const warnings: string[] = [];
  if (blurScore < 0.45) {
    warnings.push("Image appears blurry. Retake for better note recognition.");
  }
  if (contrastScore < 0.4) {
    warnings.push("Low contrast detected. Improve lighting or crop tighter.");
  }
  if (glareScore < 0.55) {
    warnings.push("Strong glare/shadow detected. Reposition and retake.");
  }
  if (perspectiveScore < 0.45) {
    warnings.push("Perspective may be too skewed. Keep camera square to page.");
  }
  if ((metadata.width ?? 0) < 1200) {
    warnings.push("Higher-resolution photo recommended for best OMR result.");
  }

  const confidence =
    0.38 * blurScore +
    0.28 * contrastScore +
    0.2 * glareScore +
    0.14 * perspectiveScore;

  return {
    lowConfidence: confidence < 0.56,
    warnings,
    quality: {
      blurScore: round2(blurScore),
      contrastScore: round2(contrastScore),
      glareScore: round2(glareScore),
      perspectiveScore: round2(perspectiveScore),
    },
  };
}

function clamp01(value: number) {
  if (!Number.isFinite(value)) {
    return 0;
  }
  return Math.max(0, Math.min(1, value));
}

function round2(value: number) {
  return Math.round(value * 100) / 100;
}

