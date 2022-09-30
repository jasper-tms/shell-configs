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
source $SHELL_CONFIGS_DIR/aliases/general.sh
for name in $(echo $LOAD_ALIASES); do
    if [ -e "$SHELL_CONFIGS_DIR/aliases/$name.sh" ]; then
        echo "Loading $name aliases"
        source "$SHELL_CONFIGS_DIR/aliases/$name.sh"
    else
        echo "No aliases file to load: $SHELL_CONFIGS_DIR/aliases/$name.sh"
    fi
done
