# Aliases for navigating filesystems and servers in the Neuroengineering Lab (PI: Pavan Ramdya)

if $IS_LINUX; then
    # Assume mount settings are listed in /etc/fstab
    alias mntls="mount /mnt/labserver"
    alias mntnas="mount /mnt/nas"
    alias mntnas2="mount /mnt/nas2"
elif $IS_MAC; then
    # Use samba mounts because I couldn't get cifs to work on Mac
    alias mntls="mount -t smbfs //phelps@sv1files.epfl.ch/Ramdya-Lab $HOME/mnt/labserver"
    alias mntnas="mount -t smbfs //phelps@upramdyanas1.epfl.ch/data $HOME/mnt/nas"
    alias mntnas2="mount -t smbfs //phelps@upramdyanas1.epfl.ch/data2 $HOME/mnt/nas2"
fi
alias cdls="cd /mnt/labserver"
alias cdnas="cd /mnt/nas"
alias cdnas2="cd /mnt/nas2"

j="/mnt/labserver/PHELPS_Jasper"
alias cdj="if [ ! -e \"$j\" ]; then mntls; fi; cd $j"
alias oj="if [ ! -e \"$j\" ]; then mntls; fi; o $j"

alias cdpo="cd $HOME/'Dropbox (Personal)/Science/Postdoc - EPFL'"
alias cdpres="cd $HOME/'Dropbox (Personal)/Science/Postdoc - EPFL/presentations'"
alias cdproj="cd $HOME/'Dropbox (Personal)/Science/Postdoc - EPFL/projects'"
alias cdscape="cd $HOME/repos/jasper-tms/NeLy-projects/build-a-scape"
