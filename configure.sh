# Configure shell settings
# Works in zsh and bash, on Linux or Mac

export IS_BASH=false
export IS_ZSH=false
SHELL_NAME=$(ps -cp "$$" -o command="")
if [ "${SHELL_NAME: -3}" = zsh ]; then
    export IS_ZSH=true
elif [ "${SHELL_NAME: -4}" = bash ]; then
    export IS_BASH=true
else
    echo "Could not determine shell!"
fi

if $IS_BASH; then
    export SHELL_CONFIGS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
elif $IS_ZSH; then
    export SHELL_CONFIGS_DIR="${0:A:h}"
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
