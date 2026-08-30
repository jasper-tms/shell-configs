#!/bin/bash
# Captures the exact system prompt a normal interactive `claude` session
# sends to the API.
#
# Default mode writes the captured prompt next to this script as
# system-prompt.md or system-prompt.txt (whichever extension fits the
# captured content), exactly as before.
#
# Flags (all optional):
#   --model <model-id>   Request a specific model (e.g. claude-opus-5). The
#                        system prompt Claude Code sends is model-conditional,
#                        so this changes what gets captured. Omit to let the
#                        binary use its default model.
#   --version <X.Y.Z>    Run a specific installed version binary from
#                        ~/.local/share/claude/versions/<X.Y.Z> instead of the
#                        `claude` on PATH. Useful for capturing the prompt an
#                        older build sends.
#   --archive            Write the result into archives/ (next to this script) as
#                        claude-code-v<version>_<model-short>.md with a dated
#                        provenance header, instead of the default
#                        system-prompt.md. The header notes when the model the
#                        binary actually sent differs from the one requested,
#                        or when no request could be captured at all.
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

# Argument parsing.
REQUESTED_MODEL=""
REQUESTED_VERSION=""
OUTPUT_MODE="default"
while [ $# -gt 0 ]; do
    case "$1" in
        --model)
            REQUESTED_MODEL="$2"; shift 2 ;;
        --version)
            REQUESTED_VERSION="$2"; shift 2 ;;
        --archive)
            OUTPUT_MODE="archive"; shift ;;
        *)
            echo "Unknown argument: $1" >&2; exit 2 ;;
    esac
done

# Resolve which claude binary to run. With --version, run that installed
# version directly (this is exactly what the `claude` launcher symlink does);
# otherwise use whatever `claude` is on PATH and read its version for naming.
if [ -n "$REQUESTED_VERSION" ]; then
    # Resolve version binaries against CLAUDE_VERSIONS_DIR when set. The
    # canonical ~/.local/share/claude/versions folder is auto-pruned whenever
    # any claude session starts, so archival captures should point this at a
    # directory outside that folder to keep old binaries from being deleted
    # mid-run.
    VERSIONS_DIR="${CLAUDE_VERSIONS_DIR:-$HOME/.local/share/claude/versions}"
    CLAUDE_BINARY="$VERSIONS_DIR/$REQUESTED_VERSION"
    if [ ! -x "$CLAUDE_BINARY" ]; then
        echo "Error: no executable version binary at $CLAUDE_BINARY" >&2
        exit 1
    fi
    RESOLVED_VERSION="$REQUESTED_VERSION"
else
    CLAUDE_BINARY="claude"
    RESOLVED_VERSION="$(claude --version | awk '{print $1}')"
fi

# Short model label for filenames: drop the leading "claude-" (claude-opus-5
# -> opus-5). Empty when no model was requested.
MODEL_SHORT="${REQUESTED_MODEL#claude-}"
[ -z "$MODEL_SHORT" ] && MODEL_SHORT="default"

# Extra CLI args passed to the binary.
EXTRA_ARGS=()
[ -n "$REQUESTED_MODEL" ] && EXTRA_ARGS=(--model "$REQUESTED_MODEL")

CLAUDE_CONFIG_DIRECTORY="${CLAUDE_CONFIG_DIR:-${CLAUDE_HOME:-$HOME}/.claude}"
CLAUDE_JSON_PATH="${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR/.claude.json}"
CLAUDE_JSON_PATH="${CLAUDE_JSON_PATH:-${CLAUDE_HOME:-$HOME}/.claude.json}"

# A distinct screen name (parameterized by version/model so parallel or
# repeated captures don't clobber each other's sessions) rather than the
# claude-remote-N scheme used by launch-new-claude-remote-control.sh: this
# session is a throwaway capture process, not a member of that persistent
# fleet.
SCREEN_NAME="claude-temp-system-prompt-${RESOLVED_VERSION}-${MODEL_SHORT}"

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

echo "Capturing from ${CLAUDE_BINARY} (version ${RESOLVED_VERSION}, model ${REQUESTED_MODEL:-<default>})..." >&2
(
    cd "$WORK_DIRECTORY"
    # DISABLE_AUTOUPDATER=1 so an older --version binary exercises its own
    # code rather than silently updating itself to the latest release first.
    screen -dmS "$SCREEN_NAME" env \
        DISABLE_AUTOUPDATER=1 \
        CLAUDE_CODE_ENABLE_TELEMETRY=1 \
        OTEL_LOG_RAW_API_BODIES="file:$CAPTURE_DIRECTORY" \
        "$CLAUDE_BINARY" "${EXTRA_ARGS[@]}" --prompt-suggestions false "Wait for further instructions"
)

# Poll for the captured request body rather than sleeping a fixed amount, so
# this finishes as soon as the turn completes on a fast connection and still
# succeeds on a slow one. A plain "Wait for further instructions" turn can
# also trigger a small, separate auxiliary call (e.g. a background classifier
# on a cheaper model) -- once at least one *.request.json shows up, pause
# briefly so any such second file has time to land, then take the largest
# file, which is the real interactive turn: the classifier call carries no
# tools and a short system prompt, dwarfed by the full interactive one.
CAPTURE_FAILED=0
REQUEST_FILE=""
ATTEMPTS_REMAINING=20
while [ -z "$(ls -1 "$CAPTURE_DIRECTORY"/*.request.json 2> /dev/null)" ]; do
    if [ "$ATTEMPTS_REMAINING" -le 0 ]; then
        if [ "$OUTPUT_MODE" = "archive" ]; then
            # In archive mode a failed capture is itself a result worth
            # recording (e.g. an old binary refusing an unknown model), so note
            # it in the file rather than aborting the whole matrix run.
            CAPTURE_FAILED=1
            break
        fi
        echo "Error: no request body appeared in $CAPTURE_DIRECTORY after 40s" >&2
        exit 1
    fi
    ATTEMPTS_REMAINING=$(( ATTEMPTS_REMAINING - 1 ))
    sleep 2
done
if [ "$CAPTURE_FAILED" -eq 0 ]; then
    sleep 3
    REQUEST_FILE="$(ls -1S "$CAPTURE_DIRECTORY"/*.request.json | head -n 1)"
fi

if [ "$OUTPUT_MODE" = "archive" ]; then
    ARCHIVE_DIRECTORY="$SCRIPT_DIR/archives"
    mkdir -p "$ARCHIVE_DIRECTORY"
    OUTPUT_FILE="$ARCHIVE_DIRECTORY/claude-code-v${RESOLVED_VERSION}_${MODEL_SHORT}.md"
    CAPTURE_DATE="$(date +%F)"

    # Reconstruct the exact command this run represents, expressed relative to
    # the archives/ folder the file lives in, so the header is a runnable
    # recipe for regenerating that specific capture.
    COMMAND_STRING="../get-system-prompt.sh"
    [ -n "$REQUESTED_VERSION" ] && COMMAND_STRING="$COMMAND_STRING --version $REQUESTED_VERSION"
    [ -n "$REQUESTED_MODEL" ] && COMMAND_STRING="$COMMAND_STRING --model $REQUESTED_MODEL"
    COMMAND_STRING="$COMMAND_STRING --archive"

    CAPTURE_FAILED="$CAPTURE_FAILED" \
    REQUESTED_MODEL="$REQUESTED_MODEL" \
    CAPTURE_DATE="$CAPTURE_DATE" \
    OUTPUT_FILE="$OUTPUT_FILE" \
    REQUEST_FILE="$REQUEST_FILE" \
    COMMAND_STRING="$COMMAND_STRING" \
    python3 <<'PYTHON_SCRIPT'
import json
import os

failed = os.environ["CAPTURE_FAILED"] == "1"
requested_model = os.environ.get("REQUESTED_MODEL", "")
capture_date = os.environ["CAPTURE_DATE"]
output_file = os.environ["OUTPUT_FILE"]
request_file = os.environ.get("REQUEST_FILE", "")
command_string = os.environ["COMMAND_STRING"]

header_lines = [
    f"This system prompt was extracted by `{command_string}` on {capture_date}"
]
system_prompt_text = ""
actual_model = None

if failed or not request_file:
    header_lines.append(
        f"NOTE: Capture failed — no API request body was produced when requesting "
        f"model '{requested_model or '<default>'}'. This Claude Code version most likely "
        f"rejected that model before sending any request."
    )
else:
    with open(request_file) as file:
        request_body = json.load(file)
    actual_model = request_body.get("model")
    system_prompt_text = "\n\n".join(
        block["text"]
        for block in request_body.get("system", [])
        if block.get("type") == "text"
    )
    if requested_model and actual_model and actual_model != requested_model:
        header_lines.append(
            f"NOTE: Requested model '{requested_model}' but this Claude Code version "
            f"actually sent model '{actual_model}'."
        )

document = "\n".join(header_lines) + "\n\n---\n\n"
if system_prompt_text:
    document += system_prompt_text + "\n"

with open(output_file, "w") as file:
    file.write(document)

print(f"actual_model={actual_model} failed={failed} chars={len(system_prompt_text)} -> {output_file}")
PYTHON_SCRIPT
else
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
fi
