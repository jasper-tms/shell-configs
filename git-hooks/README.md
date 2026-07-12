# Global git hooks

Git hooks that run in **every** repository on this machine, installed once via
`git config --global core.hooksPath` (see [Setup](#setup) below).

## How the dispatching works

Git only ever runs one file per hook name, so each hook here
(`post-checkout`, `post-commit`, `post-merge`) is a small dispatcher that:

1. Runs every executable script in the matching `<hook-name>.d/` directory, in
   sorted order (hence the `10-`, `20-` numeric prefixes). A script that fails
   prints a warning but does not stop the others or the git command itself.
2. Chains to the repository's own `.git/hooks/<hook-name>`, if one exists and is
   executable. This matters because setting `core.hooksPath` otherwise
   *shadows* `.git/hooks/`, which would silently disable hooks installed by
   tools like pre-commit or husky.

So each real concern lives in its own small file under `<hook-name>.d/`, and
adding a new one is just a matter of dropping in an executable script.

## The hooks we currently have

- `post-checkout.d/10-refresh-uv-editables.sh`
  On a *fresh clone* (git passes an all-zeros previous HEAD), registers the repo
  in the local-packages registry if it belongs to one of your GitHub
  accounts/orgs. Then, if the repo has a `pyproject.toml`, refreshes its
  auto-generated `[tool.uv.sources]` block.

- `post-checkout.d/20-symlink-skills.sh`
  Offers to symlink any not-yet-linked Claude skills found in the repo's
  `skills/` or `agent-skills/` folders into Claude Code's global skills folder.

- `post-commit.d/10-refresh-uv-editables.sh`
  Re-adds the auto-generated `[tool.uv.sources]` block to the working tree after
  a commit strips it out.

- `post-merge.d/10-refresh-uv-editables.sh`
  Same `[tool.uv.sources]` refresh, after a `git pull`/`git merge`.

- `post-merge.d/20-symlink-skills.sh`
  Same skill-symlinking offer, after a `git pull`/`git merge`.

Both underlying commands are resolved from `PATH`, which
`configure.sh` populates with this repo's `shell_scripts/` directory:

- **`refresh-uv-editables`** — points dependencies that you have local clones of
  at those clones, editably. The generated block is deliberately never
  committed: a global git `clean` filter strips it before staging, and this
  script (from these hooks, or run by hand) puts it back in the working tree.
  Full explanation in `claude/skills/using-uv/SKILL.md`.
- **`symlink-skills`** — makes a repo's skills visible to Claude Code
  everywhere on the machine. It prompts on the terminal, and quietly skips
  prompting when there isn't one (e.g. in a script or a GUI git client).

## Setup

The hooks themselves are enabled with a single global git config setting:

```bash
git config --global core.hooksPath ~/repos/jasper-tms/shell-configs/git-hooks
```

(Adjust the path if this repo is cloned somewhere else on this machine.)

That's all that's needed for `symlink-skills` to work. The
`refresh-uv-editables` hooks additionally need the local-packages registry and
the `uv-sources` git filter to exist — that's a few more one-time commands,
written out in `claude/skills/using-uv/INSTALL.md`, which also includes the
`core.hooksPath` line above so you can just follow that file end-to-end on a
new machine.

### Notes

- If a machine already has its own `core.hooksPath` set to something else, do
  **not** blindly overwrite it — reconcile the two by hand, since only one
  directory can win.
- Any new script added under a `<hook-name>.d/` directory must be executable
  (`chmod +x`), or the dispatcher will skip it.
- To add a new hook type (e.g. `pre-push`), copy one of the existing dispatchers
  to that name and create the matching `pre-push.d/` directory. The dispatchers
  are identical apart from their comments — they derive the hook name from
  `$0`.
