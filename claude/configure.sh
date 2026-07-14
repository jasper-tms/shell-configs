#!/bin/bash
# One-time configuration steps to get the files in this folder
# to be seen and used by Claude Code. Run this file as a script
# or run the commands yourself.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd -P)"

# Where Claude reads its config from: $CLAUDE_CONFIG_DIR (Claude's own variable)
# if set, else the home Claude runs under. That home is $CLAUDE_HOME on machines
# that launch Claude with an overridden HOME (see runpod-config/pods/pod_init.sh),
# and plain $HOME everywhere else.
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-${CLAUDE_HOME:-$HOME}/.claude}"

# Make sure the config dir exists before we try to symlink into it.
mkdir -p "$CLAUDE_DIR"
echo "Configuring Claude in $CLAUDE_DIR"

# Symlink settings.json
ln -snvf "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"

# Symlink statusline-command.sh
ln -snvf "$SCRIPT_DIR/statusline-command.sh" "$CLAUDE_DIR/statusline-command.sh"

# Ensure the global CLAUDE.md references this repo's CLAUDE.md as its first line.
GLOBAL_CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
REF_LINE="@$SCRIPT_DIR/CLAUDE.md"
if [ ! -f "$GLOBAL_CLAUDE_MD" ]; then
    echo "$REF_LINE" > "$GLOBAL_CLAUDE_MD"
    echo "created $GLOBAL_CLAUDE_MD with reference to $SCRIPT_DIR/CLAUDE.md"
elif ! grep -Fxq "$REF_LINE" "$GLOBAL_CLAUDE_MD"; then
    printf '%s\n%s' "$REF_LINE" "$(cat "$GLOBAL_CLAUDE_MD")" > "$GLOBAL_CLAUDE_MD"
    echo "prepended reference to $SCRIPT_DIR/CLAUDE.md in $GLOBAL_CLAUDE_MD"
fi

# Offer to link this repo's skills into the global claude skills folder. Some
# skills here are only relevant on some machines (work vs personal), so this
# prompts for which ones to install rather than linking them all. Passing
# $SCRIPT_DIR keeps the search to this repo's claude/skills folder. (Called by
# path since shell_scripts/ may not be on PATH yet on a freshly set up machine.)
"$SCRIPT_DIR/../shell_scripts/symlink-skills" "$SCRIPT_DIR"

# Claude tries to update settings.json too much (e.g. user changes the model or
# effort within a session -> claude tries to make that the new default for future
# sessions by changing settings.json), so make it read-only to prevent that.
# Actually I've decided to allow it for now so the next line is commented out.
#chmod -w "$SCRIPT_DIR" "$SCRIPT_DIR/settings.json"
