#!/usr/bin/env bash
# Claude Code statusLine command — mirrors shell PS1

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')

# Mirror PS1 `\w`: abbreviate $HOME to ~
case "$cwd" in
    "$HOME") cwd="~" ;;
    "$HOME"/*) cwd="~${cwd#$HOME}" ;;
esac

# Which account usage is billed to: "{personal}" for an individual subscription,
# or "{<organization name>}" for a Team or Enterprise seat. CLAUDE_CONFIG_DIR is
# inherited from the Claude Code process (set by the claudew alias).
if [ -n "$CLAUDE_CONFIG_DIR" ]; then
    claude_config_file="$CLAUDE_CONFIG_DIR/.claude.json"
else
    claude_config_file="$HOME/.claude.json"
fi
organization_type=$(jq -r '.oauthAccount.organizationType // empty' "$claude_config_file" 2>/dev/null)
case "$organization_type" in
    claude_team*|claude_enterprise*)
        account_label="{$(jq -r '.oauthAccount.organizationName' "$claude_config_file")}" ;;
    *)
        account_label="{personal}" ;;
esac

host=$(hostname -s)
time_str=$(date +%H:%M:%S)

# Bold orange for host and cwd, then reset
printf '%s[%s]\033[01;38;5;208m%s\033[00m:\033[01;38;5;208m%s\033[0m' \
    "$account_label" "$time_str" "$host" "$cwd"
