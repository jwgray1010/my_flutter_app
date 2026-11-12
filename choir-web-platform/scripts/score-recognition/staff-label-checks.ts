import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";
import sharp from "sharp";
import { normalizePrintedLabel } from "@/lib/part-labels";
import { detectStaffBands, recognizeStaffLabels, tesseractAvailable } from "@/lib/server/staff-label-ocr";
import type { CanonicalPartId } from "@/lib/score-types";
import { interpretUnifiedScore } from "@/lib/unified-pipeline";
import { runPartIdentityChecks } from "./part-identity-checks";

export async function runStaffLabelChecks() {
  normalizationTable();
  positionedWordsBeatPartNames();
  sharedStaffKeepsBothLabels();
  truncatedPartNameDoesNotDropTheUpperLabel();
  lyricDoesNotBecomeAPart();
  bracedGrandStaffIsOnePiano();
  soloDoesNotReplaceTheChoir();
  abbreviationsAndNumberedParts();
  repeatedSystemLabelsStayOnePart();
  directorLockDoesNotEraseAPrintedLabel();
  runPartIdentityChecks();
  await ocrReadsPrintedStaffNames();
  console.log("Staff-label checks passed.");
}

function normalizationTable() {
  const cases: Array<[string, string]> = [
    ["Soprano", "SOPRANO"],
    ["Sop.", "SOPRANO"],
    ["Soprano I", "SOPRANO_1"],
    ["Soprano II", "SOPRANO_2"],
    ["S1", "SOPRANO_1"],
    ["S2", "SOPRANO_2"],
    ["Alto", "ALTO"],
    ["Alto I", "ALTO_1"],
    ["Alto II", "ALTO_2"],
    ["Tenor", "TENOR"],
    ["Bass", "BASS"],
    ["Baritone", "BARITONE"],
    ["Part I", "PART_1"],
    ["Part II", "PART_2"],
    ["Piano", "PIANO"],
    ["Pno.", "PIANO"],
    ["Organ", "ORGAN"],
    ["Keyboard", "KEYBOARD"],
    ["Solo", "SOLO"],
    ["Descant", "DESCANT"],
    ["Soprano Solo", "SOPRANO+SOLO"],
  ];
  for (const [raw, expected] of cases) {
    const label = normalizePrintedLabel(raw, { allowSingleLetter: false });
    const actual = label.accepted
      ? label.roles.length
        ? `${label.roles[0]}${label.divisions[0] ? `_${label.divisions[0]}` : ""}${label.extraKind ? `+${label.extraKind}` : ""}`
        : label.baritone
          ? "BARITONE"
          : label.genericPart
            ? `PART_${label.genericPart}`
            : label.accompaniment ?? label.extraKind
      : "REJECTED";
    if (actual !== expected) {
      throw new Error(`Label “${raw}” normalized to ${actual}, expected ${expected}.`);
    }
  }
  for (const lyric of ["the bass of the sea", "Andante", "D.C. al Fine", "with optional PianoTrax CD", "love"]) {
    if (normalizePrintedLabel(lyric).accepted) {
      throw new Error(`Ordinary text was treated as a part label: ${lyric}`);
    }
  }
  const letter = normalizePrintedLabel("S.", { allowSingleLetter: false });
  if (letter.accepted) {
    throw new Error("A lone S. was accepted without label context.");
  }
  const contextual = normalizePrintedLabel("S.", { allowSingleLetter: true });
  if (contextual.roles[0] !== "SOPRANO") {
    throw new Error("S. was not read as Soprano when the surrounding labels are abbreviations.");
  }
}

function positionedWordsBeatPartNames() {
  const score = interpretUnifiedScore({
    xml: labeledScore([
      staff("P1", "Voice", "Soprano", "G", 2, "C", 5),
      staff("P2", "Voice", "Alto", "G", 2, "G", 4),
      staff("P3", "Voice", "Tenor", "F", 4, "E", 3),
      staff("P4", "Voice", "Bass", "F", 4, "C", 3),
      staff("P5", "Voice", "Piano", "G", 2, "C", 4),
    ]),
    sourceType: "omr",
    sourceUploadType: "PDF",
    pageCount: 1,
  });
  expectRoles(score, ["SOPRANO", "ALTO", "TENOR", "BASS", "PIANO"]);
  expectTrace(score, "Soprano", "SOPRANO");
  expectTrace(score, "Alto", "ALTO");
  expectTrace(score, "Tenor", "TENOR");
  expectTrace(score, "Bass", "BASS");
  expectTrace(score, "Piano", "PIANO");
  if (score.scoreModel?.accompaniment.kind !== "PIANO") {
    throw new Error("Printed Piano did not become the accompaniment.");
  }
  const choir = score.scoreModel.playback.channels.filter((channel) => channel.group === "CHOIR");
  if (choir.map((channel) => channel.canonicalPart).join(",") !== "SOPRANO,ALTO,TENOR,BASS") {
    throw new Error(`Playback channels were ${choir.map((channel) => channel.canonicalPart).join(",")}.`);
  }
  for (const channel of choir) {
    const events = score.scoreModel.playback.events.filter((event) => event.partId === channel.id);
    if (!events.length) {
      throw new Error(`${channel.label} reached a channel with no notes.`);
    }
  }
}

function sharedStaffKeepsBothLabels() {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1"><part-name>Voice</part-name></score-part>
    <score-part id="P2"><part-name>Voice</part-name></score-part>
  </part-list>
  <part id="P1">
    <measure number="1">
      <attributes><divisions>1</divisions><key><fifths>0</fifths><mode>major</mode></key><time><beats>4</beats><beat-type>4</beat-type></time><clef><sign>G</sign><line>2</line></clef></attributes>
      <direction><direction-type><words default-x="-10" default-y="28">Soprano</words></direction-type><staff>1</staff></direction>
      <direction><direction-type><words default-x="-10" default-y="8">Alto</words></direction-type><staff>1</staff></direction>
      <note><pitch><step>C</step><octave>5</octave></pitch><duration>4</duration><voice>1</voice></note>
      <backup><duration>4</duration></backup>
      <note><pitch><step>G</step><octave>4</octave></pitch><duration>4</duration><voice>2</voice></note>
    </measure>
  </part>
  <part id="P2">
    <measure number="1">
      <attributes><divisions>1</divisions><key><fifths>0</fifths><mode>major</mode></key><time><beats>4</beats><beat-type>4</beat-type></time><clef><sign>F</sign><line>4</line></clef></attributes>
      <direction><direction-type><words default-x="-10" default-y="28">Tenor</words></direction-type></direction>
      <direction><direction-type><words default-x="-10" default-y="8">Bass</words></direction-type></direction>
      <note><pitch><step>E</step><octave>3</octave></pitch><duration>4</duration><voice>1</voice></note>
      <backup><duration>4</duration></backup>
      <note><pitch><step>C</step><octave>3</octave></pitch><duration>4</duration><voice>2</voice></note>
    </measure>
  </part>
</score-partwise>`;
  const score = interpretUnifiedScore({
    xml,
    sourceType: "omr",
    sourceUploadType: "SINGLE_IMAGE",
    pageCount: 1,
  });
  expectRoles(score, ["SOPRANO", "ALTO", "TENOR", "BASS"]);
  if (score.inferredVoicing !== "SATB") {
    throw new Error(`Shared staves were summarized as ${score.inferredVoicing}.`);
  }
  const soprano = score.notes.filter((note) => note.partCanonical === "SOPRANO");
  const alto = score.notes.filter((note) => note.partCanonical === "ALTO");
  if (soprano.length !== 1 || alto.length !== 1 || soprano[0].midi === alto[0].midi) {
    throw new Error("Soprano and Alto on one staff collapsed to a single line.");
  }
  const channels = score.scoreModel?.playback.channels.map((channel) => channel.canonicalPart).join(",") ?? "";
  if (channels !== "SOPRANO,ALTO,TENOR,BASS") {
    throw new Error(`Shared-staff playback channels were ${channels}.`);
  }
}

function truncatedPartNameDoesNotDropTheUpperLabel() {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list><score-part id="P1"><part-name>Alto</part-name></score-part></part-list>
  <part id="P1">
    <measure number="1">
      <attributes><divisions>1</divisions><key><fifths>0</fifths><mode>major</mode></key><time><beats>4</beats><beat-type>4</beat-type></time><clef><sign>G</sign><line>2</line></clef></attributes>
      <direction><direction-type><words default-x="-8" default-y="30">Soprano</words></direction-type></direction>
      <direction><direction-type><words default-x="-8" default-y="10">Alto</words></direction-type></direction>
      <note><pitch><step>C</step><octave>5</octave></pitch><duration>4</duration><voice>1</voice></note>
      <backup><duration>4</duration></backup>
      <note><pitch><step>G</step><octave>4</octave></pitch><duration>4</duration><voice>2</voice></note>
    </measure>
  </part>
</score-partwise>`;
  const score = interpretUnifiedScore({
    xml,
    sourceType: "omr",
    sourceUploadType: "PDF",
    pageCount: 1,
  });
  expectRoles(score, ["SOPRANO", "ALTO"]);
  if (!score.notes.some((note) => note.partCanonical === "SOPRANO" && note.midi === 72)) {
    throw new Error("The upper voice was kept as Alto after the part name dropped Soprano.");
  }
}

function lyricDoesNotBecomeAPart() {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list><score-part id="P1"><part-name>Voice</part-name></score-part></part-list>
  <part id="P1">
    <measure number="1">
      <attributes><divisions>1</divisions><key><fifths>0</fifths><mode>major</mode></key><time><beats>4</beats><beat-type>4</beat-type></time></attributes>
      <note><pitch><step>C</step><octave>5</octave></pitch><duration>4</duration><voice>1</voice></note>
    </measure>
    <measure number="2">
      <note><pitch><step>D</step><octave>5</octave></pitch><duration>4</duration><voice>1</voice></note>
    </measure>
    <measure number="3">
      <direction><direction-type><words default-x="140" default-y="10">Bass</words></direction-type></direction>
      <note><pitch><step>E</step><octave>5</octave></pitch><duration>4</duration><voice>1</voice><lyric number="1"><syllabic>single</syllabic><text>bass</text></lyric></note>
    </measure>
  </part>
</score-partwise>`;
  const score = interpretUnifiedScore({
    xml,
    sourceType: "omr",
    sourceUploadType: "PDF",
    pageCount: 1,
  });
  if (score.parts.some((part) => part.canonicalPart === "BASS")) {
    throw new Error("A lyric was assigned as the Bass part.");
  }
}

function bracedGrandStaffIsOnePiano() {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1"><part-name>Soprano</part-name></score-part>
    <part-group type="start" number="1"><group-symbol>brace</group-symbol></part-group>
    <score-part id="P2"><part-name>Staff</part-name></score-part>
    <score-part id="P3"><part-name>Staff</part-name></score-part>
    <part-group type="stop" number="1"/>
  </part-list>
  <part id="P1">${measure("G", 2, "C", 5, "")}</part>
  <part id="P2">${measure("G", 2, "C", 4, "")}</part>
  <part id="P3">${measure("F", 4, "C", 3, "")}</part>
</score-partwise>`;
  const score = interpretUnifiedScore({
    xml,
    sourceType: "omr",
    sourceUploadType: "MULTI_IMAGE",
    pageCount: 2,
  });
  const choir = score.parts.filter((part) => part.canonicalPart !== "PIANO");
  if (choir.length !== 1 || choir[0].canonicalPart !== "SOPRANO") {
    throw new Error(`Braced piano staves entered the choir as ${choir.map((part) => part.canonicalPart).join(",")}.`);
  }
  if (score.scoreModel?.accompaniment.partIds.length !== 2) {
    throw new Error("The braced grand staff was not kept as one accompaniment.");
  }
  if (score.parts.some((part) => part.canonicalPart === "BASS")) {
    throw new Error("The piano bass staff became the choir Bass.");
  }
}

function soloDoesNotReplaceTheChoir() {
  const score = interpretUnifiedScore({
    xml: labeledScore([
      staff("P1", "Voice", "Soprano", "G", 2, "C", 5),
      staff("P2", "Voice", "Alto", "G", 2, "G", 4),
      staff("P3", "Voice", "Soprano Solo", "G", 2, "E", 5),
    ]),
    sourceType: "musicxml",
    sourceUploadType: "MUSICXML",
    pageCount: 1,
  });
  const choir = score.scoreModel?.logicalParts.map((part) => part.canonicalPart).join(",") ?? "";
  const extra = score.scoreModel?.extraPlayableParts.map((part) => part.label).join(",") ?? "";
  if (choir !== "SOPRANO,ALTO") {
    throw new Error(`Solo shifted the choir to ${choir}.`);
  }
  if (!extra.toLowerCase().includes("solo")) {
    throw new Error(`Solo was not playable on its own (${extra}).`);
  }
  const soloEvents = score.scoreModel?.playback.events.filter((event) => event.partCanonical === "SOPRANO" && event.midi === 76) ?? [];
  if (!soloEvents.length) {
    throw new Error("Solo notes were dropped.");
  }
}

function abbreviationsAndNumberedParts() {
  const score = interpretUnifiedScore({
    xml: labeledScore([
      staff("P1", "Voice", "Sop.", "G", 2, "C", 5),
      staff("P2", "Voice", "Soprano II", "G", 2, "A", 4),
      staff("P3", "Voice", "Pno.", "G", 2, "C", 4),
    ]),
    sourceType: "omr",
    sourceUploadType: "PDF",
    pageCount: 1,
  });
  expectRoles(score, ["SOPRANO", "SOPRANO", "PIANO"]);
  const numbered = interpretUnifiedScore({
    xml: labeledScore([
      staff("P1", "Part I", "", "G", 2, "C", 5),
      staff("P2", "Part II", "", "G", 2, "G", 4),
    ]),
    sourceType: "musicxml",
    sourceUploadType: "MUSICXML",
    pageCount: 1,
  });
  if (numbered.inferredVoicing !== "2-Part") {
    throw new Error(`Part I / Part II became ${numbered.inferredVoicing}.`);
  }
  if (numbered.parts.some((part) => part.canonicalPart === "SOPRANO" || part.canonicalPart === "ALTO")) {
    throw new Error("Generic Part I / Part II were renamed to SATB roles.");
  }
}

function repeatedSystemLabelsStayOnePart() {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list><score-part id="P1"><part-name>Voice</part-name></score-part></part-list>
  <part id="P1">
    <measure number="1">
      <attributes><divisions>1</divisions><key><fifths>0</fifths><mode>major</mode></key><time><beats>4</beats><beat-type>4</beat-type></time><clef><sign>G</sign><line>2</line></clef></attributes>
      <direction><direction-type><words default-x="-12" default-y="16">Soprano</words></direction-type></direction>
      <note><pitch><step>C</step><octave>5</octave></pitch><duration>4</duration><voice>1</voice></note>
    </measure>
    <measure number="2">
      <print new-system="yes"/>
      <direction><direction-type><words default-x="-12" default-y="16">Soprano</words></direction-type></direction>
      <note><pitch><step>D</step><octave>5</octave></pitch><duration>4</duration><voice>1</voice></note>
    </measure>
  </part>
</score-partwise>`;
  const score = interpretUnifiedScore({
    xml,
    sourceType: "omr",
    sourceUploadType: "PDF",
    pageCount: 1,
  });
  if (score.parts.length !== 1 || score.parts[0].canonicalPart !== "SOPRANO") {
    throw new Error(`A repeated Soprano label created ${score.parts.map((part) => part.canonicalPart).join(",")}.`);
  }
  if (score.notes.length !== 2) {
    throw new Error("Repeating the staff label duplicated the notes.");
  }
}

function directorLockDoesNotEraseAPrintedLabel() {
  const score = interpretUnifiedScore({
    xml: labeledScore([
      staff("P1", "Voice", "Alto", "G", 2, "G", 4),
      staff("P2", "Voice", "Soprano", "G", 2, "C", 5),
      staff("P3", "Voice", "", "G", 2, "E", 4),
      staff("P4", "Voice", "", "F", 4, "C", 3),
    ]),
    sourceType: "omr",
    sourceUploadType: "PDF",
    pageCount: 1,
    setup: { choirVoicing: "SATB", accompaniment: "AUTO", staffLayout: "AUTO" },
  });
  const order = score.scoreModel?.logicalParts.map((part) => part.canonicalPart).join(",") ?? "";
  if (!order.startsWith("ALTO,SOPRANO")) {
    throw new Error(`Director template reordered printed labels to ${order}.`);
  }
  const altoTrace = score.scoreModel?.staffLabelTrace.find((trace) => trace.rawText === "Alto");
  if (!altoTrace || altoTrace.status !== "PASS" || altoTrace.playbackChannelId == null) {
    throw new Error(`Alto trace did not survive to playback (${altoTrace?.status} ${altoTrace?.failedStage}).`);
  }
}

async function ocrReadsPrintedStaffNames() {
  if (!(await tesseractAvailable())) {
    throw new Error("Tesseract is not available, so staff-label OCR could not be checked.");
  }
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), "rk-labels-"));
  try {
    const imagePath = path.join(directory, "labels.png");
    await sharp(Buffer.from(labelPageSvg())).png().toFile(imagePath);
    const { data, info } = await sharp(imagePath).grayscale().raw().toBuffer({ resolveWithObject: true });
    const bands = detectStaffBands(info.width, info.height, data);
    if (bands.length < 4) {
      throw new Error(`Staff geometry found ${bands.length} staves on the labeled page.`);
    }
    const recognized = await recognizeStaffLabels(imagePath, 1);
    const texts = recognized.map((fact) => fact.text.toLowerCase());
    for (const word of ["soprano", "alto", "tenor", "bass", "piano"]) {
      if (!texts.some((text) => text.includes(word))) {
        throw new Error(`OCR did not read printed ${word}. Saw: ${texts.join(", ") || "(nothing)"}`);
      }
    }
    const facts = recognized.filter((fact) => fact.staff != null);
    const score = interpretUnifiedScore({
      xml: labeledScore([
        staff("P1", "Voice", "", "G", 2, "C", 5),
        staff("P2", "Voice", "", "G", 2, "G", 4),
        staff("P3", "Voice", "", "F", 4, "E", 3),
        staff("P4", "Voice", "", "F", 4, "C", 3),
        staff("P5", "Voice", "", "G", 2, "C", 4, 2),
      ]),
      sourceType: "omr",
      sourceUploadType: "PDF",
      pageCount: 1,
      supplementalLabels: facts,
    });
    expectRoles(score, ["SOPRANO", "ALTO", "TENOR", "BASS", "PIANO"]);
  } finally {
    await fs.rm(directory, { recursive: true, force: true });
  }
}

function expectRoles(
  score: ReturnType<typeof interpretUnifiedScore>,
  roles: CanonicalPartId[]
) {
  const actual = score.parts.map((part) => part.canonicalPart);
  if (actual.join(",") !== roles.join(",")) {
    throw new Error(`Parts were ${actual.join(",")}, expected ${roles.join(",")}.`);
  }
}

function expectTrace(score: ReturnType<typeof interpretUnifiedScore>, raw: string, normalized: string) {
  const trace = score.scoreModel?.staffLabelTrace.find((item) => item.rawText === raw && item.normalized.startsWith(normalized));
  if (!trace) {
    throw new Error(`No trace for printed ${raw}.`);
  }
  if (trace.status !== "PASS") {
    throw new Error(`${raw} failed at ${trace.failedStage}.`);
  }
  const channel = score.scoreModel?.playback.channels.find((item) => item.id === trace.playbackChannelId);
  if (!channel || channel.canonicalPart !== score.parts.find((part) => part.id === trace.logicalPartId)?.canonicalPart) {
    throw new Error(`${raw} did not reach its playback channel.`);
  }
}

function labeledScore(parts: { list: string; body: string }[]) {
  return `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>${parts.map((part) => part.list).join("")}</part-list>
  ${parts.map((part) => part.body).join("")}
</score-partwise>`;
}

function staff(
  id: string,
  partName: string,
  words: string,
  clef: "G" | "F",
  line: number,
  step: string,
  octave: number,
  staves = 1
) {
  return {
    list: `<score-part id="${id}"><part-name>${partName}</part-name></score-part>`,
    body: `<part id="${id}">${measure(clef, line, step, octave, words, staves)}</part>`,
  };
}

function measure(
  clef: "G" | "F",
  line: number,
  step: string,
  octave: number,
  words: string,
  staves = 1
) {
  const label = words
    ? `<direction><direction-type><words default-x="-12" default-y="20">${words}</words></direction-type></direction>`
    : "";
  const staffCount = staves > 1 ? `<staves>${staves}</staves>` : "";
  return `<measure number="1"><attributes><divisions>1</divisions><key><fifths>0</fifths><mode>major</mode></key><time><beats>4</beats><beat-type>4</beat-type></time>${staffCount}<clef><sign>${clef}</sign><line>${line}</line></clef></attributes>${label}<note><pitch><step>${step}</step><octave>${octave}</octave></pitch><duration>4</duration><voice>1</voice></note></measure>`;
}

function labelPageSvg() {
  const staves = [
    ["SOPRANO", 70],
    ["ALTO", 230],
    ["TENOR", 390],
    ["BASS", 550],
    ["PIANO", 710],
  ];
  const lines = staves
    .map(([, y]) =>
      [0, 1, 2, 3, 4]
        .map((line) => `<line x1="360" y1="${Number(y) + line * 12}" x2="980" y2="${Number(y) + line * 12}" stroke="black" stroke-width="2"/>`)
        .join("")
    )
    .join("");
  const labels = staves
    .map(([text, y]) => `<text x="24" y="${Number(y) + 34}" font-family="DejaVu Sans" font-size="42" fill="black">${text}</text>`)
    .join("");
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="860" viewBox="0 0 1000 860"><rect width="1000" height="860" fill="white"/>${lines}${labels}</svg>`;
}
