/**
 * Synthetic choral reference library.
 *
 * Ground truth is the authored spec below, not Rehearsal Keys output.
 * The MusicXML is generated from that spec, then checked by an independent
 * XML walk before the recognition engine is allowed to see it.
 *
 * These are not engraved editions or scans. origin is "synthetic".
 * License: the generated examples are original to this repository and
 * released CC0. No third-party musical work is embedded.
 */

export type FixtureSet = "development" | "regression" | "heldout";

export interface ExpectedNote {
  partId: string;
  measure: number;
  midi: number;
  durationBeats: number;
  step: string;
  octave: number;
  alter: number;
}

export interface ScoreFixture {
  id: string;
  title: string;
  set: FixtureSet;
  origin: "synthetic";
  license: "CC0";
  sourceUrl: null;
  author: "Rehearsal Keys synthetic fixture";
  sourceFormat: "authored spec";
  referenceFormat: "MusicXML 3.1 generated from the spec";
  downloadDate: "2026-10-25";
  provenance: string;
  conversionMethod: "In-memory MusicXML writer in scripts/recognition-library.ts. No OMR and no Rehearsal Keys parser.";
  xml: string;
  expected: {
    voicing: string;
    choirCanonical: string[];
    featured: { id: string; canonical: string }[];
    accompaniment: "PIANO" | "NONE";
    pianoNeedsConfirmation: boolean;
    entrances: { id: string; measure: number | null }[];
    keyFifths: { start: number; fifths: number; name: string }[];
    meters: { start: number; signature: string }[];
    writtenMeasures: number;
    route: number[];
    pickup: boolean;
    notes: ExpectedNote[];
    clefs: { partId: string; sign: string; start: number }[];
  };
}

interface PartDef {
  id: string;
  name: string;
  role: "choir" | "featured" | "piano";
  canonical: string;
  staves?: number;
  clefs?: { at: number; sign: string; line: number }[];
  measures: string[];
  voices?: string[][];
}

interface ScoreDef {
  id: string;
  title: string;
  set: FixtureSet;
  voicing: string;
  fifths: { at: number; fifths: number; name: string }[];
  meters: { at: number; beats: number; beatType: number }[];
  parts: PartDef[];
  navigation?: "repeat" | "endings" | "ds-coda" | "dc-fine";
  pickup?: string;
  pianoNeedsConfirmation?: boolean;
}

const DIVISIONS = 2;
const PROVENANCE =
  "Synthetic structural example written for the recognition harness on 2026-10-25. Not a published edition.";

const STEP_OFFSET: Record<string, number> = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };

export function referenceMidi(step: string, octave: number, alter: number) {
  const base = STEP_OFFSET[step];
  if (base == null || !Number.isFinite(octave)) {
    throw new Error(`Bad reference pitch ${step}${octave}`);
  }
  return (octave + 1) * 12 + base + alter;
}

function parseToken(token: string): { rest: boolean; step: string; octave: number; alter: number; beats: number } {
  if (token === "r" || token.startsWith("r:")) {
    const beats = token.includes(":") ? Number(token.split(":")[1]) : 1;
    return { rest: true, step: "", octave: 0, alter: 0, beats };
  }
  const match = /^([A-G])([#b]?)(-?\d+)(?::(\d+(?:\.\d+)?))?$/.exec(token);
  if (!match) {
    throw new Error(`Bad pitch token ${token}`);
  }
  const alter = match[2] === "#" ? 1 : match[2] === "b" ? -1 : 0;
  return {
    rest: false,
    step: match[1],
    octave: Number(match[3]),
    alter,
    beats: match[4] ? Number(match[4]) : 1,
  };
}

function singing(pitch: string, measures: number, perMeasure: number) {
  return Array.from({ length: measures }, () => Array(perMeasure).fill(pitch).join(" "));
}

function resting(measures: number, perMeasure: number) {
  return Array.from({ length: measures }, () => Array(perMeasure).fill("r").join(" "));
}

function buildFixture(def: ScoreDef): ScoreFixture {
  const notes: ExpectedNote[] = [];
  const entrances: { id: string; measure: number | null }[] = [];
  const partXml: string[] = [];
  const measureNumbers = measurePlan(def);

  for (const part of def.parts) {
  const voiceCount = part.voices ? part.voices.length : 1;
    const split = voiceCount > 1;
    if (part.voices) {
      const length = part.voices[0].length;
      if (part.voices.some((voice) => voice.length !== length)) {
        throw new Error(`${def.id} voices differ in length`);
      }
    }
    const measureStrings = part.voices ? part.voices[0] : part.measures;
    measureStrings.forEach((row, index) => {
      const measureNumber = measureNumbers[index];
      const rows = part.voices ? part.voices.map((voice) => voice[index]) : [row];
      rows.forEach((tokens, voiceIndex) => {
        const partId = split ? `${part.id}:v${voiceIndex + 1}` : part.id;
        for (const token of tokens.split(/\s+/).filter(Boolean)) {
          const parsed = parseToken(token);
          if (parsed.rest) {
            continue;
          }
          notes.push({
            partId,
            measure: measureNumber,
            midi: referenceMidi(parsed.step, parsed.octave, parsed.alter),
            durationBeats: parsed.beats,
            step: parsed.step,
            octave: parsed.octave,
            alter: parsed.alter,
          });
        }
      });
    });
    const ids = split ? Array.from({ length: voiceCount }, (_, index) => `${part.id}:v${index + 1}`) : [part.id];
    for (const id of ids) {
      const own = notes.filter((note) => note.partId === id);
      entrances.push({
        id,
        measure: own.length ? Math.min(...own.map((note) => note.measure)) : null,
      });
    }
    partXml.push(renderPart(part, measureNumbers, def));
  }

  const xml = wrapScore(def, partXml);
  return {
    id: def.id,
    title: def.title,
    set: def.set,
    origin: "synthetic",
    license: "CC0",
    sourceUrl: null,
    author: "Rehearsal Keys synthetic fixture",
    sourceFormat: "authored spec",
    referenceFormat: "MusicXML 3.1 generated from the spec",
    downloadDate: "2026-10-25",
    provenance: PROVENANCE,
    conversionMethod:
      "In-memory MusicXML writer in scripts/recognition-library.ts. No OMR and no Rehearsal Keys parser.",
    xml,
    expected: {
      voicing: def.voicing,
      choirCanonical: choirCanonicalFrom(def),
      featured: def.parts
        .filter((part) => part.role === "featured")
        .map((part) => ({ id: part.id, canonical: part.canonical })),
      accompaniment: def.parts.some((part) => part.role === "piano") ? "PIANO" : "NONE",
      pianoNeedsConfirmation: def.pianoNeedsConfirmation ?? false,
      entrances,
      keyFifths: def.fifths.map((item) => ({ start: item.at, fifths: item.fifths, name: item.name })),
      meters: def.meters.map((item) => ({
        start: item.at,
        signature: `${item.beats}/${item.beatType}`,
      })),
    writtenMeasures: measureNumbers.length,
    route: routeFor(def, measureNumbers),
    pickup: Boolean(def.pickup),
    notes,
    clefs: def.parts.flatMap((part) =>
      (part.clefs ?? []).map((clef) => ({
        partId: part.id,
        sign: clef.sign,
        start: clef.at,
      }))
    ),
  },
};
}

function choirCanonicalFrom(def: ScoreDef) {
  const canonicals: string[] = [];
  for (const part of def.parts) {
    if (part.role !== "choir") {
      continue;
    }
    if (part.voices) {
      const names = splitCanonicals(part);
      canonicals.push(...names);
    } else {
      canonicals.push(part.canonical);
    }
  }
  return canonicals;
}

function splitCanonicals(part: PartDef) {
  if (part.canonical.includes("+")) {
    return part.canonical.split("+");
  }
  return Array.from({ length: part.voices?.length ?? 1 }, () => part.canonical);
}

function measurePlan(def: ScoreDef) {
  const length = def.parts[0].voices ? def.parts[0].voices[0].length : def.parts[0].measures.length;
  const numbers: number[] = [];
  if (def.pickup) {
    numbers.push(0);
  }
  for (let index = numbers.length; index < length; index += 1) {
    numbers.push(numbers.length === 0 || numbers[0] === 0 ? index - (def.pickup ? 0 : 1) + (def.pickup ? 0 : 1) : index + (def.pickup ? 0 : 1));
  }
  if (def.pickup) {
    return Array.from({ length }, (_, index) => (index === 0 ? 0 : index));
  }
  return Array.from({ length }, (_, index) => index + 1);
}

function routeFor(def: ScoreDef, measureNumbers: number[]) {
  if (def.navigation === "repeat") {
    return [1, 2, 1, 2, 3, 4];
  }
  if (def.navigation === "endings") {
    return [1, 2, 3, 1, 2, 4];
  }
  if (def.navigation === "ds-coda") {
    return [1, 2, 3, 4, 2, 3, 5];
  }
  if (def.navigation === "dc-fine") {
    return [1, 2, 3, 4, 1, 2];
  }
  return measureNumbers;
}

function wrapScore(def: ScoreDef, parts: string[]) {
  const list = def.parts
    .map(
      (part) =>
        `<score-part id="${part.id}"><part-name>${escapeXml(part.name)}</part-name></score-part>`
    )
    .join("");
  return `<?xml version="1.0" encoding="UTF-8"?><score-partwise version="3.1"><part-list>${list}</part-list>${parts.join("")}</score-partwise>`;
}

function renderPart(part: PartDef, measureNumbers: number[], def: ScoreDef) {
  const measureCount = part.voices ? part.voices[0].length : part.measures.length;
  let currentBeats = def.meters[0]?.beats ?? 4;
  let currentType = def.meters[0]?.beatType ?? 4;
  let currentFifths = def.fifths[0]?.fifths;
  let currentClef = part.clefs?.[0];
  const measures: string[] = [];
  for (let index = 0; index < measureCount; index += 1) {
    const number = measureNumbers[index];
    const meter = def.meters.find((item) => item.at === number);
    if (meter) {
      currentBeats = meter.beats;
      currentType = meter.beatType;
    }
    const key = def.fifths.find((item) => item.at === number);
    if (key) {
      currentFifths = key.fifths;
    }
    const clef = part.clefs?.find((item) => item.at === number) ?? (index === 0 ? currentClef : undefined);
    if (clef) {
      currentClef = clef;
    }
    const includeMeter = index === 0 || Boolean(meter);
    const includeKey = index === 0 || Boolean(key);
    const includeClef = index === 0 || Boolean(part.clefs?.find((item) => item.at === number));
    const voiceRows = part.voices ? part.voices.map((voice) => voice[index]) : [part.measures[index]];
    measures.push(
      renderMeasure({
        number,
        beats: index === 0 && def.pickup ? undefined : currentBeats,
        beatType: currentType,
        fifths: includeKey ? currentFifths : undefined,
        clef: includeClef ? currentClef : undefined,
        staves: index === 0 ? part.staves : undefined,
        includeMeter: includeMeter || index === 0,
        meterBeats: index === 0 && def.pickup ? def.meters[0].beats : currentBeats,
        meterType: currentType,
        forceMeter: index === 0 || Boolean(meter),
        voices: voiceRows,
        extras: extrasFor(def.navigation, number),
        pickupTokens: index === 0 ? def.pickup : undefined,
      })
    );
  }
  return `<part id="${part.id}">${measures.join("")}</part>`;
}

function extrasFor(navigation: ScoreDef["navigation"], number: number) {
  if (navigation === "repeat" && number === 1) {
    return `<barline location="left"><repeat direction="forward"/></barline>`;
  }
  if (navigation === "repeat" && number === 2) {
    return `<barline location="right"><repeat direction="backward"/></barline>`;
  }
  if (navigation === "endings" && number === 1) {
    return `<barline location="left"><repeat direction="forward"/></barline>`;
  }
  if (navigation === "endings" && number === 3) {
    return `<barline location="left"><ending number="1" type="start"/></barline><barline location="right"><ending number="1" type="stop"/><repeat direction="backward"/></barline>`;
  }
  if (navigation === "endings" && number === 4) {
    return `<barline location="left"><ending number="2" type="start"/></barline><barline location="right"><ending number="2" type="stop"/></barline>`;
  }
  if (navigation === "ds-coda" && number === 2) {
    return `<direction><direction-type><words>Segno</words></direction-type><sound segno="segno"/></direction>`;
  }
  if (navigation === "ds-coda" && number === 3) {
    return `<direction><direction-type><words>To Coda</words></direction-type><sound tocoda="coda"/></direction>`;
  }
  if (navigation === "ds-coda" && number === 4) {
    return `<direction><direction-type><words>D.S. al Coda</words></direction-type><sound dalsegno="segno"/></direction>`;
  }
  if (navigation === "ds-coda" && number === 5) {
    return `<direction><direction-type><words>Coda</words></direction-type><sound coda="coda"/></direction>`;
  }
  if (navigation === "dc-fine" && number === 2) {
    return `<direction><direction-type><words>Fine</words></direction-type><sound fine="yes"/></direction>`;
  }
  if (navigation === "dc-fine" && number === 4) {
    return `<direction><direction-type><words>D.C. al Fine</words></direction-type><sound dacapo="yes"/></direction>`;
  }
  return "";
}

function renderMeasure(input: {
  number: number;
  voices: string[];
  extras: string;
  fifths?: number;
  clef?: { sign: string; line: number };
  staves?: number;
  forceMeter: boolean;
  meterBeats: number;
  meterType: number;
  beats?: number;
  beatType: number;
  includeMeter: boolean;
  pickupTokens?: string;
}) {
  const attrs: string[] = [];
  if (input.number === 0 || input.forceMeter || input.fifths != null || input.clef || input.staves) {
    attrs.push(`<divisions>${DIVISIONS}</divisions>`);
    if (input.fifths != null) {
      attrs.push(`<key><fifths>${input.fifths}</fifths></key>`);
    }
    if (input.forceMeter) {
      attrs.push(`<time><beats>${input.meterBeats}</beats><beat-type>${input.meterType}</beat-type></time>`);
    }
    if (input.staves) {
      attrs.push(`<staves>${input.staves}</staves>`);
    }
    if (input.clef) {
      attrs.push(`<clef><sign>${input.clef.sign}</sign><line>${input.clef.line}</line></clef>`);
    }
  }
  const attributes = attrs.length ? `<attributes>${attrs.join("")}</attributes>` : "";
  const voiceXml = input.voices
    .map((tokens, index) => {
      const body = tokens
        .split(/\s+/)
        .filter(Boolean)
        .map((token) => noteXml(parseToken(token), index + 1))
        .join("");
      if (index === 0) {
        return body;
      }
      const divisions = input.voices[0]
        .split(/\s+/)
        .filter(Boolean)
        .reduce((sum, token) => sum + Math.round(parseToken(token).beats * DIVISIONS), 0);
      return `<backup><duration>${divisions}</duration></backup>${body}`;
    })
    .join("");
  return `<measure number="${input.number}">${attributes}${input.extras}${voiceXml}</measure>`;
}

function noteXml(token: ReturnType<typeof parseToken>, voice: number) {
  const duration = Math.round(token.beats * DIVISIONS);
  if (token.rest) {
    return `<note><rest/><duration>${duration}</duration><voice>${voice}</voice></note>`;
  }
  const alter = token.alter === 0 ? "" : `<alter>${token.alter}</alter>`;
  return `<note><pitch><step>${token.step}</step>${alter}<octave>${token.octave}</octave></pitch><duration>${duration}</duration><voice>${voice}</voice></note>`;
}

function escapeXml(value: string) {
  return value.replace(/&/g, "&amp;").replace(/</g, "&lt;");
}

function choir(
  names: { id: string; name: string; canonical: string; pitch: string }[],
  measures: number,
  perMeasure: number,
  options: Partial<ScoreDef> & Pick<ScoreDef, "id" | "title" | "set" | "voicing">
): ScoreFixture {
  return buildFixture({
    fifths: [{ at: 1, fifths: 0, name: "C major" }],
    meters: [{ at: 1, beats: perMeasure, beatType: 4 }],
    parts: names.map((part) => ({
      id: part.id,
      name: part.name,
      role: "choir",
      canonical: part.canonical,
      clefs: [{ at: 1, sign: part.canonical === "BASS" || part.canonical === "BARITONE" ? "F" : "G", line: part.canonical === "BASS" || part.canonical === "BARITONE" ? 4 : 2 }],
      measures: singing(part.pitch, measures, perMeasure),
    })),
    ...options,
  });
}

const C_MAJOR = [{ at: 1, fifths: 0, name: "C major" }];
const FOUR_FOUR = [{ at: 1, beats: 4, beatType: 4 }];

function part(
  id: string,
  name: string,
  canonical: string,
  pitch: string,
  measures = 4,
  role: PartDef["role"] = "choir",
  clef: { sign: string; line: number } = { sign: "G", line: 2 }
): PartDef {
  return {
    id,
    name,
    role,
    canonical,
    clefs: [{ at: 1, sign: clef.sign, line: clef.line }],
    measures: singing(pitch, measures, 4),
  };
}

export const FIXTURES: ScoreFixture[] = [
  choir(
    [{ id: "P1", name: "Unison", canonical: "UNKNOWN", pitch: "C4" }],
    4,
    4,
    { id: "unison", title: "Unison line", set: "development", voicing: "UNISON" }
  ),
  choir(
    [
      { id: "P1", name: "Part I", canonical: "UNKNOWN", pitch: "E4" },
      { id: "P2", name: "Part II", canonical: "UNKNOWN", pitch: "C4" },
    ],
    4,
    4,
    { id: "two-part", title: "Two generic parts", set: "development", voicing: "2-PART" }
  ),
  choir(
    [
      { id: "P1", name: "Soprano", canonical: "SOPRANO", pitch: "G4" },
      { id: "P2", name: "Alto", canonical: "ALTO", pitch: "E4" },
    ],
    4,
    4,
    { id: "sa", title: "Soprano and Alto", set: "development", voicing: "SA" }
  ),
  choir(
    [
      { id: "P1", name: "Soprano I", canonical: "SOPRANO", pitch: "G4" },
      { id: "P2", name: "Soprano II", canonical: "SOPRANO", pitch: "E4" },
      { id: "P3", name: "Alto", canonical: "ALTO", pitch: "C4" },
    ],
    4,
    4,
    { id: "ssa", title: "SSA separate staves", set: "development", voicing: "SSA" }
  ),
  choir(
    [
      { id: "P1", name: "Soprano I", canonical: "SOPRANO", pitch: "A4" },
      { id: "P2", name: "Soprano II", canonical: "SOPRANO", pitch: "F4" },
      { id: "P3", name: "Alto I", canonical: "ALTO", pitch: "D4" },
      { id: "P4", name: "Alto II", canonical: "ALTO", pitch: "B3" },
    ],
    4,
    4,
    { id: "ssaa", title: "SSAA separate staves", set: "development", voicing: "SSAA" }
  ),
  choir(
    [
      { id: "P1", name: "Soprano", canonical: "SOPRANO", pitch: "G4" },
      { id: "P2", name: "Alto", canonical: "ALTO", pitch: "E4" },
      { id: "P3", name: "Baritone", canonical: "BARITONE", pitch: "C3" },
    ],
    4,
    4,
    { id: "sab", title: "SAB with baritone", set: "development", voicing: "SAB" }
  ),
  choir(
    [
      { id: "P1", name: "Soprano", canonical: "SOPRANO", pitch: "G4" },
      { id: "P2", name: "Alto", canonical: "ALTO", pitch: "E4" },
      { id: "P3", name: "Tenor", canonical: "TENOR", pitch: "C4" },
      { id: "P4", name: "Bass", canonical: "BASS", pitch: "G3" },
    ],
    4,
    4,
    { id: "satb", title: "SATB a cappella", set: "development", voicing: "SATB" }
  ),
  choir(
    [
      { id: "P1", name: "Tenor I", canonical: "TENOR", pitch: "E4" },
      { id: "P2", name: "Tenor II", canonical: "TENOR", pitch: "C4" },
      { id: "P3", name: "Bass I", canonical: "BASS", pitch: "A3" },
      { id: "P4", name: "Bass II", canonical: "BASS", pitch: "F3" },
    ],
    4,
    4,
    { id: "ttbb", title: "TTBB a cappella", set: "development", voicing: "TTBB" }
  ),
  choir(
    [
      { id: "P1", name: "Soprano I", canonical: "SOPRANO", pitch: "A4" },
      { id: "P2", name: "Soprano II", canonical: "SOPRANO", pitch: "F4" },
      { id: "P3", name: "Alto I", canonical: "ALTO", pitch: "D4" },
      { id: "P4", name: "Alto II", canonical: "ALTO", pitch: "B3" },
      { id: "P5", name: "Tenor I", canonical: "TENOR", pitch: "G3" },
      { id: "P6", name: "Tenor II", canonical: "TENOR", pitch: "E3" },
      { id: "P7", name: "Bass I", canonical: "BASS", pitch: "C3" },
      { id: "P8", name: "Bass II", canonical: "BASS", pitch: "G2" },
    ],
    4,
    4,
    { id: "ssaattbb", title: "SSAATTBB separate staves", set: "development", voicing: "SSAATTBB" }
  ),
  buildFixture({
    id: "satb-piano",
    title: "SATB with piano",
    set: "development",
    voicing: "SATB",
    fifths: C_MAJOR,
    meters: FOUR_FOUR,
    parts: [
      part("P1", "Soprano", "SOPRANO", "G4"),
      part("P2", "Alto", "ALTO", "E4"),
      part("P3", "Tenor", "TENOR", "C4"),
      part("P4", "Bass", "BASS", "G3", 4, "choir", { sign: "F", line: 4 }),
      { ...part("P5", "Piano", "PIANO", "C4", 4, "piano", { sign: "G", line: 2 }), staves: 2 },
    ],
  }),
  buildFixture({
    id: "piano-intro",
    title: "Piano introduction, choir enters later",
    set: "development",
    voicing: "SA",
    fifths: [{ at: 1, fifths: -1, name: "F major" }],
    meters: FOUR_FOUR,
    parts: [
      {
        id: "P1",
        name: "Soprano",
        role: "choir",
        canonical: "SOPRANO",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: [...resting(5, 4), ...singing("A4", 1, 4)],
      },
      {
        id: "P2",
        name: "Alto",
        role: "choir",
        canonical: "ALTO",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: [...resting(5, 4), ...singing("F4", 1, 4)],
      },
      {
        ...part("P3", "Piano", "PIANO", "C4", 6, "piano"),
        staves: 2,
      },
    ],
  }),
  buildFixture({
    id: "solo-then-choir",
    title: "Soprano solo before SATB",
    set: "development",
    voicing: "SATB",
    fifths: C_MAJOR,
    meters: FOUR_FOUR,
    parts: [
      {
        id: "P1",
        name: "Soprano Solo",
        role: "featured",
        canonical: "SOPRANO",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: [...singing("C5", 2, 4), ...resting(2, 4)],
      },
      {
        id: "P2",
        name: "Soprano",
        role: "choir",
        canonical: "SOPRANO",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: [...resting(2, 4), ...singing("G4", 2, 4)],
      },
      {
        id: "P3",
        name: "Alto",
        role: "choir",
        canonical: "ALTO",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: [...resting(2, 4), ...singing("E4", 2, 4)],
      },
      {
        id: "P4",
        name: "Tenor",
        role: "choir",
        canonical: "TENOR",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: [...resting(2, 4), ...singing("C4", 2, 4)],
      },
      {
        id: "P5",
        name: "Bass",
        role: "choir",
        canonical: "BASS",
        clefs: [{ at: 1, sign: "F", line: 4 }],
        measures: [...resting(2, 4), ...singing("G3", 2, 4)],
      },
      { ...part("P6", "Piano", "PIANO", "C3", 4, "piano"), staves: 2 },
    ],
  }),
  buildFixture({
    id: "descant",
    title: "Descant above SATB",
    set: "development",
    voicing: "SATB",
    fifths: C_MAJOR,
    meters: FOUR_FOUR,
    parts: [
      part("P1", "Descant", "UNKNOWN", "C5", 4, "featured"),
      part("P2", "Soprano", "SOPRANO", "G4"),
      part("P3", "Alto", "ALTO", "E4"),
      part("P4", "Tenor", "TENOR", "C4"),
      part("P5", "Bass", "BASS", "G3", 4, "choir", { sign: "F", line: 4 }),
    ],
  }),
  buildFixture({
    id: "shared-sa-tb",
    title: "Shared Soprano/Alto and Tenor/Bass staves",
    set: "development",
    voicing: "SATB",
    fifths: C_MAJOR,
    meters: FOUR_FOUR,
    parts: [
      {
        id: "P1",
        name: "Soprano/Alto",
        role: "choir",
        canonical: "SOPRANO+ALTO",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: [],
        voices: [singing("G4", 4, 4), singing("E4", 4, 4)],
      },
      {
        id: "P2",
        name: "Tenor/Bass",
        role: "choir",
        canonical: "TENOR+BASS",
        clefs: [{ at: 1, sign: "F", line: 4 }],
        measures: [],
        voices: [singing("C4", 4, 4), singing("G3", 4, 4)],
      },
    ],
  }),
  buildFixture({
    id: "chromatic-stable-key",
    title: "Chromatic notes without a key change",
    set: "development",
    voicing: "SA",
    fifths: [{ at: 1, fifths: -2, name: "Bb major" }],
    meters: FOUR_FOUR,
    parts: [
      {
        id: "P1",
        name: "Soprano",
        role: "choir",
        canonical: "SOPRANO",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: Array.from({ length: 4 }, () => "F#4 Bb4 C4 D4"),
      },
      part("P2", "Alto", "ALTO", "D4"),
    ],
  }),
  buildFixture({
    id: "modulation",
    title: "Printed key change",
    set: "development",
    voicing: "SA",
    fifths: [
      { at: 1, fifths: 0, name: "C major" },
      { at: 3, fifths: 2, name: "D major" },
    ],
    meters: FOUR_FOUR,
    parts: [part("P1", "Soprano", "SOPRANO", "G4"), part("P2", "Alto", "ALTO", "E4")],
  }),
  buildFixture({
    id: "meter-change",
    title: "Time signature change",
    set: "development",
    voicing: "UNISON",
    fifths: C_MAJOR,
    meters: [
      { at: 1, beats: 4, beatType: 4 },
      { at: 3, beats: 3, beatType: 4 },
    ],
    parts: [
      {
        id: "P1",
        name: "Unison",
        role: "choir",
        canonical: "UNKNOWN",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: ["C4 C4 E4 G4", "C4 C4 E4 G4", "C4 E4 G4", "C4 E4 G4"],
      },
    ],
  }),
  buildFixture({
    id: "clef-change",
    title: "Clef change on one staff",
    set: "development",
    voicing: "SA",
    fifths: C_MAJOR,
    meters: FOUR_FOUR,
    parts: [
      {
        id: "P1",
        name: "Soprano",
        role: "choir",
        canonical: "SOPRANO",
        clefs: [
          { at: 1, sign: "G", line: 2 },
          { at: 3, sign: "F", line: 4 },
        ],
        measures: singing("C4", 4, 4),
      },
      part("P2", "Alto", "ALTO", "A3"),
    ],
  }),
  buildFixture({
    id: "repeat",
    title: "Simple repeat",
    set: "development",
    voicing: "SA",
    fifths: C_MAJOR,
    meters: FOUR_FOUR,
    navigation: "repeat",
    parts: [part("P1", "Soprano", "SOPRANO", "G4"), part("P2", "Alto", "ALTO", "E4")],
  }),
  buildFixture({
    id: "endings",
    title: "First and second endings",
    set: "development",
    voicing: "SA",
    fifths: C_MAJOR,
    meters: FOUR_FOUR,
    navigation: "endings",
    parts: [part("P1", "Soprano", "SOPRANO", "G4"), part("P2", "Alto", "ALTO", "E4")],
  }),
  buildFixture({
    id: "ds-coda",
    title: "Dal segno al coda",
    set: "development",
    voicing: "UNISON",
    fifths: C_MAJOR,
    meters: FOUR_FOUR,
    navigation: "ds-coda",
    parts: [
      {
        id: "P1",
        name: "Unison",
        role: "choir",
        canonical: "UNKNOWN",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: singing("C4", 5, 4),
      },
    ],
  }),
  buildFixture({
    id: "dc-fine",
    title: "Da capo al fine",
    set: "development",
    voicing: "UNISON",
    fifths: C_MAJOR,
    meters: FOUR_FOUR,
    navigation: "dc-fine",
    parts: [
      {
        id: "P1",
        name: "Unison",
        role: "choir",
        canonical: "UNKNOWN",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: singing("D4", 4, 4),
      },
    ],
  }),
  buildFixture({
    id: "pickup",
    title: "Pickup measure",
    set: "development",
    voicing: "SA",
    fifths: [{ at: 0, fifths: 0, name: "C major" }],
    meters: [{ at: 0, beats: 4, beatType: 4 }],
    pickup: "G4",
    parts: [
      {
        id: "P1",
        name: "Soprano",
        role: "choir",
        canonical: "SOPRANO",
        clefs: [{ at: 0, sign: "G", line: 2 }],
        measures: ["G4", ...singing("C5", 3, 4)],
      },
      {
        id: "P2",
        name: "Alto",
        role: "choir",
        canonical: "ALTO",
        clefs: [{ at: 0, sign: "G", line: 2 }],
        measures: ["E4", ...singing("A4", 3, 4)],
      },
    ],
  }),
  choir(
    [
      { id: "P1", name: "Voice 1", canonical: "UNKNOWN", pitch: "C5" },
      { id: "P2", name: "Voice 2", canonical: "UNKNOWN", pitch: "G4" },
      { id: "P3", name: "Voice 3", canonical: "UNKNOWN", pitch: "E4" },
      { id: "P4", name: "Voice 4", canonical: "UNKNOWN", pitch: "C4" },
    ],
    4,
    4,
    { id: "four-unlabeled", title: "Four unlabeled staves", set: "development", voicing: "4-PART" }
  ),
  buildFixture({
    id: "eighths",
    title: "Eighth-note rhythm",
    set: "development",
    voicing: "SA",
    fifths: C_MAJOR,
    meters: FOUR_FOUR,
    parts: [
      {
        id: "P1",
        name: "Soprano",
        role: "choir",
        canonical: "SOPRANO",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: Array.from({ length: 4 }, () => "C5:0.5 D5:0.5 E5:0.5 F5:0.5 G5:0.5 A5:0.5 B5:0.5 C6:0.5"),
      },
      part("P2", "Alto", "ALTO", "E4"),
    ],
  }),
  buildFixture({
    id: "unlabeled-grand-staff",
    title: "Unlabeled grand staff",
    set: "development",
    voicing: "SA",
    fifths: C_MAJOR,
    meters: FOUR_FOUR,
    pianoNeedsConfirmation: true,
    parts: [
      part("P1", "Soprano", "SOPRANO", "G4"),
      part("P2", "Alto", "ALTO", "E4"),
      {
        ...part("P3", "Staff", "PIANO", "C3", 4, "piano"),
        staves: 2,
      },
    ],
  }),
];

FIXTURES.push(
  buildFixture({
    id: "ssa-piano-numbers",
    title: "Numbered SSA plus piano",
    set: "regression",
    voicing: "SSA",
    fifths: [{ at: 1, fifths: 1, name: "G major" }],
    meters: FOUR_FOUR,
    parts: [
      part("P1", "Soprano 1", "SOPRANO", "A4"),
      part("P2", "Soprano 2", "SOPRANO", "F4"),
      part("P3", "Alto", "ALTO", "D4"),
      { ...part("P4", "Piano", "PIANO", "G3", 4, "piano"), staves: 2 },
    ],
  }),
  buildFixture({
    id: "ttbb-repeat",
    title: "TTBB with a repeat",
    set: "regression",
    voicing: "TTBB",
    fifths: [{ at: 1, fifths: -1, name: "F major" }],
    meters: FOUR_FOUR,
    navigation: "repeat",
    parts: [
      part("P1", "Tenor I", "TENOR", "G4"),
      part("P2", "Tenor II", "TENOR", "E4"),
      part("P3", "Bass I", "BASS", "C3", 4, "choir", { sign: "F", line: 4 }),
      part("P4", "Bass II", "BASS", "A2", 4, "choir", { sign: "F", line: 4 }),
    ],
  }),
  buildFixture({
    id: "sab-meter",
    title: "SAB with a meter change",
    set: "regression",
    voicing: "SAB",
    fifths: C_MAJOR,
    meters: [
      { at: 1, beats: 4, beatType: 4 },
      { at: 3, beats: 6, beatType: 8 },
    ],
    parts: [
      {
        id: "P1",
        name: "Soprano",
        role: "choir",
        canonical: "SOPRANO",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: ["C5 C5 E5 G5", "C5 C5 E5 G5", "C5:0.5 D5:0.5 E5:0.5 F5:0.5 G5:0.5 A5:0.5", "C5:0.5 D5:0.5 E5:0.5 F5:0.5 G5:0.5 A5:0.5"],
      },
      {
        id: "P2",
        name: "Alto",
        role: "choir",
        canonical: "ALTO",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: ["G4 G4 B4 D5", "G4 G4 B4 D5", "G4:0.5 A4:0.5 B4:0.5 C5:0.5 D5:0.5 E5:0.5", "G4:0.5 A4:0.5 B4:0.5 C5:0.5 D5:0.5 E5:0.5"],
      },
      {
        id: "P3",
        name: "Baritone",
        role: "choir",
        canonical: "BARITONE",
        clefs: [{ at: 1, sign: "F", line: 4 }],
        measures: ["C3 C3 E3 G3", "C3 C3 E3 G3", "C3:0.5 D3:0.5 E3:0.5 F3:0.5 G3:0.5 A3:0.5", "C3:0.5 D3:0.5 E3:0.5 F3:0.5 G3:0.5 A3:0.5"],
      },
    ],
  })
);

FIXTURES.push(
  buildFixture({
    id: "heldout-ssaa-shared",
    title: "Held-out SSAA on shared staves",
    set: "heldout",
    voicing: "SSAA",
    fifths: [{ at: 1, fifths: -3, name: "Eb major" }],
    meters: FOUR_FOUR,
    parts: [
      {
        id: "P1",
        name: "Soprano/Soprano",
        role: "choir",
        canonical: "SOPRANO+SOPRANO",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: [],
        voices: [singing("G4", 4, 4), singing("E4", 4, 4)],
      },
      {
        id: "P2",
        name: "Alto/Alto",
        role: "choir",
        canonical: "ALTO+ALTO",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: [],
        voices: [singing("C4", 4, 4), singing("A3", 4, 4)],
      },
    ],
  }),
  buildFixture({
    id: "heldout-solo-ssa",
    title: "Held-out solo then SSA",
    set: "heldout",
    voicing: "SSA",
    fifths: C_MAJOR,
    meters: FOUR_FOUR,
    parts: [
      {
        id: "P1",
        name: "Alto Solo",
        role: "featured",
        canonical: "ALTO",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: [...singing("E4", 2, 4), ...resting(2, 4)],
      },
      {
        id: "P2",
        name: "Soprano I",
        role: "choir",
        canonical: "SOPRANO",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: [...resting(2, 4), ...singing("G4", 2, 4)],
      },
      {
        id: "P3",
        name: "Soprano II",
        role: "choir",
        canonical: "SOPRANO",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: [...resting(2, 4), ...singing("E4", 2, 4)],
      },
      {
        id: "P4",
        name: "Alto",
        role: "choir",
        canonical: "ALTO",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: [...resting(2, 4), ...singing("C4", 2, 4)],
      },
      { ...part("P5", "Keyboard", "PIANO", "C3", 4, "piano"), staves: 2 },
    ],
  }),
  buildFixture({
    id: "heldout-satb-coda-key",
    title: "Held-out SATB coda and modulation",
    set: "heldout",
    voicing: "SATB",
    fifths: [
      { at: 1, fifths: 0, name: "C major" },
      { at: 5, fifths: -1, name: "F major" },
    ],
    meters: FOUR_FOUR,
    navigation: "ds-coda",
    parts: [
      part("P1", "Soprano", "SOPRANO", "G4", 5),
      part("P2", "Alto", "ALTO", "E4", 5),
      part("P3", "Tenor", "TENOR", "C4", 5),
      part("P4", "Bass", "BASS", "G3", 5, "choir", { sign: "F", line: 4 }),
    ],
  }),
  buildFixture({
    id: "heldout-two-part-piano",
    title: "Held-out two-part with piano",
    set: "heldout",
    voicing: "2-PART",
    fifths: [{ at: 1, fifths: 3, name: "A major" }],
    meters: [{ at: 1, beats: 3, beatType: 4 }],
    parts: [
      {
        id: "P1",
        name: "Part I",
        role: "choir",
        canonical: "UNKNOWN",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: Array.from({ length: 4 }, () => "E4 G4 B4"),
      },
      {
        id: "P2",
        name: "Part II",
        role: "choir",
        canonical: "UNKNOWN",
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: Array.from({ length: 4 }, () => "C4 E4 G4"),
      },
      {
        id: "P3",
        name: "Piano",
        role: "piano",
        canonical: "PIANO",
        staves: 2,
        clefs: [{ at: 1, sign: "G", line: 2 }],
        measures: Array.from({ length: 4 }, () => "C3 E3 G3"),
      },
    ],
  })
);
