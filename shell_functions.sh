#Commands must be defined as functions (instead of scripts) if they:
# - modify and/or need access to special login shell variables (e.g. PS1)
# - override a shell builtin
#
#This file must be sourced, not just executed, for the functions to be accessible.
#Sourcing it in your ~/.bashrc is one way to take care of this.

# add_to_path [--append|--prepend] [VARIABLE_NAME] DIRECTORY [DIRECTORY ...]
#
# Idempotently add directories to a colon-separated, path-like variable such as
# PATH (the default), PYTHONPATH, or LD_LIBRARY_PATH. Prepend (the default) or
# append each DIRECTORY, but only if it is not already present, so re-running
# never stacks up duplicate entries no matter how many nested or
# non-interactive shells re-source these configs. Empty directories are
# skipped, each DIRECTORY may itself be a colon-separated list, and a directory
# that does not exist on the filesystem is not added and triggers a warning on
# stderr.
#
# VARIABLE_NAME is optional and defaults to PATH. It is recognized as the
# variable name (rather than a directory) when it consists solely of uppercase
# letters, digits, and underscores, which no real directory path does -- those
# always contain a slash, and usually a lowercase letter, tilde, or dot too.
#
# Works in both bash and zsh.
#
# Examples:
#   add_to_path "$HOME/.local/bin"                          # prepend to PATH
#   add_to_path --append "$HOME/repos/jasper-tms/misc/miscpy"
#   add_to_path PYTHONPATH "/first/dir:/second/dir"
function add_to_path {
    local mode=prepend
    local variable_name current_value additions argument remaining directory

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --append)  mode=append;  shift ;;
            --prepend) mode=prepend; shift ;;
            *) break ;;
        esac
    done

    # The first non-flag argument is the variable name only if it looks like
    # one (uppercase letters, digits, underscores). Otherwise it is a directory
    # and the variable defaults to PATH.
    case "${1:-}" in
        '' | *[!A-Z0-9_]*) variable_name=PATH ;;
        *) variable_name="$1"; shift ;;
    esac

    # Read the named variable's current value indirectly. Doing this through
    # eval works identically in bash and zsh, unlike ${!name} (bash-only) or
    # ${(P)name} (zsh-only).
    eval "current_value=\${$variable_name:-}"

    additions=""
    for argument in "$@"; do
        # Each argument may itself be a colon-separated list. Walk it without
        # relying on shell word-splitting, which behaves differently in zsh.
        remaining="$argument"
        while [ -n "$remaining" ]; do
            directory="${remaining%%:*}"
            case "$remaining" in
                *:*) remaining="${remaining#*:}" ;;
                *)   remaining="" ;;
            esac
            [ -z "$directory" ] && continue
            # Already present in the variable: nothing to do (checked before the
            # existence test so re-sourcing in nested shells stays quiet and
            # avoids a redundant filesystem stat per directory).
            case ":$current_value:" in *":$directory:"*) continue ;; esac
            # Warn and skip directories that do not exist on the filesystem.
            if [ ! -d "$directory" ]; then
                echo "add_to_path: not adding '$directory' to $variable_name: no such directory" >&2
                continue
            fi
            # Already queued to be added from an earlier argument.
            case ":$additions:" in *":$directory:"*) continue ;; esac
            additions="${additions:+$additions:}$directory"
        done
    done

    [ -z "$additions" ] && return 0

    if [ "$mode" = append ]; then
        current_value="${current_value:+$current_value:}$additions"
    else
        current_value="$additions${current_value:+:$current_value}"
    fi
    export "$variable_name=$current_value"
}

function rmdir {
    for dir in "$@"; do
        rm "$dir/.DS_Store" 2> /dev/null
    done
    command rmdir "$@"
}

function exit {
    if [ -z "$STY" ]; then
        # If not in a 'screen', exit normally
        builtin exit
    else
        if ${IS_ZSH:=false}; then
            read "input?WARNING: You are in a screen. Press enter to detatch, or type 'exit' again to exit: "
        elif ${IS_BASH:=false}; then
            read -p "WARNING: You are in a screen. Press enter to detatch, or type 'exit' again to exit: " input
        else
            echo "WARNING: Not zsh or bash so I don't know how to ask for user input. Detatching."
            sleep 1
            input=''
        fi

        if [ "$input" = "exit" ]; then
            builtin exit
        elif [ -z "$input" ]; then
            screen -d $STY
        else
            exit
        fi
    fi
}

function shortpath {
    if ${IS_ZSH:=false}; then
        export PROMPT="$(echo $PROMPT | sed 's/%~/%1~/g')"
    elif ${IS_BASH:=false}; then
        export PS1="$(echo $PS1 | sed 's/\\w/\\W/g') "
    fi
}

function longpath {
    if ${IS_ZSH:=false}; then
         export PROMPT="$(echo $PROMPT | sed 's/%1~/%~/g')"
    elif ${IS_BASH:=false}; then
        export PS1="$(echo $PS1 | sed 's/\\W/\\w/g') "
    fi
}

function fullpath {
    export PS1="$(echo $PS1 | sed 's/\\W/\\w/g') "
}

function startwatch {
    export STOPWATCH_STARTED=$(date)
    echo "Stopwatch started: $STOPWATCH_STARTED"
}

function readwatch {
    if [ -z "$STOPWATCH_STARTED" ]; then
        echo "Stopwatch not started. Start it with 'startwatch'"
        return 1
    fi
    echo "Stopwatch started: $STOPWATCH_STARTED"
    STOPWATCH_CHECKPOINT=$(date)
    echo "Current time:      $STOPWATCH_CHECKPOINT"
    diff_seconds=$(($(date -d "$STOPWATCH_CHECKPOINT" "+%s") - $(date -d "$STOPWATCH_STARTED" "+%s")))
    case "$1" in
        *s*)
            echo "Elapsed time:      $diff_seconds sec"
            ;;
        *m*)
            echo "Elapsed time:      $(($diff_seconds/60)) min $(($diff_seconds % 60)) sec"
            ;;
        *h*)
            echo "Elapsed time:      $(($diff_seconds/3600)) hr $(($diff_seconds % 3600 / 60)) min $(($diff_seconds % 60)) sec"
            ;;
        *)
            echo "Elapsed time:      $(($diff_seconds/3600)) hr $(($diff_seconds % 3600 / 60)) min $(($diff_seconds % 60)) sec"
            ;;
    esac
}


function noclock {
    if ${IS_ZSH:=false}; then
        export PROMPT="$(echo $PROMPT | sed 's/\[%\*\]//')"  # TODO
    elif ${IS_BASH:=false}; then
        export PS1="${PS1/\[\\t\]/}"
    fi

}
#"

function clock {
    if ${IS_ZSH:=false}; then
        case $PROMPT in
            blah) echo "Clock already showing" ;;
            *)    export PROMPT="[%*]$PROMPT" ;; #TODO
        esac
    elif ${IS_BASH:=false}; then
        case $PS1 in
            \[\\t\]*) echo "Clock already showing" ;;
            *)        export PS1="[\t]$PS1" ;;
        esac
    fi
}

# Define realpath on MacOS if it's not present, which was
# needed before ~2024, but since then `/bin/realpath` exists.
if ${IS_MAC:=false} && ! which realpath > /dev/null; then
    function realpath {
        filepath="$1"
        # First, if the file is a symlink, recursively resolve it
        # (TODO figure out how I want to handle broken links)
        while [ -L "$filepath" ]; do
            link_path=$(readlink -- "$filepath")
            case ${link_path:0:1} in
                "/") filepath="$link_path" ;;
                "~") filepath="$link_path" ;;
                *) filepath="$(dirname -- "$filepath")/$link_path"
            esac
        done
        # Then resolve symlinks and .. and any other stuff in the folder path
        echo "$(cd "$(dirname "$filepath")" && pwd -P)/$(basename -- "$1")"
    }
fi
