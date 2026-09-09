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

## This task commits on its own; the wrapper pushes main

This is the deliberate exception to the normal `finishing-tasks-in-repos`
convention (which writes a `commit_*.sh` script for Jasper to run). The nightly
task is autonomous and self-authorized to **commit** its index fixes directly.
Still follow the message conventions (under 73 characters, start with a verb).

Pushing main is **not** your job. A global `gate-git-push.sh` PreToolUse hook
denies an agent `git push` to `main`/`master`/`prod` in this headless run, so
do not attempt one. After you exit, the `run.sh` wrapper pushes the protected
branch for the repos this task maintains (its `git push` runs in the wrapper
shell, not an agent tool call, so the hook never gates it). Just commit and
leave main to the wrapper. (You *may* still push a feature branch yourself if a
repo happens to be on one - the hook allows that.)

## The six indexed folders

Exactly these version-controlled agent-skills folders carry an `INDEX.md`:

- `~/repos/jasper-tms/shell-configs/claude/skills`
- `~/repos/jasper-tms/raspberry-pi/agent-skills`
- `~/repos/jasper-tms/swiss-table-tennis-chat/agent-skills`
- `~/repos/scoreTec/reaction-test/agent-skills`
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

## Validating skill frontmatter

The Agent Skills spec makes both `name:` and `description:` mandatory, and
requires each skill's `name:` to match its parent directory name. This inline
check enforces all three across every skill the global listing knows about. It
reads the folder set straight from
`~/repos/jasper-tms/raspberry-pi/agent-skills/_SKILL_LISTING.md` (no hardcoded
folder list to drift out of date), so a skill added anywhere the listing covers
gets checked automatically, and it reuses `build_index.py`'s frontmatter parser.
Run it and route any output into the report's **Needs attention**:

```bash
python3 - <<'PY'
import re
import sys
from pathlib import Path

tidy_dir = Path(
    "~/repos/jasper-tms/shell-configs/claude/skills/tidy-repos-and-skills"
).expanduser()
sys.path.insert(0, str(tidy_dir))
from build_index import read_frontmatter  # reuse the same frontmatter parser

listing = Path(
    "~/repos/jasper-tms/raspberry-pi/agent-skills/_SKILL_LISTING.md"
).expanduser()

# Derive every (folder, skill-name) pair from the listing: a header naming an
# absolute path sets the folder (and the base for relative sub-folder headers
# like the swiss repo's `### agent-skills/`); bullets beneath it are its skills.
pairs, base, folder = [], None, None
for line in listing.read_text(encoding="utf-8").splitlines():
    header = re.match(r"^#+\s+(.*)$", line)
    if header:
        text = header.group(1).strip().strip("`").rstrip("/")
        if text.startswith(("~", "/")):
            base = folder = Path(text).expanduser()
        elif re.fullmatch(r"[\w.-]+", text) and base is not None:
            folder = base / text
        else:
            folder = None  # prose header, not a folder
        continue
    bullet = re.match(r"^-\s+(\S+)", line)
    if bullet and folder is not None:
        pairs.append((folder, bullet.group(1).strip("`")))

problems = []
for folder, name in pairs:
    if not folder.is_dir():
        continue  # repo not cloned on this machine; nothing to check here
    skill_md = folder / name / "SKILL.md"
    if not skill_md.is_file():
        problems.append(f"{folder / name}: listed but no SKILL.md on disk")
        continue
    fields = read_frontmatter(skill_md)
    fm_name = fields.get("name", "").strip()
    description = fields.get("description", "").strip()
    if not fm_name:
        problems.append(f"{skill_md}: missing mandatory name:")
    elif fm_name != name:
        problems.append(f"{skill_md}: name '{fm_name}' != folder '{name}'")
    if not description:
        problems.append(f"{skill_md}: missing mandatory description:")

print("\n".join(problems) or "all listed skills valid")
sys.exit(1 if problems else 0)
PY
```

Absent folders (repos not cloned on this machine) are skipped. A `listed but no
SKILL.md on disk` line means the listing is stale - normally the reconcile step
below has already removed such an entry; if it persists, the listing points at a
skill that no longer exists.

## Watch for asserted-state drift

Beyond the fixed checks above, stay alert for the general failure they are all
instances of: **a place that asserts some state should be true, which has
silently drifted from what is actually true.** The index files assert "these
skills exist"; frontmatter asserts "`name:` matches the folder"; a README
asserts "the cron line is `0 3 * * *`" or "this file is the source of truth"; a
committed `crontab.txt` asserts "this is the live crontab" (the machine-specific
`crontab -l` vs `crontab.txt` diff, which lives in this task's `run.sh` prompt,
not here). These drift because the assertion and the reality are edited at
different times by different people or agents.

You cannot enumerate every such assertion in advance — new ones appear with every
refactor. So when, in the course of the nightly pull and index work, you happen
to notice a doc, README, comment, or config that clearly states something now
contradicted by reality (a stale schedule, a "source of truth" that has moved, a
path or filename that no longer exists, a count that no longer matches), record
it under **Needs attention** with the file and the specific contradiction. Do
**not** auto-fix it: the correct direction is usually ambiguous (fix the
assertion, or fix the reality?), and that judgment is a human's. Reporting it is
the whole value — a drifted assertion is invisible until someone trusts it.

If a particular assertion turns out to be worth checking every single night,
that is a signal to promote it to a deterministic check (like the frontmatter
validator above, or the crontab diff in `run.sh`) rather than relying on
noticing it.

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

### 4. Validate skill frontmatter

Run the check from "Validating skill frontmatter" above (now that the listing is
reconciled against disk). Add any problems it prints - a missing mandatory
`name:` or `description:`, or a `name:` that doesn't match its folder - to the
report's **Needs attention** section. These need a human to fix the offending
`SKILL.md`; the nightly task does not rewrite skill frontmatter itself.

### 5. Commit per repo (the wrapper pushes main)

For each repo touched in steps 1-3, commit the changed files with a verb-first
message under 73 characters (e.g. `Refresh skill INDEX.md files`,
`Sync _SKILL_LISTING.md with skills on disk`). Do **not** `git push` a
main/master/prod branch - the hook blocks it and the wrapper pushes it for you
after you exit (see "This task commits on its own; the wrapper pushes main").
The wrapper records what it pushed, or any rejected push, into the report
itself, so you do not need to. If a repo happens to be on a feature branch, you
may push that yourself; never force-push.

### 6. Write the report file

Write your final summary to the path in the `TIDY_REPORT_FILE` environment
variable. The **first line** is the machine-readable status the wrapper keys
on:

- `STATUS: quiet` - everything pulled cleanly, no index drift, nothing
  committed, nothing needs attention. The wrapper sends no email.
- `STATUS: report` - anything changed or anything needs attention. The wrapper
  emails the rest of the file.

After the status line, write a short human summary: repos rebased, INDEX.md /
_SKILL_LISTING.md changes committed (name the repos), and a clearly separated
**Needs attention** section for rebase conflicts, credential failures, and any
asserted-state drift you noticed (see "Watch for asserted-state drift"). You do
not report on pushing main - the wrapper appends its own push outcome (including
any rejected push, which flips a quiet report to `STATUS: report`) after you
exit. If you could not finish, still write the file with `STATUS: report` and
explain how far you got - a missing report file makes the wrapper send a
generic failure email.

## Testing without spamming Jasper

`run.sh --dry-run` runs the whole task but the email step only prints what it
would send. Use it to verify behavior without mailing anyone.
