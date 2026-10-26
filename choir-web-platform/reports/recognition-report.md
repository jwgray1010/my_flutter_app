# Rehearsal Keys recognition test

Ground truth for synthetic scores comes from the musical plan that generates the MusicXML. It is not the parser output.
Public-domain Bach chorales are read from the local music21 corpus at test time, cross-checked against the exported MusicXML, and are not stored in this repository.
Held-out scores are included only in this report. They are not part of `npm run test:score-recognition`.

## Component map

- PDF / image ingestion: src/app/api/my-music/process/route.ts and src/app/api/score/recognize/route.ts
- Add Pages: src/app/api/my-music/[id]/replace-pages/route.ts
- Audiveris integration: src/lib/server/omr/audiveris-provider.ts (AudiverisOMRService)
- Pipeline entry: src/lib/server/score-processing.ts processFileToParsedScore
- MusicXML parser: src/lib/musicxml.ts parseMusicXmlToScore
- There is no separate ScoreStructureAnalyzer, GlobalVoicingDiscovery, StaffMapper, ChoirMapper, MeasureParser, KeySignatureParser, RepeatNavigator, or PlaybackModelBuilder module.
- Rehearsal playback: src/lib/score-player.ts ScorePlayer, fed by already-parsed note events
- Unnamed voices are assigned by register in src/lib/voicing.ts. A part is piano when its name says so, or when it is a treble-plus-bass grand staff. Repeats are listed in performanceRoute and are not copied into the written measure list.

## Results

Scores selected: 33

Verified and scored: 33

Passed: 33/33

Failed: 0/33

Category counts are fixtures with no failure in that category. A fixture can fail more than one category. Pitch-event accuracy is a separate count of sounding notes.

| Category | Correct fixtures |
| --- | --- |
| voicing | 33/33 |
| accompaniment | 33/33 |
| logical-parts | 33/33 |
| entrance | 33/33 |
| measures | 33/33 |
| time-signature | 33/33 |
| key | 33/33 |
| pitch | 33/33 |
| duration | 33/33 |
| solo | 33/33 |
| playback-channels | 33/33 |
| performance-route | 33/33 |

Pitch/event matches: 2969/2969 (100.0% of expected sounding events).

Playback-channel notes left on UNKNOWN: 0/2969.

## Sets

- development: passed 18, failed 0, blocked 0
- regression: passed 10, failed 0, blocked 0
- heldout: passed 5, failed 0, blocked 0

## Against the baseline

Before fixes: 10/28 verified fixtures passed on the development and regression baseline.

After fixes: 33/33 verified fixtures passed in this run. This run's denominator includes every selected set, so it is larger than the baseline when the held-out set is included.

Resolved since baseline: dev-ssa-unnamed, dev-ssaa-unnamed, dev-ttbb-unnamed, dev-sab-unnamed, dev-tenor-octave, dev-a-minor, dev-key-change, dev-missing-backup, dev-ties, dev-cue-entrance, dev-choir-two-staves, dev-ssa-shared, dev-repeat, dev-volta, dev-solo, dev-unison, pd-bwv255, pd-bwv101-7.

New failures since baseline: none.

## Critical failures

None on the verified fixtures in this run.

## Blocked

None.

## Performance

Playback schedules were rebuilt from parsed notes only (33 scores x 200) in 21.2 ms. Pressing Play does not re-read MusicXML; ScorePlayer schedules the notes already on the parsed score.

Sequential fixture processing heap: 49.0 MB -> 171.2 MB. Fixtures are parsed one at a time and temporary files are deleted.

Audiveris jobs in the app are already one score at a time in AudiverisOMRService.

## Printed-page OMR probes

These render a synthetic score with Verovio and run the real Audiveris path in processFileToParsedScore. They are not counted in the fixture pass rate above. A missing key is left empty when the exported MusicXML has no key element.

- dev-unison: compared. OMR output differed. key: expected 1:C major; actual none. Voices: Unison. Measures: 4. Notes: 16.
- reg-shared-sa: compared. OMR output differed. key: expected 1:C major; actual none. Voices: SA. Measures: 4. Notes: 32.
- reg-sa-named: compared. OMR output differed. key: expected 1:C major; actual none. Voices: SA. Measures: 4. Notes: 32.
