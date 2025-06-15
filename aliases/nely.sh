# Aliases for navigating filesystems and servers in the Neuroengineering Lab (PI: Pavan Ramdya)

if $IS_LINUX; then
    # Assume mount settings are listed in /etc/fstab
    alias mntls="$HOME/repos/nely/knowledge-base/mount_servers.sh"
    alias mntlsd="mount /mnt/upramdya_data"
    alias mntlsf="mount /mnt/upramdya_files"
    alias mntscapepc="mount /mnt/scapepc"
elif $IS_MAC; then
    # Use samba mounts because I couldn't get cifs to work on Mac
    alias mntlsf="mount -t smbfs //phelps@sv-nas1.rcp.epfl.ch/upramdya/files $HOME/mnt/upramdya_files"
    alias mntlsd="mount -t smbfs //phelps@sv-nas1.rcp.epfl.ch/upramdya/data $HOME/mnt/upramdya_data"
    alias mntscapepcphelps="mount -t smbfs //phelps@128.178.194.38/data $HOME/mnt/scapepc"
    alias mntscapepc='echo Enter nely password; mount -t smbfs "//.;nely@128.178.194.38/data" $HOME/mnt/scapepc'
fi
alias cdlsd="if [ ! -e \"/mnt/upramdya_data/JSP\" ]; then mntlsd; fi; cd /mnt/upramdya_data/JSP"
alias cdls=cdlsd
alias cdlsf="if [ ! -e \"/mnt/upramdya_files/PHELPS_Jasper\" ]; then mntlsf; fi; cd /mnt/upramdya_files/PHELPS_Jasper"
alias cdscapepc="if [ ! -e \"/mnt/scapepc/JSP\" ]; then mntscapepc; fi; cd /mnt/scapepc/JSP"


alias cdpo="cd $HOME/Dropbox*/Science/'Postdoc - EPFL'"
alias opo="o $HOME/Dropbox*/Science/'Postdoc - EPFL'"
alias cdpres="cd $HOME/Dropbox*/Science/'Postdoc - EPFL'/presentations"
alias cdproj="cd $HOME/Dropbox*/Science/'Postdoc - EPFL'/projects"
alias cdscape="if [ ! -e \"/mnt/upramdya_data/JSP\" ]; then mntlsd; fi; cd /mnt/upramdya_data/JSP/SCAPE"


alias falco="ssh -Y falco"
alias thorax="ssh -Y thorax"

alias watchgpu="watch -n 1 nvidia-smi"
