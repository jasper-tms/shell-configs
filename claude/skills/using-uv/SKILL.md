---
name: using-uv
description: How to use uv for anything Python — running one-off or inline commands and scripts that need packages, authoring standalone scripts and pyproject packages, using your own locally-cloned packages, and uv-made virtual environments (shebangs, PEP 723 metadata, dependency sources, lockfiles, the bin/pip shim) — while staying backward compatible with people and machines that don't have uv. Load the moment a Python script or command hits ModuleNotFoundError / ImportError or needs a package outside the standard library — uv is the default way to get it, rather than pip-installing into or activating an ambient environment. Also load whenever you run python that needs a dependency, write or edit a standalone script, add a dependency to a script or package, create or populate a virtual environment with uv, or decide a shebang line or how to pin a local or git dependency.
---

# Skill: Using uv

Mental model: uv replaces `pip install` + `python script.py` +
virtualenvwrapper with two verbs — `uv add` (declare what you need) and
`uv run` (execute anything, in an isolated environment it provisions for you).
But a large fraction of collaborators/machines won't have uv installed for a
while yet, so several choices in these files trade uv-native convenience for
compatibility on purpose. Don't "fix" these back toward the pure-uv way
without re-reading the reasoning.

## Quick answer: you need a package that isn't in the standard library

When you just want to *run* some Python that needs a dependency, do NOT `pip
install` into whatever environment happens to be active, and do not assume an
ambient `python`/`conda`/venv already has it. Reach for `uv run`, which
provisions an isolated, throwaway environment per invocation and pollutes
nothing:

- One-off / inline command — add each package with `--with`:
  ```bash
  uv run --with requests --with numpy python -c "import requests, numpy; ..."
  ```
  Add `--python 3.12` to pin the interpreter.
- Multi-line snippet — feed a heredoc to `python` on stdin:
  ```bash
  uv run --with pandas python - <<'PY'
  import pandas as pd
  ...
  PY
  ```
- A script *file* you'll keep — give it a PEP 723 header and run it with
  `uv run foo.py` (see standalone-scripts.md for how to scaffold the header
  and choose a shebang).
- Need one of your OWN locally-cloned packages (e.g. `npimage`)? Read
  `~/.config/uv/local-packages.toml` for the clone paths, then add
  `--with-editable /path/to/clone` (or `--with-editable .` from inside it).
  Default to the local clone unless there's a reason to use a published
  version.

The one exception to "don't rely on existing environments": use a named
environment only when the work is clearly tied to one — a repo whose
README/pyproject says so, or an env the user names (`workon <env>`). Otherwise
prefer `uv run`.

## Which file to read for more

This SKILL.md covers the everyday run-it-now case above. For a specific kind
of work, read the matching file in this same folder:

- **standalone-scripts.md** — writing or editing a standalone `.py` script
  you'll run (PEP 723 headers, `uv init/add --script`, chmod/shebang habits,
  pinning a local or git dependency inside a script).
- **backward-compatibility.md** — deciding a shebang line, or whether a
  script/package must keep working for people or machines that don't have uv
  (the Category 1 vs Category 2 decision that most other choices flow from).
- **packages.md** — working inside a real `pyproject.toml` package (`uv
  add`/`uv sync`, dependencies pip must also see, exporting a lockfile for
  pip-only collaborators, CI/Docker, building wheels).
- **virtual-environments.md** — creating or populating a long-lived virtual
  environment with `uv venv` (e.g. under `~/.virtualenvs` so `workon` finds
  it), and the mandatory `bin/pip` shim.
- **editable-registry.md** — the personal system for editable-installing your
  own locally-cloned packages across many project repos (the
  `~/.config/uv/local-packages.toml` registry and its git filter/hook
  machinery). Read `INSTALL.md` first when setting this up on a new machine.
- **reproducibility.md** — pinning versions and avoiding Python minor-version
  drift (`requires-python`, locking).
