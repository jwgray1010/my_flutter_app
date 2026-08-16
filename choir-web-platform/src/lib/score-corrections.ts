import { populatePartRanges } from "@/lib/musicxml";
import type {
  AssignablePartId,
  CanonicalPartId,
  ManualScoreCorrections,
  MeasurePartEditCorrection,
  ParsedScore,
} from "@/lib/score-types";

export function emptyManualCorrections(): ManualScoreCorrections {
  return {
    partAssignments: {},
    measureNumberAnchor: null,
    boundaryFlags: [],
    measurePartEdits: [],
  };
}

export function normalizeManualCorrections(raw: unknown): ManualScoreCorrections {
  if (!raw || typeof raw !== "object") {
    return emptyManualCorrections();
  }
  const candidate = raw as Partial<ManualScoreCorrections>;
  return {
    partAssignments:
      candidate.partAssignments && typeof candidate.partAssignments === "object"
        ? candidate.partAssignments
        : {},
    measureNumberAnchor:
      candidate.measureNumberAnchor &&
      Number.isFinite(candidate.measureNumberAnchor.internalIndex) &&
      Number.isFinite(candidate.measureNumberAnchor.displayNumber)
        ? candidate.measureNumberAnchor
        : null,
    boundaryFlags: Array.isArray(candidate.boundaryFlags) ? candidate.boundaryFlags : [],
    measurePartEdits: Array.isArray(candidate.measurePartEdits) ? candidate.measurePartEdits : [],
  };
}

export function applyManualCorrections(
  baseScore: ParsedScore,
  corrections: ManualScoreCorrections
): ParsedScore {
  const next = cloneScore(baseScore);
  applyPartAssignments(next, corrections.partAssignments);
  applyMeasureNumberAnchor(next, corrections.measureNumberAnchor);
  for (const edit of corrections.measurePartEdits) {
    applyMeasurePartEdit(next, edit);
  }
  next.notes.sort((a, b) => a.startBeat - b.startBeat);
  populatePartRanges(next.parts, next.notes);
  return next;
}

export function upsertMeasurePartEdit(
  corrections: ManualScoreCorrections,
  edit: MeasurePartEditCorrection
) {
  const next: ManualScoreCorrections = {
    ...corrections,
    measurePartEdits: [...corrections.measurePartEdits],
  };
  const existingIndex = next.measurePartEdits.findIndex(
    (entry) =>
      entry.partId === edit.partId && entry.measureInternalIndex === edit.measureInternalIndex
  );
  if (existingIndex >= 0) {
    next.measurePartEdits[existingIndex] = edit;
  } else {
    next.measurePartEdits.push(edit);
  }
  return next;
}

export function applyPartAssignments(
  score: ParsedScore,
  assignments: Record<string, AssignablePartId>
) {
  const partCanonicalMap = new Map<string, CanonicalPartId>();
  for (const part of score.parts) {
    const requested = assignments[part.id];
    if (requested) {
      part.canonicalPart = requested === "IGNORE" ? "UNKNOWN" : requested;
      // A director explicitly chose this mapping, so it's no longer a guess
      // that needs review - unless they deliberately left it unassigned.
      part.needsConfirmation = requested === "UNKNOWN";
    }
    partCanonicalMap.set(part.id, part.canonicalPart);
  }
  for (const note of score.notes) {
    note.partCanonical = partCanonicalMap.get(note.partId) ?? note.partCanonical;
  }
}

export function applyMeasureNumberAnchor(
  score: ParsedScore,
  anchor: ManualScoreCorrections["measureNumberAnchor"]
) {
  if (!anchor) {
    return;
  }
  const anchorMeasure = score.measures.find((measure) => measure.internalIndex === anchor.internalIndex);
  if (!anchorMeasure) {
    return;
  }
  const delta = anchor.displayNumber - anchorMeasure.displayNumber;
  if (delta === 0) {
    return;
  }
  for (const measure of score.measures) {
    if (measure.internalIndex >= anchor.internalIndex) {
      measure.displayNumber += delta;
    }
  }
  relabelNoteMeasureNumbers(score);
}

export function applyMeasurePartEdit(score: ParsedScore, edit: MeasurePartEditCorrection) {
  const part = score.parts.find((candidate) => candidate.id === edit.partId);
  const measure = score.measures.find(
    (candidate) => candidate.internalIndex === edit.measureInternalIndex
  );
  if (!part || !measure) {
    return;
  }

  const isInTarget = (startBeat: number) =>
    startBeat >= measure.startBeat && startBeat < measure.endBeat;

  score.notes = score.notes.filter(
    (note) => !(note.partId === part.id && isInTarget(note.startBeat))
  );

  let cursorBeat = measure.startBeat;
  for (const event of edit.events) {
    const durationBeats = clampDuration(event.durationBeats);
    if (event.kind === "NOTE" && Number.isFinite(event.midi) && event.midi != null) {
      score.notes.push({
        partId: part.id,
        partCanonical: part.canonicalPart,
        midi: Math.max(0, Math.min(127, Math.round(event.midi))),
        startBeat: cursorBeat,
        durationBeats,
        measureNumber: measure.displayNumber,
        velocity: part.canonicalPart === "PIANO" ? 0.72 : 0.82,
      });
    }
    cursorBeat += durationBeats;
    if (cursorBeat > measure.endBeat + 8) {
      break;
    }
  }
}

function relabelNoteMeasureNumbers(score: ParsedScore) {
  for (const note of score.notes) {
    const containing = score.measures.find(
      (measure) => note.startBeat >= measure.startBeat && note.startBeat < measure.endBeat
    );
    if (containing) {
      note.measureNumber = containing.displayNumber;
    }
  }
}

function cloneScore(score: ParsedScore): ParsedScore {
  return {
    ...score,
    parts: score.parts.map((part) => ({ ...part })),
    measures: score.measures.map((measure) => ({ ...measure })),
    notes: score.notes.map((note) => ({ ...note })),
    rehearsalMarks: { ...score.rehearsalMarks },
  };
}

function clampDuration(value: number) {
  if (!Number.isFinite(value)) {
    return 1;
  }
  return Math.max(0.125, Math.min(8, value));
}

