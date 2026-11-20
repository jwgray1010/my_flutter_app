export const TEMPO_MIN_PERCENT = 50;
export const TEMPO_MAX_PERCENT = 150;
export const TEMPO_PERCENT_STEP = 5;
export const LEGACY_TEMPO_MAX_PERCENT = 120;

export interface TempoPoint {
  startBeat: number;
  bpm: number;
}

export function clampTempoPercent(value: number, expandedRange: boolean) {
  const max = expandedRange ? TEMPO_MAX_PERCENT : LEGACY_TEMPO_MAX_PERCENT;
  const rounded = expandedRange
    ? Math.round(value / TEMPO_PERCENT_STEP) * TEMPO_PERCENT_STEP
    : Math.round(value);
  if (!Number.isFinite(rounded)) {
    return 100;
  }
  return Math.max(TEMPO_MIN_PERCENT, Math.min(max, rounded));
}

export function effectiveBpm(printedBpm: number, percent: number) {
  return printedBpm * (percent / 100);
}

export function percentForTargetBpm(printedBpm: number, targetBpm: number) {
  if (!Number.isFinite(printedBpm) || printedBpm <= 0 || !Number.isFinite(targetBpm)) {
    return 100;
  }
  return clampTempoPercent((targetBpm / printedBpm) * 100, true);
}

export function formatBpm(bpm: number) {
  if (!Number.isFinite(bpm)) {
    return "—";
  }
  const rounded = Math.round(bpm * 100) / 100;
  return Number.isInteger(rounded) ? String(rounded) : rounded.toFixed(2).replace(/0+$/, "").replace(/\.$/, "");
}

export function tempoAt(points: TempoPoint[], beat: number, fallbackBpm: number) {
  let bpm = fallbackBpm;
  for (const point of points) {
    if (point.startBeat <= beat + 1e-6) {
      bpm = point.bpm;
    } else {
      break;
    }
  }
  return bpm;
}

/** Seconds from one written beat to another, scaling the whole tempo map. */
export function secondsBetween(
  fromBeat: number,
  toBeat: number,
  points: TempoPoint[],
  fallbackBpm: number,
  percent: number
): number {
  if (toBeat < fromBeat) {
    return -secondsBetween(toBeat, fromBeat, points, fallbackBpm, percent);
  }
  let beat = fromBeat;
  let seconds = 0;
  let guard = 0;
  while (beat < toBeat - 1e-8 && guard < 1000) {
    guard += 1;
    const bpm = Math.max(1, tempoAt(points, beat, fallbackBpm) * (percent / 100));
    const next = nextTempoBeat(points, beat);
    const segmentEnd = Math.min(toBeat, next ?? toBeat);
    seconds += ((segmentEnd - beat) * 60) / bpm;
    beat = segmentEnd;
  }
  return seconds;
}

export function beatsAfterSeconds(
  startBeat: number,
  seconds: number,
  points: TempoPoint[],
  fallbackBpm: number,
  percent: number
) {
  if (seconds < 0) {
    return beatsBeforeSeconds(startBeat, -seconds, points, fallbackBpm, percent);
  }
  let beat = startBeat;
  let remaining = seconds;
  let guard = 0;
  while (remaining > 1e-8 && guard < 1000) {
    guard += 1;
    const bpm = Math.max(1, tempoAt(points, beat, fallbackBpm) * (percent / 100));
    const secondsPerBeat = 60 / bpm;
    const next = nextTempoBeat(points, beat);
    if (next == null) {
      return beat + remaining / secondsPerBeat;
    }
    const segmentSeconds = (next - beat) * secondsPerBeat;
    if (remaining <= segmentSeconds + 1e-8) {
      return beat + remaining / secondsPerBeat;
    }
    remaining -= segmentSeconds;
    beat = next;
  }
  return beat;
}

function beatsBeforeSeconds(
  startBeat: number,
  seconds: number,
  points: TempoPoint[],
  fallbackBpm: number,
  percent: number
) {
  let beat = startBeat;
  let remaining = seconds;
  let guard = 0;
  while (remaining > 1e-8 && beat > 1e-8 && guard < 1000) {
    guard += 1;
    const previous = previousTempoBeat(points, beat);
    const segmentStart = previous ?? 0;
    const bpm = Math.max(1, tempoAt(points, Math.max(0, beat - 1e-6), fallbackBpm) * (percent / 100));
    const secondsPerBeat = 60 / bpm;
    const segmentBeats = beat - segmentStart;
    const segmentSeconds = segmentBeats * secondsPerBeat;
    if (previous == null || remaining <= segmentSeconds + 1e-8) {
      return beat - remaining / secondsPerBeat;
    }
    remaining -= segmentSeconds;
    beat = segmentStart;
  }
  return beat;
}

function nextTempoBeat(points: TempoPoint[], beat: number) {
  for (const point of points) {
    if (point.startBeat > beat + 1e-6) {
      return point.startBeat;
    }
  }
  return null;
}

function previousTempoBeat(points: TempoPoint[], beat: number) {
  let previous: number | null = null;
  for (const point of points) {
    if (point.startBeat < beat - 1e-6) {
      previous = point.startBeat;
    }
  }
  return previous;
}
