#!/usr/bin/env bash
# Launch a new `claude` interactive session with Remote Control enabled,
# inside a detached GNU screen so it keeps running after this shell exits.
#
# Working directory:
#   --dir <path>, else $CLAUDE_WORK_DIR, else <claude config dir>/remote-sessions/
#   Created if missing. Workspace trust is pre-accepted for this directory
#   in the Claude config dir's .claude.json so the trust prompt never appears.
#   See the claude-home resolution block below for how that dir is located.
#
# Session naming (auto-numbered from existing claude-remote-N screens):
#   - screen name:     claude-remote-N
#   - --name (RC UI):  <prefix>-N[-<suffix>], where <prefix> is
#                      machine-dependent (see the prefix-detection block
#                      below) and <suffix> comes from --suffix, or is
#                      derived from --model (e.g. rpi-2-fable).
#
# Usage:
#   ./launch-new-claude-remote-control.sh [options] [initial-prompt]
#
# Options:
#   -m, --model  <model>   Model to run. Accepts a full model id
#                          (e.g. claude-fable-5) or a shorthand:
#                            fable   -> claude-fable-5
#                            opus    -> claude-opus-4-8
#                            sonnet  -> claude-sonnet-5
#                            haiku   -> claude-haiku-4-5-20251001
#                          When set, a short label is appended to the
#                          Remote Control display name (e.g. rpi-2-fable),
#                          unless overridden by --suffix. With no --model,
#                          the account default model is used and no suffix
#                          is added.
#   -s, --suffix <text>    Explicit suffix for the Remote Control display
#                          name, appended after the auto-numbered name.
#                          Overrides any model-derived suffix.
#   -d, --dir    <path>    Working directory for the session. Overrides
#                          $CLAUDE_WORK_DIR. Defaults to
#                          <claude config dir>/remote-sessions.
#   -e, --effort <level>   Reasoning effort (default: high).
#   -p, --prompt <text>    Initial prompt. May also be given as a trailing
#                          positional argument. Defaults to
#                          "Wait for further instructions" so the new
#                          session takes a first turn for initialization.
#   -h, --help             Show this help and exit.
#
# Examples:
#   ./launch-new-claude-remote-control.sh
#   ./launch-new-claude-remote-control.sh "Wait for further instructions"
#   ./launch-new-claude-remote-control.sh --model fable "/developer Run a loop"
#   ./launch-new-claude-remote-control.sh -m fable -d ~/repos/jasper-tms/swiss-table-tennis-chat
#   CLAUDE_WORK_DIR=/some/path ./launch-new-claude-remote-control.sh

set -euo pipefail

usage() {
    sed -n '2,50p' "$0" | sed 's/^# \{0,1\}//'
}

# --- Defaults ---
MODEL_INPUT=""
NAME_SUFFIX=""
SUFFIX_EXPLICIT=0
EFFORT="high"
PROMPT=""
PROMPT_SET=0
DIR_OVERRIDE=""

# --- Parse options (order-independent flags plus one positional prompt) ---
while [ $# -gt 0 ]; do
    case "$1" in
        -m|--model)  MODEL_INPUT="${2:-}"; shift 2 ;;
        -s|--suffix) NAME_SUFFIX="${2:-}"; SUFFIX_EXPLICIT=1; shift 2 ;;
        -d|--dir)    DIR_OVERRIDE="${2:-}"; shift 2 ;;
        -e|--effort) EFFORT="${2:-}"; shift 2 ;;
        -p|--prompt) PROMPT="${2:-}"; PROMPT_SET=1; shift 2 ;;
        -h|--help)   usage; exit 0 ;;
        --)          shift
                     if [ $# -gt 0 ]; then PROMPT="$1"; PROMPT_SET=1; shift; fi ;;
        -*)          echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
        *)           PROMPT="$1"; PROMPT_SET=1; shift ;;
    esac
done

if [ "$PROMPT_SET" -eq 0 ]; then
    PROMPT="Wait for further instructions"
fi

# --- Resolve model shorthand to (full id, short label) ---
# An empty MODEL_INPUT leaves MODEL_ID empty: no --model flag is passed and
# the account default model is used. Known shorthands expand to their full id
# and contribute a short label used as the display-name suffix. An unrecognized
# value is passed through verbatim, with a sanitized label derived from it.
MODEL_ID=""
MODEL_LABEL=""
case "$MODEL_INPUT" in
    "" )
        : ;;
    fable )
        MODEL_ID="claude-fable-5"; MODEL_LABEL="fable" ;;
    claude-fable-5 )
        MODEL_ID="$MODEL_INPUT"; MODEL_LABEL="fable" ;;
    opus )
        MODEL_ID="claude-opus-4-8"; MODEL_LABEL="opus" ;;
    claude-opus-4-8|"claude-opus-4-8[1m]" )
        MODEL_ID="$MODEL_INPUT"; MODEL_LABEL="opus" ;;
    sonnet )
        MODEL_ID="claude-sonnet-5"; MODEL_LABEL="sonnet" ;;
    claude-sonnet-5 )
        MODEL_ID="$MODEL_INPUT"; MODEL_LABEL="sonnet" ;;
    haiku )
        MODEL_ID="claude-haiku-4-5-20251001"; MODEL_LABEL="haiku" ;;
    claude-haiku-4-5-20251001 )
        MODEL_ID="$MODEL_INPUT"; MODEL_LABEL="haiku" ;;
    * )
        MODEL_ID="$MODEL_INPUT"
        MODEL_LABEL="$(printf '%s' "$MODEL_INPUT" \
            | tr '[:upper:]' '[:lower:]' \
            | sed -e 's/^claude-//' -e 's/[^a-z0-9]\{1,\}/-/g' \
                  -e 's/^-//' -e 's/-$//')"
        ;;
esac

# A model-derived label becomes the display-name suffix unless one was
# given explicitly with --suffix.
if [ "$SUFFIX_EXPLICIT" -eq 0 ] && [ -n "$MODEL_LABEL" ]; then
    NAME_SUFFIX="$MODEL_LABEL"
fi

# Sanitize the suffix so it is safe inside a screen/RC display name.
if [ -n "$NAME_SUFFIX" ]; then
    NAME_SUFFIX="$(printf '%s' "$NAME_SUFFIX" \
        | tr '[:upper:]' '[:lower:]' \
        | sed -e 's/[^a-z0-9]\{1,\}/-/g' -e 's/^-//' -e 's/-$//')"
fi

# Pick the Remote Control display-name prefix for this machine:
# First check RUNPOD_POD_ID to see if we're a Runpod node.
# If not, check `hostname` to determine which machine we are.
# Unrecognized machines fall back to the lowercased short
# hostname (tr, not ${var,,}, for Bash 3.2/macOS).
# Extend this section manually as new computers are added.
if [ -n "${RUNPOD_POD_ID:-}" ]; then
    PREFIX="runpod"
else
    HOST_SHORT="$(hostname -s)"
    case "$HOST_SHORT" in
        Jaspers-Mac*) PREFIX="mac" ;;
        jaspberrypi)  PREFIX="rpi" ;;
        thorax)       PREFIX="thorax" ;;
        *)            PREFIX="$(printf '%s' "$HOST_SHORT" | tr '[:upper:]' '[:lower:]')" ;;
    esac
fi

# Run claude under $CLAUDE_HOME where defined, else our own $HOME. Exported so
# the claude we screen-launch below inherits it, rather than relying on our caller.
claude_home="${CLAUDE_HOME:-$HOME}"
export HOME="$claude_home"

# .claude.json normally sits *beside* the config dir, but claude moves it
# *inside* when $CLAUDE_CONFIG_DIR is set. Mirror both so we write the trust
# setting to the file claude will actually read.
if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
    claude_config_dir="$CLAUDE_CONFIG_DIR"
    claude_json="$CLAUDE_CONFIG_DIR/.claude.json"
else
    claude_config_dir="$claude_home/.claude"
    claude_json="$claude_home/.claude.json"
fi

# Resolve work directory: --dir wins, then $CLAUDE_WORK_DIR, then the default.
# Canonicalize so the path used as a key in .claude.json matches what
# claude itself will use at startup.
WORK_DIR_RAW="${DIR_OVERRIDE:-${CLAUDE_WORK_DIR:-$claude_config_dir/remote-sessions}}"
mkdir -p "$WORK_DIR_RAW"
WORK_DIR="$(cd "$WORK_DIR_RAW" && pwd -P)"

# Ensure .claude.json marks this directory as trusted.
CLAUDE_JSON="$claude_json" WORK_DIR="$WORK_DIR" python3 <<'EOF'
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
RC_DISPLAY_NAME="${PREFIX}-${N}"
if [ -n "$NAME_SUFFIX" ]; then
    RC_DISPLAY_NAME="${RC_DISPLAY_NAME}-${NAME_SUFFIX}"
fi

cd "$WORK_DIR"

# GNU screen before version 5.0 cannot render 24-bit truecolor: when
# COLORTERM=truecolor is set, claude emits truecolor background sequences that
# these older screen versions mangle into reverse-video boxes (dark text on a
# light background). screen launches claude directly below, with no intervening
# shell to source shell_misc.sh (which performs this same unset for interactive
# in-screen shells), so we must drop the hint here in the environment that
# screen, and therefore claude, inherits. claude then falls back to 256-color,
# which screen renders correctly. screen 5.0 and later support truecolor, so
# leave COLORTERM untouched there.
screen_major_version="$(screen --version 2>/dev/null | sed -n 's/^Screen version \([0-9][0-9]*\).*/\1/p')"
if [ -n "$screen_major_version" ] && [ "$screen_major_version" -lt 5 ]; then
    unset COLORTERM
fi
unset screen_major_version

# Assemble the claude command. --model is only added when a model was
# requested, so the default (no flag) behavior is unchanged.
CLAUDE_ARGS=( --remote-control --name "$RC_DISPLAY_NAME" \
              --permission-mode auto \
              --effort "$EFFORT" )
if [ -n "$MODEL_ID" ]; then
    CLAUDE_ARGS+=( --model "$MODEL_ID" )
fi
CLAUDE_ARGS+=( "$PROMPT" )

# This script is often run by another Claude session (e.g. claude-boss),
# which automatically sets CLAUDE_CODE_CHILD_SESSION=1 in the new Claude, which
# stops the new Claude from saving its transcript to ~/.claude/projects. Setting
# CLAUDE_CODE_FORCE_SESSION_PERSISTENCE=1 overrides that behavior, making the
# transcript save to the projects folder like a typical (non-child) session.
screen -dmS "$SCREEN_NAME" env CLAUDE_CODE_FORCE_SESSION_PERSISTENCE=1 claude "${CLAUDE_ARGS[@]}"

echo "Launched detached screen: $SCREEN_NAME"
echo "  Working directory:   $WORK_DIR"
echo "  Remote Control name: $RC_DISPLAY_NAME"
echo "  Model:               ${MODEL_ID:-<account default>}"
echo "  Effort level:        $EFFORT"
echo "  Initial prompt:      $PROMPT"
echo "  Attach with:         screen -r $SCREEN_NAME"
echo "  List screens:        screen -ls"
echo "  Kill session:        screen -S $SCREEN_NAME -X quit"
