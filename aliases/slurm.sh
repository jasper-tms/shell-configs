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
