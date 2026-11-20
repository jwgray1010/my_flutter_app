"use client";

import type { NotationNote, TieEdit } from "@/lib/score-types";

export function TieReview(props: {
  notes: NotationNote[];
  onSave: (edits: TieEdit[]) => void;
}) {
  const ties = props.notes.filter((note) => note.tieStart || note.tieStop);
  const repeated = adjacentSamePitch(props.notes).filter((pair) => !pair.left.tieStart || !pair.right.tieStop);

  return (
    <div className="mt-4 rounded-xl border border-zinc-700 bg-zinc-900/40 p-4">
      <p className="text-sm font-semibold text-zinc-200">Ties</p>
      <p className="mt-1 text-xs text-zinc-400">
        Playback sustains a tie as one sound. These are the written notes. Saving does not rerun recognition.
      </p>
      {props.notes.length === 0 ? (
        <p className="mt-2 text-sm text-amber-200">Tie detail is not on this saved score. Reprocess it to edit ties.</p>
      ) : null}
      {ties.length > 0 ? (
        <button
          type="button"
          className="mt-3 rounded-lg bg-zinc-700 px-3 py-1 text-xs font-semibold"
          onClick={() =>
            props.onSave(
              ties.map((note) => ({
                sourcePartId: note.sourcePartId,
                voice: note.voice,
                staff: note.staff,
                midi: note.midi,
                startBeat: note.startBeat,
                tieStart: note.tieStart,
                tieStop: note.tieStop,
              }))
            )
          }
        >
          Confirm tie chains
        </button>
      ) : null}
      <ul className="mt-3 space-y-2 text-sm">
        {ties.map((note) => (
          <li key={noteKey(note)} className="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-zinc-700 px-3 py-2">
            <span>
              m.{note.measureNumber} voice {note.voice} pitch {note.midi} · {note.durationBeats} beats ·{" "}
              {note.tieStart && note.tieStop ? "continue" : note.tieStart ? "start" : "stop"}
            </span>
            <button
              type="button"
              className="rounded-lg bg-zinc-700 px-3 py-1 text-xs font-semibold"
              onClick={() => props.onSave([{ ...note, tieStart: false, tieStop: false }])}
            >
              Remove tie
            </button>
          </li>
        ))}
        {repeated.map((pair) => (
          <li key={`${noteKey(pair.left)}-next`} className="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-amber-800 px-3 py-2">
            <span>
              m.{pair.left.measureNumber} voice {pair.left.voice} pitch {pair.left.midi} is not tied to the next same pitch.
            </span>
            <button
              type="button"
              className="rounded-lg bg-cyan-400 px-3 py-1 text-xs font-semibold text-black"
              onClick={() =>
                props.onSave([
                  { ...pair.left, tieStart: true, tieStop: pair.left.tieStop },
                  { ...pair.right, tieStart: pair.right.tieStart, tieStop: true },
                ])
              }
            >
              Add tie
            </button>
          </li>
        ))}
        {ties.length === 0 && repeated.length === 0 && props.notes.length > 0 ? (
          <li className="text-zinc-400">No ties detected.</li>
        ) : null}
      </ul>
    </div>
  );
}

function adjacentSamePitch(notes: NotationNote[]) {
  const ordered = [...notes].sort((left, right) => left.startBeat - right.startBeat);
  const pairs: Array<{ left: NotationNote; right: NotationNote }> = [];
  for (let index = 0; index < ordered.length - 1; index += 1) {
    const left = ordered[index];
    const right = ordered[index + 1];
    const adjacent = Math.abs(left.startBeat + left.durationBeats - right.startBeat) < 0.02;
    if (
      left.sourcePartId === right.sourcePartId &&
      left.voice === right.voice &&
      left.staff === right.staff &&
      left.midi === right.midi &&
      adjacent
    ) {
      pairs.push({ left, right });
    }
  }
  return pairs;
}

function noteKey(note: NotationNote) {
  return `${note.sourcePartId}:${note.voice}:${note.staff}:${note.midi}:${note.startBeat}`;
}
