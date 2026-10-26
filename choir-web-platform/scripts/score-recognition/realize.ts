import type {
  ClefSpec,
  ExpectedEvent,
  ExpectedScore,
  FixtureProvenance,
  FixtureSpec,
  KeySpec,
  NoteSpec,
  PartSpec,
  RealizedFixture,
  TimeSpec,
  VoiceSpec,
} from "./types";

const DIVISIONS = 4;

const PROVENANCE: FixtureProvenance = {
  sourceUrl: null,
  originalAuthor: "Rehearsal Keys test fixture (original)",
  license: "Test fixture generated for this repository. No third-party musical work.",
  sourceFormat: "symbolic-spec",
  referenceFormat: "musicxml+independent-spec",
  downloadDate: null,
  conversionMethod:
    "Hand-specified musical plan serialized to MusicXML. Expected pitches, entrances, keys, and routes are computed from that plan, not from the Rehearsal Keys parser.",
  origin: "synthetic",
};

export function realizeFixture(spec: FixtureSpec): RealizedFixture {
  return {
    spec,
    xml: buildMusicXml(spec),
    expected: buildExpected(spec),
    provenance: PROVENANCE,
  };
}

export function timeAt(spec: FixtureSpec, measure: number): TimeSpec {
  let current = spec.time;
  for (const change of spec.timeChanges ?? []) {
    if (change.measure <= measure) {
      current = change.time;
    }
  }
  return current;
}

export function keyAt(spec: FixtureSpec, measure: number): KeySpec {
  let current = spec.key;
  for (const change of spec.keyChanges ?? []) {
    if (change.measure <= measure) {
      current = change.key;
    }
  }
  return current;
}

/** Quarter-note length of a written measure, from the spec's meter. */
export function measureQuarterLength(spec: FixtureSpec, measure: number): number {
  if (measure === 1 && spec.pickupQuarters != null) {
    return spec.pickupQuarters;
  }
  const time = timeAt(spec, measure);
  return time.beats * (4 / time.beatType);
}

export function measureStartBeat(spec: FixtureSpec, measure: number): number {
  let cursor = 0;
  for (let number = 1; number < measure; number += 1) {
    cursor += measureQuarterLength(spec, number);
  }
  return cursor;
}

function buildExpected(spec: FixtureSpec): ExpectedScore {
  const measureBeats: number[] = [];
  const timeSignatures: string[] = [];
  for (let measure = 1; measure <= spec.measures; measure += 1) {
    measureBeats.push(measureQuarterLength(spec, measure));
    const time = timeAt(spec, measure);
    timeSignatures.push(`${time.beats}/${time.beatType}`);
  }

  const keyRegions = [{ startMeasure: 1, ...spec.key }];
  for (const change of spec.keyChanges ?? []) {
    keyRegions.push({ startMeasure: change.measure, ...change.key });
  }

  const events: ExpectedEvent[] = [];
  const entrances: { partId: string; measure: number }[] = [];
  let logicalPartCount = 0;
  let pianoEntrance: number | null = null;

  for (const part of spec.parts) {
    const ids = logicalStreamIds(part);
    if (part.piano) {
      const merged = mergeTies(soundingEvents(spec, part, part.id));
      events.push(...merged);
      const entrance = firstMeasure(merged, spec);
      if (entrance != null) {
        pianoEntrance = pianoEntrance == null ? entrance : Math.min(pianoEntrance, entrance);
      }
      continue;
    }
    logicalPartCount += ids.length;
    for (const id of ids) {
      const streamEvents = mergeTies(soundingEvents(spec, part, id));
      events.push(...streamEvents);
      const entrance = firstMeasure(streamEvents, spec);
      if (entrance != null) {
        entrances.push({ partId: id, measure: entrance });
      }
    }
  }

  return {
    voicing: spec.expectedVoicing,
    logicalPartCount,
    accompaniment: spec.accompaniment,
    pianoEntranceMeasure: pianoEntrance,
    soloCount: spec.soloCount,
    writtenMeasureCount: spec.measures,
    timeSignatures,
    measureBeats,
    keyRegions,
    performanceRoute: routeFromSpec(spec),
    entrances,
    events,
  };
}

function firstMeasure(events: ExpectedEvent[], spec: FixtureSpec): number | null {
  if (!events.length) {
    return null;
  }
  let best = events[0].startBeat;
  for (const event of events) {
    best = Math.min(best, event.startBeat);
  }
  let cursor = 0;
  for (let measure = 1; measure <= spec.measures; measure += 1) {
    const length = measureQuarterLength(spec, measure);
    if (best < cursor + length - 0.001) {
      return measure;
    }
    cursor += length;
  }
  return spec.measures;
}

function routeFromSpec(spec: FixtureSpec): number[] {
  const written = Array.from({ length: spec.measures }, (_, index) => index + 1);
  if (!spec.repeat) {
    return written;
  }
  if (spec.repeat.kind === "simple") {
    return [...written, ...written];
  }
  const first: number[] = [];
  const second: number[] = [];
  for (const measure of written) {
    if (measure === spec.repeat.secondEnding) {
      continue;
    }
    first.push(measure);
  }
  for (const measure of written) {
    if (measure === spec.repeat.firstEnding) {
      continue;
    }
    second.push(measure);
  }
  return [...first, ...second];
}

function logicalStreamIds(part: PartSpec): string[] {
  if (part.piano) {
    return [part.id];
  }
  const streams = part.voices;
  if (streams.length <= 1) {
    return [part.id];
  }
  const multiStaff = (part.staves ?? 1) > 1;
  return streams.map((voice) => streamId(part, voice, multiStaff));
}

function streamId(part: PartSpec, voice: VoiceSpec, multiStaff: boolean): string {
  if (part.voices.length <= 1) {
    return part.id;
  }
  if (multiStaff) {
    return `${part.id}:s${voice.staff ?? 1}:v${voice.voice}`;
  }
  return `${part.id}:v${voice.voice}`;
}

interface TaggedEvent extends ExpectedEvent {
  tieStart: boolean;
  tieStop: boolean;
}

function soundingEvents(spec: FixtureSpec, part: PartSpec, partId: string): TaggedEvent[] {
  const multiStaff = (part.staves ?? 1) > 1;
  const events: TaggedEvent[] = [];
  for (const voice of part.voices) {
    const id = part.piano ? part.id : streamId(part, voice, multiStaff);
    if (id !== partId) {
      continue;
    }
    const staff = voice.staff ?? 1;
    const octave = clefOctave(part, staff);
    for (const note of voice.notes) {
      if (note.cue) {
        continue;
      }
      events.push({
        partId,
        startBeat: measureStartBeat(spec, note.measure) + note.beat,
        midi: note.midi + octave * 12,
        duration: note.duration,
        tieStart: note.tie === "start" || note.tie === "continue",
        tieStop: note.tie === "stop" || note.tie === "continue",
      });
    }
  }
  return events.sort((a, b) => a.startBeat - b.startBeat || a.midi - b.midi);
}

function clefOctave(part: PartSpec, staff: number): number {
  const clef = part.clefs.find((item) => (item.staff ?? 1) === staff) ?? part.clefs[0];
  return clef?.octaveChange ?? 0;
}

function mergeTies(events: TaggedEvent[]): ExpectedEvent[] {
  const open = new Map<string, TaggedEvent>();
  const merged: TaggedEvent[] = [];
  for (const event of events) {
    const key = `${event.partId}|${event.midi}`;
    const previous = open.get(key);
    if (
      event.tieStop &&
      previous?.tieStart &&
      Math.abs(previous.startBeat + previous.duration - event.startBeat) < 0.02
    ) {
      previous.duration += event.duration;
      previous.tieStart = event.tieStart;
      if (!event.tieStart) {
        open.delete(key);
      }
      continue;
    }
    const copy = { ...event };
    merged.push(copy);
    if (event.tieStart) {
      open.set(key, copy);
    } else {
      open.delete(key);
    }
  }
  return merged.map((event) => ({
    partId: event.partId,
    startBeat: event.startBeat,
    midi: event.midi,
    duration: event.duration,
  }));
}

function buildMusicXml(spec: FixtureSpec): string {
  const partList = spec.parts
    .map(
      (part) =>
        `    <score-part id="${escapeXml(part.id)}"><part-name>${escapeXml(part.name)}</part-name></score-part>`
    )
    .join("\n");
  const parts = spec.parts.map((part) => renderPart(spec, part)).join("\n");
  return `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <movement-title>${escapeXml(spec.title)}</movement-title>
  <part-list>
${partList}
  </part-list>
${parts}
</score-partwise>
`;
}

function renderPart(spec: FixtureSpec, part: PartSpec): string {
  const measures: string[] = [];
  for (let measure = 1; measure <= spec.measures; measure += 1) {
    measures.push(renderMeasure(spec, part, measure));
  }
  return `  <part id="${escapeXml(part.id)}">\n${measures.join("\n")}\n  </part>`;
}

function renderMeasure(spec: FixtureSpec, part: PartSpec, measure: number): string {
  const chunks: string[] = [];
  chunks.push(`    <measure number="${measure}">`);
  const header = renderAttributes(spec, part, measure);
  if (header) {
    chunks.push(header);
  }
  const left = leftBarline(spec, measure);
  if (left) {
    chunks.push(left);
  }
  chunks.push(renderVoices(spec, part, measure));
  const right = rightBarline(spec, measure);
  if (right) {
    chunks.push(right);
  }
  chunks.push("    </measure>");
  return chunks.join("\n");
}

function renderAttributes(spec: FixtureSpec, part: PartSpec, measure: number): string | null {
  const lines: string[] = [];
  const time = timeAt(spec, measure);
  const previousTime = measure > 1 ? timeAt(spec, measure - 1) : null;
  const key = keyAt(spec, measure);
  const previousKey = measure > 1 ? keyAt(spec, measure - 1) : null;
  const timeChanged =
    measure === 1 ||
    !previousTime ||
    previousTime.beats !== time.beats ||
    previousTime.beatType !== time.beatType;
  const keyChanged =
    measure === 1 ||
    !previousKey ||
    previousKey.fifths !== key.fifths ||
    previousKey.mode !== key.mode;
  if (measure !== 1 && !timeChanged && !keyChanged) {
    return null;
  }
  lines.push("      <attributes>");
  if (measure === 1) {
    lines.push(`        <divisions>${DIVISIONS}</divisions>`);
  }
  if (keyChanged) {
    lines.push(
      `        <key><fifths>${key.fifths}</fifths><mode>${key.mode}</mode></key>`
    );
  }
  if (timeChanged && !(measure === 1 && spec.pickupQuarters != null && measure !== 1)) {
    lines.push(
      `        <time><beats>${time.beats}</beats><beat-type>${time.beatType}</beat-type></time>`
    );
  }
  if (measure === 1) {
    const staves = part.staves ?? 1;
    if (staves > 1) {
      lines.push(`        <staves>${staves}</staves>`);
    }
    for (const clef of part.clefs) {
      lines.push(renderClef(clef, part.clefs.length > 1 || (part.staves ?? 1) > 1));
    }
  }
  lines.push("      </attributes>");
  return lines.join("\n");
}

function renderClef(clef: ClefSpec, numbered: boolean): string {
  const number = numbered ? ` number="${clef.staff ?? 1}"` : "";
  const octave =
    clef.octaveChange != null && clef.octaveChange !== 0
      ? `<clef-octave-change>${clef.octaveChange}</clef-octave-change>`
      : "";
  return `        <clef${number}><sign>${clef.sign}</sign><line>${clef.line}</line>${octave}</clef>`;
}

function leftBarline(spec: FixtureSpec, measure: number): string | null {
  if (!spec.repeat) {
    return null;
  }
  if (measure === 1) {
    return `      <barline location="left"><barline-style>heavy-light</barline-style><repeat direction="forward"/></barline>`;
  }
  if (spec.repeat.kind === "volta" && measure === spec.repeat.firstEnding) {
    return `      <barline location="left"><ending number="1" type="start"/></barline>`;
  }
  if (spec.repeat.kind === "volta" && measure === spec.repeat.secondEnding) {
    return `      <barline location="left"><ending number="2" type="start"/></barline>`;
  }
  return null;
}

function rightBarline(spec: FixtureSpec, measure: number): string | null {
  if (!spec.repeat) {
    return null;
  }
  if (spec.repeat.kind === "simple" && measure === spec.measures) {
    return `      <barline location="right"><barline-style>light-heavy</barline-style><repeat direction="backward"/></barline>`;
  }
  if (spec.repeat.kind === "volta" && measure === spec.repeat.firstEnding) {
    return `      <barline location="right"><ending number="1" type="stop"/><repeat direction="backward"/></barline>`;
  }
  if (spec.repeat.kind === "volta" && measure === spec.repeat.secondEnding) {
    return `      <barline location="right"><ending number="2" type="stop"/><barline-style>light-heavy</barline-style></barline>`;
  }
  return null;
}

function renderVoices(spec: FixtureSpec, part: PartSpec, measure: number): string {
  const lengthDivs = Math.round(measureQuarterLength(spec, measure) * DIVISIONS);
  const blocks: string[] = [];
  part.voices.forEach((voice, index) => {
    if (index > 0 && !part.omitBackup) {
      blocks.push(`      <backup><duration>${lengthDivs}</duration></backup>`);
    }
    blocks.push(renderVoiceContents(spec, part, voice, measure, lengthDivs));
  });
  return blocks.filter(Boolean).join("\n");
}

function renderVoiceContents(
  spec: FixtureSpec,
  part: PartSpec,
  voice: VoiceSpec,
  measure: number,
  lengthDivs: number
): string {
  const notes = voice.notes
    .filter((note) => note.measure === measure)
    .slice()
    .sort((a, b) => a.beat - b.beat || a.midi - b.midi);
  const staff = voice.staff ?? 1;
  const showStaff = (part.staves ?? 1) > 1;
  const lines: string[] = [];
  if (part.omitBackup && voice !== part.voices[0]) {
    for (const note of notes) {
      lines.push(renderNote(note, voice.voice, staff, showStaff, false));
    }
    return lines.join("\n");
  }
  let cursor = 0;
  let index = 0;
  while (index < notes.length) {
    const beatDivs = Math.round(notes[index].beat * DIVISIONS);
    if (beatDivs > cursor) {
      lines.push(renderRest(voice.voice, staff, showStaff, beatDivs - cursor));
      cursor = beatDivs;
    }
    const chord = notes.filter((note) => Math.round(note.beat * DIVISIONS) === beatDivs);
    chord.forEach((note, chordIndex) => {
      lines.push(renderNote(note, voice.voice, staff, showStaff, chordIndex > 0));
    });
    const durationDivs = Math.round(notes[index].duration * DIVISIONS);
    if (!notes[index].cue) {
      cursor += durationDivs;
    }
    index += chord.length;
  }
  if (cursor < lengthDivs) {
    lines.push(renderRest(voice.voice, staff, showStaff, lengthDivs - cursor));
  }
  return lines.join("\n");
}

function renderRest(voice: number, staff: number, showStaff: boolean, durationDivs: number): string {
  const staffXml = showStaff ? `<staff>${staff}</staff>` : "";
  return `      <note><rest/>${staffXml}<duration>${durationDivs}</duration><voice>${voice}</voice><type>${typeFor(durationDivs)}</type></note>`;
}

function renderNote(
  note: NoteSpec,
  voice: number,
  staff: number,
  showStaff: boolean,
  chord: boolean
): string {
  const pitch = midiToPitch(note.midi);
  const alter = pitch.alter === 0 ? "" : `<alter>${pitch.alter}</alter>`;
  const durationDivs = Math.round(note.duration * DIVISIONS);
  const tie =
    note.tie === "start"
      ? `<tie type="start"/>`
      : note.tie === "stop"
        ? `<tie type="stop"/>`
        : note.tie === "continue"
          ? `<tie type="stop"/><tie type="start"/>`
          : "";
  const tied =
    note.tie === "start"
      ? `<notations><tied type="start"/></notations>`
      : note.tie === "stop"
        ? `<notations><tied type="stop"/></notations>`
        : note.tie === "continue"
          ? `<notations><tied type="stop"/><tied type="start"/></notations>`
          : "";
  return [
    "      <note>",
    note.cue ? "<cue/>" : "",
    chord ? "<chord/>" : "",
    `<pitch><step>${pitch.step}</step>${alter}<octave>${pitch.octave}</octave></pitch>`,
    `<duration>${durationDivs}</duration>`,
    tie,
    `<voice>${voice}</voice>`,
    `<type>${typeFor(durationDivs)}</type>`,
    showStaff ? `<staff>${staff}</staff>` : "",
    tied,
    "</note>",
  ]
    .filter(Boolean)
    .join("");
}

function typeFor(durationDivs: number): string {
  if (durationDivs >= 16) return "whole";
  if (durationDivs >= 8) return "half";
  if (durationDivs >= 4) return "quarter";
  if (durationDivs >= 2) return "eighth";
  return "16th";
}

function midiToPitch(midi: number): { step: string; alter: number; octave: number } {
  const octave = Math.floor(midi / 12) - 1;
  const pitchClass = ((midi % 12) + 12) % 12;
  const names: Array<[string, number]> = [
    ["C", 0],
    ["C", 1],
    ["D", 0],
    ["D", 1],
    ["E", 0],
    ["F", 0],
    ["F", 1],
    ["G", 0],
    ["G", 1],
    ["A", 0],
    ["A", 1],
    ["B", 0],
  ];
  const [step, alter] = names[pitchClass];
  return { step, alter, octave };
}

function escapeXml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}
