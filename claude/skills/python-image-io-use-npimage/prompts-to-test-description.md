## Should trigger
1. "I'm working in Python. Write a function `load_and_downscale(path, factor)` that reads an image file from `path`, downscales it by an integer `factor`, and also writes the downscaled result to `downscaled.png`.": 2/2 Haiku and 2/2 Sonnet

## Should not trigger
1. "I'm working in Python and already have an image loaded as a NumPy array called `image` (shape H×W×3, dtype uint8) in memory. Write a function that normalizes it to floats in [0, 1] and returns the per-channel mean. No file reading or writing is involved.": 0/2 Haiku and 0/2 Sonnet
