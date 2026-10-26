import type { CanonicalPartId, NoteEvent, RecognizedPart } from "@/lib/score-types";

const VOICING_BY_COUNTS: Record<string, string> = {
  "1,1,0,0": "SA",
  "2,1,0,0": "SSA",
  "2,2,0,0": "SSAA",
  "3,1,0,0": "SSSA",
  "1,1,1,1": "SATB",
  "2,2,2,2": "SSAATTBB",
  "1,1,0,1": "SAB",
  "1,1,1,0": "SAT",
  "1,0,0,1": "SB",
  "0,0,1,1": "TB",
  "0,0,2,2": "TTBB",
  "0,0,2,1": "TTB",
  "0,0,1,2": "TBB",
  "2,0,0,0": "SS",
  "0,2,0,0": "AA",
};

/**
 * Assigns unnamed choir voices by register instead of filling leftover SATB slots.
 * A treble trio becomes SSA. A low quartet becomes TTBB. Solos are not counted
 * as extra choir sections.
 */
export function assignChoirRegisters(parts: RecognizedPart[], notes: NoteEvent[]) {
  const midiByPart = new Map<string, number[]>();
  for (const note of notes) {
    const list = midiByPart.get(note.partId) ?? [];
    list.push(note.midi);
    midiByPart.set(note.partId, list);
  }
  const medianOf = (part: RecognizedPart) => median(midiByPart.get(part.id) ?? []);
  const highOf = (part: RecognizedPart) => {
    const values = midiByPart.get(part.id) ?? [];
    return values.length ? Math.max(...values) : 0;
  };

  for (const part of parts) {
    if (part.canonicalPart === "PIANO" || !part.isSolo || part.canonicalPart !== "UNKNOWN") {
      continue;
    }
    part.canonicalPart = soloRole(medianOf(part), highOf(part));
    part.needsConfirmation = true;
  }

  const choir = parts.filter((part) => part.canonicalPart !== "PIANO" && !part.isSolo);
  const treble = choir
    .filter((part) => medianOf(part) >= 60)
    .sort((a, b) => medianOf(b) - medianOf(a));
  const lower = choir
    .filter((part) => medianOf(part) < 60)
    .sort((a, b) => medianOf(b) - medianOf(a));
  assignGroup(treble, trebleRoles(treble.length));
  assignGroup(lower, lowerRoles(lower, medianOf, highOf));
}

export function inferChoirVoicing(parts: RecognizedPart[]): string {
  const solos = parts.filter((part) => part.isSolo);
  const choir = parts.filter((part) => part.canonicalPart !== "PIANO" && !part.isSolo);
  let label = "Unknown";
  if (!choir.length) {
    label = parts.some((part) => part.canonicalPart === "PIANO") ? "Piano" : "Unknown";
  } else if (choir.some((part) => part.canonicalPart === "UNKNOWN")) {
    label = "Unknown";
  } else if (choir.length === 1) {
    label = "Unison";
  } else {
    const counts = { SOPRANO: 0, ALTO: 0, TENOR: 0, BASS: 0 };
    for (const part of choir) {
      if (
        part.canonicalPart === "SOPRANO" ||
        part.canonicalPart === "ALTO" ||
        part.canonicalPart === "TENOR" ||
        part.canonicalPart === "BASS"
      ) {
        counts[part.canonicalPart] += 1;
      }
    }
    const key = `${counts.SOPRANO},${counts.ALTO},${counts.TENOR},${counts.BASS}`;
    label = VOICING_BY_COUNTS[key] ?? voicedInitials(counts);
  }
  if (solos.length) {
    return `${label} + Solo`;
  }
  return label;
}

function assignGroup(group: RecognizedPart[], roles: CanonicalPartId[]) {
  const remaining = [...roles];
  for (const part of group) {
    if (part.canonicalPart === "UNKNOWN") {
      continue;
    }
    const index = remaining.indexOf(part.canonicalPart);
    if (index >= 0) {
      remaining.splice(index, 1);
    }
  }
  for (const part of group) {
    if (part.canonicalPart !== "UNKNOWN") {
      continue;
    }
    const role = remaining.shift();
    if (!role) {
      continue;
    }
    part.canonicalPart = role;
    part.needsConfirmation = true;
  }
}

function trebleRoles(count: number): CanonicalPartId[] {
  if (count <= 1) {
    return ["SOPRANO"];
  }
  if (count === 2) {
    return ["SOPRANO", "ALTO"];
  }
  if (count === 3) {
    return ["SOPRANO", "SOPRANO", "ALTO"];
  }
  return ["SOPRANO", "SOPRANO", "ALTO", "ALTO"];
}

function lowerRoles(
  group: RecognizedPart[],
  medianOf: (part: RecognizedPart) => number,
  highOf: (part: RecognizedPart) => number
): CanonicalPartId[] {
  if (group.length <= 1) {
    const part = group[0];
    if (!part) {
      return [];
    }
    const middle = medianOf(part);
    const high = highOf(part);
    if (middle >= 53 && high >= 57) {
      return ["TENOR"];
    }
    return ["BASS"];
  }
  if (group.length === 2) {
    return ["TENOR", "BASS"];
  }
  if (group.length === 3) {
    const second = medianOf(group[1]);
    return second < 52 ? ["TENOR", "BASS", "BASS"] : ["TENOR", "TENOR", "BASS"];
  }
  return ["TENOR", "TENOR", "BASS", "BASS"];
}

function soloRole(middle: number, high: number): CanonicalPartId {
  if (middle >= 60) {
    return "SOPRANO";
  }
  if (middle >= 53 && high >= 57) {
    return "TENOR";
  }
  return "BASS";
}

function voicedInitials(counts: { SOPRANO: number; ALTO: number; TENOR: number; BASS: number }): string {
  const chunks: string[] = [];
  if (counts.SOPRANO) chunks.push("S".repeat(counts.SOPRANO));
  if (counts.ALTO) chunks.push("A".repeat(counts.ALTO));
  if (counts.TENOR) chunks.push("T".repeat(counts.TENOR));
  if (counts.BASS) chunks.push("B".repeat(counts.BASS));
  return chunks.join("") || "Unknown";
}

function median(values: number[]): number {
  if (!values.length) {
    return 64;
  }
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.floor(sorted.length / 2)];
}
