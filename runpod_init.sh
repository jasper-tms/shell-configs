# Manually source this script once on each new RunPod instance,
# and it will add a line to ~/.bashrc that makes this script get
# sourced automatically upon each new login (at least until the
# instance gets destroyed and the contents of ~ are wiped).
configs=/workspace/repos/jasper-tms/shell-configs
if ! grep "source /workspace" ~/.bashrc > /dev/null; then
    echo "" >> ~/.bashrc
    echo "source $configs/runpod_init.sh" >> ~/.bashrc
fi


# Do some one-time setup steps
if ! which vim > /dev/null; then
    apt update
    apt install vim tree -y
    ln -sf $configs/vimrc ~/.vimrc
    git config --global user.email "jasper.s.phelps@gmail.com"
    git config --global user.name "Jasper Phelps"
fi


# Do some every-login setup steps
export TERM=xterm-256color
source $configs/configure.sh

venv_root=/workspace/.venv/venv-for-virtualenvwrapper
export VIRTUALENVWRAPPER_PYTHON=$venv_root/bin/python
export VIRTUALENVWRAPPER_VIRTUALENV=$venv_root/bin/virtualenv
export WORKON_HOME=/workspace/.virtualenvs
export PROJECT_HOME=/workspace/Devel
source $venv_root/bin/virtualenvwrapper.sh

alias cdw='cd /workspace'
cd /workspace
workon sam
