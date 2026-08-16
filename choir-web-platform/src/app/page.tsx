"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { parseMusicXmlToScore } from "@/lib/musicxml";
import { ScorePlayer, type PlaybackSnapshot } from "@/lib/score-player";
import type { CanonicalPartId, OMRDiagnostics, ParsedScore } from "@/lib/score-types";

const PART_BUTTONS: CanonicalPartId[] = [
  "SOPRANO",
  "ALTO",
  "TENOR",
  "BASS",
  "PIANO",
];

const initialSnapshot: PlaybackSnapshot = {
  isPlaying: false,
  currentBeat: 0,
  currentMeasure: 1,
  tempoPercent: 100,
  loopStartMeasure: null,
  loopEndMeasure: null,
};

export default function Home() {
  const [score, setScore] = useState<ParsedScore | null>(null);
  const [diagnostics, setDiagnostics] = useState<OMRDiagnostics | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isBusy, setIsBusy] = useState(false);
  const [snapshot, setSnapshot] = useState<PlaybackSnapshot>(initialSnapshot);
  const [selectedParts, setSelectedParts] = useState<Set<CanonicalPartId>>(new Set(PART_BUTTONS));
  const [gotoMeasure, setGotoMeasure] = useState("1");
  const [loopStartMeasure, setLoopStartMeasure] = useState("1");
  const [loopEndMeasure, setLoopEndMeasure] = useState("2");
  const [pendingFile, setPendingFile] = useState<File | null>(null);
  const uploadInputRef = useRef<HTMLInputElement>(null);
  const playerRef = useRef<ScorePlayer | null>(null);

  useEffect(() => {
    if (!score) {
      return;
    }
    const player = new ScorePlayer(score);
    playerRef.current?.dispose();
    playerRef.current = player;
    const unsub = player.onUpdate((next) => setSnapshot(next));
    return () => {
      unsub();
      player.dispose();
      if (playerRef.current === player) {
        playerRef.current = null;
      }
    };
  }, [score]);

  useEffect(() => {
    playerRef.current?.setEnabledCanonicalParts(selectedParts);
  }, [selectedParts]);

  const measureNumbers = useMemo(
    () => score?.measures.map((measure) => measure.displayNumber) ?? [],
    [score]
  );

  const runRecognition = useCallback(async () => {
    if (!pendingFile) {
      return;
    }
    const file = pendingFile;
    setPendingFile(null);
    setError(null);
    setIsBusy(true);
    try {
      const formData = new FormData();
      formData.append("file", file);
      const response = await fetch("/api/score/recognize", {
        method: "POST",
        body: formData,
      });
      const body = (await response.json()) as {
        musicXml?: string;
        diagnostics?: OMRDiagnostics;
        message?: string;
      };
      if (!response.ok || !body.musicXml) {
        throw new Error(body.message ?? "Recognition failed.");
      }
      const parsed = parseMusicXmlToScore(body.musicXml, "omr");
      setSelectedParts(defaultSelectedPartsFromScore(parsed));
      setScore(parsed);
      setDiagnostics(body.diagnostics ?? null);
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : "Unknown recognition error.";
      setError(message);
    } finally {
      setIsBusy(false);
    }
  }, [pendingFile]);

  const availableCanonicalParts = useMemo(() => {
    if (!score) {
      return new Set<CanonicalPartId>(PART_BUTTONS);
    }
    const set = new Set<CanonicalPartId>();
    for (const part of score.parts) {
      set.add(part.canonicalPart);
    }
    return set;
  }, [score]);

  const handleTogglePart = (part: CanonicalPartId) => {
    if (!availableCanonicalParts.has(part)) {
      return;
    }
    setSelectedParts((prev) => {
      const next = new Set(prev);
      if (next.has(part)) {
        next.delete(part);
      } else {
        next.add(part);
      }
      return next;
    });
  };

  const handleSetAllParts = () => {
    const next = new Set<CanonicalPartId>();
    for (const part of availableCanonicalParts) {
      next.add(part);
    }
    setSelectedParts(next);
  };

  const gotoSelectedMeasure = () => {
    const measure = Number(gotoMeasure);
    if (!Number.isFinite(measure)) {
      return;
    }
    playerRef.current?.seekToMeasure(measure);
  };

  const setLoopRange = () => {
    const start = Number(loopStartMeasure);
    const end = Number(loopEndMeasure);
    if (!Number.isFinite(start) || !Number.isFinite(end)) {
      return;
    }
    playerRef.current?.setLoopRange(start, end);
  };

  const voiceDetections = score?.parts ?? [];
  const quality = diagnostics?.quality;
  const status = isBusy
    ? "PROCESSING MUSIC..."
    : score
      ? "READY TO REHEARSE"
      : "UPLOAD SCORE";

  return (
    <div className="min-h-screen bg-[#16181d] text-zinc-100">
      <main className="mx-auto flex w-full max-w-5xl flex-col gap-5 px-4 py-6 sm:px-8">
        <header className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
          <p className="text-xs tracking-[0.16em] text-zinc-300">MILESTONE 1</p>
          <h1 className="mt-1 text-2xl font-semibold tracking-wide">FILE UPLOAD → OMR → PLAYBACK</h1>
          <p className="mt-2 text-zinc-300">{status}</p>
        </header>

        <section className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
          <h2 className="text-lg font-semibold">Upload</h2>
          <div className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2">
            <ControlButton
              label="UPLOAD SCORE"
              accent
              onClick={() => uploadInputRef.current?.click()}
              disabled={isBusy}
            />
            <ControlButton
              label="PROCESS MUSIC"
              onClick={() => void runRecognition()}
              disabled={isBusy || !pendingFile}
            />
          </div>
          <input
            ref={uploadInputRef}
            className="hidden"
            type="file"
            accept=".jpg,.jpeg,.png,.pdf"
            onChange={(event) => {
              const file = event.target.files?.[0] ?? null;
              setPendingFile(file);
              setError(null);
              event.currentTarget.value = "";
            }}
          />
          <p className="mt-3 text-sm text-zinc-300">
            {pendingFile ? pendingFile.name : "[no file selected]"}
          </p>
          {isBusy ? <p className="mt-3 text-sm text-cyan-300">PROCESSING MUSIC...</p> : null}
          {error ? <p className="mt-3 text-sm text-rose-300">{error}</p> : null}
          {diagnostics ? (
            <div className="mt-3 rounded-xl border border-zinc-600 bg-zinc-900/45 p-3 text-sm">
              <p className="font-medium">
                Photo Quality: {diagnostics.lowConfidence ? "Low Confidence" : "Good"}
              </p>
              {quality ? (
                <p className="mt-1 text-zinc-300">
                  Blur {Math.round(quality.blurScore * 100)}% • Contrast{" "}
                  {Math.round(quality.contrastScore * 100)}% • Glare{" "}
                  {Math.round(quality.glareScore * 100)}%
                </p>
              ) : null}
            </div>
          ) : null}
        </section>

        <section className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
          <h2 className="text-lg font-semibold">Playback</h2>
          <p className="mt-1 text-sm text-zinc-300">
            m.{snapshot.currentMeasure} • {snapshot.tempoPercent}% •{" "}
            {snapshot.isPlaying ? "Playing" : "Paused"}
          </p>

          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            <ControlButton
              label={snapshot.isPlaying ? "PAUSE" : "PLAY"}
              accent
              onClick={() => playerRef.current?.togglePlayPause()}
              disabled={!score}
            />
            <ControlButton
              label="TEMPO -"
              onClick={() => playerRef.current?.adjustTempoPercent(-5)}
              disabled={!score}
            />
            <ControlButton
              label="TEMPO +"
              onClick={() => playerRef.current?.adjustTempoPercent(5)}
              disabled={!score}
            />
          </div>

          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            <input
              className="rounded-xl border border-zinc-600 bg-zinc-900 px-3 py-3"
              placeholder="GO TO MEASURE"
              value={gotoMeasure}
              onChange={(event) => setGotoMeasure(event.target.value)}
            />
            <ControlButton label="GO TO MEASURE" onClick={gotoSelectedMeasure} disabled={!score} />
          </div>

          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            <input
              className="rounded-xl border border-zinc-600 bg-zinc-900 px-3 py-3"
              placeholder="LOOP START"
              value={loopStartMeasure}
              onChange={(event) => setLoopStartMeasure(event.target.value)}
            />
            <input
              className="rounded-xl border border-zinc-600 bg-zinc-900 px-3 py-3"
              placeholder="LOOP END"
              value={loopEndMeasure}
              onChange={(event) => setLoopEndMeasure(event.target.value)}
            />
            <ControlButton label="START LOOP" onClick={setLoopRange} disabled={!score} />
            <ControlButton
              label="STOP LOOP"
              onClick={() => playerRef.current?.clearLoop()}
              disabled={!score}
            />
          </div>
        </section>

        <section className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
          <h2 className="text-lg font-semibold">PARTS</h2>
          <div className="mt-3 grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-6">
            <ControlButton label="ALL" onClick={handleSetAllParts} disabled={!score} />
            {PART_BUTTONS.map((part) => {
              const selected = selectedParts.has(part);
              const disabled = !availableCanonicalParts.has(part);
              return (
                <button
                  key={part}
                  type="button"
                  className={`rounded-xl px-3 py-3 text-sm font-semibold ${
                    selected
                      ? "bg-cyan-400 text-black"
                      : disabled
                        ? "bg-zinc-800 text-zinc-500"
                        : "bg-zinc-700 text-zinc-100"
                  }`}
                  onClick={() => handleTogglePart(part)}
                  disabled={disabled}
                >
                  {part}
                </button>
              );
            })}
          </div>
        </section>

        <section className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
          <h2 className="text-lg font-semibold">Detected Parts</h2>
          <div className="mt-3 space-y-2 text-sm">
            {voiceDetections.length ? (
              voiceDetections.map((part) => (
                <div key={part.id} className="flex items-center justify-between rounded-xl bg-zinc-800 p-2">
                  <span>{part.sourceName}</span>
                  <span className="rounded-full bg-zinc-700 px-3 py-1 text-xs">
                    {part.canonicalPart}
                  </span>
                </div>
              ))
            ) : (
              <p className="text-zinc-400">No score loaded.</p>
            )}
          </div>
          <p className="mt-3 text-sm text-zinc-300">Measures detected: {measureNumbers.length}</p>
        </section>
      </main>
    </div>
  );
}

function defaultSelectedPartsFromScore(parsed: ParsedScore) {
  const next = new Set<CanonicalPartId>();
  for (const part of parsed.parts) {
    if (part.canonicalPart !== "UNKNOWN") {
      next.add(part.canonicalPart);
    }
  }
  if (!next.size) {
    next.add("PIANO");
  }
  return next;
}

function ControlButton(props: {
  label: string;
  onClick: () => void;
  disabled?: boolean;
  accent?: boolean;
}) {
  return (
    <button
      type="button"
      className={`rounded-xl px-4 py-4 text-base font-semibold ${
        props.accent ? "bg-cyan-400 text-black" : "bg-zinc-700 text-zinc-100"
      } disabled:cursor-not-allowed disabled:bg-zinc-800 disabled:text-zinc-500`}
      onClick={props.onClick}
      disabled={props.disabled}
    >
      {props.label}
    </button>
  );
}
