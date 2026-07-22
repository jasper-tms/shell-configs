---
name: sharpen-docs
description: Load when asked to improve or shorten documentation like READMEs, wikis, or skills
---

# Skill: Sharpening documentation
Your job is to improve documentation by cutting or compacting useless information.

## What roles do docs serve?
To do this effectively, you have to first think about the three concrete situations in which docs can be helpful:
1. Someone wants to _use_ something, and docs can tell them how to both set the thing up and how to use it.
2. Someone wants to _improve upon_ something, and docs of a few different types can be helpful for designing and implementing new features:
   - docs that describe existing features and their implementations
   - docs that describe design habits or feature specifications
3. Something is _broken_, and docs that describe testing frameworks, describe how things are intended to be configured, or log recent events can be useful for troubleshooting.

## Your job
Read through the documentation that the user has pointed you to. First, think about whether the document is meant to be user-facing (point 1 above) developer-facing (point 2 above), or troubleshooter-facing (point 3 above). Typically, a doc will only have one of those roles. Then based on the role assigned to that doc, consider whether every phrase and sentence in the doc serves the role it's supposed to fulfill.

Docs often contain information that does not actually serve the role that the doc is intended for. Your job is to find that unnecessary information and relocate it to a different doc or delete it

Typical ways to improve docs:

### Removing historical information ("logs") from dev-facing or user-facing documents
Stories about how something was discovered or verified are typically not useful for users or developers - as long as the thing is true, it stands on its own.

Cut the story clause even when the surrounding sentence is worth keeping - this is usually a surgical edit, not a whole-line deletion. For example, a doc might say:

> This injects the command into your own terminal exactly as if it had been typed at the keyboard, and **— confirmed by testing —** a slash command injected this way actually executes **(e.g. produces `/context`'s real usage report)**, it doesn't just land as literal chat text you'd have to interpret yourself.

The bolded pieces are both records of what the author saw while verifying the claim, not instructions the reader acts on. Delete them and the sentence still tells the reader everything they need:

> This injects the command into your own terminal exactly as if it had been typed at the keyboard, and a slash command injected this way actually executes - it doesn't just land as literal chat text you'd have to interpret yourself.

### Removing redundant reassurance ("why this is safe") narration
Docs sometimes reassure the reader that something is fine, harmless, or won't break anything. If the doc already tells the reader what to do, an added "don't worry, this is safe because..." _usually_ earns nothing - a reader following working instructions doesn't need to be talked out of a fear the doc itself introduced. For example:

> Run `refresh-registry` to rebuild the index. **Don't be alarmed that this touches every file - it only rewrites the ones whose contents actually changed, so it's completely safe to run as often as you like and won't corrupt anything.**

Cut the reassurance down to whatever is genuinely actionable (here, that re-running is idempotent):

> Run `refresh-registry` to rebuild the index. Re-running is a no-op on files that haven't changed, so it's safe to run repeatedly.

The exception: keep the reassurance when the reader has a *real, specific* reason to hesitate that the instruction alone doesn't resolve - e.g. a scary-looking warning the tool prints, or a step that looks destructive but isn't.

## Sharpening skill descriptions
The `description:` line of a skill is by far the most important part of a skill file to spend time optimizing. Because descriptions are loaded into context by _every_ agent and are the sole gate to whether the agent loads the skill content:
1. If a description is longer than necessary, tokens are wasted _every_ conversation as agents keep that unnecessary description text in mind – a small cost multiplied by a huge number of occurrences.
2. If a description does not adequately describe the situations where an agent should load the skill, agents will either not load the skill when it would be useful (wasting huge amounts of effort trying to re-discover things itself, or worse, doing the task wrong) or load it when it would not be useful (wasting tokens on now keeping the whole skill contents in mind) – rarer occurrences, but huge costs.

Your goal is therefore extremely clear: Make skill descriptions as short as possible while making them 1. trigger reliably in the situations where the skill's contents is actually useful, and 2. not trigger when the skill's contents aren't relevant. Critically, a description does not need to summarize or list the skill's main sections or conclusions – a common mistake. When you see one that does, rewrite it from the mindset of "how do I keep this extremely short while still triggering reliably".

Whenever you rewrite a skill's `description`, validate the rewrite before settling on it: rerun the skill's `prompts-to-test-description.md` fixture against the new description, confirm every "should trigger" prompt still loads the skill and every "should not trigger" prompt stays quiet, and update the recorded scores. If no fixture exists, build one first; a description shortened without this check is unverified, so say so to the user if you skip it.

The full procedure - fixture format, how to choose prompts, and how to run and score them from subagent transcripts - lives in a companion skill, **test-skill-descriptions**. It is deliberately NOT globally registered (to keep its description out of every agent's context), so you cannot load it with the Skill tool; read its `SKILL.md` directly. It sits next to this skill in the same real directory, so resolve this skill's own base directory to its real path (following the symlink) and read the sibling file:

```bash
cat "$(dirname "$(readlink -f ~/.claude/skills/sharpen-docs)")/test-skill-descriptions/SKILL.md"
```
