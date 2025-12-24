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
if ! grep -q "Jasper Phelps" $HOME/.gitconfig 2> /dev/null; then
    apt update -qq
    # General utilities
    apt install -qq -y vim htop tree rsync screen
    ln -sf $configs/vimrc ~/.vimrc
    # GL packages required by python rendering libraries
    if grep -q "22.04" /etc/os-release; then
        apt install -qq -y libegl1-mesa libegl1-mesa-dev libgl1-mesa-glx libglib2.0-0 libxrender1
    elif grep -q "24.04" /etc/os-release; then
        apt install -qq -y libegl1 libgl1-mesa-dri libglib2.0-0 libxrender1
    else
        echo "OS does not appear to be either Ubuntu 22.04 or 24.04, so I don't know" \
             " what GL packages are named and can't install them"
        exit 1
    fi
    # These commands will put entries in $HOME/.gitconfig
    git config --global core.editor vim
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

export PYGLET_HEADLESS=true
export TORCH_HOME=/workspace/.cache/torch
export FVCORE_CACHE=/workspace/.cache/fvcore
export HF_HOME=/workspace/.cache/huggingface
export XDG_CACHE_HOME=/workspace/.cache

alias cdw='cd /workspace'
cd /workspace
workon sam
