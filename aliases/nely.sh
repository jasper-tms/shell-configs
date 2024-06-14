# Aliases for navigating filesystems and servers in the Neuroengineering Lab (PI: Pavan Ramdya)

if $IS_LINUX; then
    # Assume mount settings are listed in /etc/fstab
    alias mntls="mount /mnt/labserver"
    alias mntnas="mount /mnt/nas"
    alias mntnas2="mount /mnt/nas2"
    alias mntscapepc="mount /mnt/scapepc"
elif $IS_MAC; then
    # Use samba mounts because I couldn't get cifs to work on Mac
    alias mntls="mount -t smbfs //phelps@sv-nas1.rcp.epfl.ch/Ramdya-Lab $HOME/mnt/labserver"
    alias mntnas="mount -t smbfs //phelps@upramdyanas1.epfl.ch/data $HOME/mnt/nas"
    alias mntnas2="mount -t smbfs //phelps@upramdyanas1.epfl.ch/data2 $HOME/mnt/nas2"
    alias mntscapepcphelps="mount -t smbfs //phelps@128.178.194.38/data $HOME/mnt/scapepc"
    alias mntscapepc='echo Enter nely password; mount -t smbfs "//.;nely@128.178.194.38/data" $HOME/mnt/scapepc'
fi
alias cdls="if [ ! -e \"/mnt/labserver/data/JSP\" ]; then mntls; fi; cd /mnt/labserver/data/JSP"
alias cdnas="if [ ! -e \"/mnt/nas/JSP\" ]; then mntnas; fi; cd /mnt/nas/JSP"
alias cdnas2="if [ ! -e \"/mnt/nas2/JSP\" ]; then mntnas2; fi; cd /mnt/nas2/JSP"
alias cdscapepc="if [ ! -e \"/mnt/scapepc/JSP_scape_data\" ]; then mntscapepc; fi; cd /mnt/scapepc/JSP_scape_data"


alias cdpo="cd $HOME/Dropbox*/Science/'Postdoc - EPFL'"
alias opo="o $HOME/Dropbox*/Science/'Postdoc - EPFL'"
alias cdpres="cd $HOME/Dropbox*/Science/'Postdoc - EPFL'/presentations"
alias cdproj="cd $HOME/Dropbox*/Science/'Postdoc - EPFL'/projects"
alias cdscape="cd $HOME/repos/jasper-tms/NeLy-projects/build-a-scape"


alias falco="ssh -Y falco"
alias thorax="ssh -Y thorax"

alias watchgpu="watch -n 1 nvidia-smi"
