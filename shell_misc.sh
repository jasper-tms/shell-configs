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

case ${SHELL##*/} in
    zsh)
    case "$TERM" in
        # See https://misc.flogisoft.com/bash/tip_colors_and_formatting
        xterm-color|*xterm-256color|screen) export PS1='[%*]%B%F{green}%m%f:%F{blue}%~%f%b$ ';;
        *) export PS1='[%*]%m:%/$ ';;
    esac
    ;;
    bash)
    case "$TERM" in
        # See https://misc.flogisoft.com/bash/tip_colors_and_formatting
        xterm-color|*xterm-256color|screen) export PS1='[\T]\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[0m\]$ ';;
        *) export PS1='[\T]\u@\h:\w$ ';;
    esac
    ;;
esac


python_script_folders=\
$HOME/repos/GridTape_VNC_paper:\
$HOME/repos/GridTape_VNC_paper/figures_and_analysis/python_utilities:\
$HOME/repos/GridTape_VNC_paper/template_registration_pipeline/register_EM_dataset_to_template:\
$HOME/repos/jasper-tms/misc/miscpy:\
$HOME/Dropbox\ \(HMS\)/htem_team/Jasper/data/vnc1/miscpy

if [ -z "$PYTHONPATH" ]; then
    export PYTHONPATH=$python_script_folders
else
    export PYTHONPATH=$python_script_folders:$PYTHONPATH
fi

export PATH=$PATH:$python_script_folders
