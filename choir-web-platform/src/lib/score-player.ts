import * as Tone from "tone";
import type { PlaybackVisit } from "@/lib/score-model";
import type { CanonicalPartId, ParsedScore } from "@/lib/score-types";

export interface PlaybackSnapshot {
  isPlaying: boolean;
  isCountingIn: boolean;
  currentBeat: number;
  currentMeasure: number;
  tempoPercent: number;
  countInMeasures: 0 | 1 | 2;
  loopStartMeasure: number | null;
  loopEndMeasure: number | null;
}

export class ScorePlayer {
  private readonly score: ParsedScore;

  private readonly schedule: ScheduledNote[];

  private readonly visits: PlaybackVisit[] | null;

  private readonly enabledParts = new Set<CanonicalPartId>([
    "SOPRANO",
    "ALTO",
    "TENOR",
    "BASS",
    "PIANO",
    "UNKNOWN",
  ]);

  private enabledPartIds: Set<string> | null = null;

  private readonly soundedUnison = new Set<string>();

  private readonly synths: Record<CanonicalPartId, Tone.PolySynth<Tone.Synth>> = {
    SOPRANO: new Tone.PolySynth(Tone.Synth, {
      oscillator: { type: "triangle" },
      envelope: { attack: 0.01, release: 0.25 },
      volume: -8,
    }).toDestination(),
    ALTO: new Tone.PolySynth(Tone.Synth, {
      oscillator: { type: "triangle" },
      envelope: { attack: 0.01, release: 0.25 },
      volume: -8,
    }).toDestination(),
    TENOR: new Tone.PolySynth(Tone.Synth, {
      oscillator: { type: "triangle" },
      envelope: { attack: 0.01, release: 0.25 },
      volume: -8,
    }).toDestination(),
    BASS: new Tone.PolySynth(Tone.Synth, {
      oscillator: { type: "triangle" },
      envelope: { attack: 0.01, release: 0.3 },
      volume: -8,
    }).toDestination(),
    PIANO: new Tone.PolySynth(Tone.Synth, {
      oscillator: { type: "sine" },
      envelope: { attack: 0.005, release: 0.45 },
      volume: -4,
    }).toDestination(),
    UNKNOWN: new Tone.PolySynth(Tone.Synth, {
      oscillator: { type: "triangle" },
      envelope: { attack: 0.01, release: 0.25 },
      volume: -8,
    }).toDestination(),
  };

  private readonly listeners = new Set<(snapshot: PlaybackSnapshot) => void>();
  private ticker: ReturnType<typeof setInterval> | null = null;
  private countInTimer: ReturnType<typeof setTimeout> | null = null;

  private initialized = false;
  private isPlaying = false;
  private isCountingIn = false;
  private currentBeat = 0;
  private playStartBeat = 0;
  private playStartTimeSec = 0;
  private tempoPercent = 100;
  private countInMeasures: 0 | 1 | 2 = 1;
  private nextEventIndex = 0;
  private loopStartMeasure: number | null = null;
  private loopEndMeasure: number | null = null;
  private countInBeatsPerMeasure = 4;
  private countInClickIntervalBeats = 1;
  private remainingCountInBeats = 0;

  constructor(score: ParsedScore) {
    this.score = score;
    const playback = score.scoreModel?.playback;
    if (playback) {
      this.visits = playback.visits;
      this.schedule = playback.events.map((event) => ({
        partId: event.partId,
        partCanonical: event.partCanonical,
        midi: event.midi,
        scheduleBeat: event.scheduleBeat,
        durationBeats: event.durationBeats,
        velocity: event.velocity,
        unisonGroupId: event.unisonGroupId,
      }));
    } else {
      this.visits = null;
      this.schedule = [...score.notes]
        .sort((a, b) => a.startBeat - b.startBeat)
        .map((note) => ({
          partId: note.partId,
          partCanonical: note.partCanonical,
          midi: note.midi,
          scheduleBeat: note.startBeat,
          durationBeats: note.durationBeats,
          velocity: note.velocity,
          unisonGroupId: note.unisonGroupId ?? null,
        }));
    }
  }

  async initialize() {
    if (this.initialized) {
      return;
    }
    await Tone.start();
    this.initialized = true;
    this.emitSnapshot();
  }

  dispose() {
    this.pause();
    for (const synth of Object.values(this.synths)) {
      synth.dispose();
    }
    this.listeners.clear();
  }

  onUpdate(listener: (snapshot: PlaybackSnapshot) => void) {
    this.listeners.add(listener);
    listener(this.snapshot());
    return () => {
      this.listeners.delete(listener);
    };
  }

  snapshot(): PlaybackSnapshot {
    return {
      isPlaying: this.isPlaying,
      isCountingIn: this.isCountingIn,
      currentBeat: this.currentBeat,
      currentMeasure: this.measureAtBeat(this.currentBeat),
      tempoPercent: this.tempoPercent,
      countInMeasures: this.countInMeasures,
      loopStartMeasure: this.loopStartMeasure,
      loopEndMeasure: this.loopEndMeasure,
    };
  }

  setTempoPercent(value: number) {
    const clamped = Math.max(50, Math.min(120, Math.round(value)));
    if (this.tempoPercent === clamped) {
      return;
    }
    if (this.isPlaying) {
      const nowBeat = this.nowBeat();
      this.playStartBeat = nowBeat;
      this.playStartTimeSec = Tone.now();
      this.currentBeat = nowBeat;
    }
    this.tempoPercent = clamped;
    this.emitSnapshot();
  }

  adjustTempoPercent(delta: number) {
    this.setTempoPercent(this.tempoPercent + delta);
  }

  setCountInMeasures(value: 0 | 1 | 2) {
    this.countInMeasures = value;
    this.emitSnapshot();
  }

  setEnabledCanonicalParts(parts: Iterable<CanonicalPartId>) {
    this.enabledPartIds = null;
    this.enabledParts.clear();
    for (const part of parts) {
      this.enabledParts.add(part);
    }
  }

  setEnabledPartIds(partIds: Iterable<string> | null) {
    this.enabledPartIds = partIds ? new Set(partIds) : null;
  }

  seekToMeasure(measureNumber: number) {
    const visit = this.visits?.find((candidate) => candidate.displayNumber === measureNumber);
    const target = this.score.measures.find(
      (measure) => measure.displayNumber === measureNumber
    );
    if (!visit && !target) {
      return;
    }
    this.soundedUnison.clear();
    this.currentBeat = visit?.startBeat ?? target?.startBeat ?? 0;
    this.playStartBeat = this.currentBeat;
    this.playStartTimeSec = Tone.now();
    this.nextEventIndex = this.findNextNoteIndex(this.currentBeat);
    if (this.isPlaying && this.isCountingIn) {
      this.clearCountInTimer();
      this.beginCountIn();
    }
    this.emitSnapshot();
  }

  jumpRelativeMeasures(delta: number) {
    const currentMeasure = this.measureAtBeat(this.currentBeat);
    const available = this.score.measures.map((measure) => measure.displayNumber);
    if (!available.length) {
      return;
    }
    const currentIndex = available.indexOf(currentMeasure);
    const fallbackIndex = currentIndex >= 0 ? currentIndex : 0;
    const nextIndex = Math.max(0, Math.min(available.length - 1, fallbackIndex + delta));
    this.seekToMeasure(available[nextIndex]);
  }

  setLoopRange(startMeasure: number, endMeasure: number) {
    const a = Math.min(startMeasure, endMeasure);
    const b = Math.max(startMeasure, endMeasure);
    const start = this.score.measures.find((measure) => measure.displayNumber === a);
    const end = this.score.measures.find((measure) => measure.displayNumber === b);
    if (!start || !end) {
      return;
    }
    this.loopStartMeasure = start.displayNumber;
    this.loopEndMeasure = end.displayNumber;
    this.emitSnapshot();
  }

  clearLoop() {
    this.loopStartMeasure = null;
    this.loopEndMeasure = null;
    this.emitSnapshot();
  }

  async play() {
    if (this.isPlaying) {
      return;
    }
    await this.initialize();
    this.isPlaying = true;
    this.nextEventIndex = this.findNextNoteIndex(this.currentBeat);
    if (this.countInMeasures > 0) {
      this.beginCountIn();
    } else {
      this.beginPlaybackNow();
    }
    this.startTicker();
    this.emitSnapshot();
  }

  pause() {
    if (!this.isPlaying) {
      return;
    }
    if (this.isCountingIn) {
      this.clearCountInTimer();
      this.isCountingIn = false;
      this.remainingCountInBeats = 0;
    } else {
      this.currentBeat = this.nowBeat();
    }
    this.isPlaying = false;
    if (this.ticker) {
      clearInterval(this.ticker);
      this.ticker = null;
    }
    Tone.getTransport().cancel();
    this.emitSnapshot();
  }

  togglePlayPause() {
    if (this.isPlaying) {
      this.pause();
      return;
    }
    void this.play();
  }

  playStartingPitches() {
    const firstByPart = new Map<string, { canonical: CanonicalPartId; midi: number }>();
    for (const note of this.schedule) {
      if (!this.noteEnabled(note, false)) {
        continue;
      }
      const key = this.enabledPartIds ? note.partId : note.partCanonical;
      if (!firstByPart.has(key)) {
        firstByPart.set(key, { canonical: note.partCanonical, midi: note.midi });
      }
    }
    let offset = 0;
    for (const entry of firstByPart.values()) {
      this.synthFor(entry.canonical).triggerAttackRelease(
        Tone.Frequency(entry.midi, "midi").toFrequency(),
        0.7,
        Tone.now() + offset,
        0.85
      );
      offset += 0.15;
    }
  }

  private nowBeat() {
    if (!this.isPlaying) {
      return this.currentBeat;
    }
    if (this.isCountingIn) {
      return this.currentBeat;
    }
    const elapsedSec = Tone.now() - this.playStartTimeSec;
    return this.playStartBeat + elapsedSec / this.secondsPerBeat();
  }

  private secondsPerBeat() {
    const effectiveBpm = this.score.suggestedTempoBpm * (this.tempoPercent / 100);
    return 60 / Math.max(1, effectiveBpm);
  }

  private startTicker() {
    if (this.ticker) {
      clearInterval(this.ticker);
    }
    this.ticker = setInterval(() => this.tick(), 40);
  }

  private tick() {
    if (!this.isPlaying) {
      return;
    }
    if (this.isCountingIn) {
      this.emitSnapshot();
      return;
    }
    const currentBeat = this.nowBeat();
    this.currentBeat = currentBeat;

    const loopRange = this.loopBeatRange();
    if (loopRange && currentBeat >= loopRange.endBeat) {
      this.soundedUnison.clear();
      this.currentBeat = loopRange.startBeat;
      this.playStartBeat = loopRange.startBeat;
      this.playStartTimeSec = Tone.now();
      this.nextEventIndex = this.findNextNoteIndex(loopRange.startBeat);
      this.emitSnapshot();
      return;
    }

    const lookaheadSec = 0.2;
    const lookaheadBeats = lookaheadSec / this.secondsPerBeat();
    const beatWindowEnd = currentBeat + lookaheadBeats;
    const now = Tone.now();

    while (
      this.nextEventIndex < this.schedule.length &&
      this.schedule[this.nextEventIndex].scheduleBeat <= beatWindowEnd
    ) {
      const note = this.schedule[this.nextEventIndex];
      this.nextEventIndex += 1;
      if (!this.noteEnabled(note, true)) {
        continue;
      }
      const offsetBeats = note.scheduleBeat - currentBeat;
      const when = now + Math.max(0, offsetBeats * this.secondsPerBeat());
      const durSec = Math.max(0.04, note.durationBeats * this.secondsPerBeat());
      this.synthFor(note.partCanonical).triggerAttackRelease(
        Tone.Frequency(note.midi, "midi").toFrequency(),
        durSec,
        when,
        note.velocity
      );
    }

    const scoreEndBeat = this.visits?.length
      ? this.visits[this.visits.length - 1].endBeat
      : this.score.measures[this.score.measures.length - 1]?.endBeat;
    if (scoreEndBeat != null && this.currentBeat >= scoreEndBeat) {
      this.pause();
      this.seekToMeasure(this.score.measures[0]?.displayNumber ?? 1);
      return;
    }
    this.emitSnapshot();
  }

  private loopBeatRange() {
    if (this.loopStartMeasure == null || this.loopEndMeasure == null) {
      return null;
    }
    if (this.visits?.length) {
      const selected = this.visits.filter(
        (visit) =>
          visit.displayNumber >= (this.loopStartMeasure ?? 0) &&
          visit.displayNumber <= (this.loopEndMeasure ?? 0)
      );
      if (!selected.length) {
        return null;
      }
      return {
        startBeat: Math.min(...selected.map((visit) => visit.startBeat)),
        endBeat: Math.max(...selected.map((visit) => visit.endBeat)),
      };
    }
    const start = this.score.measures.find(
      (measure) => measure.displayNumber === this.loopStartMeasure
    );
    const end = this.score.measures.find(
      (measure) => measure.displayNumber === this.loopEndMeasure
    );
    if (!start || !end) {
      return null;
    }
    return {
      startBeat: start.startBeat,
      endBeat: end.endBeat,
    };
  }

  private findNextNoteIndex(beat: number) {
    let low = 0;
    let high = this.schedule.length;
    while (low < high) {
      const mid = Math.floor((low + high) / 2);
      if (this.schedule[mid].scheduleBeat < beat) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  private measureAtBeat(beat: number) {
    if (this.visits?.length) {
      for (const visit of this.visits) {
        if (beat >= visit.startBeat && beat < visit.endBeat) {
          return visit.displayNumber;
        }
      }
      return this.visits[this.visits.length - 1]?.displayNumber ?? 1;
    }
    for (const measure of this.score.measures) {
      if (beat >= measure.startBeat && beat < measure.endBeat) {
        return measure.displayNumber;
      }
    }
    return this.score.measures[this.score.measures.length - 1]?.displayNumber ?? 1;
  }

  private noteEnabled(note: ScheduledNote, markUnison: boolean) {
    if (this.enabledPartIds) {
      if (!this.enabledPartIds.has(note.partId)) {
        return false;
      }
    } else if (!this.enabledParts.has(note.partCanonical)) {
      return false;
    }
    if (!note.unisonGroupId) {
      return true;
    }
    const key = `${note.unisonGroupId}|${note.scheduleBeat}|${note.midi}`;
    if (this.soundedUnison.has(key)) {
      return false;
    }
    if (markUnison) {
      this.soundedUnison.add(key);
    }
    return true;
  }

  private synthFor(part: CanonicalPartId) {
    return this.synths[part] ?? this.synths.UNKNOWN;
  }

  private emitSnapshot() {
    const snap = this.snapshot();
    for (const listener of this.listeners) {
      listener(snap);
    }
  }

  private beginPlaybackNow() {
    this.soundedUnison.clear();
    this.playStartBeat = this.currentBeat;
    this.playStartTimeSec = Tone.now();
  }

  private beginCountIn() {
    const currentMeasure = this.score.measures.find(
      (measure) => measure.displayNumber === this.measureAtBeat(this.currentBeat)
    );
    const beatsInMeasure = Math.max(0.25, currentMeasure?.beatsInMeasure ?? 4);
    const numerator = Math.max(
      1,
      Math.round(Number(currentMeasure?.timeSignature?.split("/")[0])) || 4
    );
    this.countInBeatsPerMeasure = numerator;
    this.countInClickIntervalBeats = beatsInMeasure / numerator;
    this.remainingCountInBeats = this.countInMeasures * numerator;
    this.isCountingIn = this.remainingCountInBeats > 0;
    if (!this.isCountingIn) {
      this.beginPlaybackNow();
      return;
    }
    this.runNextCountInBeat(0);
  }

  private runNextCountInBeat(delayMs: number) {
    this.clearCountInTimer();
    this.countInTimer = setTimeout(() => {
      if (!this.isPlaying || !this.isCountingIn) {
        return;
      }
      if (this.remainingCountInBeats <= 0) {
        this.isCountingIn = false;
        this.beginPlaybackNow();
        this.emitSnapshot();
        return;
      }

      const beatOffsetInMeasure = this.remainingCountInBeats % this.countInBeatsPerMeasure;
      const isDownbeat = beatOffsetInMeasure === 0;
      this.playCountInClick(isDownbeat);
      this.remainingCountInBeats -= 1;
      this.emitSnapshot();
      this.runNextCountInBeat(this.countInClickIntervalBeats * this.secondsPerBeat() * 1000);
    }, Math.max(0, delayMs));
  }

  private playCountInClick(isDownbeat: boolean) {
    const frequency = isDownbeat ? 1320 : 880;
    const volume = isDownbeat ? 0.9 : 0.76;
    this.synths.UNKNOWN.triggerAttackRelease(frequency, 0.08, Tone.now(), volume);
  }

  private clearCountInTimer() {
    if (this.countInTimer) {
      clearTimeout(this.countInTimer);
      this.countInTimer = null;
    }
  }
}

interface ScheduledNote {
  partId: string;
  partCanonical: CanonicalPartId;
  midi: number;
  scheduleBeat: number;
  durationBeats: number;
  velocity: number;
  unisonGroupId: string | null;
}

