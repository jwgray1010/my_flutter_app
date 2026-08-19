# my_flutter_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Choir Accompanist Voice Mode (PTT)

Voice control is push-to-talk only (no always-listening mode).

### How to test in rehearsal

1. Open the **Main Player** role on iPad.
2. Load a MusicXML score.
3. Hold the MIC button (top-right), speak, then release.
4. Check toast feedback:
   - success example: `Jump to measure 32`
   - failure example: `Didn't catch that.`
5. Try commands:
   - `play`, `pause`
   - `measure 32`
   - `slower`, `faster`
   - `loop measures 48 to 56`
   - `only altos`
   - `piano off`
   - `play starting pitches`

### Choir Room Mode

- Toggle **Choir Room Mode** in the voice safety card.
- This raises confidence threshold.
- Optional wake phrase can be required (`Podium` / `Maestro`).

### Notes

- Uses Apple Speech framework on iOS (`en-US`).
- Prefers on-device recognition when available.
- All commands are deterministic and mapped to the local command bus.

## Roku-Style Remote (iPhone) Pairing

1. On iPad **Main Player**, tap **Pair Remote**.
2. A QR payload is shown with local IP, port, and token.
3. On iPhone **Remote**, tap the QR scan icon and scan the code.
4. Remote stores the pairing profile and auto-reconnects on next launch.

### Remote command transport

- Local LAN only (WebSocket).
- Message envelope:
  - Remote -> Player: `{ "type":"COMMAND", "command":"...", "args":{...} }`
  - Player -> Remote: `{ "type":"STATE", "payload":{...} }`
- Token mismatch is rejected by player.

## Student Practice Mode + Teacher View (Local Only)

### Teacher flow (iPad Player)

1. Tap **Start Class Session** on Main Player.
2. Enter optional class name.
3. Player generates class `sessionId` and class pairing token.
4. Tap **Class QR** and show QR to students.
5. Open **Teacher View**:
   - Live roster (name, part, status, measure, tempo, current session)
   - Completion summary (minutes, sessions completed, last activity)
   - Trouble spots (most-looped ranges, most-visited measures)
6. Use **Export CSV** in Teacher View to share report.

### Student flow (iPhone)

1. Open iPhone role and choose **Student Practice**.
2. Scan class QR (`mode: class_session`).
3. Enter display name + choose part (S/A/T/B), then join session.
4. Select a practice preset and practice with locked controls:
   - Play/Pause
   - Back 1 / Back 2
   - Loop toggle (if enabled by teacher preset)
   - Tempo +/- within limited range
   - Mark Complete

### Student event messages

- `JOIN_CLASS_SESSION`
- `START_PRACTICE_SESSION`
- `PRACTICE_EVENT`
- `PRACTICE_SUMMARY`

Class session logs are stored locally on device (no cloud/auth).

## Station Mode (Single-Session Stations)

Station Mode replaces the broader student-session flow with a simpler in-school setup:

### Teacher (iPad Player)

1. Start a class session.
2. Open **Teacher View** and configure stations (S/A/T/B), each with exactly one locked range.
3. For each station, set:
   - Station name
   - Start / end measure
   - Default tempo
   - Loop default on/off
4. Tap **Generate Station QR** for each station.

### Station device (iPhone)

1. Open **Station Mode**.
2. Scan station QR once (`mode: station_single`).
3. Students rotate:
   - tap **I'M STARTING**
   - enter name
   - practice with locked controls in assigned range
   - tap **DONE / NEXT STUDENT**

### Station controls

- Play/Pause
- Back/Forward step (default 2 measures)
- Tempo +/- (clamped)
- Loop toggle, Set A, Set B, Clear loop
- Optional in-range measure grid (when enabled)
- Strict range lock clamps out-of-range movement

### Station event messages

- `REGISTER_STATION`
- `JOIN_STATION`
- `PRACTICE_EVENT`
- `PRACTICE_SUMMARY`
- `PRACTICE_COMPLETED`

## Sectional Corrector: Check-In Ladder

Station Mode now includes a 5-tier **Check-In** flow:

1. Part With Me (scored)
2. A Cappella + Click (scored)
3. Part + Accompaniment (scored)
4. Accompaniment Only (challenge)
5. Accompaniment + Other Parts (challenge)

### Scored tiers (1-3)

- Run noise check (ambient RMS)
- Starting pitch + count-in
- Record live mic stream on-device (no raw audio saved by default)
- Compute per-measure pitch/timing/confidence scores
- Return:
  - `PASS`, `NEEDS_WORK`, or `LOW_CONFIDENCE`
  - top trouble measures (max 3)
  - one-tap **Practice flagged spot** (loop + tempo 70%)

### Challenge tiers (4-5)

- No pass/fail scoring
- Completion tracked by metrics (`timeOnTaskSeconds` / loop reps)
- Result recorded as `CHALLENGE_COMPLETED` when threshold is reached

### Teacher View additions

- Latest check-in status per student
- Highest scored tier passed (1-3)
- Challenge completion checkmarks (tiers 4-5)
- Most common trouble measures by station
- Director Gate clearance status and filters

### Director Gate (optional)

Class Session setup now includes a configurable **Director Gate**:

- Gate Enabled: ON/OFF
- Required clearance tier: 1 / 2 / 3 (scored tiers only)
- Validity window:
  - This rehearsal only
  - Today
  - Custom minutes
- Low confidence behavior:
  - Does not count
  - Counts as attempt only
- Retry rule:
  - Unlimited retries
  - Optional retry cooldown (seconds)

When gate is enabled, a student is marked **CLEARED** only after passing the required scored tier within the validity window.
Challenge tiers never grant clearance.

### Check-in logging payload

- `CHECKIN_RESULT`
  - `studentId`
  - `studentName`
  - `stationId`
  - `tier`
  - `result`
  - `timeOnTaskSeconds`
  - `troubleMeasures`
  - `timestamp`

### Clearance event payload

- `CLEARANCE_STATUS`
  - `studentId`
  - `stationId`
  - `status` (`NOT_CLEARED` / `CLEARED` / `LOW_CONFIDENCE`)
  - `requiredTier`
  - `expiresAt`

## Warmups Library (iPad Player)

Warmups now has a dedicated flow on the Player side:

1. Player Home -> **Warmups**
2. Choose **Category**
3. Choose **Level** (Middle / Lower HS / Upper HS)
4. Choose warmup
5. Run in **Warmup Player**

### Included library structure

- 12 categories:
  1. Vowels & Resonance
  2. Diction & Articulation
  3. Head Voice & Registration
  4. Breath & Support
  5. Placement & Forward Tone
  6. Blend & Unison
  7. Intonation & Tuning (Drone)
  8. Agility & Flexibility
  9. Legato Line
  10. Staccato Precision
  11. Dynamic Control
  12. Range Builder
- 6 warmup families per category
- 3 difficulty levels per family (MS/LHS/UHS)

### Warmup Player controls

- Play / Pause
- Tempo - / +
- Demo On / Off
- Demo voice: Treble / Boy
- Texture: Unison / 2-Part / SAB / SATB
- Step mode: 1/2 or Whole
- Range preset selector
- Repeats per key (1-3)

### Playback behavior

- Piano playback for generated texture voices
- Algorithmic harmony generation from scale degrees
- Auto-transpose up, then down through selected range preset
- Texture changes apply on next iteration
- Tempo changes apply in real time

## Vocal Development Coach (In-School, On-Device)

The app now includes an **Individual Vocal Development Coach** that runs fully on-device and integrates with Station Mode + Warmup workflows.

### Modes

- **Mode A: Quick Skill Check**
  - 3-5 minute screen
  - Returns 1-2 focus areas
  - Suggests 2 exercises
- **Mode B: Full Pre-Assessment**
  - 5-7 minute screening
  - Builds skill profile
  - Generates a 2-week rule-based plan

### Pre-assessment tasks

1. Pitch match (5 notes)
2. 5-tone scale
3. Arpeggio 1-3-5-8-5-3-1
4. Sustain 6 seconds
5. Rhythm alignment to click

Each task outputs:

- `pitchAccuracy` (0-100)
- `stabilityScore` (0-100)
- `onsetTimingScore` (0-100)
- `confidenceScore` (0-100)

If confidence is low, coach shows guidance (`Low confidence - move closer`) and does not finalize profile.

### Focus areas and plan mapping

Coach produces up to 3 focus areas:

- `pitch_stability`
- `sustain_control`
- `head_voice_coordination`
- `leap_accuracy`
- `rhythm_alignment`
- `onset_clarity`

For each focus area, the rule engine maps to:

- 3 tagged warmups (from warmup library)
- 1 drill
- frequency recommendation (3-4x/week)
- session length (5-8 minutes)

### Session flow

After profile:

1. Show Today's Focus
2. Run 2 warmups
3. Run 1 drill
4. Run micro-check
5. Save progress

### Teacher View additions

Teacher dashboard now includes:

- Student focus areas
- Baseline vs latest micro-check improvement
- Section aggregate weaknesses by focus area

No raw audio is stored; only metrics and flags are persisted.
