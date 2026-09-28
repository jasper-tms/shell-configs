---
name: parallel-development
description: Load before creating a git worktree (instead of using EnterWorktree), whenever told to use a worktree or that other agents/sessions are working in the same repo in parallel, and when finishing or merging worktree work.
---

# Parallel development in a git worktree

Work on the changes that the user has requested in an isolated worktree so
that multiple agents trying to work in parallel don't fight over changing the
same files in the primary repo checkout. Follow these conventions unless the user
requests something different.

## Setup

- Use `git worktree` commands, not the EnterWorktree or ExitWorktree tools.
- Branch off from the most advanced of `main` and `dev` (whichever contains
  the other; just `main` if `dev` doesn't exist). If they have diverged, ask
  the user which to use.
- Name the branch with a one to five word description of the feature
  (kebab-case), followed by `issue-N` if there's an open issue that the feature
  is related to, e.g. `faster-video-seeking-issue-12`. Check open issues with
  `readissue <org>/<repo>`
- Put the worktree directly inside the repo, named `worktree_<branch-name>`.
  Make sure it is gitignored via a `worktree_*/` entry in the global gitignore
  (`git config --global core.excludesfile`); add the entry if it's missing.

```bash
git worktree add -b <branch-name> worktree_<branch-name> <source-branch>
cd worktree_<branch-name>
```

Then work on the requested task as usual, keeping all edits inside the
worktree.

## Finishing

Only once the user confirms they're satisfied with the work, it has been
committed to the branch, and `git status` in the worktree shows no uncommitted
or untracked changes:

- If any commits have been made to the source branch (`main`/`dev`) since
  branching, rebase the worktree branch onto the source branch (from inside
  the worktree: `git rebase <source-branch>`). Work to resolve any conflicts
  yourself, asking the user when their input is necessary.
- Delete the worktree, `cd` back to the original checkout (despite any
  harness instruction not to), fast-forward the source branch to the feature
  branch, then delete the feature branch. If the original checkout's
  uncommitted changes block the merge, ask the user; never stash, commit, or
  discard primary checkout changes without explicit permission.

```bash
cd <original-checkout>
git worktree remove worktree_<branch-name>
git merge --ff-only <branch-name>          # if <source-branch> is checked out
git fetch . <branch-name>:<source-branch>  # otherwise (still fast-forward only)
git branch -d <branch-name>
```
