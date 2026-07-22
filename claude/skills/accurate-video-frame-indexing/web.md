# Frame-accurate video — browser / JS web app (no server)

Read the shared principle in `SKILL.md` first (integer frame index is the source
of truth; mapping comes from a real per-frame PTS table; **index or refuse**,
never guess an fps). This file is the concrete how-to for the browser.

Keep `<video>` for display, but get the timing table by **demuxing the
container** (read PTS from the boxes; no decode needed). For the `<video>` path,
the only containers worth indexing are the ones a browser plays natively — a
format `<video>` can't decode has nothing to attach a table to — and that set is
small: ISOBMFF (mp4/m4v/mov), WebM/Matroska, and Ogg. **Only ISOBMFF has a
central index** (the `moov`), which mp4box reads from a few range requests; WebM
and Ogg store timestamps beside the frames with no central table, so building
theirs needs a full sequential no-decode pass over the whole file (Matroska
cluster-block timestamps; Ogg page granule positions). Segmented or live delivery
(HLS/MPEG-TS, DASH, MSE) is not a single range-readable file and does not fit
this model — refuse it. For ISOBMFF use **mp4box.js** (bundle it offline).

**Exception — a container you decode yourself with WebCodecs.** If you run a
`VideoDecoder` rather than a `<video>` element, you are not limited to
browser-native containers: you can index and play one the browser won't touch,
**AVI** being the case in point (Chromium and Firefox refuse AVI in `<video>`).
But this needs more than a timestamp table — WebCodecs decodes from a full
decode-order **sample table** (byte offset, size, keyframe flag per frame) plus a
**`decoderConfig`**, which you build from the container's own index (AVI's `idx1`
or OpenDML `indx`/`ix##`). Two gotchas learned the hard way on AVI's H.264: it is
stored **Annex B**, but WebKit's WebCodecs answers `isConfigSupported()` = true
for an Annex-B (no-`description`) config and then *fails the decode* — a dishonest
yes — so configure in **AVCC** mode (build an `avcC` description from the first
keyframe's SPS/PPS and convert each frame's start codes to length prefixes);
AVCC is the one form every engine decodes. And because such a container has **no
native fallback**, a codec WebCodecs can't decode must be refused, not handed to
`<video>`. Rules for the `<video>` path, all required:

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
   **This fallback is not frame-exact and cannot be made so:** sampling
   timestamps can disprove a wrong `fps` but never prove constant frame rate, and
   its blind spot — one dropped or inserted frame that leaves the surrounding
   cadence on the same grid — shifts every later index by one, undetectably.
   Build a real table (a full-file pass if that's what the container needs) or
   refuse the clip; do not ship this as if it were exact.
6. During *playback* (not after a seek) `rVFC` `mediaTime` IS exact in both
   Chrome and Firefox — use it to drive the current-frame readout while playing,
   and binary-search the table (`last pts <= t`) to get the frame.
   `requestVideoFrameCallback` is the presented-frame clock the entire native
   path depends on; where it's absent (WebKit before 15.4) there is no
   frame-exact substitute — `currentTime` drifts forward through decoder stalls
   while the picture is frozen — so refuse rather than silently fall back to it.
7. **For a progressive (single-`moov`) MP4, don't load the whole file** (matters
   for large videos). You only need the `moov` (index), never the `mdat` (frame
   bytes). Feed mp4box chunks from a range reader (`File.slice(...).arrayBuffer()`,
   or HTTP `Range` for a URL); set `buffer.fileStart` on each chunk to its byte
   offset (mp4box needs it to track position), and `appendBuffer` returns the
   next byte offset it wants, which jumps past the `mdat`. Stop once `onReady`
   fires, then read timing from `getTrackSamplesInfo(trackId)` (each sample has
   `.cts`, `.duration`, `.timescale`). Do NOT use `setExtractionOptions`/
   `onSamples` — that pulls frame data into memory. Peak memory stays ~ one chunk
   + the index, for a file of any size. **Exception — fragmented MP4 (fMP4/CMAF):**
   `onReady` fires on the init segment's `moov`, which has an `mvex` box and no
   sample table, and `getTrackSamplesInfo` stays empty until the `moof` boxes are
   fed — and those are scattered through the whole file. Detect fragmentation (an
   `mvex` box, or an empty sample table) and feed the entire container before
   reading the table.

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
