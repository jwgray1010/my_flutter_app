import { NextResponse } from "next/server";
import {
  deleteSavedScore,
  getSavedScoreById,
  renameSavedScore,
  updateDirectorPartAssignments,
  updateLastTempoPercent,
} from "@/lib/server/my-music-db";
import type { CanonicalPartId } from "@/lib/score-types";

export const runtime = "nodejs";

export async function GET(
  _request: Request,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params;
  const item = getSavedScoreById(id);
  if (!item) {
    return NextResponse.json({ message: "Score not found." }, { status: 404 });
  }
  return NextResponse.json({ item });
}

export async function PATCH(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params;
  const existing = getSavedScoreById(id);
  if (!existing) {
    return NextResponse.json({ message: "Score not found." }, { status: 404 });
  }

  const body = (await request.json()) as
    | {
        action: "rename";
        title: string;
      }
    | {
        action: "updateTempo";
        tempoPercent: number;
      }
    | {
        action: "updateAssignments";
        assignments: Record<string, CanonicalPartId>;
      };

  if (body.action === "rename") {
    const title = body.title?.trim();
    if (!title) {
      return NextResponse.json({ message: "Title cannot be empty." }, { status: 400 });
    }
    renameSavedScore(id, title);
  } else if (body.action === "updateTempo") {
    updateLastTempoPercent(id, body.tempoPercent);
  } else if (body.action === "updateAssignments") {
    updateDirectorPartAssignments(id, body.assignments);
  }

  const updated = getSavedScoreById(id);
  return NextResponse.json({ item: updated });
}

export async function DELETE(
  _request: Request,
  context: { params: Promise<{ id: string }> }
) {
  const { id } = await context.params;
  const existing = getSavedScoreById(id);
  if (!existing) {
    return NextResponse.json({ message: "Score not found." }, { status: 404 });
  }
  deleteSavedScore(id);
  return NextResponse.json({ ok: true });
}

