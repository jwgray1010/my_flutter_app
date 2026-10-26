import assert from "node:assert/strict";
import { JSDOM } from "jsdom";
import { parseMusicXmlToScore } from "@/lib/musicxml";

const dom = new JSDOM("");
(globalThis as { DOMParser: typeof window.DOMParser }).DOMParser = dom.window.DOMParser;

function quarter(step: string, octave: number, alter = 0) {
  const alterXml = alter === 0 ? "" : `<alter>${alter}</alter>`;
  return `<note><pitch><step>${step}</step>${alterXml}<octave>${octave}</octave></pitch><duration>1</duration><voice>1</voice><type>quarter</type></note>`;
}

function rest() {
  return `<note><rest/><duration>1</duration><voice>1</voice><type>quarter</type></note>`;
}

function measure(number: number, inner: string, extras = "", attributes = "") {
  return `<measure number="${number}"><attributes><divisions>1</divisions><time><beats>4</beats><beat-type>4</beat-type></time>${attributes}</attributes>${extras}${inner}</measure>`;
}

function part(id: string, measures: string) {
  return `<part id="${id}">${measures}</part>`;
}

function score(partList: string, parts: string) {
  return `<?xml version="1.0" encoding="UTF-8"?><score-partwise version="3.1"><part-list>${partList}</part-list>${parts}</score-partwise>`;
}

function fourQuarters(step = "C", octave = 4, alter = 0) {
  return quarter(step, octave, alter).repeat(4);
}

function parse(xml: string, sourceType: "musicxml" | "omr" = "musicxml") {
  return parseMusicXmlToScore(xml, sourceType);
}

function routeNumbers(xml: string) {
  const parsed = parse(xml);
  return parsed.structure?.playbackRoute.map((step) => step.displayNumber) ?? [];
}

const sopranoList = `<score-part id="P1"><part-name>Soprano</part-name></score-part>`;
const choirList = `
  <score-part id="P1"><part-name>Soprano</part-name></score-part>
  <score-part id="P2"><part-name>Alto</part-name></score-part>`;
const pianoChoirList = `
  <score-part id="P1"><part-name>Soprano</part-name></score-part>
  <score-part id="P2"><part-name>Piano</part-name></score-part>`;

function testStableKeyDespiteAccidentals() {
  const body = [1, 2, 3, 4]
    .map((number, index) => {
      const key = index === 0 ? `<key><fifths>-1</fifths></key>` : "";
      return measure(number, fourQuarters("F", 4, number === 2 ? 1 : 0), "", key);
    })
    .join("");
  const parsed = parse(score(sopranoList, part("P1", body)));
  assert.equal(parsed.structure?.keySignatureRegions.length, 1);
  assert.equal(parsed.structure?.keySignatureRegions[0]?.keySignature, "F major");
  assert.equal(parsed.keySignature, "F major");
  assert.equal(parsed.structure?.keyChangeTrace.filter((trace) => trace.confidence === "confirmed").length, 1);
  const ids = parsed.structure?.writtenMeasures.map((measure) => measure.id) ?? [];
  assert.equal(new Set(ids).size, ids.length);
  assert.equal(parsed.structure?.playbackRoute.length, parsed.structure?.writtenMeasures.length);
}

function testPrintedModulation() {
  const soprano = [1, 2, 3, 4]
    .map((number) => measure(number, fourQuarters("C", 5), "", number === 1 || number === 3 ? `<key><fifths>${number === 1 ? 0 : 2}</fifths></key>` : ""))
    .join("");
  const alto = [1, 2, 3, 4]
    .map((number) => measure(number, fourQuarters("G", 4), "", number === 1 || number === 3 ? `<key><fifths>${number === 1 ? 0 : 2}</fifths></key>` : ""))
    .join("");
  const parsed = parse(score(choirList, part("P1", soprano) + part("P2", alto)));
  assert.deepEqual(
    parsed.structure?.keySignatureRegions.map((region) => [region.startMeasure, region.keySignature]),
    [
      [1, "C major"],
      [3, "D major"],
    ]
  );
}

function testRejectsOneMeasureKeyFlicker() {
  const soprano = [1, 2, 3]
    .map((number) =>
      measure(
        number,
        fourQuarters(),
        "",
        `<key><fifths>${number === 2 ? 2 : -2}</fifths></key>`
      )
    )
    .join("");
  const alto = [1, 2, 3]
    .map((number) => measure(number, fourQuarters("A", 4), "", number === 1 ? `<key><fifths>-2</fifths></key>` : ""))
    .join("");
  const parsed = parse(score(choirList, part("P1", soprano) + part("P2", alto)));
  assert.equal(parsed.structure?.keySignatureRegions.length, 1);
  assert.equal(parsed.structure?.keySignatureRegions[0]?.keySignature, "Bb major");
  assert.ok(parsed.structure?.recognitionWarnings.some((warning) => warning.includes("key-signature conflict")));
}

function testSimpleRepeatDoesNotCopyMeasures() {
  const body = [
    measure(1, fourQuarters(), `<barline location="left"><repeat direction="forward"/></barline>`),
    measure(2, fourQuarters(), `<barline location="right"><repeat direction="backward"/></barline>`),
    measure(3, fourQuarters()),
    measure(4, fourQuarters()),
  ].join("");
  const parsed = parse(score(sopranoList, part("P1", body)));
  assert.deepEqual(routeNumbers(score(sopranoList, part("P1", body))), [1, 2, 1, 2, 3, 4]);
  assert.equal(parsed.structure?.writtenMeasures.length, 4);
  assert.equal(new Set(parsed.structure?.writtenMeasures.map((measure) => measure.id)).size, 4);
  assert.equal(parsed.measures.length, 4);
  assert.ok(parsed.notes.filter((note) => note.measureNumber === 1).length > 0);
}

function testFirstAndSecondEndings() {
  const body = [
    measure(1, fourQuarters(), `<barline location="left"><repeat direction="forward"/></barline>`),
    measure(2, fourQuarters()),
    measure(
      3,
      fourQuarters(),
      `<barline location="left"><ending number="1" type="start"/></barline><barline location="right"><ending number="1" type="stop"/><repeat direction="backward"/></barline>`
    ),
    measure(4, fourQuarters(), `<barline location="left"><ending number="2" type="start"/></barline><barline location="right"><ending number="2" type="stop"/></barline>`),
  ].join("");
  assert.deepEqual(routeNumbers(score(sopranoList, part("P1", body))), [1, 2, 3, 1, 2, 4]);
}

function testDalSegnoCodaKeepsWrittenMeasuresUnique() {
  const body = [
    measure(1, fourQuarters()),
    measure(2, fourQuarters(), `<direction><direction-type><words>Segno</words></direction-type><sound segno="segno"/></direction>`),
    measure(3, fourQuarters(), `<direction><direction-type><words>To Coda</words></direction-type><sound tocoda="coda"/></direction>`),
    measure(4, fourQuarters(), `<direction><direction-type><words>D.S. al Coda</words></direction-type><sound dalsegno="segno"/></direction>`),
    measure(5, fourQuarters(), `<direction><direction-type><words>Coda</words></direction-type><sound coda="coda"/></direction>`),
  ].join("");
  const parsed = parse(score(sopranoList, part("P1", body)));
  assert.deepEqual(
    parsed.structure?.playbackRoute.map((step) => step.displayNumber),
    [1, 2, 3, 4, 2, 3, 5]
  );
  assert.equal(parsed.structure?.writtenMeasures.length, 5);
  assert.equal(parsed.measures.length, 5);
}

function testDaCapoAlFineStopsAtFine() {
  const body = [
    measure(1, fourQuarters()),
    measure(2, fourQuarters(), `<direction><direction-type><words>Fine</words></direction-type><sound fine="yes"/></direction>`),
    measure(3, fourQuarters()),
    measure(4, fourQuarters(), `<direction><direction-type><words>D.C. al Fine</words></direction-type><sound dacapo="yes"/></direction>`),
  ].join("");
  assert.deepEqual(routeNumbers(score(sopranoList, part("P1", body))), [1, 2, 3, 4, 1, 2]);
}

function testChoirEntranceAfterPianoIntroduction() {
  const singer = [1, 2, 3, 4, 5].map((number) => measure(number, rest().repeat(4))).join("") + measure(6, fourQuarters("E", 5));
  const piano = [1, 2, 3, 4, 5, 6].map((number) => measure(number, fourQuarters("C", 3))).join("");
  const parsed = parse(score(pianoChoirList, part("P1", singer) + part("P2", piano)));
  const soprano = parsed.structure?.partActivityRegions.find((region) => region.canonicalPart === "SOPRANO");
  const accompaniment = parsed.structure?.partActivityRegions.find((region) => region.canonicalPart === "PIANO");
  assert.equal(soprano?.firstActiveMeasure, 6);
  assert.equal(accompaniment?.firstActiveMeasure, 1);
  assert.ok(parsed.notes.filter((note) => note.partCanonical === "SOPRANO").every((note) => note.measureNumber === 6));
}

function testUploadSourceDoesNotChangeInterpretation() {
  const body = measure(1, fourQuarters(), "", `<key><fifths>0</fifths></key>`) + measure(2, fourQuarters());
  const xml = score(sopranoList, part("P1", body));
  const fromFile = parse(xml, "musicxml");
  const fromPages = parse(xml, "omr");
  assert.deepEqual(fromFile.structure?.writtenMeasures, fromPages.structure?.writtenMeasures);
  assert.deepEqual(fromFile.structure?.keySignatureRegions, fromPages.structure?.keySignatureRegions);
  assert.deepEqual(fromFile.structure?.playbackRoute, fromPages.structure?.playbackRoute);
  assert.deepEqual(fromFile.structure?.partActivityRegions, fromPages.structure?.partActivityRegions);
  assert.equal(fromFile.structure?.pipelineVersion, "UNIFIED_SCORE_PIPELINE_V1");
}

function testUnlabeledVoiceIsNotAssignedSatb() {
  const xml = score(
    `<score-part id="P1"><part-name>Voice</part-name></score-part>`,
    part("P1", measure(1, fourQuarters("C", 5)))
  );
  const parsed = parse(xml);
  assert.equal(parsed.parts[0]?.canonicalPart, "UNKNOWN");
  assert.equal(parsed.parts[0]?.needsConfirmation, true);
  assert.ok(parsed.structure?.recognitionWarnings.some((warning) => warning.includes("assuming SATB")));
}

function testPickupIsNotADurationError() {
  const pickup = `<measure number="0"><attributes><divisions>1</divisions><time><beats>4</beats><beat-type>4</beat-type></time><key><fifths>0</fifths></key></attributes>${quarter("G", 4)}</measure>`;
  const full = measure(1, fourQuarters());
  const parsed = parse(score(sopranoList, part("P1", pickup + full)));
  assert.equal(parsed.structure?.writtenMeasures[0]?.isPickup, true);
  assert.equal(
    parsed.structure?.recognitionWarnings.some((warning) => warning.includes("duration")),
    false
  );
}

function testDuplicatePrintedNumbersStayDistinctIds() {
  const body = measure(1, fourQuarters()) + measure(1, fourQuarters("D", 4));
  const parsed = parse(score(sopranoList, part("P1", body)));
  assert.equal(parsed.structure?.writtenMeasures.length, 2);
  assert.notEqual(parsed.structure?.writtenMeasures[0]?.id, parsed.structure?.writtenMeasures[1]?.id);
  assert.ok(parsed.structure?.recognitionWarnings.some((warning) => warning.includes("DUPLICATE WRITTEN MEASURE")));
}

const tests = [
  testStableKeyDespiteAccidentals,
  testPrintedModulation,
  testRejectsOneMeasureKeyFlicker,
  testSimpleRepeatDoesNotCopyMeasures,
  testFirstAndSecondEndings,
  testDalSegnoCodaKeepsWrittenMeasuresUnique,
  testDaCapoAlFineStopsAtFine,
  testChoirEntranceAfterPianoIntroduction,
  testUploadSourceDoesNotChangeInterpretation,
  testUnlabeledVoiceIsNotAssignedSatb,
  testPickupIsNotADurationError,
  testDuplicatePrintedNumbersStayDistinctIds,
];

for (const test of tests) {
  test();
  console.log(`ok ${test.name}`);
}
console.log(`\n${tests.length} score-structure tests passed`);
