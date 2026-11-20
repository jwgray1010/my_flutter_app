import { featureFlags } from "@/lib/feature-flags";
import type { NotationNote, NoteEvent, RecognizedPart } from "@/lib/score-types";
import { secondsBetween, type TempoPoint } from "@/lib/tempo-control";

export interface TieCarrier {
  voice: number;
  staff: number;
  midi: number;
  startBeat: number;
  durationBeats: number;
  measureNumber: number;
  tieStart: boolean;
  tieStop: boolean;
}

const ADJACENT = 0.02;

/**
 * Combine tied notes into one playback sound.
 * Written notes are not modified. Slurs are ignored because they never set tie flags.
 * A tie must match voice, pitch, and either the next onset or a same-onset chord continuation.
 */
export function mergeTiedNotes<T extends TieCarrier>(notes: T[]): T[] {
  if (!featureFlags.tiePlaybackV2) {
    return mergeTiedNotesInFileOrder(notes);
  }
  const ordered = notes
    .map((note, index) => ({ note, index }))
    .sort((left, right) => left.note.startBeat - right.note.startBeat || left.index - right.index);
  const consumed = new Set<number>();
  const merged: T[] = [];
  const open = new Map<string, T>();

  for (const item of ordered) {
    if (consumed.has(item.index)) {
      continue;
    }
    const note: T = { ...item.note };
    const key = tieKey(note);
    const previous = open.get(key);
    if (previous && note.tieStop && previous.tieStart && continues(previous, note)) {
      previous.durationBeats += note.durationBeats;
      previous.tieStart = note.tieStart;
      if (!note.tieStart) {
        open.delete(key);
      }
      continue;
    }
    if (note.tieStop && !note.tieStart && laterSameOnsetStart(ordered, item.index, key, note.startBeat, consumed)) {
      continue;
    }
    if (note.tieStart) {
      const partner = ordered.find(
        (other) =>
          other.index !== item.index &&
          !consumed.has(other.index) &&
          other.note.tieStop &&
          tieKey(other.note) === key &&
          Math.abs(other.note.startBeat - note.startBeat) < ADJACENT
      );
      if (partner) {
        note.durationBeats += partner.note.durationBeats;
        note.tieStart = partner.note.tieStart;
        consumed.add(partner.index);
      }
    }
    merged.push(note);
    if (note.tieStart) {
      open.set(key, note);
    } else {
      open.delete(key);
    }
  }
  return merged;
}

export function playbackNotesFromNotation(notation: NotationNote[], parts: RecognizedPart[]): NoteEvent[] {
  const bySource = new Map<string, NotationNote[]>();
  for (const note of notation) {
    const list = bySource.get(note.sourcePartId) ?? [];
    list.push(note);
    bySource.set(note.sourcePartId, list);
  }
  const events: NoteEvent[] = [];
  for (const [sourcePartId, written] of bySource) {
    for (const note of mergeTiedNotes(written)) {
      const part = partFor(parts, sourcePartId, note.voice);
      if (!part) {
        continue;
      }
      events.push({
        partId: part.id,
        partCanonical: part.canonicalPart,
        midi: note.midi,
        startBeat: note.startBeat,
        durationBeats: note.durationBeats,
        measureNumber: note.measureNumber,
        velocity: part.canonicalPart === "PIANO" ? 0.72 : 0.82,
      });
    }
  }
  return events.sort((left, right) => left.startBeat - right.startBeat || left.midi - right.midi);
}

export interface ScheduledAttack {
  partId: string;
  midi: number;
  startBeat: number;
  durationBeats: number;
  noteOnCount: number;
  noteOffBeat: number;
  durationSeconds: number;
}

/** One NoteOn and one NoteOff per playback note. Duration stays in beats until this clock conversion. */
export function scheduleAttacks(
  notes: Array<Pick<NoteEvent, "partId" | "midi" | "startBeat" | "durationBeats">>,
  tempo: { points: TempoPoint[]; fallbackBpm: number; percent: number } = {
    points: [],
    fallbackBpm: 60,
    percent: 100,
  }
): ScheduledAttack[] {
  return notes.map((note) => ({
    partId: note.partId,
    midi: note.midi,
    startBeat: note.startBeat,
    durationBeats: note.durationBeats,
    noteOnCount: 1,
    noteOffBeat: note.startBeat + note.durationBeats,
    durationSeconds: secondsBetween(
      note.startBeat,
      note.startBeat + note.durationBeats,
      tempo.points,
      tempo.fallbackBpm,
      tempo.percent
    ),
  }));
}

function mergeTiedNotesInFileOrder<T extends TieCarrier>(notes: T[]): T[] {
  const open = new Map<string, T>();
  const merged: T[] = [];
  for (const note of notes) {
    const key = tieKey(note);
    const previous = open.get(key);
    const adjacent =
      previous != null && Math.abs(previous.startBeat + previous.durationBeats - note.startBeat) < ADJACENT;
    if (note.tieStop && previous?.tieStart && adjacent) {
      previous.durationBeats += note.durationBeats;
      previous.tieStart = note.tieStart;
      if (!note.tieStart) {
        open.delete(key);
      }
      continue;
    }
    const copy = { ...note };
    merged.push(copy);
    if (note.tieStart) {
      open.set(key, copy);
    } else {
      open.delete(key);
    }
  }
  return merged;
}

function tieKey(note: TieCarrier) {
  return `${note.voice}|${note.staff}|${note.midi}`;
}

function laterSameOnsetStart(
  ordered: Array<{ note: TieCarrier; index: number }>,
  index: number,
  key: string,
  startBeat: number,
  consumed: Set<number>
) {
  return ordered.some(
    (other) =>
      other.index > index &&
      !consumed.has(other.index) &&
      other.note.tieStart &&
      tieKey(other.note) === key &&
      Math.abs(other.note.startBeat - startBeat) < ADJACENT
  );
}

function continues(previous: TieCarrier, next: TieCarrier) {
  const adjacent = Math.abs(previous.startBeat + previous.durationBeats - next.startBeat) < ADJACENT;
  const sameOnsetChord = Math.abs(previous.startBeat - next.startBeat) < ADJACENT;
  return adjacent || sameOnsetChord;
}

function partFor(parts: RecognizedPart[], sourcePartId: string, voice: number) {
  return (
    parts.find((part) => part.sourcePartId === sourcePartId && part.voiceNumber === voice) ??
    parts.find((part) => part.sourcePartId === sourcePartId && part.voiceNumber == null) ??
    parts.find((part) => part.sourcePartId === sourcePartId)
  );
}
