import * as Tone from "tone";
import type { CanonicalPartId, ParsedScore } from "@/lib/score-types";

export interface PlaybackSnapshot {
  isPlaying: boolean;
  currentBeat: number;
  currentMeasure: number;
  tempoPercent: number;
  loopStartMeasure: number | null;
  loopEndMeasure: number | null;
}

export class ScorePlayer {
  private readonly score: ParsedScore;

  private readonly orderedNotes: ParsedScore["notes"];

  private readonly enabledParts = new Set<CanonicalPartId>([
    "SOPRANO",
    "ALTO",
    "TENOR",
    "BASS",
    "PIANO",
  ]);

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

  private initialized = false;
  private isPlaying = false;
  private currentBeat = 0;
  private playStartBeat = 0;
  private playStartTimeSec = 0;
  private tempoPercent = 100;
  private nextEventIndex = 0;
  private loopStartMeasure: number | null = null;
  private loopEndMeasure: number | null = null;

  constructor(score: ParsedScore) {
    this.score = score;
    this.orderedNotes = [...score.notes].sort((a, b) => a.startBeat - b.startBeat);
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
      currentBeat: this.currentBeat,
      currentMeasure: this.measureAtBeat(this.currentBeat),
      tempoPercent: this.tempoPercent,
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

  setEnabledCanonicalParts(parts: Iterable<CanonicalPartId>) {
    this.enabledParts.clear();
    for (const part of parts) {
      this.enabledParts.add(part);
    }
  }

  seekToMeasure(measureNumber: number) {
    const target = this.score.measures.find(
      (measure) => measure.displayNumber === measureNumber
    );
    if (!target) {
      return;
    }
    this.currentBeat = target.startBeat;
    this.playStartBeat = this.currentBeat;
    this.playStartTimeSec = Tone.now();
    this.nextEventIndex = this.findNextNoteIndex(this.currentBeat);
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
    this.playStartBeat = this.currentBeat;
    this.playStartTimeSec = Tone.now();
    this.nextEventIndex = this.findNextNoteIndex(this.currentBeat);
    this.startTicker();
    this.emitSnapshot();
  }

  pause() {
    if (!this.isPlaying) {
      return;
    }
    this.currentBeat = this.nowBeat();
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
    const firstByPart = new Map<CanonicalPartId, number>();
    for (const note of this.orderedNotes) {
      if (!this.enabledParts.has(note.partCanonical)) {
        continue;
      }
      if (!firstByPart.has(note.partCanonical)) {
        firstByPart.set(note.partCanonical, note.midi);
      }
    }
    let offset = 0;
    for (const [part, midi] of firstByPart) {
      this.synthFor(part).triggerAttackRelease(
        Tone.Frequency(midi, "midi").toFrequency(),
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
    const currentBeat = this.nowBeat();
    this.currentBeat = currentBeat;

    const loopRange = this.loopBeatRange();
    if (loopRange && currentBeat >= loopRange.endBeat) {
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
      this.nextEventIndex < this.orderedNotes.length &&
      this.orderedNotes[this.nextEventIndex].startBeat <= beatWindowEnd
    ) {
      const note = this.orderedNotes[this.nextEventIndex];
      this.nextEventIndex += 1;
      if (!this.enabledParts.has(note.partCanonical)) {
        continue;
      }
      const offsetBeats = note.startBeat - currentBeat;
      const when = now + Math.max(0, offsetBeats * this.secondsPerBeat());
      const durSec = Math.max(0.04, note.durationBeats * this.secondsPerBeat());
      this.synthFor(note.partCanonical).triggerAttackRelease(
        Tone.Frequency(note.midi, "midi").toFrequency(),
        durSec,
        when,
        note.velocity
      );
    }

    const scoreEnd = this.score.measures[this.score.measures.length - 1];
    if (scoreEnd && this.currentBeat >= scoreEnd.endBeat) {
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
    let high = this.orderedNotes.length;
    while (low < high) {
      const mid = Math.floor((low + high) / 2);
      if (this.orderedNotes[mid].startBeat < beat) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  private measureAtBeat(beat: number) {
    for (const measure of this.score.measures) {
      if (beat >= measure.startBeat && beat < measure.endBeat) {
        return measure.displayNumber;
      }
    }
    return this.score.measures[this.score.measures.length - 1]?.displayNumber ?? 1;
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
}

