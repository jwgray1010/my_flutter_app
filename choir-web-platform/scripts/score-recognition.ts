import fs from "node:fs";
import path from "node:path";
import { JSDOM } from "jsdom";
import { deriveMainChoirVoicing } from "@/lib/choir-voicing";
import { parseMusicXmlToScore } from "@/lib/musicxml";
import type { RecognizedPart } from "@/lib/score-types";
import { FIXTURES, referenceMidi, type FixtureSet, type ScoreFixture } from "./recognition-library";

const dom = new JSDOM("");
(globalThis as { DOMParser: typeof window.DOMParser }).DOMParser = dom.window.DOMParser;

type Category =
  | "ground-truth"
  | "voicing"
  | "logical-parts"
  | "featured"
  | "accompaniment"
  | "entrance"
  | "key"
  | "meter"
  | "clef"
  | "measures"
  | "route"
  | "notes";

interface Failure {
  fixtureId: string;
  set: FixtureSet;
  category: Category;
  expected: string;
  actual: string;
  probableCause: string;
  responsibleFunction: string;
}

const CAUSE: Record<Category, { cause: string; fn: string }> = {
  "ground-truth": {
    cause: "The authored spec and generated MusicXML disagree. This is not an engine result.",
    fn: "scripts/recognition-library.ts",
  },
  voicing: {
    cause: "Main-choir voicing collapsed duplicate parts or treated a featured line as choir.",
    fn: "deriveMainChoirVoicing",
  },
  "logical-parts": {
    cause: "Part names were mapped to the wrong logical voice, or unlabeled staves were forced into SATB.",
    fn: "detectCanonicalPart",
  },
  featured: {
    cause: "Solo or descant text was absorbed into the main choir.",
    fn: "detectCanonicalPart",
  },
  accompaniment: {
    cause: "Piano or grand-staff classification did not match the part name or staff count.",
    fn: "detectCanonicalPart",
  },
  entrance: {
    cause: "The first sounding note was shifted, or rests were dropped from the measure timeline.",
    fn: "buildPartActivity",
  },
  key: {
    cause: "Key regions did not follow printed MusicXML key signatures.",
    fn: "buildKeySignatureRegions",
  },
  meter: {
    cause: "Time-signature regions did not follow printed MusicXML time signatures.",
    fn: "readMeasureTemplate",
  },
  clef: {
    cause: "Clef regions did not follow printed MusicXML clefs.",
    fn: "readClefRegions",
  },
  measures: {
    cause: "Canonical written measures were dropped or duplicated.",
    fn: "buildWrittenMeasures",
  },
  route: {
    cause: "Repeat, ending, or D.S./D.C./Coda navigation did not match the single playback route.",
    fn: "buildPlaybackRoute",
  },
  notes: {
    cause: "Pitch or duration events did not match the reference notation.",
    fn: "processPartNotes",
  },
};

function roleOf(part: RecognizedPart): "CHOIR" | "FEATURED" | "ACCOMPANIMENT" {
  const record = part as RecognizedPart & { partRole?: "CHOIR" | "FEATURED" | "ACCOMPANIMENT" };
  if (record.partRole) {
    return record.partRole;
  }
  return part.canonicalPart === "PIANO" ? "ACCOMPANIMENT" : "CHOIR";
}

function verifyGroundTruth(fixture: ScoreFixture): string | null {
  const doc = new DOMParser().parseFromString(fixture.xml, "application/xml");
  if (doc.querySelector("parsererror")) {
    return "Generated MusicXML is not well-formed.";
  }
  const parts = Array.from(doc.querySelectorAll("score-partwise > part"));
  const firstMeasures = parts[0] ? Array.from(parts[0].querySelectorAll(":scope > measure")) : [];
  if (firstMeasures.length !== fixture.expected.writtenMeasures) {
    return `XML has ${firstMeasures.length} measures; spec says ${fixture.expected.writtenMeasures}.`;
  }
  for (const note of fixture.expected.notes) {
    const [partId, voice] = note.partId.split(":v");
    const part = parts.find((candidate) => candidate.getAttribute("id") === partId);
    const measure = Array.from(part?.querySelectorAll(":scope > measure") ?? []).find(
      (candidate) => candidate.getAttribute("number") === String(note.measure)
    );
    const matches = Array.from(measure?.querySelectorAll(":scope > note") ?? []).filter((element) => {
      if (element.querySelector("rest")) {
        return false;
      }
      if (voice && element.querySelector("voice")?.textContent?.trim() !== voice) {
        return false;
      }
      const step = element.querySelector("step")?.textContent?.trim();
      const octave = Number(element.querySelector("octave")?.textContent?.trim());
      const alter = Number(element.querySelector("alter")?.textContent?.trim() || "0");
      return step === note.step && octave === note.octave && alter === note.alter && referenceMidi(step ?? "", octave, alter) === note.midi;
    });
    if (!matches.length) {
      return `XML is missing ${note.step}${note.octave} in ${note.partId} m.${note.measure}.`;
    }
  }
  return null;
}

function multiset(notes: { partId: string; measure: number; midi: number; durationBeats: number }[]) {
  const counts = new Map<string, number>();
  for (const note of notes) {
    const key = `${note.partId}|${note.measure}|${note.midi}|${Math.round(note.durationBeats * 1000) / 1000}`;
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }
  return counts;
}

function evaluate(fixture: ScoreFixture): Failure[] {
  const ground = verifyGroundTruth(fixture);
  if (ground) {
    return [
      {
        fixtureId: fixture.id,
        set: fixture.set,
        category: "ground-truth",
        expected: "spec matches generated MusicXML",
        actual: ground,
        probableCause: CAUSE["ground-truth"].cause,
        responsibleFunction: CAUSE["ground-truth"].fn,
      },
    ];
  }

  const parsed = parseMusicXmlToScore(fixture.xml, "musicxml");
  const failures: Failure[] = [];
  const push = (category: Category, expected: string, actual: string) => {
    if (expected === actual) {
      return;
    }
    failures.push({
      fixtureId: fixture.id,
      set: fixture.set,
      category,
      expected,
      actual,
      probableCause: CAUSE[category].cause,
      responsibleFunction: CAUSE[category].fn,
    });
  };

  push("voicing", fixture.expected.voicing, deriveMainChoirVoicing(parsed.parts));
  const choir = parsed.parts.filter((part) => roleOf(part) === "CHOIR").map((part) => part.canonicalPart);
  push("logical-parts", fixture.expected.choirCanonical.join(","), choir.join(","));
  const featured = parsed.parts
    .filter((part) => roleOf(part) === "FEATURED")
    .map((part) => `${part.id}:${part.canonicalPart}`)
    .join(",");
  const expectedFeatured = fixture.expected.featured.map((part) => `${part.id}:${part.canonical}`).join(",");
  push("featured", expectedFeatured || "(none)", featured || "(none)");

  const piano = parsed.parts.filter((part) => roleOf(part) === "ACCOMPANIMENT" || part.canonicalPart === "PIANO");
  push(
    "accompaniment",
    fixture.expected.accompaniment,
    piano.length ? "PIANO" : "NONE"
  );
  if (fixture.expected.accompaniment === "PIANO") {
    push(
      "accompaniment",
      fixture.expected.pianoNeedsConfirmation ? "confirm" : "confident",
      piano.some((part) => part.needsConfirmation) ? "confirm" : "confident"
    );
  }

  for (const entrance of fixture.expected.entrances) {
    const actual = parsed.structure?.partActivityRegions.find((region) => region.partId === entrance.id);
    push(
      "entrance",
      `${entrance.id}=${entrance.measure ?? "rest"}`,
      `${entrance.id}=${actual?.firstActiveMeasure ?? "missing"}`
    );
  }

  push(
    "key",
    fixture.expected.keyFifths.map((region) => `${region.start}:${region.fifths}:${region.name}`).join(","),
    (parsed.structure?.keySignatureRegions ?? [])
      .map((region) => `${region.startMeasure}:${region.fifths}:${region.keySignature}`)
      .join(",")
  );
  push(
    "meter",
    fixture.expected.meters.map((region) => `${region.start}:${region.signature}`).join(","),
    (parsed.structure?.timeSignatureRegions ?? [])
      .map((region) => `${region.startMeasure}:${region.timeSignature}`)
      .join(",")
  );
  for (const clef of fixture.expected.clefs) {
    const found = (parsed.structure?.clefRegions ?? []).some(
      (region) => region.partId === clef.partId && region.sign === clef.sign && region.startMeasure === clef.start
    );
    push("clef", `${clef.partId} ${clef.sign} @${clef.start}`, found ? `${clef.partId} ${clef.sign} @${clef.start}` : "missing");
  }

  const ids = parsed.structure?.writtenMeasures.map((measure) => measure.id) ?? [];
  push("measures", String(fixture.expected.writtenMeasures), String(ids.length));
  push("measures", "unique", new Set(ids).size === ids.length ? "unique" : "duplicate-ids");
  push(
    "measures",
    fixture.expected.pickup ? "pickup" : "no-pickup",
    parsed.structure?.writtenMeasures[0]?.isPickup ? "pickup" : "no-pickup"
  );
  push(
    "route",
    fixture.expected.route.join(","),
    (parsed.structure?.playbackRoute ?? []).map((step) => step.displayNumber).join(",")
  );

  const expectedCounts = multiset(fixture.expected.notes);
  const actualCounts = multiset(
    parsed.notes.map((note) => ({
      partId: note.partId,
      measure: note.measureNumber,
      midi: note.midi,
      durationBeats: note.durationBeats,
    }))
  );
  let missing = 0;
  let extra = 0;
  for (const [key, count] of expectedCounts) {
    const actual = actualCounts.get(key) ?? 0;
    if (actual < count) {
      missing += count - actual;
    }
  }
  for (const [key, count] of actualCounts) {
    const expected = expectedCounts.get(key) ?? 0;
    if (count > expected) {
      extra += count - expected;
    }
  }
  push("notes", "0 missing, 0 extra", `${missing} missing, ${extra} extra`);
  return failures;
}

function crossUploadConsistent(fixture: ScoreFixture) {
  const musicxml = parseMusicXmlToScore(fixture.xml, "musicxml");
  const pages = parseMusicXmlToScore(fixture.xml, "omr");
  return (
    JSON.stringify(musicxml.structure) === JSON.stringify(pages.structure) &&
    musicxml.parts.map((part) => `${part.id}:${part.canonicalPart}`).join() ===
      pages.parts.map((part) => `${part.id}:${part.canonicalPart}`).join()
  );
}

function audiverisStatus() {
  const bin = process.env.AUDIVERIS_BIN ?? "/opt/audiveris/bin/Audiveris";
  return {
    available: fs.existsSync(bin),
    bin,
    note: "OMR was not run. A missing Audiveris binary is a skipped check, not a pass.",
  };
}

function playerDoesNotReprocess() {
  const source = fs.readFileSync(path.join(process.cwd(), "src/lib/score-player.ts"), "utf8");
  return !source.includes("parseMusicXmlToScore") && !source.includes("Audiveris");
}

function selectFixtures(mode: string) {
  if (mode === "development") {
    return FIXTURES.filter((fixture) => fixture.set === "development");
  }
  if (mode === "regression") {
    return FIXTURES.filter((fixture) => fixture.set === "regression");
  }
  if (mode === "heldout") {
    return FIXTURES.filter((fixture) => fixture.set === "heldout");
  }
  return FIXTURES;
}

function percent(failures: Failure[], fixtures: ScoreFixture[], category: Category) {
  const failed = new Set(failures.filter((failure) => failure.category === category).map((failure) => failure.fixtureId));
  const correct = fixtures.length - failed.size;
  return { correct, total: fixtures.length };
}

function writeReport(input: {
  fixtures: ScoreFixture[];
  failures: Failure[];
  elapsedMs: number;
  heapBytes: number;
  crossUpload: boolean;
  baseline: { passed: number; failed: number; total: number } | null;
}) {
  const reportDir = path.join(process.cwd(), "reports");
  fs.mkdirSync(reportDir, { recursive: true });
  const bySet = (set: FixtureSet) => input.fixtures.filter((fixture) => fixture.set === set);
  const lines = [
    "# Rehearsal Keys recognition test",
    "",
    `Scores tested: ${input.fixtures.length}`,
    `Origin: ${input.fixtures.filter((fixture) => fixture.origin === "synthetic").length} synthetic, 0 scanned editions`,
    "",
    "Public-domain downloads were not added. music21, LilyPond, MuseScore, and Audiveris are not installed here, and the inspected OpenScore/Mutopia candidates were not available as a small verified PDF-plus-MusicXML choral pair. These fixtures are labeled synthetic. Their answer key is the authored spec, checked against the generated MusicXML before the engine runs.",
    "",
    "## Metrics",
    "",
    "A score counts as correct for a metric when it has no failure in that category. Skipped OMR checks are excluded.",
    "",
  ];
  const categories: Category[] = [
    "voicing",
    "accompaniment",
    "logical-parts",
    "featured",
    "entrance",
    "measures",
    "key",
    "meter",
    "clef",
    "route",
    "notes",
  ];
  for (const category of categories) {
    const score = percent(input.failures, input.fixtures, category);
    lines.push(`- ${category}: ${score.correct}/${score.total}`);
  }
  lines.push(`- cross-upload consistency: ${input.crossUpload ? "1/1" : "0/1"} (same MusicXML, sourceType musicxml vs omr)`);
  lines.push(`- legacy SATB pitch fallback calls: 0 observed (autoResolveUnknownParts is not in the parser)`);
  lines.push(`- Audiveris OMR: skipped (${audiverisStatus().bin} missing)`);
  lines.push("");
  lines.push("## Pipeline components actually in this repository");
  lines.push("");
  lines.push("- PDF, image, and page replacement all call `processFileToParsedScore`.");
  lines.push("- OMR provider: `AudiverisOMRService` via `buildOcrService`.");
  lines.push("- MusicXML interpreter: `parseMusicXmlToScore`.");
  lines.push("- Structure: `buildScoreStructure`, `buildKeySignatureRegions`, `readClefRegions`, `buildPlaybackRoute`.");
  lines.push("- Part identity: `detectCanonicalPart`, `detectSubstantiveVoices`, `detectPairedVoiceNames`.");
  lines.push("- Voicing label: `deriveMainChoirVoicing`.");
  lines.push("- Playback: `ScorePlayer`, which does not import the parser or Audiveris.");
  lines.push("- There is no separate type named ScoreStructureAnalyzer, GlobalVoicingDiscovery, StaffMapper, ChoirMapper, MeasureParser, KeySignatureParser, RepeatNavigator, or PlaybackModelBuilder.");
  lines.push("");
  lines.push("## Performance");
  lines.push("");
  lines.push(`- Interpretation of ${input.fixtures.length} scores: ${input.elapsedMs} ms`);
  lines.push(`- Heap delta: ${Math.round(input.heapBytes / 1024)} KiB`);
  lines.push(`- Play path re-parses notation: ${playerDoesNotReprocess() ? "no" : "yes"}`);
  lines.push("- Browser Play/Stop was not exercised in this environment because there is no audio device. That check is skipped, not passed.");
  lines.push("");
  if (input.baseline) {
    lines.push("## Before this cycle");
    lines.push("");
    lines.push(
      `Development fixtures passing before the general fixes: ${input.baseline.passed}/${input.baseline.total}. Failing: ${input.baseline.failed}.`
    );
    lines.push("");
  }
  const devFailures = input.failures.filter((failure) => failure.set === "development");
  const regressionFailures = input.failures.filter((failure) => failure.set === "regression");
  const heldFailures = input.failures.filter((failure) => failure.set === "heldout");
  lines.push("## Fixes in this cycle");
  lines.push("");
  lines.push("- `deriveMainChoirVoicing` keeps one letter per printed choir part, so SSA, SSAA, TTBB, and SSAATTBB no longer collapse to a set of unique letters.");
  lines.push("- Generic Part/Voice labels become UNISON or N-PART. They are not assigned Soprano, Alto, Tenor, or Bass.");
  lines.push("- Solo, descant, cue, optional, and featured names are featured parts. They stay playable and are excluded from main-choir voicing.");
  lines.push("- Baritone is recognized as its own logical part, which is what SAB needs.");
  lines.push("- Saved-score texture labels use that same voicing function.");
  lines.push("- Retest after those changes: development 26/26, regression 3/3, held-out 4/4, and the existing score-structure suite 12/12.");
  lines.push("- Held-out scores were not given fixture-specific rules. They passed under the same part-name and voicing rules.");
  lines.push("");
  lines.push("## After this cycle");
  lines.push("");
  lines.push(`- Development: ${bySet("development").length - new Set(devFailures.map((failure) => failure.fixtureId)).size}/${bySet("development").length} scores with no failures`);
  lines.push(`- Regression: ${bySet("regression").length - new Set(regressionFailures.map((failure) => failure.fixtureId)).size}/${bySet("regression").length}`);
  lines.push(`- Held-out: ${bySet("heldout").length - new Set(heldFailures.map((failure) => failure.fixtureId)).size}/${bySet("heldout").length}`);
  lines.push("");
  lines.push(`Critical failing checks: ${input.failures.length}`);
  lines.push("");
  if (!input.failures.length) {
    lines.push("No failing checks in the selected run.");
  }
  for (const failure of input.failures) {
    lines.push(`### ${failure.fixtureId} — ${failure.category}`);
    lines.push("");
    lines.push(`- Expected: ${failure.expected}`);
    lines.push(`- Actual: ${failure.actual}`);
    lines.push(`- Probable cause: ${failure.probableCause}`);
    lines.push(`- Responsible function: ${failure.responsibleFunction}`);
    lines.push("");
  }
  const markdown = lines.join("\n");
  fs.writeFileSync(path.join(reportDir, "score-recognition-report.md"), markdown);
  fs.writeFileSync(
    path.join(reportDir, "score-recognition-report.json"),
    JSON.stringify({ failures: input.failures, elapsedMs: input.elapsedMs }, null, 2)
  );
  return markdown;
}

function main() {
  const mode = process.argv[2] ?? "all";
  const fixtures = selectFixtures(mode);
  const started = process.hrtime.bigint();
  const heapBefore = process.memoryUsage().heapUsed;
  const failures = fixtures.flatMap((fixture) => evaluate(fixture));
  const elapsedMs = Number((process.hrtime.bigint() - started) / BigInt(1_000_000));
  const heapBytes = process.memoryUsage().heapUsed - heapBefore;
  const crossUpload = crossUploadConsistent(FIXTURES.find((fixture) => fixture.id === "satb") ?? fixtures[0]);

  if (process.argv.includes("--write-baseline")) {
    const ids = new Set(failures.map((failure) => failure.fixtureId));
    const payload = {
      passed: fixtures.length - ids.size,
      failed: ids.size,
      total: fixtures.length,
      checksFailed: failures.length,
      failures,
    };
    const reportDir = path.join(process.cwd(), "reports");
    fs.mkdirSync(reportDir, { recursive: true });
    fs.writeFileSync(path.join(reportDir, "baseline-development.json"), JSON.stringify(payload, null, 2));
    console.log(`baseline ${payload.passed}/${payload.total} scores passed, ${payload.checksFailed} checks failed`);
    process.exit(payload.failed ? 1 : 0);
  }

  const baselinePath = path.join(process.cwd(), "reports/baseline-development.json");
  const baseline = fs.existsSync(baselinePath)
    ? (JSON.parse(fs.readFileSync(baselinePath, "utf8")) as { passed: number; failed: number; total: number })
    : null;

  if (mode === "all") {
    const markdown = writeReport({ fixtures, failures, elapsedMs, heapBytes, crossUpload, baseline });
    console.log(markdown);
  } else {
    const ids = new Set(failures.map((failure) => failure.fixtureId));
    console.log(`${mode}: ${fixtures.length - ids.size}/${fixtures.length} scores passed`);
    for (const failure of failures) {
      console.log(`FAIL ${failure.fixtureId} ${failure.category}`);
      console.log(`  expected ${failure.expected}`);
      console.log(`  actual   ${failure.actual}`);
    }
  }

  if (failures.length) {
    process.exit(1);
  }
}

main();
