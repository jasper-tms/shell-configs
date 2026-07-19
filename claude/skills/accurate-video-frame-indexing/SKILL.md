---
name: accurate-video-frame-indexing
description: How to map between video frames and timestamps with GUARANTEED accuracy (frame-accurate annotation, seeking, extraction) in Python (npimage) or a browser/JS web app. Use whenever code must know exactly which frame is which, e.g. "annotate this frame", "seek to frame N", "extract frames a..b".
---

# Frame-accurate video

**The trap:** there is no reliable constant `fps` you can multiply by. Computing
a frame index as `floor(time * fps)` (or seeking with `time = frame / fps`) is
NOT frame-accurate. It breaks on:
- Floating-point boundaries (`floor(N/fps * fps)` can give `N-1`).
- Non-integer rates (assuming 30 fps for true 29.97 drifts half a frame —
  enough to misindex — within ~17 s of video, and a full frame by ~33 s).
- Variable frame rate (VFR) — no single `fps` exists at all.

**The fix, in every language:** the integer frame index is the source of truth,
and the frame↔time mapping comes from the real per-frame presentation timestamps
(PTS), never from an assumed fps. Get those timestamps from an index — either the
one the container already carries or one you build by parsing the file without
decoding. You cannot recover exactness by measuring an fps and assuming constant
frame rate: sampling can disprove a wrong rate but never prove a constant one (a
single dropped or inserted frame that stays on the same grid shifts every later
index by one, undetectably). So the rule is **index or refuse**, never
index-or-guess.

Then read the file for your language — the concrete API and rules live there, and
reading it is required, not optional:

- **Python** (npimage): read [`python.md`](python.md).
- **Browser / JS web app** (no server): read [`web.md`](web.md).
