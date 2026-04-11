#!/bin/bash
# symlink files in this directory into $HOME/.claude where
# Claude Code will actually see and use them

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd -P)"
mkdir -p "$HOME/.claude" > /dev/null
ln -sv "$SCRIPT_DIR/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
ln -sv "$SCRIPT_DIR/settings.json" "$HOME/.claude/settings.json"
