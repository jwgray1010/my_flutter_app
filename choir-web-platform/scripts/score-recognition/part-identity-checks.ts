import type { ParsedScore } from "@/lib/score-types";
import { interpretUnifiedScore } from "@/lib/unified-pipeline";

/**
 * A six-measure score that changes staff layout on every system:
 * shared choir staves, a page break into separate staves, a solo and a
 * descant above the choir, a divisi line, silent rests, then a recombined
 * system with a repeat and a coda. Logical ids have to survive all of it.
 */
export function runPartIdentityChecks() {
  fullScoreKeepsOneIdPerLine();
  descantAboveTheChoirDoesNotShiftIds();
  unexpectedRelabelIsFlagged();
  console.log("Part-identity checks passed.");
}

function fullScoreKeepsOneIdPerLine() {
  const score = interpretUnifiedScore({
    xml: continuityScore(),
    sourceType: "omr",
    sourceUploadType: "PDF",
    pageCount: 2,
  });
  const model = score.scoreModel;
  if (!model) {
    throw new Error("Continuity score produced no score model.");
  }
  if (score.measures.length !== 6) {
    throw new Error(`Written measures changed to ${score.measures.length}.`);
  }

  const soprano = idFor(score, 1, 72);
  const alto = idFor(score, 1, 67);
  const tenor = idFor(score, 1, 64);
  const bass = idFor(score, 1, 55);
  assertLine(score, soprano, "Soprano", [
    [1, 72],
    [2, 72],
    [3, 74],
    [4, 76],
    [5, 77],
    [6, 79],
  ]);
  assertLine(score, alto, "Alto", [
    [1, 67],
    [2, 67],
    [3, 67],
    [4, 67],
    [5, 69],
    [6, 71],
  ]);
  assertLine(score, tenor, "Tenor", [
    [1, 64],
    [2, 64],
    [5, 64],
    [6, 64],
  ]);
  assertLine(score, bass, "Bass", [
    [1, 55],
    [2, 55],
    [3, 55],
    [4, 55],
    [5, 55],
    [6, 55],
  ]);

  const sopranoII = idFor(score, 4, 81);
  const descant = idFor(score, 3, 83);
  if (sopranoII === soprano || descant === soprano) {
    throw new Error("Soprano II or the descant replaced the choir soprano.");
  }
  if (score.notes.filter((note) => note.partId === sopranoII).some((note) => note.measureNumber !== 4)) {
    throw new Error("Soprano II notes were copied onto other measures.");
  }
  const descantPart = score.parts.find((part) => part.id === descant);
  if (descantPart?.extraKind !== "DESCANT") {
    throw new Error("The descant was stored as a choir part.");
  }
  if (score.parts.filter((part) => part.canonicalPart === "ALTO").length !== 1) {
    throw new Error(`Alto was duplicated: ${describe(score)}`);
  }
  if (score.parts.filter((part) => part.canonicalPart === "BASS").length !== 1) {
    throw new Error(`Bass was duplicated: ${describe(score)}`);
  }
  if (!score.parts.some((part) => part.id === tenor)) {
    throw new Error("The resting tenor part was deleted.");
  }
  if (score.notes.some((note) => note.partId === tenor && (note.measureNumber === 3 || note.measureNumber === 4))) {
    throw new Error("The resting tenor was given notes from another staff.");
  }
  const piano = score.parts.filter((part) => part.canonicalPart === "PIANO");
  if (piano.length !== 1 || piano[0].id === bass) {
    throw new Error("The piano staff was absorbed into the choir.");
  }

  const systems = model.systems;
  if (systems.length !== 3 || systems[0].pageNumber !== 1 || systems[1].pageNumber !== 2 || systems[2].pageNumber !== 2) {
    throw new Error(`Expected three systems across two pages, got ${systems.map((system) => `p${system.pageNumber}s${system.systemNumber}`).join(",")}.`);
  }
  const opening = region(model, 1, 2);
  const separated = region(model, 3, 4);
  const recombined = region(model, 5, 6);
  assertStaffHas(opening, "P1:s1", [soprano, alto]);
  assertStaffHas(opening, "P2:s1", [tenor, bass]);
  assertStaffHas(separated, "P1:s1", [soprano]);
  assertStaffHas(separated, "P3:s1", [alto]);
  assertStaffHas(separated, "P4:s1", [bass]);
  assertStaffHas(separated, "P5:s1", [sopranoII]);
  assertStaffHas(separated, "P6:s1", [descant]);
  if (separated.staffToParts.some((staff) => staff.partIds.includes(tenor))) {
    throw new Error("The silent tenor was given a staff in the separated system.");
  }
  if (!separated.silentPartIds?.includes(tenor)) {
    throw new Error(`The resting tenor was not kept as silent: ${describe(score)}`);
  }
  assertStaffHas(recombined, "P1:s1", [soprano, alto]);
  assertStaffHas(recombined, "P2:s1", [tenor, bass]);
  if (!recombined.silentPartIds?.includes(sopranoII)) {
    throw new Error("Soprano II disappeared after its divisi measure.");
  }

  const route = model.playback.route;
  if (route.filter((measure) => measure === 1).length < 2 || route.length < 12) {
    throw new Error(`The repeat did not revisit measure 1. Route: ${route.join(",")}`);
  }
  if (score.notes.filter((note) => note.partId === alto).length !== 6) {
    throw new Error("The repeat duplicated written alto notes.");
  }
  const kinds = new Set(model.navigationEvents.map((event) => event.kind));
  for (const kind of ["REPEAT_START", "REPEAT_END", "TO_CODA", "CODA"]) {
    if (!kinds.has(kind as "CODA")) {
      throw new Error(`Navigation is missing ${kind}.`);
    }
  }
  if (score.rehearsalMarks.B !== 3) {
    throw new Error("The rehearsal mark did not stay on its written measure.");
  }
  const shifted = model.recognitionWarnings.filter((warning) => warning.code === "IDENTITY_SHIFT" || warning.code === "IDENTITY_REVIEW");
  if (shifted.length) {
    throw new Error(`The continuity score was flagged: ${shifted.map((warning) => warning.message).join(" ")}`);
  }
  const altoEvents = model.playback.events.filter((event) => event.midi === 67);
  if (altoEvents.length < 3 || altoEvents.some((event) => event.partId !== alto)) {
    throw new Error("Alto playback events left the original alto id.");
  }
}

function descantAboveTheChoirDoesNotShiftIds() {
  const score = interpretUnifiedScore({
    xml: `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1"><part-name>Descant</part-name></score-part>
    <score-part id="P2"><part-name>Soprano</part-name></score-part>
    <score-part id="P3"><part-name>Alto</part-name></score-part>
  </part-list>
  <part id="P1">${one("B", 5)}</part>
  <part id="P2">${one("C", 5)}</part>
  <part id="P3">${one("G", 4)}</part>
</score-partwise>`,
    sourceType: "musicxml",
    sourceUploadType: "MUSICXML",
    pageCount: 1,
  });
  const soprano = score.parts.find((part) => part.id === "P2");
  const alto = score.parts.find((part) => part.id === "P3");
  const descant = score.parts.find((part) => part.id === "P1");
  if (soprano?.canonicalPart !== "SOPRANO" || alto?.canonicalPart !== "ALTO" || descant?.extraKind !== "DESCANT") {
    throw new Error(`A descant above the choir renamed the parts: ${describe(score)}`);
  }
  if (score.notes.find((note) => note.midi === 72)?.partId !== "P2") {
    throw new Error("The soprano line moved onto the descant staff.");
  }
}

function one(step: string, octave: number) {
  return `<measure number="1"><attributes><divisions>1</divisions><key><fifths>0</fifths><mode>major</mode></key><time><beats>4</beats><beat-type>4</beat-type></time><clef><sign>G</sign><line>2</line></clef></attributes><note><pitch><step>${step}</step><octave>${octave}</octave></pitch><duration>4</duration><voice>1</voice></note></measure>`;
}

function unexpectedRelabelIsFlagged() {
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
      <direction><direction-type><words default-x="-12" default-y="16">Alto</words></direction-type></direction>
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
    throw new Error(`A later Alto label rewrote the soprano: ${describe(score)}`);
  }
  const ids = new Set(score.notes.map((note) => note.partId));
  if (ids.size !== 1 || score.notes.length !== 2) {
    throw new Error("The relabeled staff split or dropped notes.");
  }
  const flagged = score.scoreModel?.recognitionWarnings.some((warning) => warning.code === "IDENTITY_SHIFT");
  if (!flagged) {
    throw new Error("An unexpected Alto label was applied instead of flagged for review.");
  }
}

function assertLine(score: ParsedScore, partId: string, name: string, expected: Array<[number, number]>) {
  const actual = score.notes
    .filter((note) => note.partId === partId)
    .map((note) => [note.measureNumber, note.midi] as [number, number])
    .sort((left, right) => left[0] - right[0] || left[1] - right[1]);
  const same =
    actual.length === expected.length && actual.every((item, index) => item[0] === expected[index][0] && item[1] === expected[index][1]);
  if (!same) {
    throw new Error(`${name} ${partId} notes were ${actual.map((item) => `${item[0]}:${item[1]}`).join(",")} instead of the written line. ${describe(score)}`);
  }
  const part = score.parts.find((candidate) => candidate.id === partId);
  if (part?.canonicalPart !== name.toUpperCase()) {
    throw new Error(`${name} changed canonical to ${part?.canonicalPart}.`);
  }
}

function assertStaffHas(
  region: { staffToParts: { staffId: string; partIds: string[] }[] },
  staffId: string,
  partIds: string[]
) {
  const staff = region.staffToParts.find((entry) => entry.staffId === staffId);
  if (!staff || partIds.some((id) => !staff.partIds.includes(id))) {
    throw new Error(`${staffId} mapped to ${staff?.partIds.join(",") ?? "nothing"}, expected ${partIds.join(",")}.`);
  }
}

function region(model: NonNullable<ParsedScore["scoreModel"]>, start: number, end: number) {
  const found = model.layoutRegions.find((entry) => entry.startMeasure === start && entry.endMeasure === end);
  if (!found) {
    throw new Error(`No layout for measures ${start}–${end}.`);
  }
  return found;
}

function idFor(score: ParsedScore, measure: number, midi: number) {
  const note = score.notes.find((candidate) => candidate.measureNumber === measure && candidate.midi === midi);
  if (!note) {
    throw new Error(`No note at measure ${measure} midi ${midi}. ${describe(score)}`);
  }
  return note.partId;
}

function describe(score: ParsedScore) {
  const parts = score.parts.map((part) => `${part.id}:${part.canonicalPart}:${part.sourceName}`).join(" | ");
  const notes = score.notes.map((note) => `m${note.measureNumber}:${note.midi}->${note.partId}`).join(" ");
  return `${parts} || ${notes}`;
}

function continuityScore() {
  return `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1"><part-name>Voice</part-name></score-part>
    <score-part id="P2"><part-name>Voice</part-name></score-part>
    <score-part id="P3"><part-name>Alto</part-name></score-part>
    <score-part id="P4"><part-name>Bass</part-name></score-part>
    <score-part id="P5"><part-name>Soprano II</part-name></score-part>
    <score-part id="P6"><part-name>Descant</part-name></score-part>
    <score-part id="P7"><part-name>Piano</part-name></score-part>
  </part-list>
  <part id="P1">
    ${opening("1", `${label("Soprano", 30)}${label("Alto", 10)}${note("C", 5, 1)}${note("G", 4, 2)}`, true)}
    ${bar("2", `${note("C", 5, 1)}${note("G", 4, 2)}`)}
    ${bar("3", `<print new-page="yes"/>${rehearsal("B")}${label("Soprano", 30)}${note("D", 5, 1)}`)}
    ${bar("4", `${aside("To Coda")}${note("E", 5, 1)}`)}
    ${bar("5", `<print new-system="yes"/>${label("Soprano", 30)}${label("Alto", 10)}${aside("Coda")}${note("F", 5, 1)}${note("A", 4, 2)}`)}
    ${bar("6", `${note("G", 5, 1)}${note("B", 4, 2)}<barline location="right"><bar-style>light-heavy</bar-style><repeat direction="backward"/></barline>`)}
  </part>
  <part id="P2">
    ${opening("1", `${label("Tenor", 30)}${label("Bass", 10)}${note("E", 4, 1)}${note("G", 3, 2)}`)}
    ${bar("2", `${note("E", 4, 1)}${note("G", 3, 2)}`)}
    ${bar("3", "")}
    ${bar("4", "")}
    ${bar("5", `${label("Tenor", 30)}${label("Bass", 10)}${note("E", 4, 1)}${note("G", 3, 2)}`)}
    ${bar("6", `${note("E", 4, 1)}${note("G", 3, 2)}`)}
  </part>
  <part id="P3">
    ${opening("1", "")}
    ${bar("2", "")}
    ${bar("3", `${label("Alto", 20)}${note("G", 4, 1)}`)}
    ${bar("4", `${note("G", 4, 1)}`)}
    ${bar("5", "")}
    ${bar("6", "")}
  </part>
  <part id="P4">
    ${opening("1", "")}
    ${bar("2", "")}
    ${bar("3", `${label("Bass", 12)}${note("G", 3, 1)}`)}
    ${bar("4", `${note("G", 3, 1)}`)}
    ${bar("5", "")}
    ${bar("6", "")}
  </part>
  <part id="P5">
    ${opening("1", "")}
    ${bar("2", "")}
    ${bar("3", "")}
    ${bar("4", `${label("Soprano II", 40)}${note("A", 5, 1)}`)}
    ${bar("5", "")}
    ${bar("6", "")}
  </part>
  <part id="P6">
    ${opening("1", "")}
    ${bar("2", "")}
    ${bar("3", `${label("Descant", 48)}${note("B", 5, 1)}`)}
    ${bar("4", "")}
    ${bar("5", "")}
    ${bar("6", "")}
  </part>
  <part id="P7">
    ${opening("1", note("C", 3, 1), false, "F", 4)}
    ${bar("2", note("C", 3, 1))}
    ${bar("3", note("C", 3, 1))}
    ${bar("4", note("C", 3, 1))}
    ${bar("5", note("C", 3, 1))}
    ${bar("6", note("C", 3, 1))}
  </part>
</score-partwise>`;
}

function opening(number: string, body: string, repeat = false, clef = "G", line = 2) {
  const left = repeat
    ? `<barline location="left"><bar-style>heavy-light</bar-style><repeat direction="forward"/></barline>`
    : "";
  return `<measure number="${number}"><attributes><divisions>1</divisions><key><fifths>0</fifths><mode>major</mode></key><time><beats>4</beats><beat-type>4</beat-type></time><clef><sign>${clef}</sign><line>${line}</line></clef></attributes>${left}${body}</measure>`;
}

function bar(number: string, body: string) {
  return `<measure number="${number}">${body}</measure>`;
}

function note(step: string, octave: number, voice: number) {
  return `<note><pitch><step>${step}</step><octave>${octave}</octave></pitch><duration>4</duration><voice>${voice}</voice></note>`;
}

function label(text: string, y: number) {
  return `<direction><direction-type><words default-x="-12" default-y="${y}">${text}</words></direction-type></direction>`;
}

function aside(text: string) {
  return `<direction><direction-type><words default-x="90" default-y="40">${text}</words></direction-type></direction>`;
}

function rehearsal(mark: string) {
  return `<direction><direction-type><rehearsal>${mark}</rehearsal></direction-type></direction>`;
}
