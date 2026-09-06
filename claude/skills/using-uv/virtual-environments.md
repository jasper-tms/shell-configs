# Virtual environments made with `uv venv` (and the bin/pip shim)

For a long-lived environment you activate by name rather than a per-project
`.venv`, create it under `~/.virtualenvs/` so virtualenvwrapper's `workon`
still lists and activates it — `workon` only needs a `bin/activate`, which
`uv venv` writes, and it does not care that uv rather than virtualenv built
the environment. (uv marks its own: `pyvenv.cfg` gets a `uv = <version>`
line where virtualenv would write `virtualenv = <version>`.)

**Always drop in the pip shim** (step 3 below). `uv venv` deliberately
installs no pip, so a bare `pip install ...` typed in an activated uv
environment is not found in its `bin/` and the shell keeps walking PATH until
it hits an unrelated pip — on a virtualenvwrapper machine, the one belonging
to the virtualenvwrapper installation itself. That pip hardcodes its own
interpreter in its shebang and ignores `$VIRTUAL_ENV`, so it installs into
that other environment and reports success. The package is then not
importable from the environment that is actually active, and nothing in the
output says why. This is silent and easy to hit, so treat the shim as part of
creating the environment, not an optional extra.

```bash
# 1. Create it (--python pins the interpreter; workon finds it here)
uv venv ~/.virtualenvs/<name> --python 3.13

# 2. Populate it. uv pip honors $VIRTUAL_ENV, so set it per command rather
#    than activating; -e installs a local clone editable.
VIRTUAL_ENV=~/.virtualenvs/<name> uv pip install <packages>
VIRTUAL_ENV=~/.virtualenvs/<name> uv pip install -e ~/repos/<org>/<repo>

# 3. Install the pip shim, so a bare `pip` can never misfire
cp ~/.claude/skills/using-uv/scripts/uv-venv-pip-shim \
   ~/.virtualenvs/<name>/bin/pip
chmod +x ~/.virtualenvs/<name>/bin/pip
ln -sf pip ~/.virtualenvs/<name>/bin/pip3
```

The shim (canonical copy: `scripts/uv-venv-pip-shim` in this skill folder)
resolves its own environment from its own location and forwards everything to
`uv pip` with `UV_PYTHON` set to that environment's interpreter. Notes on it:

- It works for `pip` run from scripts, Makefiles, and cron too, not just at
  an interactive prompt — which is exactly why this is a file in `bin/`
  rather than a shell function in a `.bashrc` or shell-config repo. Do not
  "simplify" it back into an alias or function.
- `UV_PYTHON` beats `$VIRTUAL_ENV`, so `<env>/bin/pip` always acts on
  `<env>`, even while a different environment is active.
- It finds `uv` via PATH, then falls back to `~/.local/bin/uv`,
  `/usr/local/bin/uv`, `/opt/homebrew/bin/uv`, because callers with a
  stripped PATH (cron, Makefiles) otherwise fail to find it. If uv is truly
  unavailable it exits non-zero rather than letting a foreign pip through.
- `uv pip` covers install/uninstall/list/freeze/show/tree/check/sync/compile
  but not every pip subcommand, so e.g. `pip config list` errors instead of
  running. That is the intended tradeoff.
- `python -m pip` still fails with "No module named pip" — a `bin/` file
  cannot fix module lookup. Use `pip` or `uv pip`.
- Anything looping over `~/.virtualenvs/*/` to upgrade pip must test
  `python -c "import pip"`, not `-x bin/pip`: the shim makes the file test
  pass in environments that have no real pip. `shell_scripts/pipup` in
  jasper-tms/shell-configs already does this.
