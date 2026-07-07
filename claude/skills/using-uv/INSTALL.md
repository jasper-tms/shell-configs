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

# 2. Create the registry, seeded with which GitHub accounts/orgs are yours.
#    Add [packages] entries for whichever local clones you want editable-
#    linked (name = the package's real declared distribution name, which
#    can differ from its repo directory name -- check its pyproject.toml).
#    Paths may use ~ for the home directory -- if your clones live at the
#    same path relative to $HOME on every machine, this whole file (once
#    populated) can just be copied verbatim between machines instead of
#    retyped.
mkdir -p ~/.config/uv
cat > ~/.config/uv/local-packages.toml <<'EOF'
personal-remotes = ["jasper-tms", "NeLy-EPFL"]

[packages]
EOF

# 3. Global gitattributes: routes pyproject.toml through the uv-sources filter
#    in every repo, with no per-repo .gitattributes file needed.
cat > ~/.gitattributes_global <<'EOF'
pyproject.toml filter=uv-sources
EOF

# 4. Global git config: hooks directory, attributes file, and the filter
#    driver itself.
git config --global core.hooksPath "$SHELL_CONFIGS/git-hooks"
git config --global core.attributesFile ~/.gitattributes_global
git config --global filter.uv-sources.clean "refresh-uv-editables --clean"
git config --global filter.uv-sources.smudge "refresh-uv-editables --smudge"
```

## Verify it worked

```bash
rm -rf /tmp/uv-install-check
mkdir -p /tmp/uv-install-check && cd /tmp/uv-install-check
git init --quiet -b main
cat > pyproject.toml <<'EOF'
[project]
name = "check"
version = "0.1.0"
dependencies = []
EOF
git add pyproject.toml && git commit --quiet -m "check"
refresh-uv-editables   # should print "no changes needed" (empty deps, nothing to inject)
cd - && rm -rf /tmp/uv-install-check
```

If that runs with no errors, the filter/hooks/registry are wired up correctly.

## Notes

- Before this setup, on this machine: `git config --global --get core.hooksPath`
  and `--get core.attributesFile` were both unset, so this is additive, not an
  override of some existing hook/attributes setup. If a *different* machine
  already has its own `core.hooksPath`/`core.attributesFile`, reconcile by
  hand rather than blindly overwriting — see the skill doc for why this is a
  global, not per-repo, mechanism.
- `~/.config/uv/local-packages.toml` and `~/.gitattributes_global` are
  machine-local files, not tracked by this repo's git history — re-run step 2
  and 3 above on each new machine. Since `[packages]` paths may use `~`
  (see step 2), if your clones live at consistent paths relative to `$HOME`
  across machines, you can just copy your populated
  `~/.config/uv/local-packages.toml` over instead of retyping it.
