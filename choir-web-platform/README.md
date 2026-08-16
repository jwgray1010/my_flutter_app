# Choir Rehearsal Web Platform (Phase 1 Prototype)

This folder contains the **web-first prototype** for the choral rehearsal platform.

Current focus is Phase 1 from the master build order:

1. Upload / scan one score page
2. OMR transcription to MusicXML
3. Parse measures + parts
4. Playback with part isolation, tempo, seeking, and looping

## What is implemented now

- **SCAN MUSIC** (camera capture on supported devices)
- **UPLOAD SCORE** (JPG, PNG, WEBP, PDF, XML/MusicXML)
- MusicXML direct path (bypasses OMR)
- Server-side OMR provider abstraction (`src/lib/server/omr/provider.ts`)
- OMR provider implementation using `homr` (`scripts/run_homr.py`)
- MusicXML parsing for:
  - Parts (with SATB/Piano canonical mapping)
  - Measures and time signatures
  - Tempo hint and key signature
  - Note events for playback
- Playback engine supporting:
  - PLAY/PAUSE
  - BACK 2 / FORWARD 2 measures
  - TEMPO - / TEMPO + (50% to 120%)
  - Measure jump
  - Loop range set/clear
  - Part isolation (S/A/T/B/Piano combinations)
  - Starting pitches
- Photo quality diagnostics (blur/contrast/glare/perspective warning hints)
- Local **MY MUSIC** storage using browser localStorage

## Local setup

Install node dependencies:

```bash
npm install
```

Install Python runtime dependencies for OMR:

```bash
python3 -m pip install --user homr pypdfium2 Pillow
```

Run the app:

```bash
npm run dev
```

Open http://localhost:3000

## OMR provider notes

- Provider is intentionally replaceable so Audiveris/other engines can be swapped later.
- Current pipeline:
  - upload image/pdf
  - preprocess image
  - run `homr`
  - read produced MusicXML
  - parse + play
- PDF currently processes page 1 first in this prototype.

## Important prototype constraints

- This is a **functional prototype**, not final engraving-accurate notation software.
- Playback accuracy is prioritized over rendering fidelity.
- No student voice recordings are stored in this phase.
