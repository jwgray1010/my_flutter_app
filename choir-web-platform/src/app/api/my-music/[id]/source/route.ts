import { createReadStream } from "node:fs";
import { access } from "node:fs/promises";
import path from "node:path";
import { Readable } from "node:stream";
import { NextResponse } from "next/server";
import { getSavedScoreById } from "@/lib/server/my-music-db";

export const runtime = "nodejs";

const IMAGE_TYPES = new Set(["image/jpeg", "image/png", "image/jpg", "image/webp"]);

export async function GET(
  _request: Request,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params;
  const score = getSavedScoreById(id);
  if (!score || !IMAGE_TYPES.has(score.sourceMimeType)) {
    return NextResponse.json({ message: "No score image is available." }, { status: 404 });
  }
  const uploadsDir = path.resolve(process.cwd(), "data", "uploads");
  const filePath = path.resolve(score.sourceFilePath);
  if (filePath !== uploadsDir && !filePath.startsWith(`${uploadsDir}${path.sep}`)) {
    return NextResponse.json({ message: "Score image path is not available." }, { status: 404 });
  }
  try {
    await access(filePath);
  } catch {
    return NextResponse.json({ message: "Score image file is missing." }, { status: 404 });
  }
  const stream = createReadStream(filePath);
  return new NextResponse(Readable.toWeb(stream) as ReadableStream, {
    headers: {
      "Content-Type": score.sourceMimeType === "image/jpg" ? "image/jpeg" : score.sourceMimeType,
      "Cache-Control": "private, max-age=3600",
    },
  });
}
