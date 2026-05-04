# neovim

Configuration for Neovim, including Python linting and formatting via
[ALE](https://github.com/dense-analysis/ale) + [ruff](https://docs.astral.sh/ruff/).

## Setup

### 1. Symlink `nvim-init.vim` to Neovim's config location

```sh
mkdir -p ~/.config/nvim
ln -sf "$(realpath nvim-init.vim)" ~/.config/nvim/init.vim
```

Then launch `nvim` once and run `:PlugInstall` to install the plugins
(this requires [vim-plug](https://github.com/junegunn/vim-plug) to be
installed first).

### 2. Create a virtualenv with `ruff` (and Neovim's Python provider, if needed)

The init file expects a virtualenv at `$WORKON_HOME/neovim-plugins`
(falling back to `~/.virtualenvs/neovim-plugins`) containing `ruff`:

```sh
python3 -m venv ~/.virtualenvs/neovim-plugins
~/.virtualenvs/neovim-plugins/bin/pip install ruff
```

### 3. Symlink the ruff config to the user-global location

This makes `ruff` (CLI and ALE) discover the config from any directory
when no project-local `pyproject.toml`/`ruff.toml` exists:

```sh
mkdir -p ~/.config/ruff
ln -sf "$(realpath ruff.toml)" ~/.config/ruff/ruff.toml
```

Project-local ruff configs still take precedence — this is just the
fallback for files outside any configured project.

## Behavior

- **Linting** runs automatically via ALE using `ruff check`. Warnings
  appear in the gutter and the location list. Use `]A` / `[A` to jump
  to the next/previous warning, or `]a` / `[a` to skip codes listed in
  `s:ale_skip_codes` (currently just `E501`, line-too-long).
- **Format on save** uses `ruff format` and is **opt-in**, controlled
  by the `RUFF_FORMAT_ON_SAVE` environment variable:

  | Value                       | Behavior                |
  | --------------------------- | ----------------------- |
  | unset or `0`                | no format on save       |
  | any other value (e.g. `1`)  | format on save          |

  Set per-session:

  ```sh
  RUFF_FORMAT_ON_SAVE=1 nvim some_file.py
  ```

  Or per-shell / globally:

  ```sh
  export RUFF_FORMAT_ON_SAVE=1
  ```

  You can still trigger a one-off format from inside Neovim with
  `:ALEFix` regardless of the env var.
