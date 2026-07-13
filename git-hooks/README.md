# Global git hooks

Git hooks that run in **every** repository on this machine, installed once via
`git config --global core.hooksPath` (see [Setup](#setup) below).

## How the dispatching works

Git only ever runs one file per hook name, so each hook here (`pre-commit`,
`post-checkout`, `post-commit`, `post-merge`) is an identical one-line stub that
sources `dispatch.sh`, which derives the hook name from `$0` and then, in order:

1. Runs every executable script in the matching `<hook-name>.d/` directory, in
   sorted order (hence the `10-`, `20-` numeric prefixes).
2. Runs the repository's own `.githooks/<hook-name>`, if it has one and its
   hooks are trusted — see [Repo-local hooks](#repo-local-hooks) below.
3. Chains to the repository's `.git/hooks/<hook-name>`, if one exists and is
   executable. This matters because setting `core.hooksPath` otherwise
   *shadows* `.git/hooks/`, which would silently disable hooks installed by
   tools like pre-commit or husky.

A failing script aborts the git command for a `pre-*` hook and is only a warning
for a `post-*` one. That is less a policy than an observation: blocking a commit
that should not happen is the entire point of a pre-commit hook, while a
post-commit hook runs after the fact and has nothing left to stop.

So each real concern lives in its own small file under `<hook-name>.d/`, and
adding a new one is just a matter of dropping in an executable script.

## Repo-local hooks

A repository can ship hooks to everyone who clones it by checking them in at
`.githooks/<hook-name>` (executable). Nothing is installed per clone: step 2
above finds them. This is how, for example,
[exact-video-engine.js](https://github.com/jasper-tms/exact-video-engine.js)
keeps its release version in sync on commit.

That step runs code that arrived in a clone, which is precisely what git refuses
to do by default — hooks live in `.git/hooks`, outside the tree and never
cloned, so that cloning a repo cannot make it execute code on your next commit.
We reopen that door only for repos whose `origin` belongs to an account listed
in [`trusted-remotes`](trusted-remotes). Any other repo's checked-in hooks are
skipped, with a note on stderr saying so — never silently, since a hook that a
repo went to the trouble of shipping and that then quietly does not run is the
one outcome nobody would ever think to investigate.

`trusted-remotes` is a code-execution boundary, not a convenience list: an
account belongs in it only if you would run its repos' scripts without reading
them.

To decide for a single repo either way, regardless of who owns it:

```bash
git config hooks.allowRepoHooks true    # or false, which wins even for your own repos
```

A repo that wants a hook to run for *anyone* who clones it, not just you, should
say so in its README — the portable, shadow-free install being:

```bash
ln -s ../../.githooks/pre-commit .git/hooks/pre-commit
```

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
