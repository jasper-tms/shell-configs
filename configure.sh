#!/bin/sh

if [ "${SHELL##*/}" = zsh ]; then
    export SHELL_CONFIGS_DIR="${0:A:h}"
elif [ "${SHELL##*/}" = bash ]; then
    export SHELL_CONFIGS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
fi


export IS_LINUX=false
export IS_MAC=false
case "$(uname -s)" in
    "Linux")    IS_LINUX=true;;
    "Darwin")   IS_MAC=true;;
esac

source $SHELL_CONFIGS_DIR/shell_misc.sh
source $SHELL_CONFIGS_DIR/shell_functions.sh
export PATH=${SHELL_CONFIGS_DIR}/shell_scripts:$PATH


#Aliases
source $SHELL_CONFIGS_DIR/aliases_general.sh

if [ -n "$SYNFUL_ALIASES" ]; then
    echo "Loading synful aliases"
    source $SHELL_CONFIGS_DIR/aliases_synful.sh
fi

if [ -n "$O2_ALIASES" ]; then
    echo "Loading O2 aliases"
    source $SHELL_CONFIGS_DIR/aliases_o2.sh
fi

if [ -n "$HTEM_ALIASES" ]; then
    echo "Loading htem aliases"
    source $SHELL_CONFIGS_DIR/aliases_htem.sh
fi

if [ -n "$NELY_ALIASES" ]; then
    echo "Loading NeLy aliases"
    source $SHELL_CONFIGS_DIR/aliases_nely.sh
fi
