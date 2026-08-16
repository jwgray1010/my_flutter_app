"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { ScorePlayer, type PlaybackSnapshot } from "@/lib/score-player";
import type {
  CanonicalPartId,
  OMRDiagnostics,
  ParsedScore,
  SavedScoreRecord,
  SavedScoreSummary,
} from "@/lib/score-types";

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

type DirectorPanel =
  | "upload"
  | "my-music"
  | "rehearsal"
  | "warmups"
  | "stations"
  | "tools";

type StudentMode = "station" | "sectional" | "solo" | "checkin" | "vocal";

export default function Home() {
  const [score, setScore] = useState<ParsedScore | null>(null);
  const [diagnostics, setDiagnostics] = useState<OMRDiagnostics | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isBusy, setIsBusy] = useState(false);
  const [isPhoneViewport, setIsPhoneViewport] = useState(false);
  const [studentMode, setStudentMode] = useState<StudentMode | null>(null);
  const [activePanel, setActivePanel] = useState<DirectorPanel>("upload");
  const [snapshot, setSnapshot] = useState<PlaybackSnapshot>(initialSnapshot);
  const [selectedParts, setSelectedParts] = useState<Set<CanonicalPartId>>(new Set(PART_BUTTONS));
  const [gotoMeasure, setGotoMeasure] = useState("1");
  const [loopStartMeasure, setLoopStartMeasure] = useState("1");
  const [loopEndMeasure, setLoopEndMeasure] = useState("2");
  const [pendingFile, setPendingFile] = useState<File | null>(null);
  const [savedMusic, setSavedMusic] = useState<SavedScoreSummary[]>([]);
  const [savedMusicLoading, setSavedMusicLoading] = useState(true);
  const [currentScoreId, setCurrentScoreId] = useState<string | null>(null);
  const [replaceTargetId, setReplaceTargetId] = useState<string | null>(null);
  const [feedbackMessage, setFeedbackMessage] = useState<string | null>(null);
  const uploadInputRef = useRef<HTMLInputElement>(null);
  const replaceInputRef = useRef<HTMLInputElement>(null);
  const playerRef = useRef<ScorePlayer | null>(null);
  const pendingTempoPercentRef = useRef<number | null>(null);

  useEffect(() => {
    if (typeof window === "undefined") {
      return;
    }
    const mediaQuery = window.matchMedia("(max-width: 768px)");
    const updateViewport = () => setIsPhoneViewport(mediaQuery.matches);
    updateViewport();
    mediaQuery.addEventListener("change", updateViewport);
    return () => mediaQuery.removeEventListener("change", updateViewport);
  }, []);

  useEffect(() => {
    if (typeof window === "undefined") {
      return;
    }
    const updateModeFromUrl = () => {
      const params = new URLSearchParams(window.location.search);
      setStudentMode(normalizeStudentMode(params.get("mode") ?? params.get("studentMode")));
    };
    updateModeFromUrl();
    window.addEventListener("popstate", updateModeFromUrl);
    return () => window.removeEventListener("popstate", updateModeFromUrl);
  }, []);

  useEffect(() => {
    if (!score) {
      return;
    }
    const player = new ScorePlayer(score);
    playerRef.current?.dispose();
    playerRef.current = player;
    if (pendingTempoPercentRef.current != null) {
      player.setTempoPercent(pendingTempoPercentRef.current);
      pendingTempoPercentRef.current = null;
    }
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

  const refreshSavedMusic = useCallback(async () => {
    try {
      setSavedMusicLoading(true);
      const response = await fetch("/api/my-music");
      const body = (await response.json()) as { items?: SavedScoreSummary[]; message?: string };
      if (!response.ok) {
        throw new Error(body.message ?? "Failed to load My Music.");
      }
      setSavedMusic(body.items ?? []);
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : "Failed to load My Music.";
      setError(message);
    } finally {
      setSavedMusicLoading(false);
    }
  }, []);

  useEffect(() => {
    let isCancelled = false;
    void fetch("/api/my-music")
      .then(async (response) => {
        const body = (await response.json()) as { items?: SavedScoreSummary[]; message?: string };
        if (!response.ok) {
          throw new Error(body.message ?? "Failed to load My Music.");
        }
        if (!isCancelled) {
          setSavedMusic(body.items ?? []);
        }
      })
      .catch((caught) => {
        if (isCancelled) {
          return;
        }
        const message = caught instanceof Error ? caught.message : "Failed to load My Music.";
        setError(message);
      })
      .finally(() => {
        if (!isCancelled) {
          setSavedMusicLoading(false);
        }
      });
    return () => {
      isCancelled = true;
    };
  }, []);

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
    setFeedbackMessage(null);
    setIsBusy(true);
    try {
      const formData = new FormData();
      formData.append("file", file);
      const response = await fetch("/api/my-music/process", {
        method: "POST",
        body: formData,
      });
      const body = (await response.json()) as {
        message?: string;
        diagnostics?: OMRDiagnostics;
        parsedScore?: ParsedScore;
        savedScore?: SavedScoreSummary;
      };
      if (!response.ok || !body.parsedScore || !body.savedScore) {
        throw new Error(body.message ?? "Recognition failed.");
      }
      setSelectedParts(defaultSelectedPartsFromScore(body.parsedScore));
      setScore(body.parsedScore);
      setDiagnostics(body.diagnostics ?? null);
      setCurrentScoreId(body.savedScore.id);
      pendingTempoPercentRef.current = body.savedScore.lastUsedTempoPercent;
      setFeedbackMessage(body.message ?? "✓ Saved to My Music");
      await refreshSavedMusic();
      setActivePanel("rehearsal");
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : "Unknown recognition error.";
      setError(message);
    } finally {
      setIsBusy(false);
    }
  }, [pendingFile, refreshSavedMusic]);

  const loadSavedScore = async (id: string) => {
    try {
      setFeedbackMessage(null);
      const response = await fetch(`/api/my-music/${id}`);
      const body = (await response.json()) as { item?: SavedScoreRecord; message?: string };
      if (!response.ok || !body.item) {
        throw new Error(body.message ?? "Could not load saved score.");
      }
      setSelectedParts(defaultSelectedPartsFromScore(body.item.parsedScore));
      setScore(body.item.parsedScore);
      setCurrentScoreId(body.item.id);
      pendingTempoPercentRef.current = body.item.lastUsedTempoPercent;
      setDiagnostics(null);
      setError(null);
      setActivePanel("rehearsal");
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : "Could not load saved score.";
      setError(message);
    }
  };

  const renameSavedScore = async (item: SavedScoreSummary) => {
    const nextTitle = prompt("Rename piece", item.title)?.trim();
    if (!nextTitle || nextTitle === item.title) {
      return;
    }
    const response = await fetch(`/api/my-music/${item.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action: "rename", title: nextTitle }),
    });
    if (response.ok) {
      setFeedbackMessage(`Renamed to "${nextTitle}"`);
      await refreshSavedMusic();
      if (currentScoreId === item.id && score) {
        setScore({ ...score, title: nextTitle });
      }
      return;
    }
    const body = (await response.json()) as { message?: string };
    setError(body.message ?? "Failed to rename score.");
  };

  const reprocessSavedScore = async (item: SavedScoreSummary) => {
    const response = await fetch(`/api/my-music/${item.id}/reprocess`, { method: "POST" });
    const body = (await response.json()) as { item?: SavedScoreRecord; message?: string };
    if (!response.ok || !body.item) {
      setError(body.message ?? "Failed to reprocess score.");
      return;
    }
    setFeedbackMessage("Score reprocessed.");
    await refreshSavedMusic();
    if (currentScoreId === item.id) {
      setSelectedParts(defaultSelectedPartsFromScore(body.item.parsedScore));
      setScore(body.item.parsedScore);
    }
  };

  const requestReplacePages = (itemId: string) => {
    setReplaceTargetId(itemId);
    replaceInputRef.current?.click();
  };

  const handleReplacePagesSelected = async (file: File | null) => {
    if (!replaceTargetId || !file) {
      return;
    }
    const formData = new FormData();
    formData.append("file", file);
    const response = await fetch(`/api/my-music/${replaceTargetId}/replace-pages`, {
      method: "POST",
      body: formData,
    });
    const body = (await response.json()) as { item?: SavedScoreRecord; message?: string };
    if (!response.ok || !body.item) {
      setError(body.message ?? "Failed to replace score pages.");
      return;
    }
    setFeedbackMessage("Pages replaced and score reprocessed.");
    await refreshSavedMusic();
    if (currentScoreId === replaceTargetId) {
      setSelectedParts(defaultSelectedPartsFromScore(body.item.parsedScore));
      setScore(body.item.parsedScore);
    }
    setReplaceTargetId(null);
  };

  const deleteSavedScore = async (item: SavedScoreSummary) => {
    if (!confirm(`Delete "${item.title}" from My Music?`)) {
      return;
    }
    const response = await fetch(`/api/my-music/${item.id}`, { method: "DELETE" });
    if (!response.ok) {
      const body = (await response.json()) as { message?: string };
      setError(body.message ?? "Failed to delete score.");
      return;
    }
    setFeedbackMessage(`Deleted "${item.title}"`);
    if (currentScoreId === item.id) {
      setCurrentScoreId(null);
      setScore(null);
      setDiagnostics(null);
    }
    await refreshSavedMusic();
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

  const setLoopRange = () => {
    const start = Number(loopStartMeasure);
    const end = Number(loopEndMeasure);
    if (!Number.isFinite(start) || !Number.isFinite(end)) {
      return;
    }
    playerRef.current?.setLoopRange(start, end);
  };

  const persistTempoPercent = useCallback(
    async (tempoPercent: number) => {
      if (!currentScoreId) {
        return;
      }
      await fetch(`/api/my-music/${currentScoreId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "updateTempo", tempoPercent }),
      });
    },
    [currentScoreId]
  );

  const adjustTempo = (delta: number) => {
    playerRef.current?.adjustTempoPercent(delta);
    const nextTempo = Math.max(50, Math.min(120, Math.round(snapshot.tempoPercent + delta)));
    void persistTempoPercent(nextTempo);
  };

  const voiceDetections = score?.parts ?? [];
  const quality = diagnostics?.quality;
  const status = isBusy
    ? "PROCESSING MUSIC..."
    : score
      ? "READY TO REHEARSE"
      : "UPLOAD SCORE";

  if (studentMode) {
    return (
      <div className="min-h-screen bg-[#16181d] px-4 py-6 text-zinc-100">
        <main className="mx-auto flex w-full max-w-3xl flex-col gap-5">
          <header className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
            <p className="text-xs tracking-[0.14em] text-zinc-300">STUDENT MODE • WEBSITE ONLY</p>
            <h1 className="mt-1 text-2xl font-semibold capitalize">{studentMode} Mode</h1>
            <p className="mt-2 text-zinc-300">
              Opened through a link/QR path in the same web application.
            </p>
          </header>
          {studentMode === "checkin" || studentMode === "vocal" ? (
            <section className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
              <p className="text-zinc-200">
                {studentMode === "checkin" ? "Check-In" : "Vocal Development"} tools are planned in
                this same website. This route is reserved for those workflows.
              </p>
            </section>
          ) : null}
          <RemoteControlPanel
            scoreLoaded={Boolean(score)}
            snapshot={snapshot}
            gotoMeasure={gotoMeasure}
            setGotoMeasure={setGotoMeasure}
            loopStartMeasure={loopStartMeasure}
            setLoopStartMeasure={setLoopStartMeasure}
            loopEndMeasure={loopEndMeasure}
            setLoopEndMeasure={setLoopEndMeasure}
            onTogglePlay={() => playerRef.current?.togglePlayPause()}
            onBack={() => playerRef.current?.jumpRelativeMeasures(-2)}
            onForward={() => playerRef.current?.jumpRelativeMeasures(2)}
            onTempoDown={() => adjustTempo(-5)}
            onTempoUp={() => adjustTempo(5)}
            onGoToMeasure={gotoSelectedMeasure}
            onStartLoop={setLoopRange}
            onStopLoop={() => playerRef.current?.clearLoop()}
            selectedParts={selectedParts}
            availableCanonicalParts={availableCanonicalParts}
            onTogglePart={handleTogglePart}
            onSelectAllParts={handleSetAllParts}
            largeButtons
          />
        </main>
      </div>
    );
  }

  if (isPhoneViewport) {
    return (
      <div className="min-h-screen bg-[#16181d] px-4 py-6 text-zinc-100">
        <main className="mx-auto flex w-full max-w-2xl flex-col gap-5">
          <header className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
            <p className="text-xs tracking-[0.14em] text-zinc-300">MOBILE REMOTE • WEBSITE ONLY</p>
            <h1 className="mt-1 text-2xl font-semibold">Rehearsal Remote</h1>
            <p className="mt-2 text-zinc-300">
              m.{snapshot.currentMeasure} | {snapshot.tempoPercent}% |{" "}
              {snapshot.isPlaying ? "Playing" : "Paused"}
            </p>
          </header>
          <RemoteControlPanel
            scoreLoaded={Boolean(score)}
            snapshot={snapshot}
            gotoMeasure={gotoMeasure}
            setGotoMeasure={setGotoMeasure}
            loopStartMeasure={loopStartMeasure}
            setLoopStartMeasure={setLoopStartMeasure}
            loopEndMeasure={loopEndMeasure}
            setLoopEndMeasure={setLoopEndMeasure}
            onTogglePlay={() => playerRef.current?.togglePlayPause()}
            onBack={() => playerRef.current?.jumpRelativeMeasures(-2)}
            onForward={() => playerRef.current?.jumpRelativeMeasures(2)}
            onTempoDown={() => adjustTempo(-5)}
            onTempoUp={() => adjustTempo(5)}
            onGoToMeasure={gotoSelectedMeasure}
            onStartLoop={setLoopRange}
            onStopLoop={() => playerRef.current?.clearLoop()}
            selectedParts={selectedParts}
            availableCanonicalParts={availableCanonicalParts}
            onTogglePart={handleTogglePart}
            onSelectAllParts={handleSetAllParts}
            largeButtons
          />
        </main>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#16181d] text-zinc-100">
      <main className="mx-auto flex w-full max-w-6xl flex-col gap-5 px-4 py-6 sm:px-8">
        <header className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
          <p className="text-xs tracking-[0.16em] text-zinc-300">DIRECTOR VIEW • WEBSITE ONLY</p>
          <h1 className="mt-1 text-2xl font-semibold tracking-wide">Local Web Rehearsal Platform</h1>
          <p className="mt-2 text-zinc-300">{status}</p>
          <div className="mt-4 grid grid-cols-2 gap-2 md:grid-cols-6">
            <PanelTab
              label="Upload Score"
              active={activePanel === "upload"}
              onClick={() => setActivePanel("upload")}
            />
            <PanelTab
              label="My Music"
              active={activePanel === "my-music"}
              onClick={() => setActivePanel("my-music")}
            />
            <PanelTab
              label="Rehearsal"
              active={activePanel === "rehearsal"}
              onClick={() => setActivePanel("rehearsal")}
            />
            <PanelTab
              label="Warmups"
              active={activePanel === "warmups"}
              onClick={() => setActivePanel("warmups")}
            />
            <PanelTab
              label="Stations"
              active={activePanel === "stations"}
              onClick={() => setActivePanel("stations")}
            />
            <PanelTab
              label="Student/Teacher"
              active={activePanel === "tools"}
              onClick={() => setActivePanel("tools")}
            />
          </div>
        </header>

        {activePanel === "upload" ? (
          <section className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
            <h2 className="text-lg font-semibold">Upload Score</h2>
            <p className="mt-1 text-sm text-zinc-300">
              Local workflow: Upload file → Process music → Rehearsal playback.
            </p>
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
            <button
              type="button"
              onClick={() => setActivePanel("my-music")}
              className="mt-3 w-full rounded-xl bg-zinc-700 px-4 py-4 text-left text-lg font-semibold hover:bg-zinc-600"
            >
              MY MUSIC
            </button>
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
            {feedbackMessage ? <p className="mt-3 text-sm text-emerald-300">{feedbackMessage}</p> : null}
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
        ) : null}

        {activePanel === "my-music" ? (
          <section className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
            <h2 className="text-lg font-semibold">My Music</h2>
            <p className="mt-1 text-sm text-zinc-300">Persistent local storage (SQLite + files).</p>
            {feedbackMessage ? <p className="mt-2 text-sm text-emerald-300">{feedbackMessage}</p> : null}
            {error ? <p className="mt-2 text-sm text-rose-300">{error}</p> : null}
            <input
              ref={replaceInputRef}
              className="hidden"
              type="file"
              accept=".jpg,.jpeg,.png,.pdf"
              onChange={(event) => {
                const file = event.target.files?.[0] ?? null;
                void handleReplacePagesSelected(file);
                event.currentTarget.value = "";
              }}
            />
            <div className="mt-4 space-y-2">
              {savedMusicLoading ? (
                <p className="text-sm text-zinc-300">Loading My Music...</p>
              ) : savedMusic.length ? (
                savedMusic.slice(0, 50).map((item) => (
                  <div key={item.id} className="rounded-xl border border-zinc-700 bg-zinc-800/70 p-3">
                    <p className="text-lg font-semibold">{item.title}</p>
                    <p className="text-sm text-zinc-300">{item.partTextureLabel}</p>
                    <p className="text-sm text-zinc-300">{item.measureCount} Measures</p>
                    <p className="text-xs text-zinc-400">
                      Imported {new Date(item.importedAt).toLocaleString()}
                    </p>
                    <div className="mt-3 grid grid-cols-2 gap-2 md:grid-cols-5">
                      <ControlButton
                        label="REHEARSE"
                        accent
                        onClick={() => void loadSavedScore(item.id)}
                      />
                      <ControlButton
                        label="Rename"
                        onClick={() => void renameSavedScore(item)}
                      />
                      <ControlButton
                        label="Reprocess"
                        onClick={() => void reprocessSavedScore(item)}
                      />
                      <ControlButton
                        label="Replace Pages"
                        onClick={() => requestReplacePages(item.id)}
                      />
                      <ControlButton
                        label="Delete"
                        onClick={() => void deleteSavedScore(item)}
                      />
                    </div>
                  </div>
                ))
              ) : (
                <p className="text-sm text-zinc-400">No saved scores yet.</p>
              )}
            </div>
          </section>
        ) : null}

        {activePanel === "rehearsal" ? (
          <section className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
            <h2 className="text-lg font-semibold">Rehearsal</h2>
            <p className="mt-1 text-sm text-zinc-300">
              m.{snapshot.currentMeasure} • {snapshot.tempoPercent}% •{" "}
              {snapshot.isPlaying ? "Playing" : "Paused"}
            </p>
            <RemoteControlPanel
              scoreLoaded={Boolean(score)}
              snapshot={snapshot}
              gotoMeasure={gotoMeasure}
              setGotoMeasure={setGotoMeasure}
              loopStartMeasure={loopStartMeasure}
              setLoopStartMeasure={setLoopStartMeasure}
              loopEndMeasure={loopEndMeasure}
              setLoopEndMeasure={setLoopEndMeasure}
              onTogglePlay={() => playerRef.current?.togglePlayPause()}
              onBack={() => playerRef.current?.jumpRelativeMeasures(-2)}
              onForward={() => playerRef.current?.jumpRelativeMeasures(2)}
              onTempoDown={() => adjustTempo(-5)}
              onTempoUp={() => adjustTempo(5)}
              onGoToMeasure={gotoSelectedMeasure}
              onStartLoop={setLoopRange}
              onStopLoop={() => playerRef.current?.clearLoop()}
              selectedParts={selectedParts}
              availableCanonicalParts={availableCanonicalParts}
              onTogglePart={handleTogglePart}
              onSelectAllParts={handleSetAllParts}
            />
            <div className="mt-5 rounded-xl border border-zinc-700 bg-zinc-900/35 p-3">
              <h3 className="text-sm font-semibold">Detected Parts</h3>
              <div className="mt-2 space-y-2 text-sm">
                {voiceDetections.length ? (
                  voiceDetections.map((part) => (
                    <div
                      key={part.id}
                      className="flex items-center justify-between rounded-lg bg-zinc-800 px-3 py-2"
                    >
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
              <p className="mt-2 text-sm text-zinc-300">Measures detected: {measureNumbers.length}</p>
            </div>
          </section>
        ) : null}

        {activePanel === "warmups" ? (
          <ComingSoonPanel
            title="Warmups"
            message="Warmups will run in this same website (no separate app)."
          />
        ) : null}

        {activePanel === "stations" ? (
          <ComingSoonPanel
            title="Stations"
            message="Station links/QR routes will stay inside this web app."
          />
        ) : null}

        {activePanel === "tools" ? (
          <section className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
            <h2 className="text-lg font-semibold">Student / Teacher Tools</h2>
            <p className="mt-1 text-sm text-zinc-300">
              Student routes use URL/QR in the same project:
            </p>
            <ul className="mt-3 list-disc space-y-1 pl-5 text-sm text-zinc-200">
              <li>/ ?mode=station</li>
              <li>/ ?mode=sectional</li>
              <li>/ ?mode=solo</li>
              <li>/ ?mode=checkin</li>
              <li>/ ?mode=vocal</li>
            </ul>
          </section>
        ) : null}
      </main>
    </div>
  );
}

function normalizeStudentMode(modeValue: string | null): StudentMode | null {
  const normalized = (modeValue ?? "").toLowerCase();
  if (normalized === "station") {
    return "station";
  }
  if (normalized === "sectional") {
    return "sectional";
  }
  if (normalized === "solo") {
    return "solo";
  }
  if (normalized === "checkin") {
    return "checkin";
  }
  if (normalized === "vocal") {
    return "vocal";
  }
  return null;
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

function PanelTab(props: { label: string; active: boolean; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={props.onClick}
      className={`rounded-xl px-3 py-2 text-sm font-semibold ${
        props.active ? "bg-cyan-400 text-black" : "bg-zinc-700 text-zinc-100"
      }`}
    >
      {props.label}
    </button>
  );
}

function ComingSoonPanel(props: { title: string; message: string }) {
  return (
    <section className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
      <h2 className="text-lg font-semibold">{props.title}</h2>
      <p className="mt-2 text-sm text-zinc-300">{props.message}</p>
    </section>
  );
}

function RemoteControlPanel(props: {
  scoreLoaded: boolean;
  snapshot: PlaybackSnapshot;
  gotoMeasure: string;
  setGotoMeasure: (value: string) => void;
  loopStartMeasure: string;
  setLoopStartMeasure: (value: string) => void;
  loopEndMeasure: string;
  setLoopEndMeasure: (value: string) => void;
  onTogglePlay: () => void;
  onBack: () => void;
  onForward: () => void;
  onTempoDown: () => void;
  onTempoUp: () => void;
  onGoToMeasure: () => void;
  onStartLoop: () => void;
  onStopLoop: () => void;
  selectedParts: Set<CanonicalPartId>;
  availableCanonicalParts: Set<CanonicalPartId>;
  onTogglePart: (part: CanonicalPartId) => void;
  onSelectAllParts: () => void;
  largeButtons?: boolean;
}) {
  const sizeClasses = props.largeButtons
    ? "py-5 text-lg font-semibold"
    : "py-3 text-sm font-semibold";

  return (
    <div className="mt-4 space-y-4">
      <div className="grid grid-cols-2 gap-3">
        <ControlButton
          label={props.snapshot.isPlaying ? "PAUSE" : "PLAY"}
          accent
          onClick={props.onTogglePlay}
          disabled={!props.scoreLoaded}
          large={props.largeButtons}
        />
        <ControlButton
          label="BACK 2"
          onClick={props.onBack}
          disabled={!props.scoreLoaded}
          large={props.largeButtons}
        />
        <ControlButton
          label="FORWARD 2"
          onClick={props.onForward}
          disabled={!props.scoreLoaded}
          large={props.largeButtons}
        />
        <ControlButton
          label="TEMPO -"
          onClick={props.onTempoDown}
          disabled={!props.scoreLoaded}
          large={props.largeButtons}
        />
        <ControlButton
          label="TEMPO +"
          onClick={props.onTempoUp}
          disabled={!props.scoreLoaded}
          large={props.largeButtons}
        />
      </div>

      <div className="grid grid-cols-2 gap-3">
        <input
          className={`rounded-xl border border-zinc-600 bg-zinc-900 px-3 ${sizeClasses}`}
          placeholder="MEASURE"
          value={props.gotoMeasure}
          onChange={(event) => props.setGotoMeasure(event.target.value)}
        />
        <ControlButton
          label="GO TO MEASURE"
          onClick={props.onGoToMeasure}
          disabled={!props.scoreLoaded}
          large={props.largeButtons}
        />
      </div>

      <div className="grid grid-cols-2 gap-3">
        <input
          className={`rounded-xl border border-zinc-600 bg-zinc-900 px-3 ${sizeClasses}`}
          placeholder="LOOP START"
          value={props.loopStartMeasure}
          onChange={(event) => props.setLoopStartMeasure(event.target.value)}
        />
        <input
          className={`rounded-xl border border-zinc-600 bg-zinc-900 px-3 ${sizeClasses}`}
          placeholder="LOOP END"
          value={props.loopEndMeasure}
          onChange={(event) => props.setLoopEndMeasure(event.target.value)}
        />
        <ControlButton
          label="START LOOP"
          onClick={props.onStartLoop}
          disabled={!props.scoreLoaded}
          large={props.largeButtons}
        />
        <ControlButton
          label="STOP LOOP"
          onClick={props.onStopLoop}
          disabled={!props.scoreLoaded}
          large={props.largeButtons}
        />
      </div>

      <div className="rounded-xl border border-zinc-700 bg-zinc-900/40 p-3">
        <p className="mb-2 text-sm font-semibold tracking-[0.08em] text-zinc-300">PARTS</p>
        <div className="grid grid-cols-3 gap-2">
          <ControlButton
            label="ALL"
            onClick={props.onSelectAllParts}
            disabled={!props.scoreLoaded}
            large={props.largeButtons}
          />
          {PART_BUTTONS.map((part) => {
            const selected = props.selectedParts.has(part);
            const disabled = !props.availableCanonicalParts.has(part);
            return (
              <button
                key={part}
                type="button"
                disabled={disabled}
                onClick={() => props.onTogglePart(part)}
                className={`rounded-xl px-3 ${sizeClasses} ${
                  selected
                    ? "bg-cyan-400 text-black"
                    : disabled
                      ? "bg-zinc-800 text-zinc-500"
                      : "bg-zinc-700 text-zinc-100"
                }`}
              >
                {part}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

function ControlButton(props: {
  label: string;
  onClick: () => void;
  disabled?: boolean;
  accent?: boolean;
  large?: boolean;
}) {
  return (
    <button
      type="button"
      className={`rounded-xl px-4 ${props.large ? "py-5 text-lg" : "py-4 text-base"} font-semibold ${
        props.accent ? "bg-cyan-400 text-black" : "bg-zinc-700 text-zinc-100"
      } disabled:cursor-not-allowed disabled:bg-zinc-800 disabled:text-zinc-500`}
      onClick={props.onClick}
      disabled={props.disabled}
    >
      {props.label}
    </button>
  );
}
