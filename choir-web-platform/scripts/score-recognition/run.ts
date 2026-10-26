import { execFile } from "node:child_process";
import { createRequire } from "node:module";
import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";
import { promisify } from "node:util";
import sharp from "sharp";
import { processFileToParsedScore } from "@/lib/server/score-processing";
import { SYNTHETIC_FIXTURES } from "./catalog";
import {
  buildPlaybackSchedule,
  evaluateParsedScore,
  type FailureCategory,
  type FixtureEvaluation,
} from "./evaluate";
import { realizeFixture } from "./realize";
import type { ExpectedScore, FixtureProvenance, FixtureSet } from "./types";

const execFileAsync = promisify(execFile);
const require = createRequire(import.meta.url);

interface LoadedFixture {
  id: string;
  title: string;
  set: FixtureSet;
  origin: "synthetic" | "encoded-public-domain";
  provenance: FixtureProvenance;
  xml: string;
  expected: ExpectedScore;
  verified: boolean;
  unverifiedReason?: string | null;
  omrProbe?: boolean;
}

interface RunOptions {
  sets: FixtureSet[];
  report: boolean;
  omr: boolean;
  baselineOut: string | null;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const loaded = await loadFixtures();
  const selected = loaded.filter((fixture) => options.sets.includes(fixture.set));
  const verified = selected.filter((fixture) => fixture.verified);
  const blocked = selected.filter((fixture) => !fixture.verified);

  const evaluations: FixtureEvaluation[] = [];
  let scheduleMs = 0;
  let scheduleChecks = 0;
  const heapBefore = process.memoryUsage().heapUsed;
  for (const fixture of verified) {
    const directory = await fs.mkdtemp(path.join(os.tmpdir(), "rk-score-"));
    try {
      const filePath = path.join(directory, `${fixture.id}.musicxml`);
      await fs.writeFile(filePath, fixture.xml, "utf8");
      const started = performance.now();
      const processed = await processFileToParsedScore({
        filePath,
        originalFileName: `${fixture.id}.musicxml`,
        mimeType: "application/vnd.recordare.musicxml+xml",
        audiverisOutputDir: path.join(directory, "audiveris"),
      });
      const firstSchedule = buildPlaybackSchedule(processed.parsedScore);
      const repeatStarted = performance.now();
      for (let index = 0; index < 200; index += 1) {
        buildPlaybackSchedule(processed.parsedScore);
      }
      scheduleMs += performance.now() - repeatStarted;
      scheduleChecks += 1;
      const secondSchedule = buildPlaybackSchedule(processed.parsedScore);
      if (JSON.stringify(firstSchedule) !== JSON.stringify(secondSchedule)) {
        throw new Error(`${fixture.id} playback schedule was not stable`);
      }
      if (!processed.parsedScore.rawMusicXml.includes("<score-partwise")) {
        throw new Error(`${fixture.id} did not retain source MusicXML`);
      }
      void started;
      evaluations.push(evaluateParsedScore(fixture.id, processed.parsedScore, fixture.expected));
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      evaluations.push({
        id: fixture.id,
        passed: false,
        failures: [
          {
            category: "parse-error",
            expected: "a parsed score",
            actual: message,
            probableCause: "The fixture could not be read by the current pipeline.",
            responsibleFunction: "processFileToParsedScore",
          },
        ],
        pitchMatched: 0,
        pitchExpected: fixture.expected.events.length,
        pitchExtra: 0,
        playbackUnknownNotes: 0,
        noteCount: 0,
      });
    } finally {
      await fs.rm(directory, { recursive: true, force: true });
    }
  }
  const heapAfter = process.memoryUsage().heapUsed;

  let omr: OmrSummary | null = null;
  if (options.omr) {
    omr = await runOmrProbes(verified.filter((fixture) => fixture.omrProbe));
  }

  const summary = summarize(selected, evaluations, blocked, {
    scheduleMs,
    scheduleChecks,
    heapBefore,
    heapAfter,
    omr,
  });
  printSummary(summary);
  if (options.baselineOut) {
    await fs.mkdir(path.dirname(options.baselineOut), { recursive: true });
    await fs.writeFile(options.baselineOut, JSON.stringify(summary, null, 2), "utf8");
  }
  if (options.report) {
    const reportPath = path.join(process.cwd(), "reports", "recognition-report.md");
    await fs.mkdir(path.dirname(reportPath), { recursive: true });
    const baseline = await readJsonIfExists(path.join(process.cwd(), "reports", "recognition-baseline.json"));
    await fs.writeFile(reportPath, renderReport(summary, baseline), "utf8");
    console.log(`\nReport written to ${reportPath}`);
  }
  if (evaluations.some((evaluation) => !evaluation.passed)) {
    process.exitCode = 1;
  }
}

function parseArgs(argv: string[]): RunOptions {
  const sets = new Set<FixtureSet>(["development", "regression"]);
  let report = false;
  let omr = false;
  let baselineOut: string | null = null;
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--report") {
      report = true;
    } else if (arg === "--omr") {
      omr = true;
    } else if (arg === "--sets") {
      sets.clear();
      for (const value of (argv[index + 1] ?? "").split(",")) {
        if (value === "development" || value === "regression" || value === "heldout") {
          sets.add(value);
        }
      }
      index += 1;
    } else if (arg === "--baseline-out") {
      baselineOut = argv[index + 1] ?? null;
      index += 1;
    }
  }
  return { sets: [...sets], report, omr, baselineOut };
}

async function loadFixtures(): Promise<LoadedFixture[]> {
  const synthetic: LoadedFixture[] = SYNTHETIC_FIXTURES.map((spec) => {
    const realized = realizeFixture(spec);
    return {
      id: spec.id,
      title: spec.title,
      set: spec.set,
      origin: "synthetic",
      provenance: realized.provenance,
      xml: realized.xml,
      expected: realized.expected,
      verified: true,
      omrProbe: spec.omrProbe,
    };
  });
  const chorales = await loadChorales();
  return [...synthetic, ...chorales];
}

async function loadChorales(): Promise<LoadedFixture[]> {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), "rk-chorales-"));
  try {
    await execFileAsync("python3", [path.join(process.cwd(), "scripts/score-recognition/export_chorales.py"), directory], {
      timeout: 120_000,
      maxBuffer: 16 * 1024 * 1024,
    });
    const manifest = JSON.parse(await fs.readFile(path.join(directory, "manifest.json"), "utf8")) as Array<{
      id: string;
      title: string;
      set: FixtureSet;
      origin: "encoded-public-domain";
      verified: boolean;
      unverifiedReason?: string | null;
      xmlPath: string;
      expected: ExpectedScore;
      provenance: FixtureProvenance;
    }>;
    const loaded: LoadedFixture[] = [];
    for (const entry of manifest) {
      loaded.push({
        id: entry.id,
        title: entry.title,
        set: entry.set,
        origin: entry.origin,
        provenance: entry.provenance,
        xml: await fs.readFile(entry.xmlPath, "utf8"),
        expected: entry.expected,
        verified: entry.verified,
        unverifiedReason: entry.unverifiedReason,
      });
    }
    return loaded;
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return [
      blockedChorale("pd-bwv255", "regression", message),
      blockedChorale("pd-bwv101-7", "regression", message),
      blockedChorale("pd-bwv244-10", "heldout", message),
      blockedChorale("pd-bwv286", "heldout", message),
    ];
  } finally {
    await fs.rm(directory, { recursive: true, force: true });
  }
}

function blockedChorale(id: string, set: FixtureSet, reason: string): LoadedFixture {
  return {
    id,
    title: id,
    set,
    origin: "encoded-public-domain",
    provenance: {
      sourceUrl: "https://github.com/cuthbertLab/music21",
      originalAuthor: "Johann Sebastian Bach",
      license: "Public-domain work; music21 corpus encoding was not available.",
      sourceFormat: "music21 corpus",
      referenceFormat: "unavailable",
      downloadDate: null,
      conversionMethod: "not run",
      origin: "encoded-public-domain",
    },
    xml: "",
    expected: emptyExpected(),
    verified: false,
    unverifiedReason: reason,
  };
}

function emptyExpected(): ExpectedScore {
  return {
    voicing: "Unknown",
    logicalPartCount: 0,
    accompaniment: false,
    pianoEntranceMeasure: null,
    soloCount: 0,
    writtenMeasureCount: 0,
    timeSignatures: [],
    measureBeats: [],
    keyRegions: [],
    performanceRoute: [],
    entrances: [],
    events: [],
  };
}

interface OmrProbeResult {
  id: string;
  status: "compared" | "blocked";
  detail: string;
  voicing?: string;
  measures?: number;
  notes?: number;
}

interface OmrSummary {
  blocked: boolean;
  results: OmrProbeResult[];
}

async function runOmrProbes(fixtures: LoadedFixture[]): Promise<OmrSummary> {
  const bin = process.env.AUDIVERIS_BIN ?? "/opt/audiveris/bin/Audiveris";
  try {
    await fs.access(bin);
  } catch {
    return {
      blocked: true,
      results: fixtures.map((fixture) => ({
        id: fixture.id,
        status: "blocked",
        detail: `Audiveris binary not found at ${bin}`,
      })),
    };
  }
  const createVerovioModule = require("verovio/wasm").default;
  const { VerovioToolkit } = require("verovio/esm");
  const verovioModule = await createVerovioModule();
  const results: OmrProbeResult[] = [];
  for (const fixture of fixtures) {
    const directory = await fs.mkdtemp(path.join(os.tmpdir(), "rk-omr-"));
    try {
      const toolkit = new VerovioToolkit(verovioModule);
      toolkit.setOptions({
        pageWidth: 2200,
        pageHeight: 3000,
        scale: 55,
        adjustPageHeight: 1,
        header: "none",
        footer: "none",
      });
      if (!toolkit.loadData(fixture.xml)) {
        results.push({ id: fixture.id, status: "blocked", detail: "Verovio could not render the reference score." });
        continue;
      }
      const svg = toolkit.renderToSVG(1);
      const imagePath = path.join(directory, `${fixture.id}.jpg`);
      await sharp(Buffer.from(svg))
        .flatten({ background: "#ffffff" })
        .resize({ width: 1600 })
        .jpeg({ quality: 92 })
        .toFile(imagePath);
      const processed = await processFileToParsedScore({
        filePath: imagePath,
        originalFileName: `${fixture.id}.jpg`,
        mimeType: "image/jpeg",
        audiverisOutputDir: path.join(directory, "audiveris"),
      });
      const evaluation = evaluateParsedScore(fixture.id, processed.parsedScore, fixture.expected);
      const failed = evaluation.failures
        .map((failure) => `${failure.category}: expected ${failure.expected}; actual ${failure.actual}`)
        .join(" | ");
      results.push({
        id: fixture.id,
        status: "compared",
        detail: evaluation.passed
          ? "OMR output matched the reference on every scored category."
          : `OMR output differed. ${failed}`,
        voicing: processed.parsedScore.inferredVoicing ?? processed.parsedScore.parts.map((part) => part.canonicalPart).join("+"),
        measures: processed.parsedScore.measures.length,
        notes: processed.parsedScore.notes.length,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      results.push({ id: fixture.id, status: "blocked", detail: message.slice(0, 500) });
    } finally {
      await fs.rm(directory, { recursive: true, force: true });
    }
  }
  return { blocked: results.every((result) => result.status === "blocked"), results };
}

interface Summary {
  selected: number;
  verified: number;
  blocked: { id: string; set: string; reason: string }[];
  passed: number;
  failed: number;
  bySet: Record<string, { passed: number; failed: number; blocked: number }>;
  categories: Record<string, { passed: number; scored: number }>;
  pitchMatched: number;
  pitchExpected: number;
  unknownNotes: number;
  noteCount: number;
  scheduleMs: number;
  scheduleChecks: number;
  heapBefore: number;
  heapAfter: number;
  failures: Array<FixtureEvaluation & { set: string; title: string; origin: string }>;
  omr: OmrSummary | null;
  componentMap: string[];
}

function summarize(
  selected: LoadedFixture[],
  evaluations: FixtureEvaluation[],
  blocked: LoadedFixture[],
  extra: {
    scheduleMs: number;
    scheduleChecks: number;
    heapBefore: number;
    heapAfter: number;
    omr: OmrSummary | null;
  }
): Summary {
  const byId = new Map(selected.map((fixture) => [fixture.id, fixture]));
  const categories: FailureCategory[] = [
    "voicing",
    "accompaniment",
    "logical-parts",
    "entrance",
    "measures",
    "time-signature",
    "key",
    "pitch",
    "duration",
    "solo",
    "playback-channels",
    "performance-route",
  ];
  const categoryStats: Record<string, { passed: number; scored: number }> = {};
  for (const category of categories) {
    categoryStats[category] = { passed: 0, scored: evaluations.length };
  }
  for (const evaluation of evaluations) {
    const failedCategories = new Set(evaluation.failures.map((failure) => failure.category));
    for (const category of categories) {
      if (!failedCategories.has(category)) {
        categoryStats[category].passed += 1;
      }
    }
  }
  const bySet: Summary["bySet"] = {};
  for (const fixture of selected) {
    bySet[fixture.set] ??= { passed: 0, failed: 0, blocked: 0 };
    if (!fixture.verified) {
      bySet[fixture.set].blocked += 1;
    }
  }
  for (const evaluation of evaluations) {
    const fixture = byId.get(evaluation.id);
    if (!fixture) {
      continue;
    }
    if (evaluation.passed) {
      bySet[fixture.set].passed += 1;
    } else {
      bySet[fixture.set].failed += 1;
    }
  }
  return {
    selected: selected.length,
    verified: evaluations.length,
    blocked: blocked.map((fixture) => ({
      id: fixture.id,
      set: fixture.set,
      reason: fixture.unverifiedReason ?? "unverified",
    })),
    passed: evaluations.filter((evaluation) => evaluation.passed).length,
    failed: evaluations.filter((evaluation) => !evaluation.passed).length,
    bySet,
    categories: categoryStats,
    pitchMatched: evaluations.reduce((sum, evaluation) => sum + evaluation.pitchMatched, 0),
    pitchExpected: evaluations.reduce((sum, evaluation) => sum + evaluation.pitchExpected, 0),
    unknownNotes: evaluations.reduce((sum, evaluation) => sum + evaluation.playbackUnknownNotes, 0),
    noteCount: evaluations.reduce((sum, evaluation) => sum + evaluation.noteCount, 0),
    scheduleMs: extra.scheduleMs,
    scheduleChecks: extra.scheduleChecks,
    heapBefore: extra.heapBefore,
    heapAfter: extra.heapAfter,
    failures: evaluations
      .filter((evaluation) => !evaluation.passed)
      .map((evaluation) => {
        const fixture = byId.get(evaluation.id);
        return {
          ...evaluation,
          set: fixture?.set ?? "unknown",
          title: fixture?.title ?? evaluation.id,
          origin: fixture?.origin ?? "synthetic",
        };
      }),
    omr: extra.omr,
    componentMap: [
      "PDF / image ingestion: src/app/api/my-music/process/route.ts and src/app/api/score/recognize/route.ts",
      "Add Pages: src/app/api/my-music/[id]/replace-pages/route.ts",
      "Audiveris integration: src/lib/server/omr/audiveris-provider.ts (AudiverisOMRService)",
      "Pipeline entry: src/lib/server/score-processing.ts processFileToParsedScore",
      "MusicXML parser: src/lib/musicxml.ts parseMusicXmlToScore",
      "There is no separate ScoreStructureAnalyzer, GlobalVoicingDiscovery, StaffMapper, ChoirMapper, MeasureParser, KeySignatureParser, RepeatNavigator, or PlaybackModelBuilder module.",
      "Rehearsal playback: src/lib/score-player.ts ScorePlayer, fed by already-parsed note events",
      "Unnamed voices are assigned by register in src/lib/voicing.ts. A part is piano when its name says so, or when it is a treble-plus-bass grand staff. Repeats are listed in performanceRoute and are not copied into the written measure list.",
    ],
  };
}

function printSummary(summary: Summary) {
  console.log("\nREHEARSAL KEYS RECOGNITION TEST");
  console.log(`Scores selected: ${summary.selected}`);
  console.log(`Verified and scored: ${summary.verified}`);
  console.log(`Blocked / unverified (not counted as passes): ${summary.blocked.length}`);
  console.log(`Passed: ${summary.passed}/${summary.verified}`);
  console.log(`Failed: ${summary.failed}/${summary.verified}`);
  for (const [name, counts] of Object.entries(summary.categories)) {
    console.log(`${name}: ${counts.passed}/${counts.scored}`);
  }
  const pitchRate = summary.pitchExpected ? summary.pitchMatched / summary.pitchExpected : 0;
  console.log(
    `Pitch events matched: ${summary.pitchMatched}/${summary.pitchExpected} (${(pitchRate * 100).toFixed(1)}% of expected sounding events)`
  );
  console.log(`UNKNOWN-channel notes: ${summary.unknownNotes}/${summary.noteCount}`);
  console.log(
    `Playback schedule rebuilds: ${summary.scheduleChecks} scores x 200, ${summary.scheduleMs.toFixed(1)} ms, no MusicXML reparse`
  );
  console.log(
    `Heap used before/after sequential processing: ${mb(summary.heapBefore)} MB -> ${mb(summary.heapAfter)} MB`
  );
  if (summary.blocked.length) {
    console.log("\nBlocked:");
    for (const item of summary.blocked) {
      console.log(`- ${item.id} (${item.set}): ${item.reason.split("\n")[0]}`);
    }
  }
  if (summary.failures.length) {
    console.log("\nFailures:");
    for (const failure of summary.failures) {
      console.log(`- ${failure.id} [${failure.set}]`);
      for (const item of failure.failures) {
        console.log(`  ${item.category}: expected ${item.expected} | actual ${item.actual}`);
        console.log(`  probable cause: ${item.probableCause} (${item.responsibleFunction})`);
      }
    }
  }
}

function renderReport(summary: Summary, baseline: Summary | null): string {
  const lines: string[] = [];
  lines.push("# Rehearsal Keys recognition test");
  lines.push("");
  lines.push("Ground truth for synthetic scores comes from the musical plan that generates the MusicXML. It is not the parser output.");
  lines.push("Public-domain Bach chorales are read from the local music21 corpus at test time, cross-checked against the exported MusicXML, and are not stored in this repository.");
  lines.push("Held-out scores are included only in this report. They are not part of `npm run test:score-recognition`.");
  lines.push("");
  lines.push("## Component map");
  lines.push("");
  for (const item of summary.componentMap) {
    lines.push(`- ${item}`);
  }
  lines.push("");
  lines.push("## Results");
  lines.push("");
  lines.push(`Scores selected: ${summary.selected}`);
  lines.push("");
  lines.push(`Verified and scored: ${summary.verified}`);
  lines.push("");
  lines.push(`Passed: ${summary.passed}/${summary.verified}`);
  lines.push("");
  lines.push(`Failed: ${summary.failed}/${summary.verified}`);
  lines.push("");
  lines.push("Category counts are fixtures with no failure in that category. A fixture can fail more than one category. Pitch-event accuracy is a separate count of sounding notes.");
  lines.push("");
  lines.push("| Category | Correct fixtures |");
  lines.push("| --- | --- |");
  for (const [name, counts] of Object.entries(summary.categories)) {
    lines.push(`| ${name} | ${counts.passed}/${counts.scored} |`);
  }
  const pitchRate = summary.pitchExpected ? (summary.pitchMatched / summary.pitchExpected) * 100 : 0;
  lines.push("");
  lines.push(`Pitch/event matches: ${summary.pitchMatched}/${summary.pitchExpected} (${pitchRate.toFixed(1)}% of expected sounding events).`);
  lines.push("");
  lines.push(`Playback-channel notes left on UNKNOWN: ${summary.unknownNotes}/${summary.noteCount}.`);
  lines.push("");
  lines.push("## Sets");
  lines.push("");
  for (const [name, counts] of Object.entries(summary.bySet)) {
    lines.push(`- ${name}: passed ${counts.passed}, failed ${counts.failed}, blocked ${counts.blocked}`);
  }
  lines.push("");
  if (baseline) {
    lines.push("## Against the baseline");
    lines.push("");
    lines.push(
      `Before fixes: ${baseline.passed}/${baseline.verified} verified fixtures passed on the development and regression baseline.`
    );
    lines.push("");
    lines.push(
      `After fixes: ${summary.passed}/${summary.verified} verified fixtures passed in this run. This run's denominator includes every selected set, so it is larger than the baseline when the held-out set is included.`
    );
    lines.push("");
    const before = new Set(baseline.failures.map((failure) => failure.id));
    const after = new Set(summary.failures.map((failure) => failure.id));
    const resolved = [...before].filter((id) => !after.has(id));
    const added = [...after].filter((id) => !before.has(id));
    lines.push(`Resolved since baseline: ${resolved.length ? resolved.join(", ") : "none"}.`);
    lines.push("");
    lines.push(`New failures since baseline: ${added.length ? added.join(", ") : "none"}.`);
    lines.push("");
  }
  lines.push("## Critical failures");
  lines.push("");
  if (!summary.failures.length) {
    lines.push("None on the verified fixtures in this run.");
    lines.push("");
  }
  for (const failure of summary.failures) {
    lines.push(`### ${failure.id}`);
    lines.push("");
    lines.push(`Set: ${failure.set}. Origin: ${failure.origin}. ${failure.title}.`);
    lines.push("");
    for (const item of failure.failures) {
      lines.push(`- Category: ${item.category}`);
      lines.push(`- Expected: ${item.expected}`);
      lines.push(`- Actual: ${item.actual}`);
      lines.push(`- Probable cause: ${item.probableCause}`);
      lines.push(`- Responsible function: ${item.responsibleFunction}`);
      lines.push(`- Fix attempted: see the parser changes in this branch`);
      lines.push(`- Retest result: still failing`);
      lines.push("");
    }
  }
  lines.push("## Blocked");
  lines.push("");
  if (!summary.blocked.length) {
    lines.push("None.");
  }
  for (const item of summary.blocked) {
    lines.push(`- ${item.id} (${item.set}): ${item.reason.split("\n")[0]}`);
  }
  lines.push("");
  lines.push("## Performance");
  lines.push("");
  lines.push(`Playback schedules were rebuilt from parsed notes only (${summary.scheduleChecks} scores x 200) in ${summary.scheduleMs.toFixed(1)} ms. Pressing Play does not re-read MusicXML; ScorePlayer schedules the notes already on the parsed score.`);
  lines.push("");
  lines.push(`Sequential fixture processing heap: ${mb(summary.heapBefore)} MB -> ${mb(summary.heapAfter)} MB. Fixtures are parsed one at a time and temporary files are deleted.`);
  lines.push("");
  lines.push("Audiveris jobs in the app are already one score at a time in AudiverisOMRService.");
  lines.push("");
  if (summary.omr) {
    lines.push("## Printed-page OMR probes");
    lines.push("");
    lines.push("These render a synthetic score with Verovio and run the real Audiveris path in processFileToParsedScore. They are not counted in the fixture pass rate above. A missing key is left empty when the exported MusicXML has no key element.");
    lines.push("");
    for (const result of summary.omr.results) {
      lines.push(`- ${result.id}: ${result.status}. ${result.detail}. Voices: ${result.voicing ?? "n/a"}. Measures: ${result.measures ?? "n/a"}. Notes: ${result.notes ?? "n/a"}.`);
    }
    lines.push("");
  }
  return lines.join("\n");
}

async function readJsonIfExists(filePath: string): Promise<Summary | null> {
  try {
    return JSON.parse(await fs.readFile(filePath, "utf8")) as Summary;
  } catch {
    return null;
  }
}

function mb(bytes: number): string {
  return (bytes / (1024 * 1024)).toFixed(1);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
