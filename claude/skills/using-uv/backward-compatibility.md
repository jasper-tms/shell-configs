# Backward compatibility: can you assume every user has uv?

The shebang/interpreter choice hinges on whether uv is guaranteed present
wherever the script runs — NOT on whether you ship it. A tool you hand to
others can still be Category 1 if its whole audience is uv users (e.g. a uv
ecosystem tool, or one that only makes sense alongside uv): anyone running it
will have uv, so keep the uv shebang. Sort every script into one of two
categories first — the rest of the advice flows from which one it is.

**Category 1 — uv is guaranteed on every machine that runs it** (your own
tools, git hooks/filters, cron jobs, *and* any tool you ship whose users all
have uv anyway). Make it *just work by bare name*:

- Shebang `#!/usr/bin/env -S uv run --script` (needs `env -S`, i.e.
  coreutils >= 8.30), **plus** a PEP 723 header declaring `requires-python`
  (and any deps). The header is not optional: the shebang only routes
  execution through `uv run`, while the header is what makes uv provision the
  *right* interpreter. Omit it and uv may run under the ambient `python3`,
  so a script using newer-than-ambient stdlib (e.g. `tomllib` on a 3.10 box)
  still hits `ModuleNotFoundError`.
- `chmod +x` it — here you *want* direct/bare-name invocation (the opposite
  of the "don't chmod" forcing-function below, which assumes a classic
  shebang).
- This is the only robust option for scripts invoked by other machinery
  (git hooks/filters, cron): those exec the file, and the kernel honors the
  shebang — so uv kicks in even though you never get to type `uv run` in
  front of them. A classic `#!/usr/bin/env python3` would instead run them
  under whatever ambient python the machine happens to have.
- Cost: each run is one `uv run --script` (~50-70 ms warm). For a git
  filter/hook tool, `git status` is unaffected (git spawns no filter for it);
  only operations that read/write the filtered file — `git add`, commit,
  checkout, merge — pay ~one invocation each.

**Category 2 — you can't assume uv is present** (a script for a general
audience who may use conda, venv, poetry, or system python). These must work
without assuming uv at runtime:

- Keep the classic shebang `#!/usr/bin/env python3`.
- Be ambient-safe: target the lowest interpreter you support, and get deps
  from normal packaging (`[project.dependencies]` if it ships inside a
  package) rather than assuming uv resolves them.
- A PEP 723 header is still fine to add — it's inert (just a comment) to
  non-uv users but lets uv users get an isolated env. Just don't *rely* on
  it being honored.
- The `uv run` habit and the "don't chmod as a forcing function" trick (see
  standalone-scripts.md) apply here (and to any Category 1 script you
  deliberately keep on a classic shebang).
