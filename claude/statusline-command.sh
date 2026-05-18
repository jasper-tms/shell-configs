#!/usr/bin/env bash
# Claude Code statusLine command — mirrors shell PS1

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')

# Mirror PS1 `\w`: abbreviate $HOME to ~
case "$cwd" in
    "$HOME") cwd="~" ;;
    "$HOME"/*) cwd="~${cwd#$HOME}" ;;
esac

# virtualenvwrapper env prefix: "(env) " when active, empty string when not
venv_prefix=""
if [ -n "$VIRTUAL_ENV" ]; then
    venv_prefix="($(basename "$VIRTUAL_ENV")) "
fi

user=$(whoami)
host=$(hostname -s)
time_str=$(date +%H:%M:%S)

# Bold orange for user@host and cwd, then reset
printf '%s[%s]\033[01;38;5;208m%s@%s\033[00m:\033[01;38;5;208m%s\033[0m' \
    "$venv_prefix" "$time_str" "$user" "$host" "$cwd"
