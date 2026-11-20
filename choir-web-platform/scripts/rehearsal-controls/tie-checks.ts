import { JSDOM } from "jsdom";
import { applyTieEdits } from "@/lib/score-corrections";
import { parseMusicXmlToScore } from "@/lib/musicxml";
import { scheduleAttacks } from "@/lib/ties";

const dom = new JSDOM("");
(globalThis as { DOMParser: typeof window.DOMParser }).DOMParser = dom.window.DOMParser;

function assert(condition: unknown, message: string) {
  if (!condition) {
    throw new Error(message);
  }
}

function scoreFrom(parts: string) {
  const xml = `<?xml version="1.0"?>
    <score-partwise version="3.1">
      <part-list>
        <score-part id="P1"><part-name>Soprano</part-name></score-part>
        <score-part id="P2"><part-name>Alto</part-name></score-part>
        <score-part id="P3"><part-name>Tenor</part-name></score-part>
        <score-part id="P4"><part-name>Bass</part-name></score-part>
        <score-part id="Piano"><part-name>Piano</part-name></score-part>
      </part-list>
      ${parts}
    </score-partwise>`;
  return parseMusicXmlToScore(xml, "musicxml");
}

const attrs = `<attributes><divisions>2</divisions><time><beats>4</beats><beat-type>4</beat-type></time></attributes>`;

function pitch(step: string, octave = 4) {
  return `<pitch><step>${step}</step><octave>${octave}</octave></pitch>`;
}

function note(options: {
  step: string;
  octave?: number;
  duration: number;
  voice?: number;
  staff?: number;
  type?: string;
  tie?: "start" | "stop" | "both" | "none";
  chord?: boolean;
  slur?: boolean;
}) {
  const tie =
    options.tie === "start"
      ? `<tie type="start"/>`
      : options.tie === "stop"
        ? `<tie type="stop"/>`
        : options.tie === "both"
          ? `<tie type="stop"/><tie type="start"/>`
          : "";
  const tied =
    options.tie === "start"
      ? `<notations><tied type="start"/></notations>`
      : options.tie === "stop"
        ? `<notations><tied type="stop"/></notations>`
        : options.tie === "both"
          ? `<notations><tied type="stop"/><tied type="start"/></notations>`
          : options.slur
            ? `<notations><slur type="start"/></notations>`
            : "";
  const tiedOnly = options.type === "tied-only";
  const tieOnly = options.type === "tie-only";
  return `<note>
    ${options.chord ? "<chord/>" : ""}
    ${pitch(options.step, options.octave)}
    <duration>${options.duration}</duration>
    ${tiedOnly ? "" : tie}
    <voice>${options.voice ?? 1}</voice>
    ${options.staff ? `<staff>${options.staff}</staff>` : ""}
    <type>quarter</type>
    ${tieOnly ? "" : tied}
  </note>`;
}

function attacks(partId: string, notes: { partId: string; midi: number; startBeat: number; durationBeats: number }[]) {
  return scheduleAttacks(notes.filter((item) => item.partId === partId));
}

function quarterTiedToHalf() {
  const sequential = scoreFrom(`<part id="P1"><measure number="1">${attrs}
    ${note({ step: "C", duration: 2, tie: "start", type: "tie-only" })}
    ${note({ step: "C", duration: 4, tie: "stop", type: "tie-only" })}
  </measure></part>`);
  const sequentialPlay = attacks("P1", sequential.notes);
  assert(sequentialPlay.length === 1 && sequentialPlay[0].durationBeats === 3, "sequential quarter tied to half split");
  assert(sequentialPlay[0].noteOnCount === 1 && sequentialPlay[0].noteOffBeat === 3, "sequential tie is not one note-off at 3 beats");
  assert(sequential.notes[0]?.partCanonical === "SOPRANO" && sequential.notes[0].measureNumber === 1, "sequential tie lost part or measure");
  assert((sequential.notationNotes ?? []).length === 2, "written tie notes were destroyed");

  const chordCoded = scoreFrom(`<part id="P1"><measure number="1">${attrs}
    ${note({ step: "C", duration: 2, tie: "start" })}
    ${note({ step: "C", duration: 4, tie: "stop", chord: true })}
  </measure></part>`);
  const played = attacks("P1", chordCoded.notes);
  assert(played.length === 1, `same-onset tie made ${played.length} attacks`);
  assert(played[0].durationBeats === 3 && played[0].noteOnCount === 1, "chord-coded quarter tied to half is not one 3-beat sound");

  const reversed = scoreFrom(`<part id="P1"><measure number="1">${attrs}
    ${note({ step: "C", duration: 4, tie: "stop", chord: true })}
    ${note({ step: "C", duration: 2, tie: "start" })}
  </measure></part>`);
  const reversedPlay = attacks("P1", reversed.notes);
  assert(reversedPlay.length === 1 && reversedPlay[0].durationBeats === 3 && reversedPlay[0].startBeat === 0, "stop-before-start at the same onset stayed split");
}

function quarterTiedToQuarter() {
  const score = scoreFrom(`<part id="P1"><measure number="1">${attrs}
    ${note({ step: "D", duration: 2, tie: "start", type: "tied-only" })}
    ${note({ step: "D", duration: 2, tie: "stop", type: "tied-only" })}
  </measure></part>`);
  const played = attacks("P1", score.notes);
  assert(played.length === 1 && played[0].durationBeats === 2, "tied element alone did not sustain two quarters");
}

function acrossBarlineSystemAndPage() {
  const score = scoreFrom(`<part id="P1">
    <measure number="1">${attrs}
      ${note({ step: "E", duration: 8, tie: "start" })}
    </measure>
    <measure number="2"><print new-system="yes"/>
      ${note({ step: "E", duration: 8, tie: "both" })}
    </measure>
    <measure number="3"><print new-page="yes"/>
      ${note({ step: "E", duration: 4, tie: "stop" })}
    </measure>
  </part>`);
  const played = attacks("P1", score.notes);
  assert(played.length === 1, `system and page tie made ${played.length} attacks`);
  assert(played[0].durationBeats === 10, `chain duration ${played[0].durationBeats}`);
  assert(played[0].startBeat === 0, "tie chain moved the attack");
}

function threeNoteChain() {
  const score = scoreFrom(`<part id="P1"><measure number="1">${attrs}
    ${note({ step: "F", duration: 2, tie: "start" })}
    ${note({ step: "F", duration: 2, tie: "both" })}
    ${note({ step: "F", duration: 4, tie: "stop" })}
  </measure></part>`);
  const played = attacks("P1", score.notes);
  assert(played.length === 1 && played[0].durationBeats === 4, "three-note tie is not one 4-beat sound");
}

function outOfOrderStop() {
  const score = scoreFrom(`<part id="P1"><measure number="1">${attrs}
    <forward><duration>2</duration></forward>
    ${note({ step: "G", duration: 4, tie: "stop" })}
    <backup><duration>6</duration></backup>
    ${note({ step: "G", duration: 2, tie: "start" })}
  </measure></part>`);
  const played = attacks("P1", score.notes);
  assert(played.length === 1 && played[0].durationBeats === 3 && played[0].startBeat === 0, "out-of-order tie stop stayed a second attack");
}

function sharedStaffKeepsVoices() {
  const measures = [1, 2, 3]
    .map((number) => {
      const soprano =
        number === 1
          ? `${note({ step: "C", duration: 2, tie: "start", voice: 1 })}${note({ step: "C", duration: 2, tie: "stop", voice: 1 })}${note({ step: "D", duration: 2, voice: 1 })}${note({ step: "E", duration: 2, voice: 1 })}`
          : `${note({ step: "D", duration: 2, voice: 1 })}${note({ step: "E", duration: 2, voice: 1 })}${note({ step: "F", duration: 2, voice: 1 })}${note({ step: "G", duration: 2, voice: 1 })}`;
      const alto = `${note({ step: "B", duration: 2, voice: 2 })}${note({ step: "C", duration: 2, voice: 2 })}${note({ step: "G", duration: 2, voice: 2 })}${note({ step: "A", duration: 2, voice: 2 })}`;
      return `<measure number="${number}">${number === 1 ? attrs : ""}${soprano}<backup><duration>8</duration></backup>${alto}</measure>`;
    })
    .join("");
  const score = parseMusicXmlToScore(
    `<?xml version="1.0"?><score-partwise><part-list><score-part id="P1"><part-name>Soprano/Alto</part-name></score-part></part-list><part id="P1">${measures}</part></score-partwise>`,
    "musicxml"
  );
  const soprano = score.parts.find((part) => part.voiceNumber === 1);
  const alto = score.parts.find((part) => part.voiceNumber === 2);
  assert(soprano?.id === "P1:v1" && soprano.canonicalPart === "SOPRANO", "soprano logical part changed");
  assert(alto?.id === "P1:v2" && alto.canonicalPart === "ALTO", "alto logical part changed");
  const sopranoAttacks = attacks(soprano!.id, score.notes);
  const altoAttacks = attacks(alto!.id, score.notes);
  const sustained = sopranoAttacks.find((item) => item.midi === 60 && item.startBeat === 0);
  assert(sustained?.durationBeats === 2 && sustained.noteOnCount === 1, "soprano tie did not sustain");
  assert(score.notes.find((item) => item.partId === soprano!.id && item.midi === 60)?.measureNumber === 1, "tie left its measure");
  assert(altoAttacks.length === 12, `alto notes changed: ${altoAttacks.length}`);
  assert(
    altoAttacks.some((item) => item.midi === 60 && item.startBeat === 1 && item.durationBeats === 1),
    "alto same pitch was swallowed by the soprano tie"
  );
}

function partialPianoChord() {
  const score = scoreFrom(`<part id="Piano"><measure number="1">${attrs}
    ${note({ step: "C", octave: 3, duration: 2, tie: "start", staff: 1 })}
    ${note({ step: "E", octave: 3, duration: 2, chord: true, staff: 1 })}
    ${note({ step: "C", octave: 3, duration: 4, tie: "stop", staff: 1 })}
    ${note({ step: "G", octave: 3, duration: 2, chord: true, staff: 1 })}
  </measure></part>`);
  const piano = score.parts.find((part) => part.canonicalPart === "PIANO");
  assert(piano?.id === "Piano", "piano identity changed");
  const played = attacks(piano!.id, score.notes);
  const lows = played.filter((item) => item.midi === 48);
  const others = played.filter((item) => item.midi !== 48);
  assert(lows.length === 1 && lows[0].durationBeats === 3, "tied piano pitch was reattacked");
  assert(others.length === 2 && others.every((item) => item.durationBeats === 1), "untied chord tones were merged");
}

function slurAndUntiedRepeat() {
  const slur = scoreFrom(`<part id="P1"><measure number="1">${attrs}
    ${note({ step: "C", duration: 2, slur: true })}
    ${note({ step: "E", duration: 2, slur: true })}
    ${note({ step: "C", duration: 2, slur: true })}
    ${note({ step: "C", duration: 2, slur: true })}
    ${note({ step: "C", duration: 2, tie: "start" })}
    ${note({ step: "D", duration: 2 })}
  </measure></part>`);
  const played = attacks("P1", slur.notes);
  assert(played.length === 6, "slur or untied repeat was merged");
  assert(played.filter((item) => item.midi === 60).length === 4, "same-pitch slur or dangling tie was sustained");
}

function repeatBoundaryDoesNotJoinVisits() {
  const score = scoreFrom(`<part id="P1">
    <measure number="1">${attrs}
      <barline location="left"><repeat direction="forward"/></barline>
      ${note({ step: "C", duration: 4, tie: "start" })}
      ${note({ step: "C", duration: 4, tie: "stop" })}
    </measure>
    <measure number="2">
      ${note({ step: "C", duration: 8, tie: "start" })}
      <barline location="right"><repeat direction="backward"/></barline>
    </measure>
  </part>`);
  const played = attacks("P1", score.notes);
  assert(played.length === 2, "repeat boundary changed the tie attacks");
  assert(played[0].durationBeats === 4 && played[1].durationBeats === 4, "a tie was sustained across the repeat jump or a real tie was split");
}

function tempoChangeKeepsBeatDuration() {
  const score = scoreFrom(`<part id="P1"><measure number="1">${attrs}
    ${note({ step: "C", duration: 2, tie: "start" })}
    ${note({ step: "C", duration: 6, tie: "stop" })}
  </measure></part>`);
  const scheduled = scheduleAttacks(score.notes, {
    points: [
      { startBeat: 0, bpm: 120 },
      { startBeat: 2, bpm: 60 },
    ],
    fallbackBpm: 120,
    percent: 100,
  });
  assert(scheduled[0].durationBeats === 4, "tempo change rewrote the tie length in beats");
  assert(Math.abs(scheduled[0].durationSeconds - 3) < 0.001, `tempo-map seconds ${scheduled[0].durationSeconds}`);
  assert(scheduled[0].noteOnCount === 1, "tempo change created another attack");
}

function directorCorrectionDoesNotReparse() {
  const score = scoreFrom(`<part id="P1"><measure number="1">${attrs}
    ${note({ step: "A", duration: 2 })}
    ${note({ step: "A", duration: 2 })}
  </measure></part>`);
  const before = score.notes.length;
  assert(before === 2 && (score.notationNotes ?? []).length === 2, "untied notes were already combined");
  applyTieEdits(score, [
    {
      sourcePartId: "P1",
      voice: 1,
      staff: 1,
      midi: 69,
      startBeat: 0,
      tieStart: true,
      tieStop: false,
    },
    {
      sourcePartId: "P1",
      voice: 1,
      staff: 1,
      midi: 69,
      startBeat: 1,
      tieStart: false,
      tieStop: true,
    },
  ]);
  const played = attacks("P1", score.notes);
  assert(played.length === 1 && played[0].durationBeats === 2, "director tie did not sustain");
  assert((score.notationNotes ?? []).length === 2, "director edit destroyed the written notes");
  assert(score.parts.length === 1 && score.parts[0].id === "P1", "director tie changed the part");
  applyTieEdits(score, [
    {
      sourcePartId: "P1",
      voice: 1,
      staff: 1,
      midi: 69,
      startBeat: 0,
      tieStart: false,
      tieStop: false,
    },
    {
      sourcePartId: "P1",
      voice: 1,
      staff: 1,
      midi: 69,
      startBeat: 1,
      tieStart: false,
      tieStop: false,
    },
  ]);
  assert(attacks("P1", score.notes).length === 2, "removing a tie did not restore two attacks");
  assert((score.notationNotes ?? []).length === 2, "removing a tie destroyed the written notes");
}

function accompanimentSurvivesTie() {
  const score = scoreFrom(`
    <part id="P1"><measure number="1">${attrs}
      ${note({ step: "C", octave: 5, duration: 2, tie: "start" })}
      ${note({ step: "C", octave: 5, duration: 4, tie: "stop" })}
    </measure></part>
    <part id="Piano"><measure number="1">${attrs}
      ${note({ step: "G", octave: 3, duration: 2, staff: 1 })}
      ${note({ step: "C", octave: 3, duration: 2, staff: 2 })}
    </measure></part>
  `);
  const piano = score.parts.find((part) => part.canonicalPart === "PIANO");
  assert(piano?.id === "Piano", "piano channel changed");
  assert(attacks("P1", score.notes).length === 1, "choir tie reattacked beside the piano");
  assert(attacks(piano!.id, score.notes).length === 2, "piano notes were lost beside a tie");
}

function separateSatbStaysPut() {
  const one = (id: string, step: string, octave: number, tie = false) =>
    `<part id="${id}"><measure number="1">${attrs}
      ${note({ step, octave, duration: 2, tie: tie ? "start" : "none" })}
      ${note({ step, octave, duration: 2, tie: tie ? "stop" : "none" })}
    </measure></part>`;
  const score = scoreFrom(
    [one("P1", "C", 5, true), one("P2", "A", 4), one("P3", "F", 3), one("P4", "C", 3)].join("")
  );
  assert(score.parts.map((part) => part.canonicalPart).join(",") === "SOPRANO,ALTO,TENOR,BASS", "SATB identities moved");
  assert(attacks("P1", score.notes).length === 1, "soprano tie reattacked");
  assert(["P2", "P3", "P4"].every((id) => attacks(id, score.notes).length === 2), "other parts lost notes");
}

quarterTiedToHalf();
quarterTiedToQuarter();
acrossBarlineSystemAndPage();
threeNoteChain();
outOfOrderStop();
sharedStaffKeepsVoices();
partialPianoChord();
slurAndUntiedRepeat();
repeatBoundaryDoesNotJoinVisits();
tempoChangeKeepsBeatDuration();
directorCorrectionDoesNotReparse();
accompanimentSurvivesTie();
separateSatbStaysPut();
console.log("Tie checks passed.");
