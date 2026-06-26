#!/usr/bin/env python3
"""
Generate (and verify) a frame-accuracy test video: every frame has its own index
burned into the pixels two ways, so any tool can be checked against ground truth
that does not depend on a player's timing APIs.

Encoding of each frame (must match the decoder below):
  - A large human-readable number, centered (for eyeballing).
  - A machine-readable 16-bit binary strip across the FULL WIDTH of the TOP 1/8
    of the frame: 16 equal blocks, most-significant bit on the LEFT, white = 1,
    black = 0. Decode by sampling each block center and thresholding brightness
    at 128.

The video is deliberately a real challenge: VARIABLE frame rate (three regimes
~30/8/60 fps plus jitter) AND B-frames (so composition order != decode order).
A correct frame-accurate tool must handle both.

Usage:
    ./make_test_video.py            # (re)generate frame_numbered_vfr.mp4 here
    ./make_test_video.py --verify   # check the existing file against ground truth

Requires PyAV directly (not npimage) because we assign explicit per-frame
presentation timestamps; npimage's writer is constant-rate only.
"""

import math
import sys
from fractions import Fraction
from pathlib import Path
from typing import Union

import numpy as np
from PIL import Image, ImageDraw, ImageFont
import av

WIDTH = 384            # 16 blocks * 24 px
HEIGHT = 256
N_FRAMES = 900
N_BITS = 16            # supports indices up to 65535
STRIP_FRACTION = 1 / 8
TIMEBASE = Fraction(1, 90000)
OUTPUT = Path(__file__).with_name('frame_numbered_vfr.mp4')

# Candidate font files for the large human-readable number, tried in order
# across operating systems. The typeface is purely cosmetic - only the
# machine-readable binary strip is used for verification - so any of these
# (or the PIL fallback in `load_font`) is fine.
FONT_CANDIDATES = (
    # Linux (DejaVu is what the committed fixture was generated with)
    '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    # macOS
    '/System/Library/Fonts/Menlo.ttc',
    '/Library/Fonts/Arial.ttf',
    '/System/Library/Fonts/Supplemental/Arial.ttf',
    # Windows
    'C:\\Windows\\Fonts\\consola.ttf',
    'C:\\Windows\\Fonts\\arial.ttf',
    # Pillow bundles DejaVuSans.ttf; resolvable by bare name on most installs.
    'DejaVuSans.ttf',
)


def load_font(size: int) -> Union[ImageFont.FreeTypeFont, ImageFont.ImageFont]:
    """
    Load a TrueType font for the large human-readable index, trying the
    common locations in `FONT_CANDIDATES` across operating systems and falling
    back to PIL's bundled default. The chosen typeface does not affect
    verification (only the binary strip is decoded), so any legible font works.

    Parameters
    ----------
    size : int
        Requested font size in points.

    Returns
    -------
    PIL.ImageFont.FreeTypeFont or PIL.ImageFont.ImageFont
        The first font that loads successfully.
    """
    for path in FONT_CANDIDATES:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    # Last resort: PIL's built-in default. Pillow >= 10.1 honors `size`; older
    # versions return a fixed small bitmap font, which still renders a legible
    # (if tiny) number - and again, only the binary strip matters.
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def build_frame(index: int,
                font: Union[ImageFont.FreeTypeFont, ImageFont.ImageFont]) -> np.ndarray:
    """
    Build one RGB frame (HEIGHT, WIDTH, 3) uint8 for the given frame `index`.
    """
    strip_height = int(round(HEIGHT * STRIP_FRACTION))
    block_width = WIDTH / N_BITS
    image = Image.new('RGB', (WIDTH, HEIGHT), (40, 40, 40))
    draw = ImageDraw.Draw(image)
    for i in range(N_BITS):
        bit = (index >> (N_BITS - 1 - i)) & 1
        color = (255, 255, 255) if bit else (0, 0, 0)
        x0 = int(round(i * block_width))
        x1 = int(round((i + 1) * block_width))
        draw.rectangle([x0, 0, x1 - 1, strip_height - 1], fill=color)
    text = str(index)
    bbox = draw.textbbox((0, 0), text, font=font)
    text_x = (WIDTH - (bbox[2] - bbox[0])) / 2 - bbox[0]
    text_y = strip_height + (HEIGHT - strip_height - (bbox[3] - bbox[1])) / 2 - bbox[1]
    draw.text((text_x, text_y), text, fill=(120, 220, 120), font=font)
    return np.asarray(image)


def decode_frame_index(image: np.ndarray) -> int:
    """
    Read the burned-in frame index back out of a decoded frame.

    Parameters
    ----------
    image : np.ndarray
        An (H, W, 3) or (H, W) uint8 frame.

    Returns
    -------
    int
        The frame index encoded in the top binary strip.
    """
    height, width = image.shape[:2]
    gray = image[..., :3].mean(axis=2) if image.ndim == 3 else image
    y = int(height * STRIP_FRACTION / 2)
    bits = 0
    for i in range(N_BITS):
        x = int((i + 0.5) * width / N_BITS)
        bits = (bits << 1) | (1 if gray[y, x] > 128 else 0)
    return bits


def frame_duration(index: int) -> float:
    """
    Per-frame display duration in seconds: three rate regimes plus jitter.
    """
    if index < 300:
        base = 1 / 30
    elif index < 600:
        base = 1 / 8
    else:
        base = 1 / 60
    return base * (1.0 + 0.15 * math.sin(index * 1.7))


def generate() -> None:
    font = load_font(96)
    times_seconds, t = [], 0.0
    for index in range(N_FRAMES):
        times_seconds.append(t)
        t += frame_duration(index)
    pts_ticks = [round(s / TIMEBASE) for s in times_seconds]

    container = av.open(str(OUTPUT), mode='w')
    stream = container.add_stream('libx264', rate=30)
    stream.width = WIDTH
    stream.height = HEIGHT
    stream.pix_fmt = 'yuv420p'
    stream.time_base = TIMEBASE
    stream.codec_context.time_base = TIMEBASE
    # B-frames ON (default) so composition order != decode order; low crf so the
    # binary blocks survive compression.
    stream.options = {'crf': '12'}

    for index in range(N_FRAMES):
        frame = av.VideoFrame.from_ndarray(build_frame(index, font), format='rgb24')
        frame.pts = pts_ticks[index]
        frame.time_base = TIMEBASE
        for packet in stream.encode(frame):
            container.mux(packet)
    for packet in stream.encode():
        container.mux(packet)
    container.close()

    deltas = np.diff(times_seconds)
    print(f'Wrote {N_FRAMES} frames to {OUTPUT}')
    print(f'VFR intervals {deltas.min()*1000:.1f}-{deltas.max()*1000:.1f} ms '
          f'({deltas.max()/deltas.min():.1f}x), B-frames on, ~{times_seconds[-1]:.1f}s')


def verify() -> None:
    import npimage
    with npimage.VideoStreamer(str(OUTPUT)) as stream:
        print(f'{stream.n_frames} frames in {OUTPUT.name}')
        bad = 0
        for index in [0, 1, 2, 150, 299, 300, 301, 599, 600, 700, 899]:
            decoded = decode_frame_index(stream[index])
            ok = decoded == index
            bad += not ok
            print(f'  frame {index:4d} -> decoded {decoded:4d}  {"OK" if ok else "MISMATCH"}')
        print('ALL CORRECT' if bad == 0 else f'{bad} MISMATCHES')


if __name__ == '__main__':
    verify() if '--verify' in sys.argv else generate()
