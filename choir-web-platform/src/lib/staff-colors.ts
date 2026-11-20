import type { RecognizedPart } from "@/lib/score-types";

/** Physical-staff colors. These describe the printed staff, not a new part. */
export const STAFF_ROLES = [
  "SOPRANO_ALTO",
  "TENOR_BASS",
  "SOPRANO",
  "ALTO",
  "TENOR",
  "BASS",
  "SOPRANO_1",
  "SOPRANO_2",
  "ALTO_1",
  "ALTO_2",
  "PIANO",
  "SOLO",
  "DESCANT",
  "SMALL_GROUP",
  "IGNORE",
  "CUSTOM",
] as const;

export type StaffRole = (typeof STAFF_ROLES)[number];

export const STAFF_ROLE_COLORS: Record<StaffRole, string> = {
  SOPRANO_ALTO: "#e10600",
  TENOR_BASS: "#1d4ed8",
  SOPRANO: "#f472b6",
  ALTO: "#7e22ce",
  TENOR: "#16a34a",
  BASS: "#ea580c",
  SOPRANO_1: "#f472b6",
  SOPRANO_2: "#f472b6",
  ALTO_1: "#7e22ce",
  ALTO_2: "#7e22ce",
  PIANO: "#eab308",
  IGNORE: "#6b7280",
  SMALL_GROUP: "#92400e",
  SOLO: "#0f766e",
  DESCANT: "#0f766e",
  CUSTOM: "#0f766e",
};

export const STAFF_ROLE_LABELS: Record<StaffRole, string> = {
  SOPRANO_ALTO: "Soprano + Alto",
  TENOR_BASS: "Tenor + Bass",
  SOPRANO: "Soprano",
  ALTO: "Alto",
  TENOR: "Tenor",
  BASS: "Bass",
  SOPRANO_1: "Soprano 1",
  SOPRANO_2: "Soprano 2",
  ALTO_1: "Alto 1",
  ALTO_2: "Alto 2",
  PIANO: "Piano",
  SOLO: "Solo",
  DESCANT: "Descant",
  SMALL_GROUP: "Optional Small Group",
  IGNORE: "Ignore",
  CUSTOM: "Custom",
};

export type StaffCorrectionScope = "system" | "layout" | "matching";

export interface StaffCorrection {
  staffId: string;
  role: StaffRole;
  scope: StaffCorrectionScope;
  /** Null when the score has no detected system boundaries. */
  systemId: string | null;
  layoutKey: string | null;
  customColor: string | null;
  customLabel: string | null;
}

export interface StaffMarkerPosition {
  page: number;
  /** 0–1 from the left of the page image. */
  x: number;
  /** 0–1 from the top of the page image. */
  y: number;
  height: number;
}

export interface StaffMarker {
  staffId: string;
  sourcePartId: string;
  staffNumber: number;
  logicalPartIds: string[];
  role: StaffRole;
  color: string;
  label: string;
  source: "detected" | "director";
  confidence: "confirmed" | "needs-review";
  position: StaffMarkerPosition | null;
  /** Pink/purple (or tenor/bass) voice marks. Empty while the staff is in unison. */
  innerVoices: Array<{ label: string; color: string }>;
}

const CHOIR = new Set(["SOPRANO", "ALTO", "TENOR", "BASS"]);

export function buildStaffMarkers(
  parts: RecognizedPart[],
  corrections: StaffCorrection[] = [],
  positions: StaffMarkerPositionById = {}
): StaffMarker[] {
  const grouped = new Map<string, { sourcePartId: string; staffNumber: number; parts: RecognizedPart[] }>();
  for (const part of parts) {
    for (const staffNumber of staffNumbersOf(part)) {
      const staffId = physicalStaffId(part.sourcePartId, staffNumber);
      const group = grouped.get(staffId) ?? {
        sourcePartId: part.sourcePartId,
        staffNumber,
        parts: [],
      };
      if (!group.parts.some((item) => item.id === part.id)) {
        group.parts.push(part);
      }
      grouped.set(staffId, group);
    }
  }

  const markers: StaffMarker[] = [];
  for (const [staffId, group] of grouped) {
    const correction = corrections.find((item) => item.staffId === staffId) ?? null;
    const detected = inferRole(group.parts);
    const role = correction?.role ?? detected.role;
    const customizable = isCustomizableRole(role);
    markers.push({
      staffId,
      sourcePartId: group.sourcePartId,
      staffNumber: group.staffNumber,
      logicalPartIds: group.parts.map((part) => part.id),
      role,
      color: customizable && correction?.customColor ? correction.customColor : STAFF_ROLE_COLORS[role],
      label: correction?.customLabel?.trim() || STAFF_ROLE_LABELS[role],
      source: correction ? "director" : "detected",
      confidence: correction ? "confirmed" : detected.confidence,
      position: positions[staffId] ?? null,
      innerVoices: innerVoicesFor(role, group.parts),
    });
  }
  return markers.sort(
    (left, right) =>
      left.sourcePartId.localeCompare(right.sourcePartId) || left.staffNumber - right.staffNumber
  );
}

export interface StaffMarkerPositionById {
  [staffId: string]: StaffMarkerPosition;
}

/**
 * A single choir role can update the existing part assignment.
 * Combined staves, solos, and custom labels stay on the overlay.
 */
export function canonicalAssignmentForRole(role: StaffRole): "SOPRANO" | "ALTO" | "TENOR" | "BASS" | "PIANO" | "IGNORE" | null {
  if (role === "SOPRANO" || role === "SOPRANO_1" || role === "SOPRANO_2") {
    return "SOPRANO";
  }
  if (role === "ALTO" || role === "ALTO_1" || role === "ALTO_2") {
    return "ALTO";
  }
  if (role === "TENOR") {
    return "TENOR";
  }
  if (role === "BASS") {
    return "BASS";
  }
  if (role === "PIANO") {
    return "PIANO";
  }
  if (role === "IGNORE") {
    return "IGNORE";
  }
  return null;
}

export function physicalStaffId(sourcePartId: string, staffNumber: number) {
  return `${sourcePartId}:staff:${staffNumber}`;
}

export function isCustomizableRole(role: StaffRole) {
  return role === "SOLO" || role === "DESCANT" || role === "SMALL_GROUP" || role === "CUSTOM";
}

function staffNumbersOf(part: RecognizedPart): number[] {
  const fromId = part.id.match(/:s(\d+)(?::|$)/);
  if (fromId) {
    return [Number(fromId[1])];
  }
  if (part.canonicalPart === "PIANO" && part.staves > 1) {
    return Array.from({ length: part.staves }, (_, index) => index + 1);
  }
  return [1];
}

function inferRole(parts: RecognizedPart[]): { role: StaffRole; confidence: "confirmed" | "needs-review" } {
  const needsReview = parts.some((part) => part.needsConfirmation || part.canonicalPart === "UNKNOWN");
  if (parts.some((part) => part.canonicalPart === "PIANO")) {
    return { role: "PIANO", confidence: needsReview ? "needs-review" : "confirmed" };
  }
  const solos = parts.filter((part) => part.isSolo);
  const choir = parts.filter((part) => CHOIR.has(part.canonicalPart) && !part.isSolo);
  if (!choir.length && solos.length) {
    const name = solos.map((part) => part.sourceName).join(" ");
    return {
      role: /\bdescant\b/i.test(name) ? "DESCANT" : "SOLO",
      confidence: needsReview ? "needs-review" : "confirmed",
    };
  }
  if (!choir.length) {
    return { role: "IGNORE", confidence: "needs-review" };
  }
  const roles = [...new Set(choir.map((part) => part.canonicalPart))];
  let role: StaffRole = "IGNORE";
  if (roles.length === 2 && roles.includes("SOPRANO") && roles.includes("ALTO")) {
    role = "SOPRANO_ALTO";
  } else if (roles.length === 2 && roles.includes("TENOR") && roles.includes("BASS")) {
    role = "TENOR_BASS";
  } else if (roles.length === 1 && roles[0] === "SOPRANO") {
    role = numberedRole(choir, "SOPRANO", "SOPRANO_1", "SOPRANO_2");
  } else if (roles.length === 1 && roles[0] === "ALTO") {
    role = numberedRole(choir, "ALTO", "ALTO_1", "ALTO_2");
  } else if (roles.length === 1 && roles[0] === "TENOR") {
    role = "TENOR";
  } else if (roles.length === 1 && roles[0] === "BASS") {
    role = "BASS";
  } else {
    return { role: "IGNORE", confidence: "needs-review" };
  }
  return { role, confidence: needsReview ? "needs-review" : "confirmed" };
}

function innerVoicesFor(role: StaffRole, parts: RecognizedPart[]): Array<{ label: string; color: string }> {
  if (role !== "SOPRANO_ALTO" && role !== "TENOR_BASS") {
    return [];
  }
  if (parts.length < 2) {
    return [];
  }
  const placements = parts.map((part) => part.sharedPlacement);
  const marked = placements.some((placement) => placement != null);
  if (marked && placements.every((placement) => placement === "unison" || placement === "ambiguous")) {
    return [];
  }
  if (marked && !placements.some((placement) => placement === "independent" || placement === "resting")) {
    return [];
  }
  if (role === "SOPRANO_ALTO") {
    return [
      { label: "Soprano", color: STAFF_ROLE_COLORS.SOPRANO },
      { label: "Alto", color: STAFF_ROLE_COLORS.ALTO },
    ];
  }
  return [
    { label: "Tenor", color: STAFF_ROLE_COLORS.TENOR },
    { label: "Bass", color: STAFF_ROLE_COLORS.BASS },
  ];
}

function numberedRole(
  parts: RecognizedPart[],
  single: StaffRole,
  first: StaffRole,
  second: StaffRole
): StaffRole {
  const name = parts.map((part) => part.sourceName).join(" ");
  if (/\b(ii|2)\b/i.test(name)) {
    return second;
  }
  if (/\b(i|1)\b/i.test(name) && parts.length === 1) {
    return first;
  }
  return single;
}
