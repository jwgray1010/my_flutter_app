import type {
  CanonicalPartId,
  KeyRegion,
  MeasureInfo,
  NoteEvent,
  ParsedScore,
  RecognizedPart,
} from "@/lib/score-types";
import { buildPerformanceRoute, type RepeatMeasure } from "@/lib/repeats";
import { assignChoirRegisters, inferChoirVoicing } from "@/lib/voicing";

const MAJOR_KEYS = ["Cb", "Gb", "Db", "Ab", "Eb", "Bb", "F", "C", "G", "D", "A", "E", "B", "F#", "C#"];
const MINOR_KEYS = ["Ab", "Eb", "Bb", "F", "C", "G", "D", "A", "E", "B", "F#", "C#", "G#", "D#", "A#"];

export function parseMusicXmlToScore(
  xmlText: string,
  sourceType: "musicxml" | "omr"
): ParsedScore {
  const doc = new DOMParser().parseFromString(xmlText, "application/xml");
  if (doc.querySelector("parsererror")) {
    throw new Error("Invalid XML format.");
  }
  const root = doc.querySelector("score-partwise");
  if (!root) {
    throw new Error("Invalid MusicXML: missing score-partwise root.");
  }

  const scoreTitle = readTitle(root);
  const partList = elementChildrenByTag(root.querySelector("part-list"), "score-part");
  const partNameById = new Map<string, string>();
  for (const item of partList) {
    const id = item.getAttribute("id")?.trim() ?? "";
    if (!id) {
      continue;
    }
    const partName = textOf(item.querySelector("part-name")) || "Part";
    partNameById.set(id, partName || "Part");
  }

  const partNodes = elementChildrenByTag(root, "part");
  if (!partNodes.length) {
    throw new Error("Invalid MusicXML: no parts found.");
  }

  const timeline = readPartTimeline(partNodes[0]);
  const rehearsalMarks = readRehearsalMarks(partNodes[0]);
  const suggestedTempoBpm = readTempoHint(partNodes[0]) ?? 88;
  const notes: NoteEvent[] = [];
  const parts: RecognizedPart[] = [];

  partNodes.forEach((partNode, idx) => {
    const sourcePartId = partNode.getAttribute("id") ?? `P${idx + 1}`;
    const sourceName = partNameById.get(sourcePartId) ?? `Part ${idx + 1}`;
    const partTimeline = idx === 0 ? timeline : readPartTimeline(partNode);
    const staves = estimatePartStaves(partNode);
    const piano = partLooksLikePiano(sourceName, staves, readClefSigns(partNode));
    appendPartNotes(partTimeline.notes, {
      sourcePartId,
      sourceName,
      staves,
      piano,
      parts,
      notes,
    });
  });

  assignChoirRegisters(parts, notes);
  const canonicalByPartId = new Map(parts.map((part) => [part.id, part.canonicalPart]));
  for (const note of notes) {
    note.partCanonical = canonicalByPartId.get(note.partId) ?? note.partCanonical;
  }
  populatePartRanges(parts, notes);

  const keyRegions = timeline.keyRegions;
  return {
    title: scoreTitle || "Untitled score",
    sourceType,
    parts,
    notes: notes.sort((a, b) => a.startBeat - b.startBeat || a.midi - b.midi),
    measures: timeline.measures,
    suggestedTempoBpm,
    keySignature: keyRegions[0]?.label ?? null,
    keyRegions,
    inferredVoicing: inferChoirVoicing(parts),
    performanceRoute: buildPerformanceRoute(timeline.repeats),
    rehearsalMarks,
    rawMusicXml: xmlText,
  };
}

interface RawNote {
  voice: number;
  staff: number;
  midi: number;
  startBeat: number;
  durationBeats: number;
  measureNumber: number;
  tieStart: boolean;
  tieStop: boolean;
}

interface PartTimeline {
  measures: MeasureInfo[];
  notes: RawNote[];
  keyRegions: KeyRegion[];
  repeats: RepeatMeasure[];
}

function readPartTimeline(partNode: Element): PartTimeline {
  const measureNodes = elementChildrenByTag(partNode, "measure");
  const measures: MeasureInfo[] = [];
  const notes: RawNote[] = [];
  const keyRegions: KeyRegion[] = [];
  const repeats: RepeatMeasure[] = [];
  let divisions = 1;
  let beats = 4;
  let beatType = 4;
  let absoluteBeat = 0;
  const clefOctave = new Map<number, number>();
  let activeFifths: number | null = null;
  let activeMode: KeyRegion["mode"] | null = null;

  measureNodes.forEach((measureNode, index) => {
    const measureNumber = parseMeasureToken(measureNode.getAttribute("number"), index + 1);
    const voiceEnd = new Map<number, number>();
    let global = 0;
    let currentVoice = 1;
    let positioned = true;
    let lastChordStart = 0;
    const repeat: RepeatMeasure = {
      number: measureNumber,
      repeatForward: false,
      repeatBackward: false,
      repeatTimes: 2,
      ending: null,
    };

    for (const child of Array.from(measureNode.children)) {
      if (child.tagName === "attributes") {
        const divisionsText = textOf(child.querySelector(":scope > divisions"));
        if (divisionsText) {
          divisions = Math.max(1, parseIntOr(divisionsText, divisions));
        }
        const beatsText = textOf(child.querySelector(":scope > time > beats"));
        const beatTypeText = textOf(child.querySelector(":scope > time > beat-type"));
        if (beatsText) {
          beats = Math.max(1, parseIntOr(beatsText, beats));
        }
        if (beatTypeText) {
          beatType = Math.max(1, parseIntOr(beatTypeText, beatType));
        }
        const fifthsText = textOf(child.querySelector(":scope > key > fifths"));
        if (fifthsText) {
          const fifths = parseIntOr(fifthsText, 0);
          const modeText = (textOf(child.querySelector(":scope > key > mode")) ?? "major").toLowerCase();
          const mode: KeyRegion["mode"] = modeText === "minor" ? "minor" : "major";
          if (fifths !== activeFifths || mode !== activeMode) {
            keyRegions.push({
              startMeasure: measureNumber,
              fifths,
              mode,
              label: describeKeySignature(fifths, mode),
            });
            activeFifths = fifths;
            activeMode = mode;
          }
        }
        for (const clef of Array.from(child.querySelectorAll(":scope > clef"))) {
          const staff = parseIntOr(clef.getAttribute("number"), 1);
          clefOctave.set(staff, parseIntOr(textOf(clef.querySelector("clef-octave-change")), 0));
        }
        continue;
      }
      if (child.tagName === "barline") {
        readBarline(child, repeat);
        continue;
      }
      if (child.tagName === "backup") {
        global = Math.max(0, global - parseIntOr(textOf(child.querySelector("duration")), 0));
        positioned = true;
        continue;
      }
      if (child.tagName === "forward") {
        global += parseIntOr(textOf(child.querySelector("duration")), 0);
        positioned = true;
        continue;
      }
      if (child.tagName !== "note" || child.querySelector("grace") != null) {
        continue;
      }
      const cue = child.querySelector("cue") != null || child.getAttribute("size") === "cue";
      if (cue) {
        continue;
      }
      const durationDivs = parseIntOr(textOf(child.querySelector("duration")), 0);
      const voice = parseIntOr(textOf(child.querySelector("voice")), 1);
      const staff = parseIntOr(textOf(child.querySelector("staff")), 1);
      const chord = child.querySelector("chord") != null;
      let startDivs = global;
      if (!chord) {
        if (!positioned && voice !== currentVoice && !voiceEnd.has(voice)) {
          global = 0;
        }
        currentVoice = voice;
        positioned = false;
        startDivs = global;
        lastChordStart = startDivs;
        global += durationDivs;
        voiceEnd.set(voice, global);
      } else {
        startDivs = lastChordStart;
        voiceEnd.set(voice, Math.max(voiceEnd.get(voice) ?? 0, startDivs + durationDivs));
      }
      if (child.querySelector("rest") != null || durationDivs <= 0) {
        continue;
      }
      const pitch = child.querySelector("pitch");
      if (!pitch) {
        continue;
      }
      const written = pitchToMidi(
        textOf(pitch.querySelector("step")),
        parseIntOr(textOf(pitch.querySelector("octave")), Number.NaN),
        parseIntOr(textOf(pitch.querySelector("alter")), 0)
      );
      if (written == null) {
        continue;
      }
      const ties = tieFlags(child);
      notes.push({
        voice,
        staff,
        midi: written + 12 * (clefOctave.get(staff) ?? 0),
        startBeat: absoluteBeat + startDivs / divisions,
        durationBeats: durationDivs / divisions,
        measureNumber,
        tieStart: ties.start,
        tieStop: ties.stop,
      });
    }

    const nominal = beats * (4 / beatType);
    const content = voiceEnd.size ? Math.max(...voiceEnd.values()) / divisions : 0;
    const length = content > 0 ? content : nominal;
    measures.push({
      displayNumber: measureNumber,
      displayLabel: measureNode.getAttribute("number")?.trim() || String(measureNumber),
      internalIndex: index,
      startBeat: absoluteBeat,
      endBeat: absoluteBeat + length,
      beatsInMeasure: length,
      timeSignature: `${beats}/${beatType}`,
    });
    repeats.push(repeat);
    absoluteBeat += length;
  });

  return { measures, notes: mergeTiedNotes(notes), keyRegions, repeats };
}

function mergeTiedNotes(notes: RawNote[]): RawNote[] {
  const open = new Map<string, RawNote>();
  const merged: RawNote[] = [];
  for (const note of notes) {
    const key = `${note.voice}|${note.staff}|${note.midi}`;
    const previous = open.get(key);
    if (
      note.tieStop &&
      previous?.tieStart &&
      Math.abs(previous.startBeat + previous.durationBeats - note.startBeat) < 0.02
    ) {
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

function tieFlags(note: Element): { start: boolean; stop: boolean } {
  let start = false;
  let stop = false;
  for (const element of Array.from(note.querySelectorAll("tie, tied"))) {
    const type = element.getAttribute("type");
    if (type === "start") {
      start = true;
    }
    if (type === "stop") {
      stop = true;
    }
  }
  return { start, stop };
}

function readBarline(barline: Element, repeat: RepeatMeasure) {
  const repeatNode = barline.querySelector("repeat");
  if (repeatNode) {
    const direction = repeatNode.getAttribute("direction");
    if (direction === "forward") {
      repeat.repeatForward = true;
    }
    if (direction === "backward") {
      repeat.repeatBackward = true;
      repeat.repeatTimes = Math.max(2, parseIntOr(repeatNode.getAttribute("times"), 2));
    }
  }
  const ending = barline.querySelector("ending");
  if (ending && (ending.getAttribute("type") ?? "start") === "start") {
    const number = parseIntOr(ending.getAttribute("number")?.split(",")[0], Number.NaN);
    if (Number.isFinite(number)) {
      repeat.ending = number;
    }
  }
}

function appendPartNotes(
  rawNotes: RawNote[],
  input: {
    sourcePartId: string;
    sourceName: string;
    staves: number;
    piano: boolean;
    parts: RecognizedPart[];
    notes: NoteEvent[];
  }
) {
  if (input.piano || rawNotes.length === 0) {
    const detected = input.piano
      ? { canonicalPart: "PIANO" as const, confident: true, isSolo: false }
      : detectCanonicalPart(input.sourceName);
    const part = makePart({
      id: input.sourcePartId,
      sourceName: input.sourceName,
      sourcePartId: input.sourcePartId,
      canonicalPart: detected.canonicalPart,
      confident: detected.confident,
      isSolo: detected.isSolo,
      staves: input.staves,
      voiceNumber: null,
    });
    input.parts.push(part);
    for (const note of rawNotes) {
      input.notes.push(toNoteEvent(note, part));
    }
    return;
  }

  const splitByStaff = input.staves > 1;
  const grouped = new Map<string, RawNote[]>();
  for (const note of rawNotes) {
    const staff = splitByStaff ? note.staff : 0;
    const key = `${staff}:${note.voice}`;
    const list = grouped.get(key) ?? [];
    list.push(note);
    grouped.set(key, list);
  }
  const streams = [...grouped.entries()]
    .map(([key, streamNotes]) => {
      const [staffText, voiceText] = key.split(":");
      const measures = new Set(streamNotes.map((note) => note.measureNumber));
      return {
        staff: Number(staffText),
        voice: Number(voiceText),
        notes: streamNotes,
        measureCount: measures.size,
      };
    })
    .sort((a, b) => a.staff - b.staff || a.voice - b.voice);
  const substantive = streams.filter((stream) => stream.notes.length >= 6 && stream.measureCount >= 3);
  if (substantive.length < 2) {
    const detected = detectCanonicalPart(input.sourceName);
    const part = makePart({
      id: input.sourcePartId,
      sourceName: input.sourceName,
      sourcePartId: input.sourcePartId,
      canonicalPart: detected.canonicalPart,
      confident: detected.confident,
      isSolo: detected.isSolo,
      staves: input.staves,
      voiceNumber: null,
    });
    input.parts.push(part);
    for (const note of rawNotes) {
      input.notes.push(toNoteEvent(note, part));
    }
    return;
  }
  const selected = substantive;
  const multiple = true;
  const namedRoles = multiple && !splitByStaff ? detectPairedVoiceNames(input.sourceName, selected.length) : null;

  selected.forEach((stream, index) => {
    const detected = namedRoles?.[index]
      ? { canonicalPart: namedRoles[index] as CanonicalPartId, confident: true, isSolo: false }
      : multiple
        ? { canonicalPart: "UNKNOWN" as const, confident: false, isSolo: false }
        : detectCanonicalPart(input.sourceName);
    const id = !multiple
      ? input.sourcePartId
      : splitByStaff
        ? `${input.sourcePartId}:s${stream.staff}:v${stream.voice}`
        : `${input.sourcePartId}:v${stream.voice}`;
    const label = !multiple
      ? input.sourceName
      : splitByStaff
        ? `${input.sourceName} (staff ${stream.staff} voice ${stream.voice})`
        : `${input.sourceName} (voice ${stream.voice})`;
    const part = makePart({
      id,
      sourceName: label,
      sourcePartId: input.sourcePartId,
      canonicalPart: detected.canonicalPart,
      confident: detected.confident,
      isSolo: detected.isSolo || /\b(solo|descant)\b/i.test(input.sourceName),
      staves: input.staves,
      voiceNumber: multiple ? stream.voice : null,
    });
    input.parts.push(part);
    for (const note of stream.notes) {
      input.notes.push(toNoteEvent(note, part));
    }
  });

  if (substantive.length >= 2) {
    const stray = streams.filter((stream) => !selected.includes(stream));
    for (const stream of stray) {
      const host =
        selected.find((candidate) => candidate.staff === stream.staff) ?? selected[0];
      const hostPart = input.parts.find((part) =>
        splitByStaff
          ? part.id === `${input.sourcePartId}:s${host.staff}:v${host.voice}`
          : part.id === `${input.sourcePartId}:v${host.voice}`
      );
      if (!hostPart) {
        continue;
      }
      for (const note of stream.notes) {
        input.notes.push(toNoteEvent(note, hostPart));
      }
    }
  }
}

function makePart(input: {
  id: string;
  sourceName: string;
  sourcePartId: string;
  canonicalPart: CanonicalPartId;
  confident: boolean;
  isSolo: boolean;
  staves: number;
  voiceNumber: number | null;
}): RecognizedPart {
  return {
    id: input.id,
    sourceName: input.sourceName,
    canonicalPart: input.canonicalPart,
    staves: input.staves,
    sourcePartId: input.sourcePartId,
    voiceNumber: input.voiceNumber,
    needsConfirmation: !input.confident,
    isSolo: input.isSolo,
    pitchRangeLow: null,
    pitchRangeHigh: null,
    firstMeasureNumber: null,
    lastMeasureNumber: null,
  };
}

function toNoteEvent(note: RawNote, part: RecognizedPart): NoteEvent {
  return {
    partId: part.id,
    partCanonical: part.canonicalPart,
    midi: note.midi,
    startBeat: note.startBeat,
    durationBeats: note.durationBeats,
    measureNumber: note.measureNumber,
    velocity: part.canonicalPart === "PIANO" ? 0.72 : 0.82,
  };
}

function partLooksLikePiano(sourceName: string, staves: number, clefSigns: string[]): boolean {
  const normalized = sourceName.toLowerCase();
  if (/piano|accomp|keyboard|organ/.test(normalized)) {
    return true;
  }
  if (/soprano|alto|tenor|bass|choir|voice|solo|descant|baritone|canto|altus|bassus/.test(normalized)) {
    return false;
  }
  return staves >= 2 && clefSigns.includes("G") && clefSigns.includes("F");
}

function readClefSigns(partNode: Element): string[] {
  const signs: string[] = [];
  for (const clef of Array.from(partNode.querySelectorAll("clef"))) {
    const sign = textOf(clef.querySelector("sign"));
    if (sign) {
      signs.push(sign.toUpperCase());
    }
  }
  return signs;
}

/**
 * If a shared-staff part is explicitly labeled with two role names
 * (e.g. "Soprano/Alto", "S/A", "Tenor Bass", "T. B."), map each detected
 * voice (in ascending voice-number order) to its named role.
 */
function detectPairedVoiceNames(sourceName: string, voiceCount: number): (CanonicalPartId | null)[] | null {
  const normalized = sourceName.toLowerCase().replace(/[.\s]+/g, " ").trim();
  const pairs: Array<{ pattern: RegExp; roles: CanonicalPartId[] }> = [
    { pattern: /soprano.*alto|s\s*\/\s*a\b|^s a$|^sa$/, roles: ["SOPRANO", "ALTO"] },
    { pattern: /tenor.*bass|t\s*\/\s*b\b|^t b$|^tb$/, roles: ["TENOR", "BASS"] },
    { pattern: /soprano.*soprano|s\s*\/\s*s\b/, roles: ["SOPRANO", "SOPRANO"] },
    { pattern: /alto.*alto/, roles: ["ALTO", "ALTO"] },
    { pattern: /tenor.*tenor/, roles: ["TENOR", "TENOR"] },
    { pattern: /bass.*bass/, roles: ["BASS", "BASS"] },
  ];
  for (const { pattern, roles } of pairs) {
    if (pattern.test(normalized) && roles.length === voiceCount) {
      return roles;
    }
  }
  return null;
}

export function populatePartRanges(parts: RecognizedPart[], notes: NoteEvent[]) {
  for (const part of parts) {
    const partNotes = notes.filter((note) => note.partId === part.id);
    if (!partNotes.length) {
      part.pitchRangeLow = null;
      part.pitchRangeHigh = null;
      part.firstMeasureNumber = null;
      part.lastMeasureNumber = null;
      continue;
    }
    let low = Infinity;
    let high = -Infinity;
    let firstMeasure = Infinity;
    let lastMeasure = -Infinity;
    for (const note of partNotes) {
      low = Math.min(low, note.midi);
      high = Math.max(high, note.midi);
      firstMeasure = Math.min(firstMeasure, note.measureNumber);
      lastMeasure = Math.max(lastMeasure, note.measureNumber);
    }
    part.pitchRangeLow = Number.isFinite(low) ? low : null;
    part.pitchRangeHigh = Number.isFinite(high) ? high : null;
    part.firstMeasureNumber = Number.isFinite(firstMeasure) ? firstMeasure : null;
    part.lastMeasureNumber = Number.isFinite(lastMeasure) ? lastMeasure : null;
  }
}

function readTitle(root: Element) {
  const credits = elementChildrenByTag(root, "credit");
  for (const credit of credits) {
    const words = textOf(credit.querySelector("credit-words"));
    if (words) {
      return words;
    }
  }
  return textOf(root.querySelector("movement-title")) ?? "";
}

function readRehearsalMarks(partNode: Element) {
  const marks: Record<string, number> = {};
  const measures = elementChildrenByTag(partNode, "measure");
  for (const measure of measures) {
    const directions = elementChildrenByTag(measure, "direction");
    const measureNumber = parseMeasureToken(measure.getAttribute("number"), Number.NaN);
    for (const direction of directions) {
      const rehearsal = textOf(direction.querySelector("direction-type > rehearsal"));
      if (!rehearsal || !Number.isFinite(measureNumber)) {
        continue;
      }
      marks[rehearsal.toUpperCase()] = measureNumber;
    }
  }
  return marks;
}

function readTempoHint(partNode: Element) {
  const measures = elementChildrenByTag(partNode, "measure");
  for (const measure of measures) {
    const directions = elementChildrenByTag(measure, "direction");
    for (const direction of directions) {
      const tempo = parseIntOr(direction.querySelector("sound")?.getAttribute("tempo"), Number.NaN);
      if (Number.isFinite(tempo) && tempo > 20 && tempo < 250) {
        return tempo;
      }
    }
  }
  return null;
}

function describeKeySignature(fifths: number, mode: "major" | "minor") {
  const table = mode === "minor" ? MINOR_KEYS : MAJOR_KEYS;
  const index = fifths + 7;
  if (index >= 0 && index < table.length) {
    return `${table[index]} ${mode}`;
  }
  return `${fifths} fifths`;
}

function estimatePartStaves(partNode: Element) {
  const firstMeasure = elementChildrenByTag(partNode, "measure")[0];
  const staves = parseIntOr(textOf(firstMeasure?.querySelector("attributes > staves")), 1);
  return Math.max(1, staves);
}

function detectCanonicalPart(sourceName: string): {
  canonicalPart: CanonicalPartId;
  confident: boolean;
  isSolo: boolean;
} {
  const normalized = sourceName.toLowerCase();
  const isSolo = /\b(solo|descant)\b/.test(normalized);
  if (normalized.includes("soprano") || normalized === "s" || normalized === "sop.") {
    return { canonicalPart: "SOPRANO", confident: true, isSolo };
  }
  if (normalized.includes("alto") || normalized === "a" || normalized === "alto.") {
    return { canonicalPart: "ALTO", confident: true, isSolo };
  }
  if (normalized.includes("tenor") || normalized === "t" || normalized === "ten.") {
    return { canonicalPart: "TENOR", confident: true, isSolo };
  }
  if (normalized.includes("bass") || normalized === "b" || normalized === "bs.") {
    return { canonicalPart: "BASS", confident: true, isSolo };
  }
  if (normalized.includes("piano") || normalized.includes("accomp") || normalized.includes("keyboard")) {
    return { canonicalPart: "PIANO", confident: true, isSolo: false };
  }
  return { canonicalPart: "UNKNOWN", confident: false, isSolo };
}

function pitchToMidi(step: string | null, octave: number, alter: number) {
  const normalizedStep = (step ?? "").toUpperCase();
  if (!normalizedStep || !Number.isFinite(octave)) {
    return null;
  }
  const stepOffset: Record<string, number> = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };
  const base = stepOffset[normalizedStep];
  if (base == null) {
    return null;
  }
  return (octave + 1) * 12 + base + alter;
}

function elementChildrenByTag(root: ParentNode | null | undefined, tagName: string): Element[] {
  if (!root) {
    return [];
  }
  return Array.from(root.querySelectorAll(`:scope > ${tagName}`));
}

function textOf(el: Element | null | undefined) {
  const value = el?.textContent?.trim();
  return value?.length ? value : null;
}

function parseIntOr(value: string | null | undefined, fallback: number) {
  if (value == null || value.trim() === "") {
    return fallback;
  }
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function parseMeasureToken(value: string | null | undefined, fallback: number) {
  if (value == null || value.trim() === "") {
    return fallback;
  }
  const match = /^(\d+)/.exec(value.trim());
  if (!match) {
    return fallback;
  }
  return Number(match[1]);
}
