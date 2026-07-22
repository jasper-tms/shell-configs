---
name: test-skill-descriptions
description: How to test whether a skill's `description` line makes agents load the skill in the right situations and not others - trigger/discovery testing only, NOT whether the skill's body instructions produce correct results. Uses a prompts-to-test-description.md fixture scored from subagent transcripts. Load when writing or sharpening a skill's description line.
---

# Skill: Testing that a skill description triggers correctly

A skill's `description:` line is the sole gate to whether an agent loads the skill, and it is loaded into _every_ agent's context. It has to trigger in the situations where the skill is useful and stay quiet everywhere else. This skill is how you check that empirically instead of guessing: a checked-in set of prompts and a way to score any description against them.

## The fixture: `prompts-to-test-description.md`

Next to a skill's `SKILL.md`, keep a `prompts-to-test-description.md` file. It holds nothing but two lists - no preamble or explanation, since only make-new-skill and sharpen-docs read it and they carry the instructions. List three prompts under each heading, each annotated with its score:

```markdown
## Should trigger
1. "<prompt>": X/2 Haiku and Y/2 Sonnet

## Should not trigger
1. "<prompt>": X/2 Haiku and Y/2 Sonnet
```

Two rules make the fixture worth trusting:

- **Every prompt must have actually been run against subagents, with the observed outcome matching the heading it is filed under.** Prompts that merely look plausible turn the file into fiction that future agents will trust as ground truth.
- **The "should not trigger" prompts must be genuine near-misses** - adjacent enough that a sloppy description would wrongly catch them. For a skill about reading images in Python, "write me a haiku" proves nothing, while "read this CSV of pixel intensities into a numpy array" is a real test. Prompts drawn from neighboring skills' territory are good candidates.

A passing "should not trigger" prompt is weaker evidence than a passing "should trigger" one, since a subagent can decline to load a skill for reasons unrelated to the description. Treat the negatives mainly as a regression guard against a later description getting broadened too far.

## Running a prompt and scoring it

Do NOT ask the subagent to report which skills it loaded - that primes it toward loading and relies on it self-reporting honestly. Give it the pure natural task, worded as a user actually would and never naming the skill, and read the ground truth off disk instead.

Run each prompt against a small batch - a couple of Haiku and a couple of Sonnet subagents is enough to catch a description that only triggers half the time. Every subagent writes a full transcript to a `subagents/agent-<agentId>.jsonl` file, where `agentId` is returned in the Agent tool result.

Locate that file by its globally-unique `agentId`, NOT by trying to build the path yourself. The transcript lives under a directory named after the session's *starting* working directory, so if you have since `cd`'d elsewhere (to /tmp, a scratchpad, etc.) you cannot reliably reconstruct it, and several sessions can have confusingly similar directory names. A glob by ID is location-independent and returns exactly one file:

```bash
transcript=$(ls ~/.claude/projects/*/*/subagents/agent-<agentId>.jsonl 2>/dev/null)
grep -q '"skill":"<skill-name-under-test>"' "$transcript" && echo LOADED || echo not-loaded
```

Count only agents whose transcript loaded the skill under test, ignoring other skills the task legitimately pulls in (like a code-formatting skill). Record the result per prompt in the format `"<prompt>": X/2 Haiku and Y/2 Sonnet`.

## When you use this

- **Writing a new description** (make-new-skill): once the description triggers correctly, write the prompts you tested with into the fixture so a future agent can revalidate.
- **Sharpening an existing description** (sharpen-docs): put the new description in place, rerun every prompt in the fixture, confirm every "should trigger" still loads the skill and every "should not trigger" stays quiet, and update the recorded scores. If the fixture does not exist, either build and validate it first or tell the user you shortened the description without being able to verify it still triggers correctly.
