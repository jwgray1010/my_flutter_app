"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { parseMusicXmlToScore } from "@/lib/musicxml";
import { ScorePlayer, type PlaybackSnapshot } from "@/lib/score-player";
import type { CanonicalPartId, OMRDiagnostics, ParsedScore } from "@/lib/score-types";

type SavedPiece = {
  id: string;
  title: string;
  savedAt: string;
  rawMusicXml: string;
  sourceType: "musicxml" | "omr";
};

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
  const [status, setStatus] = useState("Load a score to begin.");
  const [error, setError] = useState<string | null>(null);
  const [isBusy, setIsBusy] = useState(false);
  const [snapshot, setSnapshot] = useState<PlaybackSnapshot>(initialSnapshot);
  const [selectedParts, setSelectedParts] = useState<Set<CanonicalPartId>>(new Set(PART_BUTTONS));
  const [gotoMeasure, setGotoMeasure] = useState("");
  const [loopStart, setLoopStart] = useState("");
  const [loopEnd, setLoopEnd] = useState("");
  const [savedPieces, setSavedPieces] = useState<SavedPiece[]>([]);
  const cameraInputRef = useRef<HTMLInputElement>(null);
  const uploadInputRef = useRef<HTMLInputElement>(null);
  const playerRef = useRef<ScorePlayer | null>(null);

  useEffect(() => {
    const raw = localStorage.getItem("choir-my-music-v1");
    if (!raw) {
      return;
    }
    try {
      const parsed = JSON.parse(raw) as SavedPiece[];
      setSavedPieces(parsed);
    } catch {
      localStorage.removeItem("choir-my-music-v1");
    }
  }, []);

  useEffect(() => {
    if (!score) {
      return;
    }
    const player = new ScorePlayer(score);
    playerRef.current?.dispose();
    playerRef.current = player;
    const unsub = player.onUpdate((next) => setSnapshot(next));
    setSnapshot(player.snapshot());
    setStatus(`READY TO REHEARSE • ${score.title}`);
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

  const persistPiece = useCallback((parsed: ParsedScore) => {
    const newPiece: SavedPiece = {
      id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
      title: parsed.title,
      rawMusicXml: parsed.rawMusicXml,
      sourceType: parsed.sourceType,
      savedAt: new Date().toISOString(),
    };
    setSavedPieces((prev) => {
      const next = [newPiece, ...prev].slice(0, 25);
      localStorage.setItem("choir-my-music-v1", JSON.stringify(next));
      return next;
    });
  }, []);

  const runRecognition = useCallback(
    async (file: File) => {
      setError(null);
      setIsBusy(true);
      try {
        const extension = file.name.toLowerCase().split(".").pop();
        if (extension === "xml" || extension === "musicxml") {
          const xml = await file.text();
          const parsed = parseMusicXmlToScore(xml, "musicxml");
          setScore(parsed);
          setDiagnostics(null);
          persistPiece(parsed);
          return;
        }

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
        setScore(parsed);
        setDiagnostics(body.diagnostics ?? null);
        persistPiece(parsed);
      } catch (caught) {
        const message = caught instanceof Error ? caught.message : "Unknown recognition error.";
        setError(message);
      } finally {
        setIsBusy(false);
      }
    },
    [persistPiece]
  );

  const loadPiece = (piece: SavedPiece) => {
    try {
      const parsed = parseMusicXmlToScore(piece.rawMusicXml, piece.sourceType);
      setScore(parsed);
      setDiagnostics(null);
      setError(null);
      setStatus(`Loaded from MY MUSIC • ${piece.title}`);
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : "Could not load saved score.";
      setError(message);
    }
  };

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

  const setLoop = () => {
    const start = Number(loopStart);
    const end = Number(loopEnd);
    if (!Number.isFinite(start) || !Number.isFinite(end)) {
      return;
    }
    playerRef.current?.setLoopRange(start, end);
  };

  const voiceDetections = score?.parts ?? [];
  const quality = diagnostics?.quality;

  useEffect(() => {
    if (!score) {
      return;
    }
    const next = new Set<CanonicalPartId>();
    for (const part of score.parts) {
      if (part.canonicalPart !== "UNKNOWN") {
        next.add(part.canonicalPart);
      }
    }
    if (!next.size) {
      next.add("PIANO");
    }
    setSelectedParts(next);
  }, [score]);

  return (
    <div className="min-h-screen bg-[#16181d] text-zinc-100">
      <main className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-4 py-6 sm:px-8">
        <header className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
          <p className="text-xs tracking-[0.16em] text-zinc-300">CHOIR REHEARSAL PLATFORM</p>
          <h1 className="mt-1 text-2xl font-semibold tracking-wide">Phase 1: Scan → Recognize → Play</h1>
          <p className="mt-2 text-zinc-300">{status}</p>
        </header>

        <section className="grid gap-4 md:grid-cols-2">
          <div className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
            <h2 className="text-lg font-semibold">Score Input</h2>
            <div className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2">
              <button
                type="button"
                className="rounded-2xl bg-cyan-400 px-5 py-4 text-lg font-semibold text-black"
                onClick={() => cameraInputRef.current?.click()}
                disabled={isBusy}
              >
                SCAN MUSIC
              </button>
              <button
                type="button"
                className="rounded-2xl bg-zinc-700 px-5 py-4 text-lg font-semibold"
                onClick={() => uploadInputRef.current?.click()}
                disabled={isBusy}
              >
                UPLOAD SCORE
              </button>
            </div>
            <input
              ref={cameraInputRef}
              className="hidden"
              type="file"
              accept="image/png,image/jpeg,image/jpg,image/webp"
              capture="environment"
              onChange={(event) => {
                const file = event.target.files?.[0];
                if (file) {
                  void runRecognition(file);
                }
                event.currentTarget.value = "";
              }}
            />
            <input
              ref={uploadInputRef}
              className="hidden"
              type="file"
              accept=".jpg,.jpeg,.png,.webp,.pdf,.xml,.musicxml"
              onChange={(event) => {
                const file = event.target.files?.[0];
                if (file) {
                  void runRecognition(file);
                }
                event.currentTarget.value = "";
              }}
            />
            {isBusy ? <p className="mt-3 text-sm text-cyan-300">Recognizing score...</p> : null}
            {error ? <p className="mt-3 text-sm text-rose-300">{error}</p> : null}
            {diagnostics ? (
              <div className="mt-4 rounded-2xl border border-zinc-600 bg-zinc-900/45 p-3 text-sm">
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
                {diagnostics.warnings.length ? (
                  <ul className="mt-2 list-disc space-y-1 pl-5 text-zinc-300">
                    {diagnostics.warnings.map((warning) => (
                      <li key={warning}>{warning}</li>
                    ))}
                  </ul>
                ) : null}
              </div>
            ) : null}
          </div>

          <div className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
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
            <h3 className="mt-5 text-sm font-semibold tracking-wide text-zinc-300">MY MUSIC</h3>
            <div className="mt-2 max-h-40 space-y-2 overflow-auto pr-1">
              {savedPieces.length ? (
                savedPieces.map((piece) => (
                  <button
                    key={piece.id}
                    type="button"
                    className="w-full rounded-xl bg-zinc-800 p-2 text-left hover:bg-zinc-700"
                    onClick={() => loadPiece(piece)}
                  >
                    <p className="text-sm font-medium">{piece.title}</p>
                    <p className="text-xs text-zinc-400">
                      {new Date(piece.savedAt).toLocaleString()} • {piece.sourceType}
                    </p>
                  </button>
                ))
              ) : (
                <p className="text-sm text-zinc-400">Saved scores will appear here.</p>
              )}
            </div>
          </div>
        </section>

        <section className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
          <h2 className="text-lg font-semibold">Rehearsal Remote</h2>
          <p className="mt-1 text-sm text-zinc-300">
            m.{snapshot.currentMeasure} • {snapshot.tempoPercent}% •{" "}
            {snapshot.isPlaying ? "Playing" : "Paused"}
          </p>

          <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            <ControlButton
              label={snapshot.isPlaying ? "PAUSE" : "PLAY"}
              accent
              onClick={() => playerRef.current?.togglePlayPause()}
              disabled={!score}
            />
            <ControlButton
              label="BACK 2"
              onClick={() => playerRef.current?.jumpRelativeMeasures(-2)}
              disabled={!score}
            />
            <ControlButton
              label="FORWARD 2"
              onClick={() => playerRef.current?.jumpRelativeMeasures(2)}
              disabled={!score}
            />
            <ControlButton
              label="STARTING PITCHES"
              onClick={() => playerRef.current?.playStartingPitches()}
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
            <ControlButton label="SET LOOP" onClick={setLoop} disabled={!score} />
            <ControlButton
              label="STOP LOOP"
              onClick={() => playerRef.current?.clearLoop()}
              disabled={!score}
            />
          </div>

          <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
            <input
              className="rounded-xl border border-zinc-600 bg-zinc-900 px-3 py-3"
              placeholder="GO TO MEASURE"
              value={gotoMeasure}
              onChange={(event) => setGotoMeasure(event.target.value)}
            />
            <ControlButton label="GO" onClick={gotoSelectedMeasure} disabled={!score} />
            <input
              className="rounded-xl border border-zinc-600 bg-zinc-900 px-3 py-3"
              placeholder="LOOP START"
              value={loopStart}
              onChange={(event) => setLoopStart(event.target.value)}
            />
            <input
              className="rounded-xl border border-zinc-600 bg-zinc-900 px-3 py-3"
              placeholder="LOOP END"
              value={loopEnd}
              onChange={(event) => setLoopEnd(event.target.value)}
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
          <h2 className="text-lg font-semibold">MEASURES</h2>
          <div className="mt-3 grid grid-cols-4 gap-2 sm:grid-cols-6 md:grid-cols-10">
            {measureNumbers.slice(0, 100).map((measure) => (
              <button
                key={measure}
                type="button"
                className="rounded-lg bg-zinc-700 px-2 py-2 text-sm hover:bg-zinc-600"
                onClick={() => playerRef.current?.seekToMeasure(measure)}
              >
                {measure}
              </button>
            ))}
          </div>
          {measureNumbers.length > 100 ? (
            <p className="mt-2 text-xs text-zinc-400">
              Showing first 100 measures. Use GO TO MEASURE for later measures.
            </p>
          ) : null}
        </section>
      </main>
    </div>
  );
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
