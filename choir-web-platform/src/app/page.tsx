"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { ScorePlayer, type PlaybackSnapshot } from "@/lib/score-player";
import type {
  AssignablePartId,
  CanonicalPartId,
  MeasurePartEditEvent,
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
  | "review"
  | "check-score"
  | "rehearsal"
  | "warmups"
  | "stations"
  | "tools";

type StudentMode = "station" | "sectional" | "solo" | "checkin" | "vocal";

type MeasureEditorRow = {
  id: string;
  kind: "NOTE" | "REST";
  pitch: string;
  durationBeats: number;
};

const DURATION_OPTIONS = [
  { label: "Whole", value: 4 },
  { label: "Half", value: 2 },
  { label: "Quarter", value: 1 },
  { label: "Eighth", value: 0.5 },
  { label: "Sixteenth", value: 0.25 },
];

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
  const [loadedScoreRecord, setLoadedScoreRecord] = useState<SavedScoreRecord | null>(null);
  const [replaceTargetId, setReplaceTargetId] = useState<string | null>(null);
  const [replacePageNumber, setReplacePageNumber] = useState("1");
  const [feedbackMessage, setFeedbackMessage] = useState<string | null>(null);
  const [measureCorrectionValue, setMeasureCorrectionValue] = useState("1");
  const [measureShouldBeValue, setMeasureShouldBeValue] = useState("1");
  const [boundaryMeasureValue, setBoundaryMeasureValue] = useState("1");
  const [boundaryNote, setBoundaryNote] = useState("");
  const [reviewPart, setReviewPart] = useState<CanonicalPartId>("SOPRANO");
  const [editorPartId, setEditorPartId] = useState("");
  const [editorMeasureValue, setEditorMeasureValue] = useState("1");
  const [measureEditorRows, setMeasureEditorRows] = useState<MeasureEditorRow[]>([]);
  const [assignmentDraft, setAssignmentDraft] = useState<Record<string, AssignablePartId>>({});
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

  const hydrateFromSavedRecord = useCallback(
    (item: SavedScoreRecord, targetPanel: DirectorPanel) => {
      setLoadedScoreRecord(item);
      setAssignmentDraft({ ...item.directorConfirmedPartAssignments });
      setSelectedParts(defaultSelectedPartsFromScore(item.parsedScore));
      setScore(item.parsedScore);
      setCurrentScoreId(item.id);
      pendingTempoPercentRef.current = item.lastUsedTempoPercent;
      setDiagnostics({
        lowConfidence: item.recognitionWarnings.length > 0,
        warnings: item.recognitionWarnings,
        quality: item.recognitionQuality,
      });
      const firstMeasure = item.parsedScore.measures[0]?.displayNumber ?? 1;
      const firstPart = item.parsedScore.parts[0]?.id ?? "";
      setMeasureCorrectionValue(String(firstMeasure));
      setMeasureShouldBeValue(String(firstMeasure));
      setBoundaryMeasureValue(String(firstMeasure));
      setEditorMeasureValue(String(firstMeasure));
      setEditorPartId(firstPart);
      const fallbackPart = item.parsedScore.parts.find((part) => part.canonicalPart !== "UNKNOWN");
      if (fallbackPart) {
        setReviewPart(fallbackPart.canonicalPart);
      }
      setMeasureEditorRows(
        buildEditorRowsFromScore(item.parsedScore, firstPart, firstMeasure)
      );
      setActivePanel(targetPanel);
    },
    []
  );

  const fetchSavedScoreRecord = useCallback(
    async (id: string) => {
      const response = await fetch(`/api/my-music/${id}`);
      const body = (await response.json()) as { item?: SavedScoreRecord; message?: string };
      if (!response.ok || !body.item) {
        throw new Error(body.message ?? "Could not load saved score.");
      }
      return body.item;
    },
    []
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
        warnings?: string[];
      };
      if (!response.ok || !body.parsedScore || !body.savedScore) {
        throw new Error(body.message ?? "Recognition failed.");
      }
      const savedRecord = await fetchSavedScoreRecord(body.savedScore.id);
      hydrateFromSavedRecord(savedRecord, "review");
      setFeedbackMessage(body.message ?? "✓ Saved to My Music");
      await refreshSavedMusic();
    } catch (caught) {
      const message = caught instanceof Error ? caught.message : "Unknown recognition error.";
      setError(message);
    } finally {
      setIsBusy(false);
    }
  }, [fetchSavedScoreRecord, hydrateFromSavedRecord, pendingFile, refreshSavedMusic]);

  const loadSavedScore = async (id: string, targetPanel: DirectorPanel = "rehearsal") => {
    try {
      setFeedbackMessage(null);
      const item = await fetchSavedScoreRecord(id);
      hydrateFromSavedRecord(item, targetPanel);
      setError(null);
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
        setLoadedScoreRecord((prev) =>
          prev ? { ...prev, title: nextTitle, parsedScore: { ...prev.parsedScore, title: nextTitle } } : prev
        );
      }
      return;
    }
    const body = (await response.json()) as { message?: string };
    setError(body.message ?? "Failed to rename score.");
  };

  const reprocessSavedScore = async (item: SavedScoreSummary) => {
    const confirmed = confirm(
      "Reprocessing may replace recognition results. Your manual corrections will be preserved where possible. Continue?"
    );
    if (!confirmed) {
      return;
    }
    const response = await fetch(`/api/my-music/${item.id}/reprocess`, { method: "POST" });
    const body = (await response.json()) as { item?: SavedScoreRecord; message?: string };
    if (!response.ok || !body.item) {
      setError(body.message ?? "Failed to reprocess score.");
      return;
    }
    setFeedbackMessage("Score reprocessed.");
    await refreshSavedMusic();
    if (currentScoreId === item.id) {
      hydrateFromSavedRecord(body.item, activePanel === "check-score" ? "check-score" : "review");
    }
  };

  const requestReplacePages = (itemId: string) => {
    const nextPage = prompt("Replace which page number? (optional)", replacePageNumber)?.trim();
    if (nextPage) {
      setReplacePageNumber(nextPage);
    }
    setReplaceTargetId(itemId);
    replaceInputRef.current?.click();
  };

  const handleReplacePagesSelected = async (file: File | null) => {
    if (!replaceTargetId || !file) {
      return;
    }
    const formData = new FormData();
    formData.append("file", file);
    const pageNumber = Number(replacePageNumber);
    if (Number.isFinite(pageNumber) && pageNumber > 0) {
      formData.append("pageNumber", String(Math.round(pageNumber)));
    }
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
      hydrateFromSavedRecord(body.item, activePanel === "check-score" ? "check-score" : "review");
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
      setLoadedScoreRecord(null);
      setAssignmentDraft({});
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

  const savePartAssignments = async (assignments: Record<string, AssignablePartId>) => {
    if (!currentScoreId) {
      return;
    }
    const response = await fetch(`/api/my-music/${currentScoreId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action: "updateAssignments", assignments }),
    });
    const body = (await response.json()) as { item?: SavedScoreRecord; message?: string };
    if (!response.ok || !body.item) {
      setError(body.message ?? "Could not update part assignment.");
      return;
    }
    hydrateFromSavedRecord(body.item, "check-score");
    setFeedbackMessage("Part assignments saved.");
    await refreshSavedMusic();
  };

  const saveMeasureNumberCorrection = async () => {
    if (!currentScoreId || !loadedScoreRecord) {
      return;
    }
    const selectedMeasure = Number(measureCorrectionValue);
    const shouldBe = Number(measureShouldBeValue);
    const match = loadedScoreRecord.parsedScore.measures.find(
      (measure) => measure.displayNumber === selectedMeasure
    );
    if (!match || !Number.isFinite(shouldBe)) {
      return;
    }
    const response = await fetch(`/api/my-music/${currentScoreId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        action: "setMeasureNumberAnchor",
        internalIndex: match.internalIndex,
        displayNumber: Math.round(shouldBe),
      }),
    });
    const body = (await response.json()) as { item?: SavedScoreRecord; message?: string };
    if (!response.ok || !body.item) {
      setError(body.message ?? "Could not save measure numbering.");
      return;
    }
    hydrateFromSavedRecord(body.item, "check-score");
    setFeedbackMessage("Measure numbering updated.");
  };

  const saveBoundaryFlag = async () => {
    if (!currentScoreId || !loadedScoreRecord) {
      return;
    }
    const selectedMeasure = Number(boundaryMeasureValue);
    const match = loadedScoreRecord.parsedScore.measures.find(
      (measure) => measure.displayNumber === selectedMeasure
    );
    if (!match) {
      return;
    }
    const response = await fetch(`/api/my-music/${currentScoreId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        action: "flagMeasureBoundary",
        measureInternalIndex: match.internalIndex,
        note: boundaryNote || "Measure boundary is wrong",
      }),
    });
    const body = (await response.json()) as { item?: SavedScoreRecord; message?: string };
    if (!response.ok || !body.item) {
      setError(body.message ?? "Could not flag measure boundary.");
      return;
    }
    hydrateFromSavedRecord(body.item, "check-score");
    setBoundaryNote("");
    setFeedbackMessage("Measure boundary flagged for review.");
  };

  const saveMeasureEditor = async () => {
    if (!currentScoreId || !loadedScoreRecord || !editorPartId) {
      return;
    }
    const selectedMeasure = Number(editorMeasureValue);
    const match = loadedScoreRecord.parsedScore.measures.find(
      (measure) => measure.displayNumber === selectedMeasure
    );
    if (!match) {
      return;
    }
    const events: MeasurePartEditEvent[] = measureEditorRows.map((row) => ({
      id: row.id,
      kind: row.kind,
      midi: row.kind === "NOTE" ? pitchNameToMidi(row.pitch) : null,
      durationBeats: row.durationBeats,
    }));
    const response = await fetch(`/api/my-music/${currentScoreId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        action: "saveMeasurePartEvents",
        partId: editorPartId,
        measureInternalIndex: match.internalIndex,
        events,
      }),
    });
    const body = (await response.json()) as { item?: SavedScoreRecord; message?: string };
    if (!response.ok || !body.item) {
      setError(body.message ?? "Could not save measure edits.");
      return;
    }
    hydrateFromSavedRecord(body.item, "check-score");
    setFeedbackMessage(`Saved fixes for measure ${selectedMeasure}.`);
  };

  const playSelectedMeasure = () => {
    const target = Number(editorMeasureValue);
    if (!Number.isFinite(target)) {
      return;
    }
    playerRef.current?.setLoopRange(target, target);
    playerRef.current?.seekToMeasure(target);
    void playerRef.current?.play();
  };

  const playReviewPart = () => {
    setSelectedParts(new Set<CanonicalPartId>([reviewPart]));
    const firstMeasure = score?.measures[0]?.displayNumber ?? 1;
    playerRef.current?.seekToMeasure(firstMeasure);
    void playerRef.current?.play();
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
          <div className="mt-4 grid grid-cols-2 gap-2 md:grid-cols-8">
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
              label="Recognition Review"
              active={activePanel === "review"}
              onClick={() => setActivePanel("review")}
            />
            <PanelTab
              label="Check Score"
              active={activePanel === "check-score"}
              onClick={() => setActivePanel("check-score")}
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
                    {item.recognitionWarnings.length ? (
                      <p className="mt-2 text-xs text-amber-300">
                        ⚠ {item.recognitionWarnings[0]}
                      </p>
                    ) : null}
                    <div className="mt-3 grid grid-cols-2 gap-2 md:grid-cols-6">
                      <ControlButton
                        label="REHEARSE"
                        accent
                        onClick={() => void loadSavedScore(item.id)}
                      />
                      <ControlButton
                        label="CHECK SCORE"
                        onClick={() => void loadSavedScore(item.id, "check-score")}
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

        {activePanel === "review" ? (
          <section className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
            <h2 className="text-xl font-semibold">Ready to Rehearse</h2>
            {loadedScoreRecord ? (
              <>
                <p className="mt-2 text-sm text-zinc-300">
                  {loadedScoreRecord.title} • {loadedScoreRecord.partTextureLabel}
                </p>
                <div className="mt-4 rounded-xl border border-zinc-700 bg-zinc-900/40 p-4">
                  <p className="text-sm font-semibold text-zinc-200">Detected:</p>
                  <div className="mt-2 grid grid-cols-1 gap-2 sm:grid-cols-2">
                    {PART_BUTTONS.map((part) => {
                      const found = loadedScoreRecord.parsedScore.parts.some(
                        (item) => item.canonicalPart === part
                      );
                      return (
                        <p key={part} className="text-sm">
                          {found ? "✓" : "•"} {labelPart(part)}
                        </p>
                      );
                    })}
                  </div>
                  <p className="mt-3 text-sm text-zinc-300">
                    Measures: {measureRangeLabel(loadedScoreRecord.parsedScore)}
                  </p>
                </div>

                {loadedScoreRecord.recognitionWarnings.length ? (
                  <div className="mt-4 rounded-xl border border-amber-700 bg-amber-950/30 p-4">
                    <p className="text-sm font-semibold text-amber-200">
                      Recognition warnings
                    </p>
                    <ul className="mt-2 list-disc space-y-1 pl-5 text-sm text-amber-100">
                      {loadedScoreRecord.recognitionWarnings.slice(0, 8).map((warning) => (
                        <li key={warning}>{warning}</li>
                      ))}
                    </ul>
                  </div>
                ) : null}

                <div className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-2">
                  <ControlButton
                    label={loadedScoreRecord.recognitionWarnings.length ? "REHEARSE ANYWAY" : "REHEARSE"}
                    accent
                    onClick={() => setActivePanel("rehearsal")}
                  />
                  <ControlButton label="CHECK SCORE" onClick={() => setActivePanel("check-score")} />
                </div>
              </>
            ) : (
              <p className="mt-3 text-sm text-zinc-400">Load or process a score first.</p>
            )}
          </section>
        ) : null}

        {activePanel === "check-score" ? (
          <section className="rounded-3xl border border-zinc-700 bg-[#20242b] p-5">
            <h2 className="text-xl font-semibold">Fix Score</h2>
            {loadedScoreRecord ? (
              <div className="mt-4 space-y-5">
                <div className="rounded-xl border border-zinc-700 bg-zinc-900/40 p-4">
                  <p className="text-sm font-semibold text-zinc-200">Part-specific review</p>
                  <div className="mt-2 grid grid-cols-3 gap-2">
                    {PART_BUTTONS.map((part) => (
                      <button
                        key={part}
                        type="button"
                        onClick={() => setReviewPart(part)}
                        className={`rounded-lg px-3 py-2 text-sm font-semibold ${
                          reviewPart === part ? "bg-cyan-400 text-black" : "bg-zinc-700 text-zinc-100"
                        }`}
                      >
                        {labelPart(part)}
                      </button>
                    ))}
                  </div>
                  <div className="mt-3 grid grid-cols-1 gap-2 sm:grid-cols-2">
                    <ControlButton label={`PLAY ${labelPart(reviewPart)}`} onClick={playReviewPart} />
                    <ControlButton label="PLAY THIS MEASURE" onClick={playSelectedMeasure} />
                  </div>
                </div>

                <div className="rounded-xl border border-zinc-700 bg-zinc-900/40 p-4">
                  <p className="text-sm font-semibold text-zinc-200">Part assignment</p>
                  <div className="mt-2 space-y-2">
                    {loadedScoreRecord.parsedScore.parts.map((part) => (
                      <div key={part.id} className="grid grid-cols-1 gap-2 sm:grid-cols-[1fr_180px]">
                        <p className="rounded-lg bg-zinc-800 px-3 py-2 text-sm">
                          {part.sourceName}
                        </p>
                        <select
                          value={assignmentDraft[part.id] ?? part.canonicalPart}
                          onChange={(event) =>
                            setAssignmentDraft((prev) => ({
                              ...prev,
                              [part.id]: event.target.value as AssignablePartId,
                            }))
                          }
                          className="rounded-lg border border-zinc-600 bg-zinc-900 px-3 py-2 text-sm"
                        >
                          <option value="SOPRANO">Soprano</option>
                          <option value="ALTO">Alto</option>
                          <option value="TENOR">Tenor</option>
                          <option value="BASS">Bass</option>
                          <option value="PIANO">Piano</option>
                          <option value="IGNORE">Ignore</option>
                        </select>
                      </div>
                    ))}
                  </div>
                  <div className="mt-3">
                    <ControlButton
                      label="SAVE PART ASSIGNMENT"
                      onClick={() => void savePartAssignments(assignmentDraft)}
                    />
                  </div>
                </div>

                <div className="rounded-xl border border-zinc-700 bg-zinc-900/40 p-4">
                  <p className="text-sm font-semibold text-zinc-200">Measure numbers</p>
                  <div className="mt-2 grid grid-cols-1 gap-2 sm:grid-cols-3">
                    <input
                      value={measureCorrectionValue}
                      onChange={(event) => setMeasureCorrectionValue(event.target.value)}
                      className="rounded-lg border border-zinc-600 bg-zinc-900 px-3 py-2 text-sm"
                      placeholder="Current measure"
                    />
                    <input
                      value={measureShouldBeValue}
                      onChange={(event) => setMeasureShouldBeValue(event.target.value)}
                      className="rounded-lg border border-zinc-600 bg-zinc-900 px-3 py-2 text-sm"
                      placeholder="Should be measure"
                    />
                    <ControlButton label="SAVE NUMBERING" onClick={() => void saveMeasureNumberCorrection()} />
                  </div>
                </div>

                <div className="rounded-xl border border-zinc-700 bg-zinc-900/40 p-4">
                  <p className="text-sm font-semibold text-zinc-200">Wrong measure boundary</p>
                  <div className="mt-2 grid grid-cols-1 gap-2 sm:grid-cols-3">
                    <input
                      value={boundaryMeasureValue}
                      onChange={(event) => setBoundaryMeasureValue(event.target.value)}
                      className="rounded-lg border border-zinc-600 bg-zinc-900 px-3 py-2 text-sm"
                      placeholder="Measure"
                    />
                    <input
                      value={boundaryNote}
                      onChange={(event) => setBoundaryNote(event.target.value)}
                      className="rounded-lg border border-zinc-600 bg-zinc-900 px-3 py-2 text-sm"
                      placeholder="What sounds wrong"
                    />
                    <ControlButton label="FLAG FOR REPROCESS" onClick={() => void saveBoundaryFlag()} />
                  </div>
                </div>

                <div className="rounded-xl border border-zinc-700 bg-zinc-900/40 p-4">
                  <p className="text-sm font-semibold text-zinc-200">Measure-level note/rhythm fix</p>
                  <div className="mt-2 grid grid-cols-1 gap-2 sm:grid-cols-3">
                    <select
                      value={editorPartId}
                      onChange={(event) => {
                        const nextPartId = event.target.value;
                        setEditorPartId(nextPartId);
                        if (!loadedScoreRecord) {
                          return;
                        }
                        const selectedMeasure = Number(editorMeasureValue);
                        if (!Number.isFinite(selectedMeasure)) {
                          return;
                        }
                        setMeasureEditorRows(
                          buildEditorRowsFromScore(
                            loadedScoreRecord.parsedScore,
                            nextPartId,
                            selectedMeasure
                          )
                        );
                      }}
                      className="rounded-lg border border-zinc-600 bg-zinc-900 px-3 py-2 text-sm"
                    >
                      {loadedScoreRecord.parsedScore.parts.map((part) => (
                        <option key={part.id} value={part.id}>
                          {part.sourceName} ({labelPart(part.canonicalPart)})
                        </option>
                      ))}
                    </select>
                    <input
                      value={editorMeasureValue}
                      onChange={(event) => {
                        const nextValue = event.target.value;
                        setEditorMeasureValue(nextValue);
                        if (!loadedScoreRecord || !editorPartId) {
                          return;
                        }
                        const selectedMeasure = Number(nextValue);
                        if (!Number.isFinite(selectedMeasure)) {
                          return;
                        }
                        setMeasureEditorRows(
                          buildEditorRowsFromScore(
                            loadedScoreRecord.parsedScore,
                            editorPartId,
                            selectedMeasure
                          )
                        );
                      }}
                      className="rounded-lg border border-zinc-600 bg-zinc-900 px-3 py-2 text-sm"
                      placeholder="Measure number"
                    />
                    <ControlButton label="PLAY THIS MEASURE" onClick={playSelectedMeasure} />
                  </div>
                  <div className="mt-3 space-y-2">
                    {measureEditorRows.map((row) => (
                      <div
                        key={row.id}
                        className="grid grid-cols-1 gap-2 rounded-lg border border-zinc-700 bg-zinc-800/80 p-2 sm:grid-cols-[120px_1fr_140px_100px]"
                      >
                        <select
                          value={row.kind}
                          onChange={(event) =>
                            setMeasureEditorRows((prev) =>
                              prev.map((entry) =>
                                entry.id === row.id
                                  ? { ...entry, kind: event.target.value as "NOTE" | "REST" }
                                  : entry
                              )
                            )
                          }
                          className="rounded border border-zinc-600 bg-zinc-900 px-2 py-1 text-sm"
                        >
                          <option value="NOTE">Note</option>
                          <option value="REST">Rest</option>
                        </select>
                        <select
                          value={row.pitch}
                          disabled={row.kind === "REST"}
                          onChange={(event) =>
                            setMeasureEditorRows((prev) =>
                              prev.map((entry) =>
                                entry.id === row.id ? { ...entry, pitch: event.target.value } : entry
                              )
                            )
                          }
                          className="rounded border border-zinc-600 bg-zinc-900 px-2 py-1 text-sm disabled:text-zinc-500"
                        >
                          {pitchOptions().map((pitch) => (
                            <option key={pitch} value={pitch}>
                              {pitch}
                            </option>
                          ))}
                        </select>
                        <select
                          value={String(row.durationBeats)}
                          onChange={(event) =>
                            setMeasureEditorRows((prev) =>
                              prev.map((entry) =>
                                entry.id === row.id
                                  ? { ...entry, durationBeats: Number(event.target.value) }
                                  : entry
                              )
                            )
                          }
                          className="rounded border border-zinc-600 bg-zinc-900 px-2 py-1 text-sm"
                        >
                          {DURATION_OPTIONS.map((duration) => (
                            <option key={duration.value} value={String(duration.value)}>
                              {duration.label}
                            </option>
                          ))}
                        </select>
                        <button
                          type="button"
                          onClick={() =>
                            setMeasureEditorRows((prev) =>
                              prev.length > 1 ? prev.filter((entry) => entry.id !== row.id) : prev
                            )
                          }
                          className="rounded bg-zinc-700 px-2 py-1 text-sm"
                        >
                          Delete
                        </button>
                      </div>
                    ))}
                  </div>
                  <div className="mt-3 grid grid-cols-1 gap-2 sm:grid-cols-3">
                    <ControlButton
                      label="ADD NOTE"
                      onClick={() =>
                        setMeasureEditorRows((prev) => [
                          ...prev,
                          {
                            id: crypto.randomUUID(),
                            kind: "NOTE",
                            pitch: "C4",
                            durationBeats: 1,
                          },
                        ])
                      }
                    />
                    <ControlButton
                      label="ADD REST"
                      onClick={() =>
                        setMeasureEditorRows((prev) => [
                          ...prev,
                          {
                            id: crypto.randomUUID(),
                            kind: "REST",
                            pitch: "C4",
                            durationBeats: 1,
                          },
                        ])
                      }
                    />
                    <ControlButton label="SAVE MEASURE FIX" accent onClick={() => void saveMeasureEditor()} />
                  </div>
                </div>
              </div>
            ) : (
              <p className="mt-3 text-sm text-zinc-400">Load or process a score first.</p>
            )}
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

function labelPart(part: CanonicalPartId) {
  if (part === "SOPRANO") {
    return "Soprano";
  }
  if (part === "ALTO") {
    return "Alto";
  }
  if (part === "TENOR") {
    return "Tenor";
  }
  if (part === "BASS") {
    return "Bass";
  }
  if (part === "PIANO") {
    return "Piano";
  }
  return "Unknown";
}

function measureRangeLabel(score: ParsedScore) {
  if (!score.measures.length) {
    return "None";
  }
  const start = score.measures[0].displayNumber;
  const end = score.measures[score.measures.length - 1].displayNumber;
  return `${start}–${end}`;
}

function buildEditorRowsFromScore(
  parsed: ParsedScore,
  partId: string,
  displayMeasureNumber: number
): MeasureEditorRow[] {
  const measure = parsed.measures.find((item) => item.displayNumber === displayMeasureNumber);
  if (!measure) {
    return [
      {
        id: `seed-${displayMeasureNumber}`,
        kind: "REST",
        pitch: "C4",
        durationBeats: 1,
      },
    ];
  }
  const notes = parsed.notes
    .filter(
      (note) =>
        note.partId === partId &&
        note.startBeat >= measure.startBeat &&
        note.startBeat < measure.endBeat
    )
    .sort((a, b) => a.startBeat - b.startBeat);
  if (!notes.length) {
    return [
      {
        id: `seed-${partId}-${displayMeasureNumber}`,
        kind: "REST",
        pitch: "C4",
        durationBeats: 1,
      },
    ];
  }
  return notes.map((note, idx) => ({
    id: `${partId}-${displayMeasureNumber}-${idx}`,
    kind: "NOTE",
    pitch: midiToPitchName(note.midi),
    durationBeats: note.durationBeats,
  }));
}

function pitchOptions() {
  const options: string[] = [];
  for (let midi = 36; midi <= 96; midi += 1) {
    options.push(midiToPitchName(midi));
  }
  return options;
}

function midiToPitchName(midi: number) {
  const steps = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
  const safeMidi = Math.max(0, Math.min(127, Math.round(midi)));
  const octave = Math.floor(safeMidi / 12) - 1;
  const step = steps[safeMidi % 12];
  return `${step}${octave}`;
}

function pitchNameToMidi(value: string) {
  const match = value.trim().toUpperCase().match(/^([A-G])(#?)(-?\d+)$/);
  if (!match) {
    return 60;
  }
  const [, step, sharp, octaveValue] = match;
  const stepOffset: Record<string, number> = {
    C: 0,
    D: 2,
    E: 4,
    F: 5,
    G: 7,
    A: 9,
    B: 11,
  };
  const octave = Number(octaveValue);
  const midi = (octave + 1) * 12 + stepOffset[step] + (sharp ? 1 : 0);
  return Math.max(0, Math.min(127, midi));
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
