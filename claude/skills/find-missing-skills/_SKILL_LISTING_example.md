# Where skill files live on this computer
Lookup table for the `find-missing-skills` skill. Skills listed here can be
found at `<folder>/<skill-name>`, where each section header below is the
`folder` and each item in the bulleted list is a `skill-name`.

Each section also indicates its "consumer" locations where its skills are
symlinked to `<location>/.claude/skills` and so should be available by
default to agents working in `<location>` or its subdirectories. Tell the user
if a skill is not available that looks like it should be based on this list.

## ~/repos/jasper-tms/shell-configs/claude/skills/
All individually linked into the global `~/.claude/skills` unless noted.

- accurate-video-frame-indexing
- find-missing-skills
- google-sheet-backed-web-form (not symlinked into `~/.claude/skills`)
- make-new-skill
- reading-pdfs
- remote-claude-sessions
- using-uv
- virtualenvwrapper-setup

## ~/.claude/skills/
Machine-specific skills _would_ live here; currently none, instead there are
only symlinked skills in this folder.

## ~/repos/<org>/<repo>/agent-skills/
Linked in its own repo via `<repo>/.claude/skills -> ../agent-skills`.
Linked into `~/Dropbox/Science/`.
Linked into `<some other folder where this repo's knowledge would be useful>`.

- some-repo-specific-skill
