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
2. Keep the description short and to the point, on one line (not hard-wrapped) - all skill descriptions always get loaded into context, so token bloat is real as number of skills grows. Hard-wrap the SKILL.md body at 79 characters.
3. Symlink to a Claude-auto-loading folder:
   - After you make a skill in `jasper-tms/shell-configs`, symlink it into `~/.claude/skills/` so it becomes visible to _all_ future agents.
   - After you make an org or repo skill, make sure that `~/repos/<org>{/<repo>}/.claude/skills -> ../agent-skills` already exists and create it if it doesn't, so that the new skill becomes visible to all future agents _working in that org or repo_ (which will auto-discover that folder).
   - Nothing should need to be done for machine-specific skills since you were supposed to make them directly in the auto-discovered `~/.claude/skills/`.

## Test and iterate

Test the new skill with subagents using the simplest available model (for Claude, that's currently Haiku).

**First, confirm the skill is actually visible to subagents.** Launch a Haiku subagent, instructing it in the prompt not to use Read/Grep/Glob/Bash or any other file-inspection tool, and ask it to report the new skill's description. (The instruction matters: a subagent that can search the filesystem will find `SKILL.md` on disk and report its contents even when the skill is not actually loaded, which looks like a pass but tests nothing.) Subagents inherit the parent session's skill registry, so if the parent hasn't re-scanned since you created the skill, this fails. If the subagent can't report the skill description, you need `/reload-skills` to run before retrying:

- **If you are running inside a `screen` session** (check `$STY` — a set, non-empty `$STY` unambiguously names your own session, confirmed against `screen -ls`), you can trigger the reload yourself instead of asking the user: run `screen -S "$STY" -X stuff $'/reload-skills\r'` via the Bash tool. This injects the command into your own terminal exactly as if it had been typed at the keyboard, and — confirmed by testing — a slash command injected this way actually executes (e.g. produces `/context`'s real usage report), it doesn't just land as literal chat text you'd have to interpret yourself. Make this your last action of the turn (no further tool calls after it) so the command is submitted once the input box is idle, then let the turn end; the reload will have happened by the time you pick the task back up.
- **If `$STY` is unset** (not running in a screen), ask the user to run `/reload-skills` themselves.

Either way, then try asking a new subagent. If the subagent saw the skill on the first try, just proceed without reloading at all.

Once we confirm that a subagent can see the new skill, test and iterate on both the skill's **discovery** and its **content**:
1. **Discovery (does the `description` trigger the skill?)** — Give the subagent a natural task or question that *should* trigger the skill, WITHOUT naming the skill or pointing at its file. Verify the subagent chooses to load the skill on its own. If it doesn't, the frontmatter `description` isn't triggering well enough — sharpen it (add the words a user would actually use, the symptoms, the tool names) without getting too verbose, then retest.
2. **Content (does the loaded skill actually work?)** — Once loaded, verify the subagent's output is correct, its thinking was clear and logical, and the skill gave it everything it needed to reach the answer/solution quickly without getting confused or having to figure things out itself.

Prefer testing both together via a natural-task-or-question prompt (just described in 1. Discovery). Only fall back to prompting the subagent directly to use the skill by name if you specifically want to test content in isolation — but know that doing so bypasses (and therefore doesn't test) discovery.

If there was **any** suboptimality in the subagent's behavior, refine the skill file(s) to be more helpful and idiot-proof, then launch a new subagent to test the updated skill. Iterate until satisfied.

### Record the discovery tests in `prompts-to-test-description.md`

Once the description is triggering correctly, write the prompts you tested with into a `prompts-to-test-description.md` file next to `SKILL.md`. This is ground truth that lets a future agent rewrite the `description` (see the sharpen-docs skill) and check whether the rewrite still triggers in the right situations and stays quiet in the wrong ones.

The procedure for the fixture's format, the rules for choosing good prompts, and how to run and score them from subagent transcripts lives in a companion skill, **test-skill-descriptions**. It is deliberately NOT globally registered - keeping its description out of every agent's context - so you cannot load it with the Skill tool; read its `SKILL.md` directly. It sits next to this skill in the same real directory, so resolve this skill's own base directory to its real path (following the symlink) and read the sibling file:

```bash
cat "$(dirname "$(readlink -f ~/.claude/skills/make-new-skill)")/test-skill-descriptions/SKILL.md"
```

## Finalize

Add the new skill to the machine's skill lookup table `~/.claude/skills/_SKILL_LISTING.md` (under the heading for the folder where its files really live), if that file exists.

Write a git commit script that adds and commits the new skill file(s), including `prompts-to-test-description.md`. (Note that `.claude` is typically globally gitignored, so the symlinks that help `claude` auto-detect the skill do not need to be addressed in git operations.)
