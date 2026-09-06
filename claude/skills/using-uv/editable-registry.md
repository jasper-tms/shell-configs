# Personal editable-install registry, across independently-cloned repos

If setting this up on a new computer, read `INSTALL.md` in this same folder
first — one-time setup steps (global git config, initial registry file)
that aren't worth keeping in this file.

Solves: many separate downstream project repos each wanting to depend on a
package you have cloned locally (e.g. `npimage`) in editable mode, without
hand-writing a personal absolute path into each project's committed
`pyproject.toml`. Since `[tool.uv.sources]` can only live in a `pyproject.toml`
(see standalone-scripts.md), there's no global-config escape hatch — so this
system builds one out of git's own filter/hook mechanisms instead. Pieces, all
global (no per-repo setup):

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
