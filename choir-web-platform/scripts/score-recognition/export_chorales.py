#!/usr/bin/env python3
"""Build independent ground truth for a few public-domain Bach chorales.

The music21 corpus is read at test time and is not copied into the repository.
Expected pitches come from music21. A separate MusicXML walk must agree on the
pitch multiset before a chorale is marked verified.
"""

from __future__ import annotations

import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

CHORALES = [
    {
        "id": "pd-bwv255",
        "corpus": "bach/bwv255",
        "set": "regression",
        "title": "Bach BWV 255",
    },
    {
        "id": "pd-bwv101-7",
        "corpus": "bach/bwv101.7",
        "set": "regression",
        "title": "Bach BWV 101.7",
    },
    {
        "id": "pd-bwv244-10",
        "corpus": "bach/bwv244.10",
        "set": "heldout",
        "title": "Bach BWV 244.10",
    },
    {
        "id": "pd-bwv286",
        "corpus": "bach/bwv286",
        "set": "heldout",
        "title": "Bach BWV 286",
    },
]

MAJOR = ["Cb", "Gb", "Db", "Ab", "Eb", "Bb", "F", "C", "G", "D", "A", "E", "B", "F#", "C#"]
MINOR = ["Ab", "Eb", "Bb", "F", "C", "G", "D", "A", "E", "B", "F#", "C#", "G#", "D#", "A#"]
STEPS = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def local(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def text_of(element: ET.Element | None) -> str | None:
    if element is None or element.text is None:
        return None
    value = element.text.strip()
    return value or None


def child(element: ET.Element, name: str) -> ET.Element | None:
    for item in element:
        if local(item.tag) == name:
            return item
    return None


def children(element: ET.Element, name: str) -> list[ET.Element]:
    return [item for item in element if local(item.tag) == name]


def key_label(fifths: int, mode: str) -> str:
    table = MINOR if mode == "minor" else MAJOR
    index = fifths + 7
    if index < 0 or index >= len(table):
        return f"{fifths} fifths"
    return f"{table[index]} {mode}"


def measure_number(raw: str | None, fallback: int) -> int:
    if not raw:
        return fallback
    digits = ""
    for char in raw.strip():
        if char.isdigit():
            digits += char
        else:
            break
    return int(digits) if digits else fallback


def walk_musicxml(path: Path) -> dict:
    root = ET.parse(path).getroot()
    part_nodes = [item for item in root if local(item.tag) == "part"]
    events: list[dict] = []
    times: list[str] = []
    beats: list[float] = []
    key_regions: list[dict] = []
    route: list[int] = []
    for part_index, part in enumerate(part_nodes):
        part_id = part.attrib.get("id") or f"P{part_index + 1}"
        divisions = 1
        clef_octave: dict[int, int] = {}
        open_ties: dict[str, dict] = {}
        cursor_beats = 0.0
        current_beats = 4
        current_beat_type = 4
        for measure_index, measure in enumerate(children(part, "measure")):
            number = measure_number(measure.attrib.get("number"), measure_index + 1)
            voice_end: dict[int, int] = {}
            global_cursor = 0
            current_voice = 1
            saw_position = True
            max_global = 0
            for node in list(measure):
                name = local(node.tag)
                if name == "attributes":
                    divisions_text = text_of(child(node, "divisions"))
                    if divisions_text:
                        divisions = max(1, int(float(divisions_text)))
                    time_node = child(node, "time")
                    if time_node is not None:
                        beats_text = text_of(child(time_node, "beats"))
                        beat_type_text = text_of(child(time_node, "beat-type"))
                        if beats_text:
                            current_beats = max(1, int(float(beats_text)))
                        if beat_type_text:
                            current_beat_type = max(1, int(float(beat_type_text)))
                    key_node = child(node, "key")
                    if key_node is not None and part_index == 0:
                        fifths = int(float(text_of(child(key_node, "fifths")) or "0"))
                        mode = (text_of(child(key_node, "mode")) or "major").lower()
                        if mode not in ("major", "minor"):
                            mode = "major"
                        region = {
                            "startMeasure": number,
                            "fifths": fifths,
                            "mode": mode,
                            "label": key_label(fifths, mode),
                        }
                        if not key_regions or (
                            key_regions[-1]["fifths"] != fifths or key_regions[-1]["mode"] != mode
                        ):
                            key_regions.append(region)
                    for clef in children(node, "clef"):
                        staff = int(clef.attrib.get("number") or "1")
                        octave = int(float(text_of(child(clef, "clef-octave-change")) or "0"))
                        clef_octave[staff] = octave
                    continue
                if name in ("backup", "forward"):
                    duration = int(float(text_of(child(node, "duration")) or "0"))
                    if name == "backup":
                        global_cursor = max(0, global_cursor - duration)
                    else:
                        global_cursor += duration
                    saw_position = True
                    max_global = max(max_global, global_cursor)
                    continue
                if name != "note":
                    continue
                if child(node, "grace") is not None:
                    continue
                is_cue = child(node, "cue") is not None
                is_rest = child(node, "rest") is not None
                is_chord = child(node, "chord") is not None
                duration = int(float(text_of(child(node, "duration")) or "0"))
                voice = int(float(text_of(child(node, "voice")) or "1"))
                staff = int(float(text_of(child(node, "staff")) or "1"))
                if not is_chord and not is_cue:
                    if not saw_position and voice != current_voice and voice not in voice_end:
                        global_cursor = 0
                    current_voice = voice
                    saw_position = False
                    voice_end[voice] = global_cursor + duration
                    global_cursor += duration
                    max_global = max(max_global, global_cursor)
                if is_cue or is_rest or duration <= 0:
                    continue
                pitch = child(node, "pitch")
                if pitch is None:
                    continue
                step = text_of(child(pitch, "step")) or "C"
                octave = int(float(text_of(child(pitch, "octave")) or "4"))
                alter = int(float(text_of(child(pitch, "alter")) or "0"))
                midi = (octave + 1) * 12 + STEPS.get(step, 0) + alter + 12 * clef_octave.get(staff, 0)
                start = cursor_beats + (global_cursor - duration) / divisions
                if is_chord:
                    start = cursor_beats + (voice_end.get(voice, global_cursor) - duration) / divisions
                tie_types = [item.attrib.get("type") for item in node.iter() if local(item.tag) in ("tie", "tied")]
                event = {
                    "partId": part_id,
                    "startBeat": round(start, 4),
                    "midi": midi,
                    "duration": round(duration / divisions, 4),
                    "tieStart": "start" in tie_types,
                    "tieStop": "stop" in tie_types,
                }
                key = f"{part_id}|{midi}"
                previous = open_ties.get(key)
                if event["tieStop"] and previous and abs(previous["startBeat"] + previous["duration"] - event["startBeat"]) < 0.02:
                    previous["duration"] = round(previous["duration"] + event["duration"], 4)
                    previous["tieStart"] = event["tieStart"]
                    if not event["tieStart"]:
                        open_ties.pop(key, None)
                else:
                    events.append(event)
                    if event["tieStart"]:
                        open_ties[key] = event
            nominal = current_beats * (4 / current_beat_type)
            content = (max(voice_end.values()) / divisions) if voice_end else 0
            length = content if content > 0 else nominal
            if part_index == 0:
                times.append(f"{current_beats}/{current_beat_type}")
                beats.append(round(length, 4))
                route.append(number)
            cursor_beats += length
    cleaned = [
        {key: value for key, value in event.items() if key not in ("tieStart", "tieStop")}
        for event in events
    ]
    return {
        "events": cleaned,
        "timeSignatures": times,
        "measureBeats": beats,
        "keyRegions": key_regions,
        "performanceRoute": route,
        "writtenMeasureCount": len(route),
    }


def music21_events(score) -> list[dict]:
    from music21 import note as note_module

    events = []
    for index, part in enumerate(score.parts):
        part_id = f"P{index + 1}"
        stripped = part.stripTies(inPlace=False)
        for item in stripped.recurse().notes:
            if item.duration.isGrace:
                continue
            offset = float(item.getOffsetInHierarchy(stripped))
            if item.isChord:
                for pitch in item.pitches:
                    events.append(
                        {
                            "partId": part_id,
                            "startBeat": round(offset, 4),
                            "midi": int(pitch.midi),
                            "duration": round(float(item.quarterLength), 4),
                        }
                    )
            elif isinstance(item, note_module.Note):
                events.append(
                    {
                        "partId": part_id,
                        "startBeat": round(offset, 4),
                        "midi": int(item.pitch.midi),
                        "duration": round(float(item.quarterLength), 4),
                    }
                )
    return events


def multiset(events: list[dict]) -> dict[tuple, int]:
    counts: dict[tuple, int] = {}
    for event in events:
        key = (
            event["partId"],
            round(float(event["startBeat"]), 2),
            int(event["midi"]),
            round(float(event["duration"]), 2),
        )
        counts[key] = counts.get(key, 0) + 1
    return counts


def entrances(events: list[dict], measure_starts: list[tuple[int, float, float]]) -> list[dict]:
    by_part: dict[str, float] = {}
    for event in events:
        current = by_part.get(event["partId"])
        if current is None or event["startBeat"] < current:
            by_part[event["partId"]] = event["startBeat"]
    found = []
    for part_id, beat in by_part.items():
        measure = measure_starts[-1][0] if measure_starts else 1
        for number, start, length in measure_starts:
            if beat < start + length - 0.001:
                measure = number
                break
        found.append({"partId": part_id, "measure": measure})
    return found


def export_one(output_dir: Path, spec: dict) -> dict:
    from music21 import corpus

    score = corpus.parse(spec["corpus"])
    xml_path = output_dir / f"{spec['id']}.musicxml"
    written = Path(str(score.write("musicxml", fp=str(xml_path))))
    if written != xml_path and written.exists():
        written.replace(xml_path)
    xml_truth = walk_musicxml(xml_path)
    m21_events = music21_events(score)
    xml_counts = multiset(xml_truth["events"])
    m21_counts = multiset(m21_events)
    verified = xml_counts == m21_counts and len(m21_events) > 0
    names = [part.partName or "" for part in score.parts]
    canonical = []
    for name in names:
        lowered = name.lower()
        if "soprano" in lowered:
            canonical.append("S")
        elif "alto" in lowered:
            canonical.append("A")
        elif "tenor" in lowered:
            canonical.append("T")
        elif "bass" in lowered:
            canonical.append("B")
    voicing = {"S": 0, "A": 0, "T": 0, "B": 0}
    for initial in canonical:
        voicing[initial] += 1
    key = f"{voicing['S']},{voicing['A']},{voicing['T']},{voicing['B']}"
    voicing_label = {
        "1,1,1,1": "SATB",
        "1,1,0,0": "SA",
        "0,0,1,1": "TB",
        "2,2,2,2": "SSAATTBB",
    }.get(key, "Unknown")
    starts = []
    cursor = 0.0
    for number, length in zip(xml_truth["performanceRoute"], xml_truth["measureBeats"]):
        starts.append((number, cursor, length))
        cursor += length
    reason = None if verified else "music21 sounding events did not match an independent MusicXML walk"
    expected = {
        "voicing": voicing_label,
        "logicalPartCount": len(score.parts),
        "accompaniment": False,
        "pianoEntranceMeasure": None,
        "soloCount": 0,
        "writtenMeasureCount": xml_truth["writtenMeasureCount"],
        "timeSignatures": xml_truth["timeSignatures"],
        "measureBeats": xml_truth["measureBeats"],
        "keyRegions": xml_truth["keyRegions"],
        "performanceRoute": xml_truth["performanceRoute"],
        "entrances": entrances(m21_events if verified else [], starts),
        "events": m21_events if verified else [],
    }
    return {
        "id": spec["id"],
        "title": spec["title"],
        "set": spec["set"],
        "origin": "encoded-public-domain",
        "verified": verified,
        "unverifiedReason": reason,
        "xmlPath": str(xml_path),
        "expected": expected,
        "provenance": {
            "sourceUrl": "https://github.com/cuthbertLab/music21",
            "originalAuthor": "Johann Sebastian Bach",
            "license": "Musical work is public domain. The music21 corpus encoding is used at test runtime under the music21 corpus terms and is not redistributed in this repository.",
            "sourceFormat": "music21 corpus MusicXML (.mxl)",
            "referenceFormat": "music21 note offsets, cross-checked against the exported MusicXML",
            "downloadDate": "2026-10-25",
            "conversionMethod": "music21 corpus.parse + score.write('musicxml'); pitches from stripTies; rejected if the XML walk disagrees",
            "origin": "encoded-public-domain",
            "corpusPath": spec["corpus"],
        },
    }


def main() -> None:
    output_dir = Path(sys.argv[1])
    output_dir.mkdir(parents=True, exist_ok=True)
    fixtures = [export_one(output_dir, spec) for spec in CHORALES]
    manifest = output_dir / "manifest.json"
    manifest.write_text(json.dumps(fixtures, indent=2), encoding="utf-8")
    verified = sum(1 for fixture in fixtures if fixture["verified"])
    print(f"verified {verified}/{len(fixtures)} chorales -> {manifest}")


if __name__ == "__main__":
    main()
