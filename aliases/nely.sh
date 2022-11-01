# Aliases for navigating filesystems and servers in the Neuroengineering Lab (PI: Pavan Ramdya)

if $IS_LINUX; then
	alias mntlabserv="sudo mount -t cifs //sv1files.epfl.ch/Ramdya-Lab /mnt/labserver -o username=phelps,noperm,vers=2.1,domain=intranet"
    alias mntnas="sudo mount -t cifs //upramdyanas1.epfl.ch/data /mnt/nas -o username=phelps,noperm,vers=2.1,domain=intranet"
    alias mntnas2="sudo mount -t cifs //upramdyanas1.epfl.ch/data2 /mnt/nas2 -o username=phelps,noperm,vers=2.1,domain=intranet"

    alias cdlabserv="cd /mnt/labserver"
    alias cdnas="cd /mnt/nas"
    alias cdnas2="cd /mnt/nas2"
elif $IS_MAC; then
	alias mntlabserv="mount -t smbfs //phelps@sv1files.epfl.ch/Ramdya-Lab $HOME/mnt/nely/labserver"
    alias mntnas="mount -t smbfs //phelps@upramdyanas1.epfl.ch/data $HOME/mnt/nely/nas"
    alias mntnas2="mount -t smbfs //phelps@upramdyanas1.epfl.ch/data2 $HOME/mnt/nely/nas2"

    alias cdlabserv="cd $HOME/mnt/nely/labserver"
    alias cdnas="cd $HOME/mnt/nely/nas"
    alias cdnas2="cd $HOME/mnt/nely/nas2"
fi

j="$HOME/mnt/nely/labserver/PHELPS_Jasper"
alias cdj="if [ ! -e \"$j\" ]; then mntlabserv; fi; cd $j"
alias oj="if [ ! -e \"$j\" ]; then mntlabserv; fi; o $j"

alias cdpo="cd $HOME/'Dropbox (Personal)/Science/Postdoc - EPFL'"
alias cdpres="cd $HOME/'Dropbox (Personal)/Science/Postdoc - EPFL/presentations'"
alias cdproj="cd $HOME/'Dropbox (Personal)/Science/Postdoc - EPFL/projects'"
alias cdscape="cd $HOME/repos/jasper-tms/NeLy-projects/build-a-scape"
