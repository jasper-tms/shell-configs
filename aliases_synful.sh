alias visynful='vi ~/repos/jasper-tms/shell-configs/aliases_synful.sh'

alias synful_env='source /n/groups/htem/users/tmn7/envs/ubuntu180402/bin/activate'

alias ng='ipython -i /n/groups/htem/temcagt/datasets/vnc1_r066/segmentation/volume_info/ng.py'
alias ngsnap='ipython -i /n/groups/htem/temcagt/datasets/vnc1_r066/synapsePrediction+templateAlignment/0_synapsePrediction/synful_training/ng_snapshot.py'

alias cdg='cd /n/groups/htem/temcagt/datasets/vnc1_r066/synapsePrediction+templateAlignment/0_synapsePrediction/synapse_ground_truth'
alias cdn='cd /n/groups/htem/temcagt/datasets/vnc1_r066/synapsePrediction+templateAlignment/0_synapsePrediction/synful_training/networks'
alias cdi='cd /n/groups/htem/temcagt/datasets/vnc1_r066/synapsePrediction+templateAlignment/0_synapsePrediction/synful_inference/'
alias cdz='cd /n/groups/htem/temcagt/datasets/vnc1_r066/synapsePrediction+templateAlignment/0_synapsePrediction/zetta_inference/'

function checkpoints() {
if [ -f "checkpoint" ]; then
    head -1 checkpoint | awk '{print $2}'
fi
for p in */checkpoint; do
    if [ -e "$p" ]; then
        echo ${p/\/checkpoint/} $(head -1 $p | awk '{print $2}')
    fi
done
for p in */*/checkpoint; do
    if [ -e "$p" ]; then
        echo ${p/\/checkpoint/} $(head -1 $p | awk '{print $2}')
    fi
done
}


function usegpu() {
    export CUDA_VISIBLE_DEVICES=$1
}
