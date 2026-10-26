import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";
import { rasterizePdfPages } from "@/lib/normalize-pages";
import { PIPELINE_VERSION } from "@/lib/score-model";
import type { ParsedScore } from "@/lib/score-types";
import { guardLockedVoicing, interpretUnifiedScore } from "@/lib/unified-pipeline";
import { assignChoirRegisters } from "@/lib/voicing";
import { SYNTHETIC_FIXTURES } from "./catalog";
import { realizeFixture } from "./realize";

export async function runArchitectureChecks() {
  crossUploadAgrees();
  lockedVoicingCannotBeOverwritten();
  duplicateWrittenMeasureIsRejected();
  legacyProcessorIsRejected();
  dalCapoStopsAtFine();
  await pdfBecomesOrderedPages();
  console.log("Architecture checks passed.");
}

function crossUploadAgrees() {
  const spec = SYNTHETIC_FIXTURES.find((fixture) => fixture.id === "reg-choir-entrance");
  if (!spec) {
    throw new Error("Missing choir-entrance fixture.");
  }
  const xml = realizeFixture(spec).xml;
  const pdf = interpretUnifiedScore({
    xml,
    sourceType: "musicxml",
    sourceUploadType: "PDF",
    pageCount: 3,
  });
  const images = interpretUnifiedScore({
    xml,
    sourceType: "musicxml",
    sourceUploadType: "MULTI_IMAGE",
    pageCount: 3,
  });
  if (pdf.scoreModel?.pipelineVersion !== PIPELINE_VERSION || images.scoreModel?.sourceUploadType !== "MULTI_IMAGE") {
    throw new Error("Upload source was not recorded on the score model.");
  }
  if (pdf.scoreModel.sourceUploadType !== "PDF") {
    throw new Error("PDF upload was not recorded.");
  }
  const left = musicalSignature(pdf);
  const right = musicalSignature(images);
  if (JSON.stringify(left) !== JSON.stringify(right)) {
    throw new Error(`PDF and multi-image interpretation differ.\n${JSON.stringify(left)}\n${JSON.stringify(right)}`);
  }
  const choir = pdf.scoreModel.playback.channels.filter((channel) => channel.group === "CHOIR");
  if (choir.some((channel) => channel.entersAtMeasure !== 6)) {
    throw new Error("Choir entrance moved earlier than measure 6.");
  }
  const piano = pdf.scoreModel.playback.channels.find((channel) => channel.group === "ACCOMPANIMENT");
  if (piano?.entersAtMeasure !== 1) {
    throw new Error("Piano entrance was not measure 1.");
  }
}

function lockedVoicingCannotBeOverwritten() {
  const spec = SYNTHETIC_FIXTURES.find((fixture) => fixture.id === "reg-lock-ttbb");
  if (!spec?.setup) {
    throw new Error("Missing locked voicing fixture.");
  }
  const score = interpretUnifiedScore({
    xml: realizeFixture(spec).xml,
    sourceType: "musicxml",
    sourceUploadType: "MUSICXML",
    pageCount: 1,
    setup: spec.setup,
  });
  if (score.scoreModel?.mainChoirVoicing !== "TTBB" || !score.scoreModel.voicingLocked) {
    throw new Error(`Director lock was not kept (got ${score.scoreModel?.mainChoirVoicing}).`);
  }
  try {
    guardLockedVoicing(score, "SATB");
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (message.includes("VOICING OVERRIDE BUG")) {
      return;
    }
    throw error;
  }
  throw new Error("A later pass changed locked voicing without a director action.");
}

function duplicateWrittenMeasureIsRejected() {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list><score-part id="P1"><part-name>Soprano</part-name></score-part></part-list>
  <part id="P1">
    <measure number="2"><note><pitch><step>C</step><octave>5</octave></pitch><duration>4</duration><voice>1</voice></note></measure>
    <measure number="2"><note><pitch><step>D</step><octave>5</octave></pitch><duration>4</duration><voice>1</voice></note></measure>
  </part>
</score-partwise>`;
  try {
    interpretUnifiedScore({
      xml,
      sourceType: "musicxml",
      sourceUploadType: "MUSICXML",
      pageCount: 1,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (message.includes("DUPLICATE WRITTEN MEASURE")) {
      return;
    }
    throw error;
  }
  throw new Error("Duplicate written measures were accepted.");
}

function legacyProcessorIsRejected() {
  try {
    assignChoirRegisters([], []);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (message.includes("LEGACY SCORE PROCESSING PATH CALLED") && message.includes("assignChoirRegisters")) {
      return;
    }
    throw error;
  }
  throw new Error("Legacy pitch assignment ran.");
}

function dalCapoStopsAtFine() {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list><score-part id="P1"><part-name>Soprano</part-name></score-part></part-list>
  <part id="P1">
    <measure number="1"><attributes><divisions>1</divisions><key><fifths>0</fifths><mode>major</mode></key><time><beats>4</beats><beat-type>4</beat-type></time></attributes><note><pitch><step>C</step><octave>5</octave></pitch><duration>4</duration><voice>1</voice></note></measure>
    <measure number="2"><direction><direction-type><words>Fine</words></direction-type></direction><note><pitch><step>D</step><octave>5</octave></pitch><duration>4</duration><voice>1</voice></note></measure>
    <measure number="3"><note><pitch><step>E</step><octave>5</octave></pitch><duration>4</duration><voice>1</voice></note></measure>
    <measure number="4"><direction><direction-type><words>D.C. al Fine</words></direction-type></direction><note><pitch><step>F</step><octave>5</octave></pitch><duration>4</duration><voice>1</voice></note></measure>
  </part>
</score-partwise>`;
  const score = interpretUnifiedScore({
    xml,
    sourceType: "musicxml",
    sourceUploadType: "MUSICXML",
    pageCount: 1,
  });
  const route = (score.performanceRoute ?? []).join(",");
  if (route !== "1,2,3,4,1,2") {
    throw new Error(`D.C. al Fine route was ${route}`);
  }
  if (score.measures.length !== 4) {
    throw new Error("D.C. duplicated written measures.");
  }
  const labels = score.measures.map((measure) => measure.displayLabel);
  if (new Set(labels).size !== labels.length) {
    throw new Error("DUPLICATE WRITTEN MEASURE");
  }
}

async function pdfBecomesOrderedPages() {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), "rk-pdf-"));
  try {
    const pdfPath = path.join(directory, "pages.pdf");
    await fs.writeFile(pdfPath, blankPdf(2));
    const pages = await rasterizePdfPages(pdfPath, path.join(directory, "out"));
    if (pages.length !== 2) {
      throw new Error(`PDF split produced ${pages.length} pages.`);
    }
  } finally {
    await fs.rm(directory, { recursive: true, force: true });
  }
}

function musicalSignature(score: ParsedScore) {
  const model = score.scoreModel;
  if (!model) {
    throw new Error("Score model missing.");
  }
  return {
    voicing: model.mainChoirVoicing,
    locked: model.voicingLocked,
    parts: model.logicalParts.map((part) => [part.canonicalPart, part.extraKind]),
    extra: model.extraPlayableParts.map((part) => [part.label, part.canonicalPart]),
    accompaniment: model.accompaniment.kind,
    measures: model.writtenMeasures.length,
    entrances: model.playback.channels.map((channel) => [channel.group, channel.entersAtMeasure]),
    keys: model.keySignatureRegions.map((region) => [region.startMeasure, region.label]),
    meters: model.timeSignatureRegions.map((region) => [region.startMeasure, region.timeSignature]),
    layouts: model.layoutRegions.map((region) => [region.startMeasure, region.endMeasure]),
    navigation: model.navigationEvents.map((event) => [event.kind, event.measureNumber]),
    channels: model.playback.channels.map((channel) => [channel.group, channel.canonicalPart]),
  };
}

function blankPdf(pageCount: number): Buffer {
  const objects = new Map<number, string>();
  const pageIds: number[] = [];
  for (let index = 0; index < pageCount; index += 1) {
    pageIds.push(index + 3);
  }
  objects.set(1, "<< /Type /Catalog /Pages 2 0 R >>");
  objects.set(2, `<< /Type /Pages /Count ${pageCount} /Kids [${pageIds.map((id) => `${id} 0 R`).join(" ")}] >>`);
  for (const id of pageIds) {
    objects.set(id, "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] >>");
  }
  let body = "%PDF-1.4\n";
  const offsets: number[] = [0];
  for (let id = 1; id <= pageCount + 2; id += 1) {
    offsets[id] = Buffer.byteLength(body);
    body += `${id} 0 obj\n${objects.get(id)}\nendobj\n`;
  }
  const xref = Buffer.byteLength(body);
  body += `xref\n0 ${pageCount + 3}\n`;
  body += "0000000000 65535 f \n";
  for (let id = 1; id <= pageCount + 2; id += 1) {
    body += `${String(offsets[id]).padStart(10, "0")} 00000 n \n`;
  }
  body += `trailer << /Size ${pageCount + 3} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF`;
  return Buffer.from(body);
}
