"use client";

import { useMemo, useState } from "react";
import {
  buildStaffMarkers,
  isCustomizableRole,
  STAFF_ROLE_COLORS,
  STAFF_ROLE_LABELS,
  STAFF_ROLES,
  type StaffCorrection,
  type StaffMarker,
  type StaffRole,
} from "@/lib/staff-colors";
import { readStaffGeometry } from "@/lib/staff-geometry";
import type { RecognizedPart } from "@/lib/score-types";

export function StaffColorOverlay(props: {
  parts: RecognizedPart[];
  rawMusicXml: string;
  corrections: StaffCorrection[];
  imageUrl: string | null;
  onCorrect: (correction: StaffCorrection, marker: StaffMarker) => void;
}) {
  const [showMapping, setShowMapping] = useState(false);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [imageFailed, setImageFailed] = useState(false);
  const geometry = useMemo(
    () => readStaffGeometry(props.rawMusicXml, staffIds(props.parts)),
    [props.parts, props.rawMusicXml]
  );
  const markers = useMemo(
    () => buildStaffMarkers(props.parts, props.corrections, geometry.positions),
    [geometry.positions, props.corrections, props.parts]
  );
  const selected = markers.find((marker) => marker.staffId === selectedId) ?? null;

  return (
    <div className="mt-4 rounded-xl border border-zinc-700 bg-zinc-900/40 p-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <p className="text-sm font-semibold text-zinc-200">Staff colors</p>
        <button
          type="button"
          onClick={() => setShowMapping((current) => !current)}
          className="rounded-lg bg-zinc-700 px-3 py-2 text-xs font-semibold"
        >
          {showMapping ? "HIDE STAFF MAPPING" : "SHOW STAFF MAPPING"}
        </button>
      </div>
      <p className="mt-1 text-xs text-zinc-400">
        Colors mark the physical staff. They do not change the recognized notes.
      </p>
      {!geometry.resolved ? (
        <p className="mt-3 rounded-lg border border-amber-700 bg-amber-950/30 p-3 text-sm text-amber-100">
          Unresolved mapping. {geometry.reason} Review the staff list instead of a placed marker.
        </p>
      ) : null}
      {props.imageUrl && !imageFailed ? (
        <div className="relative mt-3 overflow-hidden rounded-lg border border-zinc-700">
          {/* The image sets the coordinate frame. Markers use the same percentages. */}
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={props.imageUrl}
            alt="Original score page"
            className="block h-auto w-full"
            onError={() => setImageFailed(true)}
          />
          {geometry.resolved
            ? markers.map((marker) =>
                marker.position ? (
                  <button
                    key={marker.staffId}
                    type="button"
                    aria-label={`Assign ${marker.label}`}
                    onClick={() => setSelectedId(marker.staffId)}
                    className="absolute w-3 rounded-sm border border-black/40"
                    style={{
                      left: `${marker.position.x * 100}%`,
                      top: `${marker.position.y * 100}%`,
                      height: `${Math.max(marker.position.height, 0.03) * 100}%`,
                      backgroundColor: marker.color,
                    }}
                  />
                ) : null
              )
            : null}
        </div>
      ) : null}
      <div className="mt-3 space-y-2">
        {markers.map((marker) => (
          <button
            key={marker.staffId}
            type="button"
            onClick={() => setSelectedId(marker.staffId)}
            className="flex w-full items-center gap-3 rounded-lg border border-zinc-700 bg-zinc-800 px-3 py-2 text-left"
          >
            <span className="h-8 w-3 shrink-0 rounded-sm" style={{ backgroundColor: marker.color }} />
            <span className="text-sm">
              {marker.label}
              <span className="mt-0.5 block text-xs text-zinc-400">
                {marker.staffId} · {marker.logicalPartIds.join(", ")}
              </span>
              {marker.innerVoices.length > 0 ? (
                <span className="mt-1 flex gap-2 text-xs text-zinc-300">
                  {marker.innerVoices.map((voice) => (
                    <span key={voice.label}>
                      <span className="mr-1 inline-block h-2 w-2 rounded-sm align-middle" style={{ backgroundColor: voice.color }} />
                      {voice.label}
                    </span>
                  ))}
                </span>
              ) : null}
            </span>
          </button>
        ))}
      </div>
      {selected ? (
        <AssignStaffDialog
          marker={selected}
          systemsAvailable={false}
          onClose={() => setSelectedId(null)}
          onSave={(correction) => {
            props.onCorrect(correction, selected);
            setSelectedId(null);
          }}
        />
      ) : null}
      {showMapping ? <StaffMappingTable markers={markers} geometryResolved={geometry.resolved} /> : null}
    </div>
  );
}

function staffIds(parts: RecognizedPart[]) {
  return buildStaffMarkers(parts).map((marker) => marker.staffId);
}

function AssignStaffDialog(props: {
  marker: StaffMarker;
  systemsAvailable: boolean;
  onClose: () => void;
  onSave: (correction: StaffCorrection) => void;
}) {
  const [role, setRole] = useState<StaffRole>(props.marker.role);
  const [scope, setScope] = useState<StaffCorrection["scope"]>("system");
  const [customColor, setCustomColor] = useState(props.marker.color);
  const [customLabel, setCustomLabel] = useState("");

  return (
    <div className="mt-3 rounded-lg border border-cyan-800 bg-zinc-950 p-3">
      <p className="text-sm font-semibold">ASSIGN STAFF</p>
      <p className="mt-1 text-xs text-zinc-400">{props.marker.staffId}</p>
      <div className="mt-2 grid grid-cols-2 gap-2 sm:grid-cols-3">
        {STAFF_ROLES.map((option) => (
          <button
            key={option}
            type="button"
            onClick={() => setRole(option)}
            className={`rounded-lg px-2 py-2 text-left text-xs font-semibold ${
              role === option ? "bg-cyan-400 text-black" : "bg-zinc-800 text-zinc-100"
            }`}
          >
            <span
              className="mr-2 inline-block h-3 w-3 rounded-sm align-middle"
              style={{ backgroundColor: STAFF_ROLE_COLORS[option] }}
            />
            {STAFF_ROLE_LABELS[option]}
          </button>
        ))}
      </div>
      {isCustomizableRole(role) ? (
        <label className="mt-3 block text-xs text-zinc-300">
          Custom color
          <input
            type="color"
            value={customColor}
            onChange={(event) => setCustomColor(event.target.value)}
            className="ml-2 align-middle"
          />
        </label>
      ) : null}
      {role === "CUSTOM" ? (
        <input
          value={customLabel}
          onChange={(event) => setCustomLabel(event.target.value)}
          placeholder="Custom name"
          className="mt-2 w-full rounded-lg border border-zinc-600 bg-zinc-900 px-3 py-2 text-sm"
        />
      ) : null}
      <fieldset className="mt-3 space-y-1 text-sm">
        <legend className="text-xs font-semibold text-zinc-300">Correction scope</legend>
        <label className="block">
          <input type="radio" checked={scope === "system"} onChange={() => setScope("system")} /> This system only
        </label>
        <label className="block text-zinc-500">
          <input type="radio" disabled /> This layout region
        </label>
        <label className="block text-zinc-500">
          <input type="radio" disabled /> Matching systems throughout the score
        </label>
        <p className="text-xs text-zinc-400">
          {props.systemsAvailable
            ? "A correction stays on this staff."
            : "System boundaries are not in this MusicXML. The correction stays on this staff and is not copied to a different staff when the layout changes."}
        </p>
      </fieldset>
      <div className="mt-3 grid grid-cols-2 gap-2">
        <button type="button" onClick={props.onClose} className="rounded-lg bg-zinc-700 px-3 py-2 text-sm font-semibold">
          Cancel
        </button>
        <button
          type="button"
          onClick={() =>
            props.onSave({
              staffId: props.marker.staffId,
              role,
              scope,
              systemId: null,
              layoutKey: null,
              customColor: isCustomizableRole(role) ? customColor : null,
              customLabel: role === "CUSTOM" ? customLabel : null,
            })
          }
          className="rounded-lg bg-cyan-400 px-3 py-2 text-sm font-semibold text-black"
        >
          Save correction
        </button>
      </div>
    </div>
  );
}

function StaffMappingTable(props: { markers: StaffMarker[]; geometryResolved: boolean }) {
  return (
    <div className="mt-3 overflow-x-auto">
      <table className="w-full min-w-[640px] text-left text-xs">
        <thead className="text-zinc-400">
          <tr>
            <th className="py-1 pr-2">Page</th>
            <th className="py-1 pr-2">System</th>
            <th className="py-1 pr-2">Physical staff</th>
            <th className="py-1 pr-2">Logical parts</th>
            <th className="py-1 pr-2">Color</th>
            <th className="py-1 pr-2">Source</th>
            <th className="py-1">Confidence</th>
          </tr>
        </thead>
        <tbody>
          {props.markers.map((marker) => (
            <tr key={marker.staffId} className="border-t border-zinc-800">
              <td className="py-1 pr-2">{marker.position?.page ?? "—"}</td>
              <td className="py-1 pr-2">{props.geometryResolved ? "1" : "unresolved"}</td>
              <td className="py-1 pr-2">{marker.staffId}</td>
              <td className="py-1 pr-2">{marker.logicalPartIds.join(", ")}</td>
              <td className="py-1 pr-2">
                <span className="mr-1 inline-block h-3 w-3 align-middle" style={{ backgroundColor: marker.color }} />
                {marker.label}
              </td>
              <td className="py-1 pr-2">{marker.source}</td>
              <td className="py-1">{marker.confidence}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
