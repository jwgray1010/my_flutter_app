import { JSDOM } from "jsdom";
import { applyManualCorrections, emptyManualCorrections } from "@/lib/score-corrections";
import { parseMusicXmlToScore } from "@/lib/musicxml";
import { buildStaffMarkers } from "@/lib/staff-colors";
import { audibleCanonical } from "@/lib/shared-voices";
import { inferChoirVoicing } from "@/lib/voicing";
import type { CanonicalPartId } from "@/lib/score-types";

const dom = new JSDOM("");
(globalThis as { DOMParser: typeof window.DOMParser }).DOMParser = dom.window.DOMParser;

function assert(condition: unknown, message: string) {
  if (!condition) {
    throw new Error(message);
  }
}

function xml(name: string, body: string) {
  return parseMusicXmlToScore(
    `<?xml version="1.0"?><score-partwise><part-list><score-part id="P1"><part-name>${name}</part-name></score-part></part-list><part id="P1">${body}</part></score-partwise>`,
    "musicxml"
  );
}

const attrs = `<attributes><divisions>1</divisions><time><beats>4</beats><beat-type>4</beat-type></time></attributes>`;

function pitched(step: string, octave: number, duration: number, voice: number, rest = false) {
  return `<note>${rest ? "<rest/>" : `<pitch><step>${step}</step><octave>${octave}</octave></pitch>`}<duration>${duration}</duration><voice>${voice}</voice><type>quarter</type></note>`;
}

function singleLineStaysTwoParts() {
  const measures = [1, 2, 3, 4]
    .map(
      (number) =>
        `<measure number="${number}">${number === 1 ? attrs : ""}${pitched("C", 5, 1, 1)}${pitched("D", 5, 1, 1)}${pitched("E", 5, 1, 1)}${pitched("F", 5, 1, 1)}</measure>`
    )
    .join("");
  const score = xml("Soprano/Alto", measures);
  const soprano = score.parts.find((part) => part.id === "P1:v1");
  const alto = score.parts.find((part) => part.id === "P1:v2");
  assert(soprano?.canonicalPart === "SOPRANO" && alto?.canonicalPart === "ALTO", "one printed line collapsed a shared staff");
  assert(score.notes.every((note) => note.partId === "P1:v1"), "the single line was copied onto both parts");
  assert(score.notes.every((note) => !note.unisonPartIds?.length), "a single remaining line was treated as unison");
  assert(soprano?.needsConfirmation && alto?.needsConfirmation, "an ambiguous single line did not ask for confirmation");
  assert(inferChoirVoicing(score.parts) === "SA", `voicing ${inferChoirVoicing(score.parts)}`);
  const marker = buildStaffMarkers(score.parts)[0];
  assert(marker.color === "#e10600" && marker.role === "SOPRANO_ALTO", "shared staff marker left red");
  assert(marker.innerVoices.length === 0, "an ambiguous single line drew split voice colors");
}

function restsDoNotBecomeUnison() {
  const body = `<measure number="1">${attrs}
    ${pitched("E", 4, 1, 1)}${pitched("F", 4, 1, 1)}${pitched("G", 4, 1, 1)}${pitched("A", 4, 1, 1)}
    <backup><duration>4</duration></backup>
    ${pitched("B", 4, 1, 2, true)}${pitched("B", 4, 1, 2, true)}${pitched("B", 4, 1, 2, true)}${pitched("B", 4, 1, 2, true)}
  </measure>`;
  const score = xml("Soprano/Alto", body);
  const soprano = score.parts.find((part) => part.voiceNumber === 1);
  const alto = score.parts.find((part) => part.voiceNumber === 2);
  assert(soprano?.canonicalPart === "SOPRANO" && alto?.canonicalPart === "ALTO", "rests collapsed the resting voice");
  assert(score.notes.length === 4 && score.notes.every((note) => note.partId === soprano?.id), "rests gave Alto the Soprano notes");
  assert(alto?.sharedPlacement === "resting" && !alto.needsConfirmation, "explicit rests stayed ambiguous");
  assert(!score.notes.some((note) => note.unisonPartIds?.length), "rests were played as unison");
}

function pitchCrossingKeepsVoiceOrder() {
  const body = [1, 2, 3, 4]
    .map(
      (number) => `<measure number="${number}">${number === 1 ? attrs : ""}
        ${pitched("C", 4, 1, 1)}${pitched("C", 4, 1, 1)}${pitched("D", 4, 1, 1)}${pitched("D", 4, 1, 1)}
        <backup><duration>4</duration></backup>
        ${pitched("C", 5, 1, 2)}${pitched("C", 5, 1, 2)}${pitched("D", 5, 1, 2)}${pitched("D", 5, 1, 2)}
      </measure>`
    )
    .join("");
  const score = xml("Soprano/Alto", body);
  const lower = score.parts.find((part) => part.voiceNumber === 1);
  const upper = score.parts.find((part) => part.voiceNumber === 2);
  assert(lower?.canonicalPart === "SOPRANO" && upper?.canonicalPart === "ALTO", "pitch crossing swapped the voices");
  assert(score.notes.filter((note) => note.partId === lower?.id).every((note) => note.midi < 72), "soprano received the upper notes");
  assert(score.notes.filter((note) => note.partId === upper?.id).every((note) => note.midi >= 72), "alto received the lower notes");
}

function numberedVoicesStaySeparate() {
  const body = [1, 2, 3]
    .map(
      (number) => `<measure number="${number}">${number === 1 ? attrs : ""}
        ${pitched("C", 5, 1, 1)}${pitched("D", 5, 1, 1)}
        <backup><duration>2</duration></backup>
        ${pitched("C", 5, 1, 2)}${pitched("E", 5, 1, 2)}
      </measure>`
    )
    .join("");
  const score = xml("Soprano 1 / Soprano 2", body);
  assert(score.parts.map((part) => part.canonicalPart).join(",") === "SOPRANO,SOPRANO", "numbered sopranos collapsed");
  assert(score.parts.map((part) => part.id).join(",") === "P1:v1,P1:v2", "numbered soprano ids moved");
  assert(inferChoirVoicing(score.parts) === "SS", `voicing ${inferChoirVoicing(score.parts)}`);
  assert(score.notes.filter((note) => note.partId === "P1:v2").some((note) => note.midi !== score.notes.find((item) => item.partId === "P1:v1")?.midi), "independent Soprano 2 notes were merged");
}

function tenorBassSingleLine() {
  const score = xml("Tenor/Bass", `<measure number="1">${attrs}${pitched("C", 3, 4, 1)}</measure>`);
  assert(score.parts.map((part) => `${part.id}:${part.canonicalPart}`).join(",") === "P1:v1:TENOR,P1:v2:BASS", "tenor/bass collapsed");
  assert(score.notes.length === 1 && score.notes[0].partId === "P1:v1", "the bass part received the only line");
}

function unisonPlaysOnce() {
  const body = `<measure number="1">${attrs}
      <direction><direction-type><words>unis.</words></direction-type></direction>
      ${pitched("G", 4, 1, 1)}${pitched("A", 4, 1, 1)}${pitched("B", 4, 1, 1)}${pitched("C", 5, 1, 1)}
    </measure>
    <measure number="2">
      <direction><direction-type><words>div.</words></direction-type></direction>
      ${pitched("G", 4, 1, 1)}${pitched("A", 4, 1, 1)}
      <backup><duration>2</duration></backup>
      ${pitched("E", 4, 1, 2)}${pitched("F", 4, 1, 2)}
    </measure>`;
  const score = xml("Soprano/Alto", body);
  const unison = score.notes.filter((note) => note.measureNumber === 1);
  const split = score.notes.filter((note) => note.measureNumber === 2);
  assert(unison.length === 4 && unison.every((note) => note.unisonPartIds?.includes("P1:v2")), "unison did not belong to both parts");
  assert(new Set(unison.map((note) => note.partId)).size === 1, "unison became two attacks");
  assert(split.length === 4 && split.every((note) => !note.unisonPartIds?.length), "divisi stayed one shared note");
  assert(split.filter((note) => note.partId === "P1:v2").length === 2, "alto lost its divisi notes");
  const both = new Set<CanonicalPartId>(["SOPRANO", "ALTO"]);
  const channels = unison.map((note) => audibleCanonical(note, score.parts, both));
  assert(channels.length === 4 && channels.every((channel) => channel === "SOPRANO"), "both parts selected played the unison twice");
  const altoOnly = unison.map((note) => audibleCanonical(note, score.parts, new Set<CanonicalPartId>(["ALTO"])));
  assert(altoOnly.every((channel) => channel === "ALTO"), "Alto alone lost the unison");
  const marker = buildStaffMarkers(score.parts)[0];
  assert(marker.color === "#e10600" && marker.innerVoices.length === 2, "split passage hid the inner voice colors");
}

function unisonWordAloneStaysRed() {
  const score = xml(
    "S / A",
    `<measure number="1">${attrs}<direction><direction-type><words>a 2</words></direction-type></direction>${pitched("C", 4, 4, 1)}</measure>`
  );
  assert(score.notes.length === 1 && score.notes[0].unisonPartIds?.includes("P1:v2"), "a 2 did not share the note");
  const marker = buildStaffMarkers(score.parts)[0];
  assert(marker.color === "#e10600" && marker.innerVoices.length === 0, "unison passage drew split colors");
  assert(score.parts.every((part) => part.sharedPlacement === "unison"), "unison placement was lost");
}

function plainVoiceStaysOnePart() {
  const score = xml("Voice", `<measure number="1">${attrs}${pitched("C", 4, 4, 1)}</measure>`);
  assert(score.parts.length === 1 && score.parts[0].id === "P1", "a unison choir line was split");
  assert(inferChoirVoicing(score.parts) === "Unison", `voicing ${inferChoirVoicing(score.parts)}`);
}

function directorConfirmsSharedStaff() {
  const score = xml("Voice", `<measure number="1">${attrs}${pitched("C", 5, 4, 1)}</measure>`);
  const corrections = emptyManualCorrections();
  corrections.staffIdentity = [
    {
      staffId: "P1:staff:1",
      role: "SOPRANO_ALTO",
      scope: "system",
      systemId: null,
      layoutKey: null,
      customColor: null,
      customLabel: null,
    },
  ];
  const next = applyManualCorrections(score, corrections);
  assert(next.parts.some((part) => part.canonicalPart === "SOPRANO"), "director confirmation dropped Soprano");
  assert(next.parts.some((part) => part.canonicalPart === "ALTO" && next.notes.every((note) => note.partId !== part.id)), "director confirmation copied the line onto Alto");
  assert(next.notes.length === 1, "director confirmation changed the written notes");
}

singleLineStaysTwoParts();
restsDoNotBecomeUnison();
pitchCrossingKeepsVoiceOrder();
numberedVoicesStaySeparate();
tenorBassSingleLine();
unisonPlaysOnce();
unisonWordAloneStaysRed();
plainVoiceStaysOnePart();
directorConfirmsSharedStaff();
console.log("Shared staff checks passed.");
