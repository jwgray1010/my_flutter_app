# Choir Rehearsal Web Platform (Website-Only Prototype)

This folder contains the **single responsive web application** for the choral rehearsal platform.

There are no separate native apps in this prototype:
- no iOS app
- no separate remote app
- no separate student app

All experiences are rendered from the same Next.js project.

Current focus remains Phase 1 from the build order:

1. Upload one score page file
2. OMR transcription to MusicXML
3. Parse measures + parts
4. Playback with part isolation, tempo, seeking, and looping

## Website-only responsive behavior

The same URL serves multiple contexts:
- **Director layout** on desktop/tablet (Upload Score, My Music, Rehearsal, Warmups, Stations, Student/Teacher tools)
- **Mobile remote layout** on phone with large controls
- **Student mode routes** via query-string link/QR (`?mode=station`, `?mode=sectional`, `?mode=solo`, `?mode=checkin`, `?mode=vocal`)

## What is implemented now

- Upload-first score intake (`.jpg`, `.jpeg`, `.png`, `.pdf`)
- Explicit processing flow:
  - `UPLOAD SCORE`
  - file name shown
  - `PROCESS MUSIC`
  - `PROCESSING MUSIC...`
  - `READY TO REHEARSE`
- Server-side OMR provider abstraction (`src/lib/server/omr/provider.ts`)
- OMR provider implementation using `homr` (`scripts/run_homr.py`)
- MusicXML parsing for:
  - Parts (with SATB/Piano canonical mapping)
  - Measures and time signatures
  - Tempo hint and key signature
  - Note events for playback
- Playback engine supporting:
  - PLAY/PAUSE
  - BACK 2 / FORWARD 2
  - TEMPO - / TEMPO + (50% to 120%)
  - Measure jump
  - Loop range set/clear
  - Part isolation (S/A/T/B/Piano combinations)
- Photo quality diagnostics (blur/contrast/glare/perspective warning hints)
- Local `MY MUSIC` storage using browser localStorage

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

For same-network device access during rehearsal, open on local IP from another device, for example:

```text
http://192.168.x.x:3000
```

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
