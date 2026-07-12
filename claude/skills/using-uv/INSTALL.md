# One-time setup: personal editable-install registry (new machine)

Only needed once per machine, to set up the system described in the "using-uv"
skill's "Personal editable-install registry" section. Assumes this repo
(`shell-configs`) is already cloned and its `shell_scripts/` directory is on
`PATH` (that's where `refresh-uv-editables` is symlinked from).

Adjust `SHELL_CONFIGS` below if this repo lives somewhere other than
`~/repos/jasper-tms/shell-configs` on this machine.

```bash
SHELL_CONFIGS=~/repos/jasper-tms/shell-configs

# 1. Confirm the script resolves via PATH.
which refresh-uv-editables   # should print $SHELL_CONFIGS/shell_scripts/refresh-uv-editables

# 2. Pre-flight: confirm this machine has no pre-existing global hooks dir or
#    attributes file that step 5 would silently clobber. Both commands should
#    print nothing and exit 1. If either prints a path, STOP and reconcile by
#    hand (only one hooks directory and one attributes file can win globally)
#    -- see the Notes at the bottom.
git config --global --get core.hooksPath
git config --global --get core.attributesFile

# 3. Create the registry, seeded with which GitHub accounts/orgs are yours.
#    Add [packages] entries for whichever local clones you want editable-
#    linked. The KEY MUST BE the package's real declared distribution name,
#    NOT the repo's directory name -- these differ more often than you'd
#    expect. Read it out of each repo's pyproject.toml ([project] name) or
#    setup.py/setup.cfg (name=), rather than guessing from the folder:
#      npimage/                 declares  numpyimage
#      pytransformix/           declares  transformix
#      the-BANC-fly-connectome/ declares  banc
#      bikini-bottom/           declares  bikinibottom
#      DeepFly3D/               declares  nely-df3d
#    Renamed forks are a deliberate case: our pyrender/ declares pyrender2
#    and our nptyping/ declares np2typing, precisely so that a project
#    depending on the real upstream pyrender/nptyping still resolves from
#    PyPI instead of being hijacked to the fork. Register them under the
#    renamed names; depend on the renamed names to get the fork.
#    Paths may use ~ for the home directory -- if your clones live at the
#    same path relative to $HOME on every machine, this whole file (once
#    populated) can just be copied verbatim between machines instead of
#    retyped.
mkdir -p ~/.config/uv
cat > ~/.config/uv/local-packages.toml <<'EOF'
personal-remotes = ["jasper-tms", "NeLy-EPFL"]

[packages]
EOF

# 4. Global gitattributes: routes pyproject.toml through the uv-sources filter
#    in every repo, with no per-repo .gitattributes file needed.
cat > ~/.gitattributes_global <<'EOF'
pyproject.toml filter=uv-sources
EOF

# 5. Global git config: hooks directory, attributes file, and the filter
#    driver itself. The filter is not optional bookkeeping -- without the
#    clean driver, nothing strips the auto-generated block, and the hooks
#    will happily commit your local machine's absolute paths into every
#    pyproject.toml. Registry without filter is worse than neither.
git config --global core.hooksPath "$SHELL_CONFIGS/git-hooks"
git config --global core.attributesFile ~/.gitattributes_global
git config --global filter.uv-sources.clean "refresh-uv-editables --clean"
git config --global filter.uv-sources.smudge "refresh-uv-editables --smudge"
```

## Verify it worked

Depend on one package you actually registered in step 3 plus one ordinary PyPI
package, so this exercises the whole loop: the hook injecting a source block,
the registry resolving the local clone, PyPI deps being left alone, and the
clean filter stripping the block back out before it can reach a commit. Set
`LOCAL_PKG` to any key from your registry's `[packages]` table.

```bash
LOCAL_PKG=numpyimage   # any registered name

rm -rf /tmp/uv-install-check
mkdir -p /tmp/uv-install-check && cd /tmp/uv-install-check
git init --quiet -b main
cat > pyproject.toml <<EOF
[project]
name = "check"
version = "0.1.0"
dependencies = ["$LOCAL_PKG", "requests"]
EOF
git add pyproject.toml && git commit --quiet -m "check"

echo "--- working tree (want: a uv-local-sources block pointing $LOCAL_PKG at its clone,"
echo "                       and NO entry for requests, which must come from PyPI) ---"
cat pyproject.toml
echo "--- what git actually stored (want: NO uv-local-sources block at all) ---"
git show HEAD:pyproject.toml
echo "--- git status (want: empty; the injected block must not read as a diff) ---"
git status --short

cd - && rm -rf /tmp/uv-install-check
```

All three expectations must hold. In particular, if the block shows up in
`git show HEAD:pyproject.toml`, the clean filter is not wired up and you are
committing machine-local absolute paths — fix step 5 before using this on a
real repo.

## Notes

- Step 2 exists because `core.hooksPath` and `core.attributesFile` are global
  and single-valued: setting them overwrites whatever was there, and setting
  `core.hooksPath` additionally *shadows* every repo's `.git/hooks/`, which is
  how tools like pre-commit and husky install themselves. Our dispatchers in
  `git-hooks/` chain back to `.git/hooks/<name>` specifically to undo that
  shadowing, but a hooks directory you did *not* write has no reason to. If a
  machine already has either setting pointed somewhere else, reconcile by hand
  — see the skill doc for why this is a global, not per-repo, mechanism.
- `~/.config/uv/local-packages.toml` and `~/.gitattributes_global` are
  machine-local files, not tracked by this repo's git history — re-run step 2
  and 3 above on each new machine. Since `[packages]` paths may use `~`
  (see step 2), if your clones live at consistent paths relative to `$HOME`
  across machines, you can just copy your populated
  `~/.config/uv/local-packages.toml` over instead of retyping it.
