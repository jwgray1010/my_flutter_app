import { JSDOM } from "jsdom";
import { populatePartRanges, readMusicXmlNotation, type RestFact } from "@/lib/musicxml";
import { buildPlaybackModel, type RouteMeasure } from "@/lib/playback-model";
import type { CanonicalPartId, ParsedScore, RecognizedPart } from "@/lib/score-types";
import {
  PIPELINE_VERSION,
  DEFAULT_SCORE_SETUP,
  rolesForVoicing,
  stavesForLayout,
  voicingDisplayLabel,
  voicingForLayout,
  type ChoirVoicingId,
  type ScoreModel,
  type ScoreSetup,
  type SourceUploadType,
  type StructuredWarning,
  type VoicingTraceEntry,
} from "@/lib/score-model";
import { inferChoirVoicing } from "@/lib/voicing";
import {
  buildClefRegions,
  buildNavigation,
  buildSystems,
  buildTempoRegions,
  buildTimeRegions,
  discoverEnsembleText,
  divisiRegions,
  endSoloMeasure,
  ensembleLabel,
  firstChoirSystem,
  genericPartPair,
  mainChoirStaffGroup,
  reconcileKeyRegions,
  rhythmWarnings,
  staffIdOf,
  validationWarnings,
} from "@/lib/structure-discovery";

export interface InterpretInput {
  xml: string;
  sourceType: ParsedScore["sourceType"];
  sourceUploadType: SourceUploadType;
  pageCount: number;
  setup?: ScoreSetup | null;
}

interface VoicingState {
  value: string;
  locked: boolean;
  trace: VoicingTraceEntry[];
}

export function interpretUnifiedScore(input: InterpretInput): ParsedScore {
  return withDomParser(() => interpretUnlocked(input));
}

export function guardLockedVoicing(score: ParsedScore, next: string) {
  if (!score.scoreModel) {
    throw new Error("missing score model");
  }
  commitVoicing(
    {
      value: score.scoreModel.mainChoirVoicing,
      locked: score.scoreModel.voicingLocked,
      trace: score.scoreModel.voicingTrace,
    },
    next,
    {
      stage: "later-pass",
      functionName: "guardLockedVoicing",
      reason: "automatic revision after lock",
      directorAction: false,
    }
  );
}

export function commitVoicing(
  state: VoicingState,
  next: string,
  meta: { stage: string; functionName: string; reason: string; directorAction: boolean }
) {
  if (state.locked && !meta.directorAction && next !== state.value) {
    throw new Error(
      `VOICING OVERRIDE BUG (${meta.functionName} in ${meta.stage}: ${state.value} -> ${next}; ${meta.reason})`
    );
  }
  state.trace.push({
    oldValue: state.value,
    newValue: next,
    stage: meta.stage,
    functionName: meta.functionName,
    reason: meta.reason,
    directorAction: meta.directorAction,
  });
  state.value = next;
  if (meta.directorAction && next !== "Unknown" && next !== "Custom") {
    state.locked = true;
  }
}

function interpretUnlocked(input: InterpretInput): ParsedScore {
  const setup = input.setup ?? DEFAULT_SCORE_SETUP;
  const notation = readMusicXmlNotation(input.xml, input.sourceType);
  const score = notation.score;
  const state: VoicingState = { value: "Unknown", locked: false, trace: [] };
  const warnings: StructuredWarning[] = [];

  const ensemble = discoverEnsembleText(notation.facts);
  if (ensemble.voicing && ensemble.voicing !== "CUSTOM") {
    const applied = applyRoleTemplate(score, ensemble.voicing, false);
    if (applied) {
      commitVoicing(state, ensembleLabel(ensemble.voicing), {
        stage: "global-structure",
        functionName: "discoverEnsembleText",
        reason: ensemble.phrase ? `Printed ensemble text: ${ensemble.phrase}` : "Printed ensemble text",
        directorAction: false,
      });
    }
  } else if (genericPartPair(score.parts)) {
    commitVoicing(state, "2-Part", {
      stage: "global-structure",
      functionName: "genericPartPair",
      reason: "Printed Part I / Part II labels, without SATB role names",
      directorAction: false,
    });
  }

  const labeled = score.parts.some(
    (part) => part.canonicalPart !== "UNKNOWN" && part.canonicalPart !== "PIANO" && !part.isSolo && !part.extraKind
  );
  if (!state.locked && labeled) {
    const summary = choirSummary(score);
    if (summary !== state.value) {
      commitVoicing(state, summary, {
        stage: "part-labels",
        functionName: "inferChoirVoicing",
        reason: "Explicit part labels",
        directorAction: false,
      });
    }
  }

  const directorVoicing = directorVoicingId(setup);
  if (directorVoicing) {
    applyRoleTemplate(score, directorVoicing, true);
    commitVoicing(state, voicingDisplayLabel(directorVoicing), {
      stage: "director-setup",
      functionName: "applyDirectorVoicing",
      reason: "Director confirmed the choir voicing",
      directorAction: true,
    });
  }

  if (setup.staffLayout !== "AUTO" && setup.staffLayout !== "CUSTOM") {
    const layoutVoicing = voicingForLayout(setup.staffLayout);
    const layoutStaves = stavesForLayout(setup.staffLayout);
    if (layoutVoicing && layoutStaves) {
      if (!state.locked) {
        commitVoicing(state, voicingDisplayLabel(layoutVoicing), {
          stage: "director-setup",
          functionName: "applyStaffLayout",
          reason: "Director confirmed the main-choir staff layout",
          directorAction: true,
        });
      } else if (voicingDisplayLabel(layoutVoicing) !== state.value) {
        warnings.push({
          code: "LAYOUT_VOICING",
          message: "Staff layout does not match the locked voicing. The locked voicing was kept.",
          measure: null,
          page: null,
          system: null,
        });
      }
      if (!directorVoicing || voicingDisplayLabel(layoutVoicing) === state.value) {
        applyStaffLayout(score, layoutStaves);
      }
    }
  }

  if (setup.accompaniment === "NONE") {
    warnings.push({
      code: "ACCOMPANIMENT_LOCK",
      message: "Director marked this score a cappella. Printed accompaniment stays playable and is not turned into choir.",
      measure: null,
      page: null,
      system: null,
    });
  }

  const soloEnd = endSoloMeasure(notation.facts);
  if (soloEnd != null) {
    closeSoloAfter(score, soloEnd);
  }

  if (!state.locked) {
    const summary = choirSummary(score);
    const summaryIsWeaker = summary === "Unknown" && state.value !== "Unknown";
    if (!summaryIsWeaker && summary !== state.value) {
      commitVoicing(state, summary, {
        stage: "summarize",
        functionName: "inferChoirVoicing",
        reason: "Summary of parts that have positive role evidence",
        directorAction: false,
      });
    }
  }

  const soloSuffix = soloSuffixFor(score);
  score.inferredVoicing = soloSuffix ? `${state.value} + ${soloSuffix}` : state.value;
  syncNoteCanonicals(score);
  populatePartRanges(score.parts, score.notes);

  const keys = reconcileKeyRegions(notation.facts, score.measures);
  score.keyRegions = keys.regions;
  score.keySignature = keys.regions[0]?.label ?? null;
  warnings.push(...keys.warnings);
  warnings.push(...rhythmWarnings(notation.facts, score.measures));

  const staffIds = [...new Set(score.parts.map((part) => staffIdOf(part)))];
  const systems = buildSystems(score.measures, notation.facts.prints, staffIds);
  const navigation = buildNavigation(score.measures, notation.facts);
  const choirGroup = mainChoirStaffGroup(score);
  const writtenMeasures = score.measures.map((measure) => ({
    id: measure.internalIndex,
    printedNumber: measure.displayLabel ?? String(measure.displayNumber),
    displayNumber: measure.displayNumber,
    beats: measure.beatsInMeasure,
    timeSignature: measure.timeSignature,
    pickup: measure.internalIndex === 0 && measure.beatsInMeasure + 0.05 < nominalBeats(measure.timeSignature),
  }));
  const logical = logicalParts(score);
  const accompaniment = accompanimentOf(score, setup.accompaniment);
  const modelShell = {
    logicalParts: logical.choir,
    extraPlayableParts: logical.extra,
    accompaniment,
    navigationEvents: navigation,
    writtenMeasures,
  };
  const playback = buildPlaybackModel(score, modelShell, notation.repeats);
  for (const warning of playback.warnings) {
    warnings.push({
      code: "NAVIGATION",
      message: warning,
      measure: null,
      page: null,
      system: null,
    });
  }
  score.performanceRoute = playback.playback.route;
  warnings.push(...validationWarnings(score, state.value, state.locked));
  if (choirCountMismatch(score, directorVoicing)) {
    warnings.push({
      code: "PART_COUNT",
      message: "The printed voices do not match the confirmed voicing. Missing parts were not invented.",
      measure: null,
      page: null,
      system: null,
    });
  }

  const scoreModel: ScoreModel = {
    pipelineVersion: PIPELINE_VERSION,
    sourceUploadType: input.sourceUploadType,
    pageCount: input.pageCount,
    pages: Array.from({ length: Math.max(1, input.pageCount) }, (_, index) => ({ pageNumber: index + 1 })),
    systems,
    scoreSetup: setup,
    mainChoirVoicing: state.value,
    lockedVoicing: state.locked ? state.value : null,
    voicingLocked: state.locked,
    logicalParts: logical.choir,
    extraPlayableParts: logical.extra,
    accompaniment,
    mainChoirGroup: choirGroup,
    firstMainChoirSystem: firstChoirSystem(systems, score),
    writtenMeasures,
    partActivityRegions: activityRegions(score),
    layoutRegions: [
      {
        id: "layout-1",
        startMeasure: writtenMeasures[0]?.displayNumber ?? 1,
        endMeasure: writtenMeasures[writtenMeasures.length - 1]?.displayNumber ?? 1,
        staffToParts: staffMap(score),
        directorVoicing: null,
      },
    ],
    divisiRegions: divisiRegions(notation.facts, score.parts, score.measures),
    keySignatureRegions: keys.regions,
    timeSignatureRegions: buildTimeRegions(score.measures),
    clefRegions: buildClefRegions(notation.facts, score.measures),
    tempoRegions: buildTempoRegions(notation.facts, score.measures),
    navigationEvents: navigation,
    normalizedNoteEvents: normalizedEvents(score, notation.rests, systems),
    directorCorrections: [],
    recognitionWarnings: warnings,
    voicingTrace: state.trace,
    keyTrace: keys.trace,
    playback: playback.playback,
  };
  score.scoreModel = scoreModel;
  return score;
}

export function applyDirectorVoicing(score: ParsedScore, voicing: ChoirVoicingId): ParsedScore {
  if (!score.scoreModel) {
    score.inferredVoicing = voicingDisplayLabel(voicing);
    return score;
  }
  const state: VoicingState = {
    value: score.scoreModel.mainChoirVoicing,
    locked: score.scoreModel.voicingLocked,
    trace: score.scoreModel.voicingTrace,
  };
  applyRoleTemplate(score, voicing, true);
  commitVoicing(state, voicingDisplayLabel(voicing), {
    stage: "director-correction",
    functionName: "applyDirectorVoicing",
    reason: "Director correction",
    directorAction: true,
  });
  const suffix = soloSuffixFor(score);
  score.inferredVoicing = suffix ? `${state.value} + ${suffix}` : state.value;
  syncNoteCanonicals(score);
  populatePartRanges(score.parts, score.notes);
  const logical = logicalParts(score);
  score.scoreModel.mainChoirVoicing = state.value;
  score.scoreModel.lockedVoicing = state.locked ? state.value : null;
  score.scoreModel.voicingLocked = state.locked;
  score.scoreModel.logicalParts = logical.choir;
  score.scoreModel.extraPlayableParts = logical.extra;
  score.scoreModel.voicingTrace = state.trace;
  score.scoreModel.scoreSetup = {
    ...score.scoreModel.scoreSetup,
    choirVoicing: voicing,
  };
  const playback = buildPlaybackModel(score, score.scoreModel, repeatsFromNavigation(score));
  score.scoreModel.playback = playback.playback;
  score.performanceRoute = playback.playback.route;
  return score;
}

function directorVoicingId(setup: ScoreSetup): ChoirVoicingId | null {
  if (setup.choirVoicing === "AUTO" || setup.choirVoicing === "CUSTOM") {
    return null;
  }
  return setup.choirVoicing;
}

function applyRoleTemplate(score: ParsedScore, voicing: ChoirVoicingId, overwriteUnknownOnly: boolean): boolean {
  const roles = rolesForVoicing(voicing);
  if (!roles) {
    return false;
  }
  const choir = choirParts(score);
  if (!choir.length) {
    return false;
  }
  if (!overwriteUnknownOnly && choir.length !== roles.length) {
    return false;
  }
  const confident = choir.filter((part) => part.canonicalPart !== "UNKNOWN" && !part.needsConfirmation);
  if (!overwriteUnknownOnly && confident.length === choir.length) {
    return true;
  }
  choir.forEach((part, index) => {
    const role = roles[index];
    if (!role) {
      return;
    }
    if (!overwriteUnknownOnly && part.canonicalPart !== "UNKNOWN") {
      return;
    }
    if (overwriteUnknownOnly && part.canonicalPart !== "UNKNOWN" && !part.needsConfirmation) {
      return;
    }
    part.canonicalPart = role;
    part.needsConfirmation = !overwriteUnknownOnly;
  });
  return true;
}

function applyStaffLayout(score: ParsedScore, staves: CanonicalPartId[][]) {
  const groups = new Map<string, RecognizedPart[]>();
  const order: string[] = [];
  for (const part of choirParts(score)) {
    const id = staffIdOf(part);
    if (!groups.has(id)) {
      groups.set(id, []);
      order.push(id);
    }
    groups.get(id)?.push(part);
  }
  order.forEach((staffId, staffIndex) => {
    const roles = staves[staffIndex];
    const parts = groups.get(staffId) ?? [];
    if (!roles) {
      return;
    }
    parts.forEach((part, index) => {
      const role = roles[index];
      if (!role || (part.canonicalPart !== "UNKNOWN" && !part.needsConfirmation)) {
        return;
      }
      part.canonicalPart = role;
      part.needsConfirmation = false;
    });
    if (roles.length > parts.length && parts[0]) {
      const host = parts[0];
      for (let index = parts.length; index < roles.length; index += 1) {
        const role = roles[index];
        const id = `${host.id}:unison:${role}:${index}`;
        const unisonGroupId = `unison:${host.id}`;
        score.parts.push({
          ...host,
          id,
          canonicalPart: role,
          sourceName: `${host.sourceName} ${role}`,
          needsConfirmation: false,
          voiceNumber: host.voiceNumber,
        });
        const copies = score.notes.filter((note) => note.partId === host.id).map((note) => ({
          ...note,
          partId: id,
          partCanonical: role,
          unisonGroupId,
        }));
        for (const note of score.notes) {
          if (note.partId === host.id) {
            note.unisonGroupId = unisonGroupId;
          }
        }
        score.notes.push(...copies);
      }
    }
  });
}

function choirParts(score: ParsedScore): RecognizedPart[] {
  return score.parts.filter((part) => part.canonicalPart !== "PIANO" && !part.isSolo && !part.extraKind);
}

function choirSummary(score: ParsedScore): string {
  const summary = inferChoirVoicing(score.parts);
  return summary.split(" + ")[0] || "Unknown";
}

function soloSuffixFor(score: ParsedScore): string | null {
  const hasSolo = score.parts.some((part) => part.extraKind === "SOLO" || (part.isSolo && part.extraKind !== "DESCANT"));
  const hasDescant = score.parts.some((part) => part.extraKind === "DESCANT");
  if (hasSolo) {
    return "Solo";
  }
  if (hasDescant) {
    return "Descant";
  }
  return null;
}

function closeSoloAfter(score: ParsedScore, measure: number) {
  for (const part of score.parts) {
    if (part.extraKind !== "SOLO" && !part.isSolo) {
      continue;
    }
    const later = score.notes.some((note) => note.partId === part.id && note.measureNumber > measure);
    if (later) {
      part.needsConfirmation = true;
    }
  }
}

function syncNoteCanonicals(score: ParsedScore) {
  const canonical = new Map(score.parts.map((part) => [part.id, part.canonicalPart]));
  for (const note of score.notes) {
    note.partCanonical = canonical.get(note.partId) ?? note.partCanonical;
  }
}

function logicalParts(score: ParsedScore) {
  const toModel = (part: RecognizedPart) => ({
    id: part.id,
    label: displayPart(part),
    canonicalPart: part.canonicalPart,
    sourcePartId: part.sourcePartId,
    physicalStaff: physicalStaff(part),
    xmlVoice: part.voiceNumber,
    extraKind: part.extraKind ?? null,
    needsConfirmation: part.needsConfirmation,
  });
  return {
    choir: choirParts(score).map(toModel),
    extra: score.parts.filter((part) => part.isSolo || part.extraKind).map(toModel),
  };
}

function displayPart(part: RecognizedPart): string {
  if (part.extraKind === "SOLO") {
    return part.canonicalPart === "UNKNOWN" ? "Solo" : `${titleCase(part.canonicalPart)} Solo`;
  }
  if (part.extraKind === "DESCANT") {
    return "Descant";
  }
  if (part.extraKind) {
    return part.sourceName;
  }
  if (part.canonicalPart === "UNKNOWN") {
    return part.sourceName;
  }
  return titleCase(part.canonicalPart);
}

function titleCase(part: CanonicalPartId): string {
  if (part === "SOPRANO") return "Soprano";
  if (part === "ALTO") return "Alto";
  if (part === "TENOR") return "Tenor";
  if (part === "BASS") return "Bass";
  if (part === "PIANO") return "Piano";
  return "Voice";
}

function physicalStaff(part: RecognizedPart): number | null {
  const match = /:s(\d+)/.exec(part.id);
  if (match) {
    return Number(match[1]);
  }
  return part.staves > 0 ? 1 : null;
}

function accompanimentOf(score: ParsedScore, choice: ScoreSetup["accompaniment"]) {
  const piano = score.parts.filter((part) => part.canonicalPart === "PIANO");
  const kind = choice === "NONE" ? "NONE" : choice === "OTHER" ? "OTHER" : piano.length ? "PIANO" : "NONE";
  const right = piano[0] ? `${piano[0].sourcePartId}:s1` : null;
  const left = piano[0] && piano[0].staves > 1 ? `${piano[0].sourcePartId}:s2` : null;
  return {
    kind: kind as "NONE" | "PIANO" | "OTHER",
    partIds: piano.map((part) => part.id),
    rightHandStaff: right,
    leftHandStaff: left,
  };
}

function activityRegions(score: ParsedScore) {
  const regions: ScoreModel["partActivityRegions"] = [];
  for (const part of score.parts) {
    let current: { start: number; end: number; active: boolean } | null = null;
    for (const measure of score.measures) {
      const active = score.notes.some(
        (note) => note.partId === part.id && note.measureNumber === measure.displayNumber
      );
      if (!current || current.active !== active) {
        if (current) {
          regions.push({
            partId: part.id,
            startMeasure: current.start,
            endMeasure: current.end,
            active: current.active,
          });
        }
        current = { start: measure.displayNumber, end: measure.displayNumber, active };
      } else {
        current.end = measure.displayNumber;
      }
    }
    if (current) {
      regions.push({
        partId: part.id,
        startMeasure: current.start,
        endMeasure: current.end,
        active: current.active,
      });
    }
  }
  return regions;
}

function staffMap(score: ParsedScore) {
  const map = new Map<string, string[]>();
  for (const part of score.parts) {
    if (part.canonicalPart === "PIANO") {
      continue;
    }
    const id = staffIdOf(part);
    const list = map.get(id) ?? [];
    list.push(part.id);
    map.set(id, list);
  }
  return [...map.entries()].map(([staffId, partIds]) => ({ staffId, partIds }));
}

function normalizedEvents(
  score: ParsedScore,
  rests: RestFact[],
  systems: ScoreModel["systems"]
): ScoreModel["normalizedNoteEvents"] {
  const systemFor = (measure: number) =>
    systems.find((system) => measure >= system.measureRange[0] && measure <= system.measureRange[1]) ?? null;
  const measureByNumber = new Map(score.measures.map((measure) => [measure.displayNumber, measure]));
  const sounding = score.notes.map((note) => {
    const measure = measureByNumber.get(note.measureNumber);
    const system = systemFor(note.measureNumber);
    return {
      logicalPart: note.partId,
      physicalStaff: note.physicalStaff ?? null,
      xmlVoice: note.xmlVoice ?? null,
      writtenMeasureId: measure?.internalIndex ?? 0,
      printedMeasureNumber: measure?.displayLabel ?? String(note.measureNumber),
      beat: note.startBeat,
      offsetWithinMeasure: measure ? note.startBeat - measure.startBeat : 0,
      duration: note.durationBeats,
      pitch: note.midi,
      rest: false,
      tieStart: Boolean(note.tieStart),
      tieStop: Boolean(note.tieStop),
      chord: Boolean(note.chord),
      sourcePage: system?.pageNumber ?? null,
      sourceSystem: system?.systemNumber ?? null,
    };
  });
  const restEvents = rests.map((rest) => {
    const measure = score.measures.find((candidate) => candidate.internalIndex === rest.measureIndex);
    const system = measure ? systemFor(measure.displayNumber) : null;
    return {
      logicalPart: rest.partId,
      physicalStaff: rest.staff,
      xmlVoice: rest.voice,
      writtenMeasureId: rest.measureIndex,
      printedMeasureNumber: measure?.displayLabel ?? String(rest.measureNumber),
      beat: rest.startBeat,
      offsetWithinMeasure: measure ? rest.startBeat - measure.startBeat : 0,
      duration: rest.durationBeats,
      pitch: null,
      rest: true,
      tieStart: false,
      tieStop: false,
      chord: false,
      sourcePage: system?.pageNumber ?? null,
      sourceSystem: system?.systemNumber ?? null,
    };
  });
  return [...sounding, ...restEvents];
}

function choirCountMismatch(score: ParsedScore, voicing: ChoirVoicingId | null): boolean {
  if (!voicing) {
    return false;
  }
  const roles = rolesForVoicing(voicing);
  if (!roles) {
    return false;
  }
  return choirParts(score).length !== roles.length;
}

function repeatsFromNavigation(score: ParsedScore): RouteMeasure[] {
  return score.measures.map((measure, index) => {
    const events = score.scoreModel?.navigationEvents.filter((event) => event.measureIndex === index) ?? [];
    const ending = events.find((event) => event.kind === "ENDING");
    const repeatEnd = events.find((event) => event.kind === "REPEAT_END");
    return {
      number: measure.displayNumber,
      repeatForward: events.some((event) => event.kind === "REPEAT_START"),
      repeatBackward: Boolean(repeatEnd),
      repeatTimes: repeatEnd?.times ?? 2,
      ending: ending?.ending ?? null,
    };
  });
}

function nominalBeats(timeSignature: string): number {
  const [beats, beatType] = timeSignature.split("/").map((part) => Number(part));
  if (!beats || !beatType) {
    return 4;
  }
  return beats * (4 / beatType);
}

function withDomParser<T>(run: () => T): T {
  const previous = globalThis.DOMParser;
  if (!previous) {
    (globalThis as { DOMParser: typeof window.DOMParser }).DOMParser = new JSDOM().window.DOMParser;
  }
  try {
    return run();
  } finally {
    if (!previous) {
      delete (globalThis as { DOMParser?: typeof window.DOMParser }).DOMParser;
    }
  }
}

