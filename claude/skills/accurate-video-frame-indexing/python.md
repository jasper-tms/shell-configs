# Frame-accurate video — Python (npimage)

Read the shared principle in `SKILL.md` first (integer frame index is the source
of truth; mapping comes from a real per-frame PTS table, never an assumed fps).
This file is the concrete how-to for Python.

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
  `(image, actual_time_in_seconds_of_returned_frame, frame_index)`.
- `npimage.load_video` / `lazy_load_video` yield frames in presentation order, so
  their position in the sequence IS the frame index.
