import { NextResponse } from "next/server";
import { listSavedScores } from "@/lib/server/my-music-db";

export const runtime = "nodejs";

export async function GET() {
  const items = listSavedScores();
  return NextResponse.json({ items });
}

