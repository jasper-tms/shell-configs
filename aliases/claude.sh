# Aliases for Claude Code

alias cdclaude="cd $SHELL_CONFIGS_DIR/claude"

# Launch Claude Code using the Scoretec Team seat instead of the personal Max
# subscription. A separate config directory gets its own login, settings, and
# conversation history, leaving the plain `claude` command untouched.
alias claudew='CLAUDE_CONFIG_DIR="$HOME/.claude-scoretec" command claude'

# Make plain `claude` use the Scoretec Team seat automatically when launched
# from a path containing "scoretec" (any capitalization), unless
# CLAUDE_CONFIG_DIR is already set. A function rather than an alias so that
# arguments pass through to both branches.
claude() {
    local lowercase_directory
    lowercase_directory=$(printf '%s' "$PWD" | tr '[:upper:]' '[:lower:]')
    if [ -z "$CLAUDE_CONFIG_DIR" ] && [[ "$lowercase_directory" == *scoretec* ]]; then
        echo "Using scoreTec's Claude Team seat" >&2
        CLAUDE_CONFIG_DIR="$HOME/.claude-scoretec" command claude "$@"
    else
        command claude "$@"
    fi
}
