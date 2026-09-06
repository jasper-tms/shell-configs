# Standalone scripts (a script living outside any project directory)

- Create/manage dependencies with inline PEP 723 metadata:
  `uv init --script foo.py --python 3.12` to scaffold the header, then
  `uv add --script foo.py pkg1 pkg2` to add dependencies.
- **Shebang: decide via backward-compatibility.md** (classic
  `#!/usr/bin/env python3` for Category 2, uv shebang + `requires-python`
  header for Category 1). Either way the PEP 723 metadata block itself is
  inert to non-uv users (just a comment); only the shebang choice can break
  `./foo.py` for them.
- Habit: invoke your own scripts via `uv run foo.py` (or an alias, e.g.
  `alias ur='uv run'` — check `command -v ur` first for collisions), not
  `./foo.py`. The alias pays off broadly since `uv run` is also the verb for
  executing things inside real projects (`uv run pytest`, etc.), not just
  lone scripts.
- Given that habit, don't bother `chmod +x` on scripts you plan to always run
  via `uv run`. Leaving them non-executable turns an accidental `./foo.py`
  (which would silently run in whatever ambient `python3` environment,
  ignoring the header) into a loud `Permission denied` instead — a forcing
  function that catches the mistake rather than hiding it.
- Local or git dependency for a script: `uv add --script foo.py --editable
  /path/to/local/clone` (writes `[tool.uv.sources]` into the header). Note
  there is no compatibility path for this at all — a non-uv user cannot run
  a PEP 723 script with such a dependency, full stop. This mechanism is
  uv-only regardless of the shebang decision.
- **`[tool.uv.sources]`/editable-path overrides can only live in a
  `pyproject.toml` (or a script's own inline header) — never in any
  `uv.toml`, project-local or global (`~/.config/uv/uv.toml`).** uv 0.11.27
  hard-errors: `sources is only applicable in the context of a project, and
  should be placed in a pyproject.toml file instead`. So there is no central,
  shared file mapping locally-cloned packages to editable paths across repos
  — each consuming project's own `pyproject.toml` must carry the override,
  which would otherwise bake a personal absolute path (e.g.
  `/home/phelps/repos/jasper-tms/npimage`) into a normally-committed file.
  Don't push that hunk. editable-registry.md builds a git filter/hook system
  to keep the block local-only; the alternative is a personal wheel index
  (`--find-links`) via the global `uv.toml`'s `extra-index-url` (allowed
  globally, unlike `sources`), at the cost of live-editable semantics. uv
  **workspaces** solve only the sibling-packages-in-one-repo case, not
  independently-cloned repos.
