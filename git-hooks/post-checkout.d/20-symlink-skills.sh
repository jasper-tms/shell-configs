#!/bin/bash
# Offers to symlink new skills/ or agent-skills/ folders into Claude's global
# skills folder. See shell_scripts/symlink-skills for the logic.
#
# The goal across all hooks is to fire whenever skills appear from a remote that
# weren't here before. `git pull` / `git merge origin/main` are the common way
# that happens, but those fire post-merge, not post-checkout -- so that case is
# handled by the sibling post-merge.d/20-symlink-skills.sh, NOT here.
#
# post-checkout fires on other things, and among those the only one where new
# skills arrive from a remote is a fresh clone, so that is the sole case we run
# for here. In particular we deliberately do NOT run on a branch switch: you
# already had this repo, you are just moving around inside it, so nothing new
# landed from a remote.
#
# post-checkout args: $1 = previous HEAD, $2 = new HEAD, $3 = 1 for a branch
# checkout or 0 for a file checkout.
#   - A file checkout ($3 = 0) doesn't switch what tree we're on; skip.
#   - A branch switch reports a real previous HEAD; skip -- this is the case we
#     specifically don't want firing.
#   - A fresh clone reports an all-zero previous HEAD. So does `git worktree
#     add`, but a linked worktree's git dir differs from its shared common dir,
#     which lets us skip worktree creation (the skills already live in the main
#     checkout) and run only for a genuine clone.
set -e

previous_head="$1"
checkout_type="$3"
all_zeros="0000000000000000000000000000000000000000"

[ "$checkout_type" = 1 ] || exit 0               # file checkout, not a branch/clone
[ "$previous_head" = "$all_zeros" ] || exit 0    # branch switch within an existing repo

# A fresh clone has git-dir == git-common-dir; a linked worktree does not.
if [ "$(git rev-parse --git-dir 2>/dev/null)" != "$(git rev-parse --git-common-dir 2>/dev/null)" ]; then
    exit 0  # `git worktree add`, not a fresh clone
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
symlink-skills "$repo_root"
