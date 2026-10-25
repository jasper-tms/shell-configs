---
name: tidy-repos-and-skills
description: Load when asked to tidy repos and skills, or when an agent-skills INDEX.md or ~/.claude/skills/_SKILL_LISTING.md looks stale or wrong, or when asked to regenerate a skill folder's index.
---

# Tidy repos and skills

A tidying pulls every repo under `~/repos` and brings two kinds of skill index
back in sync with the actual `SKILL.md` files on disk:

- a per-folder `INDEX.md` in each version-controlled agent-skills folder, and
- the single global `~/.claude/skills/_SKILL_LISTING.md` (names + locations).

It then runs whatever extra tasks this particular machine defines (see
"Machine-specific instructions").

## Machine-specific instructions: ~/.config/tidy-repos-and-skills/*.md

This skill defines only the machine-independent routine. Everything specific to
one machine - extra checks, extra files to refresh, folders deliberately left
unindexed - lives in `~/.config/tidy-repos-and-skills/`, outside this repo.
Each file there is typically a symlink to a skill describing one domain's
tidying steps (the machine's own, or an organization's), which links back to
this skill and leaves everything this skill covers to it.

At the start of every tidying, read every `.md` file in that folder (in name
order) and follow all of them. Their tasks become extra steps of the sequence
(step 5 below), and anything they say about the steps here (e.g. folders to
leave alone) applies too.

If the folder is absent or holds no `.md` files, this machine has no extra
tasks; the summary says so in one line.

## Commit and push directly

A tidying commits its own fixes and pushes them, the deliberate exception to
the `finishing-tasks-in-repos` convention (which writes a `commit_*.sh` script
for the user to run). Still follow its message conventions (under 73
characters, start with a verb). Never force-push.

Push a branch only when every commit it holds that its upstream lacks was made
by this tidying. If it also holds other unpushed commits - someone's work in
progress - do not push it: leave the tidying's commit in place and report the
repo as unpushed.

If a push is refused - rejected by the remote, denied by a hook, or ruled out
by whoever asked for the tidying - leave the commit in place and name the repo
as unpushed in the summary.

## Which folders are indexed: the INDEX.md itself is the opt-in

There is no hand-maintained list of indexed folders. A skills folder
participates in a tidying — its `INDEX.md` is regenerated, its skills appear
in the global `_SKILL_LISTING.md`, and its frontmatter is validated — **if and
only if it already contains an `INDEX.md`**. Creating that file once (a single
`build_index.py` run) opts a new folder in; deleting it opts out.

The exception is a folder inside a linked git worktree (e.g. a
`worktree_<branch>/` checkout made for parallel development): its `INDEX.md` is
just a branch copy of the main checkout's, so it is always skipped - not
regenerated, not given a listing section.

`~/.claude/skills/` itself is always left **without** an `INDEX.md`: it is a
symlink farm plus unversioned third-party skills, not in any repo. The machine
instructions may name further folders that contain `SKILL.md` files but are
deliberately left unindexed (e.g. an app's own runtime skills).

To bring a new folder in, run `build_index.py` on it once and add a section for
it to `_SKILL_LISTING.md`; from then on every tidying keeps both current.

## Regenerating an INDEX.md: use build_index.py

Never hand-transcribe an `INDEX.md`. This skill ships `build_index.py`, which
reads each `SKILL.md`'s frontmatter and deterministically rewrites the folder's
`INDEX.md` (skills sorted by name, so diffs stay stable). It sits next to this
`SKILL.md` - refer to it by the real path of the directory you read this skill
from. Run it per folder:

```bash
build_index=<this skill's directory>/build_index.py
python3 "$build_index" ~/repos/<owner>/<repo>/agent-skills
```

The generated file is repo-relative and clone-portable:

```
# Skill index for `<repo>/agent-skills/`
Each line below lists a single skill as `- <skill-name>: <skill-description>`. Each skill can be found alongside this INDEX.md file at `<skill-name>/SKILL.md`
- <skill-name>: <description>
...
```

### Skills symlinked from a repo that isn't cloned here

A skills folder may hold symlinks to skills in sibling repos (e.g.
`agent-skills/some-skill -> ../other-repo/agent-skills/some-skill`).
On a machine where that sibling repo isn't cloned, the symlink dangles. That
says nothing about whether the skill still exists, so `build_index.py` keeps
the skill's existing `INDEX.md` line unchanged (printing a `note:` to stderr)
instead of dropping it. Do not "fix" such a line by removing it, and do not
report it as a problem; at most mention which repos weren't cloned. If a
dangling symlink has no existing line to keep, the script prints a `warning:`
and leaves it out. Put that warning under **Needs attention** (clone the repo
and rerun, or check whether the link is stale).

## Validating skill frontmatter

The Agent Skills spec makes both `name:` and `description:` mandatory, and
requires each skill's `name:` to match its parent directory name. This skill
ships `validate_skill_frontmatter.py`, which enforces all three across every
skill the global listing knows about, reading the folder set straight from
`~/.claude/skills/_SKILL_LISTING.md`. Like `build_index.py`, it sits next to
this `SKILL.md`. Run it and route any output into the summary's **Needs
attention**:

```bash
python3 <this skill's directory>/validate_skill_frontmatter.py
```

It checks `~/.claude/skills/_SKILL_LISTING.md` by default; pass a different
listing path as an argument to check another. It prints one problem per line
(or `all listed skills valid`) and exits nonzero when any listed skill is
invalid.

Absent folders (repos not cloned on this machine) are skipped. A `listed but
no SKILL.md on disk` line means the listing is stale - normally the reconcile
step below has already removed such an entry; if it persists, the listing
points at a skill that no longer exists.

## Watch for asserted-state drift

Beyond the fixed checks above, stay alert for the general failure they are all
instances of: **a place that asserts some state should be true, which has
silently drifted from what is actually true.** The index files assert "these
skills exist"; frontmatter asserts "`name:` matches the folder"; a README
asserts "the cron line is `0 3 * * *`" or "this file is the source of truth".
These drift because the assertion and the reality are edited at different
times by different people or agents.

When, in the course of the pull and index work, you notice a doc, README,
comment, or config that clearly states something now contradicted by reality (a
stale schedule, a "source of truth" that has moved, a path or filename that no
longer exists, a count that no longer matches), record it under **Needs
attention** with the file and the specific contradiction. Do **not** auto-fix
it: the correct direction is usually ambiguous (fix the assertion, or fix the
reality?), and that judgment is a human's.

If a particular assertion turns out to be worth checking on every tidying, that
is a signal to promote it to a deterministic check (like the frontmatter
validator above, or a task in a machine instructions file).

## The sequence

First read the machine-specific instructions (see above). Then run these steps
in order, keeping a running note of everything worth reporting.

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

Record, for the summary: repos that were rebased, repos that hit a rebase
conflict (aborted, untouched), and any credential failures from `pullrepos`.

### 2. Regenerate every INDEX.md on disk

Find every folder that already has an `INDEX.md` beside a set of skills and
rebuild it. A folder without one is opted out, and a folder inside a linked git
worktree is a branch copy, so both are skipped (see "Which folders are
indexed"):

```bash
build_index=<this skill's directory>/build_index.py
# Only in a linked worktree do git's own directory and the shared one differ.
is_linked_worktree() {
    [ "$(git -C "$1" rev-parse --path-format=absolute --git-dir 2>/dev/null)" != \
      "$(git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" ]
}
find ~/repos -maxdepth 6 -type f -name INDEX.md \
    -not -path '*/.git/*' -not -path '*/node_modules/*' | while read -r index; do
    folder=$(dirname "$index")
    ls "$folder"/*/SKILL.md >/dev/null 2>&1 || continue  # not a skill index; skip
    is_linked_worktree "$folder" && continue             # worktree copy; skip
    python3 "$build_index" "$folder"
done
```

Then, per repo, `git diff --stat` the `INDEX.md` files to see what actually
changed. A changed `INDEX.md` means a skill was added, removed, or had its
description edited. Some indexed folders may live in other people's repos
(whose own tooling may defer index regeneration to this skill); regenerating an
already-correct index is a no-op, so a commit happens only when a skill really
changed.

### 3. Reconcile the global _SKILL_LISTING.md

`~/.claude/skills/_SKILL_LISTING.md` (usually a symlink into a
machine-specific repo; commit edits to its real file there) lists every
skill by **name** under its real-folder heading, plus symlink/consumer notes.
It carries names and locations only - no descriptions (those live in the
`INDEX.md` files). This step needs judgment:

- Every folder that has an `INDEX.md` (i.e. every indexed folder, so not one
  inside a linked worktree) should have a section in the listing. If one is
  missing — a folder was opted in but never listed — add a heading with its
  real path and its skill names, and note it under **Needs attention** so a
  human can write the section's consumer/symlink annotation.
- Within each section, every skill directory that exists on disk must appear
  under the heading. Add any missing; remove any whose directory is gone.
- Skip any skill directory git ignores (a privately symlinked skill hidden via
  `.git/info/exclude`), matching `build_index.py`, so private skills never leak
  into the listing.
- Preserve the file's structure and its per-skill annotations (e.g.
  `(NOT symlinked into ~/.claude/skills)`); only add/remove skill lines (and,
  when a section is genuinely missing, whole sections), don't reflow existing
  prose.

### 4. Validate skill frontmatter

Run the check from "Validating skill frontmatter" above (now that the listing
is reconciled against disk). Add any problems it prints to the summary's
**Needs attention**. These need a human to fix the offending `SKILL.md`; a tidying does
not rewrite skill frontmatter itself.

### 5. Run the machine-specific tasks

Do each task the machine instructions define, as they describe. Each task gets
its own line in the summary, under the label the instructions give it. If there
are no machine instructions, skip this step.

### 6. Commit and push per repo

For each repo touched in steps 2-5, commit only the files the tidying itself
changed - never someone's unrelated uncommitted work, which stays as it is
(staging just your files with `git add <file>`) - with a verb-first message
under 73 characters (e.g. `Refresh skill INDEX.md files`,
`Sync _SKILL_LISTING.md with skills on disk`), then push (see "Commit and push
directly").

### 7. Write the summary

Finish with a summary, as your final message unless whoever asked for the
tidying says where else to write it. Keep it terse - it is read at a glance,
and a routine success must not cost more than one line.

1. A header line: `tidy-repos-and-skills - <YYYY-MM-DD>`.

2. Exactly **one line per step below**, each prefixed `✓` (fine) or `⚠` (needs
   attention). A `✓` line is at most one line long: state the outcome, naming
   what changed in parentheses only if something did. Do **not** narrate *how*
   you did it, which skills you followed, or which sub-steps had nothing to
   report - a clean step is just `✓ <step>: OK`.

   Use these step labels verbatim (keep the label; only the part after the
   colon varies):

   - `✓ Pull all repos: OK` - or `✓ Pull all repos: OK (rebased: <repos>)`.
   - `✓ Regenerate agent-skills INDEX.md: no change` - or
     `... : updated <repos>`.
   - `✓ Reconcile global _SKILL_LISTING.md: no change` - or
     `... : <what changed>`.
   - `✓ Validate skill frontmatter: valid` - or
     `⚠ Validate skill frontmatter: <problems>`.
   - One line per machine-specific task, using the labels the instructions
     give. With no machine instructions, write the single line
     `✓ Machine-specific tasks: none configured`.
   - `✓ Commit and push: nothing to commit` - or `... : <repos> pushed`, or
     `⚠ Commit and push: <repos> committed but not pushed (<reason>)`.

3. A `⚠ Needs attention (<n>):` block **only if** something needs attention: a
   rebase conflict, a credential failure, a frontmatter problem, a
   machine-specific task's problem, an unpushed commit, or asserted-state drift
   you noticed (see "Watch for asserted-state drift"). This is the one place to
   expand - give each item the file/command and the specific contradiction,
   enough to act on without re-investigating. Every step line you marked `⚠`
   above must appear here in full. Omit the whole block when nothing needs
   attention.

If you could not finish, still write the summary with whatever `✓`/`⚠` step
lines you completed, and a `⚠ Needs attention` note on how far you got.

Example of a tidying with one real issue:

```
tidy-repos-and-skills - 2026-09-10

✓ Pull all repos: OK (rebased: my-app)
✓ Regenerate agent-skills INDEX.md: updated my-app
✓ Reconcile global _SKILL_LISTING.md: no change
✓ Validate skill frontmatter: valid
✓ Machine-specific tasks: none configured
✓ Commit and push: my-app pushed

⚠ Needs attention (1):
- uv-sources clean filter not configured on this machine; checkout/rebase
  leaves [tool.uv.sources] staged, and a commit could leak local absolute
  paths. Fix: using-uv INSTALL.md steps 4-5.
```
