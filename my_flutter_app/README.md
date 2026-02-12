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
