import type { CanonicalPartId, PartRole, RecognizedPart } from "@/lib/score-types";

const VOICING_LETTER: Partial<Record<CanonicalPartId, string>> = {
  SOPRANO: "S",
  ALTO: "A",
  TENOR: "T",
  BARITONE: "B",
  BASS: "B",
};

export function isFeaturedName(sourceName: string) {
  return /\b(solo|descant|cue|optional|featured)\b|small group/i.test(sourceName);
}

export function isGenericPartName(sourceName: string) {
  const normalized = sourceName.toLowerCase().replace(/\./g, " ").replace(/\s+/g, " ").trim();
  return /^(part|voice)\s+([0-9]+|[ivx]+)$/.test(normalized);
}

export function partRoleOf(part: RecognizedPart): PartRole {
  if (part.partRole) {
    return part.partRole;
  }
  if (part.canonicalPart === "PIANO" || /\b(piano|accompaniment|accomp|keyboard|organ)\b/i.test(part.sourceName)) {
    return "ACCOMPANIMENT";
  }
  if (isFeaturedName(part.sourceName)) {
    return "FEATURED";
  }
  return "CHOIR";
}

/**
 * Voicing keeps one letter per printed choir part, in staff order.
 * Soprano I and Soprano II stay SSA. Solo and descant lines are excluded.
 * Generic "Part I / Part II" labels stay N-PART instead of becoming SATB.
 */
export function deriveMainChoirVoicing(parts: RecognizedPart[]): string {
  const choir = parts.filter((part) => partRoleOf(part) === "CHOIR");
  if (!choir.length) {
    return "NONE";
  }
  if (choir.length === 1 && /\bunison\b/i.test(choir[0].sourceName)) {
    return "UNISON";
  }
  if (choir.every((part) => isGenericPartName(part.sourceName))) {
    return choir.length === 1 ? "UNISON" : `${choir.length}-PART`;
  }
  if (choir.some((part) => part.canonicalPart === "UNKNOWN" || part.canonicalPart === "PIANO")) {
    return "NEEDS CONFIRMATION";
  }
  return choir.map((part) => VOICING_LETTER[part.canonicalPart] ?? "").join("");
}

export function scoreTextureLabel(parts: RecognizedPart[]): string {
  const voicing = deriveMainChoirVoicing(parts);
  const hasPiano = parts.some((part) => partRoleOf(part) === "ACCOMPANIMENT");
  if (hasPiano && voicing !== "NONE") {
    return `${voicing} + Piano`;
  }
  if (hasPiano) {
    return "Piano";
  }
  return voicing;
}
