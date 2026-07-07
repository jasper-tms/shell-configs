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

## Standalone scripts (e.g. a script living outside any project directory)

- Create/manage dependencies with inline PEP 723 metadata:
  `uv init --script foo.py --python 3.12` to scaffold the header, then
  `uv add --script foo.py pkg1 pkg2` to add dependencies.
- **Keep the classic shebang, `#!/usr/bin/env python3`.** Do NOT switch it to
  `#!/usr/bin/env -S uv run --script`, even though that's uv's own
  recommended pattern for direct-executability — it silently breaks
  `./foo.py` on any machine without uv installed. The inline metadata
  comment block itself is inert to non-uv users (it's just a comment), so
  adding it never breaks anything on its own; only the shebang choice does.
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
  `uv.toml`, project-local or global (`~/.config/uv/uv.toml`).** Verified
  empirically (uv 0.11.27): uv hard-errors with `sources is only applicable
  in the context of a project, and should be placed in a pyproject.toml file
  instead` if you try either. So there is no built-in way to keep one
  central, shared file mapping locally-cloned packages to editable paths
  across many separate project repos — each consuming project's own
  `pyproject.toml` must carry the override, meaning a personal absolute path
  (e.g. `/home/phelps/repos/jasper-tms/npimage`) would otherwise end up baked
  into a file that's normally committed and shared. Don't push that hunk.
  If you want this centralized despite the lack of native support, the
  practical options (in order of effort) are: (a) keep one plain personal
  registry file uv never reads (name → clone path) and a small script that
  stamps the `[tool.uv.sources]` block into a given project's
  `pyproject.toml` on demand — treat the stamped hunk as a local-only edit
  you regenerate after every pull, never commit, and guard with a pre-commit
  hook that greps the diff for your home directory path; or (b) drop
  `path`/`editable` entirely and run a personal local package index (e.g. a
  `--find-links` wheel directory) referenced via the global `uv.toml`'s
  `index-url`/`extra-index-url` (which *is* allowed globally, unlike
  `sources`) — at the cost of losing live-editable semantics. Neither is a
  shipped uv feature; uv **workspaces** solve the adjacent case of sibling
  packages living in the *same* repo, but not independently-cloned repos.

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
`pyproject.toml`. Verified empirically (uv 0.11.27) that `[tool.uv.sources]`
can *only* live in `pyproject.toml` — never in any `uv.toml`, project-local
or global (`~/.config/uv/uv.toml`); uv hard-errors with `sources is only
applicable in the context of a project`. So there is no config-layering
escape hatch — this system builds one out of git's own filter/hook
mechanisms instead. Pieces, all global (no per-repo setup):

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
