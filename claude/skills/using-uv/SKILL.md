---
name: using-uv
description: Decisions on how to use uv for Python scripts and packages (shebangs, inline PEP 723 metadata, dependency sources, lockfiles) while staying backward compatible with collaborators/machines that don't have uv installed. Use whenever writing or editing a standalone Python script, adding dependencies to a script or package, or deciding on a shebang line or how to pin a local/git dependency.
---

# Skill: Using uv, backward-compatibly

Mental model: uv replaces `pip install` + `python script.py` +
virtualenvwrapper with two verbs — `uv add` (declare what you need) and
`uv run` (execute anything). But a large fraction of collaborators/machines
won't have uv installed for a while yet, so several choices below trade
uv-native convenience for compatibility on purpose. Don't "fix" these back
toward the pure-uv way without re-reading the reasoning.

## First decision: can you assume every user of this script has uv?

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
- The `uv run` habit and the "don't chmod as a forcing function" trick below
  apply here (and to any Category 1 script you deliberately keep on a classic
  shebang).

## Standalone scripts (e.g. a script living outside any project directory)

- Create/manage dependencies with inline PEP 723 metadata:
  `uv init --script foo.py --python 3.12` to scaffold the header, then
  `uv add --script foo.py pkg1 pkg2` to add dependencies.
- **Shebang: decide via the category above** (classic `#!/usr/bin/env
  python3` for Category 2, uv shebang + `requires-python` header for Category
  1). Either way the PEP 723 metadata block itself is inert to non-uv users
  (just a comment); only the shebang choice can break `./foo.py` for them.
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
  uv-only regardless of the shebang decision above.
- **`[tool.uv.sources]`/editable-path overrides can only live in a
  `pyproject.toml` (or a script's own inline header) — never in any
  `uv.toml`, project-local or global (`~/.config/uv/uv.toml`).** uv 0.11.27
  hard-errors: `sources is only applicable in the context of a project, and
  should be placed in a pyproject.toml file instead`. So there is no central,
  shared file mapping locally-cloned packages to editable paths across repos
  — each consuming project's own `pyproject.toml` must carry the override,
  which would otherwise bake a personal absolute path (e.g.
  `/home/phelps/repos/jasper-tms/npimage`) into a normally-committed file.
  Don't push that hunk. The "Personal editable-install registry" section
  below builds a git filter/hook system to keep the block local-only; the
  alternative is a personal wheel index (`--find-links`) via the global
  `uv.toml`'s `extra-index-url` (allowed globally, unlike `sources`), at the
  cost of live-editable semantics. uv **workspaces** solve only the
  sibling-packages-in-one-repo case, not independently-cloned repos.

## Real installable packages (pyproject.toml projects)

- `uv add`/`uv sync` write standard `[project.dependencies]`, which pip,
  poetry, etc. all read fine — a non-uv user can `pip install .` with no
  issue, in general.
- **Exception: `[tool.uv.sources]` is invisible to pip.** If you point a
  dependency at a local clone or git repo via `--editable`/`[tool.uv.sources]`
  and it needs to also work for someone running plain `pip install .`,
  express it directly in `[project.dependencies]` using standard PEP 508
  syntax instead/also, e.g. `"numpyimage @ git+https://github.com/jasper-tms/npimage"`
  (note the declared name must match the target's own `[project.name]` —
  e.g. the `npimage` repo's package is actually named `numpyimage`).
  Otherwise pip sees only the bare name, tries to fetch it from PyPI, and
  fails (or worse, installs an unrelated same-named package).
- `uv.lock` is a uv-proprietary format; pip/poetry/conda can't read it. For
  pip-only collaborators who need your exact pins, export a bridge file:
  `uv export --format requirements-txt > requirements.txt`.
- `.python-version` files are shared convention with pyenv (not uv-only), so
  pyenv users benefit; conda/virtualenvwrapper users' tooling ignores it.
- CI/Docker/deployment targets don't have uv preinstalled by default — add an
  explicit bootstrap step (e.g. `pip install uv`) rather than assuming it's
  there.
- A built wheel carries zero uv runtime dependency — `uv build` produces a
  completely standard artifact installable by anyone via plain pip. All of
  the compatibility concerns above are about authoring-time conventions, not
  about the thing you actually ship.

## Personal editable-install registry, across independently-cloned repos

If setting this up on a new computer, read `INSTALL.md` in this same folder
first — one-time setup steps (global git config, initial registry file)
that aren't worth keeping in this skill body.

Solves: many separate downstream project repos each wanting to depend on a
package you have cloned locally (e.g. `npimage`) in editable mode, without
hand-writing a personal absolute path into each project's committed
`pyproject.toml`. Since `[tool.uv.sources]` can only live in a `pyproject.toml`
(see above), there's no global-config escape hatch — so this system builds
one out of git's own filter/hook mechanisms instead. Pieces, all global (no
per-repo setup):

- `~/.config/uv/local-packages.toml` — the registry. Not read by uv itself.
  Top-level `personal-remotes` array lists which GitHub accounts/orgs count
  as "yours" for auto-registration (currently `["jasper-tms", "NeLy-EPFL"]`
  — edit this file directly to add more, no script changes needed); a
  `[packages]` table (kept last in the file — new entries get appended
  after it) holds `name = "path"` pairs (e.g. `numpyimage =
  "~/repos/jasper-tms/npimage"`; note the key must be the package's real
  declared distribution name, which can differ from its repo name). Paths
  may use `~` for the home directory — `load_registry()` expands it before
  building the actual `[tool.uv.sources]` block (never relying on uv itself
  to expand `~`), and `register_entry()` contracts it back on write — so
  entries under your home directory stay portable across machines with a
  different home directory, e.g. if this file is synced via dotfiles.
  Seeded with every locally-cloned package under the configured personal
  accounts that has a static `[project.name]`; deliberately excludes
  third-party clones (e.g. `napari`, `igneous`) — see "auto-registration"
  below for why.
- `refresh-uv-editables` — canonical copy lives in this skill's own
  `scripts/refresh-uv-editables`, symlinked from `shell_scripts/` (which is
  on `PATH`) so hooks/filter config can keep calling the bare command name.
  Parses a `pyproject.toml`'s declared dependencies (`project.dependencies`,
  `optional-dependencies`, `dependency-groups`), cross-references the
  registry, and rewrites a clearly delimited, auto-generated
  `[tool.uv.sources]` block (between `# BEGIN uv-local-sources` /
  `# END uv-local-sources` markers) accordingly. Run with no arguments to
  refresh the current repo's `pyproject.toml` in place; `--clean`/`--smudge`
  read/write via stdin/stdout for git filter use; `--register`/
  `--fresh-clone` add/update a registry entry (see below).
- **Index-stat reconcile (keeps `git status` quiet).** Because the block
  lives only in the working tree, `git status` — which compares stat, not
  filtered content — would flag `pyproject.toml` as perpetually modified even
  though `git diff` (which runs the `clean` filter) sees no change, and only
  a manual `git add` clears it. So after an in-place rewrite, refresh
  re-stages the file itself to re-cache git's stat. This is gated to a
  provable no-op: it stages only when the block-stripped working tree already
  matches the index blob, so a genuine unstaged edit to `pyproject.toml` is
  never swept into staging. Runs only on the no-args/hook path — never under
  `--clean`/`--smudge` (which execute with the index locked) — and any
  failure (not a repo, untracked, no git) is swallowed.
- `git-hooks/{post-checkout,post-merge,post-commit}` at this repo's root,
  wired up via a **global** `core.hooksPath` (`git config --global
  core.hooksPath .../shell-configs/git-hooks`) so every repo on the machine
  picks them up with no per-repo install. Each calls `refresh-uv-editables`
  if a `pyproject.toml` exists, then chains to any repo-local hook of the
  same name (`$(git rev-parse --git-dir)/hooks/<name>`) so a future
  per-repo pre-commit/husky setup isn't silently shadowed.
- A **global** git content filter, `uv-sources`, applied to every repo via
  `core.attributesFile` (`~/.gitattributes_global`, containing `pyproject.toml
  filter=uv-sources`) plus `filter.uv-sources.clean`/`.smudge` both set to
  `refresh-uv-editables --clean`/`--smudge`. This is what structurally
  guarantees the block never reaches a commit (clean strips it before
  content is staged, regardless of whether you use `git add`, a GUI client,
  or `commit -a`) — the git-hooks alone don't provide that guarantee, the
  filter does.
- **Auto-registration on fresh clone:** `post-checkout` detects a fresh
  clone (previous `HEAD` is the all-zeros ref) and calls
  `refresh-uv-editables --fresh-clone`, which reads the cloned repo's
  `[project.name]` and, only if its `origin` remote matches an account
  listed under `personal-remotes` in the registry file, auto-adds it to the
  registry; otherwise it just prints the equivalent `refresh-uv-editables
  --register <path>` command as a suggestion. Deliberately org-gated rather
  than unconditional: blindly registering every cloned `pyproject.toml`
  would mean cloning someone
  else's package for any reason (reading source, testing a fix) silently and
  permanently overrides that package name for every future project of
  yours, and deleting a throwaway clone later leaves a dangling path that
  breaks unrelated projects. If a repo declares no static `[project.name]`
  (dynamic name/version, e.g. via setuptools-scm or an unmigrated
  `setup.py`), registration is skipped with a warning rather than guessed.
- **Known gap:** none of the above fires the instant you run `uv add
  somepkg` directly, since that's not a git operation — the block only
  reappears at the next commit/checkout/merge. Deliberately not closed with
  a `uv` shell-wrapper (rejected as too heavy-handed); just run
  `refresh-uv-editables` by hand right after `uv add` if you need the
  editable link immediately.
- **Known limitation:** the auto-generated block fully owns
  `[tool.uv.sources]` — TOML doesn't allow defining that table twice, so this
  doesn't compose with a separately hand-maintained `[tool.uv.sources]` entry
  (e.g. a committed git-source override for some other dependency) in the
  same file.

## Reproducibility / Python-version drift

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
