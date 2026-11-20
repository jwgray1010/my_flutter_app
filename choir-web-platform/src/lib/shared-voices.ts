import type { CanonicalPartId, NoteEvent, ParsedScore, RecognizedPart } from "@/lib/score-types";

export type SharedPlacement = "independent" | "unison" | "resting" | "ambiguous";

export interface UnisonSpan {
  staff: number;
  startBeat: number;
  endBeat: number | null;
}

/** Named shared staff, in voice-number order. Pitch never decides which role is which. */
export function pairedVoiceRoles(sourceName: string): [CanonicalPartId, CanonicalPartId] | null {
  const normalized = sourceName.toLowerCase().replace(/[.\s]+/g, " ").trim();
  const pairs: Array<{ pattern: RegExp; roles: [CanonicalPartId, CanonicalPartId] }> = [
    { pattern: /soprano\s*[12i]+.*soprano|s\s*1\s*\/\s*s\s*2|soprano\s*\/\s*soprano/, roles: ["SOPRANO", "SOPRANO"] },
    { pattern: /alto\s*[12i]+.*alto|a\s*1\s*\/\s*a\s*2|alto\s*\/\s*alto/, roles: ["ALTO", "ALTO"] },
    { pattern: /tenor\s*[12i]+.*tenor|t\s*1\s*\/\s*t\s*2|tenor\s*\/\s*tenor/, roles: ["TENOR", "TENOR"] },
    { pattern: /bass\s*[12i]+.*bass|b\s*1\s*\/\s*b\s*2|bass\s*\/\s*bass/, roles: ["BASS", "BASS"] },
    { pattern: /soprano.*alto|s\s*\/\s*a\b|^s a$|^sa$/, roles: ["SOPRANO", "ALTO"] },
    { pattern: /tenor.*bass|t\s*\/\s*b\b|^t b$|^tb$/, roles: ["TENOR", "BASS"] },
  ];
  for (const pair of pairs) {
    if (pair.pattern.test(normalized)) {
      return pair.roles;
    }
  }
  return null;
}

export function rolesForSharedStaff(role: string): [CanonicalPartId, CanonicalPartId] | null {
  if (role === "SOPRANO_ALTO") {
    return ["SOPRANO", "ALTO"];
  }
  if (role === "TENOR_BASS") {
    return ["TENOR", "BASS"];
  }
  return null;
}

export function beatInUnison(spans: UnisonSpan[], staff: number, beat: number) {
  return spans.some(
    (span) =>
      span.staff === staff &&
      beat >= span.startBeat - 0.02 &&
      (span.endBeat == null || beat < span.endBeat - 0.02)
  );
}

/** One sounding channel. A unison note plays if either member is selected, and only once. */
export function audibleCanonical(
  note: Pick<NoteEvent, "partCanonical" | "unisonPartIds">,
  parts: RecognizedPart[],
  enabled: ReadonlySet<CanonicalPartId>
): CanonicalPartId | null {
  if (enabled.has(note.partCanonical)) {
    return note.partCanonical;
  }
  for (const id of note.unisonPartIds ?? []) {
    const part = parts.find((item) => item.id === id);
    if (part && enabled.has(part.canonicalPart)) {
      return part.canonicalPart;
    }
  }
  return null;
}

export function restoreUnisonMembership(previous: NoteEvent[], next: NoteEvent[]) {
  for (const note of next) {
    const donor = previous.find(
      (item) =>
        item.partId === note.partId &&
        item.midi === note.midi &&
        Math.abs(item.startBeat - note.startBeat) < 0.02 &&
        (item.unisonPartIds?.length ?? 0) > 0
    );
    if (donor?.unisonPartIds) {
      note.unisonPartIds = [...donor.unisonPartIds];
    }
  }
}

const ROLE_LABEL: Record<CanonicalPartId, string> = {
  SOPRANO: "Soprano",
  ALTO: "Alto",
  TENOR: "Tenor",
  BASS: "Bass",
  PIANO: "Piano",
  UNKNOWN: "Voice",
};

/** Director confirmed a shared staff. Both roles exist. Notes stay on the part that already has them. */
export function ensureDirectorSharedParts(
  score: ParsedScore,
  corrections: Array<{ staffId: string; role: string }>
) {
  for (const correction of corrections) {
    const roles = rolesForSharedStaff(correction.role);
    if (!roles) {
      continue;
    }
    const sourcePartId = correction.staffId.split(":staff:")[0];
    if (!sourcePartId) {
      continue;
    }
    const group = score.parts.filter(
      (part) => part.sourcePartId === sourcePartId && part.canonicalPart !== "PIANO" && !part.isSolo
    );
    if (group.length === 1 && !roles.includes(group[0].canonicalPart)) {
      group[0].canonicalPart = roles[0];
      group[0].voiceNumber = group[0].voiceNumber ?? 1;
      group[0].sharedPlacement = group[0].sharedPlacement ?? "independent";
    }
    roles.forEach((role, index) => {
      if (group.some((part) => part.canonicalPart === role) || score.parts.some((part) => part.canonicalPart === role && part.sourcePartId === sourcePartId)) {
        return;
      }
      const voice = index + 1;
      const preferred = `${sourcePartId}:v${voice}`;
      const id = score.parts.some((part) => part.id === preferred) ? `${sourcePartId}:shared:${role.toLowerCase()}` : preferred;
      score.parts.push({
        id,
        sourceName: `${ROLE_LABEL[role]} (voice ${voice})`,
        canonicalPart: role,
        staves: group[0]?.staves ?? 1,
        sourcePartId,
        voiceNumber: voice,
        needsConfirmation: false,
        isSolo: false,
        sharedPlacement: "resting",
        pitchRangeLow: null,
        pitchRangeHigh: null,
        firstMeasureNumber: null,
        lastMeasureNumber: null,
      });
    });
    for (const part of score.parts.filter((part) => part.sourcePartId === sourcePartId && !part.isSolo)) {
      if (part.canonicalPart !== "PIANO") {
        part.needsConfirmation = false;
      }
    }
  }
}
