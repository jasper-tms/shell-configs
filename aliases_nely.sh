# Aliases for navigating filesystems and servers in the Neuroengineering Lab (PI: Pavan Ramdya)

if $IS_LINUX; then
	alias mntnely="sudo mount -t cifs //sv1files.epfl.ch/Ramdya-Lab $HOME/mnt/nelyserver -o username=phelps,noperm,vers=2.1,domain=intranet"
elif $IS_MAC; then
	alias mntnely="mount -t smbfs //phelps@sv1files.epfl.ch/Ramdya-Lab $HOME/mnt/nelyserver"
fi
alias cdnely="cd $HOME/mnt/nelyserver"
alias mntnas="mount -t smbfs //phelps@upramdyanas1.epfl.ch/data ~/mnt/nelynas"
alias cdnas="cd $HOME/mnt/nelynas"
alias mntnas2="mount -t smbfs //phelps@upramdyanas1.epfl.ch/data2 ~/mnt/nelynas2"
alias cdnas2="cd $HOME/mnt/nelynas2"

j="$HOME/mnt/nelyserver/PHELPS_Jasper"
alias cdj="if [ ! -e \"$j\" ]; then mntnely; fi; cd $j"
alias oj="if [ ! -e \"$j\" ]; then mntnely; fi; o $j"

alias cdpo="cd $HOME/'Dropbox (Personal)/Science/Postdoc - EPFL'"
alias cdpres="cd $HOME/'Dropbox (Personal)/Science/Postdoc - EPFL/presentations'"
alias cddata="cd $HOME/'Dropbox (Personal)/Science/Postdoc - EPFL/data'"
