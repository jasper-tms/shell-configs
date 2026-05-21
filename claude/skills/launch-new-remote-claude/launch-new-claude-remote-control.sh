#!/usr/bin/env bash
# Launch a new `claude` interactive session with Remote Control enabled,
# inside a detached GNU screen so it keeps running after this shell exits.
#
# Working directory:
#   $CLAUDE_WORK_DIR if set, else ~/.claude/remote-sessions/
#   Created if missing. Workspace trust is pre-accepted for this directory
#   in ~/.claude.json so the trust prompt never appears.
#
# Session naming (auto-numbered from existing claude-remote-N screens):
#   - screen name:     claude-remote-N
#   - --name (RC UI):  <prefix>-N, where <prefix> is machine-dependent
#                      (see the hostname case block below)
#
# Usage:
#   ./launch-new-claude-remote-control.sh [initial-prompt]
#   CLAUDE_WORK_DIR=/some/path ./launch-new-claude-remote-control.sh [initial-prompt]
#
# initial-prompt is optional; defaults to "Wait for further instructions"
# so the new session takes a first turn for proper initialization.

set -euo pipefail

INITIAL_PROMPT="${1:-Wait for further instructions}"

# Pick the Remote Control display-name prefix for this machine, keyed on the
# short hostname. Add a case per machine you use. Unrecognized machines fall
# back to the lowercased short hostname (tr, not ${var,,}, for Bash 3.2/macOS).
HOST_SHORT="$(hostname -s)"
case "$HOST_SHORT" in
    Jaspers-Mac*) PREFIX="mac" ;;
    jaspberrypi)  PREFIX="rpi" ;;
    *)            PREFIX="$(printf '%s' "$HOST_SHORT" | tr '[:upper:]' '[:lower:]')" ;;
esac
RC_DISPLAY_NAME="${PREFIX}-${N}"

# Resolve work directory: canonicalize so the path used as a key in
# ~/.claude.json matches what claude itself will use at startup.
WORK_DIR_RAW="${CLAUDE_WORK_DIR:-$HOME/.claude/remote-sessions}"
mkdir -p "$WORK_DIR_RAW"
WORK_DIR="$(cd "$WORK_DIR_RAW" && pwd -P)"

# Ensure ~/.claude.json marks this directory as trusted.
CLAUDE_JSON="$HOME/.claude.json" WORK_DIR="$WORK_DIR" python3 <<'EOF'
import json, os
p = os.environ["CLAUDE_JSON"]
work_dir = os.environ["WORK_DIR"]
try:
    with open(p) as f:
        d = json.load(f)
except FileNotFoundError:
    d = {}
projects = d.setdefault("projects", {})
entry = projects.setdefault(work_dir, {})
entry["hasTrustDialogAccepted"] = True
with open(p, "w") as f:
    json.dump(d, f, indent=2)
EOF

# Auto-number the session: pick the lowest unused N among existing
# claude-remote-N screens, so killed sessions free up their numbers.
# (Sorted list instead of an associative array — works on Bash 3.2 / macOS.)
existing_ns="$(screen -ls 2>/dev/null \
    | grep -oE 'claude-remote-[0-9]+' \
    | sed 's/.*-//' \
    | sort -n -u || true)"

N=1
while printf '%s\n' "$existing_ns" | grep -qx "$N"; do
    N=$(( N + 1 ))
done
SCREEN_NAME="claude-remote-${N}"

cd "$WORK_DIR"
screen -dmS "$SCREEN_NAME" \
    claude --remote-control --name "$RC_DISPLAY_NAME" \
           --permission-mode auto \
           --effort high \
           "$INITIAL_PROMPT"

echo "Launched detached screen: $SCREEN_NAME"
echo "  Working directory:   $WORK_DIR"
echo "  Remote Control name: $RC_DISPLAY_NAME"
echo "  Effort level:        high"
echo "  Attach with:         screen -r $SCREEN_NAME"
echo "  List screens:        screen -ls"
echo "  Kill session:        screen -S $SCREEN_NAME -X quit"
