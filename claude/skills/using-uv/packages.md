# Real installable packages (pyproject.toml projects)

- `uv add`/`uv sync` write standard `[project.dependencies]`, which pip,
  poetry, etc. all read fine — a non-uv user can `pip install .` with no
  issue, in general.
- **Exception: `[tool.uv.sources]` is invisible to pip.** If you point a
  dependency at a local clone or git repo via `--editable`/`[tool.uv.sources]`
  and it needs to also work for someone running plain `pip install .`, express
  it directly in `[project.dependencies]` using standard PEP 508 syntax
  instead/also, e.g. `"numpyimage @ git+https://github.com/jasper-tms/npimage"`
  (note the declared name must match the target's own `[project.name]` — e.g.
  the `npimage` repo's package is actually named `numpyimage`). Otherwise pip
  sees only the bare name, tries to fetch it from PyPI, and fails (or worse,
  installs an unrelated same-named package).
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
