---
name: virtualenvwrapper-setup
description: Install and configure virtualenvwrapper for Python virtual environments, including the login-shell PATH-ordering gotcha that makes `workon` silently not stick. Use when a user asks to install, set up, or troubleshoot a virtualenvwrapper installation (e.g. `workon`/`mkvirtualenv` missing, or `which pip`/`which python` resolving to the wrong environment).
---

# Skill: Installing virtualenvwrapper

virtualenvwrapper isolates each project's packages behind
`workon <env>` / `mkvirtualenv <env>`, actually working from
venv files in `WORKON_HOME` (typically set to `~/.virtualenvs`),
avoiding cross-project dependency conflicts.

## 1. Determine the Python version

List the available Python interpreters and pick the newest Python 3, e.g.:

```bash
compgen -c | grep -E '^python[0-9.]*$' | sort -u | while read -r py; do
    printf '%s -> ' "$(command -v "$py")"; "$py" --version
done
```

Note the full path of the newest one (e.g. `/usr/bin/python3.12`) for the
next step — but see the venv-support caveat in step 2: on Debian/Ubuntu the
newest system Python may not be able to create venvs, in which case fall
back to the newest one that can.

## 2. Create a dedicated venv to host virtualenvwrapper

Replace `/usr/bin/python3.12` with the path from step 1:

```bash
cd ~
mkdir .venv
cd .venv
/usr/bin/python3.12 -m venv venv-for-virtualenvwrapper
source venv-for-virtualenvwrapper/bin/activate
```

Confirm with `which pip` — it should point inside `~/.venv`.

If `-m venv` fails with an `ensurepip … returned non-zero exit status`
error, that Python lacks its venv support — common on Debian/Ubuntu, where
the newest system Python is often missing its `python3.X-venv` package.
Either install it (`sudo apt install python3.12-venv`) or fall back to an
older Python 3 from step 1 whose `python -m venv` works. This is why step 1
picks "newest Python 3 *that can create venvs*", not simply the newest.

## 3. Install virtualenvwrapper into that venv

The guards verify `pip` resolves inside `venv-for-virtualenvwrapper` before
installing, so a mis-activated environment can't install into the wrong place:

```bash
source ~/.venv/venv-for-virtualenvwrapper/bin/activate
pip_path=$(which pip)
pip_found=0
pip_path_valid=0
if [ -n "$pip_path" ]; then pip_found=1; fi
if [ -z "${pip_path/*venv-for-virtualenvwrapper*/}" ]; then pip_path_valid=1; fi
if [ "$pip_found" -eq 1 -a "$pip_path_valid" -eq 1 ]; then pip install virtualenvwrapper; fi
```

## 4. Configure it in `~/.bashrc`

Add:

```bash
venv_root=$HOME/.venv/venv-for-virtualenvwrapper
export VIRTUALENVWRAPPER_PYTHON=$venv_root/bin/python
export VIRTUALENVWRAPPER_VIRTUALENV=$venv_root/bin/virtualenv
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$HOME/Devel
source $venv_root/bin/virtualenvwrapper.sh
```

Then start a fresh login+interactive shell so the new `~/.bashrc` config is
sourced (initialization messages confirm it loaded), and create the first
environment:

```bash
bash -lic 'mkvirtualenv base && which pip'
```

After that, `workon <env>` switches between environments and `mkvirtualenv
<env>` creates new ones.

## 5. Gotcha: make sure `workon` actually wins the PATH

`workon <env>` prepends that environment's `bin/` to `PATH`. If you add a
`workon <env>` line to `~/.bashrc` to auto-activate on shell start, that only
sticks if nothing runs *after* it that also edits `PATH`.

A login shell's `~/.profile`/`~/.bash_profile` commonly does `. ~/.bashrc`
partway through, then keeps executing. Any PATH edit later in `.profile`
(e.g. `PATH="$HOME/.local/bin:$PATH"`, a `pyenv`/`nvm`/`conda` init block,
distro-added exports) runs *after* `workon` and silently overrides its
prepend — `workon` reports success but `which pip`/`which python` resolves
elsewhere, with no error.

As a final install step, and whenever troubleshooting this symptom:

- `type -a python pip` — first match in `PATH` wins; confirm the env's `bin/`
  is actually first. `bash -lic 'echo $PATH'` shows a real login shell's
  final `PATH`.
- **Always inspect `~/.profile`/`~/.bash_profile` for PATH edits after the
  `. ~/.bashrc` line, and always tell the user what you find:** if readable,
  flag each offending line by name and recommend removing it or moving it
  *before* the `.bashrc` source line; if unreadable (permission/deny rule),
  say it *might* contain such edits and ask the user to check.
- Don't just add another `workon` call further down as a patch — that hides
  the ordering bug instead of fixing it.

Folding `.profile`'s PATH edits into `.bashrc` is one fix but only safe if
nothing besides interactive bash shells needs them: non-interactive/non-login
contexts (cron, `ssh host cmd`, `bash script.sh`) never source `.bashrc`, and
GUI-launched apps usually inherit env from `.profile`. If anything outside
interactive bash needs the entry, keep it in `.profile` and just move it
before the `. ~/.bashrc` line.
