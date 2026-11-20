import type {
  CanonicalPartId,
  KeyRegion,
  MeasureInfo,
  NotationNote,
  NoteEvent,
  ParsedScore,
  RecognizedPart,
} from "@/lib/score-types";
import { featureFlags } from "@/lib/feature-flags";
import { buildPerformanceRoute, type RepeatMeasure } from "@/lib/repeats";
import { beatInUnison, pairedVoiceRoles, type UnisonSpan } from "@/lib/shared-voices";
import { mergeTiedNotes } from "@/lib/ties";
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
  const suggestedTempoBpm = timeline.tempoRegions[0]?.bpm ?? readTempoHint(partNodes[0]) ?? 88;
  const notes: NoteEvent[] = [];
  const notationNotes: NotationNote[] = [];
  const parts: RecognizedPart[] = [];

  partNodes.forEach((partNode, idx) => {
    const sourcePartId = partNode.getAttribute("id") ?? `P${idx + 1}`;
    const sourceName = partNameById.get(sourcePartId) ?? `Part ${idx + 1}`;
    const partTimeline = idx === 0 ? timeline : readPartTimeline(partNode);
    const staves = estimatePartStaves(partNode);
    const piano = partLooksLikePiano(sourceName, staves, readClefSigns(partNode));
    notationNotes.push(
      ...partTimeline.writtenNotes.map((note) => ({
        ...note,
        sourcePartId,
      }))
    );
    appendPartNotes(partTimeline.notes, {
      sourcePartId,
      sourceName,
      staves,
      piano,
      parts,
      notes,
      voiceActivity: partTimeline.voiceActivity,
      unisonSpans: partTimeline.unisonSpans,
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
    notationNotes,
    measures: timeline.measures,
    suggestedTempoBpm,
    tempoRegions: timeline.tempoRegions,
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

interface VoiceActivity {
  voice: number;
  staff: number;
  notes: number;
  rests: number;
}

interface PartTimeline {
  measures: MeasureInfo[];
  notes: RawNote[];
  writtenNotes: RawNote[];
  keyRegions: KeyRegion[];
  repeats: RepeatMeasure[];
  tempoRegions: { startBeat: number; bpm: number }[];
  voiceActivity: VoiceActivity[];
  unisonSpans: UnisonSpan[];
}

function readPartTimeline(partNode: Element): PartTimeline {
  const measureNodes = elementChildrenByTag(partNode, "measure");
  const measures: MeasureInfo[] = [];
  const notes: RawNote[] = [];
  const keyRegions: KeyRegion[] = [];
  const repeats: RepeatMeasure[] = [];
  const tempoRegions: { startBeat: number; bpm: number }[] = [];
  const voiceActivity = new Map<string, VoiceActivity>();
  const unisonSpans: UnisonSpan[] = [];
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
      if (child.tagName === "direction") {
        const tempo = parseIntOr(child.querySelector("sound")?.getAttribute("tempo"), Number.NaN);
        if (Number.isFinite(tempo) && tempo > 20 && tempo < 250) {
          const beat = absoluteBeat + global / divisions;
          const previous = tempoRegions[tempoRegions.length - 1];
          if (!previous || previous.bpm !== tempo || Math.abs(previous.startBeat - beat) > 1e-6) {
            tempoRegions.push({ startBeat: beat, bpm: tempo });
          }
        }
        readUnisonWords(child, absoluteBeat + global / divisions, unisonSpans);
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
      const isRest = child.querySelector("rest") != null || durationDivs <= 0;
      rememberVoice(voiceActivity, voice, staff, isRest);
      if (isRest) {
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

  const writtenNotes = notes.map((note) => ({ ...note }));
  return {
    measures,
    notes: mergeTiedNotes(notes),
    writtenNotes,
    keyRegions,
    repeats,
    tempoRegions,
    voiceActivity: [...voiceActivity.values()],
    unisonSpans,
  };
}

function readUnisonWords(direction: Element, beat: number, spans: UnisonSpan[]) {
  const staff = parseIntOr(textOf(direction.querySelector("staff")), 1);
  for (const wordsNode of Array.from(direction.querySelectorAll("words"))) {
    const words = (wordsNode.textContent ?? "").toLowerCase().replace(/\s+/g, " ").trim();
    if (/^(unis\.?|unison|a ?2)$/.test(words)) {
      spans.push({ staff, startBeat: beat, endBeat: null });
    } else if (/^(div\.?|divisi)$/.test(words)) {
      const open = [...spans].reverse().find((span) => span.staff === staff && span.endBeat == null);
      if (open) {
        open.endBeat = beat;
      } else {
        spans.push({ staff, startBeat: 0, endBeat: beat });
      }
    }
  }
}

function rememberVoice(activity: Map<string, VoiceActivity>, voice: number, staff: number, rest: boolean) {
  const key = `${staff}:${voice}`;
  const current = activity.get(key) ?? { voice, staff, notes: 0, rests: 0 };
  if (rest) {
    current.rests += 1;
  } else {
    current.notes += 1;
  }
  activity.set(key, current);
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
    voiceActivity: VoiceActivity[];
    unisonSpans: UnisonSpan[];
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
  const sharedRoles = featureFlags.sharedStaffVoices && !splitByStaff ? pairedVoiceRoles(input.sourceName) : null;
  if (sharedRoles) {
    appendNamedSharedVoices(rawNotes, sharedRoles, input);
    return;
  }
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
  const roles = pairedVoiceRoles(sourceName);
  if (roles && roles.length === voiceCount) {
    return roles;
  }
  return null;
}

function appendNamedSharedVoices(
  rawNotes: RawNote[],
  roles: [CanonicalPartId, CanonicalPartId],
  input: {
    sourcePartId: string;
    sourceName: string;
    staves: number;
    parts: RecognizedPart[];
    notes: NoteEvent[];
    voiceActivity: VoiceActivity[];
    unisonSpans: UnisonSpan[];
  }
) {
  const active = input.voiceActivity.filter((item) => item.notes > 0 || item.rests > 0);
  const voiceNumbers = [...new Set(active.map((item) => item.voice))].sort((left, right) => left - right);
  const voiceForRole: Array<number | null> = roles.map((_, index) =>
    voiceNumbers.includes(index + 1) ? index + 1 : null
  );
  const used = new Set(voiceForRole.filter((voice): voice is number => voice != null));
  const leftovers = voiceNumbers.filter((voice) => !used.has(voice));
  for (let index = 0; index < voiceForRole.length && leftovers.length > 0; index += 1) {
    if (voiceForRole[index] == null) {
      voiceForRole[index] = leftovers.shift() ?? null;
    }
  }
  const missingVoice = voiceForRole.some((voice) => voice == null);
  const explicitRest = active.some((item) => item.notes === 0 && item.rests > 0);
  const ambiguous = missingVoice && !explicitRest && input.unisonSpans.length === 0;
  const created: RecognizedPart[] = [];
  const partByVoice = new Map<number, RecognizedPart>();
  roles.forEach((role, index) => {
    const voice = voiceForRole[index] ?? index + 1;
    const part = makePart({
      id: `${input.sourcePartId}:v${voice}`,
      sourceName: `${input.sourceName} (voice ${voice})`,
      sourcePartId: input.sourcePartId,
      canonicalPart: role,
      confident: !ambiguous,
      isSolo: false,
      staves: input.staves,
      voiceNumber: voice,
    });
    input.parts.push(part);
    created.push(part);
    if (voiceForRole[index] != null) {
      partByVoice.set(voiceForRole[index] as number, part);
    }
  });

  const rows: Array<{ raw: RawNote; event: NoteEvent }> = [];
  for (const note of rawNotes) {
    const part = partByVoice.get(note.voice) ?? created[0];
    if (!part) {
      continue;
    }
    rows.push({ raw: note, event: toNoteEvent(note, part) });
  }
  const dropped = new Set<NoteEvent>();
  for (const row of rows) {
    if (dropped.has(row.event) || !beatInUnison(input.unisonSpans, row.raw.staff, row.raw.startBeat)) {
      continue;
    }
    const others = rows.filter(
      (other) =>
        other !== row &&
        other.raw.staff === row.raw.staff &&
        Math.abs(other.raw.startBeat - row.raw.startBeat) < 0.02
    );
    if (others.some((other) => other.raw.midi !== row.raw.midi)) {
      continue;
    }
    const twins = others.filter(
      (other) =>
        other.raw.midi === row.raw.midi && Math.abs(other.raw.durationBeats - row.raw.durationBeats) < 0.02
    );
    const keeperVoice = Math.min(row.raw.voice, ...twins.map((twin) => twin.raw.voice));
    if (row.raw.voice !== keeperVoice) {
      continue;
    }
    for (const twin of twins) {
      dropped.add(twin.event);
      row.event.unisonPartIds = [...new Set([...(row.event.unisonPartIds ?? []), twin.event.partId])];
    }
    if (twins.length === 0) {
      row.event.unisonPartIds = created.filter((part) => part.id !== row.event.partId).map((part) => part.id);
    }
  }
  const emitted = rows.filter((row) => !dropped.has(row.event)).map((row) => row.event);
  input.notes.push(...emitted);

  const unisonPassage = emitted.length > 0 && emitted.every((note) => (note.unisonPartIds?.length ?? 0) > 0);
  for (const part of created) {
    const own = emitted.filter((note) => note.partId === part.id);
    if (ambiguous) {
      part.sharedPlacement = "ambiguous";
    } else if (unisonPassage) {
      part.sharedPlacement = "unison";
    } else if (own.length === 0) {
      part.sharedPlacement = "resting";
    } else {
      part.sharedPlacement = "independent";
    }
  }
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
