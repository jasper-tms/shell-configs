#Commands must be defined as functions (instead of scripts) if they:
# - modify and/or need access to special login shell variables (e.g. PS1)
# - override a shell builtin


#This file must be sourced, not just executed, for the functions to be accessible.
#Sourcing it in your ~/.bashrc is one way to take care of this.

function exit {
    if [ -z "$STY" ]; then
        # If not in a 'screen', exit normally
        builtin exit
    else
        if $IS_ZSH; then
            read "input?WARNING: You are in a screen. Press enter to detatch, or type 'exit' again to exit: "
        elif $IS_BASH; then
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
    if $IS_ZSH; then
        export PROMPT="$(echo $PROMPT | sed 's/%~/%1~/g')"
    elif $IS_BASH; then
        export PS1="$(echo $PS1 | sed 's/\\w/\\W/g') "
    fi
}

function longpath {
    if $IS_ZSH; then
         export PROMPT="$(echo $PROMPT | sed 's/%1~/%~/g')"
    elif $IS_BASH; then
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
    if $IS_ZSH; then
        export PROMPT="$(echo $PROMPT | sed 's/\[%\*\]//')"  # TODO
    elif $IS_BASH; then
        export PS1="${PS1/\[\\T\]/}"
    fi

}
#"

function clock {
    if $IS_ZSH; then
        case $PROMPT in
            blah) echo "Clock already showing" ;;
            *)    export PROMPT="[%*]$PROMPT" ;; #TODO
        esac
    elif $IS_BASH; then
        case $PS1 in
            \[\\T\]*) echo "Clock already showing" ;;
            *)        export PS1="[\T]$PS1" ;;
        esac
    fi
}

# Define realpath on MacOS if it is not present
if $IS_MAC && ! which realpath > /dev/null; then
    function realpath {
        filepath="$1"
        # First, if the file is a symlink, recursively resolve it
        # TODO figure out I want to handle broken links and then implement it
        while [ -L "$filepath" ]; do
            link_path=$(readlink $filepath)
            case ${link_path:0:1} in
                "/") filepath="$link_path" ;;
                "~") filepath="$link_path" ;;
                *) filepath="$(dirname "$filepath")/$link_path"
            esac
        done
        # Then resolve symlinks and .. and any other stuff in the folder path
        echo "$(cd "$(dirname "$filepath")" && pwd -P)/$(basename "$1")"
    }
fi
