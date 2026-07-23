---
name: remote-claude-sessions
description: Launch, verify, and drive Claude Code Remote Control sessions running in detached screens on this machine. Use when the user asks to "start a new session", "spawn a new claude", "launch another remote-control instance", to check on a session, or to send input (chat messages, slash commands, or `!` shell commands) to one.
---

## Launching a new session

Run `~/.claude/skills/remote-claude-sessions/launch-new-claude-remote-control.sh` via the Bash tool. The script:

- Auto-numbers the session: screen `claude-remote-N`, RC display name `<prefix>-N`, where N is the lowest unused number among existing `claude-remote-N` screens. `<prefix>` is machine-dependent, chosen by a `hostname -s` case block in the script (`macbook` on this MacBook, `rpi` on the Pi); unrecognized machines fall back to the lowercased short hostname.
- Uses `$CLAUDE_WORK_DIR` as the session's working directory, falling back to `~/.claude/remote-sessions/`. The directory is created if missing, and workspace trust is pre-accepted for it in `~/.claude.json`.
- Passes `--permission-mode auto` so the new session starts in Auto Mode.
- Defaults the initial prompt to "Wait for further instructions".

Pass an initial prompt as arg 1; override the work dir with `CLAUDE_WORK_DIR`:

```
~/.claude/skills/remote-claude-sessions/launch-new-claude-remote-control.sh "their prompt"
CLAUDE_WORK_DIR=/path/to/project ~/.claude/skills/remote-claude-sessions/launch-new-claude-remote-control.sh
CLAUDE_WORK_DIR=/path/to/project ~/.claude/skills/remote-claude-sessions/launch-new-claude-remote-control.sh "their prompt"
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

    screen -S claude-remote-N -X stuff $'\r'

Then wait ~3 seconds, recapture the screen, and confirm "Remote Control active" appears before reporting success.

## Sending other input to a session

Same mechanism — `screen -X stuff` with `\r` for Enter. Embed text the same way: `$'some text\r'`. Short input — a slash command like `/compact`, or a one-line chat message — submits fine as a single atomic `stuff` call with a trailing `\r`.

**A long chat message does NOT submit as one atomic call.** The burst of characters trips Claude Code's paste detection, and a `\r` glued onto the end of that same write is absorbed as a literal newline — the text lands in the input box but never submits. For any long/multi-line message, send the text and the Enter as **two separate `stuff` calls** with a short pause between, so the Enter arrives as a distinct keypress:

```
screen -S claude-remote-N -X stuff 'your long message here'
sleep 1
screen -S claude-remote-N -X stuff $'\r'
```

This is the same split-call shape the `!` shell-mode workaround below uses (which additionally needs the leading `!` sent separately).

`screen -X stuff` expands `$VAR` references (from screen's own environment) before injecting the bytes: `stuff '$HOME'` sends the value of `HOME` (e.g. `/home/user`). Escape any literal `$` you want to send with a backslash: `stuff '\$HOME'` sends the literal characters `$HOME`.

### Sending a literal `!shell-command` (real shell mode, not a chat message)

Claude Code's input box has a `!`-prefix shell mode: typing a bare `!` when the
box is empty switches the box into shell mode (visible as a `! for shell mode`
hint), and a command submitted from that mode runs directly in the visible
terminal, with its raw output printed inline — not routed through the agent's
own Bash tool call.

Sending the whole thing as one atomic `stuff` string, e.g.
`screen -S claude-remote-N -X stuff $'!some-command\r'`, does **not** reliably
trigger this mode — the session usually treats it as a chat message that
happens to start with `!`, and the agent decides on its own whether/how to run
it via its Bash tool (where you can't see raw stdout, and the auto-mode
permission classifier applies to whatever it chooses to run — which may differ
from what you sent).

To land a real shell command, send the `!`, the command text, and the Enter
key as **three separate `stuff` calls**, with a short pause between each so
the UI has time to switch into shell mode before the rest arrives:

```
screen -S claude-remote-N -X stuff '!'
sleep 1
screen -S claude-remote-N -X stuff 'your command here'
sleep 1
screen -S claude-remote-N -X stuff $'\r'
```

Verify by capturing the screen afterward — a genuine shell-mode run shows the
command echoed as `! your command here` followed by its raw output, directly
in the transcript.

## Listing the fleet

Run this to list the fleet (namely, screens whose names match `claude-remote-*`):

    screen -ls claude-remote-

This command exits 1 when no screens match that prefix. There might be other screens on the machine which _would_ be shown by a plain `screen -ls` command, but you may _only_ interact with screens named `claude-remote-*` (or `claude-boss`, which drives the fleet rather than belonging to it).

## Custom requests

If the user asks you to launch a new remote claude with some settings that the launch script doesn't easily let you control, you may run your own hand-written launch command, but be sure to copy the logic (e.g. which variables get set) in the launch script in every way, except for the ways that the user has requested.
