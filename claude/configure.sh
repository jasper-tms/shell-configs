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

# Symlink hook scripts. settings.json references these by their installed path
# ($HOME/.claude/hooks/...), so they must live under $CLAUDE_DIR to be found.
mkdir -p "$CLAUDE_DIR/hooks"
for hook in "$SCRIPT_DIR"/hooks/*.sh; do
    ln -snvf "$hook" "$CLAUDE_DIR/hooks/$(basename "$hook")"
done

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

# Register the filetypes MCP server. It gives Claude native tools --
# `glob_plus` (a superset of the built-in Glob tool that annotates each match
# by type) and `list_directory` (an annotated `ls`) -- that report file type
# (file / directory / symlink-and-its-target / executable), information the
# built-in Glob tool omits, so symbolic links would otherwise be invisible.
# The built-in Glob is denied in settings.json so glob_plus takes its place.
# Registration lands in $CLAUDE_DIR/../.claude.json (Claude's own state file,
# not tracked in this repo), which is why it is (re)done here rather than
# committed: each machine gets its own correct absolute path to server.py.
if claude mcp get filetypes &> /dev/null; then
    echo "filetypes MCP server already registered"
else
    claude mcp add filetypes -s user -- \
        uv run --script "$SCRIPT_DIR/mcp-servers/filetypes/server.py"
    echo "registered filetypes MCP server"
fi

# Claude rewrites settings.json when a session changes the model or effort.
# Making it read-only stops that but also breaks the slash commands that save a
# setting -- /tui then fails instead of switching -- so reset it by hand.
#chmod -w "$SCRIPT_DIR" "$SCRIPT_DIR/settings.json"
