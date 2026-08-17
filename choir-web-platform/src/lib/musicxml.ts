import type {
  CanonicalPartId,
  MeasureInfo,
  NoteEvent,
  ParsedScore,
  RecognizedPart,
} from "@/lib/score-types";

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

  const measureTemplate = readMeasureTemplate(partNodes[0]);
  const measureStartByNumber = new Map<number, number>();
  for (const measure of measureTemplate) {
    measureStartByNumber.set(measure.displayNumber, measure.startBeat);
  }
  const rehearsalMarks = readRehearsalMarks(partNodes[0]);
  const suggestedTempoBpm = readTempoHint(partNodes[0]) ?? 88;
  const keySignature = readKeySignature(partNodes[0]);
  const notes: NoteEvent[] = [];
  const parts: RecognizedPart[] = [];

  partNodes.forEach((partNode, idx) => {
    const sourcePartId = partNode.getAttribute("id") ?? `P${idx + 1}`;
    const sourceName = partNameById.get(sourcePartId) ?? `Part ${idx + 1}`;
    const staves = estimatePartStaves(partNode);
    const isLikelyPiano =
      staves >= 2 || /piano|accomp|keyboard|organ/i.test(sourceName);

    const voiceGroups = isLikelyPiano ? null : detectSubstantiveVoices(partNode);

    if (!voiceGroups || voiceGroups.length <= 1) {
      // Single voice (or piano grand staff kept as one group): preserve the
      // simple, backward-compatible behavior of one RecognizedPart per part.
      const detected = detectCanonicalPart(sourceName, staves);
      const partMeta: RecognizedPart = {
        id: sourcePartId,
        sourceName,
        canonicalPart: detected.canonicalPart,
        staves,
        sourcePartId,
        voiceNumber: null,
        needsConfirmation: !detected.confident,
        pitchRangeLow: null,
        pitchRangeHigh: null,
        firstMeasureNumber: null,
        lastMeasureNumber: null,
      };
      parts.push(partMeta);
      processPartNotes(partNode, () => partMeta, notes, measureStartByNumber);
      return;
    }

    // Multiple substantive voices share this single staff (e.g. Soprano+Alto
    // on one staff). Split into one RecognizedPart per voice so each can be
    // isolated during rehearsal, instead of treating the whole staff as one
    // undifferentiated part.
    const namedRoles = detectPairedVoiceNames(sourceName, voiceGroups.length);
    const voiceParts = new Map<number, RecognizedPart>();
    voiceGroups.forEach((group, voiceIdx) => {
      const id = `${sourcePartId}:v${group.voiceNumber}`;
      const roleFromName = namedRoles?.[voiceIdx] ?? null;
      voiceParts.set(group.voiceNumber, {
        id,
        sourceName: `${sourceName} (voice ${group.voiceNumber})`,
        canonicalPart: roleFromName ?? "UNKNOWN",
        staves,
        sourcePartId,
        voiceNumber: group.voiceNumber,
        needsConfirmation: roleFromName == null,
        pitchRangeLow: null,
        pitchRangeHigh: null,
        firstMeasureNumber: null,
        lastMeasureNumber: null,
      });
    });
    for (const partMeta of voiceParts.values()) {
      parts.push(partMeta);
    }
    processPartNotes(
      partNode,
      (voiceNumber) => voiceParts.get(voiceNumber) ?? voiceParts.values().next().value ?? null,
      notes,
      measureStartByNumber
    );
  });

  autoResolveUnknownParts(parts, notes);
  const canonicalByPartId = new Map(parts.map((part) => [part.id, part.canonicalPart]));
  for (const note of notes) {
    note.partCanonical = canonicalByPartId.get(note.partId) ?? note.partCanonical;
  }
  populatePartRanges(parts, notes);

  return {
    title: scoreTitle || "Untitled score",
    sourceType,
    parts,
    notes: notes.sort((a, b) => a.startBeat - b.startBeat),
    measures: measureTemplate,
    suggestedTempoBpm,
    keySignature,
    rehearsalMarks,
    rawMusicXml: xmlText,
  };
}

interface VoiceGroup {
  voiceNumber: number;
  noteCount: number;
  measureCount: number;
}

/**
 * Finds voice numbers within a part that carry real, independent melodic
 * content (as opposed to a stray voice=2 used once for an engraving quirk).
 * Returns null/[] when the part should be treated as a single voice.
 */
function detectSubstantiveVoices(partNode: Element): VoiceGroup[] | null {
  const measures = elementChildrenByTag(partNode, "measure");
  const stats = new Map<number, { noteCount: number; measures: Set<number> }>();

  measures.forEach((measure, idx) => {
    const measureNumber = parseIntOr(measure.getAttribute("number"), idx + 1);
    const noteNodes = elementChildrenByTag(measure, "note");
    for (const noteNode of noteNodes) {
      if (noteNode.querySelector("rest") != null) {
        continue;
      }
      if (noteNode.querySelector("pitch") == null) {
        continue;
      }
      const voiceNumber = parseIntOr(textOf(noteNode.querySelector("voice")), 1);
      if (!stats.has(voiceNumber)) {
        stats.set(voiceNumber, { noteCount: 0, measures: new Set() });
      }
      const entry = stats.get(voiceNumber);
      if (entry) {
        entry.noteCount += 1;
        entry.measures.add(measureNumber);
      }
    }
  });

  // A real independent choral voice sustains itself across a meaningful
  // stretch of the piece. A handful of scattered notes spread thinly across
  // many measures is much more often an Audiveris misread (a stray voice
  // number applied to a couple of noteheads) than a genuine extra part, so
  // the bar is set higher than "more than a couple of notes".
  const MIN_NOTES = 6;
  const MIN_MEASURES = 3;
  const groups: VoiceGroup[] = Array.from(stats.entries())
    .map(([voiceNumber, entry]) => ({
      voiceNumber,
      noteCount: entry.noteCount,
      measureCount: entry.measures.size,
    }))
    .filter((group) => group.noteCount >= MIN_NOTES && group.measureCount >= MIN_MEASURES)
    .sort((a, b) => a.voiceNumber - b.voiceNumber);

  return groups.length >= 2 ? groups : null;
}

/**
 * If a shared-staff part is explicitly labeled with two role names
 * (e.g. "Soprano/Alto", "S/A", "Tenor Bass", "T. B."), map each detected
 * voice (in ascending voice-number order, which by MusicXML/engraving
 * convention places the higher voice first) to its named role.
 * Returns null when the name doesn't clearly identify multiple roles.
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

function processPartNotes(
  partNode: Element,
  resolvePartForVoice: (voiceNumber: number) => RecognizedPart | null,
  notes: NoteEvent[],
  measureStartByNumber: Map<number, number>
) {
  let divisions = 1;
  const measures = elementChildrenByTag(partNode, "measure");
  for (let idx = 0; idx < measures.length; idx += 1) {
    const measure = measures[idx];
    const measureNumber = parseIntOr(
      measure.getAttribute("number"),
      idx + 1
    );
    const attrs = measure.querySelector("attributes");
    if (attrs) {
      const maybeDivs = parseIntOr(textOf(attrs.querySelector("divisions")), divisions);
      divisions = Math.max(1, maybeDivs);
    }
    let cursorDivs = 0;
    let lastChordStartDivs = 0;
    const children = Array.from(measure.children);
    for (const child of children) {
      if (child.tagName === "backup") {
        const duration = parseIntOr(textOf(child.querySelector("duration")), 0);
        cursorDivs = Math.max(0, cursorDivs - duration);
        continue;
      }
      if (child.tagName === "forward") {
        const duration = parseIntOr(textOf(child.querySelector("duration")), 0);
        cursorDivs += duration;
        continue;
      }
      if (child.tagName !== "note") {
        continue;
      }
      const durationDivs = parseIntOr(textOf(child.querySelector("duration")), 0);
      const isChord = child.querySelector("chord") != null;
      const isRest = child.querySelector("rest") != null;
      const startDivs = isChord ? lastChordStartDivs : cursorDivs;
      if (!isChord) {
        lastChordStartDivs = startDivs;
        cursorDivs += durationDivs;
      }
      if (isRest || durationDivs <= 0) {
        continue;
      }
      const pitch = child.querySelector("pitch");
      if (!pitch) {
        continue;
      }
      const midi = pitchToMidi(
        textOf(pitch.querySelector("step")),
        parseIntOr(textOf(pitch.querySelector("octave")), Number.NaN),
        parseIntOr(textOf(pitch.querySelector("alter")), 0)
      );
      if (midi == null) {
        continue;
      }
      const voiceNumber = parseIntOr(textOf(child.querySelector("voice")), 1);
      const partMeta = resolvePartForVoice(voiceNumber);
      if (!partMeta) {
        continue;
      }
      const measureStart = measureStartByNumber.get(measureNumber) ?? (measureNumber - 1) * 4;
      notes.push({
        partId: partMeta.id,
        partCanonical: partMeta.canonicalPart,
        midi,
        startBeat: measureStart + startDivs / divisions,
        durationBeats: durationDivs / divisions,
        measureNumber,
        velocity: partMeta.canonicalPart === "PIANO" ? 0.72 : 0.82,
      });
    }
  }
}

function readMeasureTemplate(partNode: Element): MeasureInfo[] {
  const measures = elementChildrenByTag(partNode, "measure");
  const template: MeasureInfo[] = [];
  let currentBeats = 4;
  let currentBeatType = 4;
  let currentDivisions = 1;
  let cursorBeats = 0;

  measures.forEach((measureNode, idx) => {
    const time = measureNode.querySelector("attributes > time");
    const beats = parseIntOr(textOf(time?.querySelector("beats")), currentBeats);
    const beatType = parseIntOr(textOf(time?.querySelector("beat-type")), currentBeatType);
    currentBeats = Math.max(1, beats);
    currentBeatType = Math.max(1, beatType);

    const divisions = parseIntOr(
      textOf(measureNode.querySelector("attributes > divisions")),
      currentDivisions
    );
    currentDivisions = Math.max(1, divisions);

    const measureDurationBeats = inferMeasureDurationBeats(
      measureNode,
      currentBeats,
      currentBeatType,
      currentDivisions
    );
    const displayNumber = parseIntOr(measureNode.getAttribute("number"), idx + 1);
    template.push({
      displayNumber,
      internalIndex: idx,
      startBeat: cursorBeats,
      endBeat: cursorBeats + measureDurationBeats,
      beatsInMeasure: measureDurationBeats,
      timeSignature: `${currentBeats}/${currentBeatType}`,
    });
    cursorBeats += measureDurationBeats;
  });

  return template;
}

function inferMeasureDurationBeats(
  measureNode: Element,
  beats: number,
  beatType: number,
  divisions: number
) {
  let maxCursor = 0;
  let cursor = 0;
  const children = Array.from(measureNode.children);
  for (const child of children) {
    if (child.tagName === "backup") {
      const duration = parseIntOr(textOf(child.querySelector("duration")), 0);
      cursor = Math.max(0, cursor - duration);
      continue;
    }
    if (child.tagName === "forward") {
      const duration = parseIntOr(textOf(child.querySelector("duration")), 0);
      cursor += duration;
      maxCursor = Math.max(maxCursor, cursor);
      continue;
    }
    if (child.tagName !== "note") {
      continue;
    }
    const duration = parseIntOr(textOf(child.querySelector("duration")), 0);
    if (child.querySelector("chord") == null) {
      cursor += duration;
      maxCursor = Math.max(maxCursor, cursor);
    } else {
      maxCursor = Math.max(maxCursor, cursor);
    }
  }

  if (maxCursor > 0) {
    return maxCursor / divisions;
  }
  return beats * (4 / beatType);
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
    const measureNumber = parseIntOr(measure.getAttribute("number"), NaN);
    for (const direction of directions) {
      const rehearsal = textOf(direction.querySelector("direction-type > rehearsal"));
      if (!rehearsal) {
        continue;
      }
      const label = rehearsal.toUpperCase();
      if (!label || !Number.isFinite(measureNumber)) {
        continue;
      }
      marks[label] = measureNumber;
    }
  }
  return marks;
}

function readTempoHint(partNode: Element) {
  const measures = elementChildrenByTag(partNode, "measure");
  for (const measure of measures) {
    const directions = elementChildrenByTag(measure, "direction");
    for (const direction of directions) {
      const sound = direction.querySelector("sound");
      const tempoAttr = sound?.getAttribute("tempo");
      const tempo = parseIntOr(tempoAttr, NaN);
      if (Number.isFinite(tempo) && tempo > 20 && tempo < 250) {
        return tempo;
      }
    }
  }
  return null;
}

function readKeySignature(partNode: Element) {
  const measures = elementChildrenByTag(partNode, "measure");
  for (const measure of measures) {
    const fifthsNode = measure.querySelector("attributes > key > fifths");
    if (!fifthsNode) {
      continue;
    }
    const fifths = parseIntOr(textOf(fifthsNode), NaN);
    if (!Number.isFinite(fifths)) {
      continue;
    }
    return describeKeySignature(fifths);
  }
  return null;
}

function describeKeySignature(fifths: number) {
  const majorKeys = [
    "Cb",
    "Gb",
    "Db",
    "Ab",
    "Eb",
    "Bb",
    "F",
    "C",
    "G",
    "D",
    "A",
    "E",
    "B",
    "F#",
    "C#",
  ];
  const index = fifths + 7;
  if (index >= 0 && index < majorKeys.length) {
    return `${majorKeys[index]} major`;
  }
  return `${fifths} fifths`;
}

function estimatePartStaves(partNode: Element) {
  const firstMeasure = elementChildrenByTag(partNode, "measure")[0];
  const stavesText = textOf(firstMeasure?.querySelector("attributes > staves"));
  const staves = parseIntOr(stavesText, 1);
  return Math.max(1, staves);
}

function detectCanonicalPart(
  sourceName: string,
  staves: number
): { canonicalPart: CanonicalPartId; confident: boolean } {
  const normalized = sourceName.toLowerCase();
  if (normalized.includes("soprano") || normalized === "s" || normalized === "sop.") {
    return { canonicalPart: "SOPRANO", confident: true };
  }
  if (normalized.includes("alto") || normalized === "a" || normalized === "alto.") {
    return { canonicalPart: "ALTO", confident: true };
  }
  if (normalized.includes("tenor") || normalized === "t" || normalized === "ten.") {
    return { canonicalPart: "TENOR", confident: true };
  }
  if (normalized.includes("bass") || normalized === "b" || normalized === "bs.") {
    return { canonicalPart: "BASS", confident: true };
  }
  if (
    normalized.includes("piano") ||
    normalized.includes("accomp") ||
    normalized.includes("keyboard") ||
    staves >= 2
  ) {
    return { canonicalPart: "PIANO", confident: true };
  }
  // No reliable name match (e.g. generic "Voice 1", "Voice 2"...). Leave
  // unresolved here rather than guessing by position - autoResolveUnknownParts
  // resolves every unnamed part together, by relative pitch, so a piece with
  // more voices than the 4 standard SATB slots doesn't get a voice forced
  // into a register it doesn't actually occupy.
  return { canonicalPart: "UNKNOWN", confident: false };
}

/**
 * Resolves every unnamed ("UNKNOWN") part/voice by relative pitch, assigning
 * the highest-registered remaining voice to the highest-registered remaining
 * SATB slot, and so on down. Crucially, this only fills as many slots as are
 * actually still open: if a piece has more independent voices than SATB
 * roles (e.g. a condensed choral reduction with divisi, or several shared
 * staves), the extra voices are left UNKNOWN rather than being forced into a
 * register they don't belong in (e.g. never labels a tenor-range voice
 * "BASS" just because "BASS" happened to be the last free label).
 */
function autoResolveUnknownParts(parts: RecognizedPart[], notes: NoteEvent[]) {
  const assigned = new Set(
    parts.filter((part) => part.canonicalPart !== "UNKNOWN").map((part) => part.canonicalPart)
  );
  const unknown = parts.filter((part) => part.canonicalPart === "UNKNOWN");
  if (!unknown.length) {
    return;
  }

  const midiByPart = new Map<string, number[]>();
  for (const note of notes) {
    if (!midiByPart.has(note.partId)) {
      midiByPart.set(note.partId, []);
    }
    midiByPart.get(note.partId)?.push(note.midi);
  }

  const rankedUnknown = [...unknown].sort(
    (a, b) => median(midiByPart.get(b.id) ?? []) - median(midiByPart.get(a.id) ?? [])
  );

  const satbOrder: CanonicalPartId[] = ["SOPRANO", "ALTO", "TENOR", "BASS"];
  const remainingRoles = satbOrder.filter((role) => !assigned.has(role));

  for (let i = 0; i < rankedUnknown.length && i < remainingRoles.length; i += 1) {
    const role = remainingRoles[i];
    rankedUnknown[i].canonicalPart = role;
    rankedUnknown[i].needsConfirmation = true;
    assigned.add(role);
  }
  // Any voices beyond the number of open SATB roles stay UNKNOWN - there is
  // no musically-defensible automatic guess for them, so the director is
  // asked via Identify Parts instead of receiving a wrong answer.
}

function pitchToMidi(step: string | null, octave: number, alter: number) {
  const normalizedStep = (step ?? "").toUpperCase();
  if (!normalizedStep || !Number.isFinite(octave)) {
    return null;
  }
  const stepOffset: Record<string, number> = {
    C: 0,
    D: 2,
    E: 4,
    F: 5,
    G: 7,
    A: 9,
    B: 11,
  };
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

function median(values: number[]) {
  if (!values.length) {
    return 64;
  }
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.floor(sorted.length / 2)];
}

