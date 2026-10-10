# Claude Code's `grep` wrapper silently skips gitignored files

Found 2026-10-10 with Claude Code 2.1.296 (zsh, macOS).

## Problem

Inside Claude Code's Bash tool, `grep` is not `/usr/bin/grep`. Claude Code's
shell snapshot (`~/.claude/shell-snapshots/snapshot-zsh-*.sh`) defines a
`grep` shell function that runs an embedded `ugrep` with extra flags:

```zsh
ARGV0=ugrep "$_cc_bin" -G --ignore-files --hidden -I --exclude-dir=.git ... "$@"
```

`--ignore-files` makes recursive searches skip anything excluded by a
`.gitignore`. Plain grep has no such behavior, and the agent has no way to
tell that results were dropped: the command still exits 0 with no warning.

This bites hard in `~/repos/movim`, which is a git repo whose `.gitignore`
lists every sub-repo (`SportID`, `videopose`, `runpod-config`, ...). So
`grep -r <pattern> ~/repos/movim` searches almost nothing and reports no
matches, even for strings that definitely exist in those sub-repos. In one
session this made an agent wrongly conclude that no code referenced some
renamed video paths, when about 15 files did.

## Minimal reproduction

Run inside Claude Code's Bash tool:

```zsh
mkdir -p /tmp/grepdemo/ignored_dir && cd /tmp/grepdemo
printf 'ignored_dir/\n' > .gitignore
echo needle > ignored_dir/file.txt
echo needle > visible.txt

type grep                   # "grep is a shell function from .../shell-snapshots/..."
grep -rl needle .           # prints only: visible.txt
command grep -rl needle .   # prints: ./visible.txt and ./ignored_dir/file.txt
```

Both commands exit 0. Note that a `.gitignore` alone is enough to trigger
this; the folder does not even need to be a git repo.

## Workarounds while a fix is pending

- Use `command grep` or `/usr/bin/grep` when a search must be exhaustive.
- Or pass `--no-ignore-files` (a ugrep flag) to the wrapper.

## Open questions for the fix

- Can the wrapper be disabled with a setting or environment variable, or
  overridden from `~/.zshrc` (the snapshot is sourced after it)?
- Should a note in `claude/CLAUDE.md` tell agents to use `command grep` for
  exhaustive searches instead?
- Is this worth reporting to Anthropic as a Claude Code bug? At minimum the
  wrapper should warn when it skips ignored files.
