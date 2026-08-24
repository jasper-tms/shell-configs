#!/bin/bash
# Captures the exact system prompt a normal interactive `claude` session
# sends to the API, and writes it next to this script as system-prompt.md or
# system-prompt.txt (whichever extension fits the captured content).
#
# How it works: Claude Code has an undocumented OpenTelemetry hook,
# OTEL_LOG_RAW_API_BODIES=file:<directory>, that dumps the raw JSON body of
# every API request (system prompt, tools, messages, everything) to that
# directory. This script briefly runs a real interactive `claude` session
# (not `claude -p`, which is the Agent SDK entrypoint and sends a
# noticeably different system prompt) inside a detached `screen`, so it
# behaves exactly like a session you'd start yourself, reads the system
# prompt out of the request body that produces, and tears everything down
# afterward.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd -P)"

# Where Claude reads its config from, mirroring configure.sh in this folder.
CLAUDE_CONFIG_DIRECTORY="${CLAUDE_CONFIG_DIR:-${CLAUDE_HOME:-$HOME}/.claude}"
CLAUDE_JSON_PATH="${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR/.claude.json}"
CLAUDE_JSON_PATH="${CLAUDE_JSON_PATH:-${CLAUDE_HOME:-$HOME}/.claude.json}"

# A distinct, fixed screen name rather than the claude-remote-N scheme used by
# launch-new-claude-remote-control.sh: this session is a throwaway capture
# process, not a member of that persistent fleet, and giving it its own name
# keeps it out of the numbering and out of `screen -ls claude-remote-`.
SCREEN_NAME="claude-temp-system-prompt"

# A working directory to run the throwaway session from. Using a fresh, empty
# directory (rather than the caller's current directory) keeps any
# project-specific CLAUDE.md content out of the capture, so the result
# reflects only the global system prompt Claude Code always sends. Resolved
# with pwd -P (not the raw mktemp path) because macOS's /var is a symlink to
# /private/var, and Claude Code's trust check operates on the resolved path --
# pre-trusting the unresolved path leaves the trust dialog stuck onscreen with
# nobody able to answer it.
WORK_DIRECTORY="$(cd -- "$(mktemp -d)" && pwd -P)"
CAPTURE_DIRECTORY="$(mktemp -d)"
cleanup() {
    screen -S "$SCREEN_NAME" -X quit &> /dev/null || true
    rm -rf "$WORK_DIRECTORY" "$CAPTURE_DIRECTORY"
}
trap cleanup EXIT

# In case a previous run of this script crashed and left its capture session
# behind, clear it before starting a new one.
screen -S "$SCREEN_NAME" -X quit &> /dev/null || true

# Pre-accept the workspace trust dialog for the throwaway directory, the same
# way launch-new-claude-remote-control.sh does, so the session below doesn't
# stall waiting for a trust prompt that nothing here can answer.
CLAUDE_JSON_PATH="$CLAUDE_JSON_PATH" WORK_DIRECTORY="$WORK_DIRECTORY" python3 <<'PYTHON_SCRIPT'
import json
import os

claude_json_path = os.environ["CLAUDE_JSON_PATH"]
work_directory = os.environ["WORK_DIRECTORY"]
try:
    with open(claude_json_path) as file:
        config = json.load(file)
except FileNotFoundError:
    config = {}
projects = config.setdefault("projects", {})
project_entry = projects.setdefault(work_directory, {})
project_entry["hasTrustDialogAccepted"] = True
with open(claude_json_path, "w") as file:
    json.dump(config, file, indent=2)
PYTHON_SCRIPT

echo "Starting a throwaway interactive session in a detached screen to capture the raw API body..." >&2
(
    cd "$WORK_DIRECTORY"
    screen -dmS "$SCREEN_NAME" env \
        CLAUDE_CODE_ENABLE_TELEMETRY=1 \
        OTEL_LOG_RAW_API_BODIES="file:$CAPTURE_DIRECTORY" \
        claude --prompt-suggestions false "Wait for further instructions"
)

# Poll for the captured request body rather than sleeping a fixed amount, so
# this finishes as soon as the turn completes on a fast connection and still
# succeeds on a slow one. A plain "Wait for further instructions" turn can
# also trigger a small, separate auxiliary call (e.g. a background classifier
# on a cheaper model) -- once at least one *.request.json shows up, pause
# briefly so any such second file has time to land, then take the largest
# file, which is the real interactive turn: the classifier call carries no
# tools and a short system prompt, dwarfed by the full interactive one.
ATTEMPTS_REMAINING=30
while [ -z "$(ls -1 "$CAPTURE_DIRECTORY"/*.request.json 2> /dev/null)" ]; do
    if [ "$ATTEMPTS_REMAINING" -le 0 ]; then
        echo "Error: no request body appeared in $CAPTURE_DIRECTORY after 60s" >&2
        exit 1
    fi
    ATTEMPTS_REMAINING=$(( ATTEMPTS_REMAINING - 1 ))
    sleep 2
done
sleep 3

REQUEST_FILE="$(ls -1S "$CAPTURE_DIRECTORY"/*.request.json | head -n 1)"

SYSTEM_PROMPT_TEXT="$(python3 - "$REQUEST_FILE" <<'PYTHON_SCRIPT'
import json
import sys

with open(sys.argv[1]) as file:
    request_body = json.load(file)

text_blocks = [
    block["text"]
    for block in request_body.get("system", [])
    if block.get("type") == "text"
]
print("\n\n".join(text_blocks))
PYTHON_SCRIPT
)"

# Pick .md when the captured text actually uses Markdown headings, .txt
# otherwise, and remove whichever extension we are not writing this run so a
# stale file from a previous, differently-formatted capture doesn't linger.
if printf '%s\n' "$SYSTEM_PROMPT_TEXT" | grep -qE '^#{1,6} '; then
    OUTPUT_EXTENSION="md"
else
    OUTPUT_EXTENSION="txt"
fi
rm -f "$SCRIPT_DIR/system-prompt.md" "$SCRIPT_DIR/system-prompt.txt"

OUTPUT_FILE="$SCRIPT_DIR/system-prompt.$OUTPUT_EXTENSION"
printf '%s\n' "$SYSTEM_PROMPT_TEXT" > "$OUTPUT_FILE"

CHARACTER_COUNT="$(printf '%s' "$SYSTEM_PROMPT_TEXT" | wc -c | tr -d ' ')"
echo "Wrote system prompt ($CHARACTER_COUNT chars) to $OUTPUT_FILE" >&2
