import type { ParsedScore, RecognizedPart } from "@/lib/score-types";
import type { ExpectedEvent, ExpectedScore } from "./types";

export type FailureCategory =
  | "voicing"
  | "accompaniment"
  | "logical-parts"
  | "entrance"
  | "measures"
  | "time-signature"
  | "key"
  | "pitch"
  | "duration"
  | "solo"
  | "playback-channels"
  | "performance-route"
  | "parse-error";

export interface CategoryFailure {
  category: FailureCategory;
  expected: string;
  actual: string;
  probableCause: string;
  responsibleFunction: string;
}

export interface FixtureEvaluation {
  id: string;
  passed: boolean;
  failures: CategoryFailure[];
  pitchMatched: number;
  pitchExpected: number;
  pitchExtra: number;
  playbackUnknownNotes: number;
  noteCount: number;
}

const PLAYABLE = new Set(["SOPRANO", "ALTO", "TENOR", "BASS", "PIANO", "UNKNOWN"]);

export function evaluateParsedScore(id: string, score: ParsedScore, expected: ExpectedScore): FixtureEvaluation {
  const failures: CategoryFailure[] = [];
  const actualVoicing = voicingOf(score);
  if (actualVoicing !== expected.voicing) {
    failures.push(
      fail(
        "voicing",
        expected.voicing,
        actualVoicing,
        "Choir voices were mapped onto the wrong section labels.",
        "assignChoirRegisters / inferChoirVoicing"
      )
    );
  }

  const pianoParts = score.parts.filter((part) => part.canonicalPart === "PIANO");
  const hasPiano = pianoParts.some((part) =>
    score.notes.some((note) => note.partId === part.id)
  );
  if (hasPiano !== expected.accompaniment) {
    failures.push(
      fail(
        "accompaniment",
        expected.accompaniment ? "piano present" : "no piano",
        hasPiano ? "piano present" : "no piano",
        "A multi-staff part was classified from staff count instead of clefs and name.",
        "partLooksLikePiano"
      )
    );
  }
  if (expected.pianoEntranceMeasure != null) {
    const entrance = earliest(pianoParts);
    if (entrance !== expected.pianoEntranceMeasure) {
      failures.push(
        fail(
          "entrance",
          `piano measure ${expected.pianoEntranceMeasure}`,
          `piano measure ${entrance ?? "none"}`,
          "Accompaniment notes were dropped or shifted.",
          "readPartTimeline"
        )
      );
    }
  }

  const logical = score.parts.filter((part) => part.canonicalPart !== "PIANO");
  if (logical.length !== expected.logicalPartCount) {
    failures.push(
      fail(
        "logical-parts",
        String(expected.logicalPartCount),
        String(logical.length),
        "Shared staves were collapsed, or a vocal staff was treated as piano.",
        "detectStreams / partLooksLikePiano"
      )
    );
  }

  const soloCount = score.parts.filter(
    (part) => part.isSolo || /\b(solo|descant)\b/i.test(part.sourceName)
  ).length;
  if (soloCount !== expected.soloCount) {
    failures.push(
      fail(
        "solo",
        String(expected.soloCount),
        String(soloCount),
        "A solo or descant part was dropped or merged into the choir.",
        "detectCanonicalPart"
      )
    );
  }

  if (score.measures.length !== expected.writtenMeasureCount) {
    failures.push(
      fail(
        "measures",
        `${expected.writtenMeasureCount} written measures`,
        `${score.measures.length} measure objects`,
        "Measure objects were created from the wrong part or expanded.",
        "readPartTimeline"
      )
    );
  } else {
    const beatMismatches: string[] = [];
    expected.measureBeats.forEach((beats, index) => {
      const actual = score.measures[index]?.beatsInMeasure;
      if (actual == null || Math.abs(actual - beats) > 0.05) {
        beatMismatches.push(`m${index + 1} expected ${beats} actual ${actual ?? "missing"}`);
      }
    });
    if (beatMismatches.length) {
      failures.push(
        fail(
          "measures",
          expected.measureBeats.join(","),
          beatMismatches.slice(0, 4).join("; "),
          "Measure length followed a summed multi-voice cursor or ignored a pickup.",
          "readPartTimeline"
        )
      );
    }
  }

  const actualTimes = score.measures.map((measure) => measure.timeSignature);
  if (actualTimes.join("|") !== expected.timeSignatures.join("|")) {
    failures.push(
      fail(
        "time-signature",
        expected.timeSignatures.join(", "),
        actualTimes.join(", ") || "none",
        "Time-signature regions were not read from measure attributes.",
        "readPartTimeline"
      )
    );
  }

  const actualKeys = keyLabel(score);
  const expectedKeys = expected.keyRegions.map((region) => `${region.startMeasure}:${region.label}`).join(", ");
  if (actualKeys !== expectedKeys) {
    failures.push(
      fail(
        "key",
        expectedKeys,
        actualKeys || "none",
        "Only the first signature was kept, or minor mode was ignored.",
        "readKeyRegions"
      )
    );
  }

  const actualRoute = (score.performanceRoute ?? score.measures.map((measure) => measure.displayNumber)).join(",");
  const expectedRoute = expected.performanceRoute.join(",");
  if (actualRoute !== expectedRoute) {
    failures.push(
      fail(
        "performance-route",
        expectedRoute,
        actualRoute,
        "Repeat barlines were not turned into a performance route, or written measures were duplicated.",
        "buildPerformanceRoute"
      )
    );
  }

  for (const entrance of expected.entrances) {
    const part = score.parts.find((candidate) => candidate.id === entrance.partId);
    const actual = part?.firstMeasureNumber ?? null;
    if (actual !== entrance.measure) {
      failures.push(
        fail(
          "entrance",
          `${entrance.partId} measure ${entrance.measure}`,
          part ? `${entrance.partId} measure ${actual ?? "none"}` : `${entrance.partId} missing`,
          "Rests, cues, or a shifted voice cursor moved the first sounding note.",
          "readPartTimeline / populatePartRanges"
        )
      );
    }
  }

  const actualEvents: ExpectedEvent[] = score.notes.map((note) => ({
    partId: note.partId,
    startBeat: note.startBeat,
    midi: note.midi,
    duration: note.durationBeats,
  }));
  const pitch = matchEvents(expected.events, actualEvents);
  if (pitch.missing || pitch.extra || pitch.pitchMismatch || pitch.durationMismatch) {
    const category: FailureCategory =
      pitch.pitchMismatch > 0 && pitch.durationMismatch === 0 && pitch.missing === 0
        ? "pitch"
        : pitch.durationMismatch > 0 && pitch.pitchMismatch === 0 && pitch.missing === 0
          ? "duration"
          : pitch.pitchMismatch > 0
            ? "pitch"
            : pitch.durationMismatch > 0
              ? "duration"
              : "pitch";
    failures.push(
      fail(
        category,
        `${expected.events.length} events`,
        `matched ${pitch.matched}, missing ${pitch.missing}, extra ${pitch.extra}, pitch ${pitch.pitchMismatch}, duration ${pitch.durationMismatch}. ${pitch.sample}`,
        category === "duration"
          ? "Tied notes were stored as separate short events."
          : "Written pitch was not transposed for the clef, or voice timing shifted.",
        category === "duration" ? "mergeTiedNotes" : "pitchToMidi / readPartTimeline"
      )
    );
  }

  const unknownNotes = score.notes.filter((note) => note.partCanonical === "UNKNOWN").length;
  if (unknownNotes > 0) {
    failures.push(
      fail(
        "playback-channels",
        "0 notes on UNKNOWN",
        `${unknownNotes} notes on UNKNOWN`,
        "A voice was left without a playback channel.",
        "assignChoirRegisters"
      )
    );
  }
  const unplayable = score.notes.filter((note) => !PLAYABLE.has(note.partCanonical)).length;
  if (unplayable > 0) {
    failures.push(
      fail(
        "playback-channels",
        "every note on a known channel",
        `${unplayable} notes on an unknown channel`,
        "Playback model dropped a canonical part.",
        "ScorePlayer"
      )
    );
  }

  return {
    id,
    passed: failures.length === 0,
    failures,
    pitchMatched: pitch.matched,
    pitchExpected: expected.events.length,
    pitchExtra: pitch.extra,
    playbackUnknownNotes: unknownNotes,
    noteCount: score.notes.length,
  };
}

export function buildPlaybackSchedule(score: ParsedScore) {
  return score.notes.map((note) => ({
    partCanonical: note.partCanonical,
    midi: note.midi,
    startBeat: roundBeat(note.startBeat),
    durationBeats: roundBeat(note.durationBeats),
  }));
}

function voicingOf(score: ParsedScore): string {
  if (score.inferredVoicing) {
    return score.inferredVoicing;
  }
  const vocal = new Set(
    score.parts
      .filter((part) => part.canonicalPart !== "PIANO" && part.canonicalPart !== "UNKNOWN")
      .map((part) => part.canonicalPart)
  );
  if (!vocal.size) {
    return score.parts.some((part) => part.canonicalPart === "PIANO") ? "Piano" : "Unknown";
  }
  const order = ["SOPRANO", "ALTO", "TENOR", "BASS"] as const;
  const initials: Record<string, string> = { SOPRANO: "S", ALTO: "A", TENOR: "T", BASS: "B" };
  return order.filter((part) => vocal.has(part)).map((part) => initials[part]).join("");
}

function keyLabel(score: ParsedScore): string {
  if (score.keyRegions?.length) {
    return score.keyRegions.map((region) => `${region.startMeasure}:${region.label}`).join(", ");
  }
  if (!score.keySignature) {
    return "";
  }
  const start = score.measures[0]?.displayNumber ?? 1;
  return `${start}:${score.keySignature}`;
}

function earliest(parts: RecognizedPart[]): number | null {
  const values = parts
    .map((part) => part.firstMeasureNumber)
    .filter((value): value is number => value != null);
  if (!values.length) {
    return null;
  }
  return Math.min(...values);
}

function matchEvents(expected: ExpectedEvent[], actual: ExpectedEvent[]) {
  const used = new Set<number>();
  let matched = 0;
  let pitchMismatch = 0;
  let durationMismatch = 0;
  let missing = 0;
  let sample = "";
  for (const event of expected) {
    const exact = find(actual, used, (candidate) => samePlace(event, candidate) && candidate.midi === event.midi && close(candidate.duration, event.duration));
    if (exact >= 0) {
      used.add(exact);
      matched += 1;
      continue;
    }
    const samePitch = find(actual, used, (candidate) => samePlace(event, candidate) && candidate.midi === event.midi);
    if (samePitch >= 0) {
      used.add(samePitch);
      durationMismatch += 1;
      if (!sample) {
        sample = `${event.partId} beat ${event.startBeat} duration ${event.duration} vs ${actual[samePitch].duration}`;
      }
      continue;
    }
    const sameTime = find(actual, used, (candidate) => samePlace(event, candidate));
    if (sameTime >= 0) {
      used.add(sameTime);
      pitchMismatch += 1;
      if (!sample) {
        sample = `${event.partId} beat ${event.startBeat} midi ${event.midi} vs ${actual[sameTime].midi}`;
      }
      continue;
    }
    missing += 1;
    if (!sample) {
      sample = `missing ${event.partId} beat ${event.startBeat} midi ${event.midi}`;
    }
  }
  return {
    matched,
    missing,
    extra: actual.length - used.size,
    pitchMismatch,
    durationMismatch,
    sample,
  };
}

function find(events: ExpectedEvent[], used: Set<number>, predicate: (event: ExpectedEvent) => boolean): number {
  for (let index = 0; index < events.length; index += 1) {
    if (used.has(index)) {
      continue;
    }
    if (predicate(events[index])) {
      return index;
    }
  }
  return -1;
}

function samePlace(expected: ExpectedEvent, actual: ExpectedEvent): boolean {
  return expected.partId === actual.partId && close(expected.startBeat, actual.startBeat);
}

function close(left: number, right: number): boolean {
  return Math.abs(left - right) <= 0.05;
}

function roundBeat(value: number): number {
  return Math.round(value * 1000) / 1000;
}

function fail(
  category: FailureCategory,
  expected: string,
  actual: string,
  probableCause: string,
  responsibleFunction: string
): CategoryFailure {
  return { category, expected, actual, probableCause, responsibleFunction };
}
