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

# Detect whether this shell is interactive, so the rest of this file can stay
# quiet (no alias-loading messages, etc.) when sourced non-interactively - e.g.
# at boot or from scripts. $- contains 'i' for interactive shells in bash and zsh.
case $- in
    *i*) export IS_INTERACTIVE=true ;;
    *)   export IS_INTERACTIVE=false ;;
esac

if ${IS_BASH:=false}; then
    export SHELL_CONFIGS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
elif ${IS_ZSH:=false}; then
    export SHELL_CONFIGS_DIR="${0:A:h}"
fi


export IS_LINUX=false
export IS_MAC=false
case "$(uname -s)" in
    "Linux")    IS_LINUX=true;;
    "Darwin")   IS_MAC=true;;
esac

# Source shell_functions.sh first because it defines add_to_path, which
# shell_misc.sh (and the shell_scripts line below) rely on. add_to_path adds
# each directory only if absent, so re-sourcing these configs in nested or
# non-interactive shells spawned by scripts, editors, or screen never stacks up
# duplicate PATH entries.
source $SHELL_CONFIGS_DIR/shell_functions.sh
source $SHELL_CONFIGS_DIR/shell_misc.sh
add_to_path "${SHELL_CONFIGS_DIR}/shell_scripts"


#Aliases
source $SHELL_CONFIGS_DIR/aliases/general.sh
for name in $(echo $LOAD_ALIASES); do
    if [ -e "$SHELL_CONFIGS_DIR/aliases/$name.sh" ]; then
        ${IS_INTERACTIVE:=false} && echo "Loading $name aliases"
        source "$SHELL_CONFIGS_DIR/aliases/$name.sh"
    else
        ${IS_INTERACTIVE:=false} && echo "No aliases file to load: $SHELL_CONFIGS_DIR/aliases/$name.sh"
    fi
done
