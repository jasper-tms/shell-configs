---
name: make-new-skill
description: How to make a new skill. Load when the user asks to make a skill, or when important decisions or discoveries have been made that would be useful to put into a new skill for future agents to know about.
---

# Skill: Workflow for creating a new skill

Deployed skills are symlinked into the standard `~/.claude/skills/` folder, but the real file almost always lives elsewhere, either in a specific repository's `skills/` or `agent-skills/` subfolder for project-specific skills, or in `~/repos/jasper-tms/shell-configs/claude/skills/` for general purpose skills.

Create a skill in both of these situations:
- When the user asks you to make a new skill.
- When durable (long-lasting) decisions or discoveries have been made that will be useful for future agents to be aware of. In this case, you should suggest making a new skill and wait for the user to explicitly approve or deny. The user ignoring the suggestion likely means deny but remind them about possible skills you suggest creating before wrapping up conversations.

Before creating a new skill, check whether an existing skill already covers the topic (search `~/.claude/skills/` and any project-specific `skills/`/`agent-skills/` folders) — extend that skill instead of creating an overlapping one.

Before creating a new skill, determine the appropriate location for the file (project-specific repository versus global shell-configs repository) yourself if it's clear, otherwise ask the user where they want it. After you make the skill, it's generally desirable to symlink it into `~/.claude/skills/` unless the conversation so far makes you think you shouldn't.

By default, just write a SKILL.md file. However, if the skill would benefit from example scripts, reference docs, or other supporting assets that should NOT be added into context by default every time the skill is used but instead would only be useful in some cases, add theose as separate files in the skill's own directory or a subdirectory, and describe in the new SKILL.md file when the agent should choose to load or use each supporting file. Information (scripts, docs, other text assets) that SHOULD be added into context by default every time the skill is used should go directly into SKILL.md.
