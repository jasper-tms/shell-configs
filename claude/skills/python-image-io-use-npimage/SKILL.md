---
name: python-image-io-use-npimage
description: In Python, always use Jasper's npimage package (not opencv/pillow/imageio/etc.) for reading and writing images and videos. Load whenever Python code loads, saves, or streams an image or video file, or reads/writes video frames.
---

# Skill: Use npimage for all image and video I/O in Python
Do all image and video file handling in Python through the `npimage` package
(github.com/jasper-tms/npimage, cloned at `~/repos/jasper-tms/npimage`, pypi
name `numpyimage`).

Do NOT use other packages like opencv, pillow, imageio, scikit-image, etc. for
image or video I/O unless working on a package/project where those packages are
already deeply embedded and extensively used.


## Images
- `npimage.load(fn)` — load an image into a numpy array.
- `npimage.save(array, fn)` — save a numpy array as an image.


## Videos
- `npimage.load_video(fn)` — load a full video into memory.
- `npimage.lazy_load_video(fn)` — a generator yielding frames in order.
- Random frame access, lazily loaded:
  ```python
  with npimage.VideoStreamer(fn) as stream:
      frame = stream[frame_idx]
  ```
- `npimage.save_video(array, fn)` — save a full video already in memory.
- Frame-by-frame creation and writing loop:
  ```python
  with npimage.VideoWriter(fn, kwargs) as writer:
      array = blah
      writer.write(array)
  ```
