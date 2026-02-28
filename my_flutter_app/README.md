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
