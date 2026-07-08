---
name: make-new-skill
description: How to make a new skill. Load when the user asks to make a skill, or when important decisions or discoveries have been made that you think would be useful to put into a new skill for future agents to know about.
---

# Skill: Workflow for creating a new skill

Deployed skills are symlinked into Claude's auto-discovered `<dir>/.claude/skills/` folders, but the real file almost always lives elsewhere: in a repo's or organization's `agent-skills/` folder for project-specific skills, or in `~/repos/jasper-tms/shell-configs/claude/skills/` for general purpose skills. (Note the folder naming convention: repos and orgs use `agent-skills/`, while the shell-configs directory and the global home folder are both named `skills`.)

## When to act

Create a skill in two situations:
1. The user asks you to make a new skill.
2. Decisions or discoveries have been made in the current conversation that 1) took a reasonable amount of exploring or discussing to arrive at, 2) are durable (long-lasting), and 3) would be useful for future agents to know about. Any time these conditions are fulfilled, suggest making a new skill and wait for the user to explicitly approve or deny. The user ignoring the suggestion likely means deny, but remind them about possible skills you suggest creating before wrapping up conversations.

## Plan

Before creating a new skill, you must do two things:
1. Decide on the appropriate location for the skill files to live (do this yourself if it's clear, otherwise ask the user where they want it):
   - Repo-related or organization-related information? Use `~/repos/<org>/<repo>/agent-skills/` or `~/repos/<org>/agent-skills/`, respectively.
   - General purpose, machine-independent information? Use `~/repos/jasper-tms/shell-configs/claude/skills/`.
   - Machine-specific information? Put the skill in `~/.claude/skills/` directly, instead of putting the skill in a repo and then symlinking it into this machine's `~/.claude/skills/`.
2. Check whether an existing skill already covers the topic by searching `~/.claude/skills/` and any `agent-skills` folders in relevant repos and org folders. If one or more exist, talk with the user about whether to extend an existing skill instead of creating a new one.

## Execute

1. By default, just write a SKILL.md file. However, if the skill would benefit from example scripts, reference docs, or other supporting assets that should NOT be added into context by default every time the skill is used but instead would only be useful in some cases, add those as separate files in the skill's own directory or a subdirectory, and describe in the new SKILL.md file when the agent should choose to load or use each supporting file. Information (scripts, docs, other text assets) that SHOULD be added into context by default every time the skill is used should go directly into SKILL.md.
2. Keep the frontmatter (skill description) short and to the point - all skill descriptions always get loaded into context, so token bloat is real as number of skills grows.
3. Symlink to a Claude-auto-loading folder:
   - After you make a skill in `jasper-tms/shell-configs`, symlink it into `~/.claude/skills/` so it becomes visible to _all_ future agents.
   - After you make an org or repo skill, make sure that `~/repos/<org>{/<repo>}/.claude/skills -> ../agent-skills` already exists and create it if it doesn't, so that the new skill becomes visible to all future agents _working in that org or repo_ (which will auto-discover that folder).
   - Nothing should need to be done for machine-specific skills since you were supposed to make them directly in the auto-discovered `~/.claude/skills/`.

## Test and iterate

Test the new skill with a subagent using the simplest available model (for Claude, that's currently Haiku). A freshly written skill will be visible to subagents as soon as it's symlinked into `~/.claude/skills/`, even when launched by the same agent session that wrote the skill, so you should test and iterate on both **discovery** and **content**:

1. **Discovery (does the `description` trigger the skill?)** — Give the subagent a natural task or question that *should* trigger the skill, WITHOUT naming the skill or pointing at its file. Verify the subagent chooses to load the skill on its own. If it doesn't, the frontmatter `description` isn't triggering well enough — sharpen it (add the words a user would actually use, the symptoms, the tool names) and retest.
2. **Content (does the loaded skill actually work?)** — Once loaded, verify the subagent's output is correct, its thinking was clear and without confusion, and the skill gave it everything it needed to reach the answer/solution quickly without having to figure things out itself.

Prefer testing both together via the discovery prompt in step 1. Only fall back to pointing the subagent directly at the SKILL.md file if you specifically want to test content in isolation — but know that doing so bypasses (and therefore doesn't test) discovery.

If there was any suboptimality in the subagent's behavior, refine the skill file(s) to be more helpful and idiot-proof, then launch a new subagent to test the updated skill. Iterate until satisfied.

## Finalize

Write a git commit script that adds and commits the new skill file(s). (Note that `.claude` is typically globally gitignored, so the symlinks that help `claude` auto-detect the skill do not need to be addressed in git operations.)
