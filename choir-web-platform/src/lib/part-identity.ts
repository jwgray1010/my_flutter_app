import { isStaffLabelPosition, normalizePrintedLabel } from "@/lib/part-labels";
import type { LayoutRegion, StaffLabelTrace, StructuredWarning } from "@/lib/score-model";
import type { CanonicalPartId, ParsedScore, RecognizedPart } from "@/lib/score-types";
import { buildSystems, staffIdOf, type StructuralFacts } from "@/lib/structure-discovery";

/**
 * Keeps a confirmed choir identity for the whole score.
 * A later system may move, split, or hide the printed staff. The logical id
 * stays the id of the part that first established that role.
 */
export function enforcePartIdentity(
  score: ParsedScore,
  facts: StructuralFacts,
  traces: StaffLabelTrace[]
): { warnings: StructuredWarning[]; layoutRegions: LayoutRegion[] } {
  const systems = buildSystems(score.measures, facts.prints, []);
  const warnings: StructuredWarning[] = [];
  const layoutRegions: LayoutRegion[] = [];
  const slots: Slot[] = [];
  const binding = new Map<string, Slot>();
  let establishingSystem: string | null = null;

  systems.forEach((system, index) => {
    const [start, end] = system.measureRange;
    const inSystem = (measure: number) => measure >= start && measure <= end;
    const active = score.parts.filter((part) =>
      score.notes.some((note) => note.partId === part.id && inSystem(note.measureNumber))
    );
    const claimed = new Set<string>();
    const staves = new Map<string, string[]>();
    const systemId = `${system.pageNumber}:${system.systemNumber}`;

    for (const part of active) {
      const key = roleKey(part);
      const reconnectable = isReconnectable(key);
      if (reconnectable && establishingSystem == null) {
        establishingSystem = systemId;
      }
      const bound = binding.get(part.id);
      if (bound) {
        const conflict = reconnectable ? conflictingLabel(part, facts, start, end) : null;
        if (conflict) {
          warnings.push(shiftWarning(system, start, conflict, bound.owner));
          assignStaff(staves, part, part.id);
          if (bound.owner.id === part.id) {
            claimed.add(bound.key);
          }
          continue;
        }
        if (bound.owner.id !== part.id) {
          const ownerSounding = score.notes.some(
            (note) => note.partId === bound.owner.id && inSystem(note.measureNumber)
          );
          if (ownerSounding) {
            warnings.push(reviewWarning(system, start, labelOf(bound.owner)));
            assignStaff(staves, part, part.id);
            continue;
          }
          moveNotes(score, part.id, bound.owner, inSystem);
        }
        claimed.add(bound.key);
        assignStaff(staves, part, bound.owner.id);
        continue;
      }

      if (reconnectable) {
        const resting = slots.find((slot) => slot.key === key && !claimed.has(slot.key));
        if (resting) {
          moveNotes(score, part.id, resting.owner, inSystem);
          binding.set(part.id, resting);
          claimed.add(resting.key);
          assignStaff(staves, part, resting.owner.id);
          continue;
        }
        const sounding = slots.some((slot) => slot.key === key && claimed.has(slot.key));
        if (sounding && establishingSystem !== systemId) {
          warnings.push(reviewWarning(system, start, titleRole(part.canonicalPart)));
        }
      }

      const slotKey = reconnectable ? uniqueKey(key, slots) : `KEEP:${part.id}`;
      const slot = { key: slotKey, owner: part };
      slots.push(slot);
      binding.set(part.id, slot);
      claimed.add(slotKey);
      assignStaff(staves, part, part.id);
    }

    const silentPartIds = slots
      .filter((slot) => isReconnectable(slot.key) && !claimed.has(slot.key))
      .map((slot) => slot.owner.id);
    layoutRegions.push({
      id: index === 0 ? "layout-1" : `layout-${index + 1}`,
      startMeasure: start,
      endMeasure: end,
      staffToParts: [...staves.entries()].map(([staffId, partIds]) => ({ staffId, partIds })),
      silentPartIds,
      directorVoicing: null,
    });
  });

  for (const trace of traces) {
    const slot = binding.get(trace.logicalPartId);
    if (!slot || slot.owner.id === trace.logicalPartId) {
      continue;
    }
    const donorStillSounds = score.notes.some((note) => note.partId === trace.logicalPartId);
    if (!donorStillSounds) {
      trace.logicalPartId = slot.owner.id;
    }
  }

  const owners = new Set(slots.map((slot) => slot.owner.id));
  score.parts = score.parts.filter(
    (part) => owners.has(part.id) || score.notes.some((note) => note.partId === part.id)
  );

  return { warnings, layoutRegions };
}

interface Slot {
  key: string;
  owner: RecognizedPart;
}

function roleKey(part: RecognizedPart): string {
  if (!isChoirRole(part.canonicalPart) || part.isSolo || part.extraKind) {
    return `KEEP:${part.id}`;
  }
  const withoutStream = part.sourceName.replace(/\((voice|staff)\s+\d+[^)]*\)/gi, " ");
  const division = /\b(ii|2)\b/i.test(withoutStream) ? "#2" : "";
  return `${part.canonicalPart}${division}`;
}

function isReconnectable(key: string) {
  return /^(SOPRANO|ALTO|TENOR|BASS)(#\d+)?$/.test(key);
}

function isChoirRole(part: CanonicalPartId): part is "SOPRANO" | "ALTO" | "TENOR" | "BASS" {
  return part === "SOPRANO" || part === "ALTO" || part === "TENOR" || part === "BASS";
}

function uniqueKey(base: string, slots: Slot[]) {
  const root = base.replace(/#\d+$/, "");
  if (!slots.some((slot) => slot.key === base)) {
    return base;
  }
  let index = 2;
  let key = `${root}#${index}`;
  while (slots.some((slot) => slot.key === key)) {
    index += 1;
    key = `${root}#${index}`;
  }
  return key;
}

function moveNotes(
  score: ParsedScore,
  fromId: string,
  owner: RecognizedPart,
  inSystem: (measure: number) => boolean
) {
  if (fromId === owner.id) {
    return;
  }
  for (const note of score.notes) {
    if (note.partId === fromId && inSystem(note.measureNumber)) {
      note.partId = owner.id;
      note.partCanonical = owner.canonicalPart;
    }
  }
}

function assignStaff(staves: Map<string, string[]>, part: RecognizedPart, logicalId: string) {
  if (part.canonicalPart === "PIANO") {
    return;
  }
  const staffId = staffIdOf(part);
  const list = staves.get(staffId) ?? [];
  if (!list.includes(logicalId)) {
    list.push(logicalId);
  }
  staves.set(staffId, list);
}

function conflictingLabel(part: RecognizedPart, facts: StructuralFacts, start: number, end: number) {
  const keys: string[] = [];
  const raw: string[] = [];
  for (const text of facts.staffTexts) {
    if (text.source !== "words" && text.source !== "ocr") {
      continue;
    }
    if (text.partId !== part.sourcePartId || text.measureNumber < start || text.measureNumber > end) {
      continue;
    }
    if (!isStaffLabelPosition(text) || !staffMatches(text, part)) {
      continue;
    }
    const label = normalizePrintedLabel(text.text, { allowSingleLetter: false });
    if (!label.accepted) {
      continue;
    }
    label.roles.forEach((role, index) => {
      if (!isChoirRole(role)) {
        return;
      }
      keys.push(`${role}${label.divisions[index] === 2 ? "#2" : ""}`);
      raw.push(text.text);
    });
  }
  if (!keys.length || agrees(keys, roleKey(part))) {
    return null;
  }
  return [...new Set(raw)].join(" / ");
}

function agrees(keys: string[], key: string) {
  if (keys.includes(key)) {
    return true;
  }
  const root = key.replace(/#\d+$/, "");
  return keys.includes(root) && !keys.some((candidate) => candidate !== key && candidate.startsWith(`${root}#`));
}

function staffMatches(text: { staff: number | null }, part: RecognizedPart) {
  if (text.staff == null) {
    return true;
  }
  const staff = part.voiceNumber != null && part.id.includes(":s") ? Number(part.id.split(":s")[1]?.split(":")[0]) : 1;
  return text.staff === staff;
}

function shiftWarning(
  system: { pageNumber: number; systemNumber: number },
  measure: number,
  printed: string,
  owner: RecognizedPart
): StructuredWarning {
  return {
    code: "IDENTITY_SHIFT",
    message: `System ${system.systemNumber} on page ${system.pageNumber}: printed “${printed}” does not match the established ${labelOf(owner)} part. The original part was kept.`,
    measure,
    page: system.pageNumber,
    system: system.systemNumber,
  };
}

function reviewWarning(
  system: { pageNumber: number; systemNumber: number },
  measure: number,
  role: string
): StructuredWarning {
  return {
    code: "IDENTITY_REVIEW",
    message: `System ${system.systemNumber} on page ${system.pageNumber}: another ${role} staff is sounding while ${role} is already active. The original ${role} was kept and this staff was flagged for review.`,
    measure,
    page: system.pageNumber,
    system: system.systemNumber,
  };
}

function labelOf(part: RecognizedPart) {
  return titleRole(part.canonicalPart);
}

function titleRole(part: CanonicalPartId) {
  if (part === "SOPRANO") return "Soprano";
  if (part === "ALTO") return "Alto";
  if (part === "TENOR") return "Tenor";
  if (part === "BASS") return "Bass";
  if (part === "PIANO") return "Piano";
  return "Voice";
}
