import type {
  ClefRegion,
  KeyChangeTrace,
  KeySignatureRegion,
  MeasureInfo,
  NavigationEvent,
  NavigationKind,
  NoteEvent,
  PartActivityRegion,
  PlaybackRouteStep,
  RecognizedPart,
  ScoreStructure,
  TimeSignatureRegion,
  WrittenMeasure,
} from "@/lib/score-types";
import { UNIFIED_SCORE_PIPELINE_VERSION } from "@/lib/score-types";

interface MeasureNav {
  internalIndex: number;
  displayNumber: number;
  repeatForward: boolean;
  repeatBackward: boolean;
  endingNumbers: number[] | null;
  segno: boolean;
  coda: boolean;
  toCoda: boolean;
  daCapo: boolean;
  dalSegno: boolean;
  fine: boolean;
  text: string | null;
}

interface KeyObservation {
  measureNumber: number;
  internalIndex: number;
  fifthsByPart: number[];
}

export function buildScoreStructure(input: {
  partNodes: Element[];
  measures: MeasureInfo[];
  parts: RecognizedPart[];
  notes: NoteEvent[];
}): ScoreStructure {
  const warnings: string[] = [];
  const writtenMeasures = buildWrittenMeasures(input.measures, warnings);
  const keyObservations = readKeyObservations(input.partNodes, input.measures);
  const key = buildKeySignatureRegions(keyObservations, input.measures, warnings);
  applyKeyToWrittenMeasures(writtenMeasures, key.regions);
  const timeSignatureRegions = buildTimeSignatureRegions(input.measures);
  const clefRegions = readClefRegions(input.partNodes, input.measures);
  const navigationEvents = readNavigationEvents(input.partNodes, input.measures);
  const playbackRoute = buildPlaybackRoute(input.measures, navigationEvents, warnings);
  assertUniqueWrittenMeasures(writtenMeasures, warnings);
  collectDurationWarnings(input.partNodes, input.measures, writtenMeasures, warnings);
  const partActivityRegions = buildPartActivity(input.parts, input.notes);
  if (input.parts.some((part) => part.canonicalPart === "UNKNOWN")) {
    warnings.push(
      "Unlabeled voices were left unassigned. Confirm them in Identify Parts instead of assuming SATB."
    );
  }

  return {
    pipelineVersion: UNIFIED_SCORE_PIPELINE_VERSION,
    sourceUploadType: "UNKNOWN",
    writtenMeasures,
    keySignatureRegions: key.regions,
    keyChangeTrace: key.trace,
    timeSignatureRegions,
    clefRegions,
    navigationEvents,
    playbackRoute,
    partActivityRegions,
    recognitionWarnings: [...new Set(warnings)],
  };
}

export function buildPlaybackRoute(
  measures: MeasureInfo[],
  events: NavigationEvent[],
  warnings: string[] = []
): PlaybackRouteStep[] {
  if (!measures.length) {
    return [];
  }
  const nav = indexNavigation(measures, events);
  const route: PlaybackRouteStep[] = [];
  const visitCount = new Map<string, number>();
  const repeatTakes = new Map<number, number>();
  let index = 0;
  let repeatStart = 0;
  let voltaPass = 1;
  let daCapoTaken = false;
  let dalSegnoTaken = false;
  let codaTaken = false;
  const safetyLimit = measures.length * 6 + 4;

  while (index < measures.length && route.length < safetyLimit) {
    const measure = measures[index];
    const flags = nav[index];
    if (flags.endingNumbers && !flags.endingNumbers.includes(voltaPass)) {
      index += 1;
      continue;
    }

    const id = writtenMeasureId(measure.internalIndex);
    const visit = (visitCount.get(id) ?? 0) + 1;
    visitCount.set(id, visit);
    const previousEnd = route.length ? route[route.length - 1].performanceEndBeat : 0;
    route.push({
      writtenMeasureId: id,
      displayNumber: measure.displayNumber,
      internalIndex: measure.internalIndex,
      visit,
      performanceStartBeat: previousEnd,
      performanceEndBeat: previousEnd + measure.beatsInMeasure,
    });

    const returning = daCapoTaken || dalSegnoTaken;
    if (flags.fine && returning) {
      break;
    }
    if (flags.toCoda && returning && !codaTaken) {
      const codaIndex = nav.findIndex((item) => item.coda);
      if (codaIndex >= 0) {
        codaTaken = true;
        index = codaIndex;
        continue;
      }
    }
    const repeatTarget = flags.repeatForward ? index : repeatStart;
    if (flags.repeatBackward) {
      const taken = repeatTakes.get(index) ?? 0;
      if (taken < 1) {
        repeatTakes.set(index, taken + 1);
        voltaPass = taken + 2;
        if (flags.repeatForward) {
          repeatStart = index;
        }
        index = repeatTarget;
        continue;
      }
      voltaPass = 1;
    }
    if (flags.repeatForward) {
      repeatStart = index;
    }
    if (flags.dalSegno && !dalSegnoTaken) {
      dalSegnoTaken = true;
      voltaPass = 1;
      const segnoIndex = nav.findIndex((item) => item.segno);
      index = segnoIndex >= 0 ? segnoIndex : 0;
      continue;
    }
    if (flags.daCapo && !daCapoTaken) {
      daCapoTaken = true;
      voltaPass = 1;
      index = 0;
      continue;
    }
    index += 1;
  }

  if (route.length >= safetyLimit) {
    warnings.push("Playback route stopped early to avoid an unbounded repeat.");
  }
  return route;
}

export function buildKeySignatureRegions(
  observations: KeyObservation[],
  measures: MeasureInfo[],
  warnings: string[]
): { regions: KeySignatureRegion[]; trace: KeyChangeTrace[] } {
  const regions: KeySignatureRegion[] = [];
  const trace: KeyChangeTrace[] = [];
  if (!measures.length) {
    return { regions, trace };
  }
  let currentFifths: number | null = null;
  let regionStart = measures[0].displayNumber;

  observations.forEach((observation, observationIndex) => {
    if (!observation.fifthsByPart.length) {
      return;
    }
    const majority = majorityValue(observation.fifthsByPart);
    const agreement =
      observation.fifthsByPart.filter((value) => value === majority).length /
      observation.fifthsByPart.length;
    if (currentFifths == null) {
      currentFifths = majority;
      regionStart = observation.measureNumber;
      trace.push({
        measureNumber: observation.measureNumber,
        oldKey: null,
        newKey: describeKeySignature(majority),
        source: "musicxml-key",
        confidence: "confirmed",
        reason: "Opening key comes from a printed MusicXML key signature.",
      });
      return;
    }
    if (majority === currentFifths) {
      return;
    }
    const next = nextMajority(observations, observationIndex + 1);
    const unanimous = agreement === 1 && observation.fifthsByPart.length > 1;
    const flicker = next === currentFifths && !unanimous;
    if (flicker || agreement < 0.5) {
      const rejected = describeKeySignature(majority);
      warnings.push(
        `m.${observation.measureNumber} — possible key-signature conflict (${describeKeySignature(currentFifths)} vs ${rejected}). Kept the confirmed key.`
      );
      trace.push({
        measureNumber: observation.measureNumber,
        oldKey: describeKeySignature(currentFifths),
        newKey: rejected,
        source: "musicxml-key",
        confidence: "rejected",
        reason: flicker
          ? "One-measure key flicker disagreed with the surrounding staves."
          : "Key change was not agreed across the staves that reported a signature.",
      });
      return;
    }
    const previousEnd = previousMeasureNumber(measures, observation.measureNumber);
    regions.push({
      startMeasure: regionStart,
      endMeasure: previousEnd,
      keySignature: describeKeySignature(currentFifths),
      fifths: currentFifths,
      source: "musicxml-key",
    });
    trace.push({
      measureNumber: observation.measureNumber,
      oldKey: describeKeySignature(currentFifths),
      newKey: describeKeySignature(majority),
      source: "musicxml-key",
      confidence: "confirmed",
      reason: "Printed key signature changed and the reporting staves agreed.",
    });
    currentFifths = majority;
    regionStart = observation.measureNumber;
  });

  if (currentFifths != null) {
    regions.push({
      startMeasure: regionStart,
      endMeasure: measures[measures.length - 1].displayNumber,
      keySignature: describeKeySignature(currentFifths),
      fifths: currentFifths,
      source: "musicxml-key",
    });
  }
  return { regions, trace };
}

export function describeKeySignature(fifths: number) {
  const majorKeys = ["Cb", "Gb", "Db", "Ab", "Eb", "Bb", "F", "C", "G", "D", "A", "E", "B", "F#", "C#"];
  const index = fifths + 7;
  if (index >= 0 && index < majorKeys.length) {
    return `${majorKeys[index]} major`;
  }
  return `${fifths} fifths`;
}

export function writtenMeasureId(internalIndex: number) {
  return `wm-${internalIndex}`;
}

function buildWrittenMeasures(measures: MeasureInfo[], warnings: string[]): WrittenMeasure[] {
  const seen = new Set<number>();
  return measures.map((measure) => {
    if (seen.has(measure.displayNumber)) {
      warnings.push(`DUPLICATE WRITTEN MEASURE ${measure.displayNumber}`);
    }
    seen.add(measure.displayNumber);
    const meterBeats = meterLengthBeats(measure.timeSignature);
    const isPickup =
      measure.internalIndex === 0 &&
      meterBeats != null &&
      measure.beatsInMeasure + 0.05 < meterBeats;
    return {
      id: writtenMeasureId(measure.internalIndex),
      displayNumber: measure.displayNumber,
      internalIndex: measure.internalIndex,
      timeSignature: measure.timeSignature,
      beatsInMeasure: measure.beatsInMeasure,
      isPickup,
      keySignature: null,
    };
  });
}

function assertUniqueWrittenMeasures(writtenMeasures: WrittenMeasure[], warnings: string[]) {
  const ids = new Set<string>();
  for (const measure of writtenMeasures) {
    if (ids.has(measure.id)) {
      warnings.push(`DUPLICATE WRITTEN MEASURE ${measure.id}`);
    }
    ids.add(measure.id);
  }
}

function applyKeyToWrittenMeasures(writtenMeasures: WrittenMeasure[], regions: KeySignatureRegion[]) {
  for (const measure of writtenMeasures) {
    const region = regions.find(
      (item) => measure.displayNumber >= item.startMeasure && measure.displayNumber <= item.endMeasure
    );
    measure.keySignature = region?.keySignature ?? null;
  }
}

function buildTimeSignatureRegions(measures: MeasureInfo[]): TimeSignatureRegion[] {
  const regions: TimeSignatureRegion[] = [];
  for (const measure of measures) {
    const current = regions[regions.length - 1];
    if (current && current.timeSignature === measure.timeSignature) {
      current.endMeasure = measure.displayNumber;
      continue;
    }
    regions.push({
      startMeasure: measure.displayNumber,
      endMeasure: measure.displayNumber,
      timeSignature: measure.timeSignature,
    });
  }
  return regions;
}

function buildPartActivity(parts: RecognizedPart[], notes: NoteEvent[]): PartActivityRegion[] {
  return parts.map((part) => {
    const partNotes = notes.filter((note) => note.partId === part.id);
    if (!partNotes.length) {
      return {
        partId: part.id,
        label: part.sourceName,
        canonicalPart: part.canonicalPart,
        firstActiveMeasure: null,
        lastActiveMeasure: null,
      };
    }
    let first = Infinity;
    let last = -Infinity;
    for (const note of partNotes) {
      first = Math.min(first, note.measureNumber);
      last = Math.max(last, note.measureNumber);
    }
    return {
      partId: part.id,
      label: part.sourceName,
      canonicalPart: part.canonicalPart,
      firstActiveMeasure: first,
      lastActiveMeasure: last,
    };
  });
}

function readKeyObservations(partNodes: Element[], measures: MeasureInfo[]): KeyObservation[] {
  return measures.map((measure, index) => {
    const fifthsByPart: number[] = [];
    for (const partNode of partNodes) {
      const measureNode = elementChildrenByTag(partNode, "measure")[index];
      const fifthsNode = measureNode?.querySelector("attributes > key > fifths");
      if (!fifthsNode) {
        continue;
      }
      const fifths = Number(fifthsNode.textContent?.trim());
      if (Number.isFinite(fifths)) {
        fifthsByPart.push(fifths);
      }
    }
    return {
      measureNumber: measure.displayNumber,
      internalIndex: measure.internalIndex,
      fifthsByPart,
    };
  });
}

function readClefRegions(partNodes: Element[], measures: MeasureInfo[]): ClefRegion[] {
  const regions: ClefRegion[] = [];
  partNodes.forEach((partNode, partIndex) => {
    const partId = partNode.getAttribute("id") ?? `P${partIndex + 1}`;
    const open = new Map<number, ClefRegion>();
    elementChildrenByTag(partNode, "measure").forEach((measureNode, index) => {
      const measureNumber = measures[index]?.displayNumber;
      if (measureNumber == null) {
        return;
      }
      const clefs = measureNode.querySelectorAll("attributes > clef");
      clefs.forEach((clef) => {
        const staff = Number(clef.getAttribute("number") ?? "1");
        const sign = clef.querySelector("sign")?.textContent?.trim();
        if (!sign) {
          return;
        }
        const lineText = clef.querySelector("line")?.textContent?.trim();
        const line = lineText ? Number(lineText) : null;
        const current = open.get(staff);
        if (current && current.sign === sign) {
          current.endMeasure = measureNumber;
          return;
        }
        if (current) {
          regions.push(current);
        }
        open.set(staff, {
          partId,
          staff: Number.isFinite(staff) ? staff : 1,
          startMeasure: measureNumber,
          endMeasure: measureNumber,
          sign,
          line: line != null && Number.isFinite(line) ? line : null,
        });
      });
    });
    for (const region of open.values()) {
      const last = measures[measures.length - 1]?.displayNumber;
      if (last != null) {
        region.endMeasure = last;
      }
      regions.push(region);
    }
  });
  return regions;
}

function readNavigationEvents(partNodes: Element[], measures: MeasureInfo[]): NavigationEvent[] {
  const merged: MeasureNav[] = measures.map((measure) => ({
    internalIndex: measure.internalIndex,
    displayNumber: measure.displayNumber,
    repeatForward: false,
    repeatBackward: false,
    endingNumbers: null,
    segno: false,
    coda: false,
    toCoda: false,
    daCapo: false,
    dalSegno: false,
    fine: false,
    text: null,
  }));
  let activeEnding: number[] | null = null;

  for (const partNode of partNodes) {
    activeEnding = null;
    elementChildrenByTag(partNode, "measure").forEach((measureNode, index) => {
      const slot = merged[index];
      if (!slot) {
        return;
      }
      for (const barline of elementChildrenByTag(measureNode, "barline")) {
        const repeat = barline.querySelector("repeat")?.getAttribute("direction");
        if (repeat === "forward") {
          slot.repeatForward = true;
        }
        if (repeat === "backward") {
          slot.repeatBackward = true;
        }
        const ending = barline.querySelector("ending");
        if (ending) {
          const type = ending.getAttribute("type");
          const numbers = parseEndingNumbers(ending.getAttribute("number"));
          if (type === "start" && numbers.length) {
            activeEnding = numbers;
            slot.endingNumbers = numbers;
          } else if (type === "stop" || type === "discontinue") {
            slot.endingNumbers = slot.endingNumbers ?? activeEnding;
            activeEnding = null;
          }
        }
      }
      if (activeEnding && !slot.endingNumbers) {
        slot.endingNumbers = activeEnding;
      }
      const words = collectDirectionText(measureNode);
      if (words && !slot.text) {
        slot.text = words;
      }
      applyNavigationWords(slot, words);
      for (const sound of measureNode.querySelectorAll("sound")) {
        if (sound.getAttribute("segno")) {
          slot.segno = true;
        }
        if (sound.getAttribute("coda")) {
          slot.coda = true;
        }
        if (sound.getAttribute("tocoda")) {
          slot.toCoda = true;
        }
        if (sound.getAttribute("dacapo") === "yes") {
          slot.daCapo = true;
        }
        if (sound.getAttribute("dalsegno")) {
          slot.dalSegno = true;
        }
        if (sound.getAttribute("fine") === "yes") {
          slot.fine = true;
        }
      }
    });
  }

  const events: NavigationEvent[] = [];
  for (const slot of merged) {
    pushNav(events, slot, "REPEAT_START", slot.repeatForward);
    pushNav(events, slot, "REPEAT_END", slot.repeatBackward);
    pushNav(events, slot, "ENDING", slot.endingNumbers != null);
    pushNav(events, slot, "SEGNO", slot.segno);
    pushNav(events, slot, "CODA", slot.coda);
    pushNav(events, slot, "TO_CODA", slot.toCoda);
    pushNav(events, slot, "DA_CAPO", slot.daCapo);
    pushNav(events, slot, "DAL_SEGNO", slot.dalSegno);
    pushNav(events, slot, "FINE", slot.fine);
  }
  return events;
}

function pushNav(events: NavigationEvent[], slot: MeasureNav, kind: NavigationKind, include: boolean) {
  if (!include) {
    return;
  }
  events.push({
    kind,
    measureNumber: slot.displayNumber,
    internalIndex: slot.internalIndex,
    endingNumbers: kind === "ENDING" ? slot.endingNumbers : null,
    text: slot.text,
  });
}

function applyNavigationWords(slot: MeasureNav, words: string | null) {
  if (!words) {
    return;
  }
  const normalized = words.toLowerCase().replace(/\s+/g, " ").trim();
  if (/d\.?\s*s\.?|dal segno/.test(normalized)) {
    slot.dalSegno = true;
  } else if (/d\.?\s*c\.?|da capo/.test(normalized)) {
    slot.daCapo = true;
  }
  if (/to coda/.test(normalized)) {
    slot.toCoda = true;
  } else if (/(^|\s)coda($|\s)/.test(normalized) && !/al coda/.test(normalized)) {
    slot.coda = true;
  }
  if (/(^|\s)fine($|\s)/.test(normalized) && !/al fine/.test(normalized)) {
    slot.fine = true;
  }
  if (/\bsegno\b/.test(normalized) && !/dal segno/.test(normalized)) {
    slot.segno = true;
  }
}

function collectDirectionText(measureNode: Element) {
  const chunks: string[] = [];
  for (const words of measureNode.querySelectorAll("direction-type words, direction-type rehearsal")) {
    const text = words.textContent?.trim();
    if (text) {
      chunks.push(text);
    }
  }
  return chunks.length ? chunks.join(" ") : null;
}

function indexNavigation(measures: MeasureInfo[], events: NavigationEvent[]) {
  return measures.map((measure) => {
    const mine = events.filter((event) => event.internalIndex === measure.internalIndex);
    const ending = mine.find((event) => event.kind === "ENDING");
    return {
      repeatForward: mine.some((event) => event.kind === "REPEAT_START"),
      repeatBackward: mine.some((event) => event.kind === "REPEAT_END"),
      endingNumbers: ending?.endingNumbers ?? null,
      segno: mine.some((event) => event.kind === "SEGNO"),
      coda: mine.some((event) => event.kind === "CODA"),
      toCoda: mine.some((event) => event.kind === "TO_CODA"),
      daCapo: mine.some((event) => event.kind === "DA_CAPO"),
      dalSegno: mine.some((event) => event.kind === "DAL_SEGNO"),
      fine: mine.some((event) => event.kind === "FINE"),
    };
  });
}

function collectDurationWarnings(
  partNodes: Element[],
  measures: MeasureInfo[],
  writtenMeasures: WrittenMeasure[],
  warnings: string[]
) {
  partNodes.forEach((partNode, partIndex) => {
    let divisions = 1;
    elementChildrenByTag(partNode, "measure").forEach((measureNode, index) => {
      const measure = measures[index];
      const written = writtenMeasures[index];
      if (!measure || !written || written.isPickup) {
        return;
      }
      const divisionsText = measureNode.querySelector("attributes > divisions")?.textContent?.trim();
      if (divisionsText) {
        const parsed = Number(divisionsText);
        if (Number.isFinite(parsed) && parsed > 0) {
          divisions = parsed;
        }
      }
      const expected = meterLengthBeats(measure.timeSignature);
      if (expected == null) {
        return;
      }
      let cursor = 0;
      let maxCursor = 0;
      for (const child of Array.from(measureNode.children)) {
        if (child.tagName === "backup") {
          cursor = Math.max(0, cursor - durationOf(child));
          continue;
        }
        if (child.tagName === "forward") {
          cursor += durationOf(child);
          maxCursor = Math.max(maxCursor, cursor);
          continue;
        }
        if (child.tagName !== "note" || child.querySelector("chord")) {
          continue;
        }
        cursor += durationOf(child);
        maxCursor = Math.max(maxCursor, cursor);
      }
      if (maxCursor <= 0) {
        return;
      }
      const actual = maxCursor / divisions;
      if (Math.abs(actual - expected) > 0.05) {
        const partId = partNode.getAttribute("id") ?? `P${partIndex + 1}`;
        warnings.push(
          `m.${measure.displayNumber} — ${partId} duration ${roundBeats(actual)} does not match ${measure.timeSignature}. Left unchanged for review.`
        );
      }
    });
  });
}

function durationOf(node: Element) {
  const parsed = Number(node.querySelector("duration")?.textContent?.trim());
  return Number.isFinite(parsed) ? parsed : 0;
}

function meterLengthBeats(timeSignature: string) {
  const [beatsText, beatTypeText] = timeSignature.split("/");
  const beats = Number(beatsText);
  const beatType = Number(beatTypeText);
  if (!Number.isFinite(beats) || !Number.isFinite(beatType) || beatType <= 0) {
    return null;
  }
  return beats * (4 / beatType);
}

function majorityValue(values: number[]) {
  const counts = new Map<number, number>();
  for (const value of values) {
    counts.set(value, (counts.get(value) ?? 0) + 1);
  }
  let best = values[0];
  let bestCount = -1;
  for (const [value, count] of counts) {
    if (count > bestCount) {
      best = value;
      bestCount = count;
    }
  }
  return best;
}

function nextMajority(observations: KeyObservation[], startIndex: number) {
  for (let index = startIndex; index < observations.length; index += 1) {
    const fifths = observations[index].fifthsByPart;
    if (fifths.length) {
      return majorityValue(fifths);
    }
  }
  return null;
}

function previousMeasureNumber(measures: MeasureInfo[], displayNumber: number) {
  const index = measures.findIndex((measure) => measure.displayNumber === displayNumber);
  if (index <= 0) {
    return displayNumber;
  }
  return measures[index - 1].displayNumber;
}

function parseEndingNumbers(value: string | null) {
  if (!value) {
    return [];
  }
  return value
    .split(/[^0-9]+/)
    .map((part) => Number(part))
    .filter((part) => Number.isFinite(part) && part > 0);
}

function elementChildrenByTag(root: ParentNode | null | undefined, tagName: string): Element[] {
  if (!root) {
    return [];
  }
  return Array.from(root.querySelectorAll(`:scope > ${tagName}`));
}

function roundBeats(value: number) {
  return Math.round(value * 100) / 100;
}

export function syncScoreStructure(score: {
  measures: MeasureInfo[];
  parts: RecognizedPart[];
  notes: NoteEvent[];
  structure?: ScoreStructure;
}) {
  const structure = score.structure;
  if (!structure) {
    return;
  }
  const numberMap = new Map<number, number>();
  for (const written of structure.writtenMeasures) {
    const measure = score.measures.find((item) => item.internalIndex === written.internalIndex);
    if (!measure || measure.displayNumber === written.displayNumber) {
      continue;
    }
    numberMap.set(written.displayNumber, measure.displayNumber);
    written.displayNumber = measure.displayNumber;
  }
  const remap = (value: number) => numberMap.get(value) ?? value;
  for (const region of structure.keySignatureRegions) {
    region.startMeasure = remap(region.startMeasure);
    region.endMeasure = remap(region.endMeasure);
  }
  for (const trace of structure.keyChangeTrace) {
    trace.measureNumber = remap(trace.measureNumber);
  }
  for (const region of structure.timeSignatureRegions) {
    region.startMeasure = remap(region.startMeasure);
    region.endMeasure = remap(region.endMeasure);
  }
  for (const region of structure.clefRegions) {
    region.startMeasure = remap(region.startMeasure);
    region.endMeasure = remap(region.endMeasure);
  }
  for (const event of structure.navigationEvents) {
    event.measureNumber = remap(event.measureNumber);
  }
  for (const step of structure.playbackRoute) {
    step.displayNumber = remap(step.displayNumber);
  }
  structure.partActivityRegions = buildPartActivity(score.parts, score.notes);
}

export function performanceTimeline(score: {
  measures: MeasureInfo[];
  notes: NoteEvent[];
  structure?: ScoreStructure;
}): { notes: NoteEvent[]; endBeat: number } | null {
  const route = score.structure?.playbackRoute;
  const navigation = score.structure?.navigationEvents ?? [];
  if (!route?.length || !navigation.length) {
    return null;
  }
  const displayNumbers = score.measures.map((measure) => measure.displayNumber);
  if (new Set(displayNumbers).size !== displayNumbers.length) {
    return null;
  }
  const notesByMeasure = new Map<number, NoteEvent[]>();
  for (const note of score.notes) {
    const bucket = notesByMeasure.get(note.measureNumber) ?? [];
    bucket.push(note);
    notesByMeasure.set(note.measureNumber, bucket);
  }
  const scheduled: NoteEvent[] = [];
  for (const step of route) {
    const measure = score.measures[step.internalIndex];
    if (!measure) {
      continue;
    }
    const delta = step.performanceStartBeat - measure.startBeat;
    for (const note of notesByMeasure.get(measure.displayNumber) ?? []) {
      scheduled.push({
        ...note,
        startBeat: note.startBeat + delta,
      });
    }
  }
  scheduled.sort((a, b) => a.startBeat - b.startBeat);
  return {
    notes: scheduled,
    endBeat: route[route.length - 1].performanceEndBeat,
  };
}
