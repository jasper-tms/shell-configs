# Reproducibility / Python-version drift

- `requires-python` in a script header or pyproject.toml defaults to (and
  generally should stay) a lower-bound range like `>=3.12` — that's a
  compatibility floor, the correct idiomatic meaning, not a bug or something
  to "clean up" into `==`.
- Locking (`uv lock --script foo.py`, or `uv.lock` for a project) pins
  *package* versions, resolved to remain valid across whatever
  `requires-python` range is declared — it does NOT by itself pin the
  interpreter to one exact version. If immunity to Python minor-version
  behavior drift (e.g. 3.12 vs 3.13) is the actual goal, narrow
  `requires-python` itself (e.g. `==3.12.*`) in addition to locking
  dependencies; the two controls are orthogonal.
- Once a lockfile exists and is still consistent with the declared
  dependencies, uv uses the pinned versions indefinitely, even if newer
  releases appear upstream — re-run `uv lock --script foo.py [--upgrade]` (or
  the project equivalent) to deliberately refresh it.
