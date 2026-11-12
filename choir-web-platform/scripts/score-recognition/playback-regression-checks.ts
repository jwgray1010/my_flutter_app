import { mergeMusicXmlPages } from "@/lib/server/omr/audiveris-provider";
import type { ParsedScore } from "@/lib/score-types";
import { interpretUnifiedScore } from "@/lib/unified-pipeline";

/**
 * Regressions that showed up as Alto 1 m.13, Bass 2 m.21, and Piano m.18.
 * The buttons are the same strings the rehearsal screen renders.
 */
export function runPlaybackRegressionChecks() {
  sharedStavesStaySatbWhenTheLayoutChanges();
  stableLayoutPagesStayOnePart();
  onePianoChannelKeepsLaterNotes();
  omittedRestDoesNotShiftTheNextMeasure();
  simultaneousVoicesDoNotRunInSequence();
  dottedNotesTupletsAndTiesKeepTheirTime();
  aLaterAltoJoinsTheOriginalAlto();
  twoOpeningSopranosStayDistinct();
  descantDoesNotReplaceTheChoir();
  console.log("Playback regression checks passed.");
}

function sharedStavesStaySatbWhenTheLayoutChanges() {
  const xml = mergeMusicXmlPages([
    { sheetNumber: 1, musicXml: sharedPage() },
    { sheetNumber: 2, musicXml: separatePage() },
    { sheetNumber: 3, musicXml: sharedPage("E", "B", "G", "E", "A", "D") },
  ]);
  const score = interpret(xml, 3);
  const buttons = rehearsalButtons(score);
  for (const required of ["Soprano", "Alto", "Tenor", "Bass", "Piano"]) {
    if (!buttons.includes(required)) {
      throw new Error(`Missing ${required}. Buttons: ${buttons.join(", ")}`);
    }
  }
  for (const button of buttons) {
    if (/\bm\.\d+/.test(button) || /\b(Alto|Bass|Soprano|Tenor|Piano) \d/.test(button)) {
      throw new Error(`A measure boundary created a channel: ${buttons.join(", ")}`);
    }
  }
  if (buttons.filter((button) => button === "Piano").length !== 1) {
    throw new Error(`Piano was split: ${buttons.join(", ")}`);
  }
  assertOnePart(score, "SOPRANO", [1, 2, 3]);
  assertOnePart(score, "ALTO", [1, 2, 3]);
  assertOnePart(score, "TENOR", [1, 2, 3]);
  assertOnePart(score, "BASS", [1, 2, 3]);
  const piano = score.scoreModel?.playback.channels.find((channel) => channel.group === "ACCOMPANIMENT");
  const pianoEvents = score.scoreModel?.playback.events.filter((event) => piano?.partIds.includes(event.partId)) ?? [];
  for (const measure of [1, 2, 3]) {
    const hands = pianoEvents.filter((event) => event.measureNumber === measure);
    if (hands.length < 2) {
      throw new Error(`Measure ${measure} kept ${hands.length} piano events in playback.`);
    }
  }
}

function stableLayoutPagesStayOnePart() {
  const page = (number: string, step: string) => `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1"><part-name>Soprano</part-name></score-part>
    <score-part id="P2"><part-name>Piano</part-name></score-part>
  </part-list>
  <part id="P1">${measure(number, true, `${note(step, 5, 1)}`)}</part>
  <part id="P2">${measure(number, true, `${note("C", 4, 1)}`, "F", 4)}</part>
</score-partwise>`;
  const xml = mergeMusicXmlPages([
    { sheetNumber: 1, musicXml: page("1", "C") },
    { sheetNumber: 2, musicXml: page("1", "D") },
  ]);
  const score = interpret(xml, 2);
  const soprano = score.parts.filter((part) => part.canonicalPart === "SOPRANO");
  if (soprano.length !== 1) {
    throw new Error(`A repeated page created ${soprano.length} soprano parts.`);
  }
  const buttons = rehearsalButtons(score);
  if (buttons.filter((button) => button.startsWith("Piano")).length !== 1) {
    throw new Error(`Stable piano pages became ${buttons.join(", ")}`);
  }
}

function onePianoChannelKeepsLaterNotes() {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1"><part-name>Soprano</part-name></score-part>
    <score-part id="P2"><part-name>Piano</part-name></score-part>
    <score-part id="P3"><part-name>Piano</part-name></score-part>
  </part-list>
  <part id="P1">
    ${measure("1", true, note("C", 5, 1))}
    ${measure("2", false, note("C", 5, 1))}
    ${measure("3", false, note("C", 5, 1))}
    ${measure("4", false, note("C", 5, 1))}
  </part>
  <part id="P2">
    ${measure("1", true, note("C", 3, 1), "F", 4)}
    ${measure("2", false, note("D", 3, 1))}
    ${measure("3", false, "")}
    ${measure("4", false, "")}
  </part>
  <part id="P3">
    ${measure("3", true, note("E", 3, 1), "F", 4)}
    ${measure("4", false, note("F", 3, 1))}
  </part>
</score-partwise>`;
  const score = interpret(xml, 1);
  const buttons = rehearsalButtons(score);
  if (buttons.some((button) => button.startsWith("Piano m."))) {
    throw new Error(`Later piano measures became channels: ${buttons.join(", ")}`);
  }
  const piano = score.scoreModel?.playback.channels.filter((channel) => channel.group === "ACCOMPANIMENT") ?? [];
  if (piano.length !== 1) {
    throw new Error(`Expected one piano channel, got ${piano.map((channel) => channel.label).join(", ")}`);
  }
  for (const [measure, midi] of [[1, 48], [2, 50], [3, 52], [4, 53]] as Array<[number, number]>) {
    const event = score.scoreModel?.playback.events.find(
      (candidate) => candidate.measureNumber === measure && candidate.midi === midi && piano[0].partIds.includes(candidate.partId)
    );
    if (!event) {
      throw new Error(`Piano ${midi} in measure ${measure} did not reach playback.`);
    }
    const written = score.measures.find((candidate) => candidate.displayNumber === measure);
    if (!written || event.scheduleBeat < written.startBeat || event.scheduleBeat >= written.endBeat) {
      throw new Error(`Piano measure ${measure} was scheduled outside the measure.`);
    }
  }
}

function omittedRestDoesNotShiftTheNextMeasure() {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list><score-part id="P1"><part-name>Soprano</part-name></score-part></part-list>
  <part id="P1">
    ${measure("1", true, note("C", 5, 1))}
    ${measure("2", false, `<note><pitch><step>D</step><octave>5</octave></pitch><duration>1</duration><voice>1</voice></note>`)}
    ${measure("3", false, note("E", 5, 1))}
  </part>
</score-partwise>`;
  const score = interpret(xml, 1);
  const third = score.notes.find((note) => note.measureNumber === 3);
  if (!third || Math.abs(third.startBeat - 8) > 0.001) {
    throw new Error(`Measure 3 started at beat ${third?.startBeat}, after a short measure 2.`);
  }
  if (Math.abs((score.measures[1]?.beatsInMeasure ?? 0) - 4) > 0.001) {
    throw new Error(`Measure 2 was shortened to ${score.measures[1]?.beatsInMeasure} beats.`);
  }
}

function simultaneousVoicesDoNotRunInSequence() {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list><score-part id="P1"><part-name>Soprano</part-name></score-part></part-list>
  <part id="P1">
    ${measure("1", true, [
      quarter("C", 5, 1),
      quarter("E", 4, 2),
      quarter("D", 5, 1),
      quarter("F", 4, 2),
    ].join(""))}
  </part>
</score-partwise>`;
  const score = interpret(xml, 1);
  const at = (midi: number) => score.notes.find((note) => note.midi === midi)?.startBeat;
  if (at(72) !== 0 || at(74) !== 1 || at(64) !== 0 || at(65) !== 1) {
    throw new Error(`Interleaved voices were sequenced: C ${at(72)}, D ${at(74)}, E ${at(64)}, F ${at(65)}.`);
  }
}

function dottedNotesTupletsAndTiesKeepTheirTime() {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list><score-part id="P1"><part-name>Soprano</part-name></score-part></part-list>
  <part id="P1">
    <measure number="1">
      <attributes><divisions>2</divisions><key><fifths>0</fifths><mode>major</mode></key><time><beats>4</beats><beat-type>4</beat-type></time><clef><sign>G</sign><line>2</line></clef></attributes>
      <note><pitch><step>C</step><octave>5</octave></pitch><duration>3</duration><voice>1</voice><dot/></note>
      <note><pitch><step>D</step><octave>5</octave></pitch><duration>1</duration><voice>1</voice></note>
      <note><pitch><step>E</step><octave>5</octave></pitch><duration>4</duration><voice>1</voice><tie type="start"/></note>
    </measure>
    <measure number="2">
      <note><pitch><step>E</step><octave>5</octave></pitch><duration>4</duration><voice>1</voice><tie type="stop"/></note>
    </measure>
    <measure number="3">
      <attributes><divisions>3</divisions></attributes>
      <note><pitch><step>F</step><octave>5</octave></pitch><duration>2</duration><voice>1</voice><time-modification><actual-notes>3</actual-notes><normal-notes>2</normal-notes></time-modification></note>
      <note><pitch><step>G</step><octave>5</octave></pitch><duration>2</duration><voice>1</voice><time-modification><actual-notes>3</actual-notes><normal-notes>2</normal-notes></time-modification></note>
      <note><pitch><step>A</step><octave>5</octave></pitch><duration>2</duration><voice>1</voice><time-modification><actual-notes>3</actual-notes><normal-notes>2</normal-notes></time-modification></note>
    </measure>
  </part>
</score-partwise>`;
  const score = interpret(xml, 1);
  const beat = (midi: number) => score.notes.find((note) => note.midi === midi);
  const dotted = beat(72);
  const eighth = beat(74);
  if (!dotted || !eighth || Math.abs(dotted.durationBeats - 1.5) > 0.001 || Math.abs(eighth.startBeat - 1.5) > 0.001) {
    throw new Error(`Dotted rhythm became ${dotted?.durationBeats} then beat ${eighth?.startBeat}.`);
  }
  const tied = score.notes.filter((note) => note.midi === 76);
  if (tied.length !== 1 || Math.abs(tied[0].durationBeats - 4) > 0.001) {
    throw new Error(`The tie stayed ${tied.length} notes of duration ${tied.map((note) => note.durationBeats).join(",")}.`);
  }
  const triplet = [77, 79, 81].map((midi) => beat(midi)?.startBeat);
  if (triplet[0] !== 8 || Math.abs((triplet[1] ?? 0) - (8 + 2 / 3)) > 0.001 || Math.abs((triplet[2] ?? 0) - (8 + 4 / 3)) > 0.001) {
    throw new Error(`Triplet onsets were ${triplet.join(", ")}.`);
  }
}

function aLaterAltoJoinsTheOriginalAlto() {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1"><part-name>Alto</part-name></score-part>
    <score-part id="P2"><part-name>Alto</part-name></score-part>
  </part-list>
  <part id="P1">
    ${measure("1", true, note("G", 4, 1))}
    ${measure("2", false, note("A", 4, 1))}
    ${measure("3", false, note("B", 4, 1))}
  </part>
  <part id="P2">
    ${measure("3", true, note("E", 4, 1))}
  </part>
</score-partwise>`;
  const score = interpret(xml, 1);
  const altos = score.parts.filter((part) => part.canonicalPart === "ALTO");
  if (altos.length !== 1) {
    throw new Error(`A later Alto staff became ${rehearsalButtons(score).join(", ")}.`);
  }
  const ids = new Set(score.notes.map((note) => note.partId));
  if (ids.size !== 1) {
    throw new Error("Alto notes were left on two logical parts.");
  }
}

function twoOpeningSopranosStayDistinct() {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1"><part-name>Soprano</part-name></score-part>
    <score-part id="P2"><part-name>Soprano</part-name></score-part>
  </part-list>
  <part id="P1">${measure("1", true, note("C", 5, 1))}</part>
  <part id="P2">${measure("1", true, note("A", 4, 1))}</part>
</score-partwise>`;
  const score = interpret(xml, 1);
  const sopranos = score.parts.filter((part) => part.canonicalPart === "SOPRANO");
  if (sopranos.length !== 2) {
    throw new Error("Two soprano lines that start together were collapsed.");
  }
}

function descantDoesNotReplaceTheChoir() {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1"><part-name>Descant</part-name></score-part>
    <score-part id="P2"><part-name>Soprano</part-name></score-part>
    <score-part id="P3"><part-name>Alto</part-name></score-part>
  </part-list>
  <part id="P1">${measure("1", true, note("B", 5, 1))}</part>
  <part id="P2">${measure("1", true, note("C", 5, 1))}</part>
  <part id="P3">${measure("1", true, note("G", 4, 1))}</part>
</score-partwise>`;
  const score = interpret(xml, 1);
  const buttons = rehearsalButtons(score);
  if (!buttons.includes("Soprano") || !buttons.includes("Alto") || !buttons.some((button) => button.toLowerCase().includes("descant"))) {
    throw new Error(`Descant changed the choir channels to ${buttons.join(", ")}.`);
  }
}

function assertOnePart(score: ParsedScore, canonical: "SOPRANO" | "ALTO" | "TENOR" | "BASS", measures: number[]) {
  const ids = measures.map((measure) => {
    const note = score.notes.find((candidate) => candidate.partCanonical === canonical && candidate.measureNumber === measure);
    if (!note) {
      throw new Error(`${canonical} has no note in measure ${measure}.`);
    }
    return note.partId;
  });
  if (new Set(ids).size !== 1) {
    throw new Error(`${canonical} changed identity across measures: ${ids.join(", ")}.`);
  }
}

function rehearsalButtons(score: ParsedScore) {
  return (score.scoreModel?.playback.channels ?? []).map((channel) => {
    const entrance = channel.entersAtMeasure != null && channel.entersAtMeasure > 1 ? ` m.${channel.entersAtMeasure}` : "";
    return `${channel.label}${entrance}`;
  });
}

function interpret(xml: string, pageCount: number) {
  return interpretUnifiedScore({
    xml,
    sourceType: "omr",
    sourceUploadType: "PDF",
    pageCount,
  });
}

function sharedPage(soprano = "C", alto = "G", tenor = "E", bass = "C", pianoRight = "C", pianoLeft = "G") {
  return `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1"><part-name>Voice</part-name></score-part>
    <score-part id="P2"><part-name>Voice</part-name></score-part>
    <part-group type="start" number="1"><group-symbol>brace</group-symbol></part-group>
    <score-part id="P3"><part-name>Piano</part-name></score-part>
    <score-part id="P4"><part-name>Piano</part-name></score-part>
    <part-group type="stop" number="1"/>
  </part-list>
  <part id="P1">${measure("1", true, `${label("Soprano", 30)}${label("Alto", 10)}${note(soprano, 5, 1)}${note(alto, 4, 2)}`)}</part>
  <part id="P2">${measure("1", true, `${label("Tenor", 30)}${label("Bass", 10)}${note(tenor, 4, 1)}${note(bass, 3, 2)}`)}</part>
  <part id="P3">${measure("1", true, note(pianoRight, 4, 1))}</part>
  <part id="P4">${measure("1", true, note(pianoLeft, 2, 1), "F", 4)}</part>
</score-partwise>`;
}

function separatePage() {
  return `<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="3.1">
  <part-list>
    <score-part id="P1"><part-name>Soprano</part-name></score-part>
    <score-part id="P2"><part-name>Alto</part-name></score-part>
    <score-part id="P3"><part-name>Tenor</part-name></score-part>
    <score-part id="P4"><part-name>Bass</part-name></score-part>
    <score-part id="P5"><part-name>Piano</part-name></score-part>
    <score-part id="P6"><part-name>Piano</part-name></score-part>
  </part-list>
  <part id="P1">${measure("1", true, `${label("Soprano", 20)}${note("D", 5, 1)}`)}</part>
  <part id="P2">${measure("1", true, `${label("Alto", 20)}${note("A", 4, 1)}`)}</part>
  <part id="P3">${measure("1", true, `${label("Tenor", 20)}${note("F", 4, 1)}`)}</part>
  <part id="P4">${measure("1", true, `${label("Bass", 12)}${note("D", 3, 1)}`, "F", 4)}</part>
  <part id="P5">${measure("1", true, note("E", 4, 1))}</part>
  <part id="P6">${measure("1", true, note("B", 2, 1), "F", 4)}</part>
</score-partwise>`;
}

function measure(number: string, attributes: boolean, body: string, clef = "G", line = 2) {
  const head = attributes
    ? `<attributes><divisions>1</divisions><key><fifths>0</fifths><mode>major</mode></key><time><beats>4</beats><beat-type>4</beat-type></time><clef><sign>${clef}</sign><line>${line}</line></clef></attributes>`
    : "";
  return `<measure number="${number}">${head}${body}</measure>`;
}

function note(step: string, octave: number, voice: number) {
  return `<note><pitch><step>${step}</step><octave>${octave}</octave></pitch><duration>4</duration><voice>${voice}</voice></note>`;
}

function quarter(step: string, octave: number, voice: number) {
  return `<note><pitch><step>${step}</step><octave>${octave}</octave></pitch><duration>1</duration><voice>${voice}</voice></note>`;
}

function label(text: string, y: number) {
  return `<direction><direction-type><words default-x="-12" default-y="${y}">${text}</words></direction-type></direction>`;
}
