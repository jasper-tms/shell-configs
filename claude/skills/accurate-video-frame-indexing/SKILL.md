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

The fix is the same idea everywhere: **the integer frame index is the source of
truth, and the frame<->time mapping comes from the real per-frame presentation
timestamps (PTS), never from an assumed fps.**

## Python — use npimage

npimage already does frame-exact decoding. Index by frame; never reconstruct
frames from time.

```python
import npimage  # Install with `pip install 'numpyimage[vid]'` if not installed yet
with npimage.VideoStreamer(fn) as stream:
    n = stream.n_frames          # exact frame count
    image = stream[frame_index]  # exact random access to frame N (decodes from
                                 # the preceding keyframe under the hood)
```

- When you need to convert between frame indices and timestamps/pts values, use a
  VideoStreamer function like `stream.frame_number_to_time`, `stream.frame_number_to_pts`,
  or `stream.pts_to_frame_number` which make sure to get the math right both for constant
  framerate and variable framerate videos. (Be aware that `stream.fps` gives MEAN
  framerate for any video; do NOT use it to convert times <-> frames which fails on VFR.)
- `stream[...]` takes only frame indices, not time — a continuous time doesn't
  uniquely name a frame. `stream.t[time_in_seconds]` finds the frame on screen at the
  requested time (largest PTS in the video that's <= time-in-seconds) and returns 
  returns `(image, actual_time_in_seconds_of_returned_frame, frame_index)`.
- `npimage.load_video` / `lazy_load_video` yield frames in presentation order, so
  their position in the sequence IS the frame index.

## Web app (pure HTML+JS, no server)

Keep `<video>` for display, but get the timing table by **demuxing the
container** (read PTS from the boxes; no decode needed). For MP4/MOV use
**mp4box.js** (bundle it offline). Rules, all required:

1. **Build a per-frame PTS table from the container, then SORT by composition
   time.** mp4box yields samples in *decode* order; with B-frames the
   composition timestamps are out of order, so an unsorted table silently maps
   frame N to the wrong picture.
2. **Apply the edit list** to convert media time → the movie timeline that
   `<video>.currentTime` uses (a trim edit `media_time>=0` shifts the start; an
   empty edit `media_time===-1` adds a leading delay). Identity edits need nothing.
3. **The integer frame index is canonical. Command frames; never read them
   back.** After a programmatic seek, Firefox's `requestVideoFrameCallback`
   `mediaTime` just echoes the time you set (not the real frame), so post-seek
   readback is worthless. Track which frame you intend and trust the seek.
4. **Seek to the interval MIDPOINT**, never a frame boundary. Seeking to
   `pts[N]` lands on frame `N-1` in every browser; the midpoint has half an
   interval of margin and lands on `N`. This is the VFR generalization of the
   constant-rate `(N + 0.5) / fps`.
5. **Inverting time→index without the table** — only in the constant-rate
   fallback where you have no `pts[]` — use `Math.round(t * fps)`, never
   `floor`. When you do have the table, binary-search it (`frameAtTime`) instead.
6. During *playback* (not after a seek) `rVFC` `mediaTime` IS exact in both
   Chrome and Firefox — use it to drive the current-frame readout while playing,
   and binary-search the table (`last pts <= t`) to get the frame.
7. **Never load the whole file** (matters for large videos). You only need the
   `moov` (index), never the `mdat` (frame bytes). Feed mp4box chunks from a
   range reader (`File.slice(...).arrayBuffer()`, or HTTP `Range` for a URL);
   set `buffer.fileStart` on each chunk to its byte offset (mp4box needs it to
   track position), and `appendBuffer` returns the next byte offset it wants,
   which jumps past the `mdat`. Stop once `onReady` fires, then read timing from
   `getTrackSamplesInfo(trackId)` (each sample has `.cts`, `.duration`,
   `.timescale`). Do NOT use `setExtractionOptions`/`onSamples` — that pulls
   frame data into memory. Peak memory stays ~ one chunk + the index, for a file
   of any size.

```js
// pts[], dur[] = per-frame seconds in the <video>.currentTime timeline,
// sorted by composition time, edit-list applied (built from mp4box).
function midpointTime(n) {                       // seek target for frame n
    const end = (n + 1 < pts.length) ? pts[n + 1] : pts[n] + dur[n];
    return (pts[n] + end) / 2;
}
function frameAtTime(t) {                          // last frame with pts <= t
    let lo = 0, hi = pts.length - 1, ans = 0;
    while (lo <= hi) { const m = (lo + hi) >> 1; if (pts[m] <= t) { ans = m; lo = m + 1; } else hi = m - 1; }
    return ans;
}
function seekToFrame(n) { currentFrame = n; video.currentTime = midpointTime(n); }
```

Constant-rate files are just the special case where `pts` is an arithmetic
sequence; the same code handles CFR and VFR. Store the integer frame index as
the record of truth (the PTS in seconds is fine as derived provenance).

## Verifying frame accuracy in a browser

`currentTime`/`mediaTime` can't be trusted to confirm what's on screen, so when
you need ground truth, **burn each frame's index into its pixels** (e.g. a
high-contrast binary strip), then seek, draw the `<video>` to a canvas, and read
the index back from the pixels. That is the only browser-independent way to know
which frame is actually displayed. (Headless Chrome via puppeteer-core +
`/usr/bin/google-chrome` can decode H.264 and run this end-to-end.)

A ready-made fixture lives in this skill folder: **`frame_numbered_vfr.mp4`** has
each frame's index burned in (big number + 16-bit top strip; decode by sampling
16 block centers across the top 1/8, threshold brightness at 128, MSB left), and it is
deliberately **VFR with B-frames** so it stresses both the timestamp-table path
and composition-order sorting. Use it to develop and verify against ground truth.
`make_test_video.py` (re)generates it, exposes `decode_frame_index()`, and runs
`--verify`.
