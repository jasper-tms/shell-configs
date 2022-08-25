# Aliases for navigating filesystems and servers in the Neuroengineering Lab (PI: Pavan Ramdya)

alias mntnely="mount -t smbfs //phelps@sv1files.epfl.ch/Ramdya-Lab $HOME/mnt/nelyserver"
#alias mntnely="mount -t cifs //sv1files.epfl.ch/Ramdya-Lab ~/mnt/nelyserver -o username=phelps,noperm,vers=2.1,domain=intranet"  # This is what the lab manual says to use. Might work on linux but doesn't work for me on my mac.
alias cdnely="cd $HOME/mnt/nelyserver"
alias mntnas="mount -t smbfs //phelps@upramdyanas1.epfl.ch/data ~/mnt/nelynas"
alias cdnas="cd $HOME/mnt/nelynas"

j="$HOME/mnt/nelyserver/PHELPS_Jasper"
alias cdj="if [ ! -e \"$j\" ]; then mntnely; fi; cd $j"
alias oj="if [ ! -e \"$j\" ]; then mntnely; fi; o $j"

alias cdpo="cd $HOME/'Dropbox (Personal)/Science/Postdoc - EPFL'"
alias cdpres="cd $HOME/'Dropbox (Personal)/Science/Postdoc - EPFL/presentations'"
alias cddata="cd $HOME/'Dropbox (Personal)/Science/Postdoc - EPFL/data'"
