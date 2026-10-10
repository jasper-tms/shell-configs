# Aliases for Claude Code

alias cdclaude="cd $SHELL_CONFIGS_DIR/claude"

# Launch Claude Code using the Scoretec Team seat instead of the personal Max
# subscription. A separate config directory gets its own login, settings, and
# conversation history, leaving the plain `claude` command untouched.
alias claudew='CLAUDE_CONFIG_DIR="$HOME/.claude-scoretec" command claude'

# Print the Claude config directory that sessions in the given directory
# should use, or nothing for the default personal account. Paths containing
# "scoretec" (any capitalization) use the Scoretec Team seat. Also used by the
# remote-claude-sessions launcher, so this is the one place the rule lives.
claude_config_dir_for_directory() {
    local lowercase_directory
    lowercase_directory=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
    if [[ "$lowercase_directory" == *scoretec* ]]; then
        printf '%s\n' "$HOME/.claude-scoretec"
    fi
}

# Make plain `claude` pick its account from the current directory (see above),
# unless CLAUDE_CONFIG_DIR is already set. A function rather than an alias so
# that arguments pass through to both branches.
claude() {
    local config_directory
    config_directory=$(claude_config_dir_for_directory "$PWD")
    if [ -z "${CLAUDE_CONFIG_DIR:-}" ] && [ -n "$config_directory" ]; then
        echo "Using scoreTec's Claude Team seat" >&2
        CLAUDE_CONFIG_DIR="$config_directory" command claude "$@"
    else
        command claude "$@"
    fi
}
