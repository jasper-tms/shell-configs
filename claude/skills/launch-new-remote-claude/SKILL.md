---
name: launch-new-remote-claude
description: Launch a new Claude Code Remote Control session in a detached screen on this Raspberry Pi. Use when the user asks to "start a new session", "spawn a new claude", "launch another remote-control instance", or similar.
---

Run `~/.claude/skills/launch-new-remote-claude/launch-new-claude-remote-control.sh` via the Bash tool. The script:

- Auto-numbers the session: screen `claude-remote-N`, RC display name `rpi-N`, where N is one more than the highest existing `claude-remote-N` screen.
- Uses `$CLAUDE_WORK_DIR` as the session's working directory, falling back to `~/.claude/remote-sessions/`. The directory is created if missing, and workspace trust is pre-accepted for it in `~/.claude.json`.
- Passes `--permission-mode auto` so the new session starts in Auto Mode.
- Defaults the initial prompt to "Wait for further instructions".

Pass an initial prompt as arg 1; override the work dir with `CLAUDE_WORK_DIR`:

```
~/.claude/skills/launch-new-remote-claude/launch-new-claude-remote-control.sh "their prompt"
CLAUDE_WORK_DIR=/path/to/project ~/.claude/skills/launch-new-remote-claude/launch-new-claude-remote-control.sh
CLAUDE_WORK_DIR=/path/to/project ~/.claude/skills/launch-new-remote-claude/launch-new-claude-remote-control.sh "their prompt"
```

## Required: verify the new session before reporting success

After launching, you MUST confirm the new session is at the main UI (not stalled on a prompt) before telling the user it's ready. The trust dialog should be pre-accepted, but verify it didn't appear anyway.

1. Wait ~5 seconds, then capture the screen:

   ```
   screen -S claude-remote-N -X hardcopy /tmp/check-N.txt
   ```

2. Read the file. Clean it up with `LC_ALL=C tr -cd '[:print:]\n' < /tmp/check-N.txt | sed '/^[[:space:]]*$/d'` to strip the screen's box-drawing glyphs and blank lines.

3. Look for one of these:
   - **"Remote Control active"** in the footer → session is up. Grab the `https://claude.ai/code/session_…` URL and report success to the user with screen name, RC display name, working directory, and URL.
   - **"Is this a project you created or one you trust?"** → stalled on trust dialog. Accept it (see below), then re-verify.
   - Neither → wait a few more seconds and recapture; claude may still be starting.

## Accepting a trust dialog if it appears

Option 1 ("Yes, I trust this folder") is pre-selected. Send Enter using `\r` (carriage return — `\n` does NOT work):

```
screen -S claude-remote-N -X stuff $'\r'
```

Then wait ~3 seconds, recapture the screen, and confirm "Remote Control active" appears before reporting success.

## Sending other input to a session

Same mechanism — `screen -X stuff` with `\r` for Enter. Embed text the same way: `$'some text\r'`.

## Don't re-implement

Always invoke the script — never reimplement the launch logic inline.
