#!/bin/bash
# Offers to symlink the skills that this merge newly added into Claude's global
# skills folder. See shell_scripts/symlink-skills for the logic.
#
# Only the newly added ones: offering every unlinked skill in the repo means a
# skill you have deliberately chosen never to link is offered again on every
# single `git pull`, even by pulls that do not touch it. So we ask git what this
# merge actually brought in, and name those skills to symlink-skills.
#
# "Newly added" is decided by looking for added SKILL.md files rather than for
# any changed file under a skill's folder, since editing a file inside a skill
# you have already declined is no reason to be asked about it again.
set -e
repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

# ORIG_HEAD is where HEAD was before the merge; git merge writes it, including
# for the fast-forward case that most pulls are. If it is somehow missing we
# have nothing to diff against, so fall back to offering every unlinked skill.
previous_head="$(git rev-parse --verify --quiet ORIG_HEAD)" || previous_head=""
if [ -z "$previous_head" ]; then
    symlink-skills "$repo_root"
    exit 0
fi

new_skill_names=()
while IFS= read -r added_skill_file; do
    [ -n "$added_skill_file" ] || continue
    new_skill_names+=("$(basename "$(dirname "$added_skill_file")")")
done < <(git diff --name-only --diff-filter=A "$previous_head" HEAD -- '*/SKILL.md')

[ ${#new_skill_names[@]} -gt 0 ] || exit 0
symlink-skills "$repo_root" "${new_skill_names[@]}"
