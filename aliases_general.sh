alias vialiases='vi ~/repos/jasper-tms/shell-configs/aliases_general.sh'

alias cdconfigs='cd ~/repos/jasper-tms/shell-configs'

#One line convenience functions
alias vir='vi "$(ls -t | head -1)"'
alias vio='vi "$(ls -t | tail -1)"'
alias cdr='cd "$(ls -td */ | head -1)"'
alias cdo='cd "$(ls -td */ | tail -1)"'
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
alias lod='ls -lhtd */' #Oldest edit at the bottom, folders only
alias lt='ls -Flhtr' #Most recent edit at the bottom
alias ltd='ls -lhtrd */' #Most recent edit at the bottom, folders only
if $IS_LINUX; then #-v options below are linux-specific
    alias lv='ls -Flhv' #sorts output numerically instead of by string order
    alias lvd='ls -lhvd */' #sorts output numerically instead of by string order, folders only
fi


#'Bookmarked' folders
alias cdj='cd ~/Dropbox\ \(HMS\)/htem_team/Jasper'
alias cddata='cd ~/Dropbox\ \(HMS\)/htem_team/Jasper/data'
alias cdri='cd ~/Dropbox\ \(HMS\)/htem_team/Jasper/data/righty'
alias cdmsv='cd ~/Dropbox\ \(HMS\)/htem_team/manuscripts/gtVNC_cell'
alias cdmsx='cd ~/Dropbox\ \(HMS\)/htem_team/manuscripts/2020_NatNeuro_KuanPhelpsEtAl_XrayHolographicNanotomographyMethods'
alias cdrepos='cd ~/repos'
alias cdtut='cd ~/Google\ Drive\ File\ Stream/My\ Drive/HTEM/Vnc1\ project/Tuthill-Lee\ collab'
if $IS_LINUX; then
    alias cdmyshortcuts='cd ~/.local/share/applications'
    alias cdshortcuts='cd /usr/share/applications'
fi

#Provide useful default arguments for some programs
alias ffmpeg="ffmpeg -hide_banner"
alias ffprobe="ffprobe -hide_banner"

#Check jobs running on o2 when not logged into o2
if ! type squeue &> /dev/null; then
    alias sjobs='ssh o2 "squeue -u jtm23 --format=%.8i%.55j%.11M%.2t%.7P%.8D%R"'
fi

#Server login aliases. Must have ~/.ssh/config set up to recognize these names
alias temca='ssh -Y temca'
alias o2='ssh -Y o2'
alias catmaid2='ssh -Y catmaid2'
alias catmaid3='ssh -Y catmaid3'
alias gandalf='ssh -Y gandalf'
alias radagast='ssh -Y radagast'
alias htem='ssh -Y htem'
alias temcagt='ssh -Y temcagt'
alias xtem='ssh -Y xtem'
alias dwalin='ssh -Y dwalin'
alias balin='ssh -Y balin'
alias gpu0='ssh -Y gpu0'
alias gpu1='ssh -Y gpu1'
alias rnice='ssh -Y rnice'
alias printrbottunnel='ssh -N temca -L 21100:localhost:21100'
