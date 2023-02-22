umask 0002 #Compared to the default of umask 0022, this turns on the group write permissions for newly created files

if $IS_LINUX; then
    if [ -f "$SHELL_CONFIGS_DIR/ls_colors.txt" ]; then
        eval $(dircolors -b $SHELL_CONFIGS_DIR/ls_colors.txt)
    fi
fi
if $IS_MAC; then
    # From https://apple.stackexchange.com/questions/33677/how-can-i-configure-mac-terminal-to-have-color-ls-output
    export CLICOLOR=1
    export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd
fi

if $IS_ZSH; then
    case "$TERM" in
        # See https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
        xterm-color|*xterm-256color|screen) export PS1='[%*]%B%F{green}%m%f:%F{blue}%~%f%b$ ';;
        *) export PS1='[%*]%m:%/$ ';;
    esac
elif $IS_BASH; then
    case "$TERM" in
        # See https://misc.flogisoft.com/bash/tip_colors_and_formatting
        xterm-color|*xterm-256color|screen) export PS1='[\t]\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[0m\]$ ';;
        *) export PS1='[\t]\u@\h:\w$ ';;
    esac
fi


MOREPYTHONPATHS=\
$HOME/repos/jasper-tms/misc/miscpy

export PYTHONPATH=$MOREPYTHONPATHS${PYTHONPATH+:$PYTHONPATH}

export PATH=$PATH:$MOREPYTHONPATHS
