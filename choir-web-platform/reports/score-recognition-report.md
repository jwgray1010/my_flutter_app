# Rehearsal Keys recognition test

Scores tested: 33
Origin: 33 synthetic, 0 scanned editions

Public-domain downloads were not added. music21, LilyPond, MuseScore, and Audiveris are not installed here, and the inspected OpenScore/Mutopia candidates were not available as a small verified PDF-plus-MusicXML choral pair. These fixtures are labeled synthetic. Their answer key is the authored spec, checked against the generated MusicXML before the engine runs.

## Metrics

A score counts as correct for a metric when it has no failure in that category. Skipped OMR checks are excluded.

- voicing: 33/33
- accompaniment: 33/33
- logical-parts: 33/33
- featured: 33/33
- entrance: 33/33
- measures: 33/33
- key: 33/33
- meter: 33/33
- clef: 33/33
- route: 33/33
- notes: 33/33
- cross-upload consistency: 1/1 (same MusicXML, sourceType musicxml vs omr)
- legacy SATB pitch fallback calls: 0 observed (autoResolveUnknownParts is not in the parser)
- Audiveris OMR: skipped (/opt/audiveris/bin/Audiveris missing)

## Pipeline components actually in this repository

- PDF, image, and page replacement all call `processFileToParsedScore`.
- OMR provider: `AudiverisOMRService` via `buildOcrService`.
- MusicXML interpreter: `parseMusicXmlToScore`.
- Structure: `buildScoreStructure`, `buildKeySignatureRegions`, `readClefRegions`, `buildPlaybackRoute`.
- Part identity: `detectCanonicalPart`, `detectSubstantiveVoices`, `detectPairedVoiceNames`.
- Voicing label: `deriveMainChoirVoicing`.
- Playback: `ScorePlayer`, which does not import the parser or Audiveris.
- There is no separate type named ScoreStructureAnalyzer, GlobalVoicingDiscovery, StaffMapper, ChoirMapper, MeasureParser, KeySignatureParser, RepeatNavigator, or PlaybackModelBuilder.

## Performance

- Interpretation of 33 scores: 734 ms
- Heap delta: 72761 KiB
- Play path re-parses notation: no
- Browser Play/Stop was not exercised in this environment because there is no audio device. That check is skipped, not passed.

## Before this cycle

Development fixtures passing before the general fixes: 13/26. Failing: 13.

## Fixes in this cycle

- `deriveMainChoirVoicing` keeps one letter per printed choir part, so SSA, SSAA, TTBB, and SSAATTBB no longer collapse to a set of unique letters.
- Generic Part/Voice labels become UNISON or N-PART. They are not assigned Soprano, Alto, Tenor, or Bass.
- Solo, descant, cue, optional, and featured names are featured parts. They stay playable and are excluded from main-choir voicing.
- Baritone is recognized as its own logical part, which is what SAB needs.
- Saved-score texture labels use that same voicing function.
- Retest after those changes: development 26/26, regression 3/3, held-out 4/4, and the existing score-structure suite 12/12.
- Held-out scores were not given fixture-specific rules. They passed under the same part-name and voicing rules.

## After this cycle

- Development: 26/26 scores with no failures
- Regression: 3/3
- Held-out: 4/4

Critical failing checks: 0

No failing checks in the selected run.