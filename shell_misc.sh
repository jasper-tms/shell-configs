umask 0002 #Compared to the default of umask 0022, this turns on the group write permissions for newly created files

if ${IS_LINUX:=false}; then
    if [ -f "$SHELL_CONFIGS_DIR/ls_colors.txt" ]; then
        eval $(dircolors -b $SHELL_CONFIGS_DIR/ls_colors.txt)
    fi

    # Remap Caps Lock button to be a Ctrl button
    if which setxkbmap > /dev/null; then
        setxkbmap -option ctrl:nocaps
    fi
    # Provide a way out if the user is stuck in Caps Lock by allowing
    # them to re-enable the Caps Lock key using a caps-only command
    alias STOPYELLING="setxkbmap -option"
fi
if ${IS_MAC:=false}; then
    # From https://apple.stackexchange.com/questions/33677/how-can-i-configure-mac-terminal-to-have-color-ls-output
    export CLICOLOR=1
    export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd
fi

# GNU screen before version 5.0 cannot render 24-bit truecolor. When
# COLORTERM=truecolor is inherited from the outer terminal, applications that
# honor it (for example Claude Code) emit truecolor background sequences that
# these older screen versions mangle into reverse-video boxes (dark text on a
# light background). Inside such a session, drop the hint so those applications
# fall back to 256-color, which screen renders correctly. screen 5.0 and later
# support truecolor, so leave COLORTERM untouched there. The $STY check ensures
# this only runs inside screen, leaving normal terminals alone.
if [ -n "$STY" ] && command -v screen > /dev/null 2>&1; then
    screen_major_version=$(screen --version 2>/dev/null | sed -n 's/^Screen version \([0-9][0-9]*\).*/\1/p')
    if [ -n "$screen_major_version" ] && [ "$screen_major_version" -lt 5 ]; then
        unset COLORTERM
    fi
    unset screen_major_version
fi

# Before setting LC_COLLATE=C, the default collation is UTF-8 which does this:
# $ ls -1
# apple
# Apple
# +middle    <- leading punctuation is basically ignored (only used as a tiebreaker)
# middle
# zebra
# Zebra      <- capitalization is basically ignored too (only used as a tiebreaker)
export LC_COLLATE=C
# $ LC_COLLATE=C ls -1
# +middle    <- all characters now influence sorting, and + sorts before letters
# Apple
# Zebra      <- capital letters now sort before lowercase letters
# apple
# middle
# zebra

if ${IS_MAC:=false}; then
    computername=$(scutil --get LocalHostName)
elif ${IS_ZSH:=false}; then
    computername=%m
elif ${IS_BASH:=false}; then
    computername='\h'
fi
if ${IS_ZSH:=false}; then
    case "$TERM" in
        # See https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
        xterm-color|*xterm-256color|screen) export PS1='[%*]%B%F{green}'$computername'%f:%F{blue}%~/%f%b'$'\n''$ ';;
        *) export PS1='[%*]'$computername':%/$ ';;
    esac
elif ${IS_BASH:=false}; then
    case "$TERM" in
        # See https://misc.flogisoft.com/bash/tip_colors_and_formatting
        xterm-color|*xterm-256color|screen) export PS1='[\t]\[\033[01;32m\]\u@'$computername'\[\033[00m\]:\[\033[01;34m\]\w\[\033[0m\]\n$ ';;
        *) export PS1='[\t]\u@'$computername':\w$ ';;
    esac
fi


MOREPYTHONPATHS=\
$HOME/repos/jasper-tms/misc/miscpy

add_to_path PYTHONPATH "$MOREPYTHONPATHS"
add_to_path --append "$MOREPYTHONPATHS"
