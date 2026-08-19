import { NextResponse } from "next/server";
import {
  deleteSavedScore,
  getSavedScoreById,
  renameSavedScore,
  updateSavedScoreContent,
  updateLastTempoPercent,
} from "@/lib/server/my-music-db";
import {
  applyManualCorrections,
  normalizeManualCorrections,
  upsertMeasurePartEdit,
} from "@/lib/score-corrections";
import type { AssignablePartId, MeasurePartEditEvent } from "@/lib/score-types";

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
        assignments: Record<string, AssignablePartId>;
      }
    | {
        action: "setMeasureNumberAnchor";
        internalIndex: number;
        displayNumber: number;
      }
    | {
        action: "flagMeasureBoundary";
        measureInternalIndex: number;
        note: string;
      }
    | {
        action: "saveMeasurePartEvents";
        partId: string;
        measureInternalIndex: number;
        events: MeasurePartEditEvent[];
      };

  if (body.action === "rename") {
    const title = body.title?.trim();
    if (!title) {
      return NextResponse.json({ message: "Title cannot be empty." }, { status: 400 });
    }
    renameSavedScore(id, title);
  } else if (body.action === "updateTempo") {
    updateLastTempoPercent(id, body.tempoPercent);
  } else {
    const corrections = normalizeManualCorrections(existing.manualCorrections);

    if (body.action === "updateAssignments") {
      corrections.partAssignments = {
        ...corrections.partAssignments,
        ...body.assignments,
      };
    }

    if (body.action === "setMeasureNumberAnchor") {
      corrections.measureNumberAnchor = {
        internalIndex: Math.max(0, Math.round(body.internalIndex)),
        displayNumber: Math.max(1, Math.round(body.displayNumber)),
      };
    }

    if (body.action === "flagMeasureBoundary") {
      const measure = existing.parsedScore.measures.find(
        (candidate) => candidate.internalIndex === body.measureInternalIndex
      );
      if (!measure) {
        return NextResponse.json({ message: "Measure was not found." }, { status: 400 });
      }
      corrections.boundaryFlags = [
        ...corrections.boundaryFlags,
        {
          measureInternalIndex: measure.internalIndex,
          measureDisplayNumber: measure.displayNumber,
          note: body.note?.trim() || "Measure boundary needs review.",
          createdAt: new Date().toISOString(),
        },
      ];
    }

    if (body.action === "saveMeasurePartEvents") {
      corrections.measurePartEdits = upsertMeasurePartEdit(corrections, {
        partId: body.partId,
        measureInternalIndex: body.measureInternalIndex,
        events: body.events,
        updatedAt: new Date().toISOString(),
      }).measurePartEdits;
    }

    const parsedScore = applyManualCorrections(existing.baseParsedScore, corrections);
    const confirmedAssignments = Object.fromEntries(
      parsedScore.parts.map((part) => [
        part.id,
        corrections.partAssignments[part.id] ?? part.canonicalPart,
      ])
    );
    updateSavedScoreContent(id, {
      parsedScore: {
        ...parsedScore,
        title: existing.title,
      },
      directorConfirmedPartAssignments: confirmedAssignments,
      manualCorrections: corrections,
    });
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

