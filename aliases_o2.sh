alias vio2='vi ~/repos/jasper-tms/shell-configs/aliases_o2.sh'


# SLURM stuff: squeue / srun / sshare / sacct
alias sjobs="date; squeue -u $USER --format=\"%.8i%.45j %.8M %.2t %.6P %.4C %.5D %R\""
alias sjobswide="date; squeue -u $USER --format=\"%.8i%.70j %.8M %.2t %.6P %.4C %.5D %R\""
alias sjobsu="date; squeue --format=\"%.8i%.70j %.8M %.2t %.6P %.4C %.5D %R\" -u"

alias interact="srun --pty -p interactive -t 0-12:00 --mem=2G bash"
alias interactY="srun --pty -p interactive -t 0-12:00 --x11 --mem=2G bash"

alias karma="sshare -U"
alias karmau="sshare -a | grep"
alias karmareport="sacct --format=jobid%9,jobName%30,state,MaxRSS,ReqMem%6,Elapsed%13,Timelimit,NCPUS%4,NodeList%20 --units=G -u $USER"
alias karmareportwide="sacct --format=jobid%9,jobName%50,state,MaxRSS,ReqMem%6,Elapsed%13,Timelimit,NCPUS%4,NodeList%20 --units=G -u $USER"
alias karmareportu="sacct --format=jobid%9,jobName%30,state,MaxRSS,ReqMem%6,Elapsed%13,Timelimit,NCPUS%4,NodeList%20 --units=G -u"
alias karmareportlogs='sacct --format=jobid%9,jobName%30,state,MaxRSS,ReqMem%6,Elapsed%13,Timelimit,NCPUS%4,NodeList%20 --units=G -j $(ls *job.o* | sed "s/.*job\.o//" | tr "\n" ",")'


#Watch loops
alias watchjobs="while true; do sjobs; sleep 10; done"
alias watchzalign="while true; do grep iterations zalign.job.m*; lt grids; date; sleep 10; done"


#Bookmarked folders
alias cdhtem='cd /n/groups/htem'
alias cdrepos="cd /n/groups/htem/users/$USER/repos"
alias cdalignment="cd /n/groups/htem/data/wei_alignment/bin1.7/o2"

alias mountxray='sshfs gandalf:/n/groups/htem/ESRF_id16a /n/groups/htem/ESRF_id16a'
alias cdxray='cd /n/groups/htem/ESRF_id16a'
alias cds5="cd /n/groups/htem/ESRF_id16a/180917_sample5GadNLSfemale/"

alias cdseg='cd /n/groups/htem/Segmentation'
alias mountseg='sshfs gandalf:/n/groups/htem/Segmentation/ /n/groups/htem/Segmentation'


#temcagt dataset access
alias cdab='cd /n/groups/htem/temcagt/datasets/aaronsBrain'
alias mountab='sshfs gandalf:/n/groups/htem/temcagt/datasets/aaronsBrain /n/groups/htem/temcagt/datasets/aaronsBrain'

alias cdlgn6='cd /n/groups/htem/temcagt/datasets/lgn3696_r084'
alias mountlgn6='sshfs gandalf:/n/groups/htem/tier2/lgn3696_r084 /n/groups/htem/temcagt/datasets/lgn3696_r084'
alias cdlgn7='cd /n/groups/htem/temcagt/datasets/lgn3697_r085'
alias mountlgn7='sshfs gandalf:/n/groups/htem/tier2/lgn3697_r085 /n/groups/htem/temcagt/datasets/lgn3697_r085'

alias cdvnc1='cd /n/groups/htem/temcagt/datasets/vnc1_r066'
alias cdvnc1s='cd /n/groups/htem/temcagt/datasets/vnc1_r066/sections'
alias mountvnc1='sshfs gandalf:/n/groups/htem/temcagt/datasets/vnc1_r066 /n/groups/htem/temcagt/datasets/vnc1_r066'

alias cdrighty='cd /n/groups/htem/temcagt/datasets/righty_r1062'
alias cdrightys='cd /n/groups/htem/temcagt/datasets/righty_r1062/sections'

alias cdppc='cd /n/groups/htem/temcagt/datasets/ppc'
alias mountppc='sshfs gandalf:/n/groups/htem/temcagt/datasets/ppc /n/groups/htem/temcagt/datasets/ppc'

alias cdaedes='cd /n/groups/htem/temcagt/datasets/190311megAedes5Flower8Mupper_r194'
alias cdflower='cd /n/groups/htem/temcagt/datasets/190311megAedes5Flower8Mupper_r194'
alias mountaedes='sshfs gandalf:/n/groups/htem/temcagt/datasets/190311megAedes5Flower8Mupper_r194 /n/groups/htem/temcagt/datasets/190311megAedes5Flower8Mupper_r194'
#alias cdmupper='cd /n/groups/htem/temcagt/datasets/190311megAedes5Flower8Mupper_r194_Mupper'
#alias mountmupper='sshfs gandalf:/n/groups/htem/temcagt/datasets/190311megAedes5Flower8Mupper_r194_Mupper /n/groups/htem/temcagt/datasets/190311megAedes5Flower8Mupper_r194_Mupper'
alias cd195='cd /n/groups/htem/temcagt/datasets/190311megAedes6Flower11Fupper'
alias mount195='sshfs gandalf:/n/groups/htem/temcagt/datasets/190311megAedes6Flower11Fupper /n/groups/htem/temcagt/datasets/190311megAedes6Flower11Fupper'

alias cddcn='cd /n/groups/htem/temcagt/datasets/dcn1_r131'
alias mountdcn='sshfs gandalf:/n/groups/htem/temcagt/datasets/dcn1_r131 /n/groups/htem/temcagt/datasets/dcn1_r131'

alias cddh1='cd /n/groups/htem/temcagt/datasets/dorsalhorn1'
alias mountdh1='sshfs gandalf:/n/groups/htem/temcagt/datasets/dorsalhorn1 /n/groups/htem/temcagt/datasets/dorsalhorn1'

alias cdcb2='cd /n/groups/htem/temcagt/datasets/cb2'
alias mountcb2='sshfs gandalf:/n/groups/htem/temcagt/datasets/cb2 /n/groups/htem/temcagt/datasets/cb2'

alias cdshht1='cd /n/groups/htem/data/processed/170614_emx1-shh-wt1'
alias mountshht1='sshfs gandalf:/n/groups/htem/data/processed/170614_emx1-shh-wt1 /n/groups/htem/data/processed/170614_emx1-shh-wt1'
