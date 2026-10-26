import type { MeasureInfo, NoteEvent, ParsedScore } from "@/lib/score-types";
import type {
  NavigationEvent,
  PlaybackChannel,
  PlaybackEvent,
  PlaybackModel,
  PlaybackVisit,
  ScoreModel,
} from "@/lib/score-model";

export interface RouteMeasure {
  number: number;
  repeatForward: boolean;
  repeatBackward: boolean;
  repeatTimes: number;
  ending: number | null;
}

/**
 * The only performance-route expander.
 * Written measures stay as they are. This returns the visit order.
 */
export function buildPlaybackRoute(
  measures: RouteMeasure[],
  navigation: NavigationEvent[]
): { route: number[]; warnings: string[] } {
  if (!measures.length) {
    return { route: [], warnings: [] };
  }
  const hasRepeat = measures.some(
    (measure) => measure.repeatBackward || measure.repeatForward || measure.ending != null
  );
  const hasJump = navigation.some((event) =>
    ["SEGNO", "CODA", "DS", "DC", "TO_CODA", "FINE"].includes(event.kind)
  );
  if (!hasRepeat && !hasJump) {
    return { route: measures.map((measure) => measure.number), warnings: [] };
  }

  const route: number[] = [];
  const warnings: string[] = [];
  const plays = new Map<number, number>();
  let index = 0;
  let pass = 1;
  let guard = 0;
  let dalSegnoTaken = false;
  let daCapoTaken = false;
  let codaArmed = false;
  let fineArmed = false;

  while (index < measures.length && guard < 20000) {
    guard += 1;
    const bar = measures[index];
    if (bar.ending != null && bar.ending !== pass) {
      index += 1;
      continue;
    }
    route.push(bar.number);
    const marks = navigation.filter((event) => event.measureIndex === index);

    if (fineArmed && marks.some((event) => event.kind === "FINE")) {
      break;
    }
    if (codaArmed && marks.some((event) => event.kind === "TO_CODA")) {
      const coda = navigation.find((event) => event.kind === "CODA");
      if (!coda) {
        warnings.push("To Coda was found without a Coda sign.");
        break;
      }
      codaArmed = false;
      index = coda.measureIndex;
      continue;
    }

    if (bar.repeatBackward) {
      const played = (plays.get(index) ?? 0) + 1;
      plays.set(index, played);
      if (played < bar.repeatTimes) {
        pass = played + 1;
        index = findRepeatStart(measures, index);
        continue;
      }
    }

    const dalSegno = marks.find((event) => event.kind === "DS");
    if (dalSegno && !dalSegnoTaken) {
      dalSegnoTaken = true;
      codaArmed = Boolean(dalSegno.alCoda);
      fineArmed = Boolean(dalSegno.alFine);
      const segno = navigation.find((event) => event.kind === "SEGNO");
      if (!segno) {
        warnings.push("D.S. was found without a Segno.");
        break;
      }
      pass = 1;
      index = segno.measureIndex;
      continue;
    }

    const daCapo = marks.find((event) => event.kind === "DC");
    if (daCapo && !daCapoTaken) {
      daCapoTaken = true;
      codaArmed = Boolean(daCapo.alCoda);
      fineArmed = Boolean(daCapo.alFine);
      pass = 1;
      index = 0;
      continue;
    }

    index += 1;
  }

  if (guard >= 20000) {
    warnings.push("Playback route stopped because the navigation instructions did not resolve.");
  }
  return { route, warnings };
}

export function performanceVisits(measures: MeasureInfo[], route: number[]): PlaybackVisit[] {
  const buckets = new Map<number, MeasureInfo[]>();
  for (const measure of measures) {
    const list = buckets.get(measure.displayNumber) ?? [];
    list.push(measure);
    buckets.set(measure.displayNumber, list);
  }
  const visits: PlaybackVisit[] = [];
  const cursor = new Map<number, number>();
  let beat = 0;
  for (const number of route) {
    const list = buckets.get(number) ?? [];
    const index = cursor.get(number) ?? 0;
    cursor.set(number, index + 1);
    const measure = list[Math.min(index, Math.max(0, list.length - 1))];
    if (!measure) {
      continue;
    }
    const length = measure.beatsInMeasure;
    visits.push({
      displayNumber: number,
      internalIndex: measure.internalIndex,
      startBeat: beat,
      endBeat: beat + length,
      writtenStart: measure.startBeat,
    });
    beat += length;
  }
  return visits;
}

export function buildPlaybackModel(
  score: ParsedScore,
  model: Pick<
    ScoreModel,
    "logicalParts" | "extraPlayableParts" | "accompaniment" | "navigationEvents" | "writtenMeasures"
  >,
  repeats: RouteMeasure[]
): { playback: PlaybackModel; warnings: string[] } {
  const { route, warnings } = buildPlaybackRoute(repeats, model.navigationEvents);
  const visits = performanceVisits(score.measures, route);
  const events = expandEvents(score.notes, score.measures, visits);
  const channels = buildChannels(score, model);
  const eventCountByChannel: Record<string, number> = {};
  for (const channel of channels) {
    eventCountByChannel[channel.id] = events.filter((event) => channel.partIds.includes(event.partId)).length;
  }
  return { playback: { channels, route, visits, events, eventCountByChannel }, warnings };
}

export function routeWarnings(repeats: RouteMeasure[], navigation: NavigationEvent[]): string[] {
  return buildPlaybackRoute(repeats, navigation).warnings;
}

export function repeatsFromScore(score: ParsedScore): RouteMeasure[] {
  return score.measures.map((measure, index) => {
    const events = score.scoreModel?.navigationEvents.filter((event) => event.measureIndex === index) ?? [];
    const ending = events.find((event) => event.kind === "ENDING");
    const repeatEnd = events.find((event) => event.kind === "REPEAT_END");
    return {
      number: measure.displayNumber,
      repeatForward: events.some((event) => event.kind === "REPEAT_START"),
      repeatBackward: Boolean(repeatEnd),
      repeatTimes: repeatEnd?.times ?? 2,
      ending: ending?.ending ?? null,
    };
  });
}

export function refreshPlayback(score: ParsedScore) {
  if (!score.scoreModel) {
    return;
  }
  for (const logical of [...score.scoreModel.logicalParts, ...score.scoreModel.extraPlayableParts]) {
    const part = score.parts.find((candidate) => candidate.id === logical.id);
    if (part) {
      logical.canonicalPart = part.canonicalPart;
      logical.needsConfirmation = part.needsConfirmation;
    }
  }
  const built = buildPlaybackModel(score, score.scoreModel, repeatsFromScore(score));
  score.scoreModel.playback = built.playback;
  score.performanceRoute = built.playback.route;
}

function expandEvents(notes: NoteEvent[], measures: MeasureInfo[], visits: PlaybackVisit[]): PlaybackEvent[] {
  const byIndex = new Map(measures.map((measure) => [measure.internalIndex, measure]));
  const events: PlaybackEvent[] = [];
  for (const visit of visits) {
    const measure = byIndex.get(visit.internalIndex);
    if (!measure) {
      continue;
    }
    for (const note of notes) {
      if (note.measureNumber !== measure.displayNumber) {
        continue;
      }
      if (note.startBeat < measure.startBeat - 0.001 || note.startBeat >= measure.endBeat - 0.001) {
        continue;
      }
      events.push({
        partId: note.partId,
        partCanonical: note.partCanonical,
        midi: note.midi,
        scheduleBeat: visit.startBeat + (note.startBeat - measure.startBeat),
        durationBeats: note.durationBeats,
        measureNumber: note.measureNumber,
        velocity: note.velocity,
        unisonGroupId: note.unisonGroupId ?? null,
      });
    }
  }
  events.sort((a, b) => a.scheduleBeat - b.scheduleBeat || a.midi - b.midi);
  return events;
}

function buildChannels(
  score: ParsedScore,
  model: Pick<ScoreModel, "logicalParts" | "extraPlayableParts" | "accompaniment">
): PlaybackChannel[] {
  const channels: PlaybackChannel[] = [];
  const roleCount = new Map<string, number>();
  for (const part of model.logicalParts) {
    roleCount.set(part.canonicalPart, (roleCount.get(part.canonicalPart) ?? 0) + 1);
  }
  const roleSeen = new Map<string, number>();
  for (const part of model.logicalParts) {
    const seen = (roleSeen.get(part.canonicalPart) ?? 0) + 1;
    roleSeen.set(part.canonicalPart, seen);
    const total = roleCount.get(part.canonicalPart) ?? 1;
    const roleName = labelForCanonical(part.canonicalPart);
    const label =
      part.canonicalPart === "UNKNOWN"
        ? part.label
        : total > 1
          ? `${roleName} ${seen}`
          : roleName;
    channels.push({
      id: part.id,
      label,
      group: "CHOIR",
      partIds: [part.id],
      canonicalPart: part.canonicalPart,
      entersAtMeasure: entranceOf(score, part.id),
    });
  }
  for (const part of model.extraPlayableParts) {
    channels.push({
      id: part.id,
      label: part.label,
      group: "FEATURED",
      partIds: [part.id],
      canonicalPart: part.canonicalPart,
      entersAtMeasure: entranceOf(score, part.id),
    });
  }
  for (const partId of model.accompaniment.partIds) {
    const part = score.parts.find((candidate) => candidate.id === partId);
    channels.push({
      id: partId,
      label: part?.sourceName || "Piano",
      group: "ACCOMPANIMENT",
      partIds: [partId],
      canonicalPart: "PIANO",
      entersAtMeasure: entranceOf(score, partId),
    });
  }
  return channels;
}

function entranceOf(score: ParsedScore, partId: string): number | null {
  return score.parts.find((part) => part.id === partId)?.firstMeasureNumber ?? null;
}

function labelForCanonical(part: string): string {
  if (part === "SOPRANO") return "Soprano";
  if (part === "ALTO") return "Alto";
  if (part === "TENOR") return "Tenor";
  if (part === "BASS") return "Bass";
  if (part === "PIANO") return "Piano";
  return "Voice";
}

function findRepeatStart(measures: RouteMeasure[], fromIndex: number): number {
  for (let index = fromIndex; index >= 0; index -= 1) {
    if (measures[index].repeatForward) {
      return index;
    }
  }
  return 0;
}
