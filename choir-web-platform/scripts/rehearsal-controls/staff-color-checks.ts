import { JSDOM } from "jsdom";
import { buildStaffMarkers, physicalStaffId, type StaffCorrection } from "@/lib/staff-colors";
import { markerPercents, readStaffGeometry } from "@/lib/staff-geometry";
import type { RecognizedPart } from "@/lib/score-types";

const dom = new JSDOM("");
(globalThis as { DOMParser: typeof window.DOMParser }).DOMParser = dom.window.DOMParser;

function part(input: Partial<RecognizedPart> & Pick<RecognizedPart, "id" | "sourceName" | "canonicalPart">): RecognizedPart {
  return {
    staves: 1,
    sourcePartId: input.sourcePartId ?? input.id.split(":")[0],
    voiceNumber: input.voiceNumber ?? null,
    needsConfirmation: input.needsConfirmation ?? false,
    isSolo: input.isSolo ?? false,
    pitchRangeLow: null,
    pitchRangeHigh: null,
    firstMeasureNumber: 1,
    lastMeasureNumber: 4,
    ...input,
  };
}

function assert(condition: unknown, message: string) {
  if (!condition) {
    throw new Error(message);
  }
}

function separateSatb() {
  const markers = buildStaffMarkers([
    part({ id: "P1", sourceName: "Soprano", canonicalPart: "SOPRANO" }),
    part({ id: "P2", sourceName: "Alto", canonicalPart: "ALTO" }),
    part({ id: "P3", sourceName: "Tenor", canonicalPart: "TENOR" }),
    part({ id: "P4", sourceName: "Bass", canonicalPart: "BASS" }),
  ]);
  assert(markers.map((item) => item.color).join(",") === ["#f472b6", "#7e22ce", "#16a34a", "#ea580c"].join(","), markers.map((item) => item.role).join(","));
  assert(markers.every((item) => item.logicalPartIds.length === 1), "separate staves kept one logical part");
}

function combinedSatb() {
  const markers = buildStaffMarkers([
    part({ id: "P1:v1", sourcePartId: "P1", sourceName: "Soprano/Alto (voice 1)", canonicalPart: "SOPRANO", voiceNumber: 1 }),
    part({ id: "P1:v2", sourcePartId: "P1", sourceName: "Soprano/Alto (voice 2)", canonicalPart: "ALTO", voiceNumber: 2 }),
    part({ id: "P2:v1", sourcePartId: "P2", sourceName: "Tenor/Bass (voice 1)", canonicalPart: "TENOR", voiceNumber: 1 }),
    part({ id: "P2:v2", sourcePartId: "P2", sourceName: "Tenor/Bass (voice 2)", canonicalPart: "BASS", voiceNumber: 2 }),
  ]);
  assert(markers.length === 2, `combined staves produced ${markers.length} markers`);
  assert(markers[0].color === "#e10600" && markers[0].logicalPartIds.join(",") === "P1:v1,P1:v2", "shared upper staff is one red Soprano+Alto marker");
  assert(markers[1].color === "#1d4ed8" && markers[1].logicalPartIds.join(",") === "P2:v1,P2:v2", "shared lower staff is one blue Tenor+Bass marker");
}

function sharedThenSeparateKeepsLogicalIds() {
  const sharedIds = ["P1:v1", "P1:v2", "P2:v1", "P2:v2"];
  const shared = buildStaffMarkers([
    part({ id: "P1:v1", sourcePartId: "P1", sourceName: "Soprano/Alto", canonicalPart: "SOPRANO", voiceNumber: 1 }),
    part({ id: "P1:v2", sourcePartId: "P1", sourceName: "Soprano/Alto", canonicalPart: "ALTO", voiceNumber: 2 }),
    part({ id: "P2:v1", sourcePartId: "P2", sourceName: "Tenor/Bass", canonicalPart: "TENOR", voiceNumber: 1 }),
    part({ id: "P2:v2", sourcePartId: "P2", sourceName: "Tenor/Bass", canonicalPart: "BASS", voiceNumber: 2 }),
  ]);
  const separate = buildStaffMarkers([
    part({ id: "P1", sourceName: "Soprano", canonicalPart: "SOPRANO" }),
    part({ id: "P2", sourceName: "Alto", canonicalPart: "ALTO" }),
    part({ id: "P3", sourceName: "Tenor", canonicalPart: "TENOR" }),
    part({ id: "P4", sourceName: "Bass", canonicalPart: "BASS" }),
  ]);
  assert(shared.flatMap((item) => item.logicalPartIds).join(",") === sharedIds.join(","), "shared mapping changed logical ids");
  assert(separate.flatMap((item) => item.logicalPartIds).join(",") === "P1,P2,P3,P4", "separate mapping changed logical ids");
  assert(shared[0].role === "SOPRANO_ALTO" && separate[0].role === "SOPRANO", "configuration color did not follow the physical staff");
}

function pianoIntroductionIsYellow() {
  const markers = buildStaffMarkers([
    part({ id: "P1", sourceName: "Piano", canonicalPart: "PIANO", staves: 2 }),
  ]);
  assert(markers.length === 2, "piano grand staff should mark both staves");
  assert(markers.every((item) => item.color === "#eab308" && item.logicalPartIds.join(",") === "P1"), "both piano staves stay one instrument");
  assert(markers.every((item) => item.role === "PIANO"), "piano was classified as choir");
}

function soloDoesNotMoveChoir() {
  const choir = [
    part({ id: "P1", sourceName: "Soprano", canonicalPart: "SOPRANO" }),
    part({ id: "P2", sourceName: "Alto", canonicalPart: "ALTO" }),
    part({ id: "P3", sourceName: "Tenor", canonicalPart: "TENOR" }),
    part({ id: "P4", sourceName: "Bass", canonicalPart: "BASS" }),
  ];
  const before = buildStaffMarkers(choir).map((item) => item.logicalPartIds.join(","));
  const withSolo = buildStaffMarkers([
    part({ id: "P0", sourceName: "Descant", canonicalPart: "SOPRANO", isSolo: true }),
    ...choir,
  ]);
  const choirAfter = withSolo.filter((item) => item.role !== "DESCANT").map((item) => item.logicalPartIds.join(","));
  assert(choirAfter.join("|") === before.join("|"), "descant changed choir identities");
  assert(withSolo[0].role === "DESCANT" && withSolo[0].logicalPartIds.join(",") === "P0", "descant did not stay on its own staff");
}

function directorCorrectionWins() {
  const correction: StaffCorrection = {
    staffId: physicalStaffId("P1", 1),
    role: "ALTO",
    scope: "system",
    systemId: null,
    layoutKey: null,
    customColor: null,
    customLabel: null,
  };
  const markers = buildStaffMarkers(
    [part({ id: "P1", sourceName: "Soprano", canonicalPart: "SOPRANO" })],
    [correction]
  );
  assert(markers[0].role === "ALTO" && markers[0].source === "director" && markers[0].confidence === "confirmed", "director correction was overwritten");
}

function missingLayoutIsUnresolved() {
  const geometry = readStaffGeometry("<score-partwise></score-partwise>", ["P1:staff:1"]);
  assert(!geometry.resolved && Object.keys(geometry.positions).length === 0, "missing layout invented a position");
  const markers = buildStaffMarkers(
    [part({ id: "P1", sourceName: "Soprano", canonicalPart: "SOPRANO" })],
    [],
    geometry.positions
  );
  assert(markers[0].position == null, "unresolved geometry still placed a marker");
}

function explicitLayoutUsesNormalizedCoordinates() {
  const xml = `<?xml version="1.0"?>
    <score-partwise>
      <defaults>
        <page-layout>
          <page-height>1000</page-height>
          <page-width>800</page-width>
          <page-margins type="both">
            <left-margin>80</left-margin>
            <right-margin>40</right-margin>
            <top-margin>50</top-margin>
            <bottom-margin>40</bottom-margin>
          </page-margins>
        </page-layout>
        <system-layout>
          <top-system-distance>100</top-system-distance>
        </system-layout>
        <staff-layout>
          <staff-distance>90</staff-distance>
        </staff-layout>
      </defaults>
    </score-partwise>`;
  const ids = ["P1:staff:1", "P2:staff:1"];
  const geometry = readStaffGeometry(xml, ids);
  assert(geometry.resolved, geometry.reason ?? "layout should resolve");
  const first = geometry.positions[ids[0]];
  const second = geometry.positions[ids[1]];
  assert(first.y === 0.15, `first staff y ${first.y}`);
  assert(second.y === 0.24, `second staff y ${second.y}`);
  assert(first.x > 0 && first.x < 0.2, "marker is not in the left margin");
  const percents = markerPercents(first);
  assert(percents.top === "15%" && percents.left.endsWith("%"), "marker is not a normalized percent");
}

separateSatb();
combinedSatb();
sharedThenSeparateKeepsLogicalIds();
pianoIntroductionIsYellow();
soloDoesNotMoveChoir();
directorCorrectionWins();
missingLayoutIsUnresolved();
explicitLayoutUsesNormalizedCoordinates();
console.log("Staff color checks passed.");
