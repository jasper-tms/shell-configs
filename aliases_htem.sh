# Aliases for navigating filesystems and servers in the High Throughput Electron Microscopy lab (PI: Wei-Chung Lee)

# Bookmarked folders
alias cdj='cd ~/Dropbox\ \(HMS\)/htem_team/Jasper'
alias cddata='cd ~/Dropbox\ \(HMS\)/htem_team/Jasper/data'
alias cdri='cd ~/Dropbox\ \(HMS\)/htem_team/Jasper/data/righty'
alias cdmsv='cd ~/Dropbox\ \(HMS\)/htem_team/manuscripts/gtVNC_cell'
alias cdmsx='cd ~/Dropbox\ \(HMS\)/htem_team/manuscripts/2020_NatNeuro_KuanPhelpsEtAl_XrayHolographicNanotomographyMethods'
alias cdtut='cd ~/Google\ Drive\ File\ Stream/My\ Drive/HTEM/Vnc1\ project/Tuthill-Lee\ collab'

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

#Check jobs running on o2 when not logged into o2
if ! type squeue &> /dev/null; then
    alias sjobs='ssh o2 "squeue -u \$USER --format=%.8i%.55j%.11M%.2t%.7P%.8D%R"'
fi
