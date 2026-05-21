---
name: launch-new-remote-claude
description: Launch a new Claude Code Remote Control session in a detached screen on this machine. Use when the user asks to "start a new session", "spawn a new claude", "launch another remote-control instance", or similar.
---

Run `~/.claude/skills/launch-new-remote-claude/launch-new-claude-remote-control.sh` via the Bash tool. The script:

- Auto-numbers the session: screen `claude-remote-N`, RC display name `<prefix>-N`, where N is the lowest unused number among existing `claude-remote-N` screens. `<prefix>` is machine-dependent, chosen by a `hostname -s` case block in the script (`macbook` on this MacBook, `rpi` on the Pi); unrecognized machines fall back to the lowercased short hostname.
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

1. Capture and clean the screen in one go (the sleeps matter: `hardcopy` writes the file asynchronously, and a fresh session needs a few seconds to render its splash then the UI):

   ```
   sleep 6; screen -S claude-remote-N -X hardcopy /tmp/check-N.txt; sleep 1; LC_ALL=C tr -cd '[:print:]\n' < /tmp/check-N.txt | sed '/^[[:space:]]*$/d'
   ```

   Always strip with `LC_ALL=C tr` first — never run `sed`/`grep` on the raw hardcopy (its box-drawing bytes throw "illegal byte sequence" on macOS).

2. Look for one of these:
   - **"Remote Control active"** in the footer → session is up. Grab the `https://claude.ai/code/session_…` URL and report success to the user with screen name, RC display name, working directory, and URL.
   - **"Is this a project you created or one you trust?"** → stalled on trust dialog. Accept it (see below), then re-verify.
   - **Empty output, or neither string present** → captured too early (not a failure); recapture every few seconds until one of the above appears, up to ~30s.

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
