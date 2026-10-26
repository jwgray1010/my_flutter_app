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
- One musical interpreter: src/lib/unified-pipeline.ts interpretUnifiedScore. PDF and image uploads are normalized to ordered pages first.
- Structure, voicing evidence, and validation: src/lib/structure-discovery.ts. PlaybackRouteBuilder: src/lib/playback-model.ts buildPlaybackRoute.
- Rehearsal playback: src/lib/score-player.ts ScorePlayer reads the saved playback model and does not reparse MusicXML.
- Unlabeled voices stay UNKNOWN. Choir identity comes from a director lock, printed ensemble text, or part labels. Pitch order is not applied. A part is piano when its name says so, or when it is a treble-plus-bass grand staff. Repeats and navigation are listed in performanceRoute and are not copied into the written measure list.

## Results

Scores selected: 42

Verified and scored: 42

Passed: 42/42

Failed: 0/42

Category counts are fixtures with no failure in that category. A fixture can fail more than one category. Pitch-event accuracy is a separate count of sounding notes.

| Category | Correct fixtures |
| --- | --- |
| voicing | 42/42 |
| accompaniment | 42/42 |
| logical-parts | 42/42 |
| entrance | 42/42 |
| measures | 42/42 |
| time-signature | 42/42 |
| key | 42/42 |
| pitch | 42/42 |
| duration | 42/42 |
| solo | 42/42 |
| playback-channels | 42/42 |
| performance-route | 42/42 |

Pitch/event matches: 3553/3553 (100.0% of expected sounding events).

Playback-channel notes left on UNKNOWN: 803/3553.

## Sets

- development: passed 18, failed 0, blocked 0
- regression: passed 19, failed 0, blocked 0
- heldout: passed 5, failed 0, blocked 0

## Against the baseline

Before fixes: 10/28 verified fixtures passed on the development and regression baseline.

After fixes: 42/42 verified fixtures passed in this run. This run's denominator includes every selected set, so it is larger than the baseline when the held-out set is included.

Resolved since baseline: dev-ssa-unnamed, dev-ssaa-unnamed, dev-ttbb-unnamed, dev-sab-unnamed, dev-tenor-octave, dev-a-minor, dev-key-change, dev-missing-backup, dev-ties, dev-cue-entrance, dev-choir-two-staves, dev-ssa-shared, dev-repeat, dev-volta, dev-solo, dev-unison, pd-bwv255, pd-bwv101-7.

New failures since baseline: none.

## Critical failures

None on the verified fixtures in this run.

## Blocked

None.

## Performance

Playback schedules were rebuilt from parsed notes only (42 scores x 200) in 23.5 ms. Pressing Play does not re-read MusicXML; ScorePlayer schedules the notes already on the parsed score.

Sequential fixture processing heap: 72.7 MB -> 208.1 MB. Fixtures are parsed one at a time and temporary files are deleted.

Audiveris jobs in the app are already one score at a time in AudiverisOMRService.
