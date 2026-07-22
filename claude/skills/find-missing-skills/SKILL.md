---
name: find-missing-skills
description: Immediately load this skill when asked to load or edit a skill whose name or description is not in your available-skills list – it most likely exists and _SKILL_LISTING.md can tell you where it is. Also load when asked questions like "Do we have a skill that covers X?"
---

There is a listing of all skills on this machine (that the user knows about) in
the file `~/.claude/skills/_SKILL_LISTING.md`. If it lists the requested skill,
read `<folder>/<skill-name>/SKILL.md` directly (the Skill tool won't work on a
skill that isn't in your registry), report the absolute path to the user, and
note that you used `find-missing-skills` to find it.

If that `_SKILL_LISTING.md` file does not exist, load `make-skill-listing.md`
from the `find-missing-skills/` folder and follow its instructions.

If `_SKILL_LISTING.md` does exist but doesn't include the skill you're looking
for, `ls` all folders that other skills were listed in. If the skill turns
up, read its `SKILL.md`, tell the user the listing was out of date, and update
it. If the skill is genuinely absent from the listing and from the folders that
the listing covers, report this to the user and ask for further instructions.
