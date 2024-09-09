
alias cdconfigs="cd $SHELL_CONFIGS_DIR"
alias cdaliases="cd $SHELL_CONFIGS_DIR/aliases"
alias vialiases="vi $SHELL_CONFIGS_DIR/aliases/general.sh"


#One line convenience functions
alias vir='vi "$(ls -t | head -1)"'
alias vio='vi "$(ls -t | tail -1)"'
alias cdr='cd "$(ls -td -- */ | head -1)"'
alias cdo='cd "$(ls -td -- */ | tail -1)"'
alias dc=cd  # Resist typos
alias c='clear'
if $IS_LINUX; then
    alias o='xdg-open'
else
    alias o='open'
fi

#Some more ls aliases
alias lf='ls -F'
alias la='ls -FA'
alias ll='ls -Flh'
alias lo='ls -Flht' #Oldest edit at the bottom
alias lod='ls -lhtd -- */' #Oldest edit at the bottom, folders only
alias lt='ls -Flhtr' #Most recent edit at the bottom
alias ltd='ls -lhtrd -- */' #Most recent edit at the bottom, folders only
if $IS_LINUX; then #-v options below are linux-specific
    alias lv='ls -Flhv' #sorts output numerically instead of by string order
    alias lvd='ls -lhvd -- */' #sorts output numerically instead of by string order, folders only
fi


#'Bookmarked' folders
alias cdrepos='cd ~/repos'
alias cdmedia="cd $HOME/Dropbox*/Science/the_big_media_folder"
if $IS_LINUX; then
    alias cdmyshortcuts='cd ~/.local/share/applications'
    alias cdshortcuts='cd /usr/share/applications'
fi

#Provide useful default arguments for some programs
alias ffmpeg="ffmpeg -hide_banner"
alias ffprobe="ffprobe -hide_banner"

