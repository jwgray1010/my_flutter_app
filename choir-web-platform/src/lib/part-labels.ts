import type { ExtraPartKind, StaffLabelTrace, StructuredWarning } from "@/lib/score-model";
import type { CanonicalPartId, NoteEvent, ParsedScore, RecognizedPart } from "@/lib/score-types";
import type { PartGroupFact, StaffTextFact, StructuralFacts } from "@/lib/structure-discovery";
import { staffIdOf } from "@/lib/structure-discovery";

export interface NormalizedStaffLabel {
  raw: string;
  roles: CanonicalPartId[];
  divisions: Array<1 | 2 | null>;
  extraKind: ExtraPartKind | null;
  accompaniment: "PIANO" | "ORGAN" | "KEYBOARD" | null;
  genericPart: 1 | 2 | null;
  baritone: boolean;
  accepted: boolean;
}

interface TokenHit {
  roles: CanonicalPartId[];
  divisions: Array<1 | 2 | null>;
  extraKind: ExtraPartKind | null;
  accompaniment: "PIANO" | "ORGAN" | "KEYBOARD" | null;
  genericPart: 1 | 2 | null;
  baritone: boolean;
  consumed: number;
}

const EMPTY_LABEL: NormalizedStaffLabel = {
  raw: "",
  roles: [],
  divisions: [],
  extraKind: null,
  accompaniment: null,
  genericPart: null,
  baritone: false,
  accepted: false,
};

/**
 * One normalizer for printed part names. Ordinary sentences, lyrics, and
 * navigation words are rejected. Single letters are accepted only when the
 * caller has already decided the surrounding text is a label, not a lyric.
 */
export function normalizePrintedLabel(
  raw: string,
  options?: { allowSingleLetter?: boolean }
): NormalizedStaffLabel {
  const text = raw.replace(/\s+/g, " ").trim();
  if (!text || text.length > 48) {
    return { ...EMPTY_LABEL, raw };
  }
  const tokens = text
    .toLowerCase()
    .replace(/[.&]+/g, " ")
    .split(/[\s/+,]+/)
    .map((token) => token.trim())
    .filter(Boolean);
  if (!tokens.length || tokens.length > 6) {
    return { ...EMPTY_LABEL, raw };
  }
  const roles: CanonicalPartId[] = [];
  const divisions: Array<1 | 2 | null> = [];
  let extraKind: ExtraPartKind | null = null;
  let accompaniment: NormalizedStaffLabel["accompaniment"] = null;
  let genericPart: 1 | 2 | null = null;
  let baritone = false;
  let index = 0;
  while (index < tokens.length) {
    const hit = readToken(tokens, index, options?.allowSingleLetter === true);
    if (!hit) {
      return { ...EMPTY_LABEL, raw };
    }
    roles.push(...hit.roles);
    divisions.push(...hit.divisions);
    if (hit.extraKind) {
      extraKind = hit.extraKind;
    }
    if (hit.accompaniment) {
      accompaniment = hit.accompaniment;
    }
    if (hit.genericPart) {
      genericPart = hit.genericPart;
    }
    baritone = baritone || hit.baritone;
    index += hit.consumed;
  }
  if (!roles.length && !extraKind && !accompaniment && !genericPart && !baritone) {
    return { ...EMPTY_LABEL, raw };
  }
  return {
    raw,
    roles,
    divisions,
    extraKind,
    accompaniment,
    genericPart,
    baritone,
    accepted: true,
  };
}

export function normalizedText(label: NormalizedStaffLabel, index = 0): string {
  if (label.accompaniment && !label.roles.length) {
    return label.accompaniment;
  }
  if (label.baritone && !label.roles.length) {
    return "BARITONE";
  }
  if (label.genericPart && !label.roles.length) {
    return `PART_${label.genericPart}`;
  }
  if (label.extraKind && !label.roles.length) {
    return label.extraKind;
  }
  const role = label.roles[index] ?? label.roles[0];
  if (!role) {
    return label.raw;
  }
  const division = label.divisions[index] ?? null;
  const suffix = division ? `_${division}` : "";
  const extra = label.extraKind ? `+${label.extraKind}` : "";
  return `${role}${suffix}${extra}`;
}

export interface PrintedLabelResult {
  traces: StaffLabelTrace[];
  warnings: StructuredWarning[];
}

/**
 * Attach printed labels to the staves they sit beside, then keep those
 * logical parts. A later template may fill unlabeled staves. It must not
 * replace a label that was actually printed.
 */
export function applyPrintedStaffLabels(score: ParsedScore, facts: StructuralFacts): PrintedLabelResult {
  const warnings: StructuredWarning[] = [];
  const traces: StaffLabelTrace[] = [];
  const bySource = new Map<string, RecognizedPart[]>();
  for (const part of score.parts) {
    const list = bySource.get(part.sourcePartId) ?? [];
    list.push(part);
    bySource.set(part.sourcePartId, list);
  }

  for (const [sourcePartId, members] of bySource) {
    const texts = facts.staffTexts.filter((text) => text.partId === sourcePartId);
    const chosen = distinctLabels(chooseLabels(texts));
    if (!chosen.length) {
      continue;
    }
    const staffNumbers = [...new Set(chosen.map((item) => item.text.staff).filter((staff) => staff != null))] as number[];
    const groups = staffNumbers.length
      ? staffNumbers.map((staff) => chosen.filter((item) => item.text.staff === staff))
      : [chosen];
    for (const group of groups) {
      applyLabelGroup(score, members, group, traces, warnings);
    }
  }

  applyBraceAccompaniment(score, facts.partGroups, facts, warnings);
  return { traces, warnings };
}

export function bindOcrLabelsToParts(score: ParsedScore, ocr: StaffTextFact[]): StaffTextFact[] {
  const order: string[] = [];
  const staves = new Map<string, number>();
  for (const part of score.parts) {
    if (!order.includes(part.sourcePartId)) {
      order.push(part.sourcePartId);
    }
    staves.set(part.sourcePartId, Math.max(staves.get(part.sourcePartId) ?? 1, part.staves || 1));
  }
  let cursor = 1;
  const bound: StaffTextFact[] = [];
  for (const sourcePartId of order) {
    const span = staves.get(sourcePartId) ?? 1;
    const mine = ocr.filter((text) => text.staff != null && text.staff >= cursor && text.staff < cursor + span);
    cursor += span;
    for (const text of mine) {
      bound.push({ ...text, partId: sourcePartId, source: "ocr", systemStart: true });
    }
  }
  return bound;
}

export function finalizeStaffLabelTraces(
  score: ParsedScore,
  traces: StaffLabelTrace[],
  channels: { id: string; partIds: string[]; canonicalPart: CanonicalPartId }[],
  laterFunctions: string[]
): StaffLabelTrace[] {
  const overwrite = laterFunctions.find((name) => name !== "inferChoirVoicing" && name !== "discoverEnsembleText");
  return traces.map((trace) => {
    const part = score.parts.find((candidate) => candidate.id === trace.logicalPartId);
    const channel = channels.find((candidate) => candidate.partIds.includes(trace.logicalPartId));
    const token = trace.normalized.split("+")[0]?.replace(/_\d$/, "") ?? "";
    const expected = token === "ORGAN" || token === "KEYBOARD" ? "PIANO" : token;
    const partOk =
      expected === "BARITONE"
        ? part?.sourceName.toLowerCase().includes("baritone") === true
        : expected === "PART_1" || expected === "PART_2" || expected === "SOLO" || expected === "DESCANT"
          ? part != null
          : part?.canonicalPart === expected;
    const channelOk = !channel || channel.canonicalPart === part?.canonicalPart || expected === "BARITONE";
    const noteOk =
      !part ||
      score.notes.filter((note) => note.partId === part.id).every((note) => note.partCanonical === part.canonicalPart);
    if (part && partOk && channel && channelOk && noteOk) {
      return { ...trace, playbackChannelId: channel.id, status: "PASS", failedStage: null };
    }
    if (part && partOk && !channel && part.canonicalPart !== "PIANO" && !score.notes.some((note) => note.partId === part.id)) {
      return { ...trace, playbackChannelId: null, status: "PASS", failedStage: null };
    }
    return {
      ...trace,
      playbackChannelId: channel?.id ?? null,
      status: "FAIL",
      failedStage: !partOk ? overwrite || "applyPrintedStaffLabels" : !channel ? "buildChannels" : "syncNoteCanonicals",
    };
  });
}

function distinctLabels(items: ReturnType<typeof labelsFrom>) {
  const seen = new Set<string>();
  const kept: ReturnType<typeof labelsFrom> = [];
  for (const item of items) {
    const key = `${item.text.staff ?? "*"}:${normalizedText(item.label)}`;
    if (seen.has(key)) {
      continue;
    }
    seen.add(key);
    kept.push(item);
  }
  return kept;
}

function chooseLabels(texts: StaffTextFact[]) {
  const names = texts.filter((text) => text.source === "part-name" || text.source === "part-abbreviation");
  const words = texts.filter((text) => text.source === "words" || text.source === "ocr");
  const positioned = words.filter(isLabelPosition);
  const letterContext =
    countSingleLetters(positioned) >= 2 || countSingleLetters(names) >= 2;
  const nameLabels = labelsFrom(names, true);
  const wordLabels = labelsFrom(positioned, letterContext);
  const nameRoles = nameLabels.flatMap((item) => item.label.roles);
  const wordRoles = wordLabels.flatMap((item) => item.label.roles);
  const nameGeneric = nameLabels.length === 0 || nameLabels.every((item) => isGenericLabel(item.label));
  const nameAccompaniment = nameLabels.find((item) => item.label.accompaniment)?.label.accompaniment ?? null;
  if (nameAccompaniment && !wordLabels.some((item) => item.label.accompaniment)) {
    return nameLabels;
  }
  if (wordLabels.length && (nameGeneric || covers(wordRoles, nameRoles))) {
    return wordLabels;
  }
  return nameLabels;
}

function labelsFrom(texts: StaffTextFact[], allowSingleLetter: boolean) {
  return texts
    .map((text, index) => ({ text, index, label: normalizePrintedLabel(text.text, { allowSingleLetter }) }))
    .filter((item) => item.label.accepted)
    .sort((left, right) => {
      const staffDelta = (left.text.staff ?? 0) - (right.text.staff ?? 0);
      if (staffDelta !== 0) {
        return staffDelta;
      }
      if (left.text.defaultY != null && right.text.defaultY != null && left.text.defaultY !== right.text.defaultY) {
        return right.text.defaultY - left.text.defaultY;
      }
      return left.index - right.index;
    });
}

function applyLabelGroup(
  score: ParsedScore,
  members: RecognizedPart[],
  group: ReturnType<typeof labelsFrom>,
  traces: StaffLabelTrace[],
  warnings: StructuredWarning[]
) {
  const roles = group.flatMap((item) => item.label.roles);
  const extra = group.map((item) => item.label.extraKind).find((kind) => kind) ?? null;
  const accompaniment = group.map((item) => item.label.accompaniment).find((kind) => kind) ?? null;
  const baritone = group.some((item) => item.label.baritone) && roles.length === 0;
  const generic = group.some((item) => item.label.genericPart) && roles.length === 0 && !accompaniment && !baritone;
  const rawText = group.map((item) => item.text.text).join(" / ");
  const staff = group.find((item) => item.text.staff != null)?.text.staff ?? null;
  const targeted = membersForStaff(members, staff);
  if (!targeted.length || generic) {
    return;
  }
  if (accompaniment && roles.length === 0) {
    for (const part of targeted) {
      markAccompaniment(part, accompaniment);
      pushTrace(traces, part, rawText, accompaniment, part.id);
    }
    return;
  }
  if (baritone) {
    for (const part of targeted) {
      part.canonicalPart = "UNKNOWN";
      part.needsConfirmation = true;
      part.sourceName = "Baritone";
      pushTrace(traces, part, rawText, "BARITONE", part.id);
    }
    warnings.push(warning("BARITONE", "Printed Baritone stays its own voice until a director assigns it."));
    return;
  }
  if (!roles.length && extra) {
    for (const part of targeted) {
      part.extraKind = extra;
      part.isSolo = extra === "SOLO" || extra === "DESCANT";
      part.needsConfirmation = false;
      pushTrace(traces, part, rawText, extra, part.id);
    }
    return;
  }
  if (!roles.length) {
    return;
  }
  const uncertain = group.every((item) => item.text.defaultX == null && item.text.source === "words");
  if (roles.length === 1 || targeted.length >= roles.length) {
    const hosts = targeted.length >= roles.length ? targeted : [targeted[0]];
    hosts.forEach((part, index) => {
      const role = roles[index];
      if (!role) {
        return;
      }
      assignRole(part, role, extra, uncertain);
      pushTrace(traces, part, rawText, normalizedText(roleLabel(group, index), index), part.id);
    });
    return;
  }
  splitSharedStaff(score, targeted[0], roles, extra, uncertain, rawText, group, traces, warnings);
}

function splitSharedStaff(
  score: ParsedScore,
  host: RecognizedPart,
  roles: CanonicalPartId[],
  extra: ExtraPartKind | null,
  uncertain: boolean,
  rawText: string,
  group: ReturnType<typeof labelsFrom>,
  traces: StaffLabelTrace[],
  warnings: StructuredWarning[]
) {
  const notes = score.notes.filter((note) => note.partId === host.id);
  const voices = [...new Set(notes.map((note) => note.xmlVoice ?? 1))].sort((a, b) => a - b);
  assignRole(host, roles[0], extra, uncertain);
  host.voiceNumber = voices[0] ?? host.voiceNumber;
  pushTrace(traces, host, rawText, normalizedText(roleLabel(group, 0), 0), host.id);

  if (voices.length >= 2) {
    for (let index = 1; index < roles.length; index += 1) {
      const voice = voices[index];
      const role = roles[index];
      if (!role) {
        continue;
      }
      if (voice == null) {
        const created = copyUnison(score, host, role, extra, index);
        pushTrace(traces, created, rawText, normalizedText(roleLabel(group, index), index), created.id);
        continue;
      }
      const created = makeSibling(host, role, extra, voice, index);
      created.needsConfirmation = uncertain;
      insertAfter(score, host, created);
      for (const note of notes) {
        if ((note.xmlVoice ?? 1) === voice) {
          note.partId = created.id;
          note.partCanonical = role;
        }
      }
      pushTrace(traces, created, rawText, normalizedText(roleLabel(group, index), index), created.id);
    }
    return;
  }

  const chorded = notes.some((note) => note.chord) || beatHasTwoPitches(notes);
  if (!chorded) {
    for (let index = 1; index < roles.length; index += 1) {
      const created = copyUnison(score, host, roles[index], extra, index);
      pushTrace(traces, created, rawText, normalizedText(roleLabel(group, index), index), created.id);
    }
    warnings.push(
      warning(
        "LABEL_SHARED",
        `${roles.map(titleRole).join(" and ")} are printed on one staff and share one line of notes.`
      )
    );
    return;
  }

  const byBeat = new Map<number, NoteEvent[]>();
  for (const note of notes) {
    const list = byBeat.get(note.startBeat) ?? [];
    list.push(note);
    byBeat.set(note.startBeat, list);
  }
  const siblings = roles.slice(1).map((role, index) => {
    const created = makeSibling(host, role, extra, host.voiceNumber, index + 1);
    created.needsConfirmation = uncertain;
    insertAfter(score, host, created);
    pushTrace(traces, created, rawText, normalizedText(roleLabel(group, index + 1), index + 1), created.id);
    return created;
  });
  for (const groupNotes of byBeat.values()) {
    const ordered = [...groupNotes].sort((left, right) => right.midi - left.midi);
    if (ordered.length === 1) {
      const unison = `shared:${host.id}:${ordered[0].startBeat}`;
      ordered[0].unisonGroupId = unison;
      ordered[0].partCanonical = roles[0];
      for (const sibling of siblings) {
        score.notes.push({ ...ordered[0], partId: sibling.id, partCanonical: sibling.canonicalPart, unisonGroupId: unison });
      }
      continue;
    }
    ordered.forEach((note, index) => {
      const roleIndex = Math.min(roles.length - 1, Math.floor((index * roles.length) / ordered.length));
      if (roleIndex === 0) {
        note.partCanonical = roles[0];
        return;
      }
      const sibling = siblings[roleIndex - 1];
      if (!sibling) {
        return;
      }
      note.partId = sibling.id;
      note.partCanonical = sibling.canonicalPart;
    });
  }
}

function applyBraceAccompaniment(
  score: ParsedScore,
  groups: PartGroupFact[],
  facts: StructuralFacts,
  warnings: StructuredWarning[]
) {
  for (const group of groups) {
    if (group.symbol !== "brace" || group.partIds.length < 2) {
      continue;
    }
    const members = score.parts.filter((part) => group.partIds.includes(part.sourcePartId));
    if (members.length < 2) {
      continue;
    }
    const vocal = members.some((part) => isChoirRole(part.canonicalPart) && !part.needsConfirmation);
    if (vocal) {
      continue;
    }
    const named = members
      .map((part) => normalizePrintedLabel(part.sourceName, { allowSingleLetter: false }).accompaniment)
      .find((kind) => kind);
    const signs = new Set(
      facts.clefs.filter((clef) => group.partIds.includes(clef.partId)).map((clef) => clef.sign)
    );
    const grandStaff = group.partIds.length === 2 && signs.has("G") && signs.has("F");
    if (!named && !grandStaff) {
      continue;
    }
    const kind = named ?? "PIANO";
    for (const part of members) {
      markAccompaniment(part, kind);
      part.needsConfirmation = !named;
    }
    if (!named) {
      warnings.push(
        warning("PIANO_BRACE", "A braced treble-and-bass pair with no vocal label was read as one piano part.")
      );
    }
  }
}

function copyUnison(
  score: ParsedScore,
  host: RecognizedPart,
  role: CanonicalPartId,
  extra: ExtraPartKind | null,
  index: number
) {
  const created = makeSibling(host, role, extra, host.voiceNumber, index);
  const unison = `unison:${host.id}`;
  insertAfter(score, host, created);
  for (const note of score.notes) {
    if (note.partId !== host.id) {
      continue;
    }
    note.unisonGroupId = unison;
  }
  const copies = score.notes
    .filter((note) => note.partId === host.id)
    .map((note) => ({ ...note, partId: created.id, partCanonical: role, unisonGroupId: unison }));
  score.notes.push(...copies);
  return created;
}

function insertAfter(score: ParsedScore, host: RecognizedPart, created: RecognizedPart) {
  let index = score.parts.indexOf(host);
  if (index < 0) {
    score.parts.push(created);
    return;
  }
  while (score.parts[index + 1]?.sourcePartId === host.sourcePartId) {
    index += 1;
  }
  score.parts.splice(index + 1, 0, created);
}

function makeSibling(
  host: RecognizedPart,
  role: CanonicalPartId,
  extra: ExtraPartKind | null,
  voice: number | null,
  index: number
): RecognizedPart {
  return {
    ...host,
    id: `${host.sourcePartId}:label:${role}:${index}`,
    canonicalPart: role,
    sourceName: titleRole(role),
    voiceNumber: voice,
    needsConfirmation: false,
    isSolo: extra === "SOLO" || extra === "DESCANT",
    extraKind: extra,
    pitchRangeLow: null,
    pitchRangeHigh: null,
    firstMeasureNumber: null,
    lastMeasureNumber: null,
  };
}

function assignRole(part: RecognizedPart, role: CanonicalPartId, extra: ExtraPartKind | null, uncertain: boolean) {
  part.canonicalPart = role;
  part.extraKind = extra;
  part.isSolo = extra === "SOLO" || extra === "DESCANT";
  part.needsConfirmation = uncertain;
  if (isGenericSource(part.sourceName)) {
    part.sourceName = titleRole(role);
  }
}

function markAccompaniment(part: RecognizedPart, kind: "PIANO" | "ORGAN" | "KEYBOARD") {
  part.canonicalPart = "PIANO";
  part.isSolo = false;
  part.extraKind = null;
  part.needsConfirmation = false;
  if (isGenericSource(part.sourceName)) {
    part.sourceName = kind === "PIANO" ? "Piano" : kind === "ORGAN" ? "Organ" : "Keyboard";
  }
}

function pushTrace(
  traces: StaffLabelTrace[],
  part: RecognizedPart,
  rawText: string,
  normalized: string,
  logicalPartId: string
) {
  traces.push({
    rawText,
    normalized,
    partId: part.sourcePartId,
    staffId: staffIdOf(part),
    logicalPartId,
    playbackChannelId: null,
    status: "PASS",
    failedStage: null,
  });
}

function membersForStaff(members: RecognizedPart[], staff: number | null) {
  const sorted = [...members].sort((left, right) => (left.voiceNumber ?? 1) - (right.voiceNumber ?? 1));
  if (staff == null) {
    return sorted;
  }
  const matched = sorted.filter((part) => part.id.includes(`:s${staff}:`) || (staff === 1 && !part.id.includes(":s")));
  return matched.length ? matched : sorted;
}

function isLabelPosition(text: StaffTextFact) {
  if (text.source === "ocr") {
    if (text.pageWidth && text.defaultX != null) {
      return text.defaultX <= text.pageWidth * 0.32;
    }
    return true;
  }
  if (text.defaultX != null) {
    return text.defaultX <= 48;
  }
  return text.systemStart;
}

function countSingleLetters(texts: StaffTextFact[]) {
  return texts.filter((text) => /^[SATBsatb]\.?$/.test(text.text.trim())).length;
}

function isGenericLabel(label: NormalizedStaffLabel) {
  return label.roles.length === 0 && !label.accompaniment && !label.baritone && !label.extraKind;
}

function isGenericSource(name: string) {
  const normalized = name.toLowerCase().replace(/[.\s]+/g, " ").trim();
  return (
    normalized.length === 0 ||
    /^(part|voice|staff|musicxml part)( \d+| i| ii| 1| 2)?$/.test(normalized) ||
    /^p\d+$/.test(normalized)
  );
}

function covers(outer: CanonicalPartId[], inner: CanonicalPartId[]) {
  if (!inner.length || outer.length <= inner.length) {
    return false;
  }
  const rest = [...outer];
  for (const role of inner) {
    const index = rest.indexOf(role);
    if (index < 0) {
      return false;
    }
    rest.splice(index, 1);
  }
  return true;
}

function roleLabel(group: ReturnType<typeof labelsFrom>, index: number): NormalizedStaffLabel {
  let cursor = 0;
  for (const item of group) {
    if (index < cursor + item.label.roles.length) {
      return item.label;
    }
    cursor += item.label.roles.length;
  }
  return group[0]?.label ?? EMPTY_LABEL;
}

function beatHasTwoPitches(notes: NoteEvent[]) {
  const seen = new Map<number, Set<number>>();
  for (const note of notes) {
    const pitches = seen.get(note.startBeat) ?? new Set<number>();
    pitches.add(note.midi);
    seen.set(note.startBeat, pitches);
    if (pitches.size > 1) {
      return true;
    }
  }
  return false;
}

function isChoirRole(part: CanonicalPartId) {
  return part === "SOPRANO" || part === "ALTO" || part === "TENOR" || part === "BASS";
}

function titleRole(part: CanonicalPartId) {
  if (part === "SOPRANO") return "Soprano";
  if (part === "ALTO") return "Alto";
  if (part === "TENOR") return "Tenor";
  if (part === "BASS") return "Bass";
  if (part === "PIANO") return "Piano";
  return "Voice";
}

function warning(code: string, message: string): StructuredWarning {
  return { code, message, measure: null, page: null, system: null };
}

function readToken(tokens: string[], index: number, allowSingleLetter: boolean): TokenHit | null {
  const token = tokens[index] ?? "";
  const next = tokens[index + 1] ?? "";
  const division = divisionOf(next);
  if (token === "soprano" || token === "sop") {
    return roleHit("SOPRANO", division ? divisionOf(next) : null, division ? 2 : 1);
  }
  if (/^s(1|2|i|ii)$/.test(token)) {
    return roleHit("SOPRANO", token.endsWith("2") || token.endsWith("ii") ? 2 : 1, 1);
  }
  if (token === "alto") {
    return roleHit("ALTO", division ? divisionOf(next) : null, division ? 2 : 1);
  }
  if (/^a(1|2|i|ii)$/.test(token)) {
    return roleHit("ALTO", token.endsWith("2") || token.endsWith("ii") ? 2 : 1, 1);
  }
  if (token === "tenor" || token === "ten") {
    return roleHit("TENOR", division ? divisionOf(next) : null, division ? 2 : 1);
  }
  if (/^t(1|2|i|ii)$/.test(token)) {
    return roleHit("TENOR", token.endsWith("2") || token.endsWith("ii") ? 2 : 1, 1);
  }
  if (token === "bass" || token === "bs") {
    return roleHit("BASS", division ? divisionOf(next) : null, division ? 2 : 1);
  }
  if (/^b(1|2|i|ii)$/.test(token)) {
    return roleHit("BASS", token.endsWith("2") || token.endsWith("ii") ? 2 : 1, 1);
  }
  if (token === "baritone" || token === "bari") {
    return { roles: [], divisions: [], extraKind: null, accompaniment: null, genericPart: null, baritone: true, consumed: 1 };
  }
  if ((token === "part" || token === "voice") && division) {
    return {
      roles: [],
      divisions: [],
      extraKind: null,
      accompaniment: null,
      genericPart: divisionOf(next),
      baritone: false,
      consumed: 2,
    };
  }
  if (token === "piano" || token === "pno" || token === "pianoforte") {
    return { roles: [], divisions: [], extraKind: null, accompaniment: "PIANO", genericPart: null, baritone: false, consumed: 1 };
  }
  if (token === "organ") {
    return { roles: [], divisions: [], extraKind: null, accompaniment: "ORGAN", genericPart: null, baritone: false, consumed: 1 };
  }
  if (token === "keyboard" || token === "keys") {
    return { roles: [], divisions: [], extraKind: null, accompaniment: "KEYBOARD", genericPart: null, baritone: false, consumed: 1 };
  }
  if (token === "solo") {
    return extraHit("SOLO");
  }
  if (token === "descant") {
    return extraHit("DESCANT");
  }
  if (token === "optional") {
    return extraHit("OPTIONAL");
  }
  if (token === "cue") {
    return extraHit("CUE");
  }
  if (token === "featured") {
    return extraHit("FEATURED");
  }
  if (token === "small" && next === "group") {
    return { roles: [], divisions: [], extraKind: "SMALL_GROUP", accompaniment: null, genericPart: null, baritone: false, consumed: 2 };
  }
  if (allowSingleLetter && token === "s") return roleHit("SOPRANO", null, 1);
  if (allowSingleLetter && token === "a") return roleHit("ALTO", null, 1);
  if (allowSingleLetter && token === "t") return roleHit("TENOR", null, 1);
  if (allowSingleLetter && token === "b") return roleHit("BASS", null, 1);
  return null;
}

function roleHit(role: CanonicalPartId, division: 1 | 2 | null, consumed: number): TokenHit {
  return {
    roles: [role],
    divisions: [division],
    extraKind: null,
    accompaniment: null,
    genericPart: null,
    baritone: false,
    consumed,
  };
}

function extraHit(extraKind: ExtraPartKind): TokenHit {
  return {
    roles: [],
    divisions: [],
    extraKind,
    accompaniment: null,
    genericPart: null,
    baritone: false,
    consumed: 1,
  };
}

function divisionOf(token: string): 1 | 2 | null {
  if (token === "i" || token === "1") return 1;
  if (token === "ii" || token === "2") return 2;
  return null;
}
