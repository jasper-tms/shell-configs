---
name: tidy-repos-and-skills
description: The nightly autonomous maintenance pass that pulls every repo on this machine and keeps the skill indexes in sync - each agent-skills folder's INDEX.md and the global ~/.claude/skills/_SKILL_LISTING.md. Load when running, editing, or debugging that task (the cron_tasks/tidy-repos-and-skills job), when an INDEX.md or _SKILL_LISTING.md looks stale or wrong, or when asked to regenerate a skill folder's index.
---

# Tidy repos and skills (nightly maintenance)

This skill is the playbook for the autonomous nightly task
`~/cron_tasks/tidy-repos-and-skills/`, which runs headless (`claude -p`)
overnight. It pulls every repo on this machine and keeps two kinds of skill
index in sync with the actual `SKILL.md` files on disk:

- a per-folder `INDEX.md` in each version-controlled agent-skills folder, and
- the single global `~/.claude/skills/_SKILL_LISTING.md` (names + locations).

The same steps are useful interactively whenever an index looks stale, so the
skill is loadable by any agent, not only the cron job.

## This task commits and pushes on its own

This is the deliberate exception to the normal `finishing-tasks-in-repos`
convention (which writes a `commit_*.sh` script for Jasper to run). The nightly
task is autonomous and self-authorized: it commits its index fixes and
**pushes** them directly. Still follow the message conventions (under 73
characters, start with a verb). Never force-push. If a repo cannot be pushed
safely (no upstream, or the push is rejected), do not fight it - record it in
the report and move on.

## The six indexed folders

Exactly these version-controlled agent-skills folders carry an `INDEX.md`:

- `~/repos/jasper-tms/shell-configs/claude/skills`
- `~/repos/jasper-tms/raspberry-pi/agent-skills`
- `~/repos/jasper-tms/swiss-table-tennis-chat/agent-skills`
- `~/repos/scoreTec/reaction-time-web-app/agent-skills`
- `~/repos/jasper-tms/exact-video-engine.js/agent-skills`
- `~/repos/movim/agent-skills`

Deliberately excluded: `swiss-table-tennis-chat/skills/` (the chatbot app's own
runtime skills, not agent skills) and `~/.claude/skills/` (a symlink farm plus
the unversioned third-party `runpodctl`, not in any repo).

## Regenerating an INDEX.md: use build_index.py

Never hand-transcribe an `INDEX.md`. This skill ships `build_index.py`, which
reads each `SKILL.md`'s frontmatter and deterministically rewrites the folder's
`INDEX.md` (skills sorted by name, so diffs stay stable). This skill is
intentionally **not** symlinked into `~/.claude/skills`, so refer to
`build_index.py` by its real path next to this `SKILL.md`. Run it per folder:

```bash
build_index=~/repos/jasper-tms/shell-configs/claude/skills/tidy-repos-and-skills/build_index.py
python3 "$build_index" ~/repos/jasper-tms/raspberry-pi/agent-skills
```

The generated file is repo-relative and clone-portable:

```
# Skill index for `raspberry-pi/agent-skills/`
Each skill below can be found at `raspberry-pi/agent-skills/<skill-name>/SKILL.md`
- name: <skill-name>. description: <description>
...
```

## Nightly sequence

Run these in order. Keep a running note of everything worth reporting.

### 1. Pull every repo, rebasing where needed

Run `pullrepos` (it pulls all repos under `~/repos` in parallel, times out and
retries hangs, and prints a summary of any repos whose GitHub credentials
aren't cached). `pullrepos` uses a plain `git pull`, which does not resolve a
repo that has **unpushed local commits and an advanced remote**
(non-fast-forward). So after `pullrepos`, sweep every repo and repair those:

```bash
for gitdir in ~/repos/*/.git ~/repos/*/*/.git; do
    repo="${gitdir%/.git}"
    git -C "$repo" rev-parse --abbrev-ref --symbolic-full-name @{u} \
        >/dev/null 2>&1 || continue          # skip: no upstream
    # Behind or diverged from upstream? rebase local commits on top.
    counts=$(git -C "$repo" rev-list --left-right --count HEAD...@{u} 2>/dev/null) || continue
    behind=$(printf '%s' "$counts" | awk '{print $2}')
    [ "${behind:-0}" -gt 0 ] || continue
    git -C "$repo" pull --rebase --autostash || {
        git -C "$repo" rebase --abort 2>/dev/null
        echo "REBASE CONFLICT (left for manual fix): $repo"
    }
done
```

Record, for the report: repos that were rebased, repos that hit a rebase
conflict (aborted, untouched), and any credential failures from `pullrepos`.

### 2. Rebuild the six INDEX.md files

Run `build_index.py` on each of the six folders (see above). Then, per repo,
`git diff --stat` the `INDEX.md` to see what actually changed. A changed
`INDEX.md` means a skill was added, removed, or had its description edited.

### 3. Reconcile the global _SKILL_LISTING.md

`~/.claude/skills/_SKILL_LISTING.md` (real file:
`~/repos/jasper-tms/raspberry-pi/agent-skills/_SKILL_LISTING.md`) lists every
skill by **name** under its real-folder heading, plus symlink/consumer notes.
It carries names and locations only - no descriptions (those live in the
`INDEX.md` files). This step needs judgment, which is why the task is agentic:

- Every skill directory that exists on disk (in any indexed folder, and in the
  other folders the listing already covers) must appear under the correct
  heading. Add any that are missing.
- Every skill named in the listing must still exist on disk. Remove stale ones.
- Preserve the file's structure and its per-skill annotations (e.g.
  `(NOT symlinked into ~/.claude/skills)`); only add/remove skill lines, don't
  reflow the prose.

### 4. Commit and push per repo

For each repo touched in steps 1-3, commit the changed files with a verb-first
message under 73 characters (e.g. `Refresh skill INDEX.md files`,
`Sync _SKILL_LISTING.md with skills on disk`) and push to its upstream. Never
force-push. A repo with no upstream or a rejected push: skip and report it.

### 5. Write the report file

Write your final summary to the path in the `TIDY_REPORT_FILE` environment
variable. The **first line** is the machine-readable status the wrapper keys
on:

- `STATUS: quiet` - everything pulled cleanly, no index drift, nothing pushed,
  nothing needs attention. The wrapper sends no email.
- `STATUS: report` - anything changed or anything needs attention. The wrapper
  emails the rest of the file.

After the status line, write a short human summary: repos rebased, INDEX.md /
_SKILL_LISTING.md changes committed and pushed (name the repos), and a clearly
separated **Needs attention** section for rebase conflicts, credential
failures, and rejected pushes. If you could not finish, still write the file
with `STATUS: report` and explain how far you got - a missing report file makes
the wrapper send a generic failure email.

## Testing without spamming Jasper

`run.sh --dry-run` runs the whole task but the email step only prints what it
would send. Use it to verify behavior without mailing anyone.
