---
name: finishing-tasks-in-repos
description: Load after completing any work that created or changed files in any git repo, to learn how to write the commit script the user expects. Load even for tiny edits to git-tracked code, docs, configs, or skill – your job isn't done until you do.
---

# Git commit script workflow

Do not commit changes yourself (unless explicitly asked to). Instead, once a
task is finished and the updated behavior is confirmed to be correct (either
the user says so or you verify it yourself), create a script
`commit_{yymmdd}{ABC...}_{one-or-two-word-description}.sh` (e.g.
`commit_260130A_button_behavior.sh`) in the root of each repository worked on.
Include `git add` commands for the relevant files and a
`git commit -m "{commit message}"` command. `chmod +x` the file so the user can
run it.

If an "A" script already exists for that day, use "B" in the filename, and so
on. Re-index from A if all earlier scripts for a repo have been run. Expect the
user to run these scripts quite quickly after you create them, so never assume
a script you recently wrote still exists. If the user asks for further changes
before committing, update the same script as needed.

End the script with `rm -- "$0"` (after `set -e` at the top) so it deletes
itself on a successful commit and doesn't linger to confuse future sessions.
If the script must `cd`, first capture an absolute self-path
(`self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"`) and `rm -- "$self"`,
since a relative `$0` won't resolve after the `cd`.

## Unrelated changes in the same files

If there are uncommitted changes unrelated to the task but in the exact file(s)
that you worked on, warn the user about this and proceed with care so that
unrelated changes don't get staged accidentally: use `git apply --cached`
command(s) in the commit script instead of `git add` when necessary to stage
your changes to any mixed files.

## Look for and reference related issues

If the user has not indicated which issue the work relates to, list the open
issues with their numbers and titles:

```bash
gh issue list --state open --limit 100 --json number,title -q '.[] | "#\(.number) \(.title)"'
```

If there's an obvious match, consider that the issue to reference. If there's
ambiguity, read the issue(s) post and/or comments to investigate and choose,
falling back to asking the user in case the uncertainty remains after that. You
will reference the chosen issue(s) in the next section. If `gh` errors (e.g. no
GitHub remote), or returns no open issues that seem relevant based on their
titles, consider there to be no related issue and silently move on.

## Commit messages

The commit message must start with a verb and be 72 characters or less.
Reference any related issue(s) within those 72 characters by ending with
"Fix #9" when the commit constitutes an essentially complete fix such that the
issue can be closed, and/or "See #42[, #64]" when related to an issue but the
commit doesn't fully resolve it.
For complex commits, add an extended (multi-line) commit message briefly
mentioning key decisions and changes made, without much in the way of
implementation details. Pass extended messages via a stdin heredoc like
`git commit -F - <<'EOF' ... EOF` (NOT `git commit -m "$(cat <<'EOF' ... EOF)"`
which fails to parse correctly in some bash versions).

## When asked to run the script yourself
If the user explicitly asks you to run a commit script yourself, do so, then
verify the completed commit contains exactly the intended changes and nothing
extra. This is to guard against the possibility that another agent edited one
of the files that your commit script runs `git add` on between you looking at
the file and you running the commit script.
