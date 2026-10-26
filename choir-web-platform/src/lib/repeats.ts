export interface RepeatMeasure {
  number: number;
  repeatForward: boolean;
  repeatBackward: boolean;
  repeatTimes: number;
  ending: number | null;
}

/**
 * Performance order of written measure numbers.
 * When the score has no repeat signs, this is the written order once.
 * Written measure objects are not duplicated.
 */
export function buildPerformanceRoute(measures: RepeatMeasure[]): number[] {
  if (!measures.length) {
    return [];
  }
  const hasRepeat = measures.some(
    (measure) => measure.repeatBackward || measure.repeatForward || measure.ending != null
  );
  if (!hasRepeat) {
    return measures.map((measure) => measure.number);
  }

  const route: number[] = [];
  const plays = new Map<number, number>();
  let index = 0;
  let pass = 1;
  let guard = 0;
  while (index < measures.length && guard < 20000) {
    guard += 1;
    const bar = measures[index];
    if (bar.ending != null && bar.ending !== pass) {
      index += 1;
      continue;
    }
    route.push(bar.number);
    if (bar.repeatBackward) {
      const played = (plays.get(index) ?? 0) + 1;
      plays.set(index, played);
      if (played < bar.repeatTimes) {
        pass = played + 1;
        index = findRepeatStart(measures, index);
        continue;
      }
    }
    index += 1;
  }
  return route;
}

function findRepeatStart(measures: RepeatMeasure[], fromIndex: number): number {
  for (let index = fromIndex; index >= 0; index -= 1) {
    if (measures[index].repeatForward) {
      return index;
    }
  }
  return 0;
}
