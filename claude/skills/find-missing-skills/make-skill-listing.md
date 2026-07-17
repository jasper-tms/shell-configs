# How to make `_SKILL_LISTING.md`

1. Before proceeding, confirm with the user that they want you to help them
   make the file `~/.claude/skills/_SKILL_LISTING.md` listing all known skill
   files on the computer and where they're symlinked to for agents to see.
2. Read this skill folder's `_SKILL_LISTING_example.md` for an example.
3. Search for skill directories on this machine. Adapt the examples below to
   the machine, and search additional directories where your knowledge of the
   user's machine leads you to believe skills may be stored. Do not run `find`
   commands to accompish this, instead explore between 1 and 3 levels deep in
   sensible candidate folders using `ls`/globs.

   ```bash
   ls -d ~/.claude/skills/*/ 2>/dev/null                    # global skills (often symlinks)
   ls -d ~/repos/*/*skills ~/repos/*/*/*skills 2>/dev/null  # org / repo skills
   ls -d ~/Dropbox/*/*/agent-skills 2>/dev/null             # other trees worth checking
   ```

4. Actively look for and resolve symlinks (`readlink -f`, or `ls -la`) at the
   level of `skills/`, `agent-skills/`, or `<skill-name>/` folders so you
   write into the listing where each skill really lives (rather than where they
   are linked to for visibility to agents) and so you avoid duplicate listings.
   (Do not resolve symlinks higher up, e.g. at `repos/` or `Dropbox/`.)
5. Keep the listing a plain lookup table: one heading per containing folder
   (the real path), then just the skill names, one per line. No per-skill
   descriptions or prose.
